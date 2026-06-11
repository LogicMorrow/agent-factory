---
description: Utwórz lub zaktualizuj kartę projektu w knowledge-base/projects/
---

Zbierz od użytkownika — po jednym pytaniu:

1. **Slug projektu** — kebab-case (np. `external-crm`, `n8n-pipedrive-sync`). Jeśli użytkownik nie wie — zapytaj o nazwę i wygeneruj slug.
2. **Tryb** — nowa karta czy aktualizacja? (Sprawdź czy plik istnieje: `knowledge-base/projects/<slug>.md` → jeśli tak, zaproponuj aktualizację.)

Następnie wywołaj subagenta **`project-profiler`**:
- **Tryb A** (nowa): profiler prowadzi wywiad strukturalny (max 10 pytań).
- **Tryb B** (aktualizacja): profiler pyta "co się zmieniło" i patchuje kartę.

Po zakończeniu zaraportuj użytkownikowi ścieżkę karty i listę sekcji oznaczonych jako `[do uzupełnienia]`.

**Nie uruchamiaj** `project-profilera` jeśli użytkownik prosi tylko o wyświetlenie karty — wtedy przeczytaj plik bezpośrednio.
