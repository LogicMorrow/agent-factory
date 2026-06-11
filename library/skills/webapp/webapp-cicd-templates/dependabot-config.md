# Dependabot — konfiguracja

Automatyczne aktualizacje zaleznosci npm (pnpm-lock.yaml) i GitHub Actions. Auto-merge tylko dla patch updates po przejsciu CI.

## .github/dependabot.yml

```yaml
version: 2
updates:
  # npm/pnpm packages
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "06:00"
      timezone: "Europe/Warsaw"
    # Grupuj dev-dependencies w jednym PR zamiast N oddzielnych
    groups:
      dev-dependencies:
        dependency-type: "development"
        update-types:
          - "minor"
          - "patch"
    # Limit otwartych PR od dependabota
    open-pull-requests-limit: 10
    # Reviewers
    reviewers:
      - "LogicMorrow"
    # Prefiks commit wiadomosci (Conventional Commits)
    commit-message:
      prefix: "chore(deps)"
      prefix-development: "chore(dev-deps)"
      include: "scope"
    # Pomijaj major updates (czesto breaking changes)
    ignore:
      - dependency-name: "*"
        update-types: ["version-update:semver-major"]

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "06:00"
      timezone: "Europe/Warsaw"
    open-pull-requests-limit: 5
    reviewers:
      - "LogicMorrow"
    commit-message:
      prefix: "ci(deps)"
```

## Auto-merge patch updates

Dependabot nie ma auto-merge wbudowanego w konfiguracje YAML — wymaga osobnego workflow lub GitHub settings.

**Opcja A — GitHub repo settings** (prostsze):
Settings → General → Auto-merge → Enable, potem Dependabot PRs moga byc auto-merge gdy CI zielone.

**Opcja B — workflow auto-merge** (pelna kontrola):

Utowrz `.github/workflows/dependabot-auto-merge.yml`:

```yaml
name: Dependabot auto-merge

on: pull_request

permissions:
  contents: write
  pull-requests: write

jobs:
  auto-merge:
    runs-on: ubuntu-latest
    if: github.actor == 'dependabot[bot]'
    steps:
      - name: Check update type
        id: metadata
        uses: dependabot/fetch-metadata@v2
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}

      - name: Auto-merge patch updates
        # Auto-merge tylko patch — minor i major wymagaja recenzji
        if: steps.metadata.outputs.update-type == 'version-update:semver-patch'
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Wazne: auto-merge uruchamia sie tylko po przejsciu required status checks (CI lint/typecheck/test).

## Ryzyka i mitygacje

**R: patch moze byc breaking (rzadko)** — statystycznie < 2% package'ow lamie semver przy patch. Mitygacja: CI musi byc zielone przed auto-merge (required status checks w branch protection — patrz `branch-protection.md`).

**R: dev-dependencies group PR moze byc duzy** — wiele deps naraz. Akceptowalne, bo dev deps nie trafiaja na produkcje. Jesli PR jest zbyt duzy, mozna usunac grupowanie (kazdej dep osobny PR).

## Weryfikacja

```bash
# Sprawdz czy dependabot widzi konfiguracje
# W GitHub: Insights → Dependency graph → Dependabot → Recent update jobs
# Lub: Settings → Code security and analysis → Dependabot alerts
```

Po pierwszym tygodniu w poniedzialek rano powinny pojawic sie pierwsze PR od dependabota.
