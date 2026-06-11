# Branch protection — konfiguracja

Ochrona `main` (i opcjonalnie `develop`) przed bezposrednimi pushami, wymuszenie PR + review + required status checks.

## gh CLI — one-liner

Wymaga `gh` zainstalowanego lokalnie i autoryzacji (`gh auth login`).

### main (obowiazkowy)

```bash
gh api repos/{owner}/{repo}/branches/main/protection \
  --method PUT \
  --header "Accept: application/vnd.github+json" \
  --field required_status_checks='{"strict":true,"contexts":["CI / Lint","CI / Typecheck","CI / Test (Node 20)","CI / Test (Node 22)","CI / Security Audit"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false \
  --field required_linear_history=true
```

### develop (deployment_mode: staged)

```bash
gh api repos/{owner}/{repo}/branches/develop/protection \
  --method PUT \
  --header "Accept: application/vnd.github+json" \
  --field required_status_checks='{"strict":true,"contexts":["CI / Lint","CI / Typecheck","CI / Test (Node 20)","CI / Test (Node 22)"]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":false}' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false
```

Zmien `{owner}/{repo}` na rzeczywiste wartosci, np. `LogicMorrow/my-webapp`.

## GitHub UI — alternatywa

1. Settings → **Branches** → **Add branch protection rule**
2. **Branch name pattern:** `main`
3. Wlacz:
   - [x] Require a pull request before merging
     - Required number of approvals: **1**
     - [x] Dismiss stale pull request approvals when new commits are pushed
   - [x] Require status checks to pass before merging
     - [x] Require branches to be up to date before merging
     - Status checks: `CI / Lint`, `CI / Typecheck`, `CI / Test (Node 20)`, `CI / Test (Node 22)`, `CI / Security Audit`
   - [x] Require linear history
   - [x] Include administrators
   - [ ] Allow force pushes — **wylacz**
   - [ ] Allow deletions — **wylacz**
4. Kliknij **Save changes**

## Required status checks — nazwy z ci.yml

Status check name musi dokladnie odpowiadac nazwie joba w workflow.

Z `ci.yml.template`:
| Check name w branch protection | Job w ci.yml |
|---|---|
| `CI / Lint` | `jobs.lint.name: Lint` |
| `CI / Typecheck` | `jobs.typecheck.name: Typecheck` |
| `CI / Test (Node 20)` | `jobs.test.name: Test (Node 20)` (matrix) |
| `CI / Test (Node 22)` | `jobs.test.name: Test (Node 22)` (matrix) |
| `CI / Security Audit` | `jobs.audit.name: Security Audit` |

Jezeli zmieniasz nazwy jobow w workflow — zaktualizuj rowniez branch protection rules.

## Weryfikacja

```bash
# Sprawdz aktualna konfiguracje
gh api repos/{owner}/{repo}/branches/main/protection

# Proba bezposredniego push na main powinna dac blad
git checkout main
echo "test" >> README.md
git add README.md
git commit -m "test direct push"
git push origin main
# Expected: remote: error: GH006: Protected branch update failed
```

## GitHub Flow — branching model

```
main ←── PR z feature/* lub fix/* (review + CI required)
 └── auto deploy → production (manual approval via environment)

develop (opcjonalne, tylko deployment_mode: staged)
 ├── merge z feature/* (CI required)
 └── auto deploy → staging
```

Brak `develop` przy `deployment_mode: simple` — wszystkie PR wprost do `main`.
