---
name: error-memory-framework
version: "1.0.0"
type: skill
category: universal
description: "Use when an agent makes an error that may recur, when designing or iterating an agent (read its errors-{name}.md before next version), or when reviewing project for systemic patterns. Defines convention .claude/memory/errors-{agent-name}.md with severity-based promotion to lessons.jsonl."
compatible_with: [universal]
requires: []
tags: [learning, errors, memory, idempotency, universal]
token_cost: medium
files:
  - SKILL.md
  - format-spec.md
  - examples.md
---

# error-memory-framework

Konwencja per-agent pliku bledow `.claude/memory/errors-{agent-name}.md`. Powstala po incydencie
2026-05-06 (8x powtorzony blad `.env leak` w jednej sesji — zaden agent nie zapisal bledu w warstwie
dostepnej dla innych agentow). Fundament  learning loop (E2 cross-agent-learning, E3 mistake-recorder).

---

## 1. Kiedy uruchomic

**Uruchamiaj gdy:**
- Agent popelnil blad ktory moze sie powtorzyc (co najmniej jeden z kryteriow HIGH/MED/LOW)
- Projektujesz lub iterujesz agenta (v1.1+) — przeczytaj `errors-{agent-name}.md` PRZED projektowaniem
- Piszesz agenta `mistake-recorder` (E3) — ten skill jest jego specyfikacja
- Reviewujesz projekt pod katem systemowych antywzorcow — czytasz pliki `errors-*.md`

**NIE uruchamiaj gdy:**
- Blad jest jednorazowy, niepowtarzalny i niesystemowy — zapisz w reflections (narracyjnie)
- Chcesz analizowac wzorce cross-agent — to zakres `cross-agent-learning` (E2, )
- Chcesz wykonac cleanup archiwum — egzekucja nalezy do `mistake-recorder` (E3), nie do tego skilla

---

## 2. Lokalizacja pliku per agent

```
<project-root>/
  .claude/
    memory/
      errors-{agent-name}.md        <- plik aktywny (max 100 wpisow, max 180 dni)
      errors-{agent-name}.archive.md <- plik archiwum (FIFO rotate po przekroczeniu limitu)
```

**Zasady lokalizacji:**
- Jeden plik per agent per projekt (nie globalny)
- Nazwa: `errors-{agent-name}.md` — kebab-case, dokladnie jak nazwa agenta
- Katalog: `<project>/.claude/memory/` — JEDYNA dozwolona sciezka (allowlist)
- `mistake-recorder` odrzuca kazda sciezke poza allowlist: blad "path outside allowlist"
- Plik nie istnieje = brak zapisanych bledow (nie tworz pustego pliku prewencyjnie)

**Weryfikacja sciezki przed Write:**
```bash
realpath "$target_path" | grep -q '/.claude/memory/' || echo "REJECT: path outside allowlist"
```

---

## 3. Format wpisu (skrot)

Pelna specyfikacja: `format-spec.md`

Kazdy wpis = sekcja markdown:

```markdown
## YYYY-MM-DD — {short-title}
- **error-summary:** Krotki opis bledu (1 linia, distinctive — nie "Error" ani "Failed")
- **cause-root:** Dlaczego sie zdarzylo (1-3 linie)
- **prevention:** Jak unikac — konkretny action item
- **severity:** HIGH | MED | LOW
- **context:** (opcjonalne) link do reflection / commit / issue
<!-- hash: <md5-of-normalized-error-summary> -->
```

Parsing: regex `^## (\d{4}-\d{2}-\d{2}) — (.+)$` rozpoznaje poczatek wpisu.
Pola: regex `^- \*\*(\w+(?:-\w+)*):\*\* (.+)$`.

---

## 4. Severity scale

| Severity | Kryterium | Przyklad | Promotion |
|---|---|---|---|
| **HIGH** | Pattern repeatable, architektoniczny, cross-project. Inni agenci w innych projektach powinni wiedziec. | Agent ignoruje hook block-env-leak i wywoluje `docker compose config` | Tak → append do `lessons.jsonl` |
| **MED** | Pattern w obrebcie projektu. Powtarzalny w tym projekcie, ale nie cross-project. | Agent zle parsuje multi-line frontmatter konkretnego formatu projektu | Nie — zostaje w pliku per-agent |
| **LOW** | Jednorazowy fail, nie do agregacji. Warty pamietania, ale nie systemowy. | Timeout na wolnym API endpoint podczas wdrozenia | Nie — zostaje w pliku per-agent |

**Zasada severity:** watpisz → wybierz nizszy poziom. Severity inflation (wszystko HIGH) szumi `lessons.jsonl` i degeneruje cross-project learning.

---

## 5. Promotion rule (severity=HIGH)

Gdy wpis ma `severity: HIGH` — `mistake-recorder` appenduje ROWNIEZ do `knowledge-base/lessons.jsonl`:

```json
{
  "date": "2026-05-07",
  "agent": "skill-builder",
  "error_summary": "Skill-builder pominął sekcję Czego NIE robi",
  "cause_root": "Brak checklisty walidacyjnej przed zapisem SKILL.md",
  "prevention": "Zawsze sprawdz sekcje Czego NIE robi przed finalnym zapisem",
  "source": "error-memory",
  "severity": "HIGH"
}
```

**Zasady promotion:**
- Promotion jest **one-way write-once** — nie ma backward sync
- `lessons.jsonl` jest superset (zawiera promotions + reczne lessons z `/log-lesson`)
- LOW/MED zostaja TYLKO w `errors-{agent-name}.md`
- Pole `source: "error-memory"` odróznia promotions od recznych wpisow

---

## 6. Idempotency

**Klucz unikalnosci:** MD5 hash z calego `error-summary` po normalizacji:
1. lowercase
2. trim (usun biale znaki z brzegów)
3. collapse whitespace (zamien wielokrotne spacje/taby/newline na pojedyncza spacje)

**Przechowywanie:** HTML komentarz na koncu sekcji wpisu (parsable, niewidoczny dla czlowieka):
```
<!-- hash: a1b2c3d4e5f6... -->
```

**Algorytm mistake-recorder przed appendem:**
```bash
HASH=$(echo -n "$normalized_summary" | md5sum | cut -d' ' -f1)
grep -q "<!-- hash: $HASH -->" "errors-${agent}.md" && echo "NOOP: duplicate" && exit 0
```

**Re-occurrence (ten sam blad, inne wystapienie):** hash match = noop, nie duplikuj wpisu.
**Severity escalation (blad powtorzyl sie z wyzszym znaczeniem):** nowy wpis z nowym hash + `context:` referujacy poprzedni wpis.

---

## 7. Cleanup policy

**Trigger (sprawdzany przez mistake-recorder PRZED kazdym appendem):**
- Liczba sekcji `## ` > 100, LUB
- Najstarszy wpis (pierwsza data `## YYYY-MM-DD`) > 180 dni od dzisiaj

**Akcja (sekwencyjna):**
1. Policz sekcje: `grep -c '^## ' errors-{agent}.md`
2. Wytnij najstarsze 25% sekcji (FIFO — chronologicznie)
3. Append wyciete sekcje do `errors-{agent}.archive.md` (tworz jesli nie istnieje)
4. Usun wyciete sekcje z glownego pliku
5. Dopiero potem appenduj nowy wpis

**Archive format:** identyczny z glownym plikiem (te same sekcje `## YYYY-MM-DD — {title}`).
**Concurrency:** cleanup jest sekwencyjny (check → rotate → append). Rownolegle wywolania mistake-recorder moga duplikowac — egzekucja concurrency-safe to zadanie E3, nie tego skilla.

---

## 8. Allowlist katalogów (dla mistake-recorder)

`mistake-recorder` (E3) moze zapisywac WYLACZNIE do:

```
<project>/.claude/memory/errors-*.md
<project>/.claude/memory/errors-*.archive.md
```

**Odrzucane bez modyfikacji:**
- Kazda inna sciezka (np. `knowledge-base/`, `library/`, `/tmp/`, `~/.claude/`)
- Plik o nazwie innej niz `errors-{name}.md` lub `errors-{name}.archive.md`
- Promotion do `lessons.jsonl` — jedyny wyjatek (osobna akcja, nie Write na losowy plik)

---

## 9. Konsumenci 

| Konsument | Rola | Model | Etap  |
|---|---|---|---|
| `mistake-recorder` | Producent — appenduje wpisy zgodnie ze specyfikacja | haiku | E3 |
| `cross-agent-learning` skill | Konsument — kazdy agent czyta swoj `errors-{name}.md` w pre-execution loading | model agenta-hosta | E2 |
| `agent-architect` | Konsument — czyta `errors-{agent}.md` przy projektowaniu v1.1+ | opus | E7 (update) |
| hook `on-error-record.sh` | Soft-reminder — gdy operator wspomni o bledzie, sugeruje uzycie mistake-recorder | N/A | E6 |

---

## 10. Czego skill NIE robi

- **Nie zapisuje wpisow automatycznie** — to robi `mistake-recorder` (E3). Skill = specyfikacja formatu.
- **Nie czyta wpisow per-agent automatycznie** — to robi `cross-agent-learning` (E2). Skill = struktura danych.
- **Nie wykonuje cleanupu** — cleanup policy jest specyfikacja; egzekucja w `mistake-recorder` (E3).
- **Nie waliduje schematu przez kod** — walidacja jest opisowa; pelna walidacja w implementacji E3.
- **Nie analizuje wzorcow cross-agent** — to zakres `cross-agent-learning` (E2).
- **Nie modyfikuje `lessons.jsonl` bezposrednio** — promotion jest akcja `mistake-recorder`, nie skilla.

---

## 11. Antywzorce

| Antywzorzec | Problem | Poprawka |
|---|---|---|
| Generic `error-summary` ("Error", "Failed", "Bug") | Hash collision — dwa rozne bledy maja ten sam hash → noop przy drugim | Distinctive summary: "Agent wywoluje docker compose config mimo blokady hooka" |
| Severity inflation — wszystko HIGH | Szumi `lessons.jsonl`, degeneruje cross-project learning | Watpisz → wybierz nizszy. HIGH = naprawde cross-project |
| Mutowanie istniejacego wpisu | Immutable log — zmiana tresci niszczy idempotency hash | Nowy wpis z `context:` referujacym poprzedni |
| Plik `errors-*.md` poza allowlist | mistake-recorder moze zapisac do nieoczekiwanej lokalizacji | Zawsze `<project>/.claude/memory/` |
| Reczny cleanup zamiast przez mistake-recorder | Archive rozjezdza sie z glownym plikiem (brak FIFO gwarancji) | Cleanup = wylacznie przez mistake-recorder E3 |
| Reczna promotion do `lessons.jsonl` z pomięciem skilla | Brak pola `source: "error-memory"` — nie mozna odróznic promotion od recznych wpisow | Zawsze przez mistake-recorder, nigdy recznie |

---

## 12. Powiązania

- **`format-spec.md`** (ten katalog) — pelna gramatyka wpisu, regex, idempotency hash spec, path validation, severity escalation pattern
- **`examples.md`** (ten katalog) — 5 walidnych wpisow (HIGH/MED/LOW z realnych przypadkow), 3 niewalidne z wyjasnieniam
- **`mistake-recorder`** (`library/agents/universal/mistake-recorder.md`) — agent-producent (, haiku)
- **`cross-agent-learning`** (`library/skills/universal/cross-agent-learning/`) — skill-konsument 
- **`on-error-record.sh`** (`library/hooks/on-error-record.sh`) — hook soft-reminder 
- **`secrets-handling`** (`library/skills/universal/secrets-handling/`) — zrodlo use-case 0 (`.env leak` 2026-05-06)
- **`knowledge-base/plans/2026-05-06--learning-loop.md`** — E1 = ten skill, E2/E3/E6/E7 = konsumenci
