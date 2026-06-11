#!/usr/bin/env bash
# library/hooks/userPromptSubmit-conversation-learning.sh
#
# UserPromptSubmit hook — Path 1 production dla conversation-learning skilla.
# Detect 5 patternów feedback (correction/frustration/preference/decision-
# confirmation/surprise) w prompcie usera i append candidate lesson do
# .claude/knowledge-base/candidate-lessons.jsonl (per projekt, NIE centralna
# fabryka). HITL gate przez /review-candidate-lessons przed promotion do
# lessons.jsonl.
#
# Origin:
#   Nowy artefakt fabryki 2026-05-24 . Adresuje deficit:
#   ~500+ chat interactions/sesja → 0 trafia do lessons.jsonl bez Path 1.
#   Hook generuje candidate lessons (multiplikator x2-4 learning velocity).
#
# Mechanizm:
#   Czyta JSON ze stdin (UserPromptSubmit format), wyciąga `prompt`.
#   Early exit dla krótkich/pustych promptów. Frequency + cooldown check
#   przed regex. Bash native regex match 5 patternów (priority HIGH→LOW).
#   Append candidate JSON do .claude/knowledge-base/candidate-lessons.jsonl.
#   Stderr soft-reminder TYLKO dla HIGH (correction/frustration). Exit 0.
#
# Performance: <50ms target p95, <100ms hard limit. Optymalizacje:
#   - Early exit jeśli len(prompt) < 50
#   - Read frequency counter + cooldown BEFORE regex (skip regex jeśli
#     limit/cooldown hit)
#   - Bash native [[ =~ ]] zamiast grep fork
#   - Single-pass regex per pattern
#
# Portable: hook NIE hardcode'uje ścieżek fabryki. Używa $CLAUDE_PROJECT_DIR
# (env var) lub fallback $(pwd). Identyczny w library/hooks/ (fabryka) i
# library/embedded-factory/hooks/ (bundlowany do paczek af-pack-* w Fazie
# 10B.E7).
#
# Instalacja:
#   1. Skopiuj plik do `<projekt>/.claude/hooks/userPromptSubmit-conversation-learning.sh`
#   2. `chmod +x .claude/hooks/userPromptSubmit-conversation-learning.sh`
#   3. W `.claude/settings.json` dopisz:
#        "UserPromptSubmit": [{
#          "matcher": "*",
#          "hooks": [{ "type": "command",
#                      "command": ".claude/hooks/userPromptSubmit-conversation-learning.sh" }]
#        }]
#   4. Mkdir `.claude/knowledge-base/` jeśli nie istnieje
#
# Exit codes:
#   0 zawsze (informational, NIGDY nie blokuje promptu)
#
# Towarzyszące artefakty :
#   library/skills/universal/conversation-learning/SKILL.md (v1.1.0 patch)
#   .claude/commands/review-candidate-lessons.md (HITL gate)
#   knowledge-base/candidate-lessons-schema.json (schema v1.0)

set -uo pipefail

# ──────────────────────────────────────────────────────────────────────
# Setup paths (portable: względem $CLAUDE_PROJECT_DIR lub cwd)
# ──────────────────────────────────────────────────────────────────────
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
KB_DIR="${PROJECT_DIR}/.claude/knowledge-base"
CANDIDATES_FILE="${KB_DIR}/candidate-lessons.jsonl"
COUNTER_FILE="${KB_DIR}/.session-candidate-count"
COOLDOWN_FILE="${KB_DIR}/.pattern-cooldown.json"
PERF_WARN_FILE="${PROJECT_DIR}/.claude/hooks-perf-warn.jsonl"
THROTTLE_FILE="${PROJECT_DIR}/.claude/hooks-throttle.jsonl"

# Ensure knowledge-base dir exists (idempotent)
mkdir -p "$KB_DIR" 2>/dev/null || true

# ──────────────────────────────────────────────────────────────────────
# Constants
# ──────────────────────────────────────────────────────────────────────
MAX_PER_SESSION=5                    # frequency control
COOLDOWN_SECONDS=1800                # 30 min per pattern
PERF_HARD_LIMIT_MS=100               # skip pattern detection if exceeded
MIN_PROMPT_LEN=50                    # early exit threshold

# ──────────────────────────────────────────────────────────────────────
# Performance timing start
# ──────────────────────────────────────────────────────────────────────
START_NS=$(date +%s%N)

# ──────────────────────────────────────────────────────────────────────
# Read stdin JSON, extract prompt
# ──────────────────────────────────────────────────────────────────────
INPUT="$(cat 2>/dev/null || echo '{}')"
PROMPT="$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null || echo "")"

# Early exit: empty or short prompt
[ -z "$PROMPT" ] && exit 0
PROMPT_LEN=${#PROMPT}
[ "$PROMPT_LEN" -lt "$MIN_PROMPT_LEN" ] && exit 0

# ──────────────────────────────────────────────────────────────────────
# Frequency control: read counter, exit if limit hit
# ──────────────────────────────────────────────────────────────────────
SESSION_COUNT=0
if [ -f "$COUNTER_FILE" ]; then
  SESSION_COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
  [[ "$SESSION_COUNT" =~ ^[0-9]+$ ]] || SESSION_COUNT=0
fi

if [ "$SESSION_COUNT" -ge "$MAX_PER_SESSION" ]; then
  THROTTLE_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  echo "{\"ts\":\"${THROTTLE_TS}\",\"reason\":\"max_per_session\",\"count\":${SESSION_COUNT}}" \
    >> "$THROTTLE_FILE" 2>/dev/null || true
  exit 0
fi

# ──────────────────────────────────────────────────────────────────────
# Pattern definitions (priority order: HIGH first)
# Bash native regex [[ =~ ]] for performance (no grep fork)
# ──────────────────────────────────────────────────────────────────────

# correction (HIGH): explicit user correction/override
# Anti-false-positive: "nie" must be word-boundary + context ("nie, ", "nie tak", "to nie")
# shellcheck disable=SC2016
CORRECTION_REGEX='(^|[^a-zA-Z])(nie,|nie tak|to nie|źle,|źle\.|źle$|stop\.|stop,|to niepoprawne|niepoprawn[ey]|to powinno być|powinieneś był|to powinieneś|błąd w twoj|źle to|to nie tak)'

# frustration (HIGH): repeated problem or annoyance
FRUSTRATION_REGEX='(dlaczego.{1,30}(nie działa|jest|jeszcze)|ciągle|znowu|po raz (drugi|trzeci|kolejny|[0-9]+)|już mówiłem|przecież ci mówiłem|ile razy mam|znów to samo)'

# preference (MED): user expresses preference
PREFERENCE_REGEX='(\bwolę\b|\bzawsze\b.{1,30}(rób|pisz|używaj)|bardziej mi pasuje|preferuję|lepiej (gdy|jak|żeby)|wolałbym|chciałbym żeby zawsze|domyślnie (rób|pisz|używaj))'

# decision-confirmation (MED): user confirms a decision/recommendation
DECISION_REGEX='(tak, (dobrze|rób|kontynuuj|super|idealnie|świetnie|pasuje)|świetnie, (rób|kontynuuj|dalej)|idealnie,|super, (rób|kontynuuj|dalej)|OK, (rób|kontynuuj|dalej|kontynuujmy)|dokładnie tak|właśnie tak|rób tak jak rekomendujesz|zatwierdzam|akceptuję)'

# surprise (LOW): user expresses surprise/learning
SURPRISE_REGEX='(\baha\b|ciekawe że|ciekawe, że|hm, to działa|nie wiedziałem|nie miałem pojęcia|interesujące że|nie sądziłem że)'

# ──────────────────────────────────────────────────────────────────────
# Cooldown check per pattern (read .pattern-cooldown.json)
# ──────────────────────────────────────────────────────────────────────
NOW_TS=$(date +%s)

cooldown_ok {
  # $1 = pattern name (correction, frustration, preference, decision-confirmation, surprise)
  local pattern="$1"
  if [ ! -f "$COOLDOWN_FILE" ]; then
    return 0
  fi
  local last_ts
  last_ts=$(jq -r --arg p "$pattern" '.[$p] // 0' "$COOLDOWN_FILE" 2>/dev/null || echo 0)
  [[ "$last_ts" =~ ^[0-9]+$ ]] || last_ts=0
  local delta=$((NOW_TS - last_ts))
  [ "$delta" -ge "$COOLDOWN_SECONDS" ]
}

update_cooldown {
  local pattern="$1"
  if [ ! -f "$COOLDOWN_FILE" ]; then
    echo '{}' > "$COOLDOWN_FILE"
  fi
  local tmp
  tmp=$(mktemp 2>/dev/null) || return 0
  jq --arg p "$pattern" --argjson ts "$NOW_TS" '. + {($p): $ts}' \
    "$COOLDOWN_FILE" > "$tmp" 2>/dev/null && mv "$tmp" "$COOLDOWN_FILE" || rm -f "$tmp"
}

# ──────────────────────────────────────────────────────────────────────
# Match patterns (priority order HIGH→LOW)
# Returns primary pattern + secondary patterns array
# ──────────────────────────────────────────────────────────────────────
MATCHED_PRIMARY=""
MATCHED_SEVERITY=""
SECONDARY_PATTERNS=

# Case-insensitive bash native regex
shopt -s nocasematch

if [[ "$PROMPT" =~ $CORRECTION_REGEX ]] && cooldown_ok "correction"; then
  MATCHED_PRIMARY="correction"
  MATCHED_SEVERITY="high"
elif [[ "$PROMPT" =~ $FRUSTRATION_REGEX ]] && cooldown_ok "frustration"; then
  MATCHED_PRIMARY="frustration"
  MATCHED_SEVERITY="high"
elif [[ "$PROMPT" =~ $PREFERENCE_REGEX ]] && cooldown_ok "preference"; then
  MATCHED_PRIMARY="preference"
  MATCHED_SEVERITY="medium"
elif [[ "$PROMPT" =~ $DECISION_REGEX ]] && cooldown_ok "decision-confirmation"; then
  MATCHED_PRIMARY="decision-confirmation"
  MATCHED_SEVERITY="medium"
elif [[ "$PROMPT" =~ $SURPRISE_REGEX ]] && cooldown_ok "surprise"; then
  MATCHED_PRIMARY="surprise"
  MATCHED_SEVERITY="low"
fi

shopt -u nocasematch

# No match → exit silently
[ -z "$MATCHED_PRIMARY" ] && exit 0

# Detect secondary patterns (NIE same as primary, NIE cooldown-restricted)
shopt -s nocasematch
for sec_pattern in correction frustration preference decision-confirmation surprise; do
  [ "$sec_pattern" = "$MATCHED_PRIMARY" ] && continue
  case "$sec_pattern" in
    correction)            [[ "$PROMPT" =~ $CORRECTION_REGEX ]] && SECONDARY_PATTERNS+=("$sec_pattern") ;;
    frustration)           [[ "$PROMPT" =~ $FRUSTRATION_REGEX ]] && SECONDARY_PATTERNS+=("$sec_pattern") ;;
    preference)            [[ "$PROMPT" =~ $PREFERENCE_REGEX ]] && SECONDARY_PATTERNS+=("$sec_pattern") ;;
    decision-confirmation) [[ "$PROMPT" =~ $DECISION_REGEX ]] && SECONDARY_PATTERNS+=("$sec_pattern") ;;
    surprise)              [[ "$PROMPT" =~ $SURPRISE_REGEX ]] && SECONDARY_PATTERNS+=("$sec_pattern") ;;
  esac
done
shopt -u nocasematch

# ──────────────────────────────────────────────────────────────────────
# Performance check — skip append if budget exceeded
# ──────────────────────────────────────────────────────────────────────
END_NS=$(date +%s%N)
ELAPSED_MS=$(( (END_NS - START_NS) / 1000000 ))

if [ "$ELAPSED_MS" -gt "$PERF_HARD_LIMIT_MS" ]; then
  PERF_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  echo "{\"ts\":\"${PERF_TS}\",\"prompt_len\":${PROMPT_LEN},\"elapsed_ms\":${ELAPSED_MS},\"pattern\":\"${MATCHED_PRIMARY}\"}" \
    >> "$PERF_WARN_FILE" 2>/dev/null || true
  exit 0
fi

# ──────────────────────────────────────────────────────────────────────
# Build candidate JSON and append to candidate-lessons.jsonl
# ──────────────────────────────────────────────────────────────────────
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Snippet: max 200 chars
SNIPPET="${PROMPT:0:200}"

# Auto-generate candidate_lesson stub (HITL gate enriches in /review)
case "$MATCHED_PRIMARY" in
  correction)            LESSON_STUB="User correction: ${SNIPPET:0:150}" ;;
  frustration)           LESSON_STUB="User frustration (repeated issue): ${SNIPPET:0:140}" ;;
  preference)            LESSON_STUB="User preference: ${SNIPPET:0:160}" ;;
  decision-confirmation) LESSON_STUB="User confirmed decision: ${SNIPPET:0:150}" ;;
  surprise)              LESSON_STUB="User surprise (non-obvious behavior): ${SNIPPET:0:140}" ;;
esac

# Secondary patterns JSON array
if [ ${#SECONDARY_PATTERNS[@]} -eq 0 ]; then
  SECONDARY_JSON='[]'
else
  SECONDARY_JSON=$(printf '%s\n' "${SECONDARY_PATTERNS[@]}" | jq -R . | jq -s -c .)
fi

# Build candidate JSON via jq (handles escaping)
CANDIDATE=$(jq -c -n \
  --arg ts "$TS" \
  --arg pattern "$MATCHED_PRIMARY" \
  --arg snippet "$SNIPPET" \
  --arg lesson "$LESSON_STUB" \
  --arg severity "$MATCHED_SEVERITY" \
  --argjson secondary "$SECONDARY_JSON" \
  --arg session "${CLAUDE_SESSION_ID:-}" \
  '{
    schema_version: 1,
    ts: $ts,
    origin: "conversation-learning-hook",
    pattern: $pattern,
    user_prompt_snippet: $snippet,
    context_window_hint: null,
    candidate_lesson: $lesson,
    severity: $severity,
    confidence_hits: 1,
    secondary_patterns: $secondary,
    promoted_to_factory: false,
    hitl_approved: null,
    session_id: (if $session == "" then null else $session end)
  }' 2>/dev/null)

if [ -z "$CANDIDATE" ]; then
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"reason\":\"jq_build_failed\",\"pattern\":\"${MATCHED_PRIMARY}\"}" \
    >> "$THROTTLE_FILE" 2>/dev/null || true
  exit 0
fi

# Atomic append (single line, no race condition on JSONL)
if ! echo "$CANDIDATE" >> "$CANDIDATES_FILE" 2>/dev/null; then
  cat >&2 <<MSG
⚠️  Hook userPromptSubmit-conversation-learning: write FAIL do
    ${CANDIDATES_FILE}
    (check permissions / disk space)
MSG
  exit 0
fi

# Update counter + cooldown (after successful append)
echo $((SESSION_COUNT + 1)) > "$COUNTER_FILE" 2>/dev/null || true
update_cooldown "$MATCHED_PRIMARY"

# ──────────────────────────────────────────────────────────────────────
# Stderr soft-reminder TYLKO dla HIGH (correction + frustration)
# ──────────────────────────────────────────────────────────────────────
if [ "$MATCHED_SEVERITY" = "high" ]; then
  cat >&2 <<MSG
ℹ️  Reminder (userPromptSubmit-conversation-learning):

Wykryto pattern: ${MATCHED_PRIMARY} (severity: HIGH)
Candidate lesson zapisany do .claude/knowledge-base/candidate-lessons.jsonl
(${SESSION_COUNT}/${MAX_PER_SESSION} this session, cooldown 30 min for "${MATCHED_PRIMARY}")

Po sesji uruchom \`/review-candidate-lessons\` żeby zaakceptować lub odrzucić.
HITL gate: każdy candidate wymaga Twojej decyzji przed promotion do lessons.jsonl.

Hook source: .claude/hooks/userPromptSubmit-conversation-learning.sh
Skill: .claude/skills/conversation-learning/SKILL.md
MSG
fi

exit 0
