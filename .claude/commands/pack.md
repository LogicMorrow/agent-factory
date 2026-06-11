---
description: Przygotuj paczkę agentów/skilli dla opisanego projektu i wypchnij na nowe repo GitHub (af-pack-<nazwa>)
---

Zbierz od użytkownika — po jednym pytaniu na raz:

1. **Nazwa paczki** (slug kebab-case, np. `crm-starter`, `webapp-security`). Stanie się `af-pack-<nazwa>` na GitHubie.
2. **Opis projektu** — kilka zdań: co budujesz, jaki stack, jaki cel biznesowy. Im więcej kontekstu, tym lepszy dobór agentów.
3. **Typ projektu** — `webapp` / `cli` / `automation` / `other`.
4. **Konkretni agenci/skille które MUSISZ mieć** — (opcjonalne, Enter = brak preferencji).
5. **Agenci/skille do WYKLUCZENIA** — (opcjonalne).

Gdy masz wszystkie odpowiedzi — pokaż użytkownikowi **podgląd** zanim cokolwiek stworzysz:

```
Planuję spakować:
Agenci: [lista z uzasadnieniami]
Skille: [lista]
Repo: LogicMorrow/af-pack-<nazwa> (private)

Zatwierdzasz? (tak / zmień X)
```

Po zatwierdzeniu wywołaj subagenta **`pack-agent`** z pełnym zestawem danych.

Po zakończeniu wyświetl:
- URL repo do skopiowania
- Komendę instalacyjną (`git clone ...`)
- Krótką tabelę zawartości

Zapytaj na końcu: **"Chcesz sklonować tę paczkę do któregoś projektu na tym serwerze?"**
