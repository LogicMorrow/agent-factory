#!/usr/bin/env bash
# library/scripts/retrofit-token-tracking.sh
#
# Batch retrofit "actual_token_cost" emit pattern do agentów library.
# Dodaje sekcję "## Token tracking ( B1)" w body agenta z emit example
# proxy estimation method.
#
# Origin: .1 (2026-05-13).
# Idempotent: skip jeśli już ma sekcję.

set -uo pipefail

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

TARGETS=$(find library/agents -name "*.md" -exec grep -L "Token tracking\|actual_token_cost" {} \;)

if [ -z "$TARGETS" ]; then
  echo "✅ All agents already have Token tracking section."
  exit 0
fi

FAIL=0
TOTAL=0
PATCHED=0

for file in $TARGETS; do
  TOTAL=$((TOTAL+1))
  name=$(grep -m1 "^name:" "$file" | sed 's/^name: *//; s/^"\(.*\)"$/\1/' | head -1)
  model=$(grep -m1 "^model:" "$file" | sed 's/^model: *//' | head -1)

  if [ -z "$name" ] || [ -z "$model" ]; then
    echo "⚠️  SKIP $file (missing name/model)"
    continue
  fi

  echo "── $name (model=$model) → $file"

  if [ "$APPLY" = "0" ]; then
    echo "   [dry-run] would inject Token tracking section"
    continue
  fi

  SNIPPET=$(cat <<EOF

## Token tracking ( B1)

Emit \`actual_token_cost\` w activity-log entry post-execution (skill: \`token-budget-tracking\`):

\`\`\`bash
# Po wykonaniu task — proxy estimation:
INPUT_PROXY=\$((\$(wc -c <<< "\$INPUT_CONTEXT") / 3))   # 3 chars/token dla PL
OUTPUT_PROXY=\$((\$(wc -c <<< "\$OUTPUT_TEXT") / 3))
TOTAL=\$((INPUT_PROXY + OUTPUT_PROXY))

echo "{\"ts\":\"\$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"actor\":\"$name\",\"action\":\"<action>\",\"artifact\":\"<path>\",\"status\":\"ok\",\"actual_token_cost\":{\"input\":\$INPUT_PROXY,\"output\":\$OUTPUT_PROXY,\"total\":\$TOTAL,\"model\":\"$model\",\"estimation_method\":\"proxy\"}}" >> knowledge-base/activity-log.jsonl
\`\`\`

**Apply silently** w workflow ostatni krok (po main artifact saved). Konsumowane przez \`cost-per-agent.py\` ( B2) + \`factory-status.sh\` ( B7).

EOF
)

  # Insert before "# Czego agent NIE robi" lub "## Czego" lub na koniec
  if grep -q "^# Czego" "$file"; then
    INSERT_LINE=$(grep -n "^# Czego" "$file" | head -1 | cut -d: -f1)
  elif grep -q "^## Czego" "$file"; then
    INSERT_LINE=$(grep -n "^## Czego" "$file" | head -1 | cut -d: -f1)
  else
    INSERT_LINE=$(wc -l < "$file")
    INSERT_LINE=$((INSERT_LINE + 1))
  fi

  tmpfile=$(mktemp)
  awk -v ln="$INSERT_LINE" -v snippet="$SNIPPET" '
    NR==ln { print snippet; print; next }
    { print }
  ' "$file" > "$tmpfile"

  mv "$tmpfile" "$file"

  if grep -q "Token tracking" "$file"; then
    echo "   ✓ PATCHED"
    PATCHED=$((PATCHED+1))
  else
    echo "   ✗ FAIL"
    FAIL=$((FAIL+1))
  fi
done

echo ""
if [ "$APPLY" = "0" ]; then
  echo "DRY-RUN: would patch $TOTAL agents"
else
  echo "APPLIED: $PATCHED / $TOTAL patched, $FAIL failed"
fi
[ "$FAIL" = "0" ]
