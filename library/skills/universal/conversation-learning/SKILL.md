---
name: conversation-learning
description: Wzorzec ekstrakcji lessons z chat history (operator feedback w sesji), NIE tylko z committed artifacts (lessons.jsonl / reflections). Adresuje gap: operator says "to było źle" w trakcie sesji ale nigdy NIE staje się lesson (zniknie z konteksu). Konwencja: detect feedback patterns w prompt → append candidate lesson → HITL gate przez /review-candidate-lessons → promotion do lessons.jsonl. Path 1 (UserPromptSubmit hook) produkcyjny od .
type: skill
version: 1.1.0
category: universal
tags: [learning, conversation, feedback-extraction, lessons-pipeline, intelligence, hook-production]
distribution: standard
compatible_with: [universal, agent-factory, embedded-factory]
requires: [error-memory-framework, cross-agent-learning, model-routing]
provides: [candidate-lessons-pipeline, hitl-batch-review]
token_cost: low
---

# conversation-learning

## Before starting work (cross-agent-learning krok 0)

Konsument tego skilla (main Claude, agent-architect, embedded-factory agents) MUSI przed użyciem przeczytać:

1. **`knowledge-base/lessons.jsonl` tail 20** — ostatnie lessons, szczególnie z `category: conversation-learning` lub `triggered_by: conversation-learning-hook`
2. **`.claude/knowledge-base/candidate-lessons.jsonl`** (jeśli istnieje) — pending HITL candidates, sprawdź `hitl_approved IS NULL` count
3. **`reflections/` last 3** — czy ostatnie sesje pokazują systemic gap który ten skill może wypełnić

Budget: ~3-5k tokenów. Apply silently rule (nie wypisuj że czytałeś).

## Cel

Adresować gap w learning loop: **operator feedback w trakcie sesji często NIE staje się lesson.**

**Audyt baseline 2026-05-13:**
- 98 lessons.jsonl entries (formal)
- 68 reflections (formal)
- ~500+ chat interactions w sesji (operator "to powinno być", "źle", "lepiej tak") = **0 lessons captured z tego**

**Konsekwencja:** valuable feedback operatora zostaje tylko w context window — po session end znika.

## Kiedy stosować

- **Każda sesja długoterminowa** (>2h) — main Claude monitor operator prompts dla feedback patterns
- **Po major decyzjach** (np. "rób tak jak rekomendujesz") — capture rationale jako lesson
- **Po korekcie** ("nie tak, zrób X") — capture pattern co operator odrzucił

## Feedback patterns detection

### Pattern 1 — Explicit correction

User mówi: "**nie**, zrób X" / "**źle**, to powinno być Y" / "**stop**, to **NIE** tak"

**Action:** capture jako lesson:
- `category`: scope-management / agent-design / planning (zależne)
- `severity`: MED (zwykle)
- `title`: short summary co operator skorygował
- `lesson`: what was wrong + what's right
- `action`: propagate-to (NIE re-do tego błędu)

### Pattern 2 — Explicit preference

User mówi: "**wolę** X" / "**zawsze** rób X" / "**bardziej** mi pasuje Y"

**Action:** capture jako preference (NIE error):
- `category`: planning / agent-design
- `severity`: LOW (preference, NIE bug)
- `title`: "User preference: X"
- `lesson`: preference + context (kiedy zastosować)

### Pattern 3 — Surprise/discovery

User mówi: "**aha**, nie wiedziałem że X" / "**ciekawe** że Y" / "**hm**, to działa"

**Action:** capture jako META insight:
- `category`: meta / cross-cutting
- `severity`: META (insight, NIE action)
- `title`: short discovery
- `lesson`: observation + implication

### Pattern 4 — Frustration / blocker

User mówi: "**dlaczego** X nie działa" / "**ciągle** problem" / "**znowu** to samo"

**Action:** capture jako HIGH severity issue:
- `category`: agent-design / tooling
- `severity`: HIGH
- `title`: what's blocking
- `lesson`: root cause (jeśli identified) + workaround

### Pattern 5 — Decision confirmation

User mówi: "**tak**, dobrze" / "**super**" / "**idealnie**" / "**rób tak jak rekomendujesz**"

**Action:** capture jako VALIDATION (decyzja approved):
- `category`: planning
- `severity`: META
- `title`: "Validated approach: X"
- `lesson`: confirmed pattern — apply w przyszłości

## Workflow ekstrakcji

Main Claude w trakcie sesji:

```python
# Per operator prompt (UserPromptSubmit hook level lub orchestrator level)
def extract_feedback(prompt: str, last_assistant_message: str) -> dict | None:
    patterns = {
        "correction": [r"\bnie\b", r"\bźle\b", r"\bstop\b", r"\bNIE\b"],
        "preference": [r"\bwolę\b", r"\bzawsze\b", r"\bbardziej\b", r"\bpasuje\b"],
        "surprise": [r"\baha\b", r"\bciekawe\b", r"\bhm\b"],
        "frustration": [r"\bdlaczego\b.*nie", r"\bciągle\b", r"\bznowu\b"],
        "confirmation": [r"\btak\b", r"\bsuper\b", r"\bidealnie\b", r"\brób tak\b"]
    }

    for pattern_type, regexes in patterns.items:
        for regex in regexes:
            if re.search(regex, prompt, re.IGNORECASE):
                return {
                    "pattern_type": pattern_type,
                    "context": last_assistant_message[:200],
                    "feedback": prompt[:300],
                    "suggested_lesson": draft_lesson(pattern_type, prompt, last_assistant_message)
                }
    return None
```

## HITL gate dla extraction

**NIE auto-append do lessons.jsonl bez operator approve.** Workflow:

1. Detect feedback pattern w prompt
2. Draft suggested lesson (LLM synthesis)
3. **HITL:** wypisz proposed lesson do operatora:
   ```
   📝 Conversation learning detected (pattern: correction):

   Suggested lesson:
   - Title: "..."
   - Severity: MED
   - Lesson: "..."

   Append to lessons.jsonl? [y/N/edit]
   ```
4. Jeśli operator `y` → append (z `triggered_by: "conversation-learning"`)
5. Jeśli `edit` → operator modyfikuje proposed → save
6. Jeśli `N` → skip

## Frequency control

**Anti-spam:** NIE każdy "tak" / "nie" w prompt = lesson. Threshold:
- Pattern detect → suggest TYLKO jeśli context warrants (long context, complex decision, recurring issue)
- Per session: max 5 conversation-learning suggestions (avoid noise)
- Cooldown: NIE re-suggest tego samego patternu w 30 min (operator powiedział "nie" wielokrotnie)

## Implementation paths

### Path 1 — Hook UserPromptSubmit (production, od )

**Production hook:** `library/hooks/userPromptSubmit-conversation-learning.sh` (~280l bash, 20/20 .test.sh PASS)

**Mechanizm:**
1. Hook czyta JSON ze stdin (`{prompt: "..."}`)
2. Early exit dla pustych / krótkich (<50ch) promptów
3. Frequency check (max 5/session — `.session-candidate-count`)
4. Cooldown check per pattern (30 min — `.pattern-cooldown.json`)
5. Bash native regex match 5 patternów (priority HIGH→LOW: correction, frustration, preference, decision-confirmation, surprise)
6. Performance budget <100ms hard limit — skip append jeśli przekroczone (log do `.claude/hooks-perf-warn.jsonl`)
7. Atomic append candidate JSON do `.claude/knowledge-base/candidate-lessons.jsonl`
8. Stderr soft-reminder TYLKO dla HIGH (correction + frustration)
9. Exit 0 zawsze (informational, NIGDY nie blokuje)

**Portable:** używa `$CLAUDE_PROJECT_DIR` lub fallback cwd. Identyczny w `library/hooks/` (fabryka) i `library/embedded-factory/hooks/` (paczki af-pack-* od ).

**Schema candidate-lessons.jsonl** — własna `knowledge-base/candidate-lessons-schema.json` (PRE-HITL gate, NIE blokuje lessons.jsonl commit):

```json
{
  "schema_version": 1,
  "ts": "2026-05-24T14:30:00Z",
  "origin": "conversation-learning-hook",
  "pattern": "correction|frustration|preference|decision-confirmation|surprise",
  "user_prompt_snippet": "max 200ch",
  "context_window_hint": null,
  "candidate_lesson": "auto-generated stub, HITL enriches",
  "severity": "low|medium|high",
  "confidence_hits": 1,
  "secondary_patterns": [],
  "promoted_to_factory": false,
  "hitl_approved": null,
  "session_id": "optional from $CLAUDE_SESSION_ID"
}
```

**HITL gate przez `/review-candidate-lessons`** — operator batch review (default 10/batch), akcje `y/n/e/s/q`. Accept → promotion do lokalnego `.claude/knowledge-base/lessons.jsonl` (NIE centralna fabryka — promotion to fabryki przez `/promote-lessons` od ).

**Instalacja w settings.json:**
```json
"UserPromptSubmit": [{
  "matcher": "*",
  "hooks": [{
    "type": "command",
    "command": ".claude/hooks/userPromptSubmit-conversation-learning.sh"
  }]
}]
```

### Path 2 — main Claude observation (fallback — manual)

Bez hook — main Claude reads incoming prompt, applies patterns mentally, proposes lesson capture. Używane gdy hook NIE jest zainstalowany lub w sesjach typu meta (architecture review).

**Coexistence:** Path 1 i Path 2 mogą działać równolegle — hook capture quick patterns, main Claude wychwytuje subtelne (long context, multi-message threads).

## Use cases (concrete examples)

### Use case 1 — Path 1 hook capture + batch HITL review

```
[during session — hook auto-captures]
operator: "nie, źle — zamiast Read+Edit użyj Write całego pliku"
→ hook detect "correction" (HIGH)
→ stderr soft-reminder do main Claude
→ candidate appended do .claude/knowledge-base/candidate-lessons.jsonl

[after session — operator reviews batch]
operator: /review-candidate-lessons
→ shows 7 pending candidates from session
→ operator accepts 5, rejects 2
→ 5 promoted do lokalnego lessons.jsonl
→ activity-log entry: batch summary
```

### Use case 2 — Decision confirmation captured

```
operator: "tak, dobrze — idziemy z opcją build-script zamiast symlink"
→ hook detect "decision-confirmation" (MED, NO stderr reminder)
→ candidate appended silently
→ operator w /review widzi context + accept jako "ADR rationale capture"
```

### Use case 3 — Frequency control w działaniu

```
[w sesji operator daje 6 corrections w 1h]
→ hook capture first 5 candidates
→ 6th correction: hook hits MAX_PER_SESSION=5
→ entry do .claude/hooks-throttle.jsonl
→ silent exit, operator nie dostaje stderr noise
→ session continues, hook resets na SessionStart (lub 8h bezczynności)
```

### Use case 4 — Path 2 fallback (hook nie zainstalowany)

```
operator: "wolę żebyś używał bash native regex zamiast grep"
main Claude (manual Path 2):
  📝 Conversation learning detected (preference):
  Proposed candidate lesson: "User preference: bash native regex over grep w hookach"
  Append to lessons.jsonl? [y/N/edit]
operator: y
→ direct append (manual workflow, NIE candidate gate)
```

## Activity-log

```bash
echo '{"ts":"...","actor":"conversation-learning","action":"lesson_logged","artifact":"lessons.jsonl","status":"ok","notes":"pattern: <type>, source: chat"}' >> knowledge-base/activity-log.jsonl
```

## Anti-patterns

- ❌ **Auto-append bez HITL** — spam lessons.jsonl + operator traci kontrolę
- ❌ **Pattern detection ZA szerokie** — każde "tak"/"nie" = false positive
- ❌ **Bez context** — lesson "operator powiedział tak" bez WHAT = useless
- ❌ **Re-suggest tego samego** — annoying, cooldown 30 min minimum

## Update procedure

- Q+1 review patterns — czy operator feedback evolution wymaga new patterns?
- Q+1 frequency control tuning (jeśli 5/session za mało lub za dużo)
- Last review: 2026-05-24 (v1.1.0  — Path 1 production hook)

## Changelog

- **v1.1.0 (2026-05-24, ):** Path 1 production hook (`userPromptSubmit-conversation-learning.sh`) + HITL gate command `/review-candidate-lessons` + schema `candidate-lessons-schema.json` + sekcja "Before starting work" (cross-agent-learning krok 0) + `compatible_with: embedded-factory`. Path 1 placeholder zastąpiony produkcyjną specyfikacją.
- **v1.0.0 (2026-05-13,  C3):** Initial skill, 5 patternów spec, Path 2 manual, Path 1 placeholder.

---

**Version:** 1.1.0 
**Konsumenci:** main Claude (real-time + Path 2 fallback), hook UserPromptSubmit (Path 1 production), agent-architect (czyta candidate-lessons przed projektowaniem), embedded-factory agents (od  — same hook bundlowany do paczek af-pack-*)
