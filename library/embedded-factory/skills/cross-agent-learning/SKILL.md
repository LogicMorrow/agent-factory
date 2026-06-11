---
name: cross-agent-learning
version: "1.1.0"
type: skill
category: universal
description: "Use when designing or iterating any agent (v1.1+) that should learn from past mistakes. Defines pre-execution context loading pattern: agent reads reflections/ last 3 + lessons.jsonl tail 20 + .claude/memory/errors-{name}.md full as STEP 0 of workflow. Apply silently — reference only when behavior changes vs default. v1.1.0 dodaje sekcję 'Embedded mode' dla projektów z embedded-factory (per-projekt knowledge-base, cold start thresholds, scaffold layout)."
compatible_with: [universal, embedded-factory]
requires: [error-memory-framework]
tags: [learning, cross-agent, pre-execution, context-loading, universal, embedded-mode]
token_cost: medium
files:
  - SKILL.md
  - injection-template.md
  - retrofit-checklist.md
---

# cross-agent-learning

Wzorzec pre-execution context loading dla agentow. Powstal po identyfikacji problemu #8
masterplanu fabryki (2026-05-07): 12 reflections + 44 lessons nigdy nie czytane automatycznie
przed pracy agentow — kazdy startuje z bialej kartki mimo ze fabryka ma bogate archiwum wiedzy.

E2  learning loop. Precondition dla E3 (mistake-recorder), E4 (project-recommendations-writer),
E5 (agent-evolution-reviewer). Wymaga E1 error-memory-framework (format errors-{name}.md).

---

## 1. Kiedy uruchomiac

**Uruchamiaj gdy:**
- Projektujesz nowego agenta v1.0 od  — wklej injection-template.md jako krok 0 workflow
- Iterujesz istniejacego agenta (v1.1+) — dodaj sekcje "Before starting work" przez retrofit-checklist.md
- Piszesz agenta `agent-architect` / `agent-evolution-reviewer` i chcesz wiedziece co czytac przed pracy
- Pojawia sie pytanie "jak agent ma konsumowac swoje reflections i lessons?" — tu jest odpowiedz

**NIE uruchamiaj gdy:**
- Chcesz ZAPISAC blad agenta — to robi `mistake-recorder` (E3) zgodnie z `error-memory-framework` (E1)
- Chcesz analizowac wzorce cross-agent globalnie — to zakres `agent-evolution-reviewer` (E5)
- Agent jest haiku i wykonuje prosta transformacje bez historii — pre-context tylko errors-{name}.md (patrz sekcja 4)

---

## 2. Pre-execution context — 3 zrodla

Kazdy agent z sekcja "## Before starting work" czyta 3 zrodla PRZED przystapnieniem do zadania.

**Priorytet (od najbardziej specyficznego):**

| # | Zrodlo | Co czytac | Jak |
|---|---|---|---|
| 1 | `.claude/memory/errors-{this-agent-name}.md` | Pelna zawartosc (max 100 wpisow wg E1) | `Read` — jesli plik nie istnieje: skip cicho |
| 2 | `.claude/knowledge-base/reflections/{this-agent-name}*.md` | 3 najnowsze (sort desc po nazwie pliku) | `Glob` po `{this-agent-name}*.md`, sort desc, head 3, `Read` kazdy |
| 3 | `.claude/knowledge-base/lessons.jsonl` | Tail 20 wierszy | `Read` z offset=total-20 lub `Bash: tail -n 20` |

**Dlaczego cross-agent dla lessons.jsonl (bez filtra po agencie):**
Lessons z innych agentow zawieraja wzorce o projekcie/kliencie/architekturze — nie tylko o danym agencie.
Przyklad: lesson o `.env leak` z 2026-05-06 jest waznie dla code-implementer nawet jesli incident byl z
innego agenta. Cross-agent learning jest feature, nie szum. Jesli agent potrzebuje zawezionego scope —
grep po polu `agent` w JSON po wczytaniu.

**Glob pattern dla reflections:**
- Pattern: `.claude/knowledge-base/reflections/{this-agent-name}*.md`
- Konwencja nazwy pliku reflections: `YYYY-MM-DD-{agent-name}[-opis].md` (output agent-architect)
- Sort descending = najnowsze najpierw (leksykograficzny order na prefix YYYY-MM-DD wystarczy)
- Jesli glob zwraca 0 wynikow: skip cicho (brak reflections to normalny stan dla nowego agenta)

---

## 3. Performance budget i trim policy

**Limit: ~5 000 tokenow (okolo 800-1 200 linii markdown)**

Jesli suma wszystkich zrodel przekracza limit — trim wedlug priorytetu (zachowaj najbardziej specyficzne):

```
errors-{name}.md  >  reflections (last 3)  >  lessons.jsonl tail 20
```

**Trim policy krok po kroku:**
1. Policz szacunkowy rozmiar kazdego zrodla (liczba linii × ~0.75 tokena/linia)
2. Jesli suma <= 5k: wczytaj wszystko
3. Jesli > 5k: pominij lessons.jsonl (najszerzej dostepne, najmniej specyficzne dla agenta)
4. Jesli nadal > 5k: ogranicz reflections do 1 (najnowszy zamiast 3)
5. W ostatecznosci: zostaw tylko errors-{name}.md (zawsze)

**errors-{name}.md jest nigdy nie przycinany** — to najbardziej specyficzna wiedza agenta.

---

## 4. Per-model tier

| Model tier | Pre-context | Uzasadnienie |
|---|---|---|
| **opus** | Pelny — 3 zrodla, max 5k tokenow | Zlozone zadania wymagaja pelnego kontekstu historycznego |
| **sonnet** | Pelny — 3 zrodla, max 5k tokenow | Kodowanie/budowanie korzysta z cross-agent lessons |
| **haiku** | Tylko `errors-{name}.md` (max 1 500 tokenow) | Haiku: proste transformacje, waski kontekst, cost-sensitive |

**Haiku-trim (krok 0 uproszczony):**
- Czytaj tylko `.claude/memory/errors-{this-agent-name}.md`
- Jesli nie istnieje: krok 0 = noop (brak historii bledow)
- Pomijaj reflections i lessons (zbyt szerokie dla haiku budget)

Przyklad agentow haiku z trim: `mistake-recorder` (E3).

---

## 5. "Apply silently" rule

**Agent NIE wypisuje pre-context do outputu.** Nie raportuje co wczytal, nie cytuje reflections w outputcie,
nie wymienia lessons by name w normalnym flow. Stosuje wnioski cicho w swoich decyzjach.

**Wzmianka dozwolona wylacznie gdy:**
- Decyzja agenta faktycznie sie zmienia vs default zachowanie (pomijanie kroku, wybor innej metody, ostrzezenie)
- Wzmianka musi zawierac referencje: date + id lesson ALBO sciezka pliku reflection

**Format wzmianki (1 zdanie, konkretne):**

✅ Dobrze:
```
Pomijam X bo lesson 2026-04-23 wykryl podobny pattern (agent-factory lessons.jsonl:1).
```
```
Stosuje wariant Y (ref: .claude/knowledge-base/reflections/2026-04-27-code-implementer-pilot.md — sekcja Failures).
```

❌ Zle:
```
Wczytalem 3 reflections. Oto co znalazlem: [kopiuje zawartosc reflection]
```
```
Pomijam X. (bez referencji — naruszenie spec)
```

---

## 6. Przykladowy flow (code-implementer z retrofitem)

Scenariusz: code-implementer v1.1 ma sekcje "## Before starting work". Nowa sesja, zadanie "dodaj endpoint POST /users".

**Krok 0 — Before starting work:**
1. `Read .claude/memory/errors-code-implementer.md` — znaleziono 2 wpisy (`.env leak HIGH`, `missing rollback MED`)
2. `Glob .claude/knowledge-base/reflections/code-implementer*.md` — 3 pliki, read najnowszy `2026-04-27-code-implementer-pilot.md`
3. `Read .claude/knowledge-base/lessons.jsonl` tail 20 — wczytano 20 lessons, w tym 4 dotyczace bezpieczenstwa

**Krok 1 — zadanie wlasciwe:**
Agent implementuje endpoint. Nie wspomina pre-context. Ale:
- Automatycznie nie eksponuje env vars w odpowiedzi (errors-code-implementer.md: HIGH .env leak)
- Dodaje transaction rollback do SQL (errors: MED missing rollback)
- Wzmiankuje w outputcie (bo zmiana vs default): "Dodaje explicit rollback w bloku try/catch — ref: errors-code-implementer.md 2026-05-06 missing rollback."

---

## 7. Czego skill NIE robi

- **Nie zapisuje bledow do errors-{name}.md** — to robi `mistake-recorder` (E3) zgodnie z `error-memory-framework` (E1)
- **Nie modyfikuje agentow retroaktywnie** — retrofit jest dobrowolny i opt-in; istniejace agenty bez sekcji dzialaja dalej
- **Nie wymusza hard-fail dla agentow bez sekcji** — brak "Before starting work" = brak pre-context, nie blad
- **Nie agreguje pre-context z wielu agentow** — kazdy agent czyta SWOJE zrodla; globalny widok to zadanie `agent-evolution-reviewer` (E5)
- **Nie waliduje ze agent rzeczywiscie zastosowal wnioski** — to zadanie post-execution review (E5)
- **Nie czyta plikow sam** — skill opisuje WZORZEC; egzekucja Read/Glob lezy po stronie agenta-konsumenta

---

## 8. Antywzorce

| Antywzorzec | Problem | Poprawka |
|---|---|---|
| ❌ Pre-context dump w outputcie | Agent kopiuje reflections/lessons do odpowiedzi — token waste, spam dla uzytkownika | Apply silently — wzmianka tylko gdy decyzja sie zmienia |
| ❌ Budget overflow ignorowany | Agent czyta 10k tokenow pre-context i kontynuuje bez trima | Trim policy: errors > reflections > lessons; limit 5k |
| ❌ Wzmianka bez referencji | "Pomijam X" bez daty/sciezki zrodla — niezweryfikowalne | Zawsze podaj date lesson lub sciezke pliku reflection |
| ❌ Sekcja "Before starting work" w srodku workflow | Wepchniety np. jako krok 3 zamiast krok 0 | Sekcja MUSI byc pierwszym krokiem (krok 0) przed kazdym innym krokiem |
| ❌ Reflections glob bez filtra po nazwie agenta | Agent czyta wszystkie 12 reflections zamiast swoich 3 — token waste + brak specyficznosci | Glob `{agent-name}*.md` — filtr po prefixie nazwy agenta |
| ❌ Hard-fail gdy brak errors-{name}.md | Crash gdy plik nie istnieje (nowy agent nie ma historii bledow) | Skip cicho gdy brak pliku — brak historii bledow to normalny stan |

---

## 9. Backward compatibility

Istniejace agenty BEZ sekcji "## Before starting work" dzialaja bez zmian. Skill jest opt-in:
- Nowe agenty od : sekcja obowiazujaca w spec
- Istniejace agenty: retrofit wedlug `retrofit-checklist.md` — dobrowolny, wg priorytetu

**Brak hard requirement retroaktywnego.** Fabryka nie padnie bez retrofitu. Kazdy retrofit
to incremental improvement, nie blocker.

---

## 10. Konsumenci skilla

| Konsument | Model | Tryb pre-context | Etap  | Status |
|---|---|---|---|---|
| `mistake-recorder` | haiku | haiku-trim (tylko errors) | E3 | do stworzenia |
| `project-recommendations-writer` | opus | pelny (3 zrodla) | E4 | do stworzenia |
| `agent-evolution-reviewer` | opus | pelny (3 zrodla), META | E5 | do stworzenia |
| `code-implementer` | opus | pelny (3 zrodla) | retrofit TOP 1 | do retrofitu |
| `debugger-agent` | sonnet/opus | pelny (3 zrodla) | retrofit TOP 2 | do retrofitu |
| `tech-doc-writer` | sonnet/opus | pelny (3 zrodla) | retrofit TOP 3 | do retrofitu |
| `plan-progress-tracker` | sonnet | pelny (3 zrodla) | retrofit TOP 4 | do retrofitu |
| `plan-executor` | sonnet | pelny (3 zrodla) | retrofit TOP 5 | do retrofitu |
| `agent-architect` | opus | pelny (3 zrodla) | E7 update | do retrofitu |

---

## 10b. Embedded mode (od v1.1.0, )

Gdy ten skill jest bundlowany w paczce `af-pack-*` (przez `library/embedded-factory/`), zmienia się **lokalizacja knowledge-base** i **thresholdy cold start**.

### Lokalizacja knowledge-base (per-projekt)

W trybie embedded agent czyta z `.claude/knowledge-base/` zamiast centralnej fabryki:

| Plik | Tryb fabryki | Tryb embedded (paczka) |
|---|---|---|
| Reflections | `.claude/knowledge-base/reflections/` | `.claude/.claude/knowledge-base/reflections/` |
| Lessons | `.claude/knowledge-base/lessons.jsonl` | `.claude/.claude/knowledge-base/lessons.jsonl` |
| Activity-log | `.claude/knowledge-base/activity-log.jsonl` | `.claude/.claude/knowledge-base/activity-log.jsonl` |
| Errors per-agent | `.claude/memory/errors-{name}.md` | `.claude/.claude/knowledge-base/errors/errors-{name}.md` |
| Candidate lessons (Path 1) | `.claude/.claude/knowledge-base/candidate-lessons.jsonl` | `.claude/.claude/knowledge-base/candidate-lessons.jsonl` |

**Path resolution:** używaj `$CLAUDE_PROJECT_DIR` lub fallback `$(pwd)` — w fabryce expand do `~/agent-factory`, w paczce do `~/projekty/<projekt>`. Build-script (ADR 009) auto-transformuje ścieżki przy bundling.

### Cold start thresholds (mniejsze niż fabryka)

Paczka startuje z 0 lessons. Cold start protection per agent:

| Agent embedded | Threshold fabryka | Threshold embedded | Powód |
|---|---|---|---|
| `pattern-detector-lite` | <50 lessons | **<10 lessons** (4-stopniowa matrix: <5/5-9/≥10/≥30) | mniejszy projekt, statystyczny floor wystarcza |
| `self-pilot-lite` | <50 lessons | **<10 lessons** (adaptive 3-section vs 5-section report) | reuse pattern-detector-lite floor |
| `version-bumper` | confidence ≥2.0 | confidence ≥1.5 | mniej lessons źródłowych, niższy próg |
| `mistake-recorder` | sev HIGH → lessons.jsonl | sev HIGH → lokalny lessons.jsonl (NIE fabryka) | per-projekt scope |

### Auto-start przy każdej sesji (SessionStart hook embedded)

Paczka MA `hooks/session-start-embedded.sh` (native artefakt embedded-factory) który:

1. Czyta lokalny `.claude/knowledge-base/` przy każdym uruchomieniu sesji
2. Wstrzykuje summary do kontekstu main Claude (5 sekcji: lessons + reflections + errors + activity + pending candidates)
3. Resetuje `.session-candidate-count` (counter dla Path 1 hook userPromptSubmit-conversation-learning frequency)
4. Performance: <200ms, budget context: <3k chars (~750 tokens)

**Implication:** każdy agent embedded ma "Before starting work" KROK 0 spełniony automatycznie przez SessionStart hook. Workflow agenta NIE musi re-czytać tych źródeł (już są w kontekście).

### Federacja do fabryki (`/promote-lessons`)

Lessons z paczki mogą wrócić do centralnej fabryki przez:

1. **Lokalny capture** → SessionStart hook + Path 1 conversation-learning hook + manual `/log-lesson` w projekcie
2. **HITL review** → `/review-candidate-lessons` (z 10A) → promotion do lokalnego `.claude/.claude/knowledge-base/lessons.jsonl`
3. **Promotion do fabryki** → `/promote-lessons` (10B.E11) → push branch `learning/<date>` na repo paczki
4. **Cron pull-merge** → fabryka monthly intelligence (10B.E14) pulluje branches, filtruje confidence ≥3 cross-projektowo, HITL gate → `improvement-proposals/auto-pull-merge-*.md` → operator approve → merge do centralnego `lessons.jsonl` z `origin: af-pack-<nazwa>`

**Konwencja `origin` w lessons.jsonl v2 schema (10B.E13):**
- `origin: "factory"` — lesson powstał w agent-factory (centralna fabryka)
- `origin: "af-pack-<nazwa>"` — promoted z paczki CRM
- `origin: "conversation-learning-hook"` — z Path 1 hook (przed promotion: `triggered_by`)

### Anti-patterns embedded mode

- ❌ **NIE czytaj centralnej fabryki w embedded** — agent embedded ma TYLKO `.claude/knowledge-base/` (lokalny). Cross-projektowe lessons przychodzą przez federację, NIE bezpośredni dostęp.
- ❌ **NIE hardcoduj ścieżek fabryki** w embedded agencie — używaj `$CLAUDE_PROJECT_DIR`. Build-script sed-replace ale agent powinien być portable od początku.
- ❌ **NIE auto-promotion bez HITL** w `/promote-lessons` — analogicznie do `/review-candidate-lessons` w 10A. HITL gate zawsze.
- ❌ **NIE pollute lokalny lessons.jsonl** z innych projektów — `origin: af-pack-<nazwa>` to znak że federacja zaszła źle. Konsumer paczki widzi TYLKO swoje lessons + ewentualnie merged factory-promoted.

### Patrz też

- `library/embedded-factory/README.md` — overview struktur
- `library/embedded-factory/manifest.json` — kontrakt B (lista wszystkich artefaktów)
- `library/embedded-factory/UPGRADE.md` — workflow `/upgrade-factory`
- ADR 009 (copy strategy), 010 (self-pilot-lite), 011 (pattern-detector-lite)

## 10c. Changelog

- **v1.1.0 (2026-05-24, .E7):** dodana sekcja "10b. Embedded mode" (~80l) — lokalizacja knowledge-base per-projekt, cold start thresholds (<10 lessons w embedded vs <50 w fabryce), auto-start przez SessionStart hook embedded, federacja przez `/promote-lessons` + `/pull-promoted-lessons`, schema v2 conventions (origin/confidence_hits/promoted_at), 4 anti-patterns embedded-specific. `compatible_with` rozszerzone o `embedded-factory`. `tags` + `embedded-mode`.
- **v1.0.0 (2026-05-07, ):** Initial skill — pre-execution context loading (reflections last 3 + lessons.jsonl tail 20 + errors-{name}.md), apply silently rule, 4 per-model tiers, retrofit-checklist.md companion file.

## 11. Powiazania

- **`injection-template.md`** (ten katalog) — gotowy boilerplate sekcji "## Before starting work" do copy-paste
- **`retrofit-checklist.md`** (ten katalog) — 4-stepowa checklista retrofitu + TOP 5 priorytetowych agentow
- **`error-memory-framework`** (`library/skills/universal/error-memory-framework/`) — E1; definiuje format `errors-{name}.md` ktory ten skill każe czytac. **Required dependency.**
- **`mistake-recorder`** (`library/agents/universal/mistake-recorder.md`) — E3; producent wpisow do errors-{name}.md
- **`agent-evolution-reviewer`**  — konsument globalny; analizuje tropy "lessons triggered patches" cross-agent
- **`model-routing`** (`library/skills/universal/model-routing/`) — decyduje o modelu agenta-konsumenta (wplywa na tryb pre-context)
- **`.claude/knowledge-base/plans/2026-05-06--learning-loop.md`** — E2 = ten skill; E1/E3-E7 = ekosystem
