---
description: Zaprojektuj nowego agenta (wywiad → architekt → quality-check)
---

Flow trzyetapowy: najpierw wywiad biznesowy, potem projekt techniczny, na końcu walidacja.

## Krok 0 — Wywiad biznesowy (requirements-interviewer)

Wywołaj subagenta **`requirements-interviewer`** (opus). Agent:
1. Zadaje 8-12 pytań po jednym (problem biznesowy, kontekst, wymagania funkcjonalne, ograniczenia, kryterium sukcesu).
2. Sprawdza duplikaty w `library/library-index.json`.
3. Zapisuje brief do `knowledge-base/interviews/YYYY-MM-DD-<slug>.md`.
4. Pokazuje streszczenie i pyta o zatwierdzenie.

**Jeśli użytkownik nie zatwierdzi briefu** — iteruj z requirements-interviewerem aż zatwierdzi, albo przerwij.

**Jeśli interviewer stwierdzi że problem biznesowy nie jest gotowy** — przerwij i zasugeruj użytkownikowi najpierw zmierzyć skalę manualnie.

## Krok 1 — Projekt techniczny (agent-architect)

Po zatwierdzeniu briefu wywołaj subagenta **`agent-architect`** (opus) z parametrem: ścieżka do briefu. Architekt:
1. Czyta brief z `knowledge-base/interviews/`.
2. Czyta 5 ostatnich refleksji z `knowledge-base/reflections/`.
3. Stosuje skill `model-routing`.
4. Zapisuje plik agenta.
5. Zapisuje refleksję do `knowledge-base/reflections/`.

## Krok 2 — Walidacja (quality-checker)

Wywołaj subagenta **`quality-checker`** (sonnet) na utworzonym pliku. Jeśli **FAIL** — wracasz do `agent-architect` z listą problemów i iterujesz do PASS.

## Krok 3 — Raport końcowy

Gdy PASS:
- Ścieżka pliku agenta
- Ścieżka briefu
- Ścieżka refleksji
- Model + tools + krótka delegacja
- Zapytaj czy dopisać do `knowledge-base/agent-registry.json` (jeśli agent trafił do projektu klienckiego)
