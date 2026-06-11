#!/usr/bin/env bash
# library/embedded-factory/hooks/stop-solution-record.sh
#
# Stop hook — druga oś learning-loopu (solution-memory). Po zakończeniu
# sesji, która przekroczyła PRÓG ILOŚCIOWY (≥1 commit LUB ≥3 zmienione
# pliki), wstrzykuje do main Claude instrukcję uruchomienia subagenta
# `solution-reflector`, który rekonstruuje rozwiązany problem (problem →
# ślepe uliczki → rozwiązanie), ocenia wartość i zapisuje md+index.
#
# Origin:
#   Plan 2026-06-05-autonomiczne-samouczenie, etap 8. Warstwa PROJEKTU
#   jest celowo AUTONOMICZNA (bez bramki HITL — decyzja operatora). Bramka
#   dopiero przy wejściu do fabryki (/weekly-factory-intake).
#
# Mechanizm (kontrakt Stop hooka Claude Code):
#   1. Czyta JSON ze stdin: session_id, transcript_path, cwd,
#      stop_hook_active.
#   2. stop_hook_active==true → exit 0 (jesteśmy w turze kontynuacji po
#      naszym własnym block — NIE zapętlaj).
#   3. Brak `.claude/knowledge-base/` LUB brak repo git → exit 0 (C2).
#   4. PRE-FILTR (tani, bez LLM): policz commity sesji (baseline..HEAD,
#      baseline z `.session-head-baseline` zapisanego przez SessionStart)
#      + zmienione pliki (committed + working tree). Poniżej progu → exit 0.
#   5. IDEMPOTENCJA: MD5 stanu (baseline+HEAD+porcelain). Jeśli == ostatnio
#      przetworzony (`.solution-last-md5`) → exit 0 (już obsłużone).
#   6. Zbuduj lekki payload `.solution-pending.json` (commity, diffstat,
#      pliki, baseline, head, session_id, transcript_path).
#   7. Emit `{"decision":"block","reason":...}` + additionalContext →
#      main Claude dostaje instrukcję: dispatch `solution-reflector`.
#
# Reflector (sonnet) sam dociąga `git diff/log` i (jeśli jest)
# transcript_path; sam decyduje o ciszy / scope / anti-PII (B1/B4).
#
# Performance: pre-filtr to kilka komend git (<150ms). LLM (reflector)
# odpala się TYLKO powyżej progu i tylko raz per stan (idempotencja).
#
# Instalacja (settings.json):
#   "Stop": [{ "matcher": "",
#     "hooks": [{ "type": "command",
#                 "command": ".claude/hooks/stop-solution-record.sh",
#                 "timeout": 15 }] }]
#
# Exit codes: 0 zawsze (block sygnalizowany przez JSON na stdout, nie exit).

set -uo pipefail

# Próg pre-filtra (decyzja operatora 2026-06-05)
MIN_COMMITS=1
MIN_FILES=3

INPUT="$(cat 2>/dev/null || echo '{}')"

jget { echo "$INPUT" | jq -r "$1 // \"\"" 2>/dev/null || echo ""; }

STOP_ACTIVE="$(jget '.stop_hook_active')"
CWD="$(jget '.cwd')"
SESSION_ID="$(jget '.session_id')"
TRANSCRIPT="$(jget '.transcript_path')"

# (2) Loop guard — jesteśmy w turze kontynuacji po naszym własnym block
[ "$STOP_ACTIVE" = "true" ] && exit 0

[ -z "$CWD" ] && CWD="${CLAUDE_PROJECT_DIR:-$(pwd)}"

KB_DIR="${CWD}/.claude/knowledge-base"
# (3a) Nie projekt embedded
[ ! -d "$KB_DIR" ] && exit 0

# (3b) Fallback bez gita (C2) — pre-filtr ilościowy niewykonalny
if ! git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

HEAD_REF="$(git -C "$CWD" rev-parse HEAD 2>/dev/null || echo "")"
[ -z "$HEAD_REF" ] && exit 0   # repo bez commitów

BASELINE_FILE="${KB_DIR}/.session-head-baseline"
BASELINE="$(cat "$BASELINE_FILE" 2>/dev/null || echo "")"

# (4) PRE-FILTR — commity + zmienione pliki tej sesji
COMMIT_COUNT=0
COMMIT_LIST="[]"
COMMITTED_FILES=""
if [ -n "$BASELINE" ] && git -C "$CWD" cat-file -e "${BASELINE}^{commit}" 2>/dev/null; then
  COMMIT_COUNT="$(git -C "$CWD" rev-list --count "${BASELINE}..HEAD" 2>/dev/null || echo 0)"
  COMMIT_LIST="$(git -C "$CWD" rev-list "${BASELINE}..HEAD" 2>/dev/null | head -50 | jq -R . | jq -s -c . 2>/dev/null || echo '[]')"
  COMMITTED_FILES="$(git -C "$CWD" diff --name-only "${BASELINE}..HEAD" 2>/dev/null)"
fi

# Working-tree zmiany (uncommitted) — łapie też sesje bez commita
WORKTREE_FILES="$(git -C "$CWD" status --porcelain 2>/dev/null | awk '{print $NF}')"

FILE_COUNT="$(printf '%s\n%s\n' "$COMMITTED_FILES" "$WORKTREE_FILES" | grep -v '^$' | sort -u | wc -l | tr -d ' ')"

# Poniżej progu → cisza, ZERO kosztu LLM
if [ "${COMMIT_COUNT:-0}" -lt "$MIN_COMMITS" ] && [ "${FILE_COUNT:-0}" -lt "$MIN_FILES" ]; then
  exit 0
fi

# (5) IDEMPOTENCJA — MD5 stanu; nie przetwarzaj dwa razy tego samego
PORCELAIN_HASH="$(git -C "$CWD" status --porcelain 2>/dev/null | md5sum | cut -d' ' -f1)"
STATE_ID="$(printf '%s|%s|%s' "$BASELINE" "$HEAD_REF" "$PORCELAIN_HASH" | md5sum | cut -d' ' -f1)"
LAST_MD5_FILE="${KB_DIR}/.solution-last-md5"
LAST_MD5="$(cat "$LAST_MD5_FILE" 2>/dev/null || echo "")"
[ "$STATE_ID" = "$LAST_MD5" ] && exit 0

# (6) Lekki payload dla reflectora
DIFFSTAT="$(git -C "$CWD" diff --stat "${BASELINE:-HEAD}..HEAD" 2>/dev/null | tail -40)"
[ -z "$DIFFSTAT" ] && DIFFSTAT="$(git -C "$CWD" diff --stat 2>/dev/null | tail -40)"
CHANGED_JSON="$(printf '%s\n%s\n' "$COMMITTED_FILES" "$WORKTREE_FILES" | grep -v '^$' | sort -u | head -100 | jq -R . | jq -s -c . 2>/dev/null || echo '[]')"

PENDING_FILE="${KB_DIR}/.solution-pending.json"
jq -c -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg session "$SESSION_ID" \
  --arg transcript "$TRANSCRIPT" \
  --arg baseline "$BASELINE" \
  --arg head "$HEAD_REF" \
  --argjson commit_count "${COMMIT_COUNT:-0}" \
  --argjson commits "$COMMIT_LIST" \
  --argjson file_count "${FILE_COUNT:-0}" \
  --argjson changed_files "$CHANGED_JSON" \
  --arg diffstat "$DIFFSTAT" \
  '{ts:$ts, session_id:(if $session=="" then null else $session end),
    transcript_path:(if $transcript=="" then null else $transcript end),
    baseline:(if $baseline=="" then null else $baseline end), head:$head,
    commit_count:$commit_count, commits:$commits,
    file_count:$file_count, changed_files:$changed_files,
    diffstat:$diffstat}' \
  > "$PENDING_FILE" 2>/dev/null || exit 0

# Zapisz stan PRZED block (idempotencja — nawet jeśli reflector zamilknie)
echo "$STATE_ID" > "$LAST_MD5_FILE" 2>/dev/null || true

# (7) Block + instrukcja dla main Claude → dispatch solution-reflector
REASON="Sesja przekroczyła próg solution-memory (${COMMIT_COUNT} commit(ów), ${FILE_COUNT} plik(ów)). Uruchom subagenta solution-reflector z payloadem ${PENDING_FILE}, żeby zapamiętać rozwiązanie (problem → ślepe uliczki → rozwiązanie). Reflector sam oceni czy warto zapisać (prawo do ciszy), nada scope i wykona anti-PII. To warstwa autonomiczna bez bramki — po zapisie po prostu zakończ."

jq -c -n --arg reason "$REASON" \
  '{decision:"block", reason:$reason,
    hookSpecificOutput:{hookEventName:"Stop", additionalContext:$reason}}' 2>/dev/null \
  || printf '{"decision":"block","reason":"Uruchom solution-reflector z %s"}\n' "$PENDING_FILE"

exit 0
