---
name: planner-design-patterns
description: Wzorce projektowania agentów-planistów (CRM-task-planner, factory-planner, kolejne). Wczytywany przez `agent-architect` gdy brief wskazuje rolę planisty ("planer", "rozbija na etapy", "wyplata plan"), oraz przy review/refaktorze istniejącego planera. Zawiera 12 wzorców (#9 risk-matrix, #10 contingency, #11 session-checkpointing 20-30 min — dodane w -3 fabryki 2026-05-07; #12 embedded-factory awareness — dodany w  2026-05-24), 11 antywzorców i 3 pary "dobrze vs źle" z realnych iteracji (crm-task-planner iter 1-3, factory-planner iter 1).
---

# Wzorce projektowania agentów-planistów

Specjalizacja skilla `agent-design-patterns` dla klasy agentów, których jedyną odpowiedzialnością jest wyplecenie chronologicznego planu `.md` z etapami, zależnościami, routingiem modeli i egzekutorem — zanim ruszy wykonanie.

## Kiedy uruchomić

- `agent-architect` projektuje agenta, którego brief opisuje rolę **planisty** (frazy: "planuje", "rozbija na etapy", "wyplata plan przed startem modułu/refaktoru", "planuje rozbudowę X"). Wtedy ten skill wczytujesz DODATKOWO do `agent-design-patterns` (baza) — nie zamiast.
- Review istniejącego planera (np. operator: "zreview crm-task-planner") — skill służy jako punkt odniesienia dla `quality-checker`/`agent-architect` do porównania z wzorcami.
- Refaktor planera po `meta-reviewer`, jeśli lessons wskazują nowy wzorzec do dopisania tutaj.

## Kluczowe zasady (12 wzorców)

### 1. Workflow 6 kroków (nie więcej)

Agent-planista ma dokładnie 6 głównych kroków: `pre-flight → zakres+wywiad → etapy+newralgiczność+Executor → dokumentacja+testy → self-check → zapis+raport`. Podnumeracja (2a/2b/2c, 3a/3b/3c) dozwolona i zalecana — zachowuje granularność bez łamania limitu `agent-design-patterns` (3–6 kroków).

**Uzasadnienie:** 10 rozsypanych kroków zaciemnia intent i utrudnia agentowi śledzenie postępu. Kroki "zakres" i "wywiad" zawsze wykonują się razem — muszą być jednym blokiem. Tak samo "etapy" i "newralgiczność", "dokumentacja" i "testy", "zapis" i "raport".

**Reguła pisania:** najpierw szkic 6 głównych bloków, DOPIERO potem podkroki. Nie odwrotnie.

### 2. Kolumna Executor w output planu (4 wartości)

Każde zadanie w tabeli etapów planu MUSI mieć jawnego Executora — jedną z czterech wartości:

- **`<nazwa-agenta>`** — subagent z `.claude/agents/` lub `library/agents/` z `model:` zgodnym z kolumną Model CC.
- **`/slash-command`** — meta-komenda (np. `/new-agent`, `/new-skill`, `/project-profile`). Obowiązkowa dla etapów meta-operacji fabryki. W planerach projektów aplikacyjnych bez meta-operacji kolumna może mieć tylko 3 wartości.
- **`main`** — główny Claude w terminalu. Jeśli Model CC ≠ aktualny — opis etapu zawiera `/model <x>` przed i po.
- **`NEW: <nazwa>`** — agent jeszcze nie istnieje; trafia do osobnej sekcji "Brakujący agenci" z rolą/modelem/tools do `/new-agent`.

**Reguły obowiązkowe dla Executora (wynikają z CLAUDE.md fabryki):**

1. Etap tworzący nowego agenta → `/new-agent` (NIE `agent-architect` bezpośrednio — pomija wywiad, łamie zasadę #1).
2. Etap tworzący nowy skill → `/new-skill`.
3. Etap aktualizujący kartę projektu → `/project-profile` (tryb B).
4. Etap analizujący lessons/reflections z propozycją zmiany → `meta-reviewer`.
5. Etap walidujący wyprodukowany artefakt → `quality-checker`.

**Uzasadnienie:** tag "Model CC" to tylko informacja. Realnie model jest użyty dopiero gdy zadanie wykonuje subagent z `model:` w frontmatter lub operator ręcznie `/model`. Bez Executora plan jest teoretyczny — nie gwarantuje że routing modeli faktycznie się stanie.

**Walidacja przy QC (lesson #2 z 2026-04-23):** quality-checker dla planów MUSI sprawdzić obecność kolumny Executor we wszystkich etapach tabeli. Brak kolumny lub etap bez wartości = **BLOCKER** (severity HIGH — bez tego plan jest "intencjonalnym napisem", nie planem wykonalnym przez `plan-executor`). Pierwsza wersja crm-task-planner [iter 1-2] nie miała kolumny Executor — wymusiło to iterację 3 i kolejne wywołanie opusa.

### 3. Trzy typy scope (deterministyczne drzewo decyzji)

Planer na starcie klasyfikuje temat do jednego z trzech typów:

- **`new-element`** — tworzymy nowy element od zera (moduł, agent, skill, standard).
- **`cross-cutting`** — dotykamy ≥2 istniejących elementów jednocześnie (refaktor wielu meta-skilli, zmiana wielu agentów).
- **`enhancement`** — rozbudowa 1 istniejącego elementu.

Drzewo decyzji: `1 element istniejący → enhancement`; `≥2 elementy → cross-cutting`; `od zera → new-element`. Jeśli z wypowiedzi użytkownika typ niejednoznaczny — **pierwsze pytanie** mini-wywiadu dotyczy typu.

**Uzasadnienie:** każdy typ ma inny zestaw pytań (dla `enhancement`: deficyt + backward compatibility; dla `cross-cutting`: lista dotkniętych elementów + kolejność aktualizacji; dla `new-element`: rola + MVP vs pełny). Bez typu scope planer zadaje pytania generyczne i przegapia edge-case refaktoru cross-cutting.

**Mapping lesson #3 (2026-04-23) na 3 typy:**

| Lesson #3 nazewnictwo | Typ skilla | Komentarz |
|---|---|---|
| "moduł z karty" (zamknięta lista 10 modułów z `knowledge-base/projects/<projekt>.md`) | `enhancement` z constraint `module_from_card_list: true` | Sekcja 3 planu "Wpływ na inne moduły" → tabela jednowierszowa |
| "refaktor cross-cutting" (dotyka >1 modułu lub poza listą karty) | `cross-cutting` | Sekcja 3 planu → tabela "moduł — wpływ" dla każdego dotykanego + sekcja "Cross-cutting concerns" |
| "rozbudowa istniejącego modułu" (kontynuacja, nie od zera) | `enhancement` | Sekcja 3 planu → diff "obecny stan vs docelowy" + lista plików do modyfikacji + lista plików do utworzenia |
| "od zera" (nowy moduł/agent/skill bez precedensu) | `new-element` | Sekcja 3 planu → rola + MVP vs pełny zakres |

**Walidacja przy QC (lesson #3):** quality-checker dla planów MUSI sprawdzić: (1) Typ scope explicit zadeklarowany we frontmatterze planu (`scope_type: new-element \| cross-cutting \| enhancement`), (2) sekcja 3 planu zgodna z formatem typu (jw. mapping). Brak typu scope w frontmatterze = BLOCKER. Plan może mieć więcej niż 1 typ scope w różnych fazach — wtedy każda faza ma własną klasyfikację we frontmatterze fazy.

### 4. Wariant interaktywności (c): uruchamianie w głównej konwersacji

Planer jest uruchamiany bezpośrednio w konwersacji Claude Code (wzorzec `requirements-interviewer`, `project-profiler`), NIE przez `Agent` tool. Dialog z użytkownikiem — pytanie, odpowiedź, pytanie, aż plan jest kompletny.

**Uzasadnienie:** `Agent` tool nie jest natywnie interaktywny. Planer MUSI dopytywać (reguła "pytaj, nie zgaduj" z `agent-design-patterns`) — zero pytań otwartych w finalnym pliku planu. `Agent` tool wymuszałby dwie tury z zewnętrznym stanem do utrzymania — niepraktyczne.

Konsekwencja: `description` frontmatter ma zawierać **konkretne frazy-wyzwalacze** (nie opis), po których główny Claude wie, że ma przekazać sterowanie planerowi.

### 5. Pre-flight check (hard-stop przed pierwszym pytaniem)

Zanim planer zada pierwsze pytanie użytkownikowi, wykonuje 3–4 sprawdzenia w stałej kolejności. Każde sprawdzenie ma hard-stop: brak → stop + komunikat co zrobić, żadnej improwizacji.

Minimalny zestaw:

1. **Skill `model-routing`** — agent odwołuje się do opus/sonnet/haiku; bez skilla w projekcie recipient planu nie ma referencji.
2. **Karta projektu** — źródło prawdy o stacku, portach, integracjach, modułach/obszarach.
3. **Folder planów** — czy już istnieje plan dla tego tematu (slug match). Jeśli tak — nie twórz drugiego, zaproponuj: wykonać / wznowić / zarchiwizować.
4. **Stan projektu/fabryki** — skan struktury (co już jest, co w trakcie, co puste). Chroni przed duplikowaniem istniejących elementów.

**Uzasadnienie:** pre-flight rozdzielony od workflow (osobna sekcja PRZED "Workflow" w spec agenta) jest czytelniejszy niż rozsianie sprawdzeń po krokach. Hard-stop wymusza świadome działanie użytkownika — lepiej przerwać raz, niż wygenerować plan oparty o nieistniejące fundamenty.

### 6. Samoreferencyjność (`is_reference_project: true`)

Jeśli karta projektu ma `is_reference_project: true` (obecnie: agent-factory), plany dotykające `.claude/` tego projektu lub `library/skills/` mają wyższą newralgiczność — są wzorcem dla wszystkich projektów klienckich korzystających z paczek. Planer musi:

- Trzymać boolean `reference_project_impact` w frontmatterze planu.
- Mieć podsekcję "Reference project impact" w sekcji "Wpływ" planu (kiedy `true`), wyliczającą pliki i wpływ na projekty klienckie.
- Mieć punkt w self-check pre-save, weryfikujący obecność tej podsekcji kiedy wymagana.

**Uzasadnienie:** bez tego flag samoreferencyjność działa na niekorzyść — plan który łamie zasadę projektu-wzorca propaguje złamanie do wszystkich konsumentów. Explicit flag + sekcja wpływu zamyka pętlę.

### 7. Self-check pre-save (fizyczny, nie deklaratywny)

Planer ma sekcję "Zasady jakości" z numerowaną listą 13–14 punktów kontrolnych, które AGENT WERYFIKUJE przed zapisem pliku. Jeśli którykolwiek punkt FAIL — plik NIE jest zapisywany, planer wraca do użytkownika z listą braków.

Minimalny core (13 punktów, z `crm-task-planner` iter 3):

1. Każde zadanie ma Model CC z uzasadnieniem.
2. Każde zadanie ma Executora (4/3 wartości).
3. Każde zadanie ma zależność (nr etapu lub "brak"); zero cykli.
4. Każdy etap ma zadanie dokumentacyjne.
5. Newralgiczne etapy oznaczone (`!!!` lub pogrubienie).
6. Zero pytań otwartych w sekcji "Ryzyka".
7. Migracje/breaking changes uwzględnione przed etapami zależnymi.
8. Integracje cross-module wymienione w "Wpływ".
9. Happy path + ≥2 edge cases.
10. Parametry środowiska potwierdzone (nie zgadywane — np. wersja frameworka).
11. Frontmatter kompletny.
12. Slug nazwy pliku = slug frontmatter.
13. Reguły obowiązkowe Executora przestrzegane.

**14-ty punkt (dla planerów meta-projektu):** explicite wylicz 9 zasad CLAUDE.md projektu-wzorca jako pod-checklistę.

**Uzasadnienie:** różnica między "agent który produkuje śmieci" a "agent który produkuje artefakt konsumowalny" to właśnie egzekwowany self-check, nie deklaratywny. `factory-planner` rozszerzył listę z 13 do 14 punktów właśnie przez dodanie wylistowanych 9 zasad CLAUDE.md fabryki.

### 8. Pytaj, nie zgaduj — tury po 2–5 pytań

Planer zadaje pytania w turach (max 5 pytań na raz), czeka na odpowiedzi, potem kolejna tura. Koniec dopytywania = zero pytań otwartych przed przejściem do rozbicia na etapy. Zapis pliku z pytaniem otwartym w sekcji "Ryzyka" = FAIL self-check pkt 6.

**Uzasadnienie:** plan z pytaniem otwartym jest niekompletny — wykonawca (główny Claude albo `plan-executor`) napotka niejasność i będzie musiał wracać do użytkownika. Lepiej dopytać raz na etapie planowania niż rozbić wykonanie.

**Konsekwencja dla `description` frontmatter:** planer MUSI mieć wpisane konkretne frazy-wyzwalacze (nie redukuj listy dla zwięzłości — routing CC jest lepszy im więcej przykładów widzi).

### 9. Risk-matrix wymagana dla planów >10 etapów

Plan z >10 etapami MUSI zawierać sekcję `Risk-matrix` z tabelą o kolumnach: `# | Ryzyko | Prawdop. | Impact | Mitigation | Contingency`. Wartości Prawdop./Impact: `LOW | MED | HIGH`. Minimum 5 ryzyk dla planów cross-cutting, 3 dla planów enhancement, 2 dla new-element. Wprowadzono w  fabryki (2026-05-07) po analizie planów: master-rozbudowa-fabryki (24 etapy bez risk-matrix), security-roadmap CRM (12 etapów bez risk-matrix) — oba przeszły z dryfem (commit hash niezgodny, ADR-004 vs 005).

**Uzasadnienie:** plan długi = wysokie ryzyko że jeden etap zawiedzie i zatrzyma cały łańcuch. Risk-matrix wymusza myślenie o "co może pójść nie tak" PRZED rozpoczęciem, nie ad-hoc. Plus jest checkpointem dla `quality-checker` (FAIL gdy `risk-matrix` nieobecne dla planu >10 etapów).

**Format minimalny:**
```markdown
### Risk-matrix
| # | Ryzyko | Prawdop. | Impact | Mitigation | Contingency |
|---|---|---|---|---|---|
| R1 | <konkretne ryzyko realizacji> | LOW/MED/HIGH | LOW/MED/HIGH | <co zapobiega> | <co zrobić jeśli się ziści> |
```

**Retroaktywność:** istniejące plany sprzed 2026-05-07 NIE wymagają retro patcha (zalecane, nie wymagane). Enforcement od  dla nowych planów factory-plannera i CRM-task-plannera.

### 10. Contingency obowiązkowy dla każdego ryzyka HIGH×HIGH lub HIGH×MED

W risk-matrix z wzorca #9, dla każdego ryzyka gdzie iloczyn `Prawdop. × Impact` jest `HIGH×HIGH` lub `HIGH×MED`, kolumna `Contingency` MUSI być wypełniona konkretną akcją (nie "TBD", nie "monitoring", nie pusta). Mitigation = co robimy żeby się NIE ziściło. Contingency = co robimy GDY już się ziściło.

**Przykład dobry vs zły:**

| Wzorzec | Mitigation | Contingency |
|---|---|---|
| **Źle** | Test cases inline | "Monitor failures" |
| **Dobrze** | Test cases inline | "Whitelist patternów w komentarzu skryptu, dokumentacja w skill jak zgłosić false-positive" |

**Uzasadnienie:** plan bez contingency = przy realizacji w trybie auto Claude napotka ryzyko, zablokuje się, czeka na user input. Z konkretnym contingency: agent wie co zrobić bez czekania (np. "Jeśli FAIL: dopisz sekcję X do skill, kontynuuj").

**Retroaktywność:** jak #9.

### 11. Session checkpointing — dziel pracę na samowystarczalne 20-30 min sesje

Plan na zadanie >30 min MUSI zawierać sekcję `Podział na sesje` z mapowaniem etapów → sesje 20-30 min. Każda sesja jest **samowystarczalna**: kończy się commit + push + update `next-session.md` (lub multi-plan `next-session-{slot}.md`) z dokładnym kontekstem dla następnej sesji.

**Uzasadnienie:** użytkownik pracuje w realnym świecie z przerwami (klienci, sprawy domowe, limity tokenów Claude). Bez checkpointów długie fazy się rozsypują przy przerwie — kontekst tracony, znaczna część pracy do powtórzenia. Z checkpointami: przerwa = naturalna pauza między sesjami, wznowienie = `git pull` + przeczytanie `next-session.md`. Wprowadzono w  fabryki (2026-05-07) po feedback operatora po  (2.5h ciągłej pracy bez checkpointów — działało, ale ryzyko utraty kontekstu przy przerwie było realne).

**Format minimalny:**
```markdown
### Podział na sesje

| Sesja | Etapy | Czas | Output | Hard-stop? |
|---|---|---|---|---|
| 1 | E1, E2 | ~25 min | ... | — |
| 2 | E3-E5 | ~30 min | ... | TAK (po E5) |
| ... | ... | ... | ... | ... |

**Każda sesja kończy się:** commit + push + update `next-session.md` z kontekstem dla następnej sesji.
```

**Zasady alokacji etapów do sesji:**
- 1 sesja = ~3-5 etapów średniej granularności (1 etap ~5-10 min) lub 1-2 grube pipeliny (np. `/new-skill` z interviewer+builder+quality)
- Hard-stopy z planu MUSZĄ wypadać na granicach sesji (nie w środku)
- Sesja >30 min = podziel na 2 mniejsze
- Sesja <15 min = łącz z sąsiednią (chyba że jest hard-stop)

**Estymacja czasu:** w trybie `/loop` auto z background agentami (skill-builder, agent-architect, requirements-interviewer w tle paralelnie) realny czas to **3-4× mniej** niż "Estimated time" w klasycznej formule. Dla 17 etapów × ~12 min/etap ≈ ~3.5h. Dziel na ~7-11 sesji 20-30 min.

**Wyjątki:** zadania <30 min total nie wymagają sekcji "Podział na sesje" — robi się w 1 sesji bez checkpoint.

**Retroaktywność:** istniejące plany sprzed 2026-05-07 (master + 4 podplany  z 2026-05-06) NIE wymagają retro patcha. Enforcement od kolejnego uruchomienia factory-planner / crm-task-planner.

## Przykłady (3 pary "dobrze vs źle")

### Para 1: Workflow (długość)

- **Źle — crm-task-planner iter 1 (FAIL):** workflow rozpisany jako 10 numerowanych kroków linearnie. Każde osobne zadanie dostało swój numer (zakres, pytania, rozbicie, newralgiczność, dokumentacja, testy, self-check, zapis, raport — rozsypane). Checklist `agent-design-patterns` wymaga 3–6 kroków → quality-checker FAIL blokujący.
- **Dobrze — crm-task-planner iter 2 (PASS) i factory-planner iter 1 (PASS):** workflow w 6 głównych blokach z podnumeracją 2a/2b/2c, 3a/3b/3c, 4a/4b, 6a/6b. Cała treść merytoryczna zachowana. Factory-planner dostarczył to od razu w iteracji 1, bo lesson #1 crm-task-planner była wczytana do briefu.

**Wniosek:** wymóg 3–6 kroków twardy. Projektuj najpierw szkielet 6 bloków, potem podkroki.

### Para 2: Egzekutor zadania

- **Źle — crm-task-planner iter 1 i 2:** plan miał kolumnę "Model CC" (opus/sonnet/haiku) ale bez kolumny Executor. Tag był informacją bez mechanizmu realizacji — realnie wykonywał ten model, który operator miał aktualnie w terminalu. Plan "teoretyczny".
- **Dobrze — crm-task-planner iter 3 (feature expansion) i factory-planner iter 1:** każde zadanie ma jawnego Executora. CRM: 3 wartości (agent / main / NEW:). Factory: 4 wartości (czwarta `/slash-command` specyficzna dla meta-operacji fabryki). Breakdown w raporcie: ile etapów przez agentów, ile przez main, ile przez slash-commands, ile przez NEW:.

**Wniosek:** tag bez egzekutora to tylko napis. Każda rekomendacja routingu modelu MUSI mieć jawny łącznik do runtime. Liczba wartości Executor zależy od gęstości meta-operacji w domenie.

### Para 3: Typy scope

- **Źle — crm-task-planner iter 1-2:** brak koncepcji typu scope. Refaktor brand switchera (cross-cutting dotykający 4 modułów) obsłużony ad-hoc — agent sam rozpoznał z kontekstu, ale bez deterministycznego drzewa decyzji. Lesson #3 (2026-04-23): "bez typu scope refaktory cross-cutting będą się gubić w przyszłych planerach".
- **Dobrze — factory-planner iter 1:** 3 typy scope od iteracji 1, drzewo decyzji zapisane w kroku 2a spec, każdy typ ma dedykowany zestaw 4–5 pytań mini-wywiadu (enhancement: deficyt + backward compat; cross-cutting: lista elementów + kolejność; new-element: rola + MVP). Frontmatter planu zawiera `scope: new-element | cross-cutting | enhancement` jako obowiązkowe pole.

**Wniosek:** każda iteracja projektowa w fabryce produkuje lesson — każda lesson trafia do briefu następnego agenta tej samej klasy. Dzięki temu factory-planner dostał 3 typy scope "za darmo", bez iteracji naprawczej.

## Antywzorce

1. **Workflow >6 kroków (linearnie).** Spec niespójna ze skillem `agent-design-patterns`. Najczęstszy powód: pisanie workflow "co po czym zrobi agent" zamiast "z jakich 6 bloków składa się jego praca". Rozwiązanie: szkielet 6 bloków FIRST, podkroki potem.
2. **Plan bez kolumny Executor.** Tag Model CC to tylko napis bez wykonawcy. Plan "teoretyczny" — rekomendacja routingu bez gwarancji realizacji.
3. **Spec planera zakładający tylko zamkniętą listę zakresów, bez obsługi cross-cutting.** Działa na prostych tematach, wybucha przy refaktorze dotykającym wielu elementów naraz. Rozwiązanie: 3 typy scope od iter 1.
4. **Frontmatter agenta projektowego z metadanymi library (`tags`, `version`, `compatible_with`, `token_cost`).** Niepotrzebny balast — te pola mają wartość tylko dla agentów w `library/` (dystrybuowanych między projekty). Dla agenta projektowego w `.claude/agents/` zostaw: `name`, `description`, `tools`, `model`, `requires`.
5. **Zadania bez przypisanej dokumentacji.** Self-check pkt "dokumentacja per etap" fail. Bez tego plan nie zapewnia, że onboarding nowego developera do modułu/obszaru zajmuje godziny a nie tygodnie.
6. **Zgadywanie niejasności zamiast dopytywania.** Plan z pytaniami otwartymi w sekcji "Ryzyka" = niekompletny. Wykonawca napotka niejasność → wraca do użytkownika → pętla rozbija egzekucję.
7. **Zapisywanie pliku mimo FAIL self-check.** Plan-śmieci trafia do `plans/` i rozprasza następną sesję. Self-check ma być fizyczny (agent sprawdza i blokuje Write), nie deklaratywny ("pamiętaj żeby sprawdzić").
8. **Plan >10 etapów bez risk-matrix.** Wzorzec #9. Najczęstszy objaw: plan ma listę etapów + Estimated time, brak myślenia "co może pójść nie tak". W trybie auto agent napotyka problem → zatrzymuje się → user musi reagować. Risk-matrix rozwiązuje to ex-ante.
9. **Risk-matrix z `Contingency: TBD` dla ryzyka HIGH×*.** Wzorzec #10. Pusta kolumna contingency nie jest neutralna — to deklaracja "nie wiemy co zrobić jeśli się ziści". Plan z taką kolumną nie nadaje się do trybu auto. Wymóg: konkretna akcja lub eskalacja "STOP and ask user" jako jawny contingency.
10. **Plan >30 min bez sekcji "Podział na sesje".** Wzorzec #11. Najczęstszy objaw: plan ma 12-20 etapów + Estimated time, ale brak mapowania etapów na sesje 20-30 min. Przy przerwie (koniec tokenów / wyjście użytkownika) — utrata kontekstu, kosztowne wznowienie. Rozwiązanie: zawsze sekcja "Podział na sesje" z hard-stopami na granicach.
11. **Plan dotykający paczki af-pack-* bez embedded-factory awareness.** Wzorzec #12. Najczęstszy objaw: plan tworzący nową paczkę LUB modyfikujący istniejącą NIE uwzględnia `library/embedded-factory/` (mini-fabryki samouczenia się,  2026-05-24). Pack-agent v2.0+ Krok 7.5 BLOKUJE push bez embedded — plan ignorujący to wymusza re-iterację. Rozwiązanie: planer dla paczek MUSI mieć minimum 3 etapy embedded-aware (pre-flight `build.sh --check`, copy z collision detection, parity check) ORAZ retrofit-aware dla istniejących paczek (`/upgrade-factory` dry-run+backup+apply).

### 12. Embedded-factory awareness w planach af-pack-*

**Trigger:** plan dotyka tworzenia, modyfikacji LUB retrofitu paczki `af-pack-*`. Od  (2026-05-24) embedded-factory jest **standardem** dla każdej paczki (zasada #14 CLAUDE.md fabryki).

**Wymagane elementy planu:**

| Sytuacja | Wymagane etapy w planie |
|---|---|
| **Tworzenie nowej paczki** | 1) build.sh --check (pre-flight, Krok 7.5a) 2) pack-agent v2.0+ dispatch (Krok 7.5b-f auto) 3) parity check PASS (BLOKER przed push) |
| **Retrofit istniejącej paczki v1.x → v2.0** | 1) `/upgrade-factory --dry-run` (audit changes) 2) `--backup` (safety) 3) `--apply` (deploy embedded) 4) `--validate` (smoke tests hook exit 0) |
| **Patche embedded artefaktów (agenty/skille embedded)** | 1) Edit source (`library/skills/...` lub `.claude/agents/...`) 2) `bash library/embedded-factory/build.sh` (rebuild) 3) Re-pack lub `/upgrade-factory` w istniejących paczkach |
| **Lessons federacja (cross-paczkowo)** | 1) Lokalny capture w paczce (`/promote-lessons` push branch learning/) 2) Fabryka `/pull-promoted-lessons` (HITL gate przez improvement-proposals) 3) Manual merge do `lessons.jsonl` z `origin: af-pack-<nazwa>` |

**Schema v2 awareness (lessons.jsonl od .E13):**

Plan dotyczący lessons (analytics, federation, migration) MUSI uwzględniać nowe pola opcjonalne:
- `origin` — gdzie POCHODZI lesson (factory vs af-pack-*) ≠ `project` (gdzie APPLIES)
- `confidence_hits` — cross-projektowa observation count (≥3 = trigger federacji)
- `promoted_at` + `promoted_to` — federation metadata
- `hitl_approved` — null/true/false state machine

**Anti-patterns dodatkowe (poza #11 ogólnym):**

- Plan tworzący paczkę bez Krok "verify embedded build" = paczka push blocked przez pack-agent v2.0
- Plan retrofitu istniejącej paczki bez `--backup` step = brak rollback path jeśli upgrade psuje custom code
- Plan federacji lessons bez HITL gate (auto-merge) = lesson spam + operator loses trust (analogicznie do `/review-candidate-lessons` w 10A)

**Przykład PLAN OK:**

```markdown
##  — nowa paczka af-pack-Y
1. Build verification: `bash library/embedded-factory/build.sh --check`
2. Pack dispatch: `/pack af-pack-Y "opis"` (auto-include embedded via Krok 7.5)
3. Parity check (pack-agent built-in BLOKER)
4. Real-test gate (zasada #12 fabryki)
5. `gh repo create` + push
6. Update CLAUDE.md zasada #14 sekcja paczek o nową
```

**Przykład PLAN NOK (anty-#12):**

```markdown
##  — nowa paczka af-pack-Y
1. Skopiuj agentów z library do packages/<nazwa>/.claude/agents/
2. Skopiuj skille
3. gh repo create LogicMorrow/af-pack-Y
4. git push
```

Brak: embedded-factory, build verification, parity check. Pack-agent v2.0 BLOKUJE w Krok 7.5a.

**Konsumenci wzorca #12:**

- `factory-planner` (przy plannowaniu rozbudowy fabryki dotyczącej paczek)
- Hipotetyczny `package-planner` (przy szczegółowych planach refaktorów paczek)
- `agent-architect` przy projektowaniu nowych agentów które mają być embedded-aware

## Powiązania

1. **`.claude/skills/agent-design-patterns/SKILL.md`** — BAZA ogólna dla wszystkich agentów. `planner-design-patterns` jest **specjalizacją**, nie zastępstwem. Zawsze wczytuj razem: baza daje fundamenty (frontmatter, dobór modelu, reguła pytaj-nie-zgaduj), ten skill dokłada specyfikę planisty (Executor, typy scope, samoreferencyjność).
2. **`.claude/skills/skill-design-patterns/SKILL.md`** — konwencje pisania samego `planner-design-patterns`. Używane przez `quality-checker` przy walidacji tego skilla.
3. **`.claude/skills/model-routing/SKILL.md`** — routing opus/sonnet/haiku w kolumnie Model CC planu. Planer MUSI mieć `requires: [model-routing]` we frontmatter, bo pre-flight check to weryfikuje.
4. **`.claude/agents/requirements-interviewer.md`** — wzorzec agenta interaktywnego (wariant c). Planer naśladuje jego tryb prowadzenia dialogu w głównej konwersacji.
5. **`.claude/agents/agent-architect.md`** — konsument skilla. Wczytuje `planner-design-patterns` w kroku 2 swojego workflow, gdy brief wskazuje rolę planisty.
6. **Implementacje (live reference):**
   - `~/external-crm/.claude/agents/crm-task-planner.md` (iter 3, PASS) — planer projektu aplikacyjnego, Executor 3-wartościowy, 13 punktów self-check.
   - `~/agent-factory/.claude/agents/factory-planner.md` (iter 1, PASS) — planer meta-projektu, Executor 4-wartościowy, 14 punktów self-check (14-ty = 9 zasad CLAUDE.md fabryki).

**Powiązane lessons:** `~/agent-factory/knowledge-base/lessons.jsonl` (3 wpisy z 2026-04-23: workflow 6 kroków, kolumna Executor, 3 typy scope).
