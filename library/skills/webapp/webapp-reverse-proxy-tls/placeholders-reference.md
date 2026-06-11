# Placeholders Reference — webapp-reverse-proxy-tls
# Skill: webapp-reverse-proxy-tls v1.0.0

Kompletna lista zmiennych `{{VARIABLE_NAME}}` używanych we wszystkich templates
tego skilla. Spójna z `webapp-docker-templates` (te same zmienne = ta sama wartość).

---

## Zmienne dziedziczone z webapp-docker-templates

| Zmienna | Opis | Przykład DemoApp | Przykład CRM |
|---|---|---|---|
| `{{PROJECT_NAME}}` | Nazwa projektu (lowercase-kebab) | `demo-app` | `external-crm` |
| `{{APP_PORT}}` | Port aplikacji Next.js w sieci Docker | `3020` | `3000` |
| `{{PNPM_VERSION}}` | Wersja pnpm | `10.33.2` | `10.33.2` |
| `{{NODE_VERSION}}` | Wersja Node.js | `22` | `22` |

## Zmienne nowe w webapp-reverse-proxy-tls

| Zmienna | Opis | Przykład DemoApp | Wymagane |
|---|---|---|---|
| `{{PROD_DOMAIN}}` | Domena produkcyjna (bez www, bez https://) | `demoapp.pl` | TAK |
| `{{ADMIN_EMAIL}}` | Email dla Let's Encrypt ACME | `you@example.com` | TAK |
| `{{STAGING_DOMAIN}}` | Domena staging (usuń blok jeśli brak) | `staging.demoapp.pl` | NIE |
| `{{DATE}}` | Data konfiguracji (ISO: YYYY-MM-DD) | `2026-05-29` | Dokumentacja |
| `{{VERIFIED_BY}}` | Osoba weryfikująca checklist | `operator LogicMorrow` | Dokumentacja |

## Zmienne CSP (Content Security Policy)

| Zmienna | Opis | Wartość DemoApp | Używana w |
|---|---|---|---|
| `{{CSP_SCRIPT_SOURCES}}` | Dodatkowe script-src (poza 'self' + nonce) | `https://browser.sentry-cdn.com` | Caddyfile + middleware |
| `{{CSP_STYLE_SOURCES}}` | Dodatkowe style-src | `` (pusty — Tailwind = self) | Caddyfile + middleware |
| `{{CSP_IMG_SOURCES}}` | Dodatkowe img-src | `` (pusty — obrazy = self) | Caddyfile + middleware |
| `{{CSP_CONNECT_SOURCES}}` | Dodatkowe connect-src (API, Sentry, etc.) | `https://sentry.io https://o*.ingest.sentry.io` | Caddyfile + middleware |
| `{{CSP_REPORT_URI}}` | Endpoint zbierający CSP violations | `` (pusty — usuń dyrektywę) | Caddyfile + middleware |

**Uwagi do CSP:**
- Jeśli zmienna jest pusta (brak 3rd-party danego typu), usuń ją z dyrektywy lub zostaw jako pusty string — parser ignoruje puste tokeny.
- `{{CSP_SCRIPT_SOURCES}}` NIE może zawierać `'unsafe-eval'` ani `'unsafe-inline'` w produkcji.
- Wildcards (`*`, `https:`) w script-src = BLOKER przy quality-checker.

## Zmienne rate limiting

| Zmienna | Opis | Wartość domyślna | Zatwierdzono w |
|---|---|---|---|
| `{{RATE_LIMIT_LOGIN}}` | Max prób logowania / 15 minut per IP | `5` | Brief  (sekcja 6.5) |
| `{{RATE_LIMIT_PDF}}` | Max generowań PDF / godzinę per user | `30` | Brief  (sekcja 6.5) |
| `{{RATE_LIMIT_GLOBAL}}` | Max requestów API / minutę per IP | `100` | Brief  (sekcja 5.1) |

**Uzasadnienie limitów:**
- Login 5/15min: standard OWASP ASVS L2 V2.2.1 (brute-force protection)
- PDF 30/hour: `@react-pdf/renderer` ~0.5-2s per PDF na VPS 2GB → 30 = max ~1/min bez przeciążenia
- Global 100/min: Jan single-user → 100/min = 1.67 req/s, bezpieczny bufor

## Kompletny przykład sed-replace dla DemoApp

```bash
#!/bin/bash
# run-from: katalog projektu
TEMPLATES_DIR="$HOME/agent-factory/library/skills/webapp/webapp-reverse-proxy-tls/templates"

# Skopiuj templates
cp "$TEMPLATES_DIR/Caddyfile.template" Caddyfile
cp "$TEMPLATES_DIR/Caddyfile-dev.template" Caddyfile-dev
cp "$TEMPLATES_DIR/nextjs-middleware-csp.ts.template" src/middleware.ts
cp "$TEMPLATES_DIR/rate-limit-hono.ts.template" src/lib/rate-limit.ts
cp "$TEMPLATES_DIR/security-headers-checklist.md.template" docs/security-headers-checklist.md

# Sed-replace wszystkich placeholders
DEMOAPP_VARS=(
  "s/{{PROJECT_NAME}}/demo-app/g"
  "s/{{PROD_DOMAIN}}/demoapp.pl/g"
  "s/{{ADMIN_EMAIL}}/you@example.com/g"
  "s/{{APP_PORT}}/3020/g"
  "s|{{CSP_SCRIPT_SOURCES}}|https://browser.sentry-cdn.com|g"
  "s|{{CSP_STYLE_SOURCES}}||g"
  "s|{{CSP_IMG_SOURCES}}||g"
  "s|{{CSP_CONNECT_SOURCES}}|https://sentry.io https://o*.ingest.sentry.io|g"
  "s|{{CSP_REPORT_URI}}||g"
  "s/{{STAGING_DOMAIN}}/staging.demoapp.pl/g"
  "s/{{RATE_LIMIT_LOGIN}}/5/g"
  "s/{{RATE_LIMIT_PDF}}/30/g"
  "s/{{RATE_LIMIT_GLOBAL}}/100/g"
  "s/{{DATE}}/$(date +%F)/g"
  "s/{{VERIFIED_BY}}/operator LogicMorrow/g"
)

for f in Caddyfile Caddyfile-dev src/middleware.ts src/lib/rate-limit.ts docs/security-headers-checklist.md; do
  for v in "${DEMOAPP_VARS[@]}"; do
    sed -i -e "$v" "$f"
  done
done

# Weryfikacja
echo "--- Sprawdzanie pozostałych placeholders ---"
grep -rn '{{' Caddyfile Caddyfile-dev src/middleware.ts src/lib/rate-limit.ts
echo "(wynik pusty = OK)"
```

## Spójność z webapp-docker-templates

`webapp-docker-templates` używa `{{DOMAIN}}` dla domeny — ten skill używa `{{PROD_DOMAIN}}`.
Przy sed-replace upewnij się że obydwie zmienne mają tę samą wartość:

```bash
# webapp-docker-templates
sed -e "s/{{DOMAIN}}/demoapp.pl/g" compose.yml.template > compose.yml

# webapp-reverse-proxy-tls
sed -e "s/{{PROD_DOMAIN}}/demoapp.pl/g" Caddyfile.template > Caddyfile
```
