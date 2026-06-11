# Przykłady użycia — webapp-ci-cd-workflows

Dwa kompletne przykłady konfiguracji: mały webapp single-VPS i średni webapp z monorepo.

---

## Przykład A — Mały webapp (DemoApp, single-user, VPS prod)

**Kontekst:** Next.js 14.2 + PostgreSQL 16 + Caddy + ghcr.io + 1 VPS prod z self-hosted runner.

**Zmienne:**
```
PROJECT_NAME=demo-app
GHCR_OWNER=logicmorrow
APP_PORT=3020
NODE_VERSION=22
PNPM_VERSION=10
VPS_PROD_RUNNER_LABEL=demoapp-prod
STAGING_URL=https://staging.demoapp.pl
COVERAGE_THRESHOLD=80
```

**Wynik po podmiance:**
- `ci.yml`: lint → typecheck → vitest (coverage ≥80%) → playwright → docker build
- `cd.yml`: build+push `ghcr.io/logicmorrow/demo-app:sha` → deploy na VPS prod via runner `demoapp-prod`
- `security.yml`: Trivy daily + CodeQL weekly + SBOM weekly + ZAP baseline daily vs staging

---

### Dobrze — deploy via self-hosted runner (bez SSH key sharing)

```yaml
# cd.yml - deploy-prod job
jobs:
  deploy-prod:
    runs-on: [self-hosted, demoapp-prod]
    steps:
      - name: Login to ghcr.io
        run: echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin

      - name: Deploy via compose
        run: |
          cd /srv/demo-app
          docker compose pull
          docker compose up -d

      - name: Healthcheck
        run: curl -f --retry 10 --retry-delay 3 http://localhost:3020/api/ready
```

Dlaczego dobrze: runner na VPS ma lokalny docker bez ujawniania SSH key. Healthcheck
weryfikuje faktyczne uruchomienie nowego kontenera.

---

### Zle — SSH key sharing w secrets

```yaml
# NIE rob tak
- name: Deploy
  uses: appleboy/ssh-action@master
  with:
    host: ${{ secrets.DEPLOY_HOST }}
    username: ${{ secrets.DEPLOY_USER }}
    key: ${{ secrets.DEPLOY_KEY }}
```

Dlaczego zle: SSH key w GitHub secrets = ryzyko wycieku przez GH Actions log injection.
Skompromitowany secret = dostep do VPS prod. Self-hosted runner eliminuje ten wektor.

---

## Przykład B — Sredni webapp z monorepo (2 pakiety: app + api)

**Kontekst:** Next.js + Hono API jako osobny package, pnpm workspace, ghcr.io multi-arch.

---

### Dobrze — pnpm filter per package w monorepo

```yaml
# ci.yml - dostosowany pod pnpm workspace
jobs:
  lint:
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: "{{PNPM_VERSION}}"
      - run: pnpm install --frozen-lockfile
      - run: pnpm --filter ./packages/app lint
      - run: pnpm --filter ./packages/api lint

  typecheck:
    steps:
      - run: pnpm --filter './packages/*' typecheck
```

---

### Dobrze — jeden cache key dla calosci pnpm store (monorepo)

```yaml
# ci.yml - cache pnpm store (jeden klucz dla calego workspace)
- uses: actions/cache@v4
  with:
    path: ~/.pnpm-store
    key: pnpm-${{ runner.os }}-${{ hashFiles('**/pnpm-lock.yaml') }}
    restore-keys: pnpm-${{ runner.os }}-
```

---

### Zle — cache per package w monorepo (wolniejszy CI)

```yaml
# NIE rob tak - osobny cache per package = wolniejszy CI, brak reuse
- uses: actions/cache@v4
  with:
    path: packages/app/node_modules  # WRONG: cache per package
    key: pnpm-app-${{ hashFiles('packages/app/pnpm-lock.yaml') }}
```

Dlaczego zle: oddzielny cache per package = brak reuse wspolnych deps, wiecej transferu,
wolniejszy install. Jeden store + jeden klucz = 10x szybszy warm cache.

---

### Dobrze — multi-arch build dla monorepo

```yaml
# cd.yml - build osobnych obrazow dla app i api
- name: Build and push app
  uses: docker/build-push-action@v6
  with:
    context: .
    file: ./packages/app/Dockerfile
    platforms: linux/amd64,linux/arm64
    push: true
    tags: |
      ghcr.io/{{GHCR_OWNER}}/{{PROJECT_NAME}}-app:${{ github.sha }}
      ghcr.io/{{GHCR_OWNER}}/{{PROJECT_NAME}}-app:latest

- name: Build and push api
  uses: docker/build-push-action@v6
  with:
    context: .
    file: ./packages/api/Dockerfile
    platforms: linux/amd64,linux/arm64
    push: true
    tags: |
      ghcr.io/{{GHCR_OWNER}}/{{PROJECT_NAME}}-api:${{ github.sha }}
      ghcr.io/{{GHCR_OWNER}}/{{PROJECT_NAME}}-api:latest
```

---

## Przykład C — Rollback (emergency)

Rollback bez SHA tag jest niemozliwy. Z SHA tag: jeden docker pull.

```bash
# Znajdz poprzedni stabilny SHA (np. z GH Actions run history)
PREV_SHA=abc1234def5678

# Na VPS prod (lub przez self-hosted runner workflow_dispatch)
cd /srv/{{PROJECT_NAME}}
docker pull ghcr.io/{{GHCR_OWNER}}/{{PROJECT_NAME}}:$PREV_SHA

# Zaktualizuj compose.yml tymczasowo
sed -i "s|:latest|:$PREV_SHA|" compose.yml
docker compose up -d

# Weryfikacja
curl -f http://localhost:{{APP_PORT}}/api/ready
```

Dlaczego SHA tag jest wymagany: `:latest` jest mutowalne. SHA jest immutowalne.
`cd.yml.template` zawsze pushuje oba tagi: `:sha` + `:latest`.
