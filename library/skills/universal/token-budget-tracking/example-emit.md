# example-emit.md — token tracking emit examples

**Origin:**  B1 (2026-05-13).
**Cel:** Konkretne przykłady jak agent emit `actual_token_cost` w activity-log.

---

## Przykład 1 — version-bumper (Python script-based)

Po wykonaniu workflow Krok 1-7:

```python
import json
import os
from datetime import datetime, timezone

# Estimate tokens (proxy method)
input_text = system_prompt + context + user_input  # ~3 chars/token dla PL
estimated_input = len(input_text) // 3
estimated_output = len(json.dumps(proposal_report)) // 3

entry = {
    "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "actor": "version-bumper",
    "action": "version_proposals_generated",
    "artifact": "knowledge-base/version-bumper-reports/...",
    "status": "ok",
    "notes": "3 proposals, confidence ≥2.0",
    "actual_token_cost": {
        "input": estimated_input,
        "output": estimated_output,
        "total": estimated_input + estimated_output,
        "model": "opus",
        "estimation_method": "proxy"
    }
}

with open("knowledge-base/activity-log.jsonl", "a") as f:
    f.write(json.dumps(entry) + "\n")
```

---

## Przykład 2 — agent-architect (self-report w output JSON)

Agent kończy workflow + dodaje `_meta`:

```json
{
  "agent_created": "version-bumper",
  "path": ".claude/agents/version-bumper.md",
  "status": "ok",
  "_meta": {
    "estimated_input_tokens": 3500,
    "estimated_output_tokens": 8200,
    "model_used": "opus",
    "iterations": 2
  }
}
```

Main Claude orchestrator parsuje `_meta` + appenduje do activity-log:

```bash
META=$(echo "$AGENT_OUTPUT" | jq '._meta')
INPUT=$(echo "$META" | jq -r '.estimated_input_tokens')
OUTPUT=$(echo "$META" | jq -r '.estimated_output_tokens')
MODEL=$(echo "$META" | jq -r '.model_used')

echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"actor\":\"agent-architect\",\
\"action\":\"agent_created\",\"artifact\":\".claude/agents/version-bumper.md\",\
\"status\":\"ok\",\"actual_token_cost\":{\"input\":$INPUT,\"output\":$OUTPUT,\
\"total\":$((INPUT+OUTPUT)),\"model\":\"$MODEL\",\"estimation_method\":\"self_report\"}}" \
>> knowledge-base/activity-log.jsonl
```

---

## Przykład 3 — quality-checker (bash agent)

```bash
#!/bin/bash
# Quality-checker workflow...

# Po walidacji
RESULT="PASS"
INPUT_PROXY=$(($(wc -c < $AGENT_FILE) / 3))   # plik input proxy
OUTPUT_PROXY=500  # quality-checker output zwykle ~500 tokens (brief report)

jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg artifact "$AGENT_FILE" \
  --argjson input "$INPUT_PROXY" \
  --argjson output "$OUTPUT_PROXY" \
  --argjson total "$((INPUT_PROXY + OUTPUT_PROXY))" \
  '{ts:$ts, actor:"quality-checker", action:"quality_pass",
    artifact:$artifact, status:"ok",
    actual_token_cost:{input:$input, output:$output, total:$total,
                       model:"opus", estimation_method:"proxy"}}' \
  >> knowledge-base/activity-log.jsonl
```

---

## Przykład 4 — Anthropic SDK exact (paczka klienta)

Gdy fabryka generuje paczkę używającą Claude API directly:

```python
import anthropic

client = anthropic.Anthropic

response = client.messages.create(
    model="claude-opus-4-7",
    max_tokens=1024,
    messages=[{"role": "user", "content": prompt}]
)

# EXACT tokens z API response
exact_input = response.usage.input_tokens
exact_output = response.usage.output_tokens

# Emit do activity-log (lub equivalent log paczki)
entry = {
    "ts": datetime.now(timezone.utc).isoformat + "Z",
    "actor": "claude-api-call",
    "action": "task_completed",
    "artifact": prompt[:50] + "...",
    "actual_token_cost": {
        "input": exact_input,
        "output": exact_output,
        "total": exact_input + exact_output,
        "model": "claude-opus-4-7",
        "estimation_method": "exact"
    }
}
```

---

## Anti-pattern przykłady

### ❌ Skip emit

```python
# BAD:
print("Done")  # NIC w activity-log
```

### ❌ Brak estimation_method

```json
{"actual_token_cost": {"input": 1234, "output": 567, "total": 1801, "model": "opus"}}
// Brak estimation_method — non-auditable
```

### ❌ Hardcoded model (bez auto-downgrade tracking)

Agent oficjalnie opus, ale  B3 auto-downgrade do sonnet. Activity-log MUSI emit faktyczny model (sonnet), NIE "opus" z definition.

---

## Verification (post-emit)

Po każdym emit — sprawdź:

```bash
tail -1 knowledge-base/activity-log.jsonl | jq '.actual_token_cost'
# Expected: {"input": N, "output": N, "total": N, "model": "...", "estimation_method": "..."}
```

Jeśli `null` → schema validation FAIL → fix agent emit code.

---

**Version:** 1.0.0 ( B1)
