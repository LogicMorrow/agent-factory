# Przykłady użycia — webapp-reverse-proxy-tls
# Skill: webapp-reverse-proxy-tls v1.0.0

3 przykłady: małe webapp (DemoApp), średnie CRM, retrofit istniejącej apki.

---

## Przykład A — DemoApp (single-user, demoapp.pl)

**Kontekst:** Single-user webapp dekarski, VPS 2GB RAM (Hetzner CX21 ~6 EUR/mc),
domena `demoapp.pl`, użytkownik Jan (50+, nie-IT), brak 3rd-party poza Sentry.

### Caddyfile (wynikowy po sed-replace)

```caddyfile
{
  email you@example.com
}

www.demoapp.pl {
  redir https://demoapp.pl{uri} permanent
}

demoapp.pl {
  tls you@example.com

  header {
    Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    X-Frame-Options "DENY"
    X-Content-Type-Options "nosniff"
    Referrer-Policy "strict-origin-when-cross-origin"
    Permissions-Policy "camera=, microphone=, geolocation=, payment=, usb=, interest-cohort="
    Content-Security-Policy "default-src 'self'; script-src 'self' https://browser.sentry-cdn.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self' https://sentry.io https://o*.ingest.sentry.io; frame-ancestors 'none'; base-uri 'self'; form-action 'self'; object-src 'none'; upgrade-insecure-requests"
    -Server
  }

  reverse_proxy app:3020 {
    health_uri /api/health
    health_interval 30s
    health_timeout 5s
    health_status 200
    header_up X-Real-IP {remote_host}
    header_up X-Forwarded-For {remote_host}
    header_up X-Forwarded-Proto {scheme}
  }

  log {
    output stdout
    format json
    level INFO
  }
}
```

### Rate limiting (rate-limit-hono.ts wynikowy)

```typescript
// Limity dla DemoApp (single-user, Jan ~20 ofert/mc)
const RATE_LIMIT_LOGIN = 5    // 5 prób / 15 min (brute-force)
const RATE_LIMIT_PDF = 30     // 30 PDF / godzinę (więcej niż potrzebuje)
const RATE_LIMIT_GLOBAL = 100 // 100 req/min (bezpieczny bufor dla 1 usera)
```

**Dobrze — Hono wrapper w route handler:**
```typescript
// src/app/api/auth/login/route.ts
import { withLoginRateLimit } from '@/lib/rate-limit'

async function loginHandler(req: Request): Promise<Response> {
  // ...logika logowania
}

export const POST = withLoginRateLimit(loginHandler)
```

**Źle — brak rate limitu na login:**
```typescript
// src/app/api/auth/login/route.ts — BRAK OCHRONY
export async function POST(req: Request) {
  // Brute-force możliwy — próby logowania bez limitu
  const { email, password } = await req.json
  // ...
}
```

---

## Przykład B — CRM-example.com (multi-user, istniejący projekt)

**Kontekst:** CRM dla LogicMorrow, ~5 użytkowników wewnętrznych, VPS 4GB RAM,
domena `crm.example.com`, używa Google Fonts + Sentry + zewnętrznego API mapowego.

### CSP differences vs Przykład A

```
# DemoApp (minimal)
script-src 'nonce-{NONCE}' 'strict-dynamic' https://browser.sentry-cdn.com
connect-src 'self' https://sentry.io

# external-crm (extended)
script-src 'nonce-{NONCE}' 'strict-dynamic' https://browser.sentry-cdn.com https://maps.googleapis.com
style-src 'self' 'unsafe-inline' https://fonts.googleapis.com
font-src 'self' https://fonts.gstatic.com
img-src 'self' data: blob: https://maps.gstatic.com https://lh3.googleusercontent.com
connect-src 'self' https://sentry.io https://maps.googleapis.com
```

### Caddyfile multi-host

```caddyfile
{
  email you@example.com
}

# Redirect www
www.crm.example.com {
  redir https://crm.example.com{uri} permanent
}

crm.example.com {
  tls you@example.com

  # CSP z Google Fonts
  header Content-Security-Policy "default-src 'self'; script-src 'nonce-{nonce}' 'strict-dynamic' https://browser.sentry-cdn.com https://maps.googleapis.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: blob: https://maps.gstatic.com; connect-src 'self' https://sentry.io https://maps.googleapis.com; frame-ancestors 'none'; object-src 'none'; upgrade-insecure-requests"

  # Pozostałe headers identyczne jak w A
  header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
  header X-Frame-Options "DENY"
  header X-Content-Type-Options "nosniff"
  header Referrer-Policy "strict-origin-when-cross-origin"

  reverse_proxy app:3000 {
    health_uri /api/health
    health_interval 30s
    health_status 200
    header_up X-Real-IP {remote_host}
    header_up X-Forwarded-Proto {scheme}
  }
}
```

**Uwaga:** Nonce w Caddyfile jest `{nonce}` — Caddy nie generuje nonce natively.
Poprawny flow: nonce generowany przez Next.js middleware → przekazany do app → app ustawia finalny CSP header.
Caddyfile CSP = fallback policy dla Caddy error pages (nie dla Next.js responses).

---

## Przykład C — Retrofit istniejącej apki bez CSP

**Kontekst:** Istniejąca Next.js apka na nginx bez security headers.
Migracja na Caddy + CSP bez downtime.

### Krok 1 — Audit obecnych headers

```bash
curl -sI https://stara-apka.pl | grep -iE "(x-frame|strict|content-security|x-content)"
# Wynik: BRAK headerów (blank) → start od baseline
```

### Krok 2 — Deploy z Report-Only (bezpieczny rollout)

```typescript
// src/middleware.ts — najpierw Report-Only
const IS_CSP_ENFORCED = process.env.CSP_ENFORCED === 'true'  // default: false

response.headers.set(
  IS_CSP_ENFORCED ? 'Content-Security-Policy' : 'Content-Security-Policy-Report-Only',
  csp
)
```

### Krok 3 — Analiza violations (48h)

```bash
# Obserwuj logi
docker compose logs app | grep "CSP"

# Znalezione violations → dodaj do whitelist
# np. "blocked-uri: https://old-cdn.stara-apka.pl" → dodaj img-src
```

### Krok 4 — Enforcement po stabilnym raporcie

```bash
# Ustaw zmienną środowiskową
echo "CSP_ENFORCED=true" >> .env.production

# Redeploy
docker compose pull && docker compose up -d

# Weryfikacja
curl -sI https://stara-apka.pl | grep "Content-Security-Policy"
# Oczekiwane: Content-Security-Policy: default-src 'self'; ... (bez -Report-Only)
```

### Mixed content detection (retrofit-specific)

```bash
# Sprawdź czy apka nie ładuje HTTP zasobów na HTTPS stronie (mixed content)
# Chrome DevTools → Console → szukaj: "Mixed Content"
# Lub narzędzie:
npx @nicecatch/aoc https://stara-apka.pl

# Caddy header: upgrade-insecure-requests
# Automatycznie przekierowuje http: → https: dla zasobów — dodaj do CSP
```
