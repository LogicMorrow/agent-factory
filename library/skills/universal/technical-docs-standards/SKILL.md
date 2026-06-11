---
name: technical-docs-standards
version: "1.0"
type: skill
category: universal
description: "Gdy użytkownik pracuje nad dokumentacją techniczną (ADR, runbooki, architecture, API docs) w projekcie lub konfiguruje enforcement docs w CI. Aktywuj przy frazach: dokumentacja, ADR, runbook, architecture, diagram, C4, mermaid, docs standards, technical writing"
compatible_with: ["webapp", "cli", "automation", "ai-agents", "other"]
requires: []
tags: ["documentation", "adr", "runbooks", "architecture", "mermaid", "c4", "api-docs", "technical-writing"]
token_cost: medium
files:
  - SKILL.md
  - templates/adr-template.md
  - templates/runbook-template.md
  - templates/docs-readme-template.md
  - templates/onboarding-template.md
  - templates/architecture-overview-template.md
  - templates/api-docs-readme-template.md
  - templates/project-readme-template.md
  - references/mermaid-examples.md
  - references/c4-model-primer.md
  - references/adr-runbook-pairing.md
  - references/ci-integration.md
  - assets/scripts/validate-docs.sh
  - variables.yaml
---

# technical-docs-standards

Standard dokumentacji technicznej dla projektów operatora. Warstwowy (L1/L2/L3) — dopasujesz intensywność do dojrzałości projektu, nie narzucasz L3 na MVP.

## 1. Kiedy używać / Kiedy NIE używać

**Używaj gdy:**
- zakładasz nowy projekt i chcesz postawić `docs/` od razu dobrze
- dodajesz ADR do istniejącego projektu
- piszesz runbook dla operacji produkcyjnej
- tworzysz diagramy architektoniczne (Mermaid, C4)
- konfigurujesz enforcement docs w CI
- pytasz "ile dokumentacji potrzeba dla projektu na tym etapie?"

**NIE używaj gdy:**
- projekt jest jednorazowym skryptem / POC bez zespołu (wystarczy README)
- dokumentujesz zewnętrzne API (to nie ADR, to notatki)
- piszesz dokumentację użytkownika / UX copywriting — inny skill/agent

**Specyfika per typ projektu:**
| Typ | API docs | Architecture | Runbooks |
|-----|----------|-------------|----------|
| webapp | obowiązkowe L2+ | obowiązkowe | deploy/rollback minimum |
| cli | opcjonalne (--help) | opcjonalne | instalacja/konfiguracja |
| automation | N/A | flow diagram | incident response |
| ai-agents | tRPC internal lub REST | agent graph | LLM fallback/escalation |

---

## 2. Warstwy dojrzałości L1 / L2 / L3

Ustaw `docs_maturity_level` w karcie projektu (`knowledge-base/projects/<slug>.md`). Brak pola → default L1 + warning.

| Element | L1 MVP | L2 production | L3 scale (>3 devs) |
|---------|--------|---------------|--------------------|
| `docs/README.md` (mapa) | obowiązkowy | obowiązkowy | obowiązkowy |
| `docs/adr/` | obowiązkowy | obowiązkowy | obowiązkowy |
| `docs/runbooks/deploy.md` | obowiązkowy | obowiązkowy | obowiązkowy |
| `docs/runbooks/rollback.md` | opcjonalny | **obowiązkowy** | obowiązkowy |
| `docs/runbooks/incident-response.md` | opcjonalny | **obowiązkowy** | obowiązkowy |
| `docs/architecture/overview.md` | opcjonalny | **obowiązkowy** | obowiązkowy |
| `docs/onboarding.md` | opcjonalny | **obowiązkowy** | obowiązkowy |
| `docs/api/README.md` | opcjonalny | **obowiązkowy** | obowiązkowy |
| `docs/api/` (auto-gen) | nie | obowiązkowy | obowiązkowy |
| `docs/security/` | nie | opcjonalny | **obowiązkowy** |
| `docs/postmortems/` | nie | nie | **obowiązkowy** |
| `docs/glossary.md` | nie | nie | **obowiązkowy** |
| Deployment diagram | nie | nie | **obowiązkowy** |
| Component diagram | nie | nie | opcjonalny |

Templates: `templates/docs-readme-template.md`, `templates/onboarding-template.md`.

---

## 3. ADR — Architecture Decision Records

**Lokalizacja:** `docs/adr/0001-<kebab-case>.md` (4-cyfrowa numeracja globalna, MADR format).
Fabryka używa `knowledge-base/docs/adr/` — osobny kontekst, nie dla projektów klienckich.

### Test 3-czynnikowy (≥2/3 = pisz ADR)

1. **Nieodwracalność** — cofnięcie kosztuje >1 sprint lub wymaga migracji danych
2. **Szeroki wpływ** — dotyka >1 modułu LUB >1 dewelopera
3. **Kontrowersja** — były rozważane ≥2 alternatywy

Jeśli <2/3 → to nie ADR, to commit message lub komentarz w kodzie.

**7 obowiązkowych kategorii** (ADR niezależnie od testu 3-czynnikowego):
`storage choice` / `auth/authz mechanism` / `deploy target` / `security model` / `breaking API change` / `LLM routing decision` / `core dependency swap (>10% bundle lub krytyczna)`

### Szablon ADR → `templates/adr-template.md`

Kluczowe sekcje (MADR + rozszerzenia):
- **Status** (proposed → accepted → deprecated → superseded-by-ADR-NNNN)
- **Context** — dlaczego decyzja jest potrzebna, jakie ograniczenia
- **Alternatives considered** — ≥2 opcje z pro/con
- **Decision** — co wybrano i dlaczego
- **Success criteria** (OBOWIĄZKOWA) — jak poznamy że decyzja była dobra
- **Rollback plan** (opcjonalna) — jak cofnąć jeśli Success criteria nie osiągnięte

Front-matter wymagany: `status`, `date`, `decision_by`, `kind` (infrastructure|code|process|security), `related`, `last_reviewed`.

### Supersede chain i retroaktywne

- **Supersede:** stary ADR NIGDY nie jest usuwany — zmień `status: superseded-by-ADR-NNNN`. Nowy ADR referencjuje stary w Kontekście.
- **Retroaktywny:** `date: <dzisiaj>` + adnotacja w Kontekście: `"ADR retroaktywny, decyzja faktycznie podjęta YYYY-MM-DD"`.

### ADR zbiorczy vs ADR izolowany (lesson #7 z 2026-04-27)

**Reguła:** Design v1.0 nowego agenta = **1 zbiorczy ADR z N sekcjami "Decyzja N"** (decyzje wzajemnie powiązane: scope→workflow→kontrakt I/O = jedna spójna historia).

**Decyzje izolowane** (1 sprawa, niezależna od innych) = **1 osobny ADR per sprawa**.

#### Test 3-czynnikowy "zbiorczy czy izolowane"

ADR zbiorczy jeśli **wszystkie 3 spełnione**:
1. Decyzje dotyczą **jednego artefaktu** (np. design v1.0 agenta X) — nie kilku niezależnych obiektów.
2. Decyzje są **wzajemnie powiązane** — zmiana jednej wymusza review pozostałych (scope→workflow→kontrakt to klasyczna trójka).
3. Decyzje mają **wspólny Context** — opisując pojedynczo musiałbyś duplikować ≥50% sekcji Context.

Jeśli ≥1 czynnik FAIL → osobne ADR-y per decyzja.

**Wyjątek:** architekt może zdecydować odwrotnie z jawnym uzasadnieniem w sekcji "Alternatives considered" ADR-a. Test 3-czyn jest pomocniczy, nie hard rule.

#### Precedensy w fabryce (ADR-0001..0005)

| ADR | Typ | Decyzji | Uzasadnienie |
|---|---|---|---|
| ADR-0001 (pnpm jako standard webapp) | izolowany | 1 | Pojedyncza decyzja standardu fabryki, brak powiązań z innymi decyzjami. |
| ADR-0002 (universal docs skill — vs per-stack) | izolowany | 1 | Pojedyncza decyzja struktury skilla, brak powiązań. |
| ADR-0003 (code-implementer design v1.0) | **zbiorczy** | 4 | Hybryda architekt+impl, extend-don't-edit, samo-review, ADR warunkowo — wszystkie 4 decyzje powiązane przez scope agenta. |
| ADR-0004 (debugger 4-step + impact) | izolowany | 1 (core) | Pojedyncza decyzja workflow, mimo że dotyczy nowego agenta — pozostałe pomniejsze decyzje delegowane do reflexji architekta. |
| ADR-0005 (tech-doc-writer design v1.0) | **zbiorczy** | 3 | Scope B / HITL gate / kontrakt I/O — wszystkie 3 decyzje powiązane przez scope agenta. |

**Anti-pattern:** rozbicie design v1.0 agenta na 3-4 osobne ADR-y tworzy fałszywą atomowość — każdy ADR musiałby duplikować Context, scope chain wymagałby cross-references między ADR-ami, supersede chain skomplikowany. Zbiorczy ADR z N sekcjami "Decyzja N" jest czytelniejszy.

---

## 4. Runbooks

### Trigger: ≥2/4 kryteriów LUB hard rule

**Kryteria (≥2 = pisz runbook):**
1. ≥3 kroków manualnych wymaganych
2. Wykonywane rzadziej niż raz na miesiąc
3. Prod impact (dostępność lub dane)
4. Decyzje warunkowe po drodze (nie czysto deterministyczne)

**Hard rules (zawsze runbook niezależnie od testu):**
`deploy` / `rollback` / `disaster recovery` / `rotacja sekretów` / `onboarding nowego dewelopera` / `incident response`

### Szablon → `templates/runbook-template.md`

9 sekcji: Kiedy użyć / Wymagania wstępne / Procedura / Weryfikacja sukcesu / Rollback / Troubleshooting / Eskalacja (opcjonalna) / Linki / Historia zmian

Front-matter: `severity` (p0|p1|p2|p3), `mttr_target` (minuty), `related_adrs`, `owner`, `last_updated`.

### Granularność hybrydowa

- Jeden plik per procedura: `docs/runbooks/<procedura>.md`
- Wspólne prerekvizyt: `docs/runbooks/_shared-prerequisites.md` (SSH, VPN, narzędzia CLI)
- Indeks: `docs/runbooks/README.md` — tabela: procedura / severity / MTTR target / ostatnie użycie

---

## 5. Architecture — diagramy i overview

### Polityka diagrams-as-code

| Narzędzie | Status | Warunki |
|-----------|--------|---------|
| **Mermaid** | OBOWIĄZKOWY | domyślny, renderowany natywnie na GitHub |
| PlantUML | dopuszczalny | tylko ze źródłem `.puml` + wyrenderowanym `.svg` w repo |
| Draw.io / Lucidchart | **ZAKAZANY** | chyba że `.drawio` źródło jest w repo obok eksportu |

### Diagramy per poziom dojrzałości

| Diagram | L1 | L2 | L3 |
|---------|----|----|----|
| System context (C4 L1) | obowiązkowy | obowiązkowy | obowiązkowy |
| Container diagram (C4 L2) | opcjonalny | **obowiązkowy** | obowiązkowy |
| Sequence diagram (≥1 krytyczny flow) | nie | **obowiązkowy** | obowiązkowy |
| ERD (schema.sql / DBML / Prisma) | nie | **obowiązkowy** | obowiązkowy |
| Deployment topology | nie | nie | **obowiązkowy** |
| Component diagram (C4 L3) | nie | nie | opcjonalny |

Snippety gotowe do użycia: `references/mermaid-examples.md`
Intro do C4 dla nieznających: `references/c4-model-primer.md`

### `docs/architecture/overview.md` — 8 sekcji

1. System context (C4 diagram)
2. Container view (C4 diagram)
3. Tech stack (tabela: warstwa / technologia / uzasadnienie)
4. Key flows (≥1 sequence diagram krytycznego flow)
5. Data model (ERD)
6. Deployment (**L3 only** — topology diagram)
7. ADR index (linki do accepted ADR-ów)
8. Trade-offs & known limitations (świadome kompromisy)

Template: `templates/architecture-overview-template.md`

---

## 6. API docs — hybryda

**Auto-gen z kodu** (techniczna część) + **ręczny kontekst biznesowy** (`docs/api/README.md`).

| Wariant | Auto-gen UI | `docs/api/README.md` | Kiedy |
|---------|-------------|----------------------|-------|
| tRPC internal (monorepo) | nie | minimalny (flow + auth + errors) | web+backend razem |
| tRPC public / REST / gRPC | obowiązkowy (`/api/docs`) | pełny | publiczne API lub >1 konsument |

**Obowiązkowość:** od L2. Na L1 opcjonalne.

**`docs/api/README.md` minimum 7+2 sekcji:**
1. Base URL + versioning
2. Auth (jak uzyskać token, format nagłówka)
3. Rate limiting (limity, nagłówki)
4. Error format (tabela kodów błędów)
5. Link do live UI (Swagger/trpc-panel)
6. Changelog (breaking changes)
7. E2E examples (2-3: login → call → response)
8. Webhooks (OBOWIĄZKOWE gdy aplikacja emituje)
9. SDK examples (opcjonalne, minimum curl)

Template: `templates/api-docs-readme-template.md`

---

## 7. Cross-linking ADR ↔ runbook ↔ architecture

**YAML front-matter `related`** w każdym dokumencie — lista ścieżek względnych:
```yaml
related: ["../adr/0003-redis-pubsub.md", "../runbooks/redis-down.md"]
```

**Reguła infrastruktury:** ADR z `kind: infrastructure` MUSI mieć ≥1 runbook `<komponent>-down.md` lub `<komponent>-degraded.md` w `related`.

Szczegóły + 3 przykłady powiązań: `references/adr-runbook-pairing.md`
Skrypt walidujący linki: `assets/scripts/validate-docs.sh`

---

## 8. Enforcement w CI

Pełny snippet YAML + standalone workflow + retrofit: `references/ci-integration.md`
Skrypt: `assets/scripts/validate-docs.sh` (bash + yq, exit 0/1/2)

### Hard gates (blokują merge)

1. ADR front-matter `status` wymagany i w enum
2. Runbook front-matter `severity` wymagany i w enum (p0|p1|p2|p3)
3. Broken internal links w `docs/` (`[text](path)` nie istnieje)
4. Schema/migration change bez `docs/architecture/` touched LUB `ERD-updated: yes|n/a` w PR body

### Soft gates (warning, nie blokują)

1. ADR `status: accepted` i `last_reviewed` > 12 miesięcy
2. Orphan ADR `kind: infrastructure` bez runbooka w `related`
3. `docs/README.md` niezmieniony > 90 dni
4. Nowe endpointy w diff bez `docs/api/` touched (L2+)

### Bypass

Label `emergency-merge` na PR + linia `TECH-DEBT: <opis>` w PR body + wpis w `docs/TECH_DEBT.md` (data / PR / plan spłaty / owner). Comiesięczny sweep przez `/review-lessons`.

---

## 9. Integracja z webapp-cicd-templates

Skill **nie modyfikuje** `ci.yml.template` z `webapp-cicd-templates`. Zamiast tego:
- `references/ci-integration.md` zawiera snippet YAML job `docs-lint` gotowy do wklejenia
- Standalone workflow dla projektów bez `webapp-cicd-templates`
- Instrukcja retrofit dla istniejących repo

Runtime: bash + `mikefarah/yq-action@v4`. Zero Node deps — działa w projektach non-Node (CLI, automation, ai-agents). Alternatywa Node (`validate-docs.js` + `yaml` parser) udokumentowana opcjonalnie w `references/ci-integration.md` (R5).

---

## 10. Centralny rejestr ADR-ów fabryki

Wszystkie ADR-y fabryki żyją w `knowledge-base/docs/adr/` z 4-cyfrową globalną numeracją (`0001-`, `0002-`, ...). Skille NIE hostują własnych ADR-ów — jeśli decyzja wymaga ADR-a (test 3-czynnikowy: kontrowersja + revisit_cost + ≥2 kategorie), trafia do centralnego rejestru i jest linkowana z SKILL.md skilla w sekcji "Powiązania".

Stan na 2026-04-23:
- [`ADR-0001: pnpm jako standard package managera fabryki`](../../../../knowledge-base/docs/adr/0001-pnpm-package-manager.md) — konsument: `webapp-cicd-templates`
- [`ADR-0002: Universal skill zamiast 4 osobnych dla docs standards`](../../../../knowledge-base/docs/adr/0002-universal-docs-skill.md) — ten skill

Przy dodawaniu kolejnego ADR-a: kolejny numer (`0003-`), front-matter MADR wg `templates/adr-template.md`, wpis do `related:` innych ADR-ów jeśli relacja istnieje.

---

## 11. Antywzorce

1. **Draw.io / Lucidchart bez źródła w repo** — diagram staje się black box, nikt nie może go edytować. Po 6 miesiącach nikt nie pamięta hasła do Lucidchart. Zasada: `*.drawio` lub `.puml` musi być w repo obok eksportu.

2. **ADR-inflation** — pisanie ADR o "użyjemy axios zamiast fetch" lub "nazwa zmiennej". Test 3-czynnikowy jest filtrem — <2/3 = commit message, nie ADR. Puchnienie `docs/adr/` deprecjonuje wartość wszystkich ADR-ów.

3. **Runbooki free-form** — runbook jako luźne notatki bez struktury ("krok 1: zaloguj się, krok 2: sprawdź logi... hmm"). Bez sekcji Weryfikacja sukcesu i Rollback runbook jest bezużyteczny w stresie. Template z 9 sekcjami jest wymagany.

4. **Dokumentacja na pokaz** — puste foldery `docs/adr/.gitkeep`, `docs/architecture/` bez pliku, `docs/README.md` z samym nagłówkiem. CI hard gate (obecność `docs/README.md` z contentem > 50 znaków) mitiguje.

5. **Brak `docs/README.md` jako mapy** — dokumentacja bez indeksu = archeologia. Dev nie wie co istnieje. `docs/README.md` jest hard gate w CI — musi być i musi wskazywać wszystkie dokumenty w katalogu.

6. **Retroaktywny ADR z fałszywą datą** — wpisywanie daty oryginalnej decyzji zamiast dzisiejszej zmniejsza czytelność historii. Zasada: `date: <dzisiaj>` + adnotacja w Kontekście z faktyczną datą decyzji.

7. **Bypass `emergency-merge` jako standard** — jeśli bypass pojawia się >3x/miesiąc dla tego samego dewelopera, to nie są emergency. Meta-reviewer raportuje pattern przy `/review-lessons`. Bypass ma być wyjątkiem z planowaną spłatą.

8. **ADR bez Success criteria** — "zdecydowaliśmy użyć Redis jako pub/sub" bez kryterium sukcesu = brak podstawy do ewaluacji po 6 miesiącach. Sekcja Success criteria jest OBOWIĄZKOWA w template.

---

## 12. Roadmap v1.1

- [ ] Agent `tech-doc-writer` (plan etap 8/23) — automatyczne szkicowanie ADR i runbook na podstawie diff + karty projektu
- [ ] `docs_maturity_level` w `project-profiler` — pytanie dodane przy tworzeniu/patchu karty (follow-up z briefu, R7)
- [ ] Migracja istniejących ADR-ów do `knowledge-base/docs/adr/` — etap 3b planu
- [ ] CRM pilotaż  — 3 ADR retroaktywne + 2 runbooki + overview.md
- [ ] PlantUML CI render — automatyczne generowanie `.svg` z `.puml` w CI (runner z `plantuml-action`)
- [ ] `docs/TECH_DEBT.md` sweep automation — cron job raportujący przeterminowane wpisy

---

## Powiązania

- **`webapp-cicd-templates`** (`library/skills/webapp/webapp-cicd-templates/`) — CI pipeline, w który wklejamy job `docs-lint`. Patrz `references/ci-integration.md`.
- **`webapp-security-hardening`** (`library/skills/webapp/webapp-security-hardening/`) — ADR `kind: security` dla decyzji hardeningu. Runbooki rotacji sekretów.
- **`skill-design-patterns`** (`.claude/skills/skill-design-patterns/`) — wzorce budowania skilli, konsumowane przez `skill-builder`.
- **`quality-checker`** (`.claude/agents/`) — walidacja tego skilla przed użyciem.
- **`requirements-interviewer`** + **`project-profiler`** — dostarczają `docs_maturity_level` z karty projektu.
