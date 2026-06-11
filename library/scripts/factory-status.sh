#!/usr/bin/env bash
# library/scripts/factory-status.sh
#
# Health check fabryki — 10 metryk operationalization.
# Origin:  pkt B5 (2026-05-13).
#
# Wymagania: python3, jq (opcjonalnie)
# Usage: bash library/scripts/factory-status.sh

set -uo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

TODAY=$(date -u +%Y-%m-%d)

cat <<EOF

═══════════════════════════════════════════════════════════
  Agent-Factory Status — $TODAY
═══════════════════════════════════════════════════════════

EOF

# === 1. Library counts ===
AGENTS_TOTAL=$(find library/agents -name "*.md" | wc -l)
SKILLS_TOTAL=$(find library/skills -maxdepth 3 -name "SKILL.md" -o -name "model-routing.md" 2>/dev/null | wc -l)
HOOKS_TOTAL=$(find library/hooks -name "*.sh" ! -name "*.test.sh" 2>/dev/null | wc -l)
LIBRARY_VERSION=$(python3 -c "import json; print(json.load(open('library/library-index.json'))['version'])" 2>/dev/null || echo "unknown")

echo "📦 Library:"
echo "  - Agentów: $AGENTS_TOTAL"
echo "  - Skilli: $SKILLS_TOTAL"
echo "  - Hooks: $HOOKS_TOTAL"
echo "  - Library-index version: $LIBRARY_VERSION"
echo ""

# === 2. Iteration cycle ===
AGENTS_ITERATED=$(python3 -c "
import json
d = json.load(open('library/library-index.json'))
agents = d.get('agents', [])
iterated = [a for a in agents if a.get('version', '1.0').replace('.0','') not in ['1', '1.0', '1.0.0']]
print(len(iterated))
" 2>/dev/null || echo "0")
AGENTS_ITER_PCT=$((100 * AGENTS_ITERATED / AGENTS_TOTAL))

SKILLS_ITERATED=$(python3 -c "
import json
d = json.load(open('library/library-index.json'))
skills = d.get('skills', [])
iterated = [s for s in skills if s.get('version', '1.0').replace('.0','') not in ['1', '1.0', '1.0.0']]
print(len(iterated))
" 2>/dev/null || echo "0")
SKILLS_ITER_PCT=$((100 * SKILLS_ITERATED / SKILLS_TOTAL))

echo "🔄 Iteration cycle (target: ≥50% iterated):"
echo "  - Agentów iterated: $AGENTS_ITERATED/$AGENTS_TOTAL ($AGENTS_ITER_PCT%) — TARGET ≥50%"
echo "  - Skilli iterated: $SKILLS_ITERATED/$SKILLS_TOTAL ($SKILLS_ITER_PCT%) — TARGET ≥50%"
echo ""

# === 3. Cross-agent-learning adoption ===
WITH_BSW=$(find library/agents -name "*.md" -exec grep -l "Before starting work" {} \; | wc -l)
BSW_PCT=$((100 * WITH_BSW / AGENTS_TOTAL))

# === 4. Mistake-recorder usage ===
ERRORS_FILES=$(find . -maxdepth 4 -name "errors-*.md" 2>/dev/null | wc -l)

# === 5. Lessons taxonomy ===
LESSONS_TOTAL=$(wc -l < knowledge-base/lessons.jsonl 2>/dev/null || echo "0")
LESSONS_UNKNOWN_CAT=$(python3 -c "
import json
unknown = 0
total = 0
try:
    for line in open('knowledge-base/lessons.jsonl'):
        line = line.strip
        if not line: continue
        total += 1
        l = json.loads(line)
        if l.get('category', 'unknown') == 'unknown' or 'category' not in l:
            unknown += 1
    print(unknown if total > 0 else 0)
except: print('0')
" 2>/dev/null || echo "0")
LESSONS_UNKNOWN_PCT=$([ "$LESSONS_TOTAL" -gt 0 ] && echo $((100 * LESSONS_UNKNOWN_CAT / LESSONS_TOTAL)) || echo "0")

echo "🧠 Learning loop:"
echo "  - Cross-agent-learning adoption: $WITH_BSW/$AGENTS_TOTAL ($BSW_PCT%) — TARGET 100%"
echo "  - Mistake-recorder usage (errors-*.md): $ERRORS_FILES files — TARGET ≥10"
echo "  - Lessons total: $LESSONS_TOTAL"
echo "  - Lessons taxonomy unknown category: $LESSONS_UNKNOWN_CAT/$LESSONS_TOTAL ($LESSONS_UNKNOWN_PCT%) — TARGET ≤5%"
echo ""

# === 6. Real piloty ===
REAL_TEST_FILES=$(find packages -maxdepth 3 -name ".real-test-status.json" 2>/dev/null | wc -l)
echo "🎯 Real piloty (target: ≥30% agentów testowanych):"
echo "  - Paczki z .real-test-status.json: $REAL_TEST_FILES"
echo ""

# === 7. Improvement-proposals queue ===
PROPOSALS_OPEN=$(ls knowledge-base/improvement-proposals/*.md 2>/dev/null | wc -l)
PROPOSALS_STALE=$(find knowledge-base/improvement-proposals/ -name "*.md" -mtime +14 2>/dev/null | wc -l)

echo "📋 Improvement-proposals queue:"
echo "  - Open w folderze: $PROPOSALS_OPEN"
echo "  - Stale (>14d): $PROPOSALS_STALE"
echo ""

# === 8. Releases ===
PACKAGES=$(find packages -maxdepth 1 -type d ! -path packages | wc -l)
echo "🚀 Releases:"
echo "  - Paczki af-pack: $PACKAGES"
echo "  - Główne repo: $(git log --oneline -1 2>/dev/null | head -c 60)..."
echo ""

# === 9. Activity-log health ===
ACTIVITY_TOTAL=$(wc -l < knowledge-base/activity-log.jsonl 2>/dev/null || echo "0")
ACTIVITY_RECENT=$(python3 -c "
import json
from datetime import datetime, timedelta, timezone
recent = 0
cutoff = datetime.now(timezone.utc) - timedelta(days=7)
try:
    for line in open('knowledge-base/activity-log.jsonl'):
        line = line.strip
        if not line: continue
        e = json.loads(line)
        ts = e.get('ts', '')
        if 'T' in ts:
            try:
                dt = datetime.fromisoformat(ts.replace('Z', '+00:00'))
                if dt >= cutoff: recent += 1
            except: pass
    print(recent)
except: print('0')
" 2>/dev/null || echo "0")

echo "📊 Activity-log:"
echo "  - Total wpisów: $ACTIVITY_TOTAL"
echo "  - Last 7d: $ACTIVITY_RECENT"
echo ""

# === Token economy ( B7) ===
ENTRIES_WITH_COST=$(python3 -c "
import json
count = 0
for line in open('knowledge-base/activity-log.jsonl'):
    try:
        e = json.loads(line)
        if 'actual_token_cost' in e:
            count += 1
    except: pass
print(count)
" 2>/dev/null || echo "0")
TOKEN_ADOPTION_PCT=$([ "$ACTIVITY_TOTAL" -gt 0 ] && echo $((100 * ENTRIES_WITH_COST / ACTIVITY_TOTAL)) || echo "0")

echo "💰 Token economy :"
echo "  - Entries z actual_token_cost: $ENTRIES_WITH_COST / $ACTIVITY_TOTAL ($TOKEN_ADOPTION_PCT%)"
echo "  - TARGET ≥ 80% — apply token-budget-tracking skill do wszystkich agents"
if [ "$TOKEN_ADOPTION_PCT" -lt 80 ] && [ "$ACTIVITY_TOTAL" -gt 20 ]; then
  echo "  - ⚠️  Adoption < 80% — meta-agenty NIE emit actual_token_cost"
fi
echo ""

# === 10. DoD  ===
echo "✅ DoD  (operationalize learning loop):"
PASS=0
TOTAL_DOD=14

# A1: pack-agent gate
if grep -q "real-test-status.json" .claude/agents/pack-agent.md 2>/dev/null; then
  echo "  ✓ A1: pack-agent real-test gate"
  PASS=$((PASS+1))
else
  echo "  ✗ A1: pack-agent gate (missing)"
fi
# A2: hook + mistake-recorder v1.0.2
if [ -f library/hooks/post-iteration-error-detect.sh ]; then
  echo "  ✓ A2: post-iteration-error-detect hook"
  PASS=$((PASS+1))
else
  echo "  ✗ A2: hook missing"
fi
# A3: lessons schema
if [ -f knowledge-base/lessons-schema.json ] && [ -f library/hooks/validate-lesson-schema.sh ]; then
  echo "  ✓ A3: lessons-schema + validate hook"
  PASS=$((PASS+1))
else
  echo "  ✗ A3: schema/hook missing"
fi
# A4: cron docs + pre-commit symlink
if [ -f .claude/automation/review-lessons-schedule.md ]; then
  echo "  ✓ A4: cron docs"
  PASS=$((PASS+1))
fi
# A5: 100% cross-learn adoption
if [ "$WITH_BSW" = "$AGENTS_TOTAL" ]; then
  echo "  ✓ A5: cross-agent-learning 100% ($WITH_BSW/$AGENTS_TOTAL)"
  PASS=$((PASS+1))
else
  echo "  ⚠️  A5: $WITH_BSW/$AGENTS_TOTAL (target 100%)"
fi
# B1: version-bumper
if [ -f .claude/agents/version-bumper.md ]; then
  echo "  ✓ B1: version-bumper agent"
  PASS=$((PASS+1))
else
  echo "  ⏳ B1: version-bumper pending"
fi
# B2: pilot-orchestrator
if [ -f library/agents/universal/pilot-orchestrator.md ]; then
  echo "  ✓ B2: pilot-orchestrator"
  PASS=$((PASS+1))
else
  echo "  ⏳ B2: pilot-orchestrator pending"
fi
# B3: activity-log v2
if grep -q "version_proposals_generated\|pilot_started" knowledge-base/activity-log.README.md 2>/dev/null; then
  echo "  ✓ B3: activity-log v2 schema"
  PASS=$((PASS+1))
fi
# B5: /factory-status (ten plik)
if [ -f .claude/commands/factory-status.md ]; then
  echo "  ✓ B5: /factory-status slash"
  PASS=$((PASS+1))
fi

echo ""
echo "  Total spełnione: $PASS / $TOTAL_DOD"

# Activity-log entry
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"actor\":\"factory-status\",\"action\":\"factory_status_run\",\"artifact\":\"stdout\",\"status\":\"ok\",\"notes\":\"DoD=$PASS/$TOTAL_DOD, iter=$AGENTS_ITERATED/$AGENTS_TOTAL, cross-learn=$WITH_BSW/$AGENTS_TOTAL\"}" >> knowledge-base/activity-log.jsonl

echo ""
echo "═══════════════════════════════════════════════════════════"
