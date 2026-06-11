# migration-guide.md — Migracja single→multi (next-session.md → 3-slot system)

Dokument referencyjny dla skilla `multi-plan-workflow`.
Uruchamiaj gdy: projekt ma `next-session.md` i chcesz przejść na system slotów.

---

## Kiedy migrować

Migruj gdy spełniony jeden z warunków:

- Otwierasz drugi terminal dla tego samego projektu
- Projekt ma >1 aktywny plan w katalogu `plans/`
- operator pyta "który terminal?" i masz jeden `next-session.md`
- Chcesz uruchomić hook `session-start-multi-plan` (wymaga struktury slotów)

**Nie migruj gdy:** projekt ma jeden wątek pracy i prawdopodobnie zostanie jeden — migracja
dla jednego slotu jest nadmierną złożonością.

---

## 5 kroków migracji

### Krok 1 — Zmień nazwę pliku

```bash
# Fabryka (knowledge-base/):
mv knowledge-base/next-session.md knowledge-base/next-session-1.md

# Projekt kliencki (docs/):
mv docs/next-session.md docs/next-session-1.md
```

❌ Nie usuwaj — **zachowaj całą treść** jako zawartość slotu 1.
✅ Tylko zmień nazwę, treść pozostaje niezmieniona na tym etapie.

---

### Krok 2 — Dodaj frontmatter do `next-session-1.md`

Otwórz `next-session-1.md` i **dopisz frontmatter na samej górze** (przed istniejącą treścią):

```yaml
---
slot: 1
title: "<opisowy tytuł głównego wątku pracy>"
branch: "<current-branch>"   # opcjonalne; dodaj gdy slot=branch
module: "<moduł>"             # opcjonalne; dodaj gdy slot=module
last_update: "<RRRR-MM-DD>"
status: "active"
---
```

Przykład dla fabryki:

```yaml
---
slot: 1
title: "Master plan rozbudowy fabryki -4"
module: "-plan-sync"
last_update: "2026-05-07"
status: "active"
---
```

---

### Krok 3 — Utwórz manifest `next-session-index.md`

Utwórz plik w tym samym katalogu co `next-session-1.md`:

```bash
# Fabryka:
touch knowledge-base/next-session-index.md

# Projekt kliencki:
touch docs/next-session-index.md
```

Wypełnij manifest (jeden wpis dla istniejącego slotu):

```markdown
# next-session-index
last_update: <RRRR-MM-DD>
project: <nazwa projektu>

| slot | title | branch/module | status | last_update | plik |
|---|---|---|---|---|---|
| 1 | <tytuł z kroku 2> | <branch lub module:nazwa> | active | <data> | next-session-1.md |

## Notatki
- Migracja z next-session.md wykonana <data>.
```

Szczegóły formatu kolumn: `manifest-format.md`.

---

### Krok 4 — Utwórz sloty 2 i 3 (opcjonalnie)

Jeśli masz gotowe kolejne wątki pracy do równoległego prowadzenia:

```bash
touch knowledge-base/next-session-2.md
touch knowledge-base/next-session-3.md
```

Minimalny szablon nowego slotu:

```markdown
---
slot: 2
title: "<tytuł drugiego wątku>"
branch: "<branch>"
last_update: "<data>"
status: "active"
---

## Priorytety tej sesji
1. <priorytet>

## W trakcie

## Zamknięte
```

Dodaj wiersze do manifestu dla każdego nowego slotu.

**Jeśli nie masz drugiego wątku — pomijaj ten krok.** Sloty tworzone na żądanie, nie z góry.

---

### Krok 5 — Zaktualizuj `CLAUDE.md` projektu

Znajdź sekcję instrukcji startowych w `CLAUDE.md` projektu. Zwykle wygląda tak:

```markdown
## Start sesji — OBOWIĄZKOWE
1. **Przeczytaj `knowledge-base/next-session.md`** — zawiera priorytety...
```

Zmień na:

```markdown
## Start sesji — OBOWIĄZKOWE
1. **Sprawdź `knowledge-base/next-session-index.md`** — manifest aktywnych slotów.
   Wybierz slot odpowiadający bieżącemu kontekstowi (git branch lub pytanie operatora),
   następnie wczytaj odpowiedni `next-session-{N}.md`.
   Jeśli brak manifestu lub jeden slot — czytaj `next-session-1.md` bezpośrednio.
```

---

## Przykladowa migracja — fabryka (agent-factory)

**Przed migracją:**
```
knowledge-base/
├── next-session.md          ← jeden plik, stare API
└── plans/
    ├── 2026-05-06-master-rozbudowa-fabryki-9-problemow.md
    ├── 2026-05-06--plan-sync-multi.md
    └── ...
```

**Krok 1:**
```bash
mv knowledge-base/next-session.md knowledge-base/next-session-1.md
```

**Krok 2 — dopisz frontmatter na gorze next-session-1.md:**
```yaml
---
slot: 1
title: "Master plan rozbudowy fabryki -4"
module: "-plan-sync"
last_update: "2026-05-07"
status: "active"
---
```

**Krok 3 — utwórz knowledge-base/next-session-index.md:**
```markdown
# next-session-index
last_update: 2026-05-07
project: agent-factory

| slot | title | branch/module | status | last_update | plik |
|---|---|---|---|---|---|
| 1 | Master plan rozbudowy fabryki -4 | module:-plan-sync | active | 2026-05-07 | next-session-1.md |

## Notatki
- Migracja z legacy next-session.md wykonana 2026-05-07.
- Sloty 2-3 wolne — dodaj gdy otworzy się drugi wątek w fabryce.
```

**Krok 4:** pominięty — fabryka ma jeden aktywny wątek ( w toku).

**Krok 5 — update CLAUDE.md fabryki:**
Zmień linię `Przeczytaj knowledge-base/next-session.md` na instrukcję z manifestem.

**Po migracji:**
```
knowledge-base/
├── next-session-index.md    ← manifest (nowy)
├── next-session-1.md        ← slot 1 (zmieniona nazwa + frontmatter)
└── plans/
    └── ...
```

---

## Weryfikacja po migracji

Uruchom ten checklist:

- [ ] Plik `next-session.md` (legacy) **nie istnieje** w katalogu (stan mieszany = błąd)
- [ ] `next-session-index.md` istnieje i ma tabelę z co najmniej 1 wpisem
- [ ] `next-session-1.md` ma frontmatter z `slot: 1` i `status: active`
- [ ] `CLAUDE.md` projektu odnosi się do `next-session-index.md`, nie do `next-session.md`
- [ ] Liczba plików `next-session-N.md` ze statusem `active`/`paused` <= 3

---

## Stan mieszany — jak naprawić

Jeśli istnieje jednocześnie `next-session.md` i `next-session-1.md`:

```bash
# Opcja A: next-session.md to stara wersja — usuń
rm knowledge-base/next-session.md

# Opcja B: next-session.md ma nowe notatki których nie ma w next-session-1.md — scal
cat knowledge-base/next-session.md >> knowledge-base/next-session-1.md
rm knowledge-base/next-session.md
```

Po naprawie — uruchom checklist weryfikacji ponownie.

---

## Odniesienia

- `SKILL.md` (ten katalog) — sekcja 6 "Migracja" (skrócony widok)
- `manifest-format.md` (ten katalog) — szczegółowy format `next-session-index.md`
- `plan-progress-tracker` — agent ; po wdrożeniu przejmuje aktualizacje manifestu
