---
name: webapp-docker-templates
description: Templates konkretne (NIE placeholdery) — Dockerfile multi-stage + docker-compose dev/prod + entrypoint.sh + .dockerignore + healthcheck endpoints. Dla webapp produkcyjnych Next.js 14.2 LTS + Node 22 + pnpm 10 + PostgreSQL 16 + Caddy v2 auto-TLS. Pokrywa zasadę #15 CLAUDE.md punkty 1-3 (Dockerfile multi-stage + compose dev/prod + healthcheck /api/health /ready /version). Uruchamiaj gdy bootstrap nowego webapp produkcyjnego lub retrofit istniejącego pod audit-ready 18/18.
tools: Read, Write
model: sonnet
version: "1.0.0"
compatible_with: [webapp]
requires: []
tags: [docker, compose, iac, audit-ready, healthcheck, , zasada-15-pkt-1-3]
token_cost: medium
distribution: library/skills/webapp/
last_updated: 2026-05-29
last_reviewed: 2026-05-29
valid_until: 2027-05-29
---

# webapp-docker-templates

## 1. Purpose

Skill dostarcza **gotowe do podmienienia** szablony Docker dla webapp produkcyjnych LogicMorrow. Każdy template jest funkcjonalny — nie zawiera `# TODO implement` ani `YOUR_VALUE_HERE`. Zamiast tego używa konwencji `{{VARIABLE_NAME}}` z pełną listą zmiennych w sekcji 5.

**Dla kogo:** każdy nowy webapp produkcyjny LogicMorrow (DemoApp, external-crm, przyszłe projekty) oparty o Next.js 14.2 LTS + PostgreSQL 16 + Caddy v2. Stack referencyjny: external-crm (Next.js 14.2.35, React 18, TS 5, pnpm 10.33.2).

**Powiązanie z zasadą #15 CLAUDE.md:** skill pokrywa punkty 1-3 z 18 wymaganych dla audit-ready PASS. Brak tych plików = BLOKER przy `/pack`.

**Co NIE jest w scope tego skilla:**
- CI/CD workflows (GitHub Actions) → skill `webapp-cicd-templates`
- Security headers / hardening → skill `webapp-security-hardening`
- Backup off-site konfiguracja → osobny runbook w projekcie

---

## 2. Before starting work (cross-agent-learning v1.1.0)

Przed użyciem tego skilla konsument (agent lub Claude) MUSI:

1. **Sprawdzić `errors-webapp-docker-templates.md`** (pełna treść) jeśli istnieje w `.claude/memory/` projektu — apply silently rule (nie pytaj, popraw wzorzec który zawiódł).
2. **Przeczytać ostatnie 3 reflections** z `knowledge-base/reflections/` zawierające `docker` lub `compose` w nazwie lub treści.
3. **Przejrzeć `knowledge-base/lessons.jsonl` tail 20** — szczególnie lessons dotyczące Docker, healthcheck, pnpm corepack.

Budget: 5k tokenów. Apply silently — nie raportuj "czytam lessons", po prostu uwzględnij w decyzjach.

**Znane pułapki (z briefu , 2026-05-29):**
- `pnpm` wymaga `corepack enable` PRZED `corepack prepare` w Dockerfile — kolejność ma znaczenie.
- Next.js standalone output wymaga `output: 'standalone'` w `next.config.js` — bez tego COPY `--from=builder /app/.next/standalone` zawiedzie cicho.
- `wget` zamiast `curl` w HEALTHCHECK alpine — alpine ma `wget` domyślnie, `curl` wymaga instalacji.
- Backup sidecar w compose dev używa `postgres:16-alpine` bez dedykowanego hasła — musi dziedziczyć env z głównej bazy lub mieć `PGPASSWORD` explicite.

---

## 3. Templates dostarczane

Wszystkie 6 plików w katalogu `templates/` tego skilla:

| Plik | Rozmiar | Opis |
|---|---|---|
| `Dockerfile.template` | ~100 linii | Multi-stage build: deps → builder → runner. Node 22 alpine, pnpm 10, nieprivileged user UID 1001, HEALTHCHECK CMD wget |
| `compose.yml.template` | ~100 linii | Dev: 4 services (app, db, proxy, backup), volumes, networks, env_file |
| `compose.prod.yml.template` | ~75 linii | Prod override: resource limits, restart: always, healthcheck depends_on, logging json-file |
| `entrypoint.sh.template` | ~50 linii | DB wait loop (nc), prisma migrate deploy, exec "$@" |
| `dockerignore.template` | ~40 linii | Wykluczenia: node_modules, .next, .git, .env* + !.env.example, secrets/, etc. |
| `healthcheck-routes.md.template` | ~55 linii | Kontrakty 3 endpoints + TypeScript snippets dla Next.js 14 App Router |

---

## 4. Zasada #15 mapping

Skill `webapp-docker-templates` pokrywa te punkty zasady #15 CLAUDE.md:

| Punkt #15 | Co pokrywa | Plik template |
|---|---|---|
| **Pkt 1** — Dockerfile multi-stage + .dockerignore | Multi-stage deps/builder/runner + pełne wykluczenia | `Dockerfile.template` + `dockerignore.template` |
| **Pkt 2** — docker-compose.yml dev + docker-compose.prod.yml + entrypoint.sh z migracjami | Dev 4 services + prod override z limits + entrypoint prisma migrate | `compose.yml.template` + `compose.prod.yml.template` + `entrypoint.sh.template` |
| **Pkt 3** — Healthcheck endpoints `/api/health` `/api/ready` `/api/version` | Kontrakty JSON + TypeScript snippets Next.js 14 App Router | `healthcheck-routes.md.template` |

**Punkty 4-18 zasady #15** (CI/CD, security, docs, backup) — inne skille i komponenty paczki.

**Weryfikacja po wdrożeniu:**
```bash
# Test liveness
curl -sf http://localhost:${APP_PORT}/api/health | jq .status
# Test readiness (z DB ping)
curl -sf http://localhost:${APP_PORT}/api/ready | jq .
# Test version
curl -sf http://localhost:${APP_PORT}/api/version | jq .
# Docker healthcheck status
docker inspect <container_name> | jq '.[0].State.Health'
```

---

## 5. Konwencja placeholderów

Wszystkie zmienne do podmienienia przez konsumenta używają formatu `{{VARIABLE_NAME}}` (uppercase, bez spacji, z `_`).

**Lista wszystkich zmiennych we wszystkich templates:**

| Zmienna | Opis | Przykład dla DemoApp |
|---|---|---|
| `{{PROJECT_NAME}}` | Nazwa projektu (lowercase-kebab) | `demo-app` |
| `{{APP_PORT}}` | Port aplikacji Next.js w kontenerze | `3020` |
| `{{DB_HOST}}` | Hostname bazy danych w sieci compose | `db` |
| `{{DB_PORT}}` | Port PostgreSQL | `5432` |
| `{{DB_NAME}}` | Nazwa bazy danych | `demoapp_production` |
| `{{DB_USER}}` | Użytkownik bazy | `demoapp_user` |
| `{{DB_PASSWORD}}` | Hasło bazy (z .env, NIE hardcode) | `${DB_PASSWORD}` |
| `{{DOMAIN}}` | Domena produkcyjna | `demoapp.pl` |
| `{{IMAGE_REGISTRY}}` | Container registry | `ghcr.io/logicmorrow/demo-app` |
| `{{PNPM_VERSION}}` | Wersja pnpm (z package.json) | `10.33.2` |
| `{{NODE_VERSION}}` | Wersja Node.js | `22` |
| `{{BACKUP_SCHEDULE}}` | Cron schedule pg_dump | `0 3 * * *` |
| `{{BACKUP_RETENTION_DAYS}}` | Dni retencji local backup | `7` |
| `{{APP_MEM_LIMIT}}` | Memory limit dla app container | `512m` |
| `{{DB_MEM_LIMIT}}` | Memory limit dla db container | `256m` |
| `{{PROXY_MEM_LIMIT}}` | Memory limit dla proxy container | `64m` |

**Sed-replace example (bash):**
```bash
VARS=(
  "s/{{PROJECT_NAME}}/demo-app/g"
  "s/{{APP_PORT}}/3020/g"
  "s/{{DB_HOST}}/db/g"
  "s/{{DB_PORT}}/5432/g"
  "s/{{DB_NAME}}/demoapp_production/g"
  "s/{{DOMAIN}}/demoapp.pl/g"
  "s/{{IMAGE_REGISTRY}}/ghcr.io\/logicmorrow\/demo-app/g"
  "s/{{PNPM_VERSION}}/10.33.2/g"
  "s/{{NODE_VERSION}}/22/g"
)
for f in Dockerfile .dockerignore compose.yml compose.prod.yml entrypoint.sh; do
  sed_cmd=""
  for v in "${VARS[@]}"; do sed_cmd="$sed_cmd -e '$v'"; done
  eval "sed $sed_cmd $f > $f.tmp && mv $f.tmp $f"
done
```

---

## 6. Workflow konsumenta

### Krok 1 — Skopiuj templates

```bash
# Z katalogu projektu
SKILL_DIR="$(realpath ~/agent-factory/library/skills/webapp/webapp-docker-templates/templates)"
mkdir -p docker/
cp "$SKILL_DIR/Dockerfile.template" Dockerfile
cp "$SKILL_DIR/compose.yml.template" compose.yml
cp "$SKILL_DIR/compose.prod.yml.template" compose.prod.yml
cp "$SKILL_DIR/entrypoint.sh.template" entrypoint.sh
cp "$SKILL_DIR/dockerignore.template" .dockerignore
# healthcheck-routes.md.template → implementacja jako /src/app/api/health/route.ts etc.
```

### Krok 2 — Sed-replace placeholderów

Użyj skryptu z sekcji 5 lub podmień ręcznie. Zweryfikuj że nie zostały żadne `{{`:
```bash
grep -r '{{' Dockerfile compose.yml compose.prod.yml entrypoint.sh .dockerignore
# Wynik pusty = OK
```

### Krok 3 — Ustaw next.config.js

```js
// next.config.js — WYMAGANE dla standalone output
const nextConfig = {
  output: 'standalone',  // ← bez tego Dockerfile stage runner się posypie
}
```

### Krok 4 — Docker Compose up

```bash
# Dev
docker compose up -d
docker compose logs -f app

# Prod (VPS)
docker compose -f compose.yml -f compose.prod.yml up -d
```

### Krok 5 — Healthcheck verify

```bash
sleep 35  # czekaj na start-period
curl -sf http://localhost:{{APP_PORT}}/api/health
curl -sf http://localhost:{{APP_PORT}}/api/ready
curl -sf http://localhost:{{APP_PORT}}/api/version
# Wszystkie zwracają HTTP 200 = zasada #15 pkt 3 PASS
```

---

## 7. Przykłady użycia

### Przykład A — DemoApp (1 user, small webapp)

**Kontekst:** single-user webapp dekarski, VPS 2GB RAM, domena `demoapp.pl`.

**Zmienne do podmienienia:**
```
{{PROJECT_NAME}}    → demo-app
{{APP_PORT}}        → 3020
{{DOMAIN}}          → demoapp.pl
{{IMAGE_REGISTRY}}  → ghcr.io/logicmorrow/demo-app
{{APP_MEM_LIMIT}}   → 512m
{{DB_MEM_LIMIT}}    → 256m
{{PROXY_MEM_LIMIT}} → 64m
```

**Wynikowy compose.prod.yml resource limits:** suma ~832m z 2048m VPS = 41% wykorzystania. Pozostałe ~1.2GB = system + OS + backup sidecar. Bezpieczne.

**Backup schedule:** `0 3 * * *` (3:00 AM, niska aktywność jednego użytkownika).

### Przykład B — Przyszły webapp multi-tenant (średni projekt)

**Kontekst:** webapp dla 10-50 użytkowników, VPS 8GB RAM.

**Zmienne do podmienienia:**
```
{{PROJECT_NAME}}    → crm-v2
{{APP_PORT}}        → 3000
{{DOMAIN}}          → app.firma.pl
{{APP_MEM_LIMIT}}   → 1024m
{{DB_MEM_LIMIT}}    → 512m
{{PROXY_MEM_LIMIT}} → 128m
```

**Różnica vs Przykład A:** większe `mem_limit` w compose.prod.yml, backup sidecar retencja 30 dni zamiast 7.

**Dobrze (konkretne limity):**
```yaml
deploy:
  resources:
    limits:
      memory: 1024m
      cpus: '1.0'
```

**Źle (brak limitów):**
```yaml
# brak sekcji deploy.resources = kontener może zjeść całą pamięć VPS
# przy OOM kill → wypad produkcji bez ostrzeżenia
```

---

## 8. Anti-patterns

### A1 — Docker bez .dockerignore = secret leak (severity: CRITICAL)

**Problem:** `COPY . .` bez `.dockerignore` kopiuje `.env`, `.env.local`, `.env.production` do warstwy obrazu. Obraz wypchnięty na ghcr.io = sekrety publicznie dostępne przez `docker inspect`.

**Dobrze:**
```
# .dockerignore
.env*
!.env.example   ← tylko przykładowy plik
secrets/
```

**Źle:**
```
# .dockerignore bez .env* — sekrety w każdej warstwie obrazu
node_modules
.git
```

### A2 — Brak healthcheck = orchestrator nie wie kiedy restartować

**Problem:** Docker bez `HEALTHCHECK` zgłasza kontener jako `healthy` zaraz po starcie — nawet jeśli Next.js jeszcze inicjalizuje połączenie z DB. Caddy zaczyna routować ruch do niezainicjowanego serwera.

**Dobrze:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:{{APP_PORT}}/api/health || exit 1
```

**Źle:**
```dockerfile
# brak HEALTHCHECK — docker ps pokazuje (healthy) ale serwer jeszcze nie gotowy
```

### A3 — Root user w kontenerze = security risk (severity: HIGH)

**Problem:** domyślnie Docker uruchamia procesy jako root. Exploiting aplikacji = root na hoście jeśli namespace isolation nieskonfigurowany.

**Dobrze:**
```dockerfile
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs
USER nextjs
```

**Źle:**
```dockerfile
# brak USER nextjs — Next.js uruchamia się jako root
CMD ["node", "server.js"]
```

### A4 — Migracje bez entrypoint.sh = race condition

**Problem:** uruchomienie `prisma migrate deploy` jako osobny `docker compose run` przed `up` działa lokalnie, ale na VPS self-hosted runner kolejność nie jest gwarantowana. Entrypoint blokuje start do czasu migracji.

**Dobrze:**
```bash
# entrypoint.sh: wait DB → migrate → exec server
pnpm prisma migrate deploy
exec "$@"
```

**Źle:**
```yaml
# compose.yml command bez entrypoint:
command: sh -c "pnpm prisma migrate deploy && node server.js"
# Przy restarcie kontenera = migracje uruchamiają się ponownie (idempotentne, ale niesemantyczne)
```

---

## 9. Done criteria

Skill jest "użyty poprawnie" gdy spełnione WSZYSTKIE warunki:

- [ ] **5 plików docelowych** istnieje w katalogu projektu: `Dockerfile`, `compose.yml`, `compose.prod.yml`, `entrypoint.sh`, `.dockerignore`
- [ ] **Brak `{{` w plikach** — grep zwraca 0 wyników (`grep -r '{{' Dockerfile compose.yml compose.prod.yml entrypoint.sh .dockerignore`)
- [ ] **`next.config.js` ma `output: 'standalone'`** — bez tego stage runner zawiedzie
- [ ] **`docker compose up -d` działa** — wszystkie 4 services (app, db, proxy, backup) w stanie `running` lub `healthy`
- [ ] **Healthcheck endpoints zwracają HTTP 200:**
  - `GET /api/health` → `{"status":"ok","timestamp":"...","uptime":...}`
  - `GET /api/ready` → `{"status":"ok","db":"connected","timestamp":"..."}`
  - `GET /api/version` → `{"version":"...","sha":"...","env":"production"}`
- [ ] **zasada #15 pkt 1-3 PASS** — potwierdzone przez konsumenta lub quality-checker

---

## 10. Powiązania

**Agenty i skille które zazwyczaj współpracują z tym skillem:**

| Komponent | Rola |
|---|---|
| `webapp-cicd-templates` (skill) | Uzupełnia pkt 4 zasady #15 — GitHub Actions workflows CI/CD |
| `webapp-security-hardening` (skill) | Uzupełnia pkt 5-10 zasady #15 — CSP, HSTS, rate limiting |
| `webapp-bootstrapper` (agent) | Bootstrap nowego projektu — wywołuje ten skill przy /new-project |
| `quality-checker` (agent) | Weryfikuje done criteria sekcja 9 i zasada #15 mapping sekcja 4 |
| `model-routing` (skill) | Routing modeli — ten skill używa sonnet (medium token_cost) |

---

## ACTIVITY-LOG template (dla konsumenta)

Po użyciu skilla w projekcie dodaj wpis do `knowledge-base/activity-log.jsonl`:

```json
{"ts":"<ISO-8601>","actor":"<agent-lub-claude>","action":"skill_applied","artifact":"<projekt>/Dockerfile","skill":"webapp-docker-templates@1.0.0","notes":"zasada #15 pkt 1-3, sed-replace {{VARS}}, compose up PASS"}
```
