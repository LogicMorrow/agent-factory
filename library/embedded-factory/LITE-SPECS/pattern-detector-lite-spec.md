# Spec: `pattern-detector-lite` (embedded variant)

**Status:** spec ready for implementation (NIE pełna implementacja — to specyfikacja)
**Source-of-truth (build.sh input):** `library/embedded-factory/LITE-SPECS/pattern-detector-lite-source.md` (intermediate file dla build-script, ADR 009)
**Output (build.sh derived):** `library/embedded-factory/agents/pattern-detector-lite.md` (po sed-replace + path transformations)
**Related ADRs:** 008 (lite vs full arch), 009 (copy strategy), 011 (cold start threshold)

---

## Frontmatter spec

```yaml
---
name: pattern-detector-lite
description: Lite wariant pattern-detector dla projektów (embedded-factory). LLM (sonnet) analizuje lokalne lessons.jsonl + errors-*.md + reflections i wykrywa cross-agent patterns w projekcie. Cold start <10 lessons (vs <50 w fabryce). Generuje `.claude/knowledge-base/patterns/<date>-<slug>.md` z propozycją lokalnej akcji. Wywoływany manualnie `/pattern-detector-lite` lub przez self-pilot-lite weekly z `--include-patterns` flag.
type: agent
version: 1.0.0
category: meta
tags: [meta, embedded, pattern-detection, llm-analysis, lite-variant]
model: sonnet
tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Write
compatible_with: [embedded-factory-1.0.0+]
requires: [cross-agent-learning, error-memory-framework, model-routing]
distribution: embedded
token_cost: medium
---
```

**Diff vs full frontmatter:**
- `name: pattern-detector-lite` (vs `pattern-detector`)
- `model: sonnet` (vs `opus`) — cost optimization
- `tags`: dodane `lite-variant`, dropped `intelligence` (lite jest mniej "smart" niż full)
- `compatible_with: [embedded-factory-1.0.0+]` (vs `[agent-factory]`)
- `distribution: embedded` (vs `factory-only`)
- `token_cost: medium` (vs `high`)

---

## Args spec

```
/pattern-detector-lite [--since=<date|-Nd>] [--min-occurrences=N]
```

| Arg | Default lite | Default full | Reason |
|---|---|---|---|
| `--since` | `-30d` | `-90d` | Krótsza historia typowego projektu (~1-3 miesiące lifetime) |
| `--min-occurrences` | `2` | `3` | Niższy threshold dla mniejszej sample size |
| `--focus=<category>` | **USUNIĘTE** | TAK | YAGNI — projekt ma <10 agentów, brak potrzeby filtrowania |
| `--include-resolved` | **USUNIĘTE** | TAK | YAGNI — embedded simplicity |
| `--include-cross-project` | **NIE wprowadzone** | N/A | Cross-projekt = rola fabryki cron pull-merge |

---

## Cold start protection (3 progi + 1 recommendation tier)

Krok 1 workflow MUSI wykonać check przed jakąkolwiek analizą:

```python
local_lessons_count = wc_l(".claude/knowledge-base/lessons.jsonl") - header_lines

# Próg 1: SKIP całkowity
if local_lessons_count < 5:
    print(f"⏸  pattern-detector-lite SKIPPED")
    print(f"Insufficient data — collect more lessons before pattern analysis.")
    print(f"Lessons available: {local_lessons_count}, minimum: 5.")
    print(f"Continue using project, return after ≥10 lessons captured.")
    activity_log({"action":"pattern_detection_skipped","reason":"insufficient_data","count":local_lessons_count})
    exit(0)

# Próg 2: SKIP audyt + lite report "early-stage"
elif local_lessons_count < 10:
    generate_early_stage_report(local_lessons_count)
    # = `.claude/knowledge-base/patterns/<date>-early-stage.md`
    # = 3 top error_cause keywords (frequency count, NO LLM synthesis)
    # = note: "early-stage data, threshold 10 for full analysis"
    activity_log({"action":"early_stage_report","count":local_lessons_count})
    exit(0)

# Próg 3 + 4: RUN full lite analysis
else:
    run_full_lite_analysis
    if local_lessons_count >= 30:
        # Dopisek do output summary
        append_promote_recommendation
```

**Schema `early-stage.md`:**

```markdown
# Pattern detection — early-stage report (<date>)

**Status:** early-stage data (X lessons, threshold 10 for full analysis)
**Lessons analyzed:** X (since: <30d default>)
**Action:** continue using project — full analysis available at ≥10 lessons

## Top error_cause keywords (frequency)

| # | Keyword | Count | Example excerpt |
|---|---|---|---|
| 1 | <keyword> | N | "..." |
| 2 | ... | ... | ... |
| 3 | ... | ... | ... |

## Note

Pełna analiza pattern (LLM synthesis, cross-agent correlation, proposed systemic fix) dostępna od ≥10 lessons.
NIE są to actionable patterns — tylko surface-level themes dla orientacji.
```

---

## Workflow (5 kroków — z full's 6 usunięty Krok 5 aggregate jeśli single pattern)

### Krok 0: Before starting work (cross-agent-learning E2)

Standard `Before starting work` sekcja (cross-agent-learning skill,  fabryki +  embedded):

1. Czytaj `.claude/memory/errors-pattern-detector-lite.md` (jeśli istnieje, skip cicho)
2. Czytaj 3 najnowsze reflections (`.claude/knowledge-base/reflections/`) — szczególnie poprzednie pattern-detector-lite runs
3. Czytaj WSZYSTKIE poprzednie pattern files w `.claude/knowledge-base/patterns/` — żeby NIE re-detect tego samego patternu (idempotency)

**Budget:** max ~5 000 tokenów (mniejszy niż full ~10k, mniejszy lokalny scope).

**Apply silently.**

### Krok 1: Cold start check

Implementacja `cold start protection` (sekcja powyżej). EXIT 0 jeśli `<5` lub `5-9` lessons (po wygenerowaniu early-stage report).

### Krok 2: Load sources

1. **`.claude/knowledge-base/lessons.jsonl`** — full, filter `--since` + severity ∈ [HIGH, MED]
2. **`.claude/memory/errors-*.md`** — wszystkie pliki agentów lokalnych, parse wpisy (severity + cause + prevention)
3. **`.claude/knowledge-base/reflections/`** — last 10 (vs 30 w fabryce), grep "Co poszło źle" / "Lessons" / "Patterns" sekcje
4. **Existing patterns** — `.claude/knowledge-base/patterns/*.md` (NIE re-detect)

**Sed transformations (build.sh ADR 009 zapewnia):**
- `knowledge-base/lessons.jsonl` → `.claude/knowledge-base/lessons.jsonl`
- `knowledge-base/reflections/` → `.claude/knowledge-base/reflections/`
- `knowledge-base/patterns/` → `.claude/knowledge-base/patterns/`
- `library/library-index.json` → `.claude/embedded-factory-manifest.json` (lokalna kopia)

### Krok 3: Tokenize root causes + detect clusters

Identyczny jak full (heurystyczna tokenizacja: lowercase, remove PL stop words, extract noun phrases, cluster by semantic similarity).

**Threshold lite:** clusters z `≥--min-occurrences` (default 2 vs 3 full).

### Krok 4: LLM synthesis per cluster (sonnet)

Identyczny output schema jak full pattern-detector (federacja compatibility — patrz ADR 011 sekcja "Lite vs full feature matrix"):

```markdown
# Pattern: <Name>

**Detected:** <date> (pattern-detector-lite v1.0.0)
**Occurrences:** N across M agents (lokalnych)
**Severity (median):** HIGH | MED | LOW
**Status:** unresolved | partial | resolved

## Pattern signature
- Root cause: <jednolity opis>
- Symptoms: <jak się manifestuje>
- Distinguishing keyword: <token który clusters>

## Sources

| # | Source | Date | Severity | Agent | Excerpt |
|---|---|---|---|---|---|
| 1 | lesson #N | <date> | <sev> | <agent> | "..." |
| ... | ... | ... | ... | ... | ... |

## Proposed systemic fix (lokalny)

**NIE per-agent patch** — systemic action w projekcie:
- Update lokalnego agenta (przez `/new-agent` patch v1.0.X — version-bumper)
- Update lokalnego skill / hook
- Lokalna dokumentacja w `.claude/docs/`

## Action items
1. ...
2. ...

## Decision
**Recommended:** APPROVE / DEFER / REJECT (user HITL)

- **APPROVE** → spawn lokalna implementacja (version-bumper / agent-architect / skill-builder embedded)
- **DEFER** → review w next cycle (>14d)
- **REJECT** → noise, NIE pattern — dopisz dlaczego
```

### Krok 5: Generate summary + activity-log

`.claude/knowledge-base/patterns/<date>-summary.md`:
- Liczba detected patterns
- Per pattern: severity + occurrences + status
- Top patterns
- **Jeśli `lessons_count >= 30`:** dopisek `"Recommendation: run /promote-lessons — projekt ma znaczący wkład (≥30 lessons)"`

Activity-log (lokalny):
```bash
echo '{"ts":"<ISO>","actor":"pattern-detector-lite","action":"pattern_detected","artifact":".claude/knowledge-base/patterns/<date>/","status":"ok","notes":"N patterns lite","actual_token_cost":{"input":<>,"output":<>,"total":<>,"model":"sonnet","estimation_method":"proxy"}}' >> .claude/knowledge-base/activity-log.jsonl
```

---

## Output template — co trafia do `.claude/knowledge-base/patterns/`

3 typy plików (jak w full, ale lokalnie):

1. **Per-pattern file:** `.claude/knowledge-base/patterns/<date>-<pattern-slug>.md` — 1 plik per detected pattern (schema powyżej Krok 4)
2. **Aggregate summary:** `.claude/knowledge-base/patterns/<date>-summary.md` — 1 plik per run (cross-pattern insights)
3. **Early-stage report** (5-9 lessons tier): `.claude/knowledge-base/patterns/<date>-early-stage.md` — 1 plik dla cold start tier 2 (zamiast normal patterns)

---

## Anti-patterns (rzeczy których lite NIE robi)

- ❌ **LLM-judge per lesson** — lite NIE wywołuje LLM dla każdej z 30 lessons individually (cost explosion). LLM tylko na cluster level (po heurystycznej tokenizacji).
- ❌ **Cross-projekt scope** — lite NIE czyta lessons z innych paczek. Cross-projekt to rola fabryki cron `monthly-intelligence` po `/promote-lessons` federation.
- ❌ **Opus tokens** — lite na sonnet. Jeśli kiedyś projekt potrzebuje opus analysis (rzadkie use case), niech użyje fabryki `/pattern-detector` przez `/promote-lessons` + factory pull.
- ❌ **`--focus=<category>` filtering** — usunięte z lite (YAGNI, projekt ma <10 agentów).
- ❌ **`--include-resolved` flag** — usunięte (YAGNI v1.0.0).
- ❌ **Auto-implement systemic fix** — lite to ANALYZER, NIE actor. HITL gate ZAWSZE (user accept/reject per pattern).
- ❌ **Re-detect already-detected pattern** — Krok 0 czyta existing `.claude/knowledge-base/patterns/`, idempotency wymuszona.
- ❌ **Pattern detection w pattern files** (meta-meta-pattern) — noise, skip.
- ❌ **Single-source pattern** (N=1) — anegdota, NIE pattern. `--min-occurrences ≥2` wymuszone.

---

## Reguły niezmienne (lite-specific)

1. **NIE modyfikuje agentów/skilli/hooków** — tylko generuje pattern files + recommendations w `.claude/knowledge-base/patterns/`.
2. **Min occurrences 2 (lite) lub user override** — niższy niż full (3), ale wciąż >1.
3. **HITL gate dla każdej proposal** — user accept/reject/defer per pattern (jak fabryka).
4. **Idempotent re-run** — przy ponownym uruchomieniu (tego samego dnia) NIE duplicate patterns już detected.
5. **Embedded distribution** — kopiowany do paczek przez build.sh ADR 009.
6. **NIE wywołuje siebie rekurencyjnie** (avoid feedback loop).
7. **NIE pattern detection na patterns** (meta-meta-pattern = noise).
8. **Token-budget-tracking** — emit `actual_token_cost` per run.
9. **NIE cross-projekt scope** — local-only enforced przez sed transformations (build.sh).
10. **Federacja-compatible output schema** — markdown sections IDENTYCZNE jak full pattern-detector (żeby `/promote-lessons` mogło przekazać 1:1).

---

## Mistake-recorder triggering (lite-adjusted)

Jeśli pattern detection zwraca **>5 patterns** (vs >10 w full — lite mniejszy scope = mniejszy expected count, niższy próg noise detection) → wywołaj mistake-recorder severity MED:

```json
{
  "agent_name": "pattern-detector-lite",
  "error_summary": "noise threshold exceeded: 5+ patterns detected in lite scope",
  "error_cause": "min_occurrences za niski (2) lub tokenization za szeroka dla małego scope projektu",
  "prevention_hint": "tune --min-occurrences ≥3 lub rozważ czy projekt ma faktycznie tyle patterns (może to noise z niskiego sample)",
  "severity": "MED"
}
```

---

## Diff vs full — checklist co usunięto / co zmieniono

**Usunięte z full:**
- ❌ `--focus=<category>` flag
- ❌ `--include-resolved` flag
- ❌ Tryb `Cron weekly (przez self-pilot)` — w embedded self-pilot-lite ma `--include-patterns` opt-in flag (NIE auto-dispatch jak fabryka)
- ❌ Tryb `Post-lesson-batch` — `/review-lessons` (meta-reviewer) NIE w embedded (factory-only meta-agent)

**Zmienione:**
- Model: `opus` → `sonnet`
- `--since` default: `-90d` → `-30d`
- `--min-occurrences` default: `3` → `2`
- Reflections last: `30` → `10`
- Cold start: `<50 lessons` SKIP → **4-stopniowa matrix** (`<5` SKIP, `5-9` early-stage, `≥10` RUN, `≥30` RUN+promote-recommendation)
- Mistake-recorder noise threshold: `>10 patterns` → `>5 patterns`
- Output paths: `knowledge-base/patterns/` → `.claude/knowledge-base/patterns/` (sed transform build.sh)
- Activity-log path: `knowledge-base/activity-log.jsonl` → `.claude/knowledge-base/activity-log.jsonl`
- Cadence: weekly (cron) → monthly (manual lub opt-in self-pilot-lite)
- Token budget Krok 0 (Before starting work): `~10 000` → `~5 000`

**Niezmienione (federacja compatibility):**
- ✅ Output schema markdown (6 sekcji per pattern file)
- ✅ Aggregate summary structure
- ✅ HITL gate (operator / user accept/reject/defer)
- ✅ Idempotency (Krok 0 czyta existing patterns)
- ✅ Min-occurrences semantics (≥N wystąpień to próg "pattern" vs "anegdota")
- ✅ Activity-log entry schema (action: `pattern_detected`)

---

## References

- ADR 011: cold start threshold decyzja (`knowledge-base/docs/embedded-factory/adr/011-pattern-detector-lite-cold-start.md`)
- ADR 009: copy strategy (`knowledge-base/docs/embedded-factory/adr/009-copy-strategy.md`) — build.sh source-of-truth dla lite
- ADR 008: lite vs full architecture (definiuje WHAT jest lite)
- Source full agent: `.claude/agents/pattern-detector.md` (factory-only opus, reference dla schema niezmienionych sekcji)
- Manifest: `library/embedded-factory/manifest.json` entry `pattern-detector` z `cold_start_threshold: 10`, `lite: true`, `model: sonnet`
- Brief: `knowledge-base/interviews/2026-05-24-embedded-factory.md` (sekcja 4 lite vs full tabela)

---

**Spec status:** READY for E7 (copy skille + bundling) — build.sh ADR 009 uruchomi po finalizacji `pattern-detector-lite-source.md` (intermediate source file dla build-script).
**Next action E7:** copy skille (cross-agent-learning v1.1.0 patch dla embedded mode cold start matrix), hook bundling, lite-source file creation.
