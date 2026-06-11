# CI Integration — docs-lint job

Instrukcja podpięcia walidacji dokumentacji do CI. Trzy warianty:
1. **Patch** — wklejenie job `docs-lint` do istniejącego `ci.yml` (np. z `webapp-cicd-templates`)
2. **Standalone** — osobny workflow dla projektów bez `webapp-cicd-templates`
3. **Retrofit** — jak podpiąć dla istniejącego repo z historią bez docs

> **Ważne:** Ten plik NIE modyfikuje `ci.yml.template` z `webapp-cicd-templates`. To decyzja dewelopera czy włączyć `docs-lint` do swojego pipeline.

---

## Runtime

**Domyślny:** bash + `mikefarah/yq-action@v4`
- Zero Node deps — działa w projektach non-Node (CLI, automation, ai-agents)
- Wymaga GitHub Actions

**Alternatywa (Node):** patrz sekcja "Node runtime fallback" na końcu pliku.
**GitLab CI / Jenkins:** patrz sekcja "Non-GitHub runners".

---

## Wariant 1: Patch do istniejącego ci.yml

Wklej poniższy job na końcu pliku `ci.yml` (obok `lint`, `test`, `audit`):

```yaml
  # ─────────────────────────────────────────────────────────
  # docs-lint: walidacja dokumentacji technicznej
  # Hard gates (exit 1): brak ADR status, brak runbook severity, broken links, schema bez ERD
  # Soft gates (exit 2): stare last_reviewed, orphan ADR, stary docs/README.md
  # Bypass: label 'emergency-merge' + 'TECH-DEBT: <opis>' w PR body
  # Runtime: bash + yq (mikefarah/yq-action@v4)
  # ─────────────────────────────────────────────────────────
  docs-lint:
    name: Docs Lint
    runs-on: ubuntu-latest
    # Uruchamiaj tylko przy PR (nie na push do main po merge)
    if: github.event_name == 'pull_request'

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # potrzebne dla git log (sprawdzenie daty ostatniej zmiany)

      - name: Install yq
        uses: mikefarah/yq-action@v4
        with:
          cmd: yq --version

      - name: Run docs validation
        id: docs_validate
        run: |
          chmod +x ./assets/scripts/validate-docs.sh
          ./assets/scripts/validate-docs.sh
        env:
          PR_BODY: ${{ github.event.pull_request.body }}
          PR_LABELS: ${{ join(github.event.pull_request.labels.*.name, ',') }}
          CHANGED_FILES: ${{ steps.changed.outputs.all_changed_files }}

      - name: Check for bypass
        if: failure && steps.docs_validate.outcome == 'failure'
        run: |
          if echo "${{ github.event.pull_request.labels.*.name }}" | grep -q "emergency-merge"; then
            if echo "${{ github.event.pull_request.body }}" | grep -q "TECH-DEBT:"; then
              echo "::warning::Bypass emergency-merge aktywny. Pamiętaj o wpisie w docs/TECH_DEBT.md"
              exit 0
            else
              echo "::error::Label emergency-merge wymaga 'TECH-DEBT: <opis>' w PR body"
              exit 1
            fi
          fi

      - name: Annotate soft warnings
        if: steps.docs_validate.outcome == 'success'
        run: |
          # Soft warnings nie blokują — pokazują się jako annotations
          ./assets/scripts/validate-docs.sh --soft-only 2>&1 | while read line; do
            echo "::warning::$line"
          done
        continue-on-error: true
```

**Gdzie wkleić w ci.yml z webapp-cicd-templates:** po job `audit`, przed końcem pliku. Opcjonalnie dodaj do `needs: [lint, typecheck, test, audit]` jeśli chcesz zależności.

---

## Wariant 2: Standalone workflow

Utwórz `.github/workflows/docs-lint.yml`:

```yaml
name: Docs Lint

on:
  pull_request:
    branches: [main, develop]
    # Opcjonalnie: uruchamiaj tylko gdy zmieniony docs/
    # paths:
    #   - 'docs/**'
    #   - 'schema.sql'
    #   - 'migrations/**'

concurrency:
  group: docs-lint-${{ github.ref }}
  cancel-in-progress: true

jobs:
  docs-lint:
    name: Docs Validation
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install yq
        uses: mikefarah/yq-action@v4
        with:
          cmd: yq --version

      - name: Validate docs
        run: |
          chmod +x ./assets/scripts/validate-docs.sh
          ./assets/scripts/validate-docs.sh
        env:
          PR_BODY: ${{ github.event.pull_request.body }}
          PR_LABELS: ${{ join(github.event.pull_request.labels.*.name, ',') }}

      - name: Bypass check
        if: failure
        run: |
          LABELS="${{ join(github.event.pull_request.labels.*.name, ',') }}"
          BODY="${{ github.event.pull_request.body }}"
          if [[ "$LABELS" == *"emergency-merge"* ]] && echo "$BODY" | grep -q "TECH-DEBT:"; then
            echo "::warning::Bypass aktywny. Dodaj wpis do docs/TECH_DEBT.md po merge."
            exit 0
          fi
          exit 1
```

---

## Wariant 3: Retrofit istniejącego repo

Dla repozytoriów z historią bez `docs/` — stopniowe wdrożenie:

### Krok 1 — Uruchom w trybie "warn-only"

Tymczasowo zmień skrypt na soft-only (nie blokuje):

```yaml
      - name: Validate docs (warn-only retrofit)
        run: |
          chmod +x ./assets/scripts/validate-docs.sh
          ./assets/scripts/validate-docs.sh --warn-only 2>&1 | while read line; do
            echo "::warning::$line"
          done
        continue-on-error: true
```

### Krok 2 — Stwórz docs/README.md

Minimalny plik wymagany przez hard gate #3:

```bash
mkdir -p docs/adr docs/runbooks
cp <skill-path>/templates/docs-readme-template.md docs/README.md
# Uzupełnij podstawowe informacje
git add docs/ && git commit -m "docs: init docs structure (retrofit)"
```

### Krok 3 — Retrospektywne ADR-y

Dla każdej kluczowej decyzji przeszłości:
```bash
cp <skill-path>/templates/adr-template.md docs/adr/0001-<nazwa>.md
# Wypełnij z adnotacją "ADR retroaktywny, decyzja faktycznie podjęta YYYY-MM-DD"
```

### Krok 4 — Włącz hard gates

Po utworzeniu podstawowej struktury usuń `continue-on-error: true`.

---

## Node runtime fallback

Dla środowisk bez `mikefarah/yq` (GitLab CI, Jenkins, custom runners):

Zastąp krok `Install yq` + skrypt bash alternatywą Node:

```yaml
      - name: Validate docs (Node)
        run: |
          node -e "
          const fs = require('fs');
          const path = require('path');
          const yaml = require('js-yaml');  // npm install -g js-yaml lub w devDeps

          // Załaduj ADR-y i sprawdź front-matter
          const adrDir = 'docs/adr';
          if (!fs.existsSync(adrDir)) { console.warn('WARN: docs/adr/ nie istnieje'); process.exit(2); }

          const adrs = fs.readdirSync(adrDir).filter(f => f.endsWith('.md'));
          let hardFail = false;

          for (const adr of adrs) {
            const content = fs.readFileSync(path.join(adrDir, adr), 'utf8');
            const match = content.match(/^---\n([\s\S]*?)\n---/);
            if (!match) { console.error('FAIL: Brak front-matter w ' + adr); hardFail = true; continue; }
            const fm = yaml.load(match[1]);
            if (!['proposed','accepted','deprecated'].includes((fm.status||'').split('-')[0])) {
              console.error('FAIL: Nieprawidłowy status w ' + adr + ': ' + fm.status);
              hardFail = true;
            }
          }
          process.exit(hardFail ? 1 : 0);
          "
```

Wymaga: `js-yaml` w `devDependencies` lub globalnie. Pełny port skryptu bash → Node nie jest dostarczany w tym skillu (zbyt projektowo-specyficzny). Podstawowy hard gate #1 powyżej jako punkt startowy.

---

## Non-GitHub runners (GitLab CI, Jenkins)

`validate-docs.sh` to czysty bash + `yq`. Wymagania środowiskowe:
- `bash` ≥4
- `yq` v4 (`brew install yq` / `snap install yq` / binary release z github.com/mikefarah/yq)
- `git` (dla sprawdzania dat zmian plików)

```bash
# GitLab CI — przykład job
docs-lint:
  stage: test
  image: ubuntu:22.04
  before_script:
    - apt-get update -q && apt-get install -y git wget
    - wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    - chmod +x /usr/local/bin/yq
  script:
    - chmod +x ./assets/scripts/validate-docs.sh
    - ./assets/scripts/validate-docs.sh
  only:
    - merge_requests
```
