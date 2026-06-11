# retrofit-checklist — cross-agent-learning

Checklista retrofitu istniejacych agentow do wzorca pre-execution context loading (E2).
Egzekucja retrofitu jest opcjonalna — skill dostarcza wzorzec i liste priorytetow.

---

## 4-stepowa checklista retrofit (per agent)

Dla kazdego agenta z listy TOP 5 wykonaj kolejno:

```
[ ] Step 1: Zidentyfikuj {this-agent-name}
[ ] Step 2: Wklej sekcje "Before starting work" z injection-template.md
[ ] Step 3: Utworz pusty errors-{name}.md jesli nie istnieje
[ ] Step 4: Bump version + changelog
```

### Step 1 — Zidentyfikuj {this-agent-name}

Otworz plik agenta i odczytaj pole `name:` z frontmattera YAML:

```yaml
---
name: code-implementer   # <- to jest {this-agent-name}
...
---
```

Wartosc `name:` to klucz do:
- Glob pattern dla reflections: `.claude/knowledge-base/reflections/code-implementer*.md`
- Nazwa pliku errors: `.claude/memory/errors-code-implementer.md`

### Step 2 — Wklej sekcje "Before starting work"

1. Otworz `injection-template.md` z tego katalogu
2. Wybierz wariant:
   - **Wariant A (Full)** — dla agentow opus lub sonnet
   - **Wariant B (Haiku-trim)** — dla agentow haiku (np. mistake-recorder)
   - **Wariant C (Custom)** — gdy potrzebujesz override budgetu lub filtrowania lessons
3. Skopiuj wybrany wariant
4. Zamien `{this-agent-name}` na wartosci z Step 1
5. Wklej jako PIERWSZY element sekcji workflow (przed dotychczasowym krokiem 1)

Weryfikacja pozycji — sekcja MUSI byc przed krokiem 1:
```
## Before starting work    <-- krok 0
## 1. [dotychczasowy krok 1]
```

### Step 3 — Utworz pusty errors-{name}.md jesli nie istnieje

Sprawdz czy plik istnieje:

```bash
ls .claude/memory/errors-{this-agent-name}.md 2>/dev/null || echo "brak — tworz"
```

Jesli brak — utworz placeholder (naglowek bez wpisow):

```markdown
# errors-{this-agent-name}

Plik per-agent bledow. Format zgodny z error-memory-framework (E1).
Uzupelniane przez mistake-recorder (E3) lub recznie po incydencie.

<!-- Plik aktywny: max 100 wpisow, max 180 dni. Archiwum: errors-{name}.archive.md -->
```

Lokalizacja: `.claude/memory/errors-{this-agent-name}.md` (projekt w ktorym agent dziala).

### Step 4 — Bump version + changelog

W frontmatterze agenta:

```yaml
version: "1.0.0"   ->   version: "1.0.1"
```

Dodaj wpis w changelogu agenta (szukaj sekcji `## Changelog` lub dodaj na koncu):

```markdown
## Changelog

### v1.0.1 — 2026-XX-XX
- Retrofit: pre-execution context loading (cross-agent-learning E2)
```

Szablon commit message:

```
feat({agent-name}): retrofit pre-execution context loading (E2 cross-agent-learning)
```

Przyklad: `feat(code-implementer): retrofit pre-execution context loading (E2 cross-agent-learning)`

---

## TOP 5 — priorytetowe agenty do retrofitu

Kolejnosc wedlug: czestotliwosci uzycia + korzysci z historii bledow + model (opus/sonnet > haiku).

### 1. `library/agents/universal/code-implementer.md`

| Atrybut | Wartosc |
|---|---|
| Model | opus |
| Uzasadnienie priorytetu | Najczesciej uzywany w projektach webapp; pilot CRM 2026-04-28 wykazal powtarzalne bledy (.env leak, missing rollback); highest ROI z reflections |
| Wariant injection | A (Full — opus) |
| errors plik | `.claude/memory/errors-code-implementer.md` |

```
[ ] Step 1: name: code-implementer
[ ] Step 2: Wariant A wklejony jako krok 0
[ ] Step 3: errors-code-implementer.md placeholder stworzony
[ ] Step 4: version 1.0.0 -> 1.0.1, changelog dodany
```

### 2. `library/agents/universal/debugger-agent.md`

| Atrybut | Wartosc |
|---|---|
| Model | sonnet (upgrade do opus gdy potrzeba) |
| Uzasadnienie priorytetu | Konsument outputu code-implementer; bledy debuggera (zla diagnoza root-cause) bezposrednio kosztuja czas; reflections debuggera maja patterns o kontraktach I/O |
| Wariant injection | A (Full — sonnet/opus) |
| errors plik | `.claude/memory/errors-debugger-agent.md` |

```
[ ] Step 1: name: debugger-agent
[ ] Step 2: Wariant A wklejony jako krok 0
[ ] Step 3: errors-debugger-agent.md placeholder stworzony
[ ] Step 4: version bump + changelog
```

### 3. `library/agents/universal/tech-doc-writer.md`

| Atrybut | Wartosc |
|---|---|
| Model | sonnet (upgrade do opus gdy potrzeba) |
| Uzasadnienie priorytetu | Pilotaz CRM 2026-04-28 — 2 patche v1.0.1 juz znane (infra #1, scope creep #2); te wpisy powinny byc w errors-tech-doc-writer.md i konsumowane przy v1.1; reflections maja dane empiryczne z SC |
| Wariant injection | A (Full — sonnet/opus) |
| errors plik | `.claude/memory/errors-tech-doc-writer.md` |

```
[ ] Step 1: name: tech-doc-writer
[ ] Step 2: Wariant A wklejony jako krok 0
[ ] Step 3: errors-tech-doc-writer.md placeholder stworzony
[ ] Step 4: version bump + changelog
```

### 4. `library/agents/universal/plan-progress-tracker.md`

| Atrybut | Wartosc |
|---|---|
| Model | sonnet |
| Uzasadnienie priorytetu |  — nowy, kluczowy dla multi-plan-workflow; lessons o idempotency (2026-05-07 HIGH) powinny byc skonsumowane przy nastepnym uruchomieniu |
| Wariant injection | A (Full — sonnet) |
| errors plik | `.claude/memory/errors-plan-progress-tracker.md` |

```
[ ] Step 1: name: plan-progress-tracker
[ ] Step 2: Wariant A wklejony jako krok 0
[ ] Step 3: errors-plan-progress-tracker.md placeholder stworzony
[ ] Step 4: version bump + changelog
```

### 5. `library/agents/universal/plan-executor.md`

| Atrybut | Wartosc |
|---|---|
| Model | sonnet |
| Uzasadnienie priorytetu | Orkiestrator agentow — blad plan-executora kaskaduje do wszystkich sub-agentow; wczesny pre-context loading zapobiega powielaniu bledow z poprzednich sesji |
| Wariant injection | A (Full — sonnet) |
| errors plik | `.claude/memory/errors-plan-executor.md` |

```
[ ] Step 1: name: plan-executor
[ ] Step 2: Wariant A wklejony jako krok 0
[ ] Step 3: errors-plan-executor.md placeholder stworzony
[ ] Step 4: version bump + changelog
```

---

## Pozostale agenty — opportunistic retrofit

Retrofit przy nastepnej iteracji/patchu danego agenta. Brak hard deadline.

### Library agents (11 pozostalych)

| Agent | Lokalizacja | Model | Wariant |
|---|---|---|---|
| `commit-reviewer` | `library/agents/universal/` | sonnet | A (Full) |
| `session-router` | `library/agents/universal/` | haiku | B (Haiku-trim) |
| `requirements-interviewer` | `.claude/agents/` | opus | A (Full) |
| `agent-architect` | `.claude/agents/` | opus | A (Full) — ref E7 |
| `skill-builder` | `.claude/agents/` | sonnet | A (Full) |
| `quality-checker` | `.claude/agents/` | sonnet | A (Full) |
| `project-profiler` | `.claude/agents/` | opus | A (Full) |
| `project-bootstrap` | `.claude/agents/` | sonnet | A (Full) |
| `meta-reviewer` | `.claude/agents/` | opus | A (Full) |
| `pack-agent` | `.claude/agents/` | sonnet | A (Full) |
| `mistake-recorder` | `library/agents/universal/`  | haiku | B (Haiku-trim) |

Uwaga: `agent-architect` retrofit jest czescia E7 planu  — wykonuj jako E7, nie tutaj.

---

## Jesli retrofit konfliktuje z istniejacym workflow

**Sytuacja:** agent ma krok 1 ktory "wczytuje brief/kontekst" — czy krok 0 to duplikat?

Nie. Krok 0 (pre-context historyczny) i krok 1 (wczytanie biezacego briefu/zadania) sa rozne:
- Krok 0: przeszlosc — bledy, reflections, lessons. Nie zmienia inputu zadania.
- Krok 1: terazniejszosc — aktualny brief, karta projektu, wymagania.

Wstaw krok 0 przed krokiem 1 nawet jesli krok 1 juz czyta pliki. Nie sa w konflikcie.

**Sytuacja:** agent ma inna nazwe sekcji niz "## Workflow" (np. "## Instrukcja", "## Steps").

Wstaw sekcje "## Before starting work" jako pierwsza sekcje ciala agenta, przed jakakolwiek inna
sekcja workflow, niezaleznie od jej nazwy.

**Sytuacja:** agent jest bardzo krotki (< 30 linii), sekcja krok 0 to > 30% rozmiaru.

Uzyj Wariantu A ale bez HTML komentarzy (skrot o ~5 linii). Sekcja pre-context ma byc czytelna,
nie minimalistyczna — ale nie musi duplikowac komentarzy jesli agent-builder rozumie wzorzec.

---

## Dependent changes (informacja)

- **E7 (agent-architect update):** po retroficie TOP 5, agent-architect ma referencowac
  ten skill jako wzorzec dla nowych agentow. E7 jest osobnym etapem .
- **E3 (mistake-recorder):** nowy agent ktory bedzie producentem wpisow do errors-{name}.md.
  Po wdrozeniu E3 — errors-{name}.md beda uzupelniane automatycznie, nie recznie.
- **Reflections format (E7 context):** istniejace 12 reflections nie wymagaja update przez retrofit.
  Sa backward-compatible z glob patternem `{agent-name}*.md`.
