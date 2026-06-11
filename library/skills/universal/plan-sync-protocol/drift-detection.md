# drift-detection.md

Specyfikacja wykrywania rozjazdu miedzy tabela statusu planu a rzeczywistymi commitami w git.
Uzywana przez agenta `plan-progress-tracker` (E3) jako sanity check przed edycja, oraz manualne przez operatora.

---

## Problem

Plan mowi jedno, git mowi drugie. Przyklad z incydentu 2026-05-01..2026-05-06:

```
plan 2026-01-01-example-roadmap.md, sekcja B5: "✅ ADR-004"
reflection 2026-05-06: "ADR-005"
```

5 dni rozjazdu, wykryty dopiero podczas recznej analizy. Bez skryptu drift-detection ten typ bledu
pozostaje niewidoczny az do kolizji (agent robi E2 bo mysli ze nieukonczone, commit juz istnieje).

---

## Dwa typy dryfu

### Type 1: ghost_completion

**Definicja:** Tabela planu mowi `✅` + `commit <hash>`, ale `git log` NIE zawiera tego commita.

**Przyklad:**
```
Plan: | E3 | plan-progress-tracker agent | ... | ✅ 2026-05-07 / commit deadbee / @plan-progress-tracker |
Git:  git log --oneline | grep deadbee → (brak output)
DRIFT [type=ghost_completion]: E3 marked ✅ with commit deadbee, but commit not in git log
```

**Mozliwe przyczyny:**
- Commit zostal wpisany z literowka
- Commit istnieje na innym branchu/repo
- Plan zaktualizowany ale commit nigdy nie nastapil (pre-commit sync error)
- Stary commit squashed lub rebase'owany

### Type 2: missing_sync

**Definicja:** Commit istnieje w `git log` z message wspominajacym `stage_id`, ale tabela planu NIE ma `✅` dla tego stage.

**Przyklad:**
```
Git:  git log --oneline → "fe3a070 feat(library): E1 multi-plan-workflow skill gotowy"
Plan: | E1 | multi-plan-workflow skill | ... |  |  ← brak ✅
DRIFT [type=missing_sync]: commit mentions E1 but plan table lacks ✅
```

**Mozliwe przyczyny:**
- Agent wykonał prace i zrobil commit ale nie wywolal `plan-progress-tracker`
- operator recznie commital poza pipeline'em agenta
- Sesja zakonczyla sie przed sync (crash, timeout)

---

## Skrypt check-plan-drift.sh

> **Disclaimer:** Przejrzyj skrypt przed uruchomieniem na produkcyjnym planie.
> Skrypt jest read-only (grep + git log) — nie modyfikuje zadnych plikow.

```bash
#!/usr/bin/env bash
# check-plan-drift.sh — wykrywa ghost_completion i missing_sync
# Uzycie: bash check-plan-drift.sh <plan-path> [project-root]
# Exit: 0 = brak dryfu, 1 = ≥1 dryf wykryty

set -euo pipefail

PLAN_FILE="${1:-}"
PROJECT_ROOT="${2:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DRIFT_COUNT=0

if [[ -z "$PLAN_FILE" ]]; then
  echo "Uzycie: bash check-plan-drift.sh <plan-path> [project-root]" >&2
  exit 2
fi

if [[ ! -f "$PLAN_FILE" ]]; then
  echo "ERROR: plik planu nie istnieje: $PLAN_FILE" >&2
  exit 2
fi

# ---- TYPE 1: ghost_completion ----
# Szukaj wierszy tabeli z ✅ i commit hash

while IFS= read -r row; do
  stage_id=$(echo "$row" | awk -F'|' '{print $2}' | xargs)
  commit=$(echo "$row" | grep -oE 'commit[[:space:]]+[a-f0-9]{7,40}' | awk '{print $2}' | head -1)

  if [[ -z "$commit" ]]; then
    continue
  fi

  if ! git -C "$PROJECT_ROOT" log --oneline 2>/dev/null | grep -q "^$commit"; then
    echo "DRIFT [type=ghost_completion]: $stage_id marked ✅ with commit $commit, but commit not in git log" >&2
    DRIFT_COUNT=$((DRIFT_COUNT + 1))
  fi
done < <(grep -E '^\|.*✅.*commit[[:space:]]+[a-f0-9]{7,40}' "$PLAN_FILE" || true)

# ---- TYPE 2: missing_sync ----
# Szukaj stage_id z sekcji ## Etapy, sprawdz czy commit wspomina id ale tabela bez ✅

IN_ETAPY=false

while IFS= read -r line; do
  if echo "$line" | grep -qE '^## Etapy'; then
    IN_ETAPY=true
    continue
  fi
  if $IN_ETAPY && echo "$line" | grep -qE '^## '; then
    break
  fi
  if $IN_ETAPY; then
    stage_id=$(echo "$line" | grep -oE '^\|\s*[A-Z][0-9a-z.]+' | sed 's/^[|[:space:]]*//')
    if [[ -z "$stage_id" ]]; then
      continue
    fi
    # Sprawdz czy ten stage juz ma ✅ w tabeli
    if echo "$line" | grep -q '✅'; then
      continue
    fi
    # Sprawdz czy jakis commit w git log wspomina ten stage_id
    if git -C "$PROJECT_ROOT" log --oneline 2>/dev/null | grep -qE "\b${stage_id}\b"; then
      echo "DRIFT [type=missing_sync]: commit mentions $stage_id but plan table lacks ✅" >&2
      DRIFT_COUNT=$((DRIFT_COUNT + 1))
    fi
  fi
done < "$PLAN_FILE"

# ---- Wynik ----

if [[ $DRIFT_COUNT -eq 0 ]]; then
  echo "OK: brak dryfu w $PLAN_FILE" >&2
  exit 0
else
  echo "FAIL: $DRIFT_COUNT dryf(ow) wykrytych w $PLAN_FILE" >&2
  exit 1
fi
```

---

## Output skryptu

Kazdy dryf = 1 linia na stderr w formacie:
```
DRIFT [type=<ghost_completion|missing_sync>]: <stage_id> <opis>
```

Podsumowanie na koncu:
```
OK: brak dryfu w <plan-path>
```
lub:
```
FAIL: 3 dryf(ow) wykrytych w <plan-path>
```

**Exit codes:**
- `0` — brak dryfu (plan spojny z git)
- `1` — ≥1 dryf wykryty
- `2` — blad invokacji (brak argumentu, plik nie istnieje)

---

## Manualne uruchomienie

```bash
# Konkretny plan (fabryka)
bash check-plan-drift.sh knowledge-base/plans/2026-05-06--plan-sync-multi.md

# Konkretny plan (CRM) — inny project root
bash check-plan-drift.sh \
  ~/your-app/docs/plans/2026-01-01-example-roadmap.md \
  ~/external-crm

# Z jawnym project root (gdy cwd != project root)
bash check-plan-drift.sh /abs/path/to/plan.md /abs/path/to/project-root
```

**Test backreference (incydent ADR-004 vs ADR-005):**
```bash
bash check-plan-drift.sh \
  ~/your-app/docs/plans/2026-01-01-example-roadmap.md \
  ~/external-crm
# Oczekiwane: DRIFT [type=...]: B5 ...
```

---

## Integracja z plan-progress-tracker

Agent E3 (`plan-progress-tracker`) wywoluje skrypt PRZED edycja jako sanity check:

```
1. bash check-plan-drift.sh <plan_path> → exit code?
2. exit 0 → kontynuuj normalny flow sync
3. exit 1 → emit warning w output agenta:
   "⚠️ Drift wykryty przed sync — szczegoly powyzej. Kontynuowac mimo to? [y/N]"
   (jesli agent autonomiczny — kontynuuj ale dodaj note do activity-log entry)
4. exit 2 → blad skryptu → abort sync, zwroc {status: error, reason: "drift_check_failed"}
```

Skrypt jest read-only — wywolanie go przed edycja jest bezpieczne.

---

## Ograniczenia

| Ograniczenie | Skutek | Workaround |
|---|---|---|
| False-positive jezeli commit message nie zawiera stage_id | `missing_sync` nie zostanie wykryty | Stosuj konwencje message `feat(...): <stage_id> ...` |
| Nie wykrywa semantycznego dryfu | Etap "zrobiony" ale inaczej niz opisane — wymaga ludzkiego review | Czytaj plany po sesji |
| Nie obsluguje multi-repo | Plan w fabryce, commit w projekcie klienta → ghost_completion false positive | Uzyj `--project-root=<sciezka>` do wlasciwego repo |
| Regex `^\|.*✅.*commit\s+<hash>` — zaklada format skilla | Jesli ktos wpisal ✅ bez "commit <hash>" — ghost_completion nie wykryty | Wymuszaj format wiersza z SKILL.md sekcja 2a |
| git log bez `--all` — sprawdza tylko current branch history | Commit na innym branchu → ghost_completion false positive | Mozna rozszerzyc o `git log --all` w przyszlosci |
