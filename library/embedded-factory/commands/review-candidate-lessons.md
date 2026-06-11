---
description: Batch HITL review pending candidate lessons z conversation-learning hook. Per-candidate accept/reject/edit/skip → promotion accepted do lokalnego lessons.jsonl. Idempotent (skip hitl_approved != null). Flagi --batch-size, --pattern, --severity, --dry-run, --auto-prune.
---

Cel: przeprowadź batch HITL review **pending candidate lessons** z `.claude/knowledge-base/candidate-lessons.jsonl` (output Path 1 hook `userPromptSubmit-conversation-learning.sh`).

## Setup

Sprawdź input — czy user podał flagi:

- `--batch-size=N` (default 10, max 50)
- `--pattern=correction|frustration|preference|decision-confirmation|surprise` (filter, optional)
- `--severity=high|medium|low` (filter, optional)
- `--dry-run` (preview bez zapisu, optional)
- `--auto-prune` (przenoś `hitl_approved=null` starsze niż 30 dni do archive, optional standalone — jeśli podane → wykonaj prune i exit, NIE wchodź w review)

## Krok 1 — Sprawdź środowisko

```bash
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CANDIDATES="${PROJECT_DIR}/.claude/knowledge-base/candidate-lessons.jsonl"
LESSONS="${PROJECT_DIR}/.claude/knowledge-base/lessons.jsonl"  # lokalny, NIE centralna fabryka
LESSONS_FACTORY="${PROJECT_DIR}/knowledge-base/lessons.jsonl"  # fallback dla fabryki

# W fabryce target = knowledge-base/lessons.jsonl
# W paczce = .claude/knowledge-base/lessons.jsonl
if [ -f "$LESSONS_FACTORY" ] && [ "$PROJECT_DIR" = "~/agent-factory" ]; then
  TARGET_LESSONS="$LESSONS_FACTORY"
else
  TARGET_LESSONS="$LESSONS"
  mkdir -p "$(dirname "$LESSONS")"
  touch "$LESSONS"
fi
```

Jeśli `$CANDIDATES` nie istnieje LUB zawiera 0 pending (`hitl_approved == null`):
- Wypisz: `📭 Brak pending candidates do review w ${CANDIDATES}`
- Sugestia diagnostyczna: `Jeśli hook userPromptSubmit-conversation-learning.sh jest zainstalowany, sprawdź settings.json: jq '.hooks.UserPromptSubmit' .claude/settings.json`
- Exit

## Krok 2 — Auto-prune (jeśli `--auto-prune` flag)

```bash
ARCHIVE="${PROJECT_DIR}/.claude/knowledge-base/candidate-lessons-archive-$(date +%Y-%m).jsonl"
CUTOFF=$(date -d '30 days ago' -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -v-30d -u +%Y-%m-%dT%H:%M:%SZ)

# Move hitl_approved=null entries starsze niż 30 dni do archive
jq -c --arg cutoff "$CUTOFF" 'select(.hitl_approved == null and .ts < $cutoff)' \
  "$CANDIDATES" >> "$ARCHIVE"

# Keep tylko nowsze niż cutoff lub already-decided (true/false)
TMP=$(mktemp)
jq -c --arg cutoff "$CUTOFF" 'select(.hitl_approved != null or .ts >= $cutoff)' \
  "$CANDIDATES" > "$TMP" && mv "$TMP" "$CANDIDATES"
```

Wypisz: `🗄️  Auto-pruned N candidates older than 30 days → ${ARCHIVE}`. Exit.

## Krok 3 — Load pending candidates (z filtrami)

```bash
# Pending: hitl_approved == null
# Z opcjonalnymi filtrami pattern + severity
FILTER='.hitl_approved == null'
[ -n "$PATTERN_FILTER" ] && FILTER="$FILTER and .pattern == \"$PATTERN_FILTER\""
[ -n "$SEVERITY_FILTER" ] && FILTER="$FILTER and .severity == \"$SEVERITY_FILTER\""

PENDING=$(jq -c "select($FILTER)" "$CANDIDATES")
TOTAL=$(echo "$PENDING" | grep -c . || echo 0)
```

Wypisz header:

```
═══════════════════════════════════════════════════════════
  Conversation-learning candidate lessons review
  Project: <basename $PROJECT_DIR>
  Total pending: <TOTAL> candidates (showing batch 1 of <ceil(TOTAL/BATCH_SIZE)>, <BATCH_SIZE> per batch)
  Filters: pattern=<PATTERN_FILTER|all>, severity=<SEVERITY_FILTER|all>
  Mode: <dry-run|live>
═══════════════════════════════════════════════════════════
```

## Krok 4 — Per-candidate batch loop

Dla każdego candidate (pierwszy batch):

1. Wypisz w formacie:
   ```
   [N/BATCH_SIZE] Pattern: <pattern> (severity: <severity>)
     ts: <ts>
     prompt_snippet: "<user_prompt_snippet>"
     candidate_lesson: "<candidate_lesson>"
     secondary_patterns: [<list>]
   
     [y]es accept / [n]o reject / [e]dit / [s]kip / [q]uit
   ```

2. Zapytaj usera: czekaj na response `y` / `n` / `e` / `s` / `q`.

3. Akcja per response:

   **`y` (accept):**
   - Zapytaj `Pick project: [1] <auto-detected> [2] cross-cutting [3] other` → wybór
   - Zapytaj `Pick category: [1] agent-design [2] tooling [3] scope-management [4] planning [5] meta [6] other` → wybór
   - Zapytaj `Edit title? (default: "<derived from candidate_lesson first 60ch>"): [Enter to keep]` → wybór
   - Zapytaj `Edit lesson? (default: <candidate_lesson>): [Enter to keep]` → wybór
   - Get next lesson ID: `LAST_ID=$(jq -r '.id // 0' "$TARGET_LESSONS" | sort -n | tail -1 || echo 0); NEXT_ID=$((LAST_ID + 1))`
   - Build lesson JSON: `{id, date: today, project: ..., category: ..., severity: <mapped: low→LOW, medium→MED, high→HIGH>, title: ..., lesson: ..., triggered_by: "conversation-learning-hook", origin: "<basename PROJECT_DIR>", tags: ["conversation-learning", "<pattern>"]}`
   - **In-place update candidate-lessons.jsonl:** ustaw `hitl_approved: true`, `promoted_to_factory: false`, dodaj `promoted_at: <ISO ts>` (atomic via Python tempfile + mv)
   - **Append lesson** do `$TARGET_LESSONS`
   - Wypisz: `✅ Promoted as lesson #<NEXT_ID>`
   - Increment `ACCEPTED_COUNT`

   **`n` (reject):**
   - In-place update candidate-lessons.jsonl: ustaw `hitl_approved: false`
   - Wypisz: `❌ Rejected (zachowany w archive)`
   - Increment `REJECTED_COUNT`

   **`e` (edit):**
   - Zapytaj usera: `Edit candidate_lesson (current: <text>):` → user dostarcza nowy tekst
   - Validate: min 10ch, max 500ch
   - Jeśli OK → traktuj jako `y` accept (kontynuuj z accept workflow z nowym lesson text)
   - Jeśli FAIL → wypisz error, treat jako skip
   - Increment `EDITED_COUNT`

   **`s` (skip):**
   - Pozostaw `hitl_approved: null` (re-review next time)
   - Increment `SKIPPED_COUNT`

   **`q` (quit):**
   - Break loop natychmiast, zachowaj progress dotychczasowy
   - Increment `QUIT_FLAG=1`

4. Jeśli `--dry-run`: pokazuj akcje ale NIE zapisuj (in-place update + append do lessons.jsonl skip).

## Krok 5 — Batch summary

Po batch end (przed kolejnym batch lub przy quit):

```
═══════════════════════════════════════════════════════════
  Batch summary: accepted=<N>, rejected=<M>, edited=<K>, skipped=<L>, quit=<bool>
  Lessons promoted to <TARGET_LESSONS>: <N+K>
  Candidates updated in-place: <N+M+K>
═══════════════════════════════════════════════════════════
```

Append activity-log entry:

```bash
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"actor\":\"/review-candidate-lessons\",\"action\":\"batch_reviewed\",\"artifact\":\"candidate-lessons.jsonl\",\"notes\":\"accepted=N rejected=M edited=K skipped=L promoted=$((N+K))\"}" >> "${PROJECT_DIR}/knowledge-base/activity-log.jsonl"
```

Jeśli `QUIT_FLAG=0` AND więcej pending: zapytaj `Continue to batch 2? [y/N]`. Jeśli `y` → pętla od Krok 4 dla kolejnego batch.

## Krok 6 — Edge cases

- **Malformed JSONL line:** w Kroku 3 jq raportuje parse error. Wypisz `⚠️  Skipping malformed line N: <error message>` i kontynuuj z kolejną linią (NIE crash).
- **Schema validation fail przy append do lessons.jsonl:** zatrzymaj batch, wypisz validation errors, zachowaj progress (in-place update candidate już zrobione → next `/review` resume).
- **`$TARGET_LESSONS` nie istnieje:** stwórz pustą jsonl + dopisz pierwszą lesson.
- **Concurrent edit (.bak conflict):** sprawdzaj checksums przed in-place update — jeśli mismatch → abort z error message.

## Krok 7 — Idempotencja

Re-uruchomienie `/review-candidate-lessons` po przerwaniu (Ctrl-C lub `q`):
- Re-load Pending z filtrem `hitl_approved == null` → already-decided pomijane automatycznie
- Counter `.session-candidate-count` NIE jest touchowany (to inny mechanism — hook only)

## Anti-patterns

- ❌ **NIE delete linii z candidate-lessons.jsonl** — zawsze in-place update (`null` → `true`/`false`). Audit trail.
- ❌ **NIE skip schema validation** przed append do lessons.jsonl — walidator pre-commit BLOKUJE bad lessons (validate-lesson-schema.sh).
- ❌ **NIE auto-accept wszystkie pending** — HITL gate jest CELEM, NIE przeszkodą. operator musi review.
- ❌ **NIE batch-size >50** — HITL fatigue, jakość spadnie. Max 50 z warning.
- ❌ **NIE promotion do centralnej fabryki bezpośrednio** — `/review` promuje LOKALNIE. Promotion do fabryki = osobny `/promote-lessons` (.E11).

## Referencje

- Hook source: `library/hooks/userPromptSubmit-conversation-learning.sh`
- Skill: `library/skills/universal/conversation-learning/SKILL.md` v1.1.0
- Schema candidate-lessons: `knowledge-base/candidate-lessons-schema.json` (E5b backlog)
-  plan: `knowledge-base/plans/2026-05-24--conversation-learning-path1.md`

## Distribution

Ten command istnieje w 2 lokalizacjach (zarządzane build-script ADR 009):

- **Fabryka:** `.claude/commands/review-candidate-lessons.md` (master source)
- **Embedded (od .E7):** `library/embedded-factory/commands/review-candidate-lessons.md` (build-script copy, identyczna logika, $TARGET_LESSONS = lokalny `.claude/knowledge-base/lessons.jsonl`)
