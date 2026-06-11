#!/usr/bin/env bash
# library/embedded-factory/hooks/session-start-embedded.test.sh
# Test suite dla session-start-embedded.sh

set -u

HOOK="$(dirname "$0")/session-start-embedded.sh"
PASSED=0
FAILED=0
FAILED_NAMES=

run_hook {
  local tmpdir="$1"
  echo "{\"cwd\":\"$tmpdir\"}" | bash "$HOOK" 2>/dev/null
}

assert_contains {
  local name="$1"
  local output="$2"
  local pattern="$3"
  if echo "$output" | grep -q "$pattern"; then
    PASSED=$((PASSED + 1))
    printf '  [PASS] %s\n' "$name"
  else
    FAILED=$((FAILED + 1))
    FAILED_NAMES+=("$name")
    printf '  [FAIL] %s — expected pattern: %s\n' "$name" "$pattern"
  fi
}

assert_empty {
  local name="$1"
  local output="$2"
  if [ -z "$output" ]; then
    PASSED=$((PASSED + 1))
    printf '  [PASS] %s (empty output)\n' "$name"
  else
    FAILED=$((FAILED + 1))
    FAILED_NAMES+=("$name")
    printf '  [FAIL] %s — expected empty, got %s chars\n' "$name" "${#output}"
  fi
}

echo "=== session-start-embedded.sh test suite ==="
echo ""
echo "--- Test 1: empty project ---"
TMPDIR=$(mktemp -d)
OUTPUT=$(run_hook "$TMPDIR")
assert_empty "Empty project → silent exit" "$OUTPUT"
rm -rf "$TMPDIR"

echo ""
echo "--- Test 2: knowledge-base dir but no files ---"
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.claude/knowledge-base"
OUTPUT=$(run_hook "$TMPDIR")
assert_empty "Empty KB dir → silent exit" "$OUTPUT"
rm -rf "$TMPDIR"

echo ""
echo "--- Test 3: full data context ---"
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.claude/knowledge-base/reflections" "$TMPDIR/.claude/knowledge-base/errors"
echo '{"id":1,"date":"2026-05-24","project":"af-pack-<nazwa>","category":"agent-design","severity":"MED","title":"Test lesson","lesson":"Test content"}' > "$TMPDIR/.claude/knowledge-base/lessons.jsonl"
echo '{"id":2,"date":"2026-05-24","project":"af-pack-<nazwa>","category":"tooling","severity":"HIGH","title":"Tool fail","lesson":"Bug"}' >> "$TMPDIR/.claude/knowledge-base/lessons.jsonl"
echo '{"ts":"2026-05-24T12:00:00Z","actor":"test","action":"smoke_test","artifact":"x"}' > "$TMPDIR/.claude/knowledge-base/activity-log.jsonl"
echo '{"schema_version":1,"ts":"2026-05-24T12:00:00Z","origin":"conversation-learning-hook","pattern":"correction","user_prompt_snippet":"test","candidate_lesson":"Test candidate","severity":"high","hitl_approved":null}' > "$TMPDIR/.claude/knowledge-base/candidate-lessons.jsonl"
cat > "$TMPDIR/.claude/knowledge-base/reflections/2026-05-24-test.md" <<'EOF'
---
date: 2026-05-24
---

# Test reflection

Sample reflection content for hook testing.
EOF
cat > "$TMPDIR/.claude/knowledge-base/errors/errors-test-agent.md" <<'EOF'
# Errors for test-agent

## 2026-05-24 — First error
- Severity: HIGH

## 2026-05-24 — Second error
- Severity: MED
EOF

OUTPUT=$(run_hook "$TMPDIR")
assert_contains "Header with date" "$OUTPUT" "Embedded-factory context"
assert_contains "Lessons section (2 total)" "$OUTPUT" "Local lessons (2 total"
assert_contains "Lesson title rendered" "$OUTPUT" "Test lesson"
assert_contains "Lesson severity HIGH" "$OUTPUT" "\[HIGH\]"
assert_contains "Reflections section" "$OUTPUT" "Recent reflections (1 total"
assert_contains "Reflection filename" "$OUTPUT" "2026-05-24-test.md"
assert_contains "Errors section" "$OUTPUT" "Per-agent error logs"
assert_contains "Errors agent name" "$OUTPUT" "test-agent"
assert_contains "Activity section" "$OUTPUT" "Recent activity"
assert_contains "Activity actor" "$OUTPUT" "smoke_test"
assert_contains "Pending HITL count" "$OUTPUT" "Pending HITL candidates: 1"
assert_contains "Footer apply silently" "$OUTPUT" "apply silently"

if [ -f "$TMPDIR/.claude/knowledge-base/.session-candidate-count" ]; then
  COUNTER=$(cat "$TMPDIR/.claude/knowledge-base/.session-candidate-count")
  if [ "$COUNTER" = "0" ]; then
    PASSED=$((PASSED + 1))
    printf '  [PASS] Frequency counter reset to 0\n'
  else
    FAILED=$((FAILED + 1))
    FAILED_NAMES+=("Counter reset")
    printf '  [FAIL] Counter = %s (expected 0)\n' "$COUNTER"
  fi
else
  FAILED=$((FAILED + 1))
  FAILED_NAMES+=("Counter file not created")
  printf '  [FAIL] Counter file not created\n'
fi
rm -rf "$TMPDIR"

echo ""
echo "--- Test 4: partial data (only lessons) ---"
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.claude/knowledge-base"
echo '{"id":1,"date":"2026-05-24","project":"test","category":"agent-design","severity":"LOW","title":"Solo lesson","lesson":"X"}' > "$TMPDIR/.claude/knowledge-base/lessons.jsonl"
OUTPUT=$(run_hook "$TMPDIR")
assert_contains "Partial: lessons rendered" "$OUTPUT" "Local lessons (1 total"
if echo "$OUTPUT" | grep -q "Recent reflections"; then
  FAILED=$((FAILED + 1))
  FAILED_NAMES+=("Partial: reflections skip")
  printf '  [FAIL] Partial: reflections section rendered (expected skipped)\n'
else
  PASSED=$((PASSED + 1))
  printf '  [PASS] Partial: reflections correctly skipped\n'
fi
rm -rf "$TMPDIR"

echo ""
echo "--- Test 5: only pending candidates ---"
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.claude/knowledge-base"
echo '{"schema_version":1,"ts":"2026-05-24T12:00:00Z","origin":"conversation-learning-hook","pattern":"correction","user_prompt_snippet":"test","candidate_lesson":"Test","severity":"high","hitl_approved":null}' > "$TMPDIR/.claude/knowledge-base/candidate-lessons.jsonl"
echo '{"schema_version":1,"ts":"2026-05-23T12:00:00Z","origin":"conversation-learning-hook","pattern":"correction","user_prompt_snippet":"old","candidate_lesson":"Old","severity":"high","hitl_approved":true}' >> "$TMPDIR/.claude/knowledge-base/candidate-lessons.jsonl"
OUTPUT=$(run_hook "$TMPDIR")
assert_contains "Only candidates: pending=1 (filter approved)" "$OUTPUT" "Pending HITL candidates: 1"
rm -rf "$TMPDIR"

echo ""
echo "--- Test 6: env fallback (no cwd in stdin) ---"
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.claude/knowledge-base"
echo '{"id":1,"date":"2026-05-24","project":"env-test","category":"meta","severity":"LOW","title":"Env fallback","lesson":"X"}' > "$TMPDIR/.claude/knowledge-base/lessons.jsonl"
OUTPUT=$(CLAUDE_PROJECT_DIR="$TMPDIR" bash "$HOOK" <<< '{}' 2>/dev/null)
assert_contains "Env fallback: lessons rendered" "$OUTPUT" "Env fallback"
rm -rf "$TMPDIR"

echo ""
echo "--- Test 7: performance smoke (<500ms wall-clock) ---"
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.claude/knowledge-base/reflections"
for i in 1 2 3 4 5 6 7 8 9 10; do
  echo "{\"id\":$i,\"date\":\"2026-05-24\",\"project\":\"perf\",\"category\":\"x\",\"severity\":\"LOW\",\"title\":\"Lesson $i\",\"lesson\":\"perf test\"}" >> "$TMPDIR/.claude/knowledge-base/lessons.jsonl"
done
START=$(date +%s%N)
run_hook "$TMPDIR" >/dev/null
END=$(date +%s%N)
ELAPSED_MS=$(( (END - START) / 1000000 ))
if [ "$ELAPSED_MS" -lt 500 ]; then
  PASSED=$((PASSED + 1))
  printf '  [PASS] Performance: %sms (target <500ms)\n' "$ELAPSED_MS"
else
  FAILED=$((FAILED + 1))
  FAILED_NAMES+=("Performance smoke")
  printf '  [FAIL] Performance: %sms exceeds 500ms\n' "$ELAPSED_MS"
fi
rm -rf "$TMPDIR"

echo ""
echo "=== Summary ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
if [ "$FAILED" -gt 0 ]; then
  echo "Failed cases:"
  for n in "${FAILED_NAMES[@]}"; do echo "  - $n"; done
  exit 1
fi
echo "All tests PASS ✓"
exit 0
