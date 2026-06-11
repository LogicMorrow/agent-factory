#!/usr/bin/env bash
# library/scripts/monthly-intelligence-run.sh
#
# Monthly intelligence orchestrator — wywoływany przez cron routine
# `agent-factory-monthly-intelligence` (Claude Code Schedule
# trig_REDACTED) 1-szy month 11:00 CEST.
#
# Sekwencyjny workflow:
#   Step 0 (NEW v2.0): /pull-promoted-lessons --apply  ←  .E14
#     → aggregate lessons z paczek af-pack-* branch learning/*
#     → filter confidence ≥3 + ≥2 paczek cross-paczkowo
#     → emit improvement-proposals/auto-pull-merge-<date>.md (HITL gate)
#
#   Step 1: pattern-detector --since=-30d --all  ←   C1
#     → cross-agent LLM analysis errors-*.md + lessons.jsonl
#     → emit knowledge-base/patterns/<date>-<topic>.md
#
#   Step 2: recommendation-engine --horizon=this-month  ←   C2
#     → proactive "powinieneś zrobić X" recommendations
#     → emit knowledge-base/recommendations/<date>-monthly.md
#
# Origin:
#   .E14 (2026-05-24) — pull-merge step dodany jako Step 0.
#   Pre-: tylko Step 1+2 (pattern-detector + recommendation-engine).
#
# Cold start protection:
#   Step 0 SKIP jeśli brak paczek af-pack-* z learning branches.
#   Step 1 SKIP jeśli <50 lessons cross-agent (fabryka threshold).
#   Step 2 SKIP jeśli <3 active project cards.
#
# Routine prompt w Claude Code Schedule (operator update przez /schedule):
#   "cd ~/agent-factory && bash library/scripts/monthly-intelligence-run.sh --report"
#
# Usage:
#   bash library/scripts/monthly-intelligence-run.sh                  # all 3 steps
#   bash library/scripts/monthly-intelligence-run.sh --dry-run        # preview, no writes
#   bash library/scripts/monthly-intelligence-run.sh --step=0         # only pull-merge
#   bash library/scripts/monthly-intelligence-run.sh --step=1         # only pattern-detector
#   bash library/scripts/monthly-intelligence-run.sh --step=2         # only recommendation-engine
#   bash library/scripts/monthly-intelligence-run.sh --report         # + write summary report

set -uo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# NOTE: set -uo pipefail enforced od początku (zasada quality-checker S18, .E16)

TODAY=$(date -u +%Y-%m-%d)
REPORT_DIR="knowledge-base/intelligence-reports"
REPORT="$REPORT_DIR/$TODAY-monthly.md"
mkdir -p "$REPORT_DIR"

DRY_RUN=0
STEP_FILTER=""
WRITE_REPORT=0

for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=1 ;;
    --report)    WRITE_REPORT=1 ;;
    --step=*)    STEP_FILTER="${arg#--step=}" ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

log { printf '[monthly-intelligence] %s\n' "$*" >&2; }

# ──────────────────────────────────────────────────────────────────────
# Helper: should run step?
# ──────────────────────────────────────────────────────────────────────
should_run {
  [ -z "$STEP_FILTER" ] && return 0
  [ "$STEP_FILTER" = "$1" ] && return 0
  return 1
}

# ──────────────────────────────────────────────────────────────────────
# Step 0: pull-promoted-lessons (.E14)
# ──────────────────────────────────────────────────────────────────────
run_step_0 {
  log ""
  log "=== Step 0: /pull-promoted-lessons (federacja lessons z paczek af-pack-*) ==="

  # Check: są jakieś paczki af-pack-* z learning branches?
  if ! command -v gh >/dev/null 2>&1; then
    log "  SKIP: gh CLI not available — routine wymaga gh auth (web-setup)"
    return 0
  fi

  if ! gh auth status >/dev/null 2>&1; then
    log "  SKIP: gh CLI not authenticated — run /web-setup pierwszy raz"
    return 0
  fi

  PACZKI_COUNT=$(gh repo list LogicMorrow --limit 100 --json name 2>/dev/null | jq -r '.[].name' | grep -c "^af-pack-" || echo 0)
  if [ "$PACZKI_COUNT" = "0" ]; then
    log "  SKIP: no af-pack-* repos found"
    return 0
  fi

  log "  Found $PACZKI_COUNT paczki — invoking /pull-promoted-lessons"

  if [ "$DRY_RUN" = "1" ]; then
    log "  DRY: would call /pull-promoted-lessons --apply --since=-30d"
    return 0
  fi

  # Note: /pull-promoted-lessons jest slash command requiring main Claude session
  # W cron mode: emit message do routine output żeby Claude wykonał manualnie
  # Alternative: extract bash logic z command markdown → standalone script (backlog)
  cat <<MSG
ACTION REQUIRED: monthly-intelligence Step 0 requires Claude session.

Run in interactive Claude session:
  /pull-promoted-lessons --apply --since=$(date -d '30 days ago' +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d)

Output: knowledge-base/improvement-proposals/auto-pull-merge-${TODAY}.md
Then HITL review przez operatora (MERGE / DEFER / REJECT per cluster).
MSG
  log "  Step 0: emitted ACTION REQUIRED message (Claude session needed)"
}

# ──────────────────────────────────────────────────────────────────────
# Step 1: pattern-detector ( C1)
# ──────────────────────────────────────────────────────────────────────
run_step_1 {
  log ""
  log "=== Step 1: pattern-detector --since=-30d --all ==="

  # Cold start protection
  LESSONS_COUNT=$(wc -l < knowledge-base/lessons.jsonl 2>/dev/null || echo 0)
  if [ "$LESSONS_COUNT" -lt 50 ]; then
    log "  SKIP: <50 lessons (cold start protection — fabryka threshold)"
    return 0
  fi

  if [ "$DRY_RUN" = "1" ]; then
    log "  DRY: would call pattern-detector"
    return 0
  fi

  cat <<MSG
ACTION REQUIRED: monthly-intelligence Step 1 requires Claude session.

Run in interactive Claude session:
  /pattern-detector --since=$(date -d '30 days ago' +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d) --all

Output: knowledge-base/patterns/${TODAY}-<topic>.md (per detected pattern)
MSG
  log "  Step 1: emitted ACTION REQUIRED message"
}

# ──────────────────────────────────────────────────────────────────────
# Step 2: recommendation-engine ( C2)
# ──────────────────────────────────────────────────────────────────────
run_step_2 {
  log ""
  log "=== Step 2: recommendation-engine --horizon=this-month ==="

  # Cold start protection
  PROJECT_COUNT=$(find knowledge-base/projects -maxdepth 1 -name "*.md" -type f ! -name "_template.md" 2>/dev/null | wc -l)
  if [ "$PROJECT_COUNT" -lt 3 ]; then
    log "  SKIP: <3 active project cards (cold start protection)"
    return 0
  fi

  if [ "$DRY_RUN" = "1" ]; then
    log "  DRY: would call recommendation-engine"
    return 0
  fi

  cat <<MSG
ACTION REQUIRED: monthly-intelligence Step 2 requires Claude session.

Run in interactive Claude session:
  /recommend --horizon=this-month

Output: knowledge-base/recommendations/${TODAY}-monthly.md
MSG
  log "  Step 2: emitted ACTION REQUIRED message"
}

# ──────────────────────────────────────────────────────────────────────
# Write summary report (--report flag)
# ──────────────────────────────────────────────────────────────────────
write_report {
  cat > "$REPORT" <<EOF
# Monthly Intelligence Report — $TODAY

**Generated:** $(date -u +%Y-%m-%dT%H:%M:%SZ)
**Routine:** \`agent-factory-monthly-intelligence\` (Claude Code Schedule)
**Script:** \`library/scripts/monthly-intelligence-run.sh\`

## Steps executed

- **Step 0** /pull-promoted-lessons — federacja z paczek af-pack-* (.E14, NEW v2.0)
- **Step 1** pattern-detector — cross-agent LLM analysis ( C1)
- **Step 2** recommendation-engine — proactive recommendations ( C2)

## Cold start status

- Lessons cross-agent: $(wc -l < knowledge-base/lessons.jsonl 2>/dev/null || echo 0) (threshold ≥50 for Step 1)
- Project cards: $(find knowledge-base/projects -maxdepth 1 -name "*.md" -type f ! -name "_template.md" 2>/dev/null | wc -l) (threshold ≥3 for Step 2)
- Paczki af-pack-*: $(gh repo list LogicMorrow --limit 100 --json name 2>/dev/null | jq -r '.[].name' | grep -c "^af-pack-" || echo 0) (threshold ≥1 for Step 0)

## HITL action items (po cron)

1. Review \`knowledge-base/improvement-proposals/auto-pull-merge-${TODAY}.md\` (Step 0 — federation lessons)
2. Review \`knowledge-base/patterns/${TODAY}-*.md\` (Step 1 — emerging patterns)
3. Review \`knowledge-base/recommendations/${TODAY}-monthly.md\` (Step 2 — proactive actions)

## Activity-log

$(echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"actor\":\"monthly-intelligence-run.sh\",\"action\":\"cron_executed\",\"artifact\":\"$REPORT\",\"notes\":\"steps=$([ -z "$STEP_FILTER" ] && echo all || echo $STEP_FILTER) dry_run=$DRY_RUN\"}" | tee -a knowledge-base/activity-log.jsonl)

EOF
  log ""
  log "Report written: $REPORT"
}

# ──────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────
log "=== Monthly intelligence run ($TODAY) ==="
log "Filter: ${STEP_FILTER:-all steps}"
log "Mode: $([ "$DRY_RUN" = "1" ] && echo DRY-RUN || echo LIVE)"

if should_run "0"; then run_step_0; fi
if should_run "1"; then run_step_1; fi
if should_run "2"; then run_step_2; fi

if [ "$WRITE_REPORT" = "1" ]; then
  write_report
fi

log ""
log "=== Monthly intelligence DONE ==="

exit 0
