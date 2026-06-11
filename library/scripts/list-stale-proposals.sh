#!/usr/bin/env bash
# library/scripts/list-stale-proposals.sh
#
# Wylistuj stale improvement-proposals (>14d open, brak action).
# Origin:  pkt B4 (2026-05-13) — fallback dla GH Issues queue
# (queue defer do  — wymaga PAT Account-level Administration escalation).
#
# Usage:
#   bash library/scripts/list-stale-proposals.sh                 # console output
#   bash library/scripts/list-stale-proposals.sh --notify        # + desktop notify-send
#   bash library/scripts/list-stale-proposals.sh --since=30      # custom threshold (days)
#
# Stale = file mtime > N days AND filename nie zaczyna się od accepted-/rejected-/implemented-.

set -uo pipefail

DAYS="${DAYS:-14}"
NOTIFY=0

for arg in "$@"; do
  case "$arg" in
    --since=*) DAYS="${arg#--since=}" ;;
    --notify) NOTIFY=1 ;;
  esac
done

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
PROPOSALS_DIR="knowledge-base/improvement-proposals"

if [ ! -d "$PROPOSALS_DIR" ]; then
  echo "❌ Folder $PROPOSALS_DIR nie istnieje"
  exit 1
fi

# Find stale (>N days, NOT prefixed accepted-/rejected-/implemented-)
STALE=$(find "$PROPOSALS_DIR" -maxdepth 1 -name "*.md" -mtime "+${DAYS}" \
  ! -name "accepted-*" ! -name "rejected-*" ! -name "implemented-*" \
  ! -name "_template*" ! -name ".gitkeep" 2>/dev/null | sort)

COUNT=$(echo "$STALE" | grep -c "^" 2>/dev/null || echo "0")
[ -z "$STALE" ] && COUNT=0

if [ "$COUNT" = "0" ]; then
  echo "✅ No stale proposals (>$DAYS days). Wszystko zaadresowane!"
  exit 0
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ⚠️  Stale improvement-proposals (>$DAYS days open)"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Found: $COUNT stale proposal(s)"
echo ""

while IFS= read -r file; do
  [ -z "$file" ] && continue
  age_days=$(( ( $(date +%s) - $(stat -c %Y "$file" 2>/dev/null || date +%s) ) / 86400 ))
  size=$(wc -l < "$file")
  title=$(grep -m1 "^# " "$file" 2>/dev/null | head -c 80 || echo "(no title)")
  echo "  📄 $file"
  echo "     age: ${age_days}d, lines: $size"
  echo "     title: ${title}"
  echo ""
done <<< "$STALE"

echo "═══════════════════════════════════════════════════════════"
echo "  💡 Actions:"
echo "     - Review każdy → rename prefix: accepted-/rejected-/implemented-"
echo "     - Accept → trigger version-bumper z briefem z proposal:"
echo "       /version-bumper --proposal=<path>"
echo "     - Reject → komentarz dlaczego (informuje meta-reviewera)"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [ "$NOTIFY" = "1" ] && command -v notify-send >/dev/null 2>&1; then
  notify-send -u normal "Agent-Factory: stale proposals" \
    "$COUNT proposal(s) >$DAYS days. Run /review-lessons lub edytuj knowledge-base/improvement-proposals/"
fi

# Activity-log entry
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"actor\":\"list-stale-proposals\",\"action\":\"factory_status_run\",\"artifact\":\"$PROPOSALS_DIR/\",\"status\":\"warn\",\"notes\":\"$COUNT stale (>$DAYS d)\"}" >> knowledge-base/activity-log.jsonl 2>/dev/null || true

# Exit code 0 informational, NIE blokuje
exit 0
