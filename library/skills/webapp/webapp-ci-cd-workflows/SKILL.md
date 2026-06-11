---
name: webapp-ci-cd-workflows
description: Templates konkretne 3 GitHub Actions workflows (ci.yml + cd.yml + security.yml) dla webapp produkcyjnych Next.js + pnpm + Docker + ghcr.io + self-hosted runner. Pokrywa zasadę #15 CLAUDE.md punkty 4 (GH Actions), 11 (SBOM cyclonedx-bom), 12 (Trivy container scan). Reconciliation z webapp-cicd-templates (legacy, audit-scope=minimal). Uruchamiaj gdy bootstrap webapp produkcyjnego z audit-ready 18/18.
tools: Read, Write
model: sonnet
version: "1.0.0"
compatible_with: [webapp]
requires: [webapp-docker-templates]
tags: [ci-cd, github-actions, ghcr, trivy, codeql, dependabot, sbom, zap, audit-ready, , zasada-15-pkt-4-11-12]
token_cost: medium
distribution: library/skills/webapp/
last_updated: 2026-05-29
last_reviewed: 2026-05-29
valid_until: 2027-05-29
---

# webapp-ci-cd-workflows

## 1. Purpose

Skill dostarcza **gotowe do podmienienia** szablony trzech GitHub Actions workflows dla webapp produkcyjnych LogicMorrow. Każdy template jest funkcjonalny — używa konwencji `{{VARIABLE_NAME}}` z pełną listą zmiennych w [placeholders-reference.md](./placeholders-reference.md).

**Dla kogo:** każdy nowy webapp produkcyjny (DemoApp, external-crm, przyszłe projekty) oparty o Next.js 14.2 LTS + pnpm 10 + Docker + ghcr.io.

**Powiązanie z zasadą #15:** Pkt 4 (ci.yml + cd.yml + security.yml), Pkt 11 (SBOM cyclonedx-bom → artifact), Pkt 12 (Trivy HIGH/CRITICAL exit-code 1, CodeQL, Dependabot).

Brak tych workflows = BLOKER przy `/pack` dla audit-scope=production.

**Co NIE jest w scope:** Dockerfile/compose → `webapp-docker-templates` | security headers → `webapp-security-hardening` | Caddy → `webapp-reverse-proxy-tls` | backup → `webapp-backup-dr` | observability → `webapp-observability-stack`

---

## 2. Before starting work (cross-agent-learning v1.1.0)

1. **Sprawdź `errors-webapp-ci-cd-workflows.md`** (pełna treść) jeśli istnieje — apply silently.
2. **Przeczytaj ostatnie 3 reflections** z `knowledge-base/reflections/` z `ci-cd` / `github-actions` / `ghcr`.
3. **Przejrzyj `knowledge-base/lessons.jsonl` tail 20** — szczególnie lessons o GitHub Actions, pnpm cache, ghcr.io, self-hosted runner.

Budget: 5k tokenów. Apply silently — nie raportuj, po prostu uwzględnij.

**Znane pułapki:**
- `packages: write` wymaga explicit `permissions:` bloku w workflow (nie jest domyślne).
- Self-hosted runner na VPS musi mieć `docker` i `docker compose` zainstalowane.
- `docker login ghcr.io` w CD: `echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin`.
- `trivy-scan` job musi mieć `needs: [build-and-push]` — inaczej skanuje nieistniejący obraz.
- ZAP baseline scan NIE na prod URL — tylko staging lub localhost.
- `pnpm install --frozen-lockfile` jest kluczowe w CI.

---

## 3. Templates dostarczane

Katalog `templates/`:

| Plik | Opis |
|---|---|
| `ci.yml.template` | GitHub-hosted runner: lint + typecheck + unit-test + e2e + docker-build (no push) |
| `cd.yml.template` | GitHub-hosted build+push ghcr.io + self-hosted runner deploy-prod + healthcheck + rollback |
| `security.yml.template` | Trivy + CodeQL + SBOM cyclonedx-bom + OWASP ZAP baseline + ZAP full weekly |
| `dependabot.yml.template` | `.github/dependabot.yml` — npm + github-actions weekly schedule |
| `codeql-config.yml.template` | `.github/codeql/codeql-config.yml` — security-extended queries |
| `README-reconciliation.md.template` | Reconciliation webapp-cicd-templates DEPRECATED vs ten skill |

---

## 4. Zasada #15 mapping

| Punkt #15 | Wymaganie | Plik w skilla | Status |
|---|---|---|---|
| Pkt 4 | `.github/workflows/ci.yml` | `templates/ci.yml.template` | POKRYTY |
| Pkt 4 | `.github/workflows/cd.yml` | `templates/cd.yml.template` | POKRYTY |
| Pkt 4 | `.github/workflows/security.yml` | `templates/security.yml.template` | POKRYTY |
| Pkt 11 | SBOM `cyclonedx-bom` + upload-artifact | `templates/security.yml.template` job `sbom-generation` | POKRYTY |
| Pkt 12 | Trivy container scan HIGH/CRITICAL exit-code 1 | `templates/security.yml.template` job `trivy-scan` | POKRYTY |
| Pkt 12 | CodeQL static analysis JS/TS | `templates/security.yml.template` job `codeql` | POKRYTY |
| Pkt 12 | Dependabot security updates | `templates/dependabot.yml.template` | POKRYTY |

**ci.yml wymaga:** `pnpm install --frozen-lockfile` + typecheck + eslint + vitest coverage ≥`{{COVERAGE_THRESHOLD}}`% + playwright + docker build (no push)

**cd.yml wymaga:** push main → build+push `ghcr.io:sha` → self-hosted runner deploy + healthcheck + rollback on fail

---

## 5. Konwencja placeholderów `{{VAR}}`

Format `{{VARIABLE_NAME}}` — podmiana przez `sed`/`envsubst` przy bootstrapie. Kluczowe 3:

- `{{PROJECT_NAME}}` — slug (lowercase kebab-case), np. `demo-app` — we wszystkich plikach
- `{{GHCR_OWNER}}` — lowercase GitHub org/user, np. `logicmorrow` — we wszystkich plikach
- `{{VPS_PROD_RUNNER_LABEL}}` — label runnera na VPS, np. `demoapp-prod` — w `cd.yml`

Pełna tabela 12 zmiennych, opisy i blok sed-replace: [placeholders-reference.md](./placeholders-reference.md)

**Uwaga spójności:** `{{PROJECT_NAME}}`, `{{APP_PORT}}`, `{{IMAGE_REGISTRY}}`, `{{GHCR_OWNER}}`, `{{NODE_VERSION}}`, `{{PNPM_VERSION}}` muszą być identyczne jak w `webapp-docker-templates`.

---

## 6. Workflow konsumenta (jak użyć)

5 kroków:
1. **cp templates** → `.github/workflows/` + `.github/codeql/`
2. **sed-replace** wszystkich `{{VAR}}` w skopiowanych plikach
3. **GitHub Secrets** — `GITHUB_TOKEN` jest automatyczny (nie dodawaj manualnie); dodaj sekrety aplikacyjne osobno
4. **Self-hosted runner** — zarejestruj na VPS prod z `./config.sh --labels {{VPS_PROD_RUNNER_LABEL}}`; user runnerowy musi być w grupie `docker`
5. **Weryfikacja** — `git push origin main` → sprawdź GitHub Actions (CI zielony, CD deploy PASS)

Pełne komendy bash, debug tips i tabela oczekiwanych wyników: [workflow-konsumenta.md](./workflow-konsumenta.md)

---

## 7. Reconciliation z webapp-cicd-templates

**Stary skill:** `library/skills/webapp/webapp-cicd-templates/` (v1.0) — DEPRECATED dla webapp prod

| Kryterium | webapp-cicd-templates (legacy) | webapp-ci-cd-workflows (ten skill) |
|---|---|---|
| audit-scope | `minimal` | `production` |
| Deploy target | Coolify + ssh-compose | ghcr.io + self-hosted runner |
| Security scans | brak | Trivy + CodeQL + SBOM + ZAP |
| Zasada #15 coverage | brak | Pkt 4, 11, 12 POKRYTE |

**NIE usuwaj webapp-cicd-templates** — legacy projects (CLI/internal/Coolify) go używają. Deprecation timeline: 2031-05-29.

**Migration guide:** rm stare workflows → cp nowe templates → sed-replace → zarejestruj self-hosted runner → dodaj `dependabot.yml` + CodeQL config. Szczegóły w `templates/README-reconciliation.md.template`.

**Auto-discovery TODO :** routing per scope (`production` → ten skill, `minimal` → webapp-cicd-templates).

---

## 8. Przykłady użycia

**Przykład A (DemoApp):** single VPS, `demoapp-prod` runner, port 3020, staging ZAP scan.
Wzorzec: deploy-prod via `runs-on: [self-hosted, demoapp-prod]` + `docker login ghcr.io` + `docker compose pull` + healthcheck.

**Przykład B (monorepo):** pnpm workspace 2 pakiety, `pnpm --filter` per job, jeden pnpm-store cache key, multi-arch build osobnych obrazów.

**Przykład C (rollback emergency):** `docker pull ghcr.io/.../app:PREV_SHA` + `docker compose up -d` — wymaga SHA tag w cd.yml (default w template).

Pełne YAML snippety (dobrze/zle z wyjaśnieniami): [examples.md](./examples.md)

---

## 9. Antywzorce

Top 5 (pełne opisy z dobrze/zle YAML w [anti-patterns.md](./anti-patterns.md)):

1. **Sekrety hardkodowane w workflow YAML** — audit finding CRITICAL, wymaga rotacji
2. **`docker compose pull` bez `docker login ghcr.io`** — cicha porazka, stary obraz na prod
3. **Tylko `:latest` tag w ghcr.io** — rollback niemozliwy bez re-deployu kodu
4. **ZAP full scan w `deploy-prod` job** — 30-60 min blokada + WAF alarm na prod
5. **`trivy-scan` bez `needs: [build-and-push]`** — race condition, skanuje nieistniejacy obraz

---

## 10. Done criteria

- [ ] `ci.yml` skopiowany + sed-replaced → CI PASS (lint + typecheck + unit-test + docker-build)
- [ ] `cd.yml` skopiowany + sed-replaced → CD PASS (build+push ghcr.io + deploy-prod + healthcheck)
- [ ] `security.yml` skopiowany + sed-replaced → Trivy + CodeQL + SBOM artifacts dostepne
- [ ] `dependabot.yml` + `codeql-config.yml` skopiowane + sed-replaced
- [ ] Self-hosted runner zarejestrowany z labelem `{{VPS_PROD_RUNNER_LABEL}}` i statusem Idle
- [ ] `grep -r '{{' .github/` → 0 wynikow (wszystkie placeholdery podmienione)
- [ ] `library-index.json` zaktualizowany z wpisem `webapp-ci-cd-workflows`

**Audit-ready gate (zasada #15 pkt 4, 11, 12):** 3 workflowy obecne + Trivy `--exit-code 1 --severity HIGH,CRITICAL` aktywne + SBOM artifact uploadowany + CodeQL aktywne dla `javascript-typescript`

---

## 11. Powiązania

- `webapp-docker-templates` — **wymagany** (spójność placeholderów `{{PROJECT_NAME}}`, `{{APP_PORT}}`, `{{IMAGE_REGISTRY}}`, `{{GHCR_OWNER}}`, `{{NODE_VERSION}}`, `{{PNPM_VERSION}}`)
- `webapp-security-hardening` — pokrewny (aplikacyjne security headers vs pipeline security scans)
- `webapp-observability-stack` — pokrewny (Sentry config w app vs CI/CD pipeline monitoring)
- `webapp-cicd-templates` — poprzednia wersja (DEPRECATED dla webapp prod, zostaje dla CLI/internal)
- `webapp-reverse-proxy-tls` — pokrewny (Caddy security headers uzupełniają ZAP scan wyniki)
- `quality-checker` — konsument (waliduje zgodność ze standardami skilla)
- `pack-agent` — bloker (audit-scope=production wymaga tego skilla PASS przed `/pack`)

---

## 12. ACTIVITY-LOG template

Konsument tego skilla emituje ACTIVITY-LOG entry po zakończeniu setup CI/CD workflows w docelowym projekcie:

```
ACTIVITY-LOG: {"ts":"<ISO-8601 UTC>","actor":"<consumer-agent-or-main>","action":"ci_cd_workflows_configured","artifact":".github/workflows/","skill":"webapp-ci-cd-workflows","skill_version":"1.0.0","notes":"<liczba workflowow + opis: ci.yml + cd.yml + security.yml + dependabot.yml + codeql config>"}
```

Pola obowiązkowe: `ts`, `actor`, `action`, `artifact`, `skill`, `skill_version`. Pole `notes` — krótkie streszczenie konkretnej konfiguracji (np. `"4 workflowy + 1 codeql config, COVERAGE_THRESHOLD=80, GHCR_OWNER=logicmorrow, VPS_PROD_RUNNER_LABEL=demoapp-prod"`).

Po append do `knowledge-base/activity-log.jsonl` (zasada #10 CLAUDE.md fabryki) lub `.claude/knowledge-base/activity-log.jsonl` (embedded mode w paczce).

---
