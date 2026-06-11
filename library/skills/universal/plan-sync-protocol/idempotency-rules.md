# idempotency-rules.md

Reguly idempotencji dla `plan-sync-protocol`. Konsumowane przez agenta `plan-progress-tracker` (E3).

---

## Klucz unikalnosci

```
(absolute_plan_path, stage_id)
```

Przyklad: `("~/your-app/docs/plans/2026-01-01-example-roadmap.md", "B5")`

Hash SHA-256 klucza moze byc uzyty do cache'owania, ale glowny mechanizm to **deterministyczny re-read pliku** przed edycja — nie ma zewnetrznego state.

---

## Algorytm pre-check (PRZED edycja pliku planu)

```
read plan_file
locate section "## Etapy" (find heading, scope subsequent lines until next "##")
within that section, find row matching:
  regex: ^\|\s*<stage_id>\s*\|

IF row not found:
  return {status: error, reason: "stage_not_found"}
  exit

IF row contains "✅":
  return {status: noop, reason: "already_completed"}
  exit

ELSE:
  proceed to update
```

**Uwagi:**
- Regex escape: stage_id moze zawierac `.` i litery (`E1.a`, `E5b`) — uzyj `re.escape` lub odpowiednika w bash (`grep -F` dla fixed string)
- Scope sekcji `## Etapy`: wiersze od linii po `## Etapy` az do nastepnego `^## ` (nie wlacznie). Ignoruj tabele z innych sekcji (Risk-matrix, Contingency).
- Jesli plan nie ma sekcji `## Etapy`: return `{status: error, reason: "missing_etapy_section"}`

---

## Algorytm post-check (PO edycji pliku planu)

Po wykonaniu `Edit` wiersza:

```
re-read plan_file
count rows matching ^\|\s*<stage_id>\s*\|.*✅ in section "## Etapy"

IF count == 1:
  OK — idempotent, proceed to step (b)

IF count == 0:
  ERROR — edit nie zapikal sie poprawnie
  return {status: error, reason: "edit_not_persisted"}

IF count > 1:
  CRITICAL — duplikat wiersza
  revert last edit (przywroc poprzedni stan wiersza)
  return {status: error, reason: "duplicate_row_detected"}
```

---

## Activity-log idempotencja

PRZED appendem do `activity-log.jsonl`:

```bash
grep -qF '"artifact":"plans/<slug>.md::<stage_id>"' activity-log.jsonl
```

Jesli match (exit 0): pominij append — wpis juz istnieje. NIE duplikuj.
Jesli brak matcha (exit 1): kontynuuj append.

`<slug>` = basename pliku planu bez rozszerzenia, np. `2026-05-06--plan-sync-multi`.

**Uwaga path resolution:** `activity-log.jsonl` szukaj wedlug konwencji projektu:
- Fabryka: `<project-root>/knowledge-base/activity-log.jsonl`
- CRM / inne projekty z `docs/`: `<project-root>/docs/activity-log.jsonl`
- Fallback: agent E3 implementuje auto-detection (`find <project-root> -name activity-log.jsonl -maxdepth 3`)

---

## Race condition handling

Dwa rownoleg wywolania `plan-progress-tracker` dla tego samego `(plan, stage)`:

1. **Pre-check** (oba czytaja plik) — oba widza brak `✅`, oba decyduja proceed
2. **Edit** — pierwsze wywolanie zapisuje `✅`, drugie rowniez probuje

Mechanizm defensywny (delegowany do implementacji agenta E3):
- Uzyj `flock` lub re-read po edit (post-check)
- Post-check wykryje `count > 1` jesli oba zapisaly → rollback
- Alternatywa: atomic write przez temp file + rename (`mv tmp plan_file`)

Skill definiuje **kontrakty** (pre/post-check), agent E3 decyduje **implementacje** (flock vs re-read).

---

## Statusy zwracane

| Status | Kiedy | Akcja agenta |
|---|---|---|
| `ok` | Pierwszy zapis, wszystkie 3 miejsca zaktualizowane | Zwroc `{status: completed}` |
| `noop` | Wiersz juz ma `✅` | Zwroc `{status: noop, reason: "already_completed"}`, zero modyfikacji |
| `error` | Blad (stage not found, edit fail, slot invalid, etc.) | Zwroc `{status: error, reason: "...", step: "..."}` |
| `pending_user_action` | Conflict wykryty (count > 1), wymaga recznej weryfikacji | Zwroc `{status: pending_user_action, reason: "duplicate_row_detected"}` |

---

## Trzy przyklady

### Przyklad 1 — pierwszy zapis (status: ok)

```
Plan: plans/dummy-test.md, stage: E1
Pre-check: wiersz `| E1 | ... |  |` — brak ✅ → proceed
Edit: zmien kolumne Status na `✅ 2026-05-07 / commit abc123 / @plan-progress-tracker`
Post-check: count = 1 → OK
Activity-log grep: brak matcha → append
next-session-1.md: E1 przesuniete do "Zamkniete"
Return: {status: "completed", plan: "plans/dummy-test.md", stage: "E1", commit: "abc123", slot: 1}
```

### Przyklad 2 — retry (status: noop)

```
Plan: plans/dummy-test.md, stage: E1 (juz zaktualizowany z Przykladu 1)
Pre-check: wiersz `| E1 | ... | ✅ 2026-05-07 / commit abc123 / @plan-progress-tracker |`
           → zawiera ✅ → NOOP
Return: {status: "noop", reason: "already_completed"}
Pliki: bez zmian. Activity-log: bez nowego wpisu.
```

### Przyklad 3 — conflict (status: pending_user_action)

```
Plan: plans/dummy-test.md, stage: E2
Scenariusz: dwa agenty uruchomily sie rownolegla (race condition)
Pre-check (oba): brak ✅ → oba decyduja proceed
Edit (agent A): zapisuje ✅ dla E2
Edit (agent B): rowniez probuje zapisac ✅ dla E2 (nie wie o A)
Post-check (agent B): count = 2 dla E2 → CONFLICT
Akcja (agent B): revert edit agenta B, log conflict
Return: {status: "pending_user_action", reason: "duplicate_row_detected",
         hint: "Manually verify plans/dummy-test.md row E2, remove duplicate ✅"}
```

---

## Edge cases

| Edge case | Zachowanie |
|---|---|
| `stage_id` z kropka (`E1.a`) | Uzyj `grep -F "| E1.a |"` (fixed string) zamiast regex — unikaj false match `E1a` |
| Plan ma dwie tabele (`## Etapy` + `## Risk-matrix`) | Match TYLKO w sekcji `## Etapy` — zakoncz scope na nastepnym `## ` |
| `stage_id` pojawia sie w sub-tabeli (nested) | Match na pierwszym wierszu w sekcji `## Etapy` z tym id — sub-tabele ignorowane (nie maja standardowego formatu) |
| Plan bez sekcji `## Etapy` | `{status: error, reason: "missing_etapy_section"}` — nie modyfikuj pliku |
| Plik planu nie istnieje | `{status: error, reason: "plan_file_not_found"}` |
| `activity-log.jsonl` nie istnieje | Stworz pusty plik, nastepnie append — nie blokuj (c) z powodu braku pliku |
