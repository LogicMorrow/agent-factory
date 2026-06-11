# Security Headers — Caddy + Hono + Next.js specifics

Weryfikacja przed retrofitem:
```bash
curl -I https://twoja-domena.pl
# Brakujące headers = lista robocza poniżej
```

---

## Retrofit (istniejący projekt)

### Caddy — blok `header` w Caddyfile

Dodaj sekcję `header` do istniejącego bloku domeny:

```caddyfile
twoja-domena.pl {
    reverse_proxy api:3001

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Frame-Options "DENY"
        X-Content-Type-Options "nosniff"
        Referrer-Policy "strict-origin-when-cross-origin"
        Permissions-Policy "camera=, microphone=, geolocation="
        Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self'; frame-ancestors 'none'"
        -Server
        -X-Powered-By
    }
}
```

`-Server` i `-X-Powered-By` usuwają nagłówki ujawniające stos technologiczny.

### Hono middleware (`hono/secure-headers`)

Dla projektów które nie mają Caddy lub potrzebują granularnej kontroli per-endpoint:

```typescript
import { secureHeaders } from 'hono/secure-headers';
import type { Hono } from 'hono';

export function applySecurityHeaders(app: Hono) {
  app.use('*', secureHeaders({
    strictTransportSecurity: 'max-age=31536000; includeSubDomains',
    xFrameOptions: 'DENY',
    xContentTypeOptions: 'nosniff',
    referrerPolicy: 'strict-origin-when-cross-origin',
    permissionsPolicy: {
      camera: [],
      microphone: [],
      geolocation: [],
    },
    contentSecurityPolicy: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:', 'https:'],
      connectSrc: ["'self'"],
      frameAncestors: ["'none'"],
    },
  }));
}
```

Docs: https://hono.dev/docs/middleware/builtin/secure-headers

---

## New project (greenfield)

Ten sam blok Caddy lub middleware Hono od pierwszego deploy. Nie ma powodu odkładać.

---

## CSP — restrykcyjny vs permisywny

### Produkcja (restrykcyjny)
```
Content-Security-Policy:
  default-src 'self';
  script-src 'self';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  font-src 'self';
  connect-src 'self' https://api.sentry.io;
  frame-ancestors 'none';
  upgrade-insecure-requests;
```

### Dev/staging (permisywny — tylko debug)
```
Content-Security-Policy:
  default-src 'self' 'unsafe-inline' 'unsafe-eval';
  img-src *;
  connect-src *;
```

Nigdy nie deploy permisywnego CSP na prod.

---

## Next.js specifics

Tylko tam gdzie jest realna różnica vs standardowego Hono.

### CSP z `next/image`

`next/image` serwuje obrazy przez `//_next/image?url=...` — CSP musi uwzględnić źródła zewnętrzne:

```
img-src 'self' data: https: blob:;
```

Dla własnych domen image:
```
img-src 'self' data: https://cdn.twoja-domena.pl https://images.zewnetrzny.pl;
```

### Middleware headers (App Router — Next 14+)

`middleware.ts` w katalogu root:

```typescript
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const response = NextResponse.next;

  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');

  // CSP osobno — długi string
  response.headers.set(
    'Content-Security-Policy',
    "default-src 'self'; script-src 'self' 'nonce-${nonce}'; ..."
  );

  return response;
}
```

Next 14 vs 15: w Next 15 `headers` w Server Components jest async — nie dotyczy middleware, ale dotyczy `next.config.ts` headers array. Szczegóły: https://nextjs.org/docs/app/building-your-application/configuring/content-security-policy

Alternatywa dla Next: headers w `next.config.ts` (statyczne, bez nonce):

```typescript
// next.config.ts
const nextConfig = {
  async headers {
    return [
      {
        source: '/(.*)',
        headers: [
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
        ],
      },
    ];
  },
};
```

Preferable: headers przez Caddy (1 miejsce) zamiast duplikowania w Next middleware i Hono.

---

## Antywzorce

- ❌ `Content-Security-Policy: default-src *` — odpowiednik braku CSP.
- ❌ `unsafe-eval` w script-src na produkcji — otwiera XSS przez eval.
- ❌ HSTS bez `includeSubDomains` gdy subdomeny też mają HTTPS — niespójność.
- ❌ Ustawianie headers tylko w Hono ale nie w Caddy — Caddy może obsługiwać inne ścieżki (static files).
- ❌ Brak `-Server` i `-X-Powered-By` — ujawnianie stosu ułatwia targeted attacks.

## Weryfikacja

```bash
# Sprawdź wszystkie security headers naraz
curl -I https://twoja-domena.pl | grep -E "Strict|X-Frame|X-Content|Referrer|Content-Security|Permissions"

# Narzędzie online
# https://securityheaders.com/?q=twoja-domena.pl
```

## Oficjalne docs

- MDN Security Headers: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers#security
- CSP Reference: https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
- Next.js CSP: https://nextjs.org/docs/app/building-your-application/configuring/content-security-policy
