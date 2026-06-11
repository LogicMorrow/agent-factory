# Konwencja placeholderów — webapp-ci-cd-workflows

Wszystkie zmienne w formacie `{{VARIABLE_NAME}}` — do podmienienia przez `sed` lub `envsubst`
przy bootstrapie projektu. Wartości muszą być spójne z `webapp-docker-templates`.

---

## Pełna tabela zmiennych

| Zmienna | Przykład | Opis | Wymagana w |
|---|---|---|---|
| `{{PROJECT_NAME}}` | `demo-app` | Slug projektu (lowercase, kebab-case) | ci, cd, security |
| `{{IMAGE_REGISTRY}}` | `ghcr.io` | Rejestr kontenerów (zawsze ghcr.io dla LogicMorrow) | ci, cd, security |
| `{{GHCR_OWNER}}` | `logicmorrow` | Owner w ghcr.io (lowercase GitHub org/user) | ci, cd, security |
| `{{APP_PORT}}` | `3020` | Port aplikacji w kontenerze | cd |
| `{{NODE_VERSION}}` | `22` | Wersja Node.js | ci |
| `{{PNPM_VERSION}}` | `10` | Wersja pnpm | ci |
| `{{COVERAGE_THRESHOLD}}` | `80` | Minimalne pokrycie linii w % (Vitest gate) | ci |
| `{{DEPLOY_BRANCH}}` | `main` | Branch triggujący deployment | cd |
| `{{VPS_PROD_RUNNER_LABEL}}` | `demoapp-prod` | Label self-hosted runner na VPS prod | cd |
| `{{STAGING_URL}}` | `https://staging.demoapp.pl` | URL stagingu dla ZAP scan (NIE prod) | security |
| `{{CODEQL_LANGUAGE}}` | `javascript-typescript` | Język CodeQL analysis | security |
| `{{ZAP_RULES_FILE}}` | `.zap/rules.tsv` | Opcjonalny plik reguł ZAP (suppress false positives) | security |

---

## Szczegółowy opis każdej zmiennej

### `{{PROJECT_NAME}}`
Slug projektu w lowercase + kebab-case. Używany jako:
- prefix obrazu Docker: `ghcr.io/{{GHCR_OWNER}}/{{PROJECT_NAME}}:sha`
- nazwa compose project: `docker compose -p {{PROJECT_NAME}}`
- label w workflow name: `CI — {{PROJECT_NAME}}`

Przykłady: `demo-app`, `external-crm`, `site-budowlana`

**NIE używaj:** spacji, underscore, wielkich liter.

### `{{IMAGE_REGISTRY}}`
Dla LogicMorrow zawsze `ghcr.io`. Oddzielna zmienna dla przenoszalności szablonu
do projektów z innym registrym (Docker Hub, AWS ECR).

### `{{GHCR_OWNER}}`
Lowercase GitHub organization lub username. Musi odpowiadać tokenowi `GITHUB_TOKEN`
(packages:write uprawnienie). Dla LogicMorrow: `logicmorrow`.

### `{{APP_PORT}}`
Port HTTP aplikacji wewnątrz kontenera. Musi być identyczny z portem w `Dockerfile`
(`EXPOSE`) i `compose.yml` (`ports: "HOST:APP_PORT"`).

Konwencja portów LogicMorrow:
- `3020` — DemoApp
- `3030` — external-crm
- `3000` — domyślny Next.js (dev-only)

### `{{NODE_VERSION}}`
Major wersja Node.js (np. `22`). Musi być spójna z:
- `webapp-docker-templates` Dockerfile ARG `NODE_VERSION`
- `.nvmrc` lub `engines.node` w `package.json`

### `{{PNPM_VERSION}}`
Major wersja pnpm (np. `10`). Musi być spójna z:
- `webapp-docker-templates` Dockerfile ARG `PNPM_VERSION`
- `packageManager` pole w `package.json` (np. `"pnpm@10.11.0"`)

### `{{COVERAGE_THRESHOLD}}`
Minimalne pokrycie linii testów w %. Vitest coverage gate blokuje CI jeśli spadnie poniżej.
Default: `80`. Dla projektów z wysokim ryzykiem (finanse, medical): `90`.

### `{{DEPLOY_BRANCH}}`
Branch triggujący deployment produkcyjny. Default: `main`. Dla gitflow z `release` branch:
podmień na `release`.

### `{{VPS_PROD_RUNNER_LABEL}}`
Label samodzielnie dodany do self-hosted runner przy konfiguracji (`./config.sh --labels`).
Pozwala kierować job `deploy-prod` wyłącznie do konkretnego VPS.

Konwencja: `<project>-prod` lub `vps-<hostname>-prod`.
Przykłady: `demoapp-prod`, `crm-prod`, `vps-warszawa-prod`

### `{{STAGING_URL}}`
Pełny URL środowiska staging dla OWASP ZAP baseline scan. **Nigdy URL produkcyjny.**
ZAP generuje traffic wygladający jak atak — na prod = alert u hostingu lub WAF block.

Jeśli brak staging: użyj `http://localhost:3020` z docker compose up w CI job.

### `{{CODEQL_LANGUAGE}}`
Dla Next.js + TypeScript: zawsze `javascript-typescript`. CodeQL obsługuje oba w jednym runner.

### `{{ZAP_RULES_FILE}}`
Opcjonalny. Plik TSV z regułami ZAP do suppression fałszywych pozytywów.
Format: `<id>\tIGNORE\t<comment>`. Jeśli nie istnieje — usuń linię `rules_file_name` z yaml.

---

## Komendy sed-replace (pełny blok)

```bash
PROJECT=demo-app
GHCR_OWNER=logicmorrow
APP_PORT=3020
NODE_VER=22
PNPM_VER=10
RUNNER_LABEL=demoapp-prod
STAGING=https://staging.demoapp.pl

for f in .github/workflows/ci.yml \
          .github/workflows/cd.yml \
          .github/workflows/security.yml \
          .github/dependabot.yml \
          .github/codeql/codeql-config.yml; do
  sed -i \
    -e "s/{{PROJECT_NAME}}/$PROJECT/g" \
    -e "s/{{GHCR_OWNER}}/$GHCR_OWNER/g" \
    -e "s/{{IMAGE_REGISTRY}}/ghcr.io/g" \
    -e "s/{{APP_PORT}}/$APP_PORT/g" \
    -e "s/{{NODE_VERSION}}/$NODE_VER/g" \
    -e "s/{{PNPM_VERSION}}/$PNPM_VER/g" \
    -e "s/{{COVERAGE_THRESHOLD}}/80/g" \
    -e "s/{{DEPLOY_BRANCH}}/main/g" \
    -e "s/{{VPS_PROD_RUNNER_LABEL}}/$RUNNER_LABEL/g" \
    -e "s|{{STAGING_URL}}|$STAGING|g" \
    -e "s/{{CODEQL_LANGUAGE}}/javascript-typescript/g" \
    "$f"
done
```

**Uwaga:** `{{STAGING_URL}}` używa `|` jako separatora w sed (URL zawiera `/`).

---

## Weryfikacja po podmiance

```bash
# Sprawdź czy zostały nierozwiązane placeholdery
grep -r '{{' .github/ && echo "FAIL: unreplaced placeholders" || echo "PASS: all replaced"
```
