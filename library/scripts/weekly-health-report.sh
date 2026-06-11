#!/usr/bin/env bash
# library/scripts/weekly-health-report.sh
#
# Tygodniowy health report fabryki — agreguje factory-status + lista
# stale proposals + cross-propagation suggestions + top 3 stale agents.
# Generuje markdown report w knowledge-base/health-reports/.
#
# Origin:  pkt C5 (2026-05-13).
#
# Usage:
#   bash library/scripts/weekly-health-report.sh                    # generate report
#   bash library/scripts/weekly-health-report.sh --console          # only console
#   bash library/scripts/weekly-health-report.sh --notify           # + notify-send
#
# Cron setup:
#   0 9 * * 1 cd ~/agent-factory && bash library/scripts/weekly-health-report.sh --notify

set -uo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

TODAY=$(date -u +%Y-%m-%d)
REPORT_DIR="knowledge-base/health-reports"
REPORT="$REPORT_DIR/$TODAY-weekly.md"
mkdir -p "$REPORT_DIR"

CONSOLE_ONLY=0
NOTIFY=0
for arg in "$@"; do
  case "$arg" in
    --console) CONSOLE_ONLY=1 ;;
    --notify) NOTIFY=1 ;;
  esac
done

# === Generuj report ===
{
  echo "# Agent-Factory weekly health report — $TODAY"
  echo ""
  echo "**Generated:** $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "**Next report:** $(date -u -d '+7 days' +%Y-%m-%d 2>/dev/null || date -u -v +7d +%Y-%m-%d)"
  echo ""

  echo "## 1. Factory health snapshot"
  echo ""
  echo '```'
  bash library/scripts/factory-status.sh 2>&1 | tail -n +3
  echo '```'
  echo ""

  echo "## 2. Top 3 stale agents (>30d bez patcha, ≥2 lessons HIGH/MED)"
  echo ""
  python3 <<'PYEOF'
import json
import os
from datetime import datetime, timezone, timedelta
import subprocess

# Read library-index
try:
    d = json.load(open('library/library-index.json'))
    agents = d.get('agents', [])
except:
    agents = []

# Read lessons
lessons = []
for line in open('knowledge-base/lessons.jsonl'):
    line = line.strip
    if not line: continue
    try:
        lessons.append(json.loads(line))
    except: pass

# Filter HIGH+MED last 60d
cutoff = datetime.now(timezone.utc) - timedelta(days=60)
recent = [l for l in lessons if l.get('severity') in ['HIGH', 'MED']
          and 'T' in l.get('ts', '')]

scored = []
for agent in agents:
    name = agent.get('name', '')
    # Score = lessons match (tier1 body match)
    matches = []
    for l in recent:
        body = (l.get('title','') + ' ' + l.get('lesson','')).lower
        if name in body:
            matches.append(l)

    # Days since last commit on agent file
    path_candidates = [
        f"library/agents/universal/{name}.md",
        f"library/agents/webapp/{name}.md",
        f"library/agents/example-pack/{name}.md",
        f"library/agents/automation/{name}.md",
        f"library/agents/ai-agents/{name}.md",
        f".claude/agents/{name}.md",
    ]
    file = next((p for p in path_candidates if os.path.exists(p)), None)
    if not file:
        continue
    try:
        rc = subprocess.run(['git', 'log', '-1', '--format=%ct', file],
                            capture_output=True, text=True, timeout=10)
        if rc.returncode == 0 and rc.stdout.strip:
            last_commit_ts = int(rc.stdout.strip)
            days_since = (datetime.now(timezone.utc).timestamp - last_commit_ts) / 86400
        else:
            days_since = 999
    except:
        days_since = 999

    if days_since >= 30 and len(matches) >= 1:
        scored.append({'name': name, 'days': int(days_since),
                       'lessons_count': len(matches),
                       'version': agent.get('version', '?')})

scored.sort(key=lambda x: (-x['lessons_count'], -x['days']))

if scored[:3]:
    print("| Agent | Version | Days since last patch | Lessons HIGH/MED match | Status |")
    print("|---|---|---|---|---|")
    for a in scored[:3]:
        status = "🔴 CRITICAL" if a['lessons_count'] >= 2 else "🟡 STALE"
        print(f"| `{a['name']}` | v{a['version']} | {a['days']}d | {a['lessons_count']} | {status} |")
else:
    print("No stale agents detected. 🎉")

PYEOF

  echo ""
  echo "## 3. Stale improvement-proposals (>14d open)"
  echo ""
  echo '```'
  bash library/scripts/list-stale-proposals.sh --since=14 2>&1 | tail -n +4 | head -30
  echo '```'
  echo ""

  echo "## 4. Recommended actions (this week)"
  echo ""
  echo "Patrz section 1 (DoD score) + section 2 (top stale) + section 3 (proposals)."
  echo ""
  echo "### Suggested workflow"
  echo "1. **Approve top 3 stale agents** → spawn \`/version-bumper --agent=<name>\` per agent"
  echo "2. **Triage stale proposals** → review każdy, rename accepted-/rejected-/implemented-"
  echo "3. **Run \`/self-pilot --weekly\`** → full weekly cycle (jeśli nie ma cron)"
  echo "4. **Run \`/factory-status\`** po wdrożeniu → sprawdź czy DoD score idzie up"
  echo ""

  echo "## 5. Token economy (last 7d) —  B6"
  echo ""
  echo '```'
  python3 library/scripts/cost-per-agent.py --since=-7d --top=10 --include-no-cost 2>&1 | tail -n +2
  echo '```'
  echo ""

  echo "## 6. Activity-log highlights (last 7d)"
  echo ""
  echo '```'
  python3 <<'PYEOF'
import json
from datetime import datetime, timezone, timedelta

cutoff = datetime.now(timezone.utc) - timedelta(days=7)
recent = []
try:
    for line in open('knowledge-base/activity-log.jsonl'):
        line = line.strip
        if not line: continue
        e = json.loads(line)
        ts = e.get('ts', '')
        if 'T' in ts:
            try:
                dt = datetime.fromisoformat(ts.replace('Z', '+00:00'))
                if dt >= cutoff:
                    recent.append(e)
            except: pass
except: pass

print(f"Total wpisów last 7d: {len(recent)}")
print

# Group by action
actions = {}
for e in recent:
    a = e.get('action', 'unknown')
    actions[a] = actions.get(a, 0) + 1

for k, v in sorted(actions.items, key=lambda x: -x[1])[:10]:
    print(f"  {v:3d}  {k}")
PYEOF
  echo '```'
  echo ""

  echo "---"
  echo ""
  echo "**Auto-generated by:** \`library/scripts/weekly-health-report.sh\` v1.0.0"
  echo "**Plan:** knowledge-base/plans/2026-05-13--operationalize-learning-loop.md (C5)"

} > "$REPORT" 2>&1

if [ "$CONSOLE_ONLY" = "1" ]; then
  cat "$REPORT"
  rm -f "$REPORT"
else
  echo "✅ Weekly health report: $REPORT"
  head -20 "$REPORT"
  echo "..."
fi

# Activity-log
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"actor\":\"weekly-health-report\",\"action\":\"factory_status_run\",\"artifact\":\"$REPORT\",\"status\":\"ok\"}" >> knowledge-base/activity-log.jsonl

if [ "$NOTIFY" = "1" ] && command -v notify-send >/dev/null 2>&1; then
  notify-send "Agent-Factory weekly health" "$REPORT"
fi

exit 0
