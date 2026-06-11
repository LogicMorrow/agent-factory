---
description: Bootstrap nowy projekt kliencki w ~/projekty/ (wywołuje project-bootstrap)
---

Zbierz od użytkownika — w tej kolejności, po jednym pytaniu na raz:

1. **Nazwa projektu** (slug w kebab-case, np. `crm-nowy-klient`).
2. **Typ projektu** — jeden z: `webapp` / `cli` / `automation` / `other`.
3. **Jednozdaniowy opis celu** projektu.

Gdy masz wszystkie 3 odpowiedzi:

- Wywołaj subagenta **`project-bootstrap`** przekazując te dane.
- Po zakończeniu wyświetl użytkownikowi raport zwrócony przez subagenta (ścieżka, lista skopiowanych szablonów, komenda startowa).
- Zadaj pytanie końcowe: **"Zainicjować gita w tym projekcie?"** — jeśli tak, wykonaj `git init` w ścieżce projektu i zapytaj o remote.

Nie twórz niczego sam — cała logika scaffoldingu jest w `project-bootstrap`.
