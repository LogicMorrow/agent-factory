---
name: plan-sync-protocol
version: "1.0.0"
type: skill
category: universal
description: "Use after completing any stage of a plan in `plans/` directory. Enforces 3-place sync (plan file + next-session-{slot}.md + activity-log.jsonl) with idempotency. Prevents plan drift (plan says X, reality says Y)."
compatible_with: [universal]
requires: [multi-plan-workflow]
tags: [planning, plan-sync, idempotency, drift-detection, universal]
token_cost: medium
files:
  - SKILL.md
  - idempotency-rules.md
  - drift-detection.md
---

# plan-sync-protocol

Protokol synchronizacji stanu planu po wykonanym etapie. Powstal po incydencie 2026-05-01..2026-05-06:
plan `2026-01-01-example-roadmap.md` mowil "B5 → ADR-004", reflection 2026-05-06 mowil "ADR-005"
— 5 dni rozjazdu bez wykrycia. Layered defense: **skill = intencja, agent = executor, hook = soft-reminder.**

## 1. Kiedy uruchomic

**Uruchamiaj gdy:**
- Kończysz etap planu z katalogu `plans/` (dowolnego projektu)
- Agent lub operator wykonal prace która powinna byc odnotowana w tabeli statusu planu
- Hook `post-stage-update-plan.sh` emituje reminder na stderr po edycji pliku w `plans/`
- Po manualnym `git commit` poza pipeline'em agenta (etap wykonany "reczne")
- Po crash agenta w srodku etapu — sprawdz co sie dokonalo, domknij recznie przez `plan-progress-tracker`

**NIE uruchamiaj gdy:**
- Plik planu jest poza allowlist katalogów (patrz sekcja 6) — zwroc `rejected_path`
- Sesja jest bez aktywnego planu (exploration, ad-hoc spike)
- Chcesz zarzadzac slotami `next-session-*.md` — to zakres skilla `multi-plan-workflow`

---

## 2. Trzy miejsca synchronizacji (mandatory, w tej kolejnosci)

Po kazdym wykonanym etapie ZAWSZE trzy miejsca — w stalej kolejnosci (a) → (b) → (c):

### (a) Plan file — edit wiersza tabeli statusu

Format wiersza w tabeli `## Etapy`:

```
| <id> | <tytul> | ... | ✅ <ISO-date> / commit <hash> / @<owner-agent> |
```

Przyklad:

```
| E1 | multi-plan-workflow skill | ... | ✅ 2026-05-07 / commit fe3a070 / @plan-progress-tracker |
```

Zasady:
- ISO-date: `YYYY-MM-DD` (bez godziny)
- commit hash: min 7 znakow hex, max 40
- `@<owner-agent>`: nazwa agenta ktory wykonal aktualizacje (np. `@plan-progress-tracker`, `@manual`)
- Match wiersza: regex `^\|\s*<stage_id>\s*\|` w sekcji `## Etapy` (patrz `idempotency-rules.md`)

### (b) next-session-{slot}.md — przeniesienie etapu

Przenies bullet z `## W trakcie` do `## Zamknięte` z prefixem `[<ISO-date>]`:

```markdown
## Zamknięte
- [2026-05-07] E1 multi-plan-workflow skill
```

`slot` = numer slotu z `multi-plan-workflow` (patrz frontmatter `slot:` pliku `next-session-N.md`).

### (c) activity-log.jsonl — append JSON line

```json
{"ts":"2026-05-07T14:32:00Z","actor":"plan-progress-tracker","action":"stage_completed","artifact":"plans/2026-05-06--plan-sync-multi.md::E1","commit":"fe3a070","slot":1,"notes":"multi-plan-workflow skill gotowy"}
```

Pola wymagane: `ts` (ISO-8601), `actor`, `action: "stage_completed"`, `artifact` (format `plans/<slug>.md::<stage_id>`), `commit`, `slot` (1-3), `notes` (opcjonalne, string).

---

## 3. Sekwencja i obsługa błędów

**ZAWSZE (a) → (b) → (c). Nigdy inaczej.**

| Krok | FAIL → akcja |
|---|---|
| (a) FAIL | Abort. NIE rob (b) ani (c). Zwroc `{status: error, step: "plan_file", reason: ...}` |
| (b) FAIL | Revert (a) jesli mozliwe (przywroc poprzedni stan wiersza). Abort. Zwroc `{status: error, step: "next_session"}` |
| (c) FAIL | Emit warning na stderr. NIE revertuj (a)/(b). Best-effort — plan i next-session sa juz zaktualizowane, log to tylko audit trail. Zwroc `{status: partial, step: "activity_log_failed"}` |

---

## 4. Statusy zwracane (JSON output)

Kazde wywolanie `plan-progress-tracker` konczy sie jednym z:

| Status | Znaczenie |
|---|---|
| `completed` | Wszystkie 3 miejsca zaktualizowane pomyslnie |
| `noop` | Etap juz mial ✅ — zadna modyfikacja (idempotentne) |
| `rejected_path` | Plik planu poza allowlist — zadna modyfikacja |
| `error` | Blad podczas wykonania — patrz `reason` i `step` |
| `partial` | (a)+(b) OK, (c) FAIL — ostrzezenie, nie blad krytyczny |

---

## 5. Idempotencja

Szczegoly: `idempotency-rules.md`

**Summary:** klucz unikalnosci = `(absolute_plan_path, stage_id)`.

Przed edycja:
1. Read plan file
2. Znajdz wiersz `^\|\s*<stage_id>\s*\|` w sekcji `## Etapy`
3. Jesli wiersz zawiera `✅` → return `{status: noop, reason: "already_completed"}` — exit, zero modyfikacji
4. Jesli brak wiersza → return `{status: error, reason: "stage_not_found"}`
5. Jesli wiersz bez `✅` → proceed do aktualizacji

Activity-log idempotencja: `grep -q '"artifact":"plans/<slug>.md::<stage_id>"' activity-log.jsonl` PRZED appendem. Jesli match → pominij append (c).

---

## 6. Allowlist katalogów

Skill operuje TYLKO na plikach planow w nastepujacych lokalizacjach (wzgledne do project root):

```
<project>/docs/plans/
<project>/knowledge-base/plans/
<project>/.claude/plans/
```

**Kazda inna sciezka → `{status: rejected_path, reason: "not_in_allowlist"}`, zero modyfikacji.**

Weryfikacja: przed kazdym edit sprawdz `realpath <plan_path>` i dopasuj do allowlist.

---

## 7. Drift detection

Szczegoly: `drift-detection.md`

**Summary:** skrypt `check-plan-drift.sh` wykrywa 2 typy rozjazdu:
- `ghost_completion` — tabela mowi ✅ + commit hash, ale `git log` nie ma tego commita
- `missing_sync` — commit w git log wspomina stage_id, ale tabela nie ma ✅

**Kiedy uruchamiac:**
- Manualnie po sesji w ktorej plan byl aktualizowany recznie (poza pipeline'em)
- Przed wywolaniem `plan-progress-tracker` (sanity check przez agenta E3)
- Po wykryciu podejrzanego stanu tabeli statusu

```bash
bash check-plan-drift.sh <sciezka-do-planu.md>
```

Exit 0 = brak dryfu. Exit 1 = ≥1 dryf wykryty (szczegoly na stderr).

---

## 8. Kiedy recznie wywolac `plan-progress-tracker`

Wywolaj reczne przez `/task plan-progress-tracker` lub CLI gdy:

1. **Manualny `git commit`** poza pipeline'em agenta — commit istnieje, ale tabela planu nie zostala zaktualizowana
2. **Etap wykonany w terminalu** bez Task call — np. operator recznie uruchomil skrypt, wpisal kod, plik gotowy
3. **Crash agenta w srodku etapu** — czesc krokow moglA sie dokonac; sprawdz co jest w (a)/(b)/(c), domknij tylko brakujace
4. **Import historycznych etapow** — stare etapy sprzed wdrozenia skilla, retroaktywne oznaczenie

Parametry: `--plan=<sciezka>`, `--stage=<id>`, `--commit=<hash>`, `--slot=<1|2|3>`, opcjonalnie `--notes=<tekst>`.

---

## 9. Integracja z hookiem post-stage-update-plan.sh

Hook `library/hooks/post-stage-update-plan.sh` (b) — PostToolUse na `Write|Edit`.

Gdy Claude edytuje plik w `plans/*.md`, hook emituje na stderr:
```
[plan-sync-protocol] Pamietaj: po zakonczeniu etapu wywolaj plan-progress-tracker
(zasada plan-sync-protocol). Parametry: --plan=<plik> --stage=<id> --commit=<hash> --slot=<N>
```

Hook **nie blokuje** i **nie wywoluje agenta automatycznie**. To soft-reminder — Claude w sesji decyduje czy wywolac tracker (np. gdy etap jeszcze nie jest kompletny, hooker sie uruchomi przy pierwszej edycji, ale tracker wywolujemy dopiero po commit).

---

## 10. Czego skill NIE robi

- **Nie wykonuje aktualizacji** — to robi agent `plan-progress-tracker` (E3). Skill = specyfikacja, agent = executor.
- **Nie definiuje formatu planu** (sekcje, risk-matrix, contingency) — to terytorium `planner-design-patterns`. Skill zaklada ze plan ma tabele w `## Etapy` z kolumna Status.
- **Nie zarzadza slotami** `next-session-*.md` — to `multi-plan-workflow` (E1). Skill referuje slot=N notation jako dependency.
- **Nie robi session routing** — to agent `session-router` (E4).
- **Nie definiuje slash command** `/plan-sync` — ewentualna  (poza scope).
- **Nie modyfikuje pliku planu poza allowlist** — reject bez modyfikacji.
- **Nie laduje slotu do kontekstu** — to hook `session-start-multi-plan.sh` (E5a).

---

## 11. Antywzorce

| Antywzorzec | Problem | Poprawka |
|---|---|---|
| Pominac (b) lub (c) "bo i tak wiadomo" | Next-session i log desync z planem — dryf nieuchronny | Zawsze 3 miejsca, zawsze ta kolejnosc |
| Zrobic (c) przed (a) | Activity-log ma wpis ale tabela pusta — ghost entry | Sekwencja (a)→(b)→(c) jest obligatoryjna |
| Wywolac tracker bez `--commit` | Brak hash = ghost_completion od razu po sync | Zawsze podaj commit hash po git commit |
| Edytowac plan poza allowlist | Moznna edytowac bezposrednio ale bez tracker sync = dryf | Trzymaj plany w allowlist, tracker dziala only in-allowlist |
| Wywolac tracker dwa razy dla tego samego etapu | Bez idempotencji = duplikat w activity-log | Tracker zwraca `noop` — bezpieczne; ale idempotencja musi dzialac poprawnie |

---

## 12. Powiązania

- **`idempotency-rules.md`** (ten katalog) — pelna specyfikacja algorytmu pre/post-check
- **`drift-detection.md`** (ten katalog) — skrypt `check-plan-drift.sh`, 2 typy dryfu, test backreference
- **`plan-progress-tracker`** (`library/agents/universal/plan-progress-tracker.md`) — agent-executor (, sonnet)
- **`multi-plan-workflow`** (`library/skills/universal/multi-plan-workflow/`) — dependency: slot=N notation, format `next-session-{slot}.md`
- **`post-stage-update-plan.sh`** (`library/hooks/post-stage-update-plan.sh`) — hook soft-reminder (b)
- **`planner-design-patterns`** (`.claude/skills/planner-design-patterns/`) — format planu (sekcja `## Etapy`, risk-matrix) — nie twarda zaleznosc, ale naturalny kontekst
- **`model-routing`** (`library/skills/universal/model-routing/`) — `plan-progress-tracker` = sonnet (edit wg jasnych regul)
- **Plan :** `knowledge-base/plans/2026-05-06--plan-sync-multi.md` (E2 = ten skill, E3 = agent, E5b = hook)
