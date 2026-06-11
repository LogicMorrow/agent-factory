# Workflow konsumenta — webapp-observability-stack

Pełny przewodnik wdrożenia skilla w nowym projekcie webapp Next.js 14.2.

---

## Prereqs

- [ ] Next.js 14.2 App Router projekt istnieje
- [ ] pnpm 10+ zainstalowany
- [ ] Skill `webapp-docker-templates` już zastosowany (healthcheck endpoints jako kontrakty)
- [ ] Konto Sentry SaaS założone (lub pominąć Sentry → tylko pino + healthcheck)
- [ ] Konto UptimeRobot założone (free tier wystarczy)

---

## Krok 1 — Instalacja zależności

```bash
# Logger
pnpm add pino pino-http pino-redact

# Sentry (Next.js 14 App Router)
pnpm add @sentry/nextjs

# Dev: pino-pretty dla czytelnych logów lokalnie
pnpm add -D pino-pretty
```

---

## Krok 2 — Kopiowanie templates

```bash
# Utwórz katalogi docelowe
mkdir -p lib app/api/health app/api/ready app/api/version app/api/metrics docs

# Kopiuj z library skills
SKILL_DIR="$HOME/agent-factory/library/skills/webapp/webapp-observability-stack/templates"

cp "${SKILL_DIR}/pino.config.ts.template"              lib/logger.ts
cp "${SKILL_DIR}/sentry.server.config.ts.template"     sentry.server.config.ts
cp "${SKILL_DIR}/sentry.client.config.ts.template"     sentry.client.config.ts
cp "${SKILL_DIR}/healthcheck-routes.ts.template"       _healthcheck-routes.ts  # split manually below
cp "${SKILL_DIR}/uptimerobot-setup.md.template"        docs/uptimerobot-setup.md
cp "${SKILL_DIR}/audit-trail-hook-template.sh.template" .claude/hooks/audit-trail-on-offer-write.sh
cp "${SKILL_DIR}/observability-env-vars.md.template"   _env-vars-obs.md        # merge do .env.example
```

Rozbij `_healthcheck-routes.ts` na osobne pliki Route Handler:
```bash
# Ręcznie wytnij każdą sekcję FILE: z _healthcheck-routes.ts i zapisz jako:
#   app/api/health/route.ts   (sekcja "Liveness probe")
#   app/api/ready/route.ts    (sekcja "Readiness probe")
#   app/api/version/route.ts  (sekcja "Build metadata")
#   app/api/metrics/route.ts  (sekcja "Prometheus v2 stub")
```

---

## Krok 3 — Podmień placeholdery

```bash
# Uruchom skrypt z placeholders-reference.md (edytuj wartości najpierw)
bash replace-placeholders.sh

# Weryfikacja — powinien zwrócić 0 linii (brak niepodmienionych zmiennych)
grep -r '{{' . --include='*.ts' --include='*.md' --include='*.sh' \
  | grep -v 'node_modules' | grep -v '.claude/skills'
```

---

## Krok 4 — Konfiguracja ENV vars

```bash
# Skopiuj obserwability blok z _env-vars-obs.md do .env.example
cat _env-vars-obs.md | grep -A 30 'Gotowy blok' >> .env.example

# Utwórz .env z prawdziwymi wartościami (nie commit do git)
cp .env.example .env
# Edytuj .env — podaj SENTRY_DSN z Sentry dashboard
```

Sentry DSN pobierz z: Sentry Dashboard → Project → Settings → Client Keys (DSN).

```bash
# SENTRY_AUTH_TOKEN (tylko CI) — dodaj do GitHub Secrets
gh secret set SENTRY_AUTH_TOKEN --body "sntrys_..."
```

---

## Krok 5 — Konfiguracja Sentry w Next.js

Dodaj `instrumentation.ts` w root projektu:
```typescript
export async function register {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    await import('./sentry.server.config')
  }
}
```

Zaktualizuj `next.config.js`:
```javascript
const { withSentryConfig } = require('@sentry/nextjs')

const nextConfig = {
  // twoja istniejąca konfiguracja
}

module.exports = withSentryConfig(nextConfig, {
  org: process.env.SENTRY_ORG,
  project: process.env.SENTRY_PROJECT,
  silent: !process.env.CI,
  widenClientFileUpload: true,
  hideSourceMaps: true,
  disableLogger: true,
})
```

---

## Krok 6 — Test lokalny

```bash
# Start dev server
pnpm dev

# Test healthcheck endpoints
curl -sf http://localhost:3020/api/health | jq .
# Oczekiwane: {"status":"ok","timestamp":"...","uptime":...}

curl -sf http://localhost:3020/api/ready | jq .
# Oczekiwane: {"status":"ok","checks":{"db":"ok"},"latency_ms":5}

curl -sf http://localhost:3020/api/version | jq .
# Oczekiwane: {"version":"0.0.0","build_sha":"local",...}

# Test Sentry (wymaga DSN w .env)
# Wejdź na stronę Next.js → sprawdź Sentry Dashboard za ~30s
```

---

## Krok 7 — UptimeRobot setup

Postępuj z `docs/uptimerobot-setup.md` — procedure krok po kroku.
Wymaga deploymentu na prod (krok 5 w uptimerobot-setup.md zakłada istniejącą domenę).

---

## Krok 8 — Done criteria check

Przejdź przez sekcję 11 Done criteria w SKILL.md. Każdy checkbox musi być odznaczony przed
oznaczeniem zadania jako zakończonego.

```bash
# Szybka weryfikacja kluczowych punktów
curl -sf https://{{PROD_URL}}/api/health | jq .status     # "ok"
curl -sf https://{{PROD_URL}}/api/ready | jq .checks.db   # "ok"
curl -sf https://{{PROD_URL}}/api/version | jq .version   # semver
grep -r 'SENTRY_DSN' .env.example                          # powinien być
git grep 'SENTRY_AUTH_TOKEN' -- ':!.gitignore'             # 0 wyników (sekret w CI)
ls -la artifacts/audit-trail/ 2>/dev/null || echo "audit-trail nie ma jeszcze ofert (OK)"
```
