---
description: Uruchom meta-reviewer do analizy lessons.jsonl i wygenerowania propozycji ulepszeń
---

1. Sprawdź ilość lekcji w `~/agent-factory/knowledge-base/lessons.jsonl`. Jeśli < 3 — poinformuj użytkownika że za mało danych i zatrzymaj się.

2. Wywołaj subagenta **`meta-reviewer`**. On wczyta lessons, pogrupuje wzorce, i zapisze propozycje jako osobne pliki w `~/agent-factory/knowledge-base/improvement-proposals/`.

3. Wyświetl użytkownikowi raport zwrócony przez meta-reviewera:
   - Liczba przeczytanych lekcji + zakres dat
   - Top 3–5 dominujących wzorców
   - Lista utworzonych plików propozycji z 1-liniowym tytułem każdej

4. Zapytaj: **"Które propozycje chcesz wdrożyć?"** — NIE wdrażaj automatycznie.

5. Gdy użytkownik wskaże propozycje do wdrożenia — dopiero wtedy wywołuj `agent-architect` lub `skill-builder` (zależnie od rodzaju zmiany) z treścią propozycji jako input.
