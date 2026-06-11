#!/usr/bin/env bash
# Test suite dla stop-solution-record.sh (Stop hook solution-memory, etap 8).
# Uruchom: bash stop-solution-record.test.sh
set -uo pipefail

HOOK="$(cd "$(dirname "$0")" && pwd)/stop-solution-record.sh"
PASS=0; FAIL=0
ok   { echo "  [PASS] $1"; PASS=$((PASS+1)); }
bad  { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }

mkrepo {
  local d; d=$(mktemp -d)
  mkdir -p "$d/.claude/knowledge-base"
  git -C "$d" init -q
  git -C "$d" config user.email t@t.pl
  git -C "$d" config user.name t
  git -C "$d" commit -q --allow-empty -m init
  git -C "$d" rev-parse HEAD > "$d/.claude/knowledge-base/.session-head-baseline"
  echo "$d"
}

echo "=== Test 1: poniżej progu (1 plik) → cisza ==="
D=$(mkrepo); echo a > "$D/f1.txt"
OUT=$(echo "{\"cwd\":\"$D\",\"stop_hook_active\":false}" | bash "$HOOK")
[ -z "$OUT" ] && ok "cisza poniżej progu" || bad "powinno być cicho (got: $OUT)"
rm -rf "$D"

echo "=== Test 2: próg ≥3 pliki → decision=block + payload ==="
D=$(mkrepo); echo a > "$D/f1.txt"; echo b > "$D/f2.txt"; echo c > "$D/f3.txt"
OUT=$(echo "{\"cwd\":\"$D\",\"session_id\":\"s1\",\"transcript_path\":\"/tmp/t.jsonl\",\"stop_hook_active\":false}" | bash "$HOOK")
echo "$OUT" | jq -e '.decision=="block"' >/dev/null 2>&1 && ok "decision=block" || bad "brak block"
[ -f "$D/.claude/knowledge-base/.solution-pending.json" ] && ok "payload zapisany" || bad "brak payload"
echo "$OUT" | jq -e '.hookSpecificOutput.additionalContext | test("solution-reflector")' >/dev/null 2>&1 \
  && ok "additionalContext wskazuje reflectora" || bad "brak instrukcji reflectora"
rm -rf "$D"

echo "=== Test 3: ≥1 commit (0 uncommitted) → block ==="
D=$(mkrepo); echo x > "$D/c.txt"; git -C "$D" add -A; git -C "$D" commit -q -m work
OUT=$(echo "{\"cwd\":\"$D\",\"stop_hook_active\":false}" | bash "$HOOK")
echo "$OUT" | jq -e '.decision=="block"' >/dev/null 2>&1 && ok "commit triggers block" || bad "commit nie wyzwolił"
rm -rf "$D"

echo "=== Test 4: idempotencja — ten sam stan → cisza ==="
D=$(mkrepo); echo a > "$D/f1.txt"; echo b > "$D/f2.txt"; echo c > "$D/f3.txt"
echo "{\"cwd\":\"$D\",\"stop_hook_active\":false}" | bash "$HOOK" >/dev/null
OUT=$(echo "{\"cwd\":\"$D\",\"stop_hook_active\":false}" | bash "$HOOK")
[ -z "$OUT" ] && ok "idempotent skip" || bad "powinno skip"
rm -rf "$D"

echo "=== Test 5: stop_hook_active=true → cisza (loop guard) ==="
D=$(mkrepo); echo a > "$D/f1.txt"; echo b > "$D/f2.txt"; echo c > "$D/f3.txt"
OUT=$(echo "{\"cwd\":\"$D\",\"stop_hook_active\":true}" | bash "$HOOK")
[ -z "$OUT" ] && ok "loop guard" || bad "powinno cicho"
rm -rf "$D"

echo "=== Test 6: brak repo git → cisza (C2 fallback) ==="
D=$(mktemp -d); mkdir -p "$D/.claude/knowledge-base"
OUT=$(echo "{\"cwd\":\"$D\",\"stop_hook_active\":false}" | bash "$HOOK")
[ -z "$OUT" ] && ok "brak gita cicho" || bad "powinno cicho"
rm -rf "$D"

echo "=== Test 7: brak .claude/knowledge-base → cisza ==="
D=$(mktemp -d)
OUT=$(echo "{\"cwd\":\"$D\",\"stop_hook_active\":false}" | bash "$HOOK")
[ -z "$OUT" ] && ok "nie-embedded cicho" || bad "powinno cicho"
rm -rf "$D"

echo ""
echo "=== Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
[ "$FAIL" -eq 0 ] && echo "All tests PASS ✓" || { echo "FAILURES"; exit 1; }
