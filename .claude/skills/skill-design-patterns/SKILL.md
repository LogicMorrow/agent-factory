---
name: skill-design-patterns
description: Wzorce projektowania dobrych skilli Claude Code (paczek wiedzy). Uruchamiaj gdy projektujesz, recenzujesz lub refaktoryzujesz skill w `.claude/skills/`.
---

# Wzorce projektowania skilli

## Skill vs agent — kiedy co
| Potrzeba | Użyj |
|---|---|
| Wiedza referencyjna ładowana na żądanie | **skill** |
| Zestaw reguł / wzorców / konwencji | **skill** |
| Dokumentacja procesu z przykładami | **skill** |
| Zadanie z własnym workflow i tools | **agent** |
| Operacja modyfikująca pliki / system | **agent** |
| Powtarzalna procedura z wieloma krokami | **agent** |

Wątpisz? **Zacznij od skilla.** Łatwiej skill promować do agenta niż odwrotnie.

## Struktura katalogu
```
.claude/skills/<nazwa-skilla>/
├── SKILL.md            # obowiązkowy, z frontmatterem
├── examples/           # opcjonalne: konkretne przykłady
├── references/         # opcjonalne: cytaty z dokumentacji
└── <tematyczne-pliki>.md  # gdy SKILL.md rośnie > 300 linii
```

## Frontmatter SKILL.md
```yaml
---
name: nazwa-kebab-case
description: Kiedy uruchomić skill — konkretny wyzwalacz, nie ogólnikowa definicja
---
```

## Frontmatter library-extended — `compatible_with` vs `requires` (NAJCZĘŚCIEJ MYLONE)

Dla skilli trafiających do `library/skills/<kategoria>/` frontmatter jest rozszerzony o kilka pól metadata. **Dwa pola są systematycznie mylone** — wykryte 2026-04-27 etap 12 ( planu rozbudowy fabryki pod CRM): 2/3 skilli kategorii webapp/universal miały `compatible_with` z **nazwami innych skilli zamiast kategorii projektów**. Lesson #8 severity HIGH.

| Pole | Semantyka | Wartości dozwolone | Przykład poprawny |
|---|---|---|---|
| **`compatible_with`** | **kategorie projektów** w których skill ma sens | `webapp`, `cli`, `automation`, `ai-agents`, `other`, `universal` (skill pasuje wszędzie) | `compatible_with: [webapp]` (dla `webapp-cicd-templates`) |
| **`requires`** | **inne skille** od których ten skill zależy (musi być w paczce) | nazwy innych skilli z `library/skills/.../` | `requires: [model-routing, webapp-standards]` |

### Dobry przykład — `technical-docs-standards` (universal)
```yaml
---
name: technical-docs-standards
compatible_with: [webapp, cli, automation, ai-agents, other]   # universal — pasuje wszędzie
requires: []                                                    # standalone, brak zależności
category: universal
version: 1.0
---
```

### Zły przykład — anti-pattern wykryty etap 12 (lesson #8 + meta-reflection Porażka 2)
```yaml
---
name: webapp-cicd-templates
compatible_with: [webapp-standards, webapp-security-hardening]  # ❌ NAZWY INNYCH SKILLI — błąd semantyczny
requires: []
---
```

**Naprawa:**
```yaml
compatible_with: [webapp]                  # ✅ kategoria projektu
requires: [webapp-standards]               # ✅ dependency na inny skill
```

### Whitelist wartości `compatible_with`
- Dokładnie 6 wartości: `webapp | cli | automation | ai-agents | other | universal`.
- `universal` traktuj jako sygnał "skill pasuje wszędzie" — ekwiwalent listy 5 pozostałych. NIE mieszaj `universal` z innymi wartościami w tej samej liście (`compatible_with: [universal, webapp]` → niejednoznaczne, FAIL).
- Wszystkie inne wartości (np. nazwy skilli, pojedyncze frameworki typu `nextjs`) = BLOCKER w quality-checker.

### Walidacja w `quality-checker`
Quality-checker holistyczny musi sprawdzić:
- [ ] `compatible_with` zawiera tylko wartości z whitelisty (6 wartości — viz wyżej).
- [ ] `requires` zawiera tylko nazwy skilli istniejących w `library-index.json`.
- [ ] Niezgodność = **BLOCKER severity HIGH** (defekt systemowy — lesson #8 severity HIGH, 2 powtórzenia w jednej fazie).

## `description` — te same zasady co dla agenta
- **Złe:** `Wiedza o Reakcie.`
- **Dobre:** `Wzorce hooków React 18+ (useEffect, useMemo, useTransition). Uruchamiaj przy pisaniu/debugowaniu komponentów funkcyjnych w .tsx.`

## Rozmiar
- SKILL.md poniżej **300 linii** — powyżej rozbij na pliki tematyczne i linkuj z SKILL.md.
- Każda sekcja ma być **skanowalna** (nagłówki, tabele, listy).

## Treść — co powinien zawierać dobry skill
1. **Kiedy uruchomić** (pierwsza sekcja, zgodna z `description`).
2. **Kluczowe zasady** — 5–10 zwięzłych reguł.
3. **Przykłady** — co najmniej 2 konkretne "dobrze" vs "źle".
4. **Antywzorce** — czego unikać i dlaczego.
5. **Powiązania** — do jakich agentów/skilli odesłać w sąsiednich zadaniach.

## Zasada minimalności
Skill **nie przepisuje dokumentacji** zewnętrznej — cytuje tylko to co **nieoczywiste** lub **bolesne** w praktyce. Skill to "zestaw wniosków", nie encyklopedia.

## Aktualizowanie skilli
Skille ewoluują z lekcjami (`knowledge-base/lessons.jsonl`). Gdy meta-reviewer proponuje zmianę skilla — zapisuje propozycję, a **operator decyduje** o wdrożeniu. Skill nigdy nie jest modyfikowany automatycznie.

## Przykłady: dobrze vs źle

### Para 1 — "Kiedy uruchomić" jako pierwsza sekcja

❌ **Źle (skill o React Hooks):**
```markdown
# React Hooks

Hooks to funkcje pozwalające na używanie stanu i cyklu życia w komponentach funkcyjnych.

## useState
...
```

✅ **Dobrze (ten sam skill):**
```markdown
# React Hooks

## Kiedy uruchomić
Przy pisaniu lub debugowaniu komponentów funkcyjnych React (.tsx) — szczególnie gdy
pojawia się "useEffect niespójny z dependency array" albo "state nie odświeża się".
Nie uruchamiaj dla komponentów klasowych (tam zobacz `react-class-components`).

## Kluczowe zasady
1. useState do lokalnego stanu, NIE do danych z API (tam TanStack Query).
2. ...
```

**Dlaczego:** bez sekcji "Kiedy uruchomić" Claude nie wie kiedy wczytać skill — w każdej sesji ryzykuje zgadywanie albo pominięcie. Pierwsza wersja to opis *czym jest*, druga daje konkretny trigger i wyłącznik (negatywny przypadek).

### Para 2 — minimalizm vs przepisywanie dokumentacji

❌ **Źle (skill o PostgreSQL):**
```markdown
# PostgreSQL

PostgreSQL to relacyjna baza danych stworzona w 1986 roku...
[200 linii pełnej dokumentacji SQL-a]
```

✅ **Dobrze:**
```markdown
# PostgreSQL — wzorce w naszych projektach

## Kiedy uruchomić
Gdy piszesz migrację SQL, query do Prisma, lub debugujesz slow query.

## Nieoczywiste zasady (wniosek z lekcji, nie teoria)
- ❗ `NOT NULL` dodawaj w migracji zawsze z `DEFAULT` — inaczej padnie na
  istniejących wierszach (lekcja z 2025-03 — external-crm, migracja 007).
- ❗ `CASCADE DELETE` testuj na kopii produkcyjnej — był incydent z wycięciem
  historii kampanii (lekcja z 2025-05).
- ❗ Idx złożony: kolumna najczęściej filtrowana pierwsza.

## Odniesienia
- Oficjalna dokumentacja: https://www.postgresql.org/docs/ (nie przepisujemy).
- Nasz plik migracji wzorcowy: `/external-crm/db/init/001_schema.sql`.
```

**Dlaczego:** pierwsza wersja to encyklopedia — ładuje się długo do kontekstu i jest dostępna w dokumentacji oficjalnej. Druga wersja to **zestaw wniosków** — nieoczywiste rzeczy, które bolały w praktyce, plus linki do źródeł. Skill = "to czego nie da się łatwo znaleźć nigdzie indziej".

## Antywzorce
- ❌ Skill bez `description` — nie wywoła się poprawnie.
- ❌ Skill > 500 linii w jednym SKILL.md — nikt tego nie przeczyta.
- ❌ Skill który opisuje "jak używać Git" — lepiej link do oficjalnej dokumentacji.
- ❌ Skill duplikujący treść CLAUDE.md projektu — CLAUDE.md jest zawsze w kontekście, skill nie.
- ❌ Skill bez przykładów — teoria bez zastosowania.
- ❌ **Skill bez sekcji "Kiedy uruchomić"** — Claude nie wie kiedy go wczytać, skill nigdy nie trafia do kontekstu.
- ❌ **Mieszanie instrukcji z odniesieniami bez kontekstu** — np. "użyj X" obok "patrz dokument Y" bez wyjaśnienia związku. Użytkownik się gubi, nie wie czy X pochodzi z Y, czy jest alternatywą.
- ❌ **Skill wywołujący inny skill w pętli** — jeśli A linkuje B, a B linkuje A przy każdej sekcji, kontekst puchnie. Linki powinny być jednokierunkowe (specjalizacja → baza, nie odwrotnie).

## Powiązania

- **`agent-design-patterns`** (`.claude/skills/agent-design-patterns/`) — gdy decydujesz "skill czy agent?" i wybór pada na agenta. Ma tabelę "skill vs agent" i zasadę "zacznij od skilla".
- **`planner-design-patterns`** (`.claude/skills/planner-design-patterns/`) — przykład specjalizacji bazy. Zbudowany jako osobny skill, nie sekcja w `agent-design-patterns` (patrz ADR 001 w `docs/meta-skills/adr/`).
- **`skill-builder`** (`.claude/agents/`) — konsument tego skilla przy projektowaniu każdego nowego skilla.
- **`quality-checker`** (`.claude/agents/`) — używa checklisty z tego skilla przy walidacji skilli (sprawdza frontmatter, <300 linii, ≥2 przykłady, antywzorce, powiązania).
