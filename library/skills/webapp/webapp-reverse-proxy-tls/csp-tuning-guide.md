# CSP Tuning Guide — webapp-reverse-proxy-tls
# Skill: webapp-reverse-proxy-tls v1.0.0

Przewodnik stopniowego zaostrzania CSP: od "wszystko dozwolone" do "strict-dynamic + nonce".
Używaj gdy: pierwszy deploy, dodajesz nową bibliotekę 3rd-party, audyt zewnętrzny.

---

## Filozofia: gradual tightening

CSP zbyt restrykcyjne od razu = zerwane UI w produkcji.
Poprawny workflow: Report-Only (obserwuj) → analiza → tightening → enforcement.

```
Dev: CSP-Report-Only + relaxed policy
          ↓ 48h obserwacji
Staging: CSP-Report-Only + target policy
          ↓ 48h bez niespodziewanych violations
Prod: CSP enforcement + monitoring
```

---

##  — Baseline inventory (przed deployem)

Zbierz listę wszystkich zewnętrznych zasobów które ładuje webapp:

```bash
# Otwórz Chrome DevTools → Network → filter na external domains
# Lub narzędzie:
npx @dawnlabs/csp-audit https://localhost:3020

# Sprawdź package.json — każda lib która ładuje coś zewnętrznego
# Next.js App Router: sprawdź _document.tsx, layout.tsx, Script komponent
grep -r "Script\|link\|href\|src=" src/ --include="*.tsx" --include="*.ts" \
  | grep -E "(http|//)" \
  | grep -v "localhost"
```

Stwórz listę:
```
SCRIPT: https://browser.sentry-cdn.com     (Sentry SDK)
SCRIPT: https://www.googletagmanager.com   (GTM - jeśli używany)
CONNECT: https://sentry.io                 (Sentry DSN)
STYLE: https://fonts.googleapis.com        (Google Fonts - jeśli używany)
FONT: https://fonts.gstatic.com            (Google Fonts)
IMG: https://lh3.googleusercontent.com     (Google avatars - jeśli OAuth)
```

---

##  — Report-Only deployment

### Krok 2.1 — Ustaw Report-Only w middleware.ts

```typescript
// src/middleware.ts — zamień Content-Security-Policy na Report-Only
response.headers.set(
  'Content-Security-Policy-Report-Only',  // ← REPORT ONLY (nie blokuje!)
  csp
)
// USUŃ lub zakomentuj:
// response.headers.set('Content-Security-Policy', csp)
```

### Krok 2.2 — Dodaj endpoint zbierający violations

```typescript
// src/app/api/csp-report/route.ts
import { NextRequest, NextResponse } from 'next/server'

export async function POST(req: NextRequest) {
  const body = await req.json
  console.warn('[CSP Violation]', JSON.stringify(body))
  // Opcjonalnie: wyślij do Sentry
  // Sentry.captureMessage('CSP Violation', { extra: body })
  return NextResponse.json({ ok: true })
}
```

Dodaj do CSP:
```
report-uri /api/csp-report
```

### Krok 2.3 — Deploy na staging i obserwuj 48h

```bash
# Obserwuj logi violations
docker compose logs app | grep "CSP Violation"

# Lub w przeglądarce: DevTools → Console → red CSP errors
# Format violation: { "csp-report": { "violated-directive": "...", "blocked-uri": "..." } }
```

---

##  — Analiza violations

### Katalog typowych violations Next.js 14

| Violation | Przyczyna | Rozwiązanie |
|---|---|---|
| `script-src 'inline'` | `<script>` inline w HTML (Next.js hydration) | Nonce via middleware — **NIE 'unsafe-inline'** |
| `script-src blob:` | Next.js lazy chunk loader | Dodaj `blob:` do script-src (nisko ryzykowne) |
| `connect-src wss://localhost` | Next.js HMR WebSocket (DEV) | Tylko dev — nie rób whitelist w prod |
| `img-src data:` | Inline SVG / placeholder | Dodaj `data:` do img-src (OK) |
| `img-src blob:` | Canvas.toBlob / File preview | Dodaj `blob:` do img-src |
| `style-src 'inline'` | Tailwind inline styles | `'unsafe-inline'` w style-src (akceptowalne) |
| `font-src data:` | Font embedded jako base64 | Dodaj `data:` do font-src |

### Violations które NIE powinny wystąpić (czerwona flaga)

```
script-src https://evil.com           → nieautoryzowany zewnętrzny JS → XSS injection?
script-src 'unsafe-eval'              → eval gdzieś w kodzie → szukaj i usuń
connect-src https://unknown-api.com   → nieznane API call → sprawdź deps
```

---

##  — Tightening policy

### Przepis na bezpieczny CSP Next.js 14 App Router (produkcja)

```
default-src 'self'
script-src 'nonce-{NONCE}' 'strict-dynamic'
style-src 'self' 'unsafe-inline'
img-src 'self' data: blob: [CDN_DOMAINS]
font-src 'self' data:
connect-src 'self' [API_DOMAINS] [SENTRY]
media-src 'none'
frame-ancestors 'none'
base-uri 'self'
form-action 'self'
object-src 'none'
upgrade-insecure-requests
```

### Dlaczego `'strict-dynamic'` zamiast whitelist

Whitelist domenowa (`script-src https://trusted.com`) jest obchodzona gdy `trusted.com` ma JSONP endpoint:
```html
<script src="https://trusted.com/jsonp?callback=alert(1)"></script>
```

`'strict-dynamic'` pozwala tylko skryptom załadowanym przez nonce ładować kolejne skrypty.
Next.js lazy chunks są ładowane przez initial script → `'strict-dynamic'` pokrywa automatycznie.

### Nonce generation — poprawna implementacja

```typescript
// src/middleware.ts — generuj nonce per-request (nie per-deployment!)
const nonce = Buffer.from(crypto.randomUUID).toString('base64')

// Przekaż nonce do Next.js layout
requestHeaders.set('x-nonce', nonce)
```

```typescript
// src/app/layout.tsx — użyj nonce w Script/style tags
import { headers } from 'next/headers'

export default async function RootLayout({ children }) {
  const headersList = await headers
  const nonce = headersList.get('x-nonce') ?? ''

  return (
    <html>
      <head>
        {/* Nonce wymagany dla każdego inline <script> */}
        <script nonce={nonce} dangerouslySetInnerHTML={{ __html: 'window.__NONCE__="' + nonce + '"' }} />
      </head>
      <body>{children}</body>
    </html>
  )
}
```

---

##  — Enforcement + monitoring

### Przełącz z Report-Only na enforcement

```typescript
// src/middleware.ts
// Zmień:
//   'Content-Security-Policy-Report-Only' → 'Content-Security-Policy'
response.headers.set('Content-Security-Policy', csp)
```

### Monitoring w Sentry (opcjonalne)

```typescript
// sentry.client.config.ts
Sentry.init({
  // CSP violations automatycznie reportowane jako events
  // Jeśli report-uri = Sentry DSN endpoint
})
```

### Weryfikacja końcowa

```bash
# csp-evaluator
CSP="default-src 'self'; script-src 'nonce-abc123' 'strict-dynamic'; ..."
curl "https://csp-evaluator.withgoogle.com/getCSPEvaluation?csp=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CSP'))")"

# Target: severity NONE lub max MEDIUM (dla 'unsafe-inline' style-src)
```

---

## Quick Reference — CSP severity matrix

| Dyrektywa | Wartość | Severity | Akcja |
|---|---|---|---|
| `script-src` | `'unsafe-eval'` | CRITICAL | USUŃ — XSS → RCE |
| `script-src` | `'unsafe-inline'` bez nonce | HIGH | USUŃ — zamień na nonce |
| `script-src` | `*` (wildcard) | HIGH | USUŃ — zastąp konkretną domeną |
| `script-src` | `data:` | HIGH | USUŃ — inline script injection |
| `style-src` | `'unsafe-inline'` | LOW-MEDIUM | Akceptowalne (Tailwind) |
| `img-src` | `*` | MEDIUM | Zamień na konkretny CDN |
| `frame-ancestors` | brak | MEDIUM | Dodaj `'none'` lub `'self'` |
| `object-src` | brak `'none'` | HIGH | Dodaj `object-src 'none'` |
