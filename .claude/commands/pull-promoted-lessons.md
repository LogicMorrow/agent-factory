---
description: Manual trigger pull-merge lessons z repos af-pack-* branch learning/<date> do centralnej fabryki. Aggregate cross-paczkowo, filter confidence ≥3 + seen w ≥2 paczkach, emit improvement-proposals/auto-pull-merge-<date>.md (HITL gate dla operatora). Cron monthly intelligence (.E14) wywołuje tę samą logikę automatycznie 1-szy month.
---

Cel: federacja lessons z paczek `af-pack-*` do centralnej fabryki. Manual trigger (vs cron monthly intelligence — automated 1-szy month 11:00 CEST).

## Setup

Sprawdź flagi:

- `--dry-run` (preview merge bez pisania improvement-proposal) **domyślne**
- `--apply` (emit improvement-proposals/auto-pull-merge-<date>.md)
- `--paczki=<lista>` (CSV nazw paczek, default: wszystkie `af-pack-*` z `gh repo list LogicMorrow`)
- `--since=<YYYY-MM-DD>` (filter learning/<date> branches utworzonych po, default: 60 days ago)
- `--threshold=<N>` (override confidence_hits threshold, default: 3)
- `--min-paczki=<N>` (override cross-paczkowo minimum, default: 2)
- `--first-pilot` (tryb pierwszego feedbacku POJEDYNCZEGO pilota — ustawia `threshold=1` + `min-paczki=1`. Single-package lessons normalnie zostają lokalne (anti-pattern cross-paczkowo). Ten tryb je przepuszcza do improvement-proposal, ale HITL gate dalej obowiązuje. Użyj gdy paczka jest jedyną aktywną LUB chcesz feedback świeżego pilota zanim urośnie cross-paczkowo. Wprowadzono 2026-06-02 po pierwszym realnym feedbacku DemoApp.)
- `--repos=<CSV>` (dodatkowe repos do skanu POZA `af-pack-*` — np. repo projektu-konsumenta którego origin ≠ nazwa paczki. Pilot DemoApp: origin `LogicMorrow/DemoApp`, paczka `af-pack-<nazwa>` — promocja `learning/` może trafić na którekolwiek z nich. Default: tylko `af-pack-*`.)

## Krok 0 — Verify środowisko

```bash
# MUST być w fabryce
PROJECT_DIR="$(pwd)"
if [ "$(basename $PROJECT_DIR)" != "agent-factory" ]; then
  echo "❌ /pull-promoted-lessons must run from agent-factory (centralna fabryka)"
  echo "   Current: $PROJECT_DIR"
  exit 1
fi

# Verify PAT auth
if ! gh auth status >/dev/null 2>&1; then
  echo "❌ gh CLI not authenticated. Run: gh auth login"
  exit 1
fi
```

## Krok 1 — Discover paczki + branches

```bash
SINCE_DATE="${SINCE_FLAG:-$(date -d '60 days ago' +%Y-%m-%d 2>/dev/null || date -v-60d +%Y-%m-%d)}"

# --first-pilot: single-pilot mode (przepuszcza single-package lessons)
if [ -n "$FIRST_PILOT_FLAG" ]; then
  THRESHOLD_FLAG="${THRESHOLD_FLAG:-1}"
  MIN_PACZKI_FLAG="${MIN_PACZKI_FLAG:-1}"
  echo "ℹ️  --first-pilot: threshold=${THRESHOLD_FLAG}, min-paczki=${MIN_PACZKI_FLAG} (single-package lessons przepuszczone, HITL gate dalej obowiązuje)"
fi

# List af-pack-* repos (+ opcjonalne --repos dla konsumentów których origin != nazwa paczki)
if [ -n "$PACZKI_FLAG" ]; then
  PACZKI=$(echo "$PACZKI_FLAG" | tr ',' '\n')
else
  PACZKI=$(gh repo list LogicMorrow --limit 100 --json name | jq -r '.[].name' | grep "^af-pack-")
fi
# Doklej dodatkowe repos (--repos) — np. DemoApp (origin != af-pack-<nazwa>)
if [ -n "$REPOS_FLAG" ]; then
  PACZKI="$PACZKI"$'\n'"$(echo "$REPOS_FLAG" | tr ',' '\n')"
fi

# Per paczka: find learning/<date> branches >= since
LEARNING_BRANCHES=$(for paczka in $PACZKI; do
  gh api "repos/LogicMorrow/${paczka}/branches" --paginate 2>/dev/null | jq -r --arg s "$SINCE_DATE" '
    .[] | select(.name | startswith("learning/")) | select(.name > "learning/" + $s) | "\(.name)\t'"$paczka"'"
  '
done)

BRANCH_COUNT=$(echo "$LEARNING_BRANCHES" | grep -c . || echo 0)
```

Wypisz:

```
═══════════════════════════════════════════════════════════
  📥 /pull-promoted-lessons dry-run
  Paczki scanned: <COUNT>
  Learning branches found (since ${SINCE_DATE}): ${BRANCH_COUNT}
═══════════════════════════════════════════════════════════
```

Jeśli `BRANCH_COUNT = 0`:
- Wypisz: "No learning branches in any paczka since ${SINCE_DATE}."
- Sugestia: "Paczki muszą wywołać `/promote-lessons` żeby push branches."
- Exit

## Krok 2 — Aggregate lessons cross-paczkowo

```bash
THRESHOLD="${THRESHOLD_FLAG:-3}"
MIN_PACZKI="${MIN_PACZKI_FLAG:-2}"
TMPDIR=$(mktemp -d)

# Per branch: fetch lessons-promoted.jsonl + manifest.json
echo "$LEARNING_BRANCHES" | while IFS=$'\t' read -r branch paczka; do
  [ -z "$branch" ] && continue
  
  # gh api (NIE curl raw.githubusercontent) — paczki af-pack-* są PRIVATE,
  # raw.githubusercontent zwraca pustkę dla private repo bez auth.
  # Fix 2026-06-02 (pierwszy realny feedback DemoApp ujawnił bug: curl -sf → 0 lekcji).
  gh api "repos/LogicMorrow/${paczka}/contents/lessons-promoted.jsonl?ref=${branch}" --jq '.content' 2>/dev/null \
    | base64 -d > "${TMPDIR}/${paczka}--${branch//\//-}.lessons.jsonl"
  gh api "repos/LogicMorrow/${paczka}/contents/manifest.json?ref=${branch}" --jq '.content' 2>/dev/null \
    | base64 -d > "${TMPDIR}/${paczka}--${branch//\//-}.manifest.json"
done

# Aggregate: cross-paczkowo similarity check
# Two lessons "similar" if jaccard(tags) ≥ 0.5 OR title cosine similarity ≥ 0.7
# (V1.0.0 simplified: tag intersection ≥ 2)
python3 <<PYTHON > "${TMPDIR}/aggregated.jsonl"
import json, os, glob
from collections import defaultdict

lessons_by_paczka = defaultdict(list)
for f in glob.glob("${TMPDIR}/*.lessons.jsonl"):
    paczka = os.path.basename(f).split("--")[0]
    with open(f) as fp:
        for line in fp:
            try:
                lesson = json.loads(line)
                lessons_by_paczka[paczka].append(lesson)
            except: pass

# Build similarity clusters
all_lessons = [(p, l) for p, ll in lessons_by_paczka.items for l in ll]
clusters = []
seen = set
for i, (p1, l1) in enumerate(all_lessons):
    if i in seen: continue
    cluster = [(p1, l1)]
    tags1 = set(l1.get("tags", []))
    for j, (p2, l2) in enumerate(all_lessons[i+1:], i+1):
        if j in seen: continue
        if p2 == p1: continue  # same paczka — NIE cross
        tags2 = set(l2.get("tags", []))
        if len(tags1 & tags2) >= 2:  # tag intersection threshold
            cluster.append((p2, l2))
            seen.add(j)
    if len({p for p, _ in cluster}) >= ${MIN_PACZKI}:  # cross-paczkowo threshold
        total_confidence = sum(l.get("confidence_hits", 1) for _, l in cluster)
        if total_confidence >= ${THRESHOLD}:
            print(json.dumps({
                "cluster_size": len(cluster),
                "paczki": list({p for p, _ in cluster}),
                "total_confidence": total_confidence,
                "representative": cluster[0][1],
                "all_lessons": [{"paczka": p, "lesson": l} for p, l in cluster]
            }))
    seen.add(i)
PYTHON

CLUSTER_COUNT=$(wc -l < "${TMPDIR}/aggregated.jsonl")
```

Wypisz preview:

```
═══════════════════════════════════════════════════════════
  Aggregated clusters (confidence ≥${THRESHOLD}, cross-paczkowo ≥${MIN_PACZKI})
  Total clusters: ${CLUSTER_COUNT}
═══════════════════════════════════════════════════════════

Cluster examples (first 3):
$(head -3 "${TMPDIR}/aggregated.jsonl" | jq -r '"  - [\(.cluster_size) paczki, confidence=\(.total_confidence)] \(.representative.title // .representative.lesson[0:80])"')
```

Jeśli `--dry-run` (default): cleanup `$TMPDIR`, exit.

## Krok 3 — Emit improvement-proposal (--apply)

```bash
PROPOSAL_FILE="knowledge-base/improvement-proposals/auto-pull-merge-$(date +%Y-%m-%d).md"
DATE_NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

cat > "$PROPOSAL_FILE" <<EOF
---
proposal_id: auto-pull-merge-$(date +%Y-%m-%d)
title: Pull-merge lessons z paczek af-pack-* ($(date +%Y-%m-%d))
date: $(date +%Y-%m-%d)
type: lessons-federation
status: pending-hitl
generator: /pull-promoted-lessons
threshold_confidence: ${THRESHOLD}
threshold_min_paczki: ${MIN_PACZKI}
since_date: ${SINCE_DATE}
clusters_count: ${CLUSTER_COUNT}
---

# Improvement proposal: Pull-merge lessons (${CLUSTER_COUNT} clusters)

## Summary

Cron monthly intelligence (lub manual /pull-promoted-lessons) wykrył ${CLUSTER_COUNT} cluster-ów lessons cross-paczkowo z confidence ≥${THRESHOLD} w ≥${MIN_PACZKI} paczkach.

## Action required (HITL gate)

operator review per cluster — akcje:
- **MERGE** → append do agent-factory \`lessons.jsonl\` z \`origin: <paczka>\`, \`promoted_at: ${DATE_NOW}\`
- **DEFER** → wait następnego cycle (cluster może urosnąć)
- **REJECT** → fałszywy positive, NIE merge (lesson nie wnosi value cross-projektowo)

## Clusters

EOF

# Per cluster: append details
jq -c . "${TMPDIR}/aggregated.jsonl" | nl | while IFS= read -r line; do
  idx=$(echo "$line" | awk '{print $1}')
  cluster=$(echo "$line" | cut -f2-)
  rep_title=$(echo "$cluster" | jq -r '.representative.title // .representative.lesson[0:80]')
  cluster_size=$(echo "$cluster" | jq -r '.cluster_size')
  paczki=$(echo "$cluster" | jq -r '.paczki | join(", ")')
  conf=$(echo "$cluster" | jq -r '.total_confidence')
  
  cat >> "$PROPOSAL_FILE" <<EOF
### Cluster #${idx}: ${rep_title}

- **Cluster size:** ${cluster_size} (paczki: ${paczki})
- **Total confidence:** ${conf}
- **Action:** [ ] MERGE [ ] DEFER [ ] REJECT
- **Notes:** _operator fill in_

**Lessons w cluster:**

\`\`\`json
$(echo "$cluster" | jq '.all_lessons')
\`\`\`

---

EOF
done

cat >> "$PROPOSAL_FILE" <<EOF

## Approval workflow

1. operator review każdy cluster (Action checkbox)
2. Per cluster:
   - **MERGE:** uruchom \`/log-lesson\` LUB manualne append z \`origin: <paczka>\`, \`promoted_at: ${DATE_NOW}\`, \`triggered_by: pull-promoted-lessons\`
   - **DEFER:** brak akcji, pozostaje w improvement-proposals/ do następnego cycle
   - **REJECT:** mark "rejected" w notes, archive po 30 dni
3. Update status proposal: \`pending-hitl\` → \`completed\` (frontmatter)
4. Commit + push

## References

- Branch: knowledge-base/plans/2026-05-24--portable-self-learning-loop.md (E12, E14)
- Kontrakt C: master plan sekcja 7
- ADR 015 (do napisania): lessons.jsonl schema v2 backward compat
- ADR 016 (do napisania): cron pull-merge HITL gate

EOF

# Activity-log
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"actor\":\"/pull-promoted-lessons\",\"action\":\"pull_merge_proposal_emitted\",\"artifact\":\"$PROPOSAL_FILE\",\"notes\":\"clusters=${CLUSTER_COUNT} threshold=${THRESHOLD} min_paczki=${MIN_PACZKI} since=${SINCE_DATE}\"}" \
  >> knowledge-base/activity-log.jsonl

# Cleanup
rm -rf "$TMPDIR"

echo ""
echo "✅ Improvement-proposal written: $PROPOSAL_FILE"
echo "   ${CLUSTER_COUNT} clusters await operator HITL review."
```

## Anti-patterns

- ❌ **NIE auto-merge bez HITL** — KAŻDY cluster wymaga operator approve. Cron monthly intelligence robi ten sam mechanism z HITL gate.
- ❌ **NIE pull z agent-factory repo** — pętla recursive (Krok 0 guard sprawdza basename != agent-factory).
- ❌ **NIE merge tych samych clusters wielokrotnie** — improvement-proposals są dated; new file per run. operator manual archiwizacja zaakceptowanych.
- ❌ **NIE delete branches paczek po pull** — paczka może mieć referencję do swoich learning branches. Cleanup w paczce manualnie via operator.
- ❌ **NIE niski threshold (< 3)** — false positive risk. Threshold ≥3 = lesson musi mieć trwałe value cross-projektowo. **Wyjątek:** `--first-pilot` (threshold=1) dla pierwszego feedbacku pojedynczego pilota — HITL gate kompensuje ryzyko false-positive.
- ❌ **NIE single-paczka clusters** — wymaga ≥2 paczek (cross-paczkowo signal). Single-paczka lessons stay lokalne. **Wyjątek:** `--first-pilot` (min-paczki=1) — świadomie przepuszcza single-package feedback gdy paczka jest jedyną aktywną; decyzja MERGE/DEFER/REJECT i tak należy do operatora w improvement-proposal.

## Frequency expectations

- **Manual:** ad-hoc, gdy operator chce sprawdzić stan federacji (np. po promote z konkretnej paczki)
- **Cron:** monthly intelligence routine (.E14 implementacja w S15-S16) — automated 1-szy month 11:00 CEST. Output ten sam (improvement-proposal w `knowledge-base/improvement-proposals/`).

## References

- Kontrakt C: master plan `knowledge-base/plans/2026-05-24-master--11-portable-learning.md` sekcja 7
- /promote-lessons w paczkach: `library/embedded-factory/commands/promote-lessons.md`
- Cron monthly intelligence: `.claude/commands/agent-factory-monthly-intelligence.md` (patch w S15-S16)
- ADR 015 (schema v2), ADR 016 (cron pull-merge HITL gate)
