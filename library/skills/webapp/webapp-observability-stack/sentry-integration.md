# Sentry Integration — webapp-observability-stack

Pełna procedura konfiguracji Sentry SaaS dla webapp produkcyjnego LogicMorrow.

---

## 1. Account setup (jednorazowo per organizacja)

1. Wejdź na `https://sentry.io/` → "Get Started for Free"
2. Utwórz organizację: `logicmorrow`
3. Plan: **Free** (5000 errors/mo, 10GB attachment, 1 seat — wystarczające dla DemoApp)
4. Create Project:
   - Platform: `Next.js`
   - Alert Frequency: `Alert me on every new issue`
   - Project Name: `{{PROJECT_NAME}}`
   - Team: Personal (single developer)

---

## 2. DSN management

**Gdzie znaleźć DSN:**
```
Sentry Dashboard → Project → Settings → Client Keys (DSN) → DSN
```

**Format:** `https://<public_key>@o<org_id>.ingest.sentry.io/<project_id>`

**Zasady:**
- DSN jest **public-safe** — widoczny w bundlu JS przeglądarki. Nie traktuj jak hasła.
- `SENTRY_AUTH_TOKEN` jest **sekretny** — tylko upload source maps w CI (nie w DSN).
- Jeden DSN per projekt/środowisko (nie współdziel między DemoApp i external-crm).

**Rotacja DSN** (gdy compromise lub leakage):
1. Sentry → Project → Settings → Client Keys → Revoke current key
2. Generate new key
3. Update `SENTRY_DSN` w `.env` prod + GitHub Secrets
4. Redeploy aplikacji

---

## 3. Alert routing

### Default alert (rekomendowany dla DemoApp single-developer)

```
Sentry → Alerts → New Alert → Issue Alert
```

| Ustawienie | Wartość |
|---|---|
| Environment | `production` |
| Trigger | "When: A new issue is created" |
| Filter | Severity: all (nie filtruj — mała apka) |
| Action | Send an email to `{{ADMIN_EMAIL}}` |

### Alert na email dla każdego nowego erroru

1. Project → Alerts → "New Issue" alert (tworzony automatycznie)
2. Edytuj → Actions → "Send a notification to `{{ADMIN_EMAIL}}`"
3. Save

### Throttling na free tier

Free tier: 5000 events/month. DemoApp: ~50-200 sessions/mc = ~500-2000 events/mc max.
W razie spiku (bug deploy):
- Sentry auto-throttles po 5000 events — dalsze nie są przyjmowane
- Ustawienie "Ignore" dla znanych nie-bugów → sekcja 5 (Ignore patterns)

---

## 4. Sample rates — kiedy zmieniać

Domyślne wartości w templates (wystarczające dla DemoApp):

| Środowisko | `tracesSampleRate` | Errors |
|---|---|---|
| `development` | `1.0` (100%) | 100% |
| `production` | `0.1` (10%) | 100% |

**Kiedy zwiększyć tracesSampleRate na prod:**
- Debugging wydajności (powolne queries)
- Chwilowo do 1.0, reset po znalezieniu problemu

**Kiedy zmniejszyć:**
- Jeśli zbliżasz się do 5000 events/mc — zmniejsz do 0.05 lub 0.01
- Monitor usage: Sentry → Settings → Subscription → Usage

---

## 5. Ignore patterns (nie-bugi = szum)

Dodaj do `ignoreErrors` w `sentry.server.config.ts`:

```typescript
ignoreErrors: [
  // Next.js not found — obsługiwane przez app, nie są bugami
  'NEXT_NOT_FOUND',
  // Prisma expected business flow
  'NotFoundError',
  // User-initiated aborts
  'AbortError',
  // Network issues po stronie klienta
  'Failed to fetch',
  'NetworkError',
  'Load failed',
  // Rate limiting (oczekiwany behavior) — nie loguj do Sentry
  // Zamiast tego: pino.warn + return HTTP 429
]
```

**Zasada:** ignore only expected errors. Nieoczekiwane błędy ZAWSZE trafiają do Sentry.

---

## 6. Source maps upload (CI)

Source maps pozwalają Sentry pokazać oryginalne linie kodu TypeScript zamiast minified JS.

```yaml
# W .github/workflows/cd.yml
- name: Build with source maps
  env:
    SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
    SENTRY_ORG: ${{ secrets.SENTRY_ORG }}
    SENTRY_PROJECT: ${{ secrets.SENTRY_PROJECT }}
  run: pnpm build
  # @sentry/nextjs withSentryConfig w next.config.js auto-uploads source maps
  # gdy SENTRY_AUTH_TOKEN jest dostępny w środowisku
```

`SENTRY_AUTH_TOKEN` pobierz z: Sentry → User Settings → Auth Tokens → Create New Token
Scopes wymagane: `project:releases`, `org:read`.

---

## 7. Verify integration działa

```bash
# W terminalu dev (wymaga SENTRY_DSN w .env)
pnpm dev

# Trigger test error w kodzie (usuń po weryfikacji)
# np. w app/page.tsx:
throw new Error('Sentry test — usuń po weryfikacji')

# Sprawdź Sentry Dashboard za ~30 sekund
# Powinieneś zobaczyć event: "Sentry test — usuń po weryfikacji"
```

**Checklist weryfikacji:**
- [ ] Test event widoczny w Sentry Dashboard
- [ ] Environment = `development` (lub `production` jeśli test na prod)
- [ ] Stack trace pokazuje oryginalny TypeScript (nie minified)
- [ ] Email alert przyszedł na `{{ADMIN_EMAIL}}`
- [ ] `SENTRY_DSN` w `.env.example` (NIE hardcode w kodzie)
