#!/usr/bin/env bash
# library/embedded-factory/hooks/session-start-embedded.sh
#
# SessionStart hook — czyta lokalny `.claude/knowledge-base/` przy starcie
# sesji w projekcie z embedded-factory. Wstrzykuje summary do kontekstu
# main Claude jako system message.
#
# Origin:
#   Nowy artefakt fabryki 2026-05-24 . Fundament samouczenia
#   się projektu — bez tego hooka projekt-konsument paczki nie wie co już
#   się uczył w poprzednich sesjach.
#
# Mechanizm:
#   Czyta JSON ze stdin (Claude Code SessionStart format), wyciąga `cwd`.
#   Per kategoria (lessons/reflections/errors/activity/candidates):
#     - Lessons.jsonl tail 5 — last 5 cross-agent lessons
#     - Reflections last 3 — filename + first paragraph
#     - Errors-*.md list — per-agent error count + last entry
#     - Activity-log.jsonl tail 5 — last actions
#     - Candidate-lessons.jsonl pending count — HITL gate reminder
#   Bufor max 3k znaków (~750 tokens).
#   Pisze na stdout (exit 0) — tekst trafia do kontekstu sesji.
#   Reset `.session-candidate-count` (counter dla Path 1 hook frequency).
#
# Performance: <200ms target. Optymalizacje:
#   - Early exit jeśli brak `.claude/knowledge-base/`
#   - jq z `.[-5:]` (last 5) zamiast pełnego read
#   - Truncation per sekcja (cap chars)
#
# Portable: używa `cwd` z stdin JSON LUB fallback `$CLAUDE_PROJECT_DIR`
# LUB `$(pwd)`. Działa w paczce af-pack-* gdy bundlowany.
#
# Instalacja:
#   1. Skopiuj do `<projekt>/.claude/hooks/session-start-embedded.sh`
#   2. `chmod +x .claude/hooks/session-start-embedded.sh`
#   3. W `.claude/settings.json` dopisz w sekcji "hooks":
#        "SessionStart": [{
#          "matcher": "*",
#          "hooks": [{ "type": "command",
#                      "command": ".claude/hooks/session-start-embedded.sh" }]
#        }]
#
# Exit codes:
#   0 zawsze (informational)

set -uo pipefail

INPUT="$(cat 2>/dev/null || echo '{}')"
CWD="$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || echo "")"
[ -z "$CWD" ] && CWD="${CLAUDE_PROJECT_DIR:-$(pwd)}"

KB_DIR="${CWD}/.claude/knowledge-base"
LESSONS="${KB_DIR}/lessons.jsonl"
ACTIVITY="${KB_DIR}/activity-log.jsonl"
CANDIDATES="${KB_DIR}/candidate-lessons.jsonl"
REFLECTIONS_DIR="${KB_DIR}/reflections"
ERRORS_DIR="${KB_DIR}/errors"
SOLUTIONS_INDEX="${KB_DIR}/solutions-index.jsonl"
SOLUTIONS_DIR="${KB_DIR}/solutions"
COUNTER_FILE="${KB_DIR}/.session-candidate-count"
BASELINE_FILE="${KB_DIR}/.session-head-baseline"

[ ! -d "$KB_DIR" ] && exit 0

echo "0" > "$COUNTER_FILE" 2>/dev/null || true

# Solution-memory: zapisz baseline HEAD sesji (czyta go Stop-hook
# stop-solution-record.sh do liczenia commitów tej sesji). Tylko repo git.
if git -C "$CWD" rev-parse HEAD >/dev/null 2>&1; then
  git -C "$CWD" rev-parse HEAD > "$BASELINE_FILE" 2>/dev/null || true
fi

{
  HAS_ANY_DATA=0

  if [ -f "$LESSONS" ] && [ -s "$LESSONS" ]; then
    LESSONS_COUNT=$(wc -l < "$LESSONS" 2>/dev/null | tr -d ' ')
    if [ "$LESSONS_COUNT" -gt 0 ]; then
      HAS_ANY_DATA=1
      echo "## 📚 Local lessons (${LESSONS_COUNT} total, last 5 shown)"
      echo ""
      tail -5 "$LESSONS" 2>/dev/null | while IFS= read -r line; do
        echo "$line" | jq -r '"- [\(.severity // "?")] \(.category // "?"): \(.title // .lesson[0:80])"' 2>/dev/null || echo "- (parse error: line skipped)"
      done
      echo ""
    fi
  fi

  if [ -d "$REFLECTIONS_DIR" ]; then
    REFL_COUNT=$(find "$REFLECTIONS_DIR" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$REFL_COUNT" -gt 0 ]; then
      HAS_ANY_DATA=1
      echo "## 🪞 Recent reflections (${REFL_COUNT} total, last 3 shown)"
      echo ""
      find "$REFLECTIONS_DIR" -maxdepth 1 -name "*.md" -type f -printf "%f\n" 2>/dev/null | sort -r | head -3 | while IFS= read -r fname; do
        first_line=$(awk '/^---$/{f=!f;next} !f && NF && !/^#/ {print; exit}' "${REFLECTIONS_DIR}/${fname}" 2>/dev/null | head -c 100)
        echo "- \`${fname}\`: ${first_line}..."
      done
      echo ""
    fi
  fi

  if [ -f "$SOLUTIONS_INDEX" ] && [ -s "$SOLUTIONS_INDEX" ]; then
    SOL_COUNT=$(wc -l < "$SOLUTIONS_INDEX" 2>/dev/null | tr -d ' ')
    if [ "$SOL_COUNT" -gt 0 ]; then
      HAS_ANY_DATA=1
      echo "## 🧩 Solution-memory (${SOL_COUNT} total, last 5 — apply silently przy podobnym problemie)"
      echo ""
      # Sub-budżet ~1200 znaków: tail 5, problem truncated, sygnalizuj pełne md
      tail -5 "$SOLUTIONS_INDEX" 2>/dev/null | while IFS= read -r line; do
        echo "$line" | jq -r '"- [\(.scope // "?")] \(.title // .id): \(.problem[0:90] // "")… → `\(.md_path // "")` (dead_ends w pliku)"' 2>/dev/null || echo "- (parse error: line skipped)"
      done
      echo ""
    fi
  fi

  if [ -d "$ERRORS_DIR" ]; then
    ERR_FILES=$(find "$ERRORS_DIR" -maxdepth 1 -name "errors-*.md" -type f 2>/dev/null)
    if [ -n "$ERR_FILES" ]; then
      ERR_COUNT=$(echo "$ERR_FILES" | wc -l | tr -d ' ')
      HAS_ANY_DATA=1
      echo "## ⚠️  Per-agent error logs (${ERR_COUNT} agents have errors)"
      echo ""
      echo "$ERR_FILES" | head -5 | while IFS= read -r f; do
        agent_name=$(basename "$f" .md | sed 's/^errors-//')
        entry_count=$(grep -c "^## " "$f" 2>/dev/null || echo 0)
        echo "- \`${agent_name}\`: ${entry_count} recorded errors"
      done
      echo ""
    fi
  fi

  if [ -f "$ACTIVITY" ] && [ -s "$ACTIVITY" ]; then
    HAS_ANY_DATA=1
    echo "## 📋 Recent activity (last 5 events)"
    echo ""
    tail -5 "$ACTIVITY" 2>/dev/null | while IFS= read -r line; do
      echo "$line" | jq -r '"- \(.ts // "?") [\(.actor // "?")] \(.action // "?")"' 2>/dev/null || echo "- (parse error)"
    done
    echo ""
  fi

  if [ -f "$CANDIDATES" ] && [ -s "$CANDIDATES" ]; then
    PENDING=$(jq -c 'select(.hitl_approved == null)' "$CANDIDATES" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$PENDING" -gt 0 ]; then
      HAS_ANY_DATA=1
      echo "## 🔔 Pending HITL candidates: ${PENDING}"
      echo ""
      echo "Uruchom \`/review-candidate-lessons\` żeby zaakceptować lub odrzucić."
      echo ""
    fi
  fi

  if [ "$HAS_ANY_DATA" = "0" ]; then
    exit 0
  fi

} > /tmp/embedded-context-$$.tmp 2>/dev/null || exit 0

if [ -s /tmp/embedded-context-$$.tmp ]; then
  cat <<HEADER
═══════════════════════════════════════════════════════════
  📦 Embedded-factory context (session start, $(date -u +%Y-%m-%d))
  Project: $(basename "$CWD")
  Source: .claude/knowledge-base/
═══════════════════════════════════════════════════════════

HEADER
  head -c 3000 /tmp/embedded-context-$$.tmp
  echo ""
  echo "─── (apply silently — read this context, use w decyzjach, NIE komentuj) ───"
fi

rm -f /tmp/embedded-context-$$.tmp

exit 0
