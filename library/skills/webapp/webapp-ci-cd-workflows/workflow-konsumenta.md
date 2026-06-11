# Workflow konsumenta — webapp-ci-cd-workflows

Pełny przewodnik: od skopiowania templates do weryfikacji działających pipelines CI/CD.

---

## Krok 1 — Kopiuj templates

```bash
mkdir -p .github/workflows .github/codeql

cp library/skills/webapp/webapp-ci-cd-workflows/templates/ci.yml.template \
   .github/workflows/ci.yml

cp library/skills/webapp/webapp-ci-cd-workflows/templates/cd.yml.template \
   .github/workflows/cd.yml

cp library/skills/webapp/webapp-ci-cd-workflows/templates/security.yml.template \
   .github/workflows/security.yml

cp library/skills/webapp/webapp-ci-cd-workflows/templates/dependabot.yml.template \
   .github/dependabot.yml

cp library/skills/webapp/webapp-ci-cd-workflows/templates/codeql-config.yml.template \
   .github/codeql/codeql-config.yml
```

Opcjonalnie (dla audytorów i nowych developerów):
```bash
cp library/skills/webapp/webapp-ci-cd-workflows/templates/README-reconciliation.md.template \
   .github/workflows/README-reconciliation.md
```

---

## Krok 2 — Podmień zmienne (sed-replace)

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

# Weryfikacja braku nierozwiązanych placeholderów
grep -r '{{' .github/ && echo "FAIL: unreplaced placeholders" || echo "PASS"
```

Pełna lista zmiennych z opisami: [placeholders-reference.md](./placeholders-reference.md)

---

## Krok 3 — Skonfiguruj GitHub Secrets

W repozytorium: **Settings → Secrets and variables → Actions**

| Secret | Wartość | Użycie |
|---|---|---|
| `GITHUB_TOKEN` | automatyczny (GH Actions) | ghcr.io login, packages:write |

`GITHUB_TOKEN` jest wstrzykiwany automatycznie — **nie dodawaj go manualnie** do secrets.

Workflow `cd.yml` wymaga explicit `permissions` bloku (już zawarty w template):
```yaml
permissions:
  packages: write
  contents: read
```

Dla self-hosted runner na VPS: żaden secret SSH key nie jest potrzebny. Runner działa
jako daemon na VPS i ma lokalny dostęp do `docker compose`. To jest celowy design
eliminujący wyciek kluczy SSH przez GH Actions log injection.

Dodatkowe secrets aplikacyjne (DB password, Sentry DSN itp.) konfigurujesz osobno
i referencujesz jako `${{ secrets.SECRET_NAME }}` w workflow — nie hardkoduj wartości.

---

## Krok 4 — Zarejestruj self-hosted runner na VPS prod

Wymagania wstępne na VPS:
- `docker` i `docker compose` zainstalowane i dostępne dla usera runnerowego
- User runnerowy w grupie `docker` (`sudo usermod -aG docker <runner-user>`)

```bash
# Na VPS prod (jako user z dostępem do docker)
mkdir -p ~/actions-runner && cd ~/actions-runner

# Download runner (sprawdź aktualną wersję: github.com/actions/runner/releases)
curl -o actions-runner-linux-x64-2.317.0.tar.gz \
  -L https://github.com/actions/runner/releases/download/v2.317.0/actions-runner-linux-x64-2.317.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.317.0.tar.gz

# Wygeneruj token rejestracyjny:
# GitHub repo → Settings → Actions → Runners → New self-hosted runner → skopiuj token

# Konfiguruj runner
./config.sh \
  --url https://github.com/LogicMorrow/{{PROJECT_NAME}} \
  --token <TOKEN_Z_GH_UI> \
  --labels {{VPS_PROD_RUNNER_LABEL}} \
  --name vps-prod-runner \
  --unattended

# Zainstaluj i uruchom jako systemd service
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

Weryfikacja:
```bash
# VPS: sprawdź czy runner jest IDLE (gotowy)
sudo ./svc.sh status
# GitHub UI: repo → Settings → Actions → Runners → powinien być "Idle"
```

Uwaga: token rejestracyjny jest jednorazowy i wygasa po 1h. Jeśli wygasł — wygeneruj nowy
w GitHub UI.

---

## Krok 5 — Weryfikacja pipeline

```bash
git add .github/
git commit -m "ci: add GitHub Actions workflows (ci/cd/security) + dependabot"
git push origin main
```

**Oczekiwane zachowanie po push:**

| Event | Workflow | Oczekiwany rezultat |
|---|---|---|
| `push` na dowolny branch | `ci.yml` | lint + typecheck + vitest + playwright + docker-build PASS |
| `push` na `main` | `cd.yml` | build+push ghcr.io + deploy-prod + healthcheck PASS |
| Harmonogram (daily) | `security.yml` | trivy-scan + zap-baseline (pierwsze uruchomienie może być `workflow_dispatch`) |
| Harmonogram (weekly) | `security.yml` | codeql + sbom-generation + zap-full |
| `pull_request` na `main` | `ci.yml` | jak wyżej — gate przed merge |

**Debug CI fail:**
- `pnpm install` fail → sprawdź czy `pnpm-lock.yaml` jest w repo i aktualny
- `docker build` fail → sprawdź czy `Dockerfile` jest w root projektu
- `deploy-prod` fail → sprawdź logi runnera: `sudo journalctl -u actions.runner.* -n 50`
- `trivy-scan` fail HIGH/CRITICAL → sprawdź `trivy image --severity HIGH,CRITICAL ghcr.io/...`

---

## Krok 6 — Emit ACTIVITY-LOG (po zakończeniu setup)

Po zakończeniu setup CI/CD wyemituj wpis do activity-log (patrz sekcja 12 SKILL.md).
