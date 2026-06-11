---
name: token-budget-tracking
description: Convention dla każdego agenta — emit `actual_token_cost` field w activity-log entry post-execution. Pozwala na cost analytics (cost-per-agent.py) + weekly cost reports + budget alerts. Trigger systemowy  (Performance & Token Economy) — adresuje "nie wiemy ile kosztuje fabryka" gap.
type: skill
version: 1.0.0
category: universal
tags: [tokens, cost, performance, analytics, operationalize]
distribution: standard
compatible_with: [universal, agent-factory]
requires: [cross-agent-learning, model-routing]
token_cost: low
---

# token-budget-tracking

## Cel

Wszystkie agenty fabryki emit `actual_token_cost: {input, output, total, model}` w activity-log po wykonaniu zadania. Bez tego: **fabryka nie wie ile realnie kosztuje uruchomienie agenta X** —  fix.

**Audyt baseline 2026-05-13:** 247 wpisów w activity-log, 0 ma `actual_token_cost`. Nie wiemy kto pali najwięcej tokenów.

## Kiedy stosować

- Każdy meta-agent (factory-only): version-bumper, self-pilot, pilot-orchestrator, quality-checker — MANDATORY
- Każdy library agent: jeśli wywoływany przez Task tool z user prompt — MANDATORY
- Hooks: NIE (hooks są krótkie, ~50-200 tokens, ignore)
- Bash scripts: NIE (nie LLM calls)

## Schema (activity-log addition)

Standard wpis activity-log (+):
```json
{"ts": "2026-05-13T...", "actor": "agent-name", "action": "...",
 "artifact": "...", "status": "ok", "notes": "..."}
```

** addition** — dodaj field `actual_token_cost`:
```json
{"ts": "2026-05-13T...", "actor": "agent-name", "action": "...",
 "artifact": "...", "status": "ok", "notes": "...",
 "actual_token_cost": {
   "input": 1234,
   "output": 567,
   "total": 1801,
   "model": "opus",
   "estimation_method": "exact|proxy|self_report"
 }}
```

**Pola:**
- `input` (int) — tokeny input (system prompt + context + user input)
- `output` (int) — tokeny output (response)
- `total` (int) — sum
- `model` (string) — opus | sonnet | haiku
- `estimation_method` (string) — `"exact"` (z API response), `"proxy"` (estymata z znaków÷4), `"self_report"` (agent sam policzył)

## Metody pomiaru

### Method 1: Exact (preferowane — gdy używamy Anthropic SDK directly)

Anthropic API zwraca `usage: {input_tokens, output_tokens}` w response. Bezpośrednio użyj te wartości.

**Use case:** projekty z Anthropic SDK (`anthropic` Python package) — np. paczki klientów które używają Claude API.

### Method 2: Proxy (fallback — Claude Code CLI bez exposed token counts)

**Problem:** Claude Code CLI NIE exposuje token counts post-execution dla agentów wywołanych przez Task tool.

**Workaround proxy:**
- `input ≈ len(system_prompt + user_input) / 4` (rough — 4 chars ≈ 1 token dla EN, 3 chars ≈ 1 token dla PL)
- `output ≈ len(response_text) / 4`

**Accuracy:** ±20-30% (proxy nie liczy tool use overhead). Sufficient dla aggregate trends, NIE dla precyzyjnych billing.

### Method 3: Self-report (agent sam liczy w Krok N workflow)

Agent kończy workflow + dodaje do output JSON:
```json
{
  "result": "...",
  "_meta": {
    "estimated_input_tokens": 1234,
    "estimated_output_tokens": 567,
    "model_used": "opus"
  }
}
```

Main Claude orchestrator parsuje + emit do activity-log.

## Emit pattern (Bash)

Po wykonaniu agent action — appenduj do activity-log:

```bash
# W agencie po Krok 7 (output) lub po main task:
INPUT_TOKENS="<liczba lub estimacja>"
OUTPUT_TOKENS="<liczba>"
TOTAL=$((INPUT_TOKENS + OUTPUT_TOKENS))
MODEL="opus"  # lub sonnet/haiku

JSON_ENTRY=$(jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg actor "$AGENT_NAME" \
  --arg action "$ACTION" \
  --arg artifact "$ARTIFACT_PATH" \
  --argjson input "$INPUT_TOKENS" \
  --argjson output "$OUTPUT_TOKENS" \
  --argjson total "$TOTAL" \
  --arg model "$MODEL" \
  '{ts:$ts, actor:$actor, action:$action, artifact:$artifact, status:"ok",
    actual_token_cost: {input:$input, output:$output, total:$total, model:$model,
                        estimation_method: "proxy"}}')

echo "$JSON_ENTRY" >> knowledge-base/activity-log.jsonl
```

## Aggregation (cost-per-agent.py)

Patrz `library/scripts/cost-per-agent.py` — agreguje wszystkie entries z `actual_token_cost` field, oblicza kosztTotal per agent / per dzień / per model.

## Pricing reference (USD per million tokens, status 2026-05-13)

| Model | Input $/M | Output $/M |
|---|---|---|
| Claude Opus 4.7 | 15.00 | 75.00 |
| Claude Sonnet 4.6 | 3.00 | 15.00 |
| Claude Haiku 4.5 | 0.80 | 4.00 |

**Update procedure:** review Q+1 (next: 2026-08-13).

## Anti-patterns

- ❌ **Skip emit** "bo nie wiem ile tokenów" — lepiej proxy estymata niż brak danych
- ❌ **Self-report bez metody** — emit `estimation_method` zawsze (auditable)
- ❌ **Cache stats z agent definition** — w agencie .md NIE umieszczaj actual costs (zmieniają się per run)
- ❌ **Hardcoded model w activity-log** — emit `model` field z faktycznego użytego (auto-downgrade może zmienić)

## Update procedure skilla

- Q+1 review pricing (Anthropic zmienia ceny rocznie)
- Q+1 verify czy nowy metryk (cache_read_tokens?) wymaga schema update

---

**Version:** 1.0.0 ( B1)
**Last review:** 2026-05-13
