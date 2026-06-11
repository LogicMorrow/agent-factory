---
name: webapp-cicd-templates
version: "1.0"
type: skill
category: webapp
description: "Gdy użytkownik pracuje nad CI/CD, GitHub Actions, pre-commit hooks lub deployment automation w projekcie webapp. Aktywuj przy frazach: setup ci, pipeline, deploy webapp, husky, commitlint, github actions, coolify deploy, branch protection, dependabot."
compatible_with: ["webapp"]
requires: ["webapp-standards"]
tags: ["ci-cd", "github-actions", "husky", "commitlint", "dependabot", "coolify", "pnpm"]
token_cost: medium
files:
  - SKILL.md
  - workflows/ci.yml.template
  - workflows/deploy.yml.template
  - husky-setup.md
  - commitlint-config.md
  - dependabot-config.md
  - deploy-targets.md
  - README-secrets.md
  - variables.yaml
  - branch-protection.md
---

# webapp-cicd-templates

CI/CD boilerplate dla webapp w stacku Next.js + Hono + Postgres, VPS + Coolify lub ssh-compose.

## Kiedy używać

Uruchom gdy:
- nowy projekt webapp (greenfield) — pipeline od dnia 1
- istniejący projekt bez CI/CD (retrofit) — brak testow w PR, deploy reczny przez SSH
- konfiguracja husky / commitlint / dependabot
- zmiana deploy targetu (Coolify ↔ ssh-compose)

Nie uruchamiaj gdy:
- projekt backendowy bez frontendu (inne templates)
- projekt poza GitHub (GitLab, Bitbucket — inne runners)
- tylko hotfix secrets — wtedy tylko [`README-secrets.md`](README-secrets.md)

## Wymagania wstepne (consuming project)

| Wymaganie | Dlaczego | Pilne? |
|---|---|---|
| `GET /api/health` → 200 + `{status,version,uptime}` | health-check po deployu (30 prob × 10s) | **MUST-HAVE** |
| `pnpm-lock.yaml` w repo | CI cache kluczowany tym plikiem | must-have |
| `package.json` scripts: `lint`, `typecheck`, `test`, `build` | CI job names mapuja 1:1 | must-have |
| `docker-compose.yml` (tylko ssh-compose target) | deploy via compose up | warunkowy |
| `corepack enable` w Dockerfile | pnpm bez globalnego install | must-have gdy Docker |

Brak `/api/health` = CI deploy job zawsze fail (health-check loop). Dodaj endpoint zanim podepniesz deploy workflow.

## Quick Start — greenfield (5 krokow)

```bash
# 1. Kopiuj templates
cp -r library/skills/webapp/webapp-cicd-templates/workflows/ .github/workflows/
cp library/skills/webapp/webapp-cicd-templates/variables.yaml .github/cicd-variables.yaml

# 2. Wypelnij zmienne (edytuj .github/cicd-variables.yaml)
#    deployment_mode, deploy_target, rollback_mode, coverage_threshold

# 3. Renderuj templates (envsubst lub sed)
#    Podmien {{PROJECT_NAME}}, {{COOLIFY_APP_ID}}, {{HEALTH_URL}} w deploy.yml.template

# 4. Setup husky + commitlint
#    Patrz: husky-setup.md

# 5. Skonfiguruj secrets i branch protection
#    Patrz: README-secrets.md + branch-protection.md
```

Po wykonaniu: push feature branch → PR otwiera CI (lint/typecheck/test/audit), merge do main → auto deploy staging → manual approval production.

## Retrofit existing project — CRM case study (7 krokow)

**Stan startowy CRM:** npm, brak testow, CI brak, deploy SSH recznie.
**Config startowa:** `deployment_mode: staged`, `deploy_target: ssh-compose`, `rollback_mode: manual-only`, `coverage_threshold: 0`.

### Krok 1 — Migracja npm → pnpm

```bash
corepack enable && corepack prepare pnpm@latest --activate
pnpm import          # konwertuje package-lock.json → pnpm-lock.yaml
rm package-lock.json && rm -rf node_modules
pnpm install
pnpm run build       # weryfikacja
```

Weryfikacja: `cat pnpm-lock.yaml | head -3` — powinno zawierac `lockfileVersion`.
Rollback: `git revert HEAD` + `npm ci`.

Tech-debt flag: `coverage_threshold: 0` jest tech-debtem — podnosic iteracyjnie po dodaniu testow (patrz `webapp-standards/testing.md`).

### Krok 2 — Husky + commitlint

Patrz [`husky-setup.md`](husky-setup.md).

### Krok 3 — CI workflow

```bash
mkdir -p .github/workflows
cp workflows/ci.yml.template .github/workflows/ci.yml
# Edytuj: coverage_threshold → 0 dla startu
```

Weryfikacja: push dowolnego brancha → Actions tab → CI uruchomiony.

### Krok 4 — Secrets

Patrz [`README-secrets.md`](README-secrets.md), sekcja "ssh-compose target".
Wymagane sekrety: `DEPLOY_SSH_KEY`, `DEPLOY_HOST`, `DEPLOY_USER`.

### Krok 5 — Branch protection

```bash
gh auth login
# Patrz: branch-protection.md — gh CLI one-liner
```

Weryfikacja: proba push bezposrednio na main → blad "protected branch".

### Krok 6 — Deploy workflow (ssh-compose)

```bash
cp workflows/deploy.yml.template .github/workflows/deploy.yml
# Ustaw: deploy_target: ssh-compose, rollback_mode: manual-only
# Podmien: {{DEPLOY_HOST}}, {{DEPLOY_USER}}, {{DEPLOY_PATH}}
```

Weryfikacja: merge do main → Actions → deploy job uruchomiony.

### Krok 7 — Health endpoint

Dodaj do Hono backend:
```typescript
app.get('/api/health', (c) => c.json({ status: 'ok', version: process.env.APP_VERSION ?? 'dev', uptime: process.uptime }))
```

Weryfikacja: `curl https://<host>/api/health` → 200 + JSON.

## Konfiguracja — variables.yaml

Pelna dokumentacja: [`variables.yaml`](variables.yaml)

| Klucz | Typ | Default | Opis |
|---|---|---|---|
| `deployment_mode` | enum | `staged` | `simple` / `staged` / `preview` (preview = stub v1.0) |
| `deploy_target` | enum | `coolify` | `coolify` / `ssh-compose` |
| `coverage_threshold` | int 0-100 | `70` | 0 = pomijaj coverage gate |
| `rollback_mode` | enum | `retry-manual` | `manual-only` / `retry-manual` / `auto` (auto = TODO v1.1) |
| `slack_alerts` | bool | `false` | Slack webhook po deploy fail |
| `node_versions` | array | `[20, 22]` | Node matrix w CI |

## Integracja z webapp-security-hardening

CI job `audit` (`pnpm audit --prod --audit-level=high`) jest pierwsza warstwa bezpieczenstwa. Nie zastepuje pelnego retrofitu — patrz [`webapp-security-hardening/SKILL.md`](../webapp-security-hardening/SKILL.md):

- HTTPS / reverse proxy → `https-retrofit.md`
- Security headers → `security-headers.md`
- Rate-limiting → `rate-limiting.md`
- Secrets management → `secrets-management.md`

Workflow: najpierw `webapp-security-hardening` (infra), potem `webapp-cicd-templates` (pipeline).

## Rollback Procedure

### Coolify target (UI)

1. Coolify UI → projekt → Deployments → ostatni zielony deployment → "Redeploy"
2. Czekaj na health-check (max 5 min) — sprawdz `GET /api/health`
3. Jesli fail: Coolify UI → Environment → powrot do poprzedniego obrazu/tagu

### ssh-compose target (SSH)

```bash
ssh $DEPLOY_USER@$DEPLOY_HOST
cd /opt/<project>
git log --oneline -5          # znajdz poprzedni commit
git checkout <previous-sha>
docker compose up -d --build
curl http://localhost:<port>/api/health
```

### Post-mortem

Po rollbacku wypelnij template do `knowledge-base/reflections/`:
```
Data: <ISO>
Projekt: <nazwa>
Commit przyczyna: <sha>
Objawy: <co nie dzialalo>
Rollback: Coolify UI / SSH (zaznacz)
Czas rollbacku: <minuty>
Mitygacja: <co zmienic w workflow>
```

## Antywzorce

### 1. Commit sekretow do repo (krytyczny)

**Zle:**
```yaml
# deploy.yml
env:
  COOLIFY_WEBHOOK_TOKEN: "abc123xyz"
```
**Dobrze:** zawsze GitHub Secrets (`${{ secrets.COOLIFY_WEBHOOK_TOKEN }}`). Patrz `README-secrets.md`.

Dlaczego bolesne: po jednym commicie sekret jest w historii git na zawsze (nawet po usunieciu). Wymaga rotacji tokenu + audytu kto mial dostep.

### 2. Deploy bez health-check

**Zle:** webhook do Coolify → job konczy sie jako "success" — nie wiesz czy deploy faktycznie zadziałal.

**Dobrze:** polling `GET /api/health` 30 prob × 10s po webhook. Coolify webhook zwraca 200 OK = "przyjeto zadanie", nie "deploy OK". To fire-and-forget.

Dlaczego bolesne: produkcja na zepsutym obrazie przez godziny, bo CI "przeszedl".

### 3. `rollback_mode: auto` bez Coolify API tokenu

**Zle:** ustawienie `auto` w `variables.yaml` bez wcześniejszego skonfigurowania Coolify API token i rollback endpoint.

**Dobrze:** zostaw `retry-manual` (default) dopoki Coolify nie jest w pelni skonfigurowane. `auto` = TODO v1.1 — workflow emituje blad "not implemented".

Dlaczego bolesne: pozorna automatyzacja + cichy fail = brak rollbacku gdy naprawde potrzebny.

### 4. pnpm-lock.yaml nie w git

**Zle:** `.gitignore` zawiera `pnpm-lock.yaml` lub plik nie istnieje.

**Dobrze:** `pnpm-lock.yaml` zawsze w repo. CI klucz cache: `hashFiles('pnpm-lock.yaml')`.

Dlaczego bolesne: bez lockfile CI instaluje najnowsze wersje = `pnpm install` na CI != lokalne srodowisko = "u mnie działa" x10. Cache jest wtedy bezuzyteczny (kazdy run = nowy hash = miss cache).

### 5. Matrix Node bez cache per-node

**Zle:**
```yaml
- uses: actions/cache@v4
  with:
    key: pnpm-store-${{ hashFiles('pnpm-lock.yaml') }}  # jeden klucz dla obu node
```

**Dobrze:** klucz zawiera `${{ matrix.node-version }}` — osobny cache per Node.

Dlaczego bolesne: Node 20 i Node 22 moga miec rozne binarne buildowane addony — wspolny cache = corrupted cache = losowe bledy CI.

## Roadmap v1.1

- [ ] `rollback_mode: auto` — Coolify API rollback endpoint (wymaga Coolify token + `/api/v1/rollback`)
- [ ] Preview deployments (`deployment_mode: preview`) — ephemeral URL per PR
- [ ] GHCR image build + push w `deploy.yml` — szybsze deploy przez gotowy obraz zamiast Coolify build from git
- [ ] `/pack` automatyczne renderowanie templates (envsubst zamiast recznie sed)

## Powiazania

- [`webapp-security-hardening/SKILL.md`](../webapp-security-hardening/SKILL.md) — zaleznosc (CI audit step), uruchom przed lub razem
- [`webapp-standards/testing.md`](../webapp-standards/testing.md) — zasady pisania testow (AAA, naming, coverage progi) — CI je egzekwuje, skill definiuje
- [`husky-setup.md`](husky-setup.md) — krok-po-kroku pre-commit hooks
- [`deploy-targets.md`](deploy-targets.md) — Coolify vs ssh-compose — kiedy co, migration path
- [`ADR-0001: pnpm jako standard package managera fabryki`](../../../../knowledge-base/docs/adr/0001-pnpm-package-manager.md) — uzasadnienie wyboru pnpm jako standardu fabryki (centralny rejestr ADR, migracja 2026-04-23)

## Changelog

| Wersja | Data | Zmiana |
|---|---|---|
| 1.0 | 2026-04-23 | Pierwsza wersja: CI matrix [20,22], Coolify webhook, ssh-compose, husky, commitlint, dependabot |
