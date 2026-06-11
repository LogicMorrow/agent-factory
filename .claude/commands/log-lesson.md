---
description: Dopisz lekcję do knowledge-base/lessons.jsonl po zakończeniu projektu lub milestone
---

Zbierz od użytkownika — zadaj cztery pytania, po jednym:

1. **Projekt** — nazwa (slug, np. `crm-nowy-klient`) lub `agent-factory` jeśli dotyczy samej fabryki.
2. **Co zadziałało dobrze** — jedno zdanie, konkret (np. "bootstrap projektu przez `/new-project` zajął 2 minuty zamiast ręcznego setupu").
3. **Co NIE zadziałało** — jedno zdanie, konkret (np. "quality-checker nie złapał że `description` agent-X jest za ogólny").
4. **Rekomendacja** — jedno zdanie, konkretne działanie (np. "dodać do checklisty quality-checkera wymaganie przykładu wyzwalacza w description").

Następnie:

- Zbuduj obiekt JSON: `{"date": "YYYY-MM-DD", "project": "...", "worked": "...", "failed": "...", "recommendation": "..."}` — używaj dzisiejszej daty w formacie ISO.
- Dopisz jako **jedną linię** na końcu `~/agent-factory/knowledge-base/lessons.jsonl` (append, nigdy nie nadpisuj istniejących linii).
- Potwierdź użytkownikowi: liczbę linii w pliku po dopisaniu + sugestię: "Gdy uzbiera się ≥5 nowych lekcji, uruchom `/review-lessons`".
