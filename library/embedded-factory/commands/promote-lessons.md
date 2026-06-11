---
description: Push branch `learning/<YYYY-MM-DD>` na repo paczki af-pack-* z subset .claude/knowledge-base/lessons.jsonl (filter confidence_hits ≥3). Fabryka cron monthly intelligence pulluje + HITL gate. Dry-run + interactive confirm. Decyzja Q1: auto-promotion z confidence threshold (NIE każda lesson promotowana).
---

Cel: promocja lokalnych lessons z projektu-konsumenta paczki do centralnej fabryki `agent-factory` poprzez branch `learning/<date>` na repo paczki. Fabryka pulluje przez cron monthly intelligence, filtruje confidence ≥3 cross-projektowo, HITL gate w improvement-proposals.

## Setup

Sprawdź flagi:

- `--dry-run` (preview branch content, NIE push) **domyślne jeśli brak flagi**
- `--push` (właściwy push, wymaga uprzedniego dry-run)
- `--since=<YYYY-MM-DD>` (filter lessons created after date, default: 30 days ago)
- `--confidence=<N>` (override threshold, default: 3, lite override jeśli first promotion: 1)
- `--include-reflections` (v2 backlog, na razie ignore)
- `--include-errors` (v2 backlog, na razie ignore)
- `--remote=<url|nazwa>` (target push — domyślnie `origin`. Użyj gdy origin projektu-konsumenta ≠ repo paczki. Pilot DemoApp: origin to `LogicMorrow/DemoApp`, ale fabryka `/pull-promoted-lessons` skanuje repos `af-pack-*` — promuj na `https://github.com/LogicMorrow/af-pack-<nazwa>.git` żeby pull znalazł branch. Wprowadzono 2026-06-02 po pierwszym realnym feedbacku.)

## Krok 0 — Pre-flight checks

```bash
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LESSONS_LOCAL="${PROJECT_DIR}/.claude/knowledge-base/lessons.jsonl"
PROMOTION_LOG="${PROJECT_DIR}/.claude/knowledge-base/promotion-history.jsonl"

# Verify w git repo paczki (NIE w fabryce, NIE w random dir)
cd "$PROJECT_DIR"
GIT_REMOTE=$(git remote get-url origin 2>/dev/null)
if [ -z "$GIT_REMOTE" ]; then
  echo "❌ Not a git repo or no origin remote. /promote-lessons requires paczka repo."
  exit 1
fi

# Verify NIE w agent-factory (recursive promotion guard)
if echo "$GIT_REMOTE" | grep -q "LogicMorrow/agent-factory"; then
  echo "❌ /promote-lessons is for af-pack-* projekts, NOT agent-factory itself."
  echo "   Detected origin: $GIT_REMOTE"
  echo "   W fabryce użyj /pull-promoted-lessons (manual trigger pull-merge)."
  exit 1
fi

# Verify lessons.jsonl exists + ≥1 entry
if [ ! -f "$LESSONS_LOCAL" ] || [ ! -s "$LESSONS_LOCAL" ]; then
  echo "📭 No local lessons to promote (${LESSONS_LOCAL} empty or missing)"
  echo "   Lessons capture przez /log-lesson lub /review-candidate-lessons accept."
  exit 0
fi

# Verify PAT auth (gh CLI)
if ! gh auth status >/dev/null 2>&1; then
  echo "❌ gh CLI not authenticated. Run: gh auth login"
  echo "   Required scopes: Contents: write, Pull requests: write (na repo paczki)"
  exit 1
fi
```

## Krok 1 — Filter lessons do promotion

```bash
SINCE_DATE="${SINCE_FLAG:-$(date -d '30 days ago' +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d)}"
CONFIDENCE_THRESHOLD="${CONFIDENCE_FLAG:-3}"

# Filter: lessons created since + confidence_hits ≥ threshold + NIE already promoted
PROMOTED_IDS=$(jq -r '.lesson_id' "$PROMOTION_LOG" 2>/dev/null | sort -u)

CANDIDATES=$(jq -c --arg since "$SINCE_DATE" --argjson threshold "$CONFIDENCE_THRESHOLD" '
  select(.date >= $since)
  | select(.confidence_hits // 1 >= $threshold)
' "$LESSONS_LOCAL" | while read line; do
  ID=$(echo "$line" | jq -r '.id')
  if ! echo "$PROMOTED_IDS" | grep -q "^${ID}$"; then
    echo "$line"
  fi
done)

CANDIDATE_COUNT=$(echo "$CANDIDATES" | grep -c . || echo 0)
```

Wypisz header:

```
═══════════════════════════════════════════════════════════
  📤 /promote-lessons dry-run
  Project: $(basename $PROJECT_DIR)
  Filter: since=${SINCE_DATE}, confidence ≥${CONFIDENCE_THRESHOLD}
  Candidates: ${CANDIDATE_COUNT}
═══════════════════════════════════════════════════════════
```

Jeśli `CANDIDATE_COUNT = 0`:
- Wypisz: "No lessons match filter. Try `--confidence=1` (first promotion) or `--since=<earlier>`."
- Exit

## Krok 2 — Build branch content

```bash
BRANCH_NAME="learning/$(date +%Y-%m-%d)"
BRANCH_DIR="/tmp/promote-${BRANCH_NAME//\//-}-$$"
mkdir -p "$BRANCH_DIR"

# 1. lessons-promoted.jsonl — subset zgodnie z filtrami
echo "$CANDIDATES" > "${BRANCH_DIR}/lessons-promoted.jsonl"

# 2. manifest.json — metadata
PROJECT_NAME=$(basename "$PROJECT_DIR")
TOTAL_SCORE=$(echo "$CANDIDATES" | jq -s 'map(.confidence_hits // 1) | add')
jq -n \
  --arg project "$PROJECT_NAME" \
  --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson lessons_count "$CANDIDATE_COUNT" \
  --argjson reflections_count 0 \
  --argjson errors_count 0 \
  --argjson total_score "$TOTAL_SCORE" \
  --arg since "$SINCE_DATE" \
  --argjson threshold "$CONFIDENCE_THRESHOLD" \
  '{
    schema_version: 1,
    project: $project,
    date: $date,
    lessons_count: $lessons_count,
    reflections_count: $reflections_count,
    errors_count: $errors_count,
    total_confidence_score: $total_score,
    filters: {since: $since, confidence_threshold: $threshold}
  }' > "${BRANCH_DIR}/manifest.json"

# 3. reflections-summary.md — placeholder (v2)
echo "# Reflections summary (v2 backlog)" > "${BRANCH_DIR}/reflections-summary.md"

# 4. errors-summary.md — placeholder (v2)
echo "# Errors summary (v2 backlog)" > "${BRANCH_DIR}/errors-summary.md"
```

Wypisz dry-run preview:

```
Branch content (${BRANCH_DIR}):
  lessons-promoted.jsonl: ${CANDIDATE_COUNT} lessons, total_score=${TOTAL_SCORE}
  manifest.json: project=${PROJECT_NAME}, since=${SINCE_DATE}, threshold=${CONFIDENCE_THRESHOLD}
  reflections-summary.md: placeholder (v2)
  errors-summary.md: placeholder (v2)

Lessons sample (first 3):
$(echo "$CANDIDATES" | head -3 | jq -r '  "  - #\(.id) [\(.severity)] \(.category): \(.title // .lesson[0:80])"')
```

Zapytaj: `Push branch ${BRANCH_NAME} to ${GIT_REMOTE}? [y/N]`

Jeśli `y` → Krok 3 (--push).
Jeśli `N` lub `--dry-run`: cleanup `$BRANCH_DIR`, exit.

## Krok 3 — Push branch (--push)

```bash
cd "$PROJECT_DIR"

# Create orphan branch (NIE merge z main paczki — to czysty learning branch)
git checkout --orphan "$BRANCH_NAME"
git rm -rf . 2>/dev/null || true

# Copy branch content
cp "${BRANCH_DIR}"/lessons-promoted.jsonl ./
cp "${BRANCH_DIR}"/manifest.json ./
cp "${BRANCH_DIR}"/reflections-summary.md ./
cp "${BRANCH_DIR}"/errors-summary.md ./

# Commit
git add .
git commit -m "$(cat <<EOF
promote(learning): ${CANDIDATE_COUNT} lessons z ${PROJECT_NAME} ($(date +%Y-%m-%d))

Filter: since=${SINCE_DATE}, confidence ≥${CONFIDENCE_THRESHOLD}
Total confidence score: ${TOTAL_SCORE}

Fabryka cron monthly intelligence pull-merge:
- Filter cross-projektowy (confidence ≥3 w ≥2 paczkach)
- HITL gate przez improvement-proposals/auto-pull-merge-<date>.md
- operator approve → merge do agent-factory/lessons.jsonl

🤖 Generated by /promote-lessons (embedded-factory v1.0.0)
EOF
)"

# Push — target = --remote (url lub nazwa) jeśli podany, inaczej origin.
# Gdy origin konsumenta != repo paczki (np. DemoApp vs af-pack-<nazwa>),
# podaj --remote=<url paczki> żeby fabryka /pull-promoted-lessons (skan af-pack-*) znalazła branch.
TARGET_REMOTE="${REMOTE_FLAG:-origin}"
git push "$TARGET_REMOTE" "$BRANCH_NAME"

# Switch back to original branch
ORIGINAL_BRANCH=$(git config --get init.defaultBranch || echo "main")
git checkout "$ORIGINAL_BRANCH"
```

## Krok 4 — Update promotion-history.jsonl (audit trail)

```bash
echo "$CANDIDATES" | jq -c --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg branch "$BRANCH_NAME" '
  {lesson_id: .id, promoted_at: $ts, branch: $branch}
' >> "$PROMOTION_LOG"
```

## Krok 5 — Activity-log entry

```bash
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"actor\":\"/promote-lessons\",\"action\":\"branch_pushed\",\"artifact\":\"${BRANCH_NAME}\",\"notes\":\"count=${CANDIDATE_COUNT} score=${TOTAL_SCORE} threshold=${CONFIDENCE_THRESHOLD} remote=${GIT_REMOTE}\"}" \
  >> "${PROJECT_DIR}/.claude/knowledge-base/activity-log.jsonl"

# Cleanup tmp
rm -rf "$BRANCH_DIR"
```

Output summary:

```
═══════════════════════════════════════════════════════════
  ✅ Promoted ${CANDIDATE_COUNT} lessons to ${BRANCH_NAME}
  Pushed to: ${GIT_REMOTE}
  Total confidence: ${TOTAL_SCORE}
  
  Next steps (na stronie fabryki):
  - Cron monthly intelligence (1-szy month 11:00 CEST) pulluje branches
  - Filter cross-projektowy confidence ≥3 w ≥2 paczkach
  - HITL improvement-proposals/auto-pull-merge-<date>.md
  - operator approve → merge do agent-factory lessons.jsonl
  
  Twoje lessons będą widoczne w fabryce w following monthly cycle.
═══════════════════════════════════════════════════════════
```

## Anti-patterns

- ❌ **NIE promote lessons z PII** — pre-check: ostrzeżenie jeśli `lesson` zawiera @ (email-like) lub regex sekretów. HITL pre-push confirm.
- ❌ **NIE promote w fabryce (agent-factory)** — recursive promotion guard w Krok 0
- ❌ **NIE push branch jeśli już istnieje na remote** — git push fail-fast (NIE force)
- ❌ **NIE auto-promote bez user confirm** — dry-run + interactive `y/N` zawsze
- ❌ **NIE promote tych samych lessons wielokrotnie** — `promotion-history.jsonl` audit trail, filter `NOT IN promoted_ids`
- ❌ **NIE delete branch po push** — fabryka cron może potrzebować re-fetch. Branch cleanup post-pull-merge w fabryce (NIE w paczce).
- ❌ **NIE include reflections/errors w v1.0** — backlog v2, scope limit (deal-breaker scope creep)

## Frequency expectations

- **Pierwsza promotion:** ~2-4 tygodnie po install paczki (czas zebrać ≥3 lessons confidence)
- **Regularna kadencja:** miesięcznie (synchronizuje się z fabryka cron monthly intelligence)
- **Threshold override:** `--confidence=1` dla pierwszej promotion (signal że projekt jest aktywny, fabryka decyduje czy merge)

## References

- Kontrakt C w master plan: `knowledge-base/plans/2026-05-24-master--11-portable-learning.md`
- Fabryka cron monthly intelligence: .E14 (S15-S16)
- `/pull-promoted-lessons` w fabryce: .E12 (S13)
- ADR 014 (do napisania): `/promote-lessons` branch convention
- Schema lessons v2: ADR 015 (.E13)
