---
name: solution-memory
description: >
  Stosuj gdy projekt używa Stop-hooka i solution-reflectora do autonomicznego zapamiętywania rozwiązanych problemów
  (druga oś learning-loopu, obok conversation-learning). Skill opisuje konwencję plików md per-solution + indeks JSONL,
  protokół recall przy SessionStart oraz zasadę klasyfikacji scope (project-local vs factory-candidate).
  Konsumenci: solution-reflector (producent), stop-solution-record.sh (trigger), session-start-embedded.sh (recall),
  /weekly-factory-intake (federacja do fabryki).
type: skill
version: "1.0.0"
category: universal
tags: [solution-memory, learning, recall, dead-ends, stop-hook, scope-classification, sessions, universal]
distribution: standard
compatible_with: [universal]
requires: [model-routing, cross-agent-learning]
provides: [solution-memory-pipeline, solution-recall]
token_cost: low
---

# solution-memory

## Before starting work (cross-agent-learning krok 0)

Konsument tego skilla (solution-reflector, session-start-embedded.sh, /weekly-factory-intake) MUSI przed użyciem przeczytać:

1. **`.claude/knowledge-base/solutions-index.jsonl` tail 5** — ostatnie rozwiązania; sprawdź `scope` i `promoted_to_factory`.
2. **`.claude/knowledge-base/solutions/<najnowszy-id>.md`** (opcjonalnie, 1 plik) — jeśli bieżący problem pasuje do tytułu/tagów ostatniego rozwiązania, przeczytaj pełną narrację.
3. **`.claude/knowledge-base/lessons.jsonl` tail 10** — czy ostatnie lessons zawierają wzorce powiązane z bieżącym problemem.

Budget: ~3k tokenów łącznie. Apply silently — nie wypisuj że czytałeś. Wzmianka w outpucie TYLKO gdy konkretna decision się zmienia vs default.

---

## Kiedy uruchomić

Wczytaj ten skill, gdy: (a) projektujesz/recenzujesz `solution-reflector`, Stop-hook `stop-solution-record.sh` lub recall w `session-start-embedded.sh`; (b) implementujesz `/weekly-factory-intake` i musisz wiedzieć, jak wygląda `factory-candidate`; (c) pracujesz w projekcie z embedded-factory i widzisz `solutions/` lub `solutions-index.jsonl` i potrzebujesz konwencji.

NIE wczytuj, gdy chodzi o werbalny feedback operatora w czacie (korekty/preferencje) — to `conversation-learning`, druga, niezależna oś.

---

## Cel i granica z conversation-learning

`solution-memory` to **druga oś learning-loopu**:

| Oś | Trigger | Co zapisuje | Gate HITL |
|---|---|---|---|
| **solution-memory** | Stop-hook (`stop-solution-record.sh`) | Co projekt ZROBIŁ — rozwiązany problem, ścieżka, ślepe uliczki | Brak na warstwie projektu; dopiero `/weekly-factory-intake` |
| **conversation-learning** | UserPromptSubmit hook | Co operator POWIEDZIAŁ — werbalny feedback, korekty, preferencje | `/review-candidate-lessons` |

Obie osie są niezależne. solution-reflector NIGDY nie dotyka `candidate-lessons.jsonl`; conversation-learning NIGDY nie dotyka `solutions/`.

## 1. Konwencja: md per-solution + indeks JSONL

### 1.1 Plik md — źródło prawdy (pełna narracja)

Ścieżka: `.claude/knowledge-base/solutions/<id>.md`

`<id>` = `<YYYY-MM-DD>-<kebab-temat>` (pattern: `^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9][a-z0-9-]{2,60}$`)

Przykład: `2026-06-06-edytor-2d-3d-canvas-skala.md`

**Frontmatter YAML** (nadzbiór pól indeksu — wszystkie pola indeksu muszą być obecne):

```yaml
---
id: 2026-06-06-edytor-2d-3d-canvas-skala
ts: 2026-06-06T18:42:11Z
project: demo-app
title: "Edytor dachu 2D/3D — poprawne skalowanie canvas przy zoomie"
problem: "Canvas edytora rozjeżdżał się przy zoomie na ekranach HiDPI — geometria dachu nie zgadzała się ze skalą."
solution_summary: "Użyto devicePixelRatio do skalowania kontekstu canvas zamiast stałego mnożnika — geometria spójna na wszystkich DPI."
scope: factory-candidate
domain: frontend-canvas
tags: [canvas, zoom, skala, devicePixelRatio, hidpi]
dead_ends:
  - "Stały mnożnik 2x — działał tylko na Retina, łamał się na 1x i 1.5x DPI."
  - "Skalowanie przez CSS transform — rozmywało linie i psuło hit-testing."
reusability: high
commits: [a1b2c3d, e4f5a6b]
files_touched: 4
anti_pii_verified: true
md_path: solutions/2026-06-06-edytor-2d-3d-canvas-skala.md
# + confidence_hits (default 1), promoted_to_factory (false), promoted_at/session_id (null)
---
```

**Body md — 5 sekcji (obowiązkowe, kolejność stała):**

```markdown
## Problem
[Z czym walczyliśmy — objaw, kontekst, dlaczego było trudne.]

## Co próbowano (ślepe uliczki)
[Lista nieudanych podejść + DLACZEGO każde nie zadziałało. Najważniejsza sekcja — zapobiega powielaniu błędów.]

## Rozwiązanie
[Ścieżka, która ZADZIAŁAŁA — konkretne kroki/technika.]

## Dlaczego zadziałało
[Mechanizm — dlaczego to podejście było właściwe tam, gdzie inne zawiodły.]

## Kiedy reużyć
[Sygnatura problemu, przy którym warto sięgnąć po to rozwiązanie ponownie.]
```

Pole `dead_ends` (frontmatter) = projekcja sekcji "Co próbowano" na krótkie stringi (dla recall bez otwierania pełnego md). Może być pustą tablicą jeśli problem poszedł od razu.

### 1.2 Lekki indeks `solutions-index.jsonl` — dla recall

Ścieżka: `.claude/knowledge-base/solutions-index.jsonl`

Jedna linia JSON per rozwiązanie — projekcja frontmatter na pola required + recall-istotne. Pełne body sekcji md NIE jest tu kopiowane.

Przykład linii:

```json
{"id":"2026-06-06-edytor-2d-3d-canvas-skala","ts":"2026-06-06T18:42:11Z","project":"demo-app","title":"Edytor dachu 2D/3D — poprawne skalowanie canvas przy zoomie","problem":"Canvas edytora rozjeżdżał się przy zoomie na ekranach HiDPI.","solution_summary":"Użyto devicePixelRatio do skalowania kontekstu canvas zamiast stałego mnożnika.","dead_ends":["Stały mnożnik 2x — tylko Retina.","CSS transform — rozmycie + zły hit-testing."],"scope":"factory-candidate","domain":"frontend-canvas","tags":["canvas","zoom","devicePixelRatio"],"reusability":"high","commits":["a1b2c3d","e4f5a6b"],"files_touched":4,"md_path":"solutions/2026-06-06-edytor-2d-3d-canvas-skala.md","confidence_hits":1,"anti_pii_verified":true,"promoted_to_factory":false,"promoted_at":null,"session_id":null}
```

Schemat waliduje: `solution-memory-schema.json` (pola required: `id, ts, project, title, problem, solution_summary, scope, md_path`).

**Spójność id ↔ md_path:** `id` musi odpowiadać nazwie pliku md (bez `.md`), a `md_path` = `solutions/<id>.md`. Reflector zapisuje oba atomowo — niespójność jest błędem producenta.

---

## 2. Recall protocol (SessionStart)

Hook `session-start-embedded.sh` przy starcie każdej sesji:

1. Czyta `solutions-index.jsonl` — **tail N=5** (domyślnie ostatnie 5 rozwiązań; preferencja recency).
2. Wyświetla per rozwiązanie: `title` + `problem` (truncated ~100 znaków) + `scope`.
3. Sygnalizuje, że pełna narracja z dead_ends jest w `solutions/<id>.md` — nie kopiuje body do kontekstu.
4. **Budżet bloku solutions-recall:** do ~1200 znaków (z łącznego twardego cap 3000 znaków hooka `session-start-embedded.sh` — reszta na lessons / candidate-lessons / error-memory recall). Tail N=5 × ~200 znaków/wpis mieści się w tym sub-budżecie.
5. **Apply-silently** — main Claude wczytuje recall do kontekstu i stosuje w decyzjach, NIE wypisuje komentarza "wczytałem rozwiązania". Wzmianka TYLKO gdy recall faktycznie zmienia decyzję — 1 zdanie z referencją do `id`.

**Celowany filtr (v2):** w v1 recall = tail N po recency; docelowo filtr po `domain`/`tags` dla trafionego recall. **Dedup inkrement:** MD5-match (exact `problem`+`solution_summary`) → reflector inkrementuje `confidence_hits` istniejącego wpisu zamiast nowego md; `confidence_hits >= 2` = wyższa waga przy weekly intake.

---

## 3. Klasyfikacja scope (reguła ADR-001 — przepisana 1:1)

`solution-reflector` nadaje `scope` przy zapisie. Zasada zachowawcza (lekcja #118: ~90% rozwiązań z pilota to app-specific):

### `factory-candidate` — TYLKO gdy rozwiązanie spełnia WSZYSTKIE 4:

1. **Generalizowalne** — wzorzec/technika niezależna od domeny biznesowej tego konkretnego projektu.
   - Tak: "skalowanie canvas przez devicePixelRatio" — technika frontendowa, działa w każdym projekcie z canvas.
   - Nie: "stawka VAT dla drewna dekarskiego" — domena biznesowa, specyficzna dla jednego projektu.
2. **Reużywalne** — prawdopodobnie wystąpi w innym projekcie/paczce (`reusability: high` lub `med`).
3. **Niesie wartość ślepych uliczek LUB rozwiązanie jest nieoczywiste** — `dead_ends` zawiera podejścia warte ostrzeżenia, lub ścieżka rozwiązania jest nieoczywista.
4. **Bez PII/sekretów** — `anti_pii_verified: true`.

### `project-local` (DEFAULT) — w każdym innym przypadku:

Rozwiązanie specyficzne dla domeny/stacku/danych projektu, oczywiste, lub niskiej reużywalności. Zostaje lokalnie — recall tylko w tym projekcie, NIE idzie do `/weekly-factory-intake`.

**Zasada zachowawcza: w razie wątpliwości → `project-local`.** Trzy warstwy przed fabryką już odsiewają: Stop-hook (ilościowy próg) + reflector (jakościowy szum) + scope (app-specific). Czwarta warstwa to bramka HITL `/weekly-factory-intake`.

---

## 4. Integracja z solution-reflector

`solution-reflector` jest jedynym producentem plików `solutions/<id>.md` i linii `solutions-index.jsonl`. Ten skill opisuje kontrakt — reflector go implementuje.

### Co reflector zapisuje

- Plik md z frontmatterem (nadzbiór schematu) + 5 sekcji body.
- Linię indeksu (projekcja frontmatter, walidowana schematem).
- Wpis do `activity-log.jsonl` (Bash append, `actor: solution-reflector`, `action: solution_recorded`).

### Prawo do ciszy (B1)

Reflector może NICZEGO nie zapisać — gdy ocenia jakościowo, że sesja była mechaniczna/trywialna (literówka, bump wersji, formatowanie/lint, czysty rename). Cisza jest poprawnym wynikiem. NIE każda sesja przekraczająca próg ilościowy hooka zasługuje na zapis.

### Dedup MD5 (B3)

Reflector liczy MD5 ze znormalizowanego `problem + solution_summary` (lowercase, trim, collapse whitespace). Jeśli exact match istnieje w indeksie → inkrementuje `confidence_hits`, NIE tworzy nowego md. Fuzzy/similarity dedup = dług v2.

### Anti-PII (B4 — hard gate)

Reflector skanuje CAŁE planowane wyjście (frontmatter + body + linia indeksu) zestawem regex (klucze API, `KEY=/SECRET=/TOKEN=`, emaile, IBAN PL, tokeny w URL, bloki kluczy prywatnych) PRZED jakimkolwiek zapisem. Trafienie → maskowanie `***REDACTED***`; `anti_pii_verified: true` ustawiany TYLKO po skanie. Warstwa hookowa działa bez HITL → to jedyna bariera przed wyciekiem sekretów do pamięci projektu.

Pełny zestaw regex, tryb degraded bez transkryptu i podział sesji na N rozwiązań: `library/agents/universal/solution-reflector.md`.

---

## 5. Flow: od triggera do fabryki

```
Stop-hook (próg ≥1 commit / ≥3 edycje)
  │
  ▼
solution-reflector (ocena jakościowa + scope + anti-PII)
  │
  ├── [szum / mechaniczne] → CISZA (nic nie zapisuje)
  │
  └── [niesie wartość]
        │
        ▼
        solutions/<id>.md  +  solutions-index.jsonl
                │
                ▼
        SessionStart recall (tail N=5, sub-budżet ~1200 znaków, apply-silently)
                │
                ├── scope: project-local → zostaje lokalnie (recall w tym projekcie)
                │
                └── scope: factory-candidate
                      │
                      ▼
                      /weekly-factory-intake (HITL, pon 10:00)
                        │
                        ▼
                        candidate-lessons fabryki → lessons.jsonl
```

---

## 6. Przykłady (dobrze vs źle)

### Przykład 1 — scope classification

**Dobrze — `factory-candidate`:**
```yaml
title: "Edytor dachu 2D/3D — poprawne skalowanie canvas przy zoomie"
problem: "Canvas rozjeżdżał się przy zoomie na ekranach HiDPI."
solution_summary: "Użyto devicePixelRatio zamiast stałego mnożnika."
dead_ends: ["Stały mnożnik 2x — łamał się na 1x DPI.", "CSS transform — rozmycie + zły hit-testing."]
scope: factory-candidate
reusability: high
```
Technika frontendowa (devicePixelRatio) generalizowalna, dead_ends niosą ostrzeżenie, anti_pii_verified.

**Źle — błędna klasyfikacja jako `factory-candidate`:**
```yaml
title: "Stawka VAT 8% dla materiałów dekarskich — poprawna konfiguracja"
solution_summary: "Ustawiono stawkę 8% dla kategorii 'materiały budowlane' w konfiguracji FV."
scope: factory-candidate  # BŁĄD — domena biznesowa, projekt-specific
```
To domena DemoApp, nie technika. Prawidłowe `scope: project-local`.

### Przykład 2 — prawo do ciszy vs zapis

**Dobrze — cisza (reflector nic nie zapisuje):**
```
Sesja: bump wersji package.json 1.2.3 → 1.2.4, 1 commit.
Stop-hook przekracza próg ilościowy (≥1 commit).
Reflector ocenia jakościowo: bump wersji, brak nowej wiedzy, brak dead_ends.
→ Cisza. Output: "Brak rozwiązań wartych zapisu — sesja mechaniczna."
```

**Dobrze — zapis:**
```
Sesja: 3h walki z PDF (wkhtmltopdf vs jsPDF vs Puppeteer), 6 commitów, 12 plików.
dead_ends = [wkhtmltopdf — brak UTF-8 PL, jsPDF — brak tabel]; solution = Puppeteer headless.
→ solutions/2026-06-07-pdf-generation-pl-utf8.md; scope: factory-candidate (reusability high).
```

---

## 7. Antywzorce

- **Zapis każdej sesji bez oceny jakościowej** — zaśmieca recall szumem (bump wersji, lint, rename). Prawo do ciszy reflectora jest fundamentem użytecznego recall.
- **`factory-candidate` dla domen biznesowych** — "stawka VAT dla drewna" to app-specific, NIE wzorzec techniki. Lekcja #118: ~90% rozwiązań z pilota to app-specific.
- **`anti_pii_verified: true` bez wykonania skanu** — w warstwie bez HITL to jedyna bariera. Ustawiaj DOPIERO po regex skanie.
- **Recall bez budżetu tokenów** — wczytywanie pełnych md (ze wszystkimi sekcjami) przy starcie sesji zamiast lekkiego indeksu. Indeks = szybki filtr, pełne md = tylko dla trafionych.
- **Fuzzy dedup w v1** — implementacja similarity-dedup po tags/domain to dług v2. W v1 wyłącznie MD5 exact.
- **Reflector wywołany ręcznie do "podsumowania czatu"** — to działka conversation-learning, nie solution-reflector.

---

## 8. Czego skill NIE robi

- **NIE implementuje pre-filtra progu ilościowego** (≥1 commit / ≥3 edycje) — to Stop-hook `stop-solution-record.sh` (etap 8 planu).
- **NIE jest producentem zapisów** — to `solution-reflector`. Skill opisuje konwencję; reflector ją implementuje.
- **NIE dotyka strumienia `candidate-lessons.jsonl` ani werbalnego feedbacku** — to `conversation-learning`.
- **NIE promuje rozwiązań do fabryki** — to `/weekly-factory-intake` (bramka HITL). Skill opisuje sygnaturę kandydata (`scope: factory-candidate`), nie akt promocji.

---

## 9. Powiązania

| Artefakt | Relacja |
|---|---|
| `library/agents/universal/solution-reflector.md` | Jedyny producent md + indeksu; implementuje kontrakt tego skilla |
| `library/skills/universal/conversation-learning/SKILL.md` | Siostra — druga oś learning-loopu (werbalny feedback operatora) |
| `.claude/knowledge-base/solution-memory-schema.json` | Schemat walidacji linii indeksu + frontmatter md |
| `.claude/knowledge-base/docs/solution-memory/adr/001-model-solution-memory.md` | ADR — wybór md+index (opcja C) + reguła scope |
| `stop-solution-record.sh` (hooks) | Trigger — pre-filtr ilościowy przed wywołaniem reflectora |
| `session-start-embedded.sh` (hooks) | Recall przy SessionStart — tail N indeksu, apply-silently |
| `/weekly-factory-intake` | HITL gate do fabryki dla `factory-candidate` rozwiązań |
| `embedded-factory` | Każda paczka af-pack-* dostaje ten skill + scaffold `solutions/` + indeks |

---

## Changelog

- **v1.0.0 (2026-06-06, plan autonomiczne-samouczenie etap 6):** Initial — konwencja md+index, recall SessionStart (tail N=5, sub-budżet ~1200 znaków), scope ADR-001, integracja z solution-reflector, flow ASCII, granica z conversation-learning.
