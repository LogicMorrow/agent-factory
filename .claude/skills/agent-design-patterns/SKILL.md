---
name: agent-design-patterns
description: Wzorce projektowania dobrych subagentów Claude Code. Uruchamiaj gdy projektujesz, recenzujesz lub refaktoryzujesz agenta w `.claude/agents/`.
---

# Wzorce projektowania agentów

## Kiedy w ogóle tworzyć agenta
Agent ma sens, gdy spełnione jest ≥1 z poniższych:
- Zadanie jest **powtarzalne** w wielu kontekstach (np. review kodu, walidacja).
- Zadanie wymaga **własnego system promptu** — innego niż główny agent (np. bardziej restrykcyjnego, z określoną rolą).
- Zadanie wymaga **ograniczonego zestawu narzędzi** (np. tylko read-only).
- Zadanie byłoby **szumem w głównym kontekście** (np. grep przez 200 plików).

Jeśli potrzebujesz tylko wiedzy referencyjnej — zrób **skill**, nie agenta. Skill ładuje się na żądanie, agent ma własny context window.

## Frontmatter — obowiązkowy zestaw pól
```yaml
---
name: nazwa-kebab-case
description: Kiedy uruchomić (konkretnie!). Idealnie 1–2 zdania + przykład wyzwalacza.
tools: Read, Write, Grep, Glob        # minimalny zestaw, rozdzielone przecinkami
model: opus | sonnet | haiku
---
```

## Jak pisać `description`
Złe: `Agent do kodu.`
Dobre: `Review kodu TypeScript pod kątem bezpieczeństwa i wydajności. Uruchamiaj po wygenerowaniu nowego pliku .ts/.tsx, przed commitem. Przykład: "zreview src/auth/login.ts".`

Zasada: description **uczy Claude kiedy delegować**. Jeśli jest mglisty, agent albo się nie uruchomi, albo uruchomi w złym momencie.

## Dobór modelu
- **opus** — projektowanie, analiza, bezpieczeństwo, refaktory wymagające zrozumienia całości.
- **sonnet** — standardowe pisanie kodu, walidacja, bootstrap, operacje CRUD na plikach.
- **haiku** — szybkie operacje: grep, format, przesuwanie plików, proste transformacje.

Nie wrzucaj wszystkiego na opus "dla bezpieczeństwa" — kosztuje i spowalnia.

## Minimalny zestaw `tools`
Startuj od `Read, Grep, Glob` i dodawaj tylko to co **konkretnie** agent potrzebuje.
- Walidator/reviewer → read-only (nigdy `Write`, `Edit`, `Bash`).
- Bootstrap/generator → `Read, Write, Bash` (z `Bash` tylko do `mkdir/cp`).
- Architekt agentów → `Read, Write, Glob` — nie potrzebuje `Bash`.

## Struktura system promptu
Każdy agent ma dokładnie te sekcje:

1. **Rola** — jedno zdanie, kim jesteś.
2. **Kiedy się uruchamiasz** — sytuacja wyzwalająca.
3. **Workflow** — numerowane kroki 3–6 punktów.
4. **Zasady jakości** — co obowiązkowo sprawdzasz/dostarczasz.
5. **Czego NIE robisz i do kogo odesłać** — obowiązkowe. Bez tego quality-checker odrzuca agenta.
6. **Format outputu** — co zwracasz do wołającego (tekst, plik, JSON?).

## Agent interaktywny (wariant prowadzony w głównej rozmowie)

Niektórzy agenci **nie są wywoływani przez `Agent` tool** — są prowadzeni w głównej konwersacji Claude Code przez głównego Claude, który wciela się w ich rolę. Wzorzec używany dla agentów, którzy **muszą zadawać pytania przed zakończeniem pracy** (zero pytań otwartych w output).

**Kiedy to wariant konieczny:**
- Wywiad z użytkownikiem (`requirements-interviewer`, `project-profiler`).
- Planowanie wymagające mini-wywiadu (`crm-task-planner`, `factory-planner`).
- Agent musi iterować dialog z użytkownikiem — `Agent` tool zwraca pojedynczą wiadomość, więc nie pasuje.

**Jak to wyraźnie oznaczyć w spec agenta:**

W sekcji "Kiedy się uruchamiasz" dodaj:

> Jesteś uruchamiany **w głównej konwersacji Claude Code** (jak `requirements-interviewer`), nie przez `Agent` tool. Prowadzisz dialog z użytkownikiem bezpośrednio — zadajesz pytania, dostajesz odpowiedzi, dopiero potem zapisujesz plik.

**Kiedy to wariant zły:**
- Agent wykonuje pracę bez pytania użytkownika (np. code-reviewer, bootstrapper) — tam `Agent` tool jest właściwy, bo zadanie jest deterministyczne i ma jeden output.

## Reguła "pytaj, nie zgaduj"
Jeśli wymagania są niekompletne — agent **ZATRZYMUJE się i pyta**. Nie improwizuje, nie dopisuje sobie założeń. To chroni przed cichymi błędami.

## Wzorzec: Atomowe wywołania z `WAITING_FOR_USER` dla agentów z HITL gate

**Problem:** subagenci wywoływani przez `Task` tool zwracają **pojedynczą wiadomość** — nie są natywnie interaktywni. Pętla "agent zadaje pytanie → czeka na response inline → kontynuuje" NIE DZIAŁA dla subagentów wywoływanych przez `Task`.

**Rozwiązanie:** każde wywołanie subagenta = 1 deterministyczny output JSON. Gdy potrzebny dialog z użytkownikiem (HITL gate — np. zatwierdzenie hipotezy ADR retro, eskalacja modelu sonnet→opus, klaryfikacja scope) — agent emituje status `WAITING_FOR_USER` z payloadem propozycji i kończy turn. Wznowienie = **nowe wywołanie** z dodatkowym polem w payloadzie (np. `approved_hypothesis: "<jedna z 3 hipotez>"`).

### Output JSON enum statusów (kanon dla agentów uniwersalnych)

```json
{
  "status": "DONE | ESCALATED | BLOCKED | WAITING_FOR_USER",
  "artifact_path": "<path lub null>",
  "reason": "<dla WAITING_FOR_USER: model_upgrade_recommended | hypothesis_approval_needed | scope_clarification | ...>",
  "payload": { /* dane potrzebne do wznowienia */ }
}
```

### Konsekwencja dla planu

Każdy agent uniwersalny z HITL gate generuje **2x sub-etapy w planie** (gate + finalny zapis). Plan-executor MUSI traktować `WAITING_FOR_USER` jako **intentional pause**, nie failure. To zmienia szacowanie czasu: 5 atomowych artefaktów z 3 ADR retro = **8 sub-etapów** (nie 5).

### Precedensy
- `tech-doc-writer` ADR retro — HITL gate motywacji (2-3 hipotezy → zatwierdzenie → finalny zapis).
- `debugger-agent` — protokół upgrade modelu (sonnet→opus) używa `reason: model_upgrade_recommended`.

**Anti-pattern:** agent w pętli pyta-odpowiada inline (połknięte przez `Task` tool, deterministyczność stracona). Jeśli potrzebny dialog → wariant interaktywny w głównej rozmowie (`requirements-interviewer` style), nie subagent.

## Wzorzec: Wyprzedzająca definicja kontraktów dla agentów wzajemnie zależnych (obu kierunków)

**Problem:** gdy projektujesz agenta A który będzie konsumentem agenta B (jeszcze nieistniejącego), brak kontraktu I/O wymusza mikro-wywiad między architektami w czasie projektowania B. Dodatkowo asymetria — architekt A definiuje tylko kontrakty *swoje* (od B do A), pomija reverse direction (od A do B w przyszłej delegacji).

**Rozwiązanie:** w sekcji "Sygnały dla następnych agentów" reflexji architekta A — wpisz **wszystkie** proponowane kontrakty JSON I/O w **obu kierunkach**:
- A → B (delegacja w przód: A wywołuje B)
- B → A (delegacja w tył: B wywołuje A)

Architekt B znajdzie reflection A i użyje 1:1.

### Reguła "obu kierunków"
Pattern działa **tylko jeśli reflection definiuje WSZYSTKIE kontrakty wychodzące z agenta**. Asymetria pojawia się gdy reflection skupia się tylko na kontrakcie wchodzącym (np. tech-doc-writer Input D od debuggera) i pomija wychodzący (Input E gdy debugger w przyszłości delegował do tech-doc-writer ADR retro). Wykrywane dopiero w E2E walidacji — naprawa wymaga patcha pliku już istniejącego sąsiada.

### Walidacja przy QC
Quality-checker dla agentów uniwersalnych MUSI sprawdzić:
- [ ] Każdy istniejący sąsiad referowany w "Delegujesz" / "Możesz być wywoływany przez" — kontrakt JSON pełny (nie tylko nazwa typu).
- [ ] Jeśli sąsiad to `<nazwa> (jeszcze nie istnieje, stan na YYYY-MM-DD)` — TODO patch w `next-session.md` przy stworzeniu tego sąsiada.
- [ ] `grep -r '(jeszcze nie istnieje|stan na YYYY-MM-DD)' library/` po stworzeniu agenta X — wszystkie hity to **post-creation cleanup pass** (krok 9.5 architekta, viz sekcja "Self-check architekta przed zapisem").

### Precedensy
- ✅ `code-implementer` reflection (2026-04-24) → Input A+B dla `debuggera` **przed istnieniem debuggera**.
- ✅ `debugger-agent` reflection (2026-04-24) → Input D dla `tech-doc-writera` **przed istnieniem tech-doc-writera**.
- ❌ `tech-doc-writer` reflection (2026-04-27) → Input D od debuggera 1:1 ✅, ALE Input E (reverse: tech-doc-writer ↔ debugger ADR retro) NIE wyprzedzająco zdefiniowany → asymetria wykryta E2E etap 13, naprawa +19 linii w `debugger-agent.md`.

**Anti-pattern:** reflection wymienia tylko najbardziej oczywiste kontrakty, pomija reverse-direction. Mitygacja: w self-check architekta (krok 7.5) zdefiniowany hard-stop "wszystkie kontrakty wychodzące w obu kierunkach" — viz sekcja "Self-check architekta przed zapisem agenta".

**Ograniczenie:** nie spekuluj o kontraktach dla agentów których powstanie jest niepewne. Definicja wyprzedzająca dotyczy agentów już zaplanowanych w roadmapie (`knowledge-base/plans/` lub `next-session.md`).

## Delegacja
Agenci nie powinni próbować robić wszystkiego. Jeśli wychodzi poza zakres — odsyłaj:
- Projektowanie agenta → `agent-architect`
- Budowa skilla → `skill-builder`
- Walidacja → `quality-checker`
- Analiza lekcji → `meta-reviewer`
- Bootstrap projektu → `project-bootstrap`
- **Projektowanie agenta-planisty** (planer modułów/featuresów w projekcie) → `agent-architect` + `requires: [planner-design-patterns]` w nowym agencie.
- **Zapis błędu do per-agent memory** → `mistake-recorder` (haiku, JSON in/out, idempotentny). Wzorzec `error-memory-framework`.
- **Cross-project recommendations brief** → `project-recommendations-writer` (opus, syntezuje lessons+reflections+activity-log+errors).
- **Raport ewolucji agentów fabryki** (META, factory-only) → `agent-evolution-reviewer` (opus, cross-references git log + lessons + reflections).

## Wzorzec: Cross-agent-learning — pre-execution context ( fabryki)

Każdy nowy agent (od 2026-05-07,  fabryki) MA mieć w body sekcję **"## Before starting work"** jako KROK 0 workflow:

```markdown
## Before starting work
1. Read `knowledge-base/reflections/` last 3 (lub docs/reflections/)
2. Read `knowledge-base/lessons.jsonl` tail 20
3. Read `.claude/memory/errors-{this-agent-name}.md` full (jeśli istnieje)
4. Apply silently — wzmianka w output tylko gdy decyzja zmieniona vs default
```

**Reguły:**
- Performance budget ~5k tokens. Trim priority: errors > reflections > lessons.
- Per-model tier: haiku → tylko errors-{name}.md (wąskie context); sonnet/opus → pełny.
- Apply silently rule: agent NIE wypisuje "wczytałem 3 reflections" — stosuje wnioski cicho. Wzmianka tylko gdy decyzja się zmienia ("Pomijam X bo lesson 2026-04-23 wykrył Y").

**Pełny wzorzec:** `library/skills/universal/cross-agent-learning/SKILL.md` + `injection-template.md` (boilerplate gotowy do wklejenia) + `retrofit-checklist.md` (5 priorytetowych agentów + 11 opportunistic).

**Wymóg dla architekta:** przy `/new-agent` v1.1+ (iteracja istniejącego agenta) — agent-architect MUSI przeczytać `errors-<agent-name>.md` PRZED projektowaniem patcha. Workflow agent-architect step 3 (zaktualizowany w  E7) zawiera ten wymóg.

## Wzorzec: Per-agent error memory ( fabryki)

Każdy agent w produkcji MA `.claude/memory/errors-<agent-name>.md` (per projekt, per agent) — pamięć błędów z formatu spec `error-memory-framework`:

- **Format wpisu:** `## YYYY-MM-DD — <short-title>` + 5 pól (error-summary, cause-root, prevention, severity LOW|MED|HIGH, context opcjonalne) + HTML komentarz `<!-- hash: <md5_8> -->` (idempotency).
- **Promotion rule:** severity=HIGH automatycznie promuje wpis do `lessons.jsonl` (cross-project relevant).
- **Cleanup:** >100 wpisów lub >180 dni → 25% FIFO archive do `errors-<name>.archive.md`.
- **Producent:** agent `mistake-recorder` (haiku, JSON in/out).
- **Konsument:** każdy agent w step 0 (cross-agent-learning) + agent-architect przy iteracji.

**Pełny spec:** `library/skills/universal/error-memory-framework/SKILL.md` + `format-spec.md` + `examples.md`.

**Hook supportowy:** `library/hooks/on-error-record.sh` (UserPromptSubmit) — soft-reminder dla Claude'a gdy user wspomina o błędzie ("Rozważ wywołanie mistake-recorder").

## Antywzorce (czego unikać)
- ❌ `tools: *` — brak kontroli, duże ryzyko niechcianych akcji.
- ❌ `description: pomaga z kodem` — za ogólnie, nie wywoła się poprawnie.
- ❌ Brak sekcji "czego NIE robi" — agent wchodzi na cudze terytorium.
- ❌ Model `opus` dla operacji plikowych — marnowanie zasobów.
- ❌ Agent który modyfikuje i waliduje — rozdziel odpowiedzialności.
- ❌ **Brak kroku 0 "Before starting work"** w nowym agencie (od  fabryki) — pomija cross-agent-learning, agent powtarza znane błędy.
- ❌ **Pre-context jako dump** — agent kopiuje surowy content reflections/lessons do output. Apply silently rule wymaga ciszy (chyba że decyzja zmieniona).
- ❌ Agent interaktywny wywoływany przez `Agent` tool — subagent nie jest natywnie interaktywny, pytania użytkownika zostaną połknięte. Użyj wariantu prowadzonego w głównej rozmowie.

## Przykłady: dobrze vs źle

### Para 1 — `description` (najważniejszy element dla routingu CC)

❌ **Źle:** `description: Agent do kodu.`

✅ **Dobrze:** `description: Review kodu TypeScript pod kątem bezpieczeństwa i wydajności. Uruchamiaj po wygenerowaniu nowego pliku .ts/.tsx, przed commitem. Przykład wyzwalacza: "zreview src/auth/login.ts".`

**Dlaczego:** `description` uczy Claude *kiedy* delegować. Pierwsza wersja to szum — agent nie uruchomi się albo uruchomi chaotycznie. Druga wersja daje routingowi 3 sygnały: domena (TypeScript), moment (po wygenerowaniu, przed commitem), konkretny przykład (co user napisze).

### Para 2 — `tools` (minimalizm, nie "na zapas")

❌ **Źle:**
```yaml
tools: Read, Write, Edit, Bash, Grep, Glob, WebFetch
# "na wszelki wypadek"
```

✅ **Dobrze (dla walidatora read-only):**
```yaml
tools: Read, Grep, Glob
```

✅ **Dobrze (dla bootstrappera — z uzasadnieniem):**
```yaml
tools: Read, Write, Bash   # Bash tylko do mkdir/cp, nie npm install bez autoryzacji
```

**Dlaczego:** każde narzędzie to potencjalna akcja uboczna. `Edit` w walidatorze = ryzyko że agent "naprawi" coś co miał tylko zweryfikować. `WebFetch` bez jasnego powodu = niekontrolowany ruch sieciowy. Minimalizm to bezpieczeństwo, nie skąpstwo.

### Para 3 — sekcja "Czego NIE robi"

❌ **Źle (agent webapp-code-reviewer):**
```markdown
# Czego NIE robisz
- Nie naprawiasz błędów.
```

✅ **Dobrze (ten sam agent):**
```markdown
# Czego NIE robisz i do kogo odesłać
- Nie naprawiasz błędów — raportujesz. Naprawę robi deweloper lub `agent-architect` przy refaktorze.
- Nie walidujesz skilli → `quality-checker` (inny typ walidacji).
- Nie robisz review commita → `commit-reviewer` (universal).
- Nie analizujesz architektury projektu → `agent-architect` + karta projektu.
```

**Dlaczego:** pierwsza wersja to tylko "co NIE", bez "dokąd". Agent napotykający scope creep nie wie jak odesłać użytkownika dalej — albo się zatrzymuje, albo (gorzej) obejmuje cudze zadania. Druga wersja daje routing nawet w momencie odmowy.

## Self-check architekta przed zapisem agenta (krok 7.5 workflow architekta)

PRZED `Write library/agents/<kat>/<nazwa>.md` (lub `.claude/agents/<nazwa>.md` dla meta-agentów) — wykonaj checklistę meta. Każdy punkt FAIL = NIE pisz, popraw projekt i ponów check.

### Strukturalne
- [ ] **Sekcja "Workflow" istnieje jako osobna sekcja** — nie wystarczy wbudować workflow w "Rolę" lub "Format outputu".
- [ ] **Workflow ma 3-6 ponumerowanych głównych kroków** (sub-numeracja `1a/1b/1c` jest OK i nie liczy się do limitu). *Wyjątek:* agenci-planiści mogą mieć więcej kroków — udokumentuj odchylenie w reflexji/ADR i wczytaj `planner-design-patterns`.
- [ ] **Sekcja "Czego NIE robi i do kogo odesłać"** ma min. 3 pozycje z konkretnymi delegatami (nie ogólniki typu "do innego agenta").
- [ ] **Frontmatter library extended** (dla agentów w `library/`): `name`, `description`, `tools`, `model` + `tags`, `category`, `compatible_with`, `version`, `token_cost`, `requires`. Dla meta-agentów (`.claude/agents/`) — minimal frontmatter wystarczy.

### Kontrakty I/O — symetria w obu kierunkach
- [ ] **Wszystkie kontrakty wychodzące z agenta wymienione** w sekcji "Sygnały dla następnych agentów" w reflexji architekta — w obu kierunkach (A→B i B→A), nie tylko najbardziej oczywiste.
- [ ] **Każdy istniejący sąsiad zweryfikowany pod kątem reverse-direction** — gdy projektujesz agenta C który ma sąsiada B (już istniejącego w `library/`), `grep` `library/agents/.../B.md` szukając referencji do C; jeśli B nie referuje C w sekcji "Delegujesz" / "Możesz być wywoływany przez" — flag jako TODO patch w reflexji + appenduj patch do `B.md`.
- [ ] **Stale placeholders post-creation** — po stworzeniu agenta X, `grep -r '(jeszcze nie istnieje|stan na YYYY-MM-DD|TODO patch po dodaniu)' library/` — wszystkie hity to TODO patch w plikach delegujących, do wykonania w tym samym etapie planu.

### Spójność z briefem
- [ ] **Każdy wymóg z briefu** (sekcja "Wymagania F1-FN") odzwierciedlony w pliku agenta — w reflexji rób explicit mapping `F1 → krok N workflow` / `F2 → sekcja Zasady jakości punkt M`.
- [ ] **Decyzje techniczne zgodne z kartą projektu** — jeśli brief referuje kartę `knowledge-base/projects/<slug>.md`, decyzje stack/porty/integracje muszą być zgodne (lub wymagać tryb B karty PRZED zapisem agenta).

### Po zapisie (cleanup pass)
- [ ] **Patche stale references** w plikach delegujących (z lessons #1, #6 + meta-reflection Porażka 3) — np. dodanie agenta C wymaga patcha A i B żeby zaczęły go referować w "Delegujesz".
- [ ] **library-index.json bumped** (jeśli agent w `library/`) — wpis dodany lub zaktualizowany.
- [ ] **Reflection w `knowledge-base/reflections/YYYY-MM-DD-<nazwa>.md`** zapisany ze wszystkimi 4 sekcjami (problem, decyzje, wzorce zaobserwowane, sygnały dla następnych agentów).

**Liczba punktów łącznie:** ~13 boolean checks. Reflection tech-doc-writer (2026-04-27) wykonał podobny self-check w ~5 minut — to nie jest długi blocker, tylko świadoma walidacja.

## Powiązania

- **`skill-design-patterns`** (`.claude/skills/skill-design-patterns/`) — gdy zamiast agenta potrzebujesz skilla (paczki wiedzy bez własnego workflow).
- **`model-routing`** (`.claude/skills/model-routing/`) — dobór modelu per zadanie (opus / sonnet / haiku).
- **`planner-design-patterns`** (`.claude/skills/planner-design-patterns/`) — **specjalizacja** tego skilla dla agentów-planistów (planujących moduły/refaktory projektów). Zawiera 8 dodatkowych wzorców (workflow 6 kroków, kolumna Executor, 3 typy scope, wariant interaktywności, pre-flight check, samoreferencyjność, self-check pre-save, pytaj-nie-zgaduj). Gdy brief agenta wskazuje rolę planisty — wczytaj oba skille (`agent-design-patterns` + `planner-design-patterns`).
- **`agent-architect`** (`.claude/agents/`) — konsument tego skilla przy projektowaniu każdego nowego agenta.
- **`quality-checker`** (`.claude/agents/`) — używa checklisty z tego skilla przy walidacji.
