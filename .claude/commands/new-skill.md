---
description: Stwórz nowy skill (wywiad → builder → quality-check)
---

Flow trzyetapowy: wywiad biznesowy, projekt, walidacja.

## Krok 0 — Wywiad biznesowy (requirements-interviewer)

Wywołaj subagenta **`requirements-interviewer`** (opus, typ: skill). Agent:
1. Zadaje pytania dostosowane do skilla (zakres wiedzy, kiedy się uruchomić, pliki pomocnicze, czy nie powinien to być agent).
2. Sanity check: **jeśli opis brzmi jak "procedura modyfikująca system" — zasugeruj agenta zamiast skilla** i odeślij do `/new-agent`.
3. Sprawdza duplikaty w `library/library-index.json`.
4. Zapisuje brief do `knowledge-base/interviews/YYYY-MM-DD-<slug>.md`.
5. Pokazuje streszczenie i pyta o zatwierdzenie.

## Krok 1 — Projekt (skill-builder)

Po zatwierdzeniu briefu wywołaj subagenta **`skill-builder`** (sonnet) z parametrem: ścieżka do briefu.

## Krok 2 — Walidacja (quality-checker)

Wywołaj **`quality-checker`** na utworzonym `SKILL.md`. Jeśli **FAIL** — iteruj aż do PASS.

## Krok 3 — Raport końcowy

Ścieżka, model, struktura plików pomocniczych, zapis w `library-index.json` jeśli trafił do biblioteki.
