---
name: webapp-reverse-proxy-tls
description: Templates konkretne — Caddy v2 Caddyfile + auto-TLS Let's Encrypt + security headers (CSP/HSTS/X-Frame-Options/X-Content-Type-Options/Referrer-Policy) + rate limiting (Caddy IP-based + Hono middleware). Dla webapp produkcyjnych single/multi-tenant. Pokrywa zasadę #15 CLAUDE.md punkty 9-10. Uruchamiaj gdy bootstrap webapp produkcyjnego pod audit-ready 18/18.
tools: Read, Write
model: sonnet
version: "1.0.0"
compatible_with: [webapp]
requires: [webapp-docker-templates]
tags: [reverse-proxy, caddy, tls, lets-encrypt, csp, hsts, security-headers, rate-limiting, audit-ready, , zasada-15-pkt-9-10]
token_cost: medium
distribution: library/skills/webapp/
last_updated: 2026-05-29
last_reviewed: 2026-05-29
valid_until: 2027-05-29
---

# webapp-reverse-proxy-tls

## 1. Purpose

Skill dostarcza **gotowe do podmienienia** templates Caddy v2 + security headers + rate limiting dla webapp produkcyjnych.
Kontynuacja `webapp-docker-templates` — tamten skill definiuje `proxy` service w compose.yml, ten skill
dostarcza konkretny Caddyfile + middleware CSP + Hono rate limiting.

**Dla kogo:** każdy nowy webapp produkcyjny LogicMorrow oparty o Next.js 14.2 LTS + Caddy v2.
Stack referencyjny: DemoApp (`demoapp.pl:3020`), external-crm.

**Zasada #15 mapping:**

| Punkt #15 | Co pokrywa | Plik template |
|---|---|---|
| **Pkt 9** — Reverse proxy config + auto-TLS Let's Encrypt | Caddyfile prod + dev + placeholders-reference | `Caddyfile.template` + `Caddyfile-dev.template` |
| **Pkt 10** — CSP headers konkretne w middleware | Next.js middleware.ts + Hono rate limiting + checklist | `nextjs-middleware-csp.ts.template` + `rate-limit-hono.ts.template` + `security-headers-checklist.md.template` |

**Co NIE jest w scope tego skilla:**
- Dockerfile / compose.yml → skill `webapp-docker-templates`
- CI/CD workflows → skill `webapp-cicd-templates`
- RODO data protection → skill `data-protection-rodo-pl`
- Backup / DR → skill `webapp-docker-templates` (backup sidecar) + runbook

---

## 2. Before starting work (cross-agent-learning v1.1.0)

Przed użyciem tego skilla konsument MUSI:

1. **Sprawdzić `errors-webapp-reverse-proxy-tls.md`** jeśli istnieje w `.claude/memory/` — apply silently.
2. **Przeczytać ostatnie 3 reflections** zawierające `caddy`, `csp`, `tls` lub `proxy`.
3. **Przejrzeć `lessons.jsonl` tail 20** — szczególnie lessons dotyczące Caddy, CSP, HSTS.

Budget: 5k tokenów. Apply silently — nie raportuj czytania, uwzględnij w decyzjach.

**Znane pułapki (z briefu , 2026-05-29):**
- Caddy `rate_limit` wymaga pluginu `caddy-ratelimit` — nie wbudowany w oficjalny obraz. Alternatywa: `caddy-l4` lub Hono rate-limiter jako fallback (preferowane dla audit-ready).
- CSP `'unsafe-eval'` **NIGDY w produkcji** — Next.js 14 App Router nie potrzebuje. Dev: `'unsafe-inline'` akceptowalne, prod: nonce-based.
- HSTS `preload` wymaga `includeSubDomains` — bez tego preload list odrzuca domenę.
- Let's Encrypt rate limit: 5 certyfikatów per domenę per tydzień — staging ACME do testów TLS.

---

## 3. Templates dostarczane

Wszystkie pliki w `templates/`:

| Plik | Rozmiar | Opis |
|---|---|---|
| `Caddyfile.template` | ~120 linii | Production: auto-TLS, security headers, rate limit, www→apex redirect, logging |
| `Caddyfile-dev.template` | ~60 linii | Dev: localhost, no TLS, mock headers, no rate limit |
| `csp-policy.md.template` | ~100 linii | Przewodnik konfiguracji CSP per Next.js webapp |
| `nextjs-middleware-csp.ts.template` | ~100 linii | middleware.ts z nonce-based CSP + HSTS + X-Frame-Options |
| `rate-limit-hono.ts.template` | ~90 linii | Hono middleware: login 5/15min, PDF 30/hour, API 100/min |
| `security-headers-checklist.md.template` | ~80 linii | Weryfikacja po deploy: curl tests + narzędzia online |

---

## 4. Placeholders — pełna lista

Szczegóły w `placeholders-reference.md`. Kluczowe zmienne:

| Zmienna | Opis | Przykład DemoApp |
|---|---|---|
| `{{PROD_DOMAIN}}` | Domena produkcyjna | `demoapp.pl` |
| `{{ADMIN_EMAIL}}` | Email Let's Encrypt | `you@example.com` |
| `{{APP_PORT}}` | Port aplikacji w sieci Docker | `3020` |
| `{{CSP_SCRIPT_SOURCES}}` | Dodatkowe script-src | `https://browser.sentry-cdn.com` |
| `{{CSP_CONNECT_SOURCES}}` | Dodatkowe connect-src | `https://sentry.io` |
| `{{RATE_LIMIT_LOGIN}}` | Próby logowania/15min | `5` |
| `{{RATE_LIMIT_PDF}}` | Generowania PDF/hour | `30` |

Seed-replace example:
```bash
sed -e "s/{{PROD_DOMAIN}}/demoapp.pl/g" \
    -e "s/{{ADMIN_EMAIL}}/you@example.com/g" \
    -e "s/{{APP_PORT}}/3020/g" \
    Caddyfile.template > Caddyfile
```

---

## 5. Workflow konsumenta

Szczegółowy 7-krok opis w `workflow-konsumenta.md`. Skrót:

1. `cp templates/Caddyfile.template Caddyfile` + sed-replace
2. `cp templates/nextjs-middleware-csp.ts.template src/middleware.ts` + dostosuj CSP sources
3. `cp templates/rate-limit-hono.ts.template src/lib/rate-limit.ts`
4. DNS A record → IP VPS
5. `docker compose up -d proxy` → Let's Encrypt cert auto-fetch
6. `curl -I https://{{PROD_DOMAIN}}` → weryfikuj headers
7. `security-headers-checklist.md.template` → wszystkie PASS

---

## 6. Przykłady użycia

Szczegółowe 3 przykłady w `examples.md`. Skrót:

**Dobrze — DemoApp (CSP z nonce):**
```typescript
const nonce = Buffer.from(crypto.randomUUID).toString('base64')
const csp = `script-src 'nonce-${nonce}' 'strict-dynamic'; object-src 'none'`
headers.set('Content-Security-Policy', csp)
```

**Dobrze — Caddy HSTS:**
```
header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
```

**Źle — CSP z unsafe-eval (severity: CRITICAL):**
```typescript
// NIGDY w produkcji
const csp = "script-src 'self' 'unsafe-eval' 'unsafe-inline'"
// XSS exploitation = RCE via eval
```

**Źle — brak HSTS preload:**
```
# Strict-Transport-Security bez preload = podatny na SSL stripping przy pierwszym połączeniu
header Strict-Transport-Security "max-age=300"
```

---

## 7. Anti-patterns

Szczegółowe 6 antywzorców w `anti-patterns.md`. Lista:

| ID | Wzorzec | Severity |
|---|---|---|
| AP1 | `'unsafe-eval'` w CSP produkcji | CRITICAL |
| AP2 | Brak HSTS lub zbyt krótki max-age | HIGH |
| AP3 | `X-Frame-Options ALLOWALL` lub brak | HIGH |
| AP4 | Rate limit za luźny (brak limitu logowania) | HIGH |
| AP5 | Caddy bez `tls {email}` = self-signed = browser warnings | MEDIUM |
| AP6 | CSP `report-uri` do zewnętrznej domeny bez whitelist w `connect-src` | MEDIUM |

---

## 8. Tuning CSP

Szczegółowy przewodnik w `csp-tuning-guide.md`. Workflow:

1. Deploy z CSP `Content-Security-Policy-Report-Only` (nie blokuje, tylko loguje)
2. Zbierz violations przez 48h
3. Whitelist tylko wymagane sources
4. Przełącz na `Content-Security-Policy` (enforcement)
5. Weryfikacja: `csp-evaluator.withgoogle.com` PASS

---

## 9. Done criteria

Skill użyty poprawnie gdy spełnione WSZYSTKIE:

- [ ] `Caddyfile` istnieje w projekcie — brak `{{` po sed-replace
- [ ] `src/middleware.ts` zawiera CSP header z nonce (nie `'unsafe-eval'`, nie `'unsafe-inline'` w prod)
- [ ] HSTS header zawiera `max-age=31536000; includeSubDomains; preload`
- [ ] `X-Frame-Options: DENY` i `X-Content-Type-Options: nosniff` w odpowiedziach
- [ ] Hono rate-limit middleware aktywny na `/api/auth` i `/api/pdf`
- [ ] `curl -I https://{{PROD_DOMAIN}}` zwraca wszystkie 5 security headers
- [ ] `securityheaders.com` grade A lub A+
- [ ] Zasada #15 pkt 9-10 PASS — potwierdzone przez quality-checker

---

## 10. Powiązania

| Komponent | Rola |
|---|---|
| `webapp-docker-templates` (skill) | **Wymagany** — definiuje `proxy` service Caddy w compose.yml |
| `webapp-cicd-templates` (skill) | CI/CD workflows (pkt 4 zasady #15) |
| `webapp-security-hardening` (skill) | Głębsze hardening OWASP ASVS L2 |
| `data-protection-rodo-pl` (skill) | RODO compliance (pkt 12-15 zasady #15) |
| `quality-checker` (agent) | Weryfikuje done criteria sekcja 9 |
| `model-routing` (skill) | Routing modeli — ten skill używa sonnet |

---

## 11. Zasada #15 CLAUDE.md full mapping (ten skill)

```
Pkt 9  — Reverse proxy config Caddy/nginx + auto-TLS Let's Encrypt  → Caddyfile.template
Pkt 10 — CSP headers konkretne w middleware                          → nextjs-middleware-csp.ts.template
                                                                        + rate-limit-hono.ts.template
                                                                        + security-headers-checklist.md.template
```

---

## 12. ACTIVITY-LOG template (dla konsumenta)

Po użyciu skilla w projekcie dodaj wpis do `knowledge-base/activity-log.jsonl`:

```json
{
  "ts": "<ISO-8601>",
  "actor": "<agent-lub-claude>",
  "action": "skill_applied",
  "artifact": "<projekt>/Caddyfile",
  "skill": "webapp-reverse-proxy-tls",
  "skill_version": "1.0.0",
  "notes": "zasada #15 pkt 9-10, Caddyfile + middleware.ts + rate-limit PASS, securityheaders.com A+"
}
```
