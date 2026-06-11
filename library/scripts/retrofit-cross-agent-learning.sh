#!/usr/bin/env bash
# library/scripts/retrofit-cross-agent-learning.sh
#
# Batch retrofit "Before starting work" do agentów library NIE mających tej sekcji.
# Wstrzykuje wariant z injection-template.md per model (opus/sonnet → Full; haiku → Trim).
# Idempotentny — skip jeśli już ma.
#
# Origin:  pkt A5 (2026-05-13).
#
# Usage:
#   bash library/scripts/retrofit-cross-agent-learning.sh           # dry-run (lista, no changes)
#   bash library/scripts/retrofit-cross-agent-learning.sh --apply   # apply patches
#
# Exit codes:
#   0 — done (dry-run or applied)
#   1 — at least 1 patch failed

set -uo pipefail

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

# Lista plików do retrofit (dynamicznie z find)
TARGETS=$(find library/agents -name "*.md" -exec grep -L "Before starting work" {} \;)

if [ -z "$TARGETS" ]; then
  echo "✅ All agents already have 'Before starting work' section. Nothing to retrofit."
  exit 0
fi

FAIL=0
TOTAL=0
PATCHED=0
SKIPPED=0

for file in $TARGETS; do
  TOTAL=$((TOTAL+1))
  name=$(grep -m1 "^name:" "$file" | sed 's/^name: *//; s/^"\(.*\)"$/\1/; s/^'\''\(.*\)'\''$/\1/')
  model=$(grep -m1 "^model:" "$file" | sed 's/^model: *//; s/^"\(.*\)"$/\1/' | head -1)

  if [ -z "$name" ]; then
    echo "⚠️  SKIP $file — no name in frontmatter"
    SKIPPED=$((SKIPPED+1))
    continue
  fi

  # Default model = sonnet if not specified
  [ -z "$model" ] && model="sonnet"

  # Wybierz wariant
  if [ "$model" = "haiku" ]; then
    VARIANT="haiku-trim"
  else
    VARIANT="full"
  fi

  echo ""
  echo "── $name (model=$model, variant=$VARIANT) → $file"

  if [ "$APPLY" = "0" ]; then
    echo "   [dry-run] would inject '$VARIANT' Before starting work section"
    continue
  fi

  # Generate snippet
  if [ "$VARIANT" = "haiku-trim" ]; then
    SNIPPET=$(cat <<EOF

## Before starting work

<!-- cross-agent-learning E2: pre-execution context loading, model=haiku, trim mode -->
<!--  retrofit 2026-05-13 -->

Przed przystąpieniem do zadania właściwego wykonaj krok 0:

**Krok 0 — Wczytaj historyczne błędy (apply silently):**

1. Czytaj \`.claude/memory/errors-${name}.md\` (full, max 1 500 tokenów)
   - Jeśli plik nie istnieje: skip cicho, przejdź do dalszych kroków

**Apply silently:** nie wypisuj zawartości pliku. Stosuj wnioski cicho.
Wzmianka TYLKO gdy decyzja się zmienia — 1 zdanie z referencją do pliku i daty wpisu.

EOF
)
  else
    SNIPPET=$(cat <<EOF

## Before starting work

<!-- cross-agent-learning E2: pre-execution context loading, model=$model, full mode -->
<!--  retrofit 2026-05-13 -->

Przed przystąpieniem do zadania właściwego wykonaj krok 0:

**Krok 0 — Wczytaj kontekst historyczny (apply silently):**

1. Czytaj \`.claude/memory/errors-${name}.md\` (full) — jeśli plik nie istnieje, skip cicho
2. Czytaj 3 najnowsze reflections:
   - \`Glob: knowledge-base/reflections/${name}*.md\` (sort desc, head 3)
   - \`Read\` każdy znaleziony plik
   - Jeśli glob zwraca 0 wyników: skip cicho
3. Czytaj \`knowledge-base/lessons.jsonl\` — tail 20 wierszy

**Budget:** łącznie max ~5 000 tokenów. Jeśli przekroczone — pomijaj w kolejności:
lessons.jsonl najpierw, potem ogranicz reflections do 1 (najnowszej), errors-${name}.md nigdy nie pomijaj.

**Apply silently:** nie wypisuj co wczytałaś/eś. Stosuj wnioski cicho w dalszych krokach.
Wzmianka w outpucie TYLKO gdy decyzja faktycznie się zmienia vs default — 1 zdanie z referencją
(data lesson lub ścieżka pliku reflection).

EOF
)
  fi

  # Insertion point: po frontmatter (linia z drugim '---'), przed pierwszą sekcją
  # Find line number of second '---' (closing frontmatter)
  CLOSE_FM=$(awk '/^---$/{c++; if(c==2){print NR; exit}}' "$file")
  if [ -z "$CLOSE_FM" ]; then
    echo "   ⚠️  FAIL: no closing frontmatter found"
    FAIL=$((FAIL+1))
    continue
  fi

  # Insert snippet after closing frontmatter (line CLOSE_FM)
  # Using awk for atomic insert
  tmpfile=$(mktemp)
  awk -v ln="$CLOSE_FM" -v snippet="$SNIPPET" '
    NR==ln { print; print snippet; next }
    { print }
  ' "$file" > "$tmpfile"

  if [ ! -s "$tmpfile" ]; then
    echo "   ⚠️  FAIL: empty output, abort"
    rm -f "$tmpfile"
    FAIL=$((FAIL+1))
    continue
  fi

  mv "$tmpfile" "$file"

  # Verify
  if grep -q "Before starting work" "$file"; then
    echo "   ✓ PATCHED"
    PATCHED=$((PATCHED+1))
  else
    echo "   ✗ FAIL — verification: section not present after patch"
    FAIL=$((FAIL+1))
  fi
done

echo ""
echo "════════════════════════════════════════════════"
if [ "$APPLY" = "0" ]; then
  echo "  DRY-RUN: would patch $TOTAL agents"
  echo "  Re-run with --apply to execute"
else
  echo "  APPLIED: $PATCHED / $TOTAL patched, $FAIL failed, $SKIPPED skipped"
fi
echo "════════════════════════════════════════════════"

[ "$FAIL" = "0" ]
