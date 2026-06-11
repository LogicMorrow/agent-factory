#!/usr/bin/env bash
# library/embedded-factory/build.sh
#
# Build-script copy z sed-replace dla embedded-factory (ADR 009).
# Source-of-truth: .claude/agents/ + library/skills/ + library/hooks/ + .claude/commands/.
# Output: library/embedded-factory/{agents,skills,hooks,commands}/ z transformowanymi ścieżkami.
#
# Mechanizm:
#   1. Clean-and-rebuild library/embedded-factory/{agents,skills,hooks,commands}/
#      (delete old, copy fresh — zero state leak)
#   2. Per artefakt z manifest.json:
#      a. cp source → embedded_path
#      b. apply sed_transformations (knowledge-base/ → .claude/knowledge-base/,
#         ~/agent-factory/ → $CLAUDE_PROJECT_DIR/, etc.)
#      c. compute MD5 source_hash, update manifest.json
#   3. Update manifest.json: generated_at, build_count, last_built, source_hash per entry
#   4. Run parity check: każdy embedded_path istnieje + source_hash matches
#
# Trade-off (z ADR 009): deferred sync — edytujesz source, build.sh NIE odpala
# się auto. Manual `bash library/embedded-factory/build.sh` przed `/pack`.
# Mitygacja ( backlog): pre-commit hook auto-detect drift źródło→embedded.
#
# Usage:
#   bash library/embedded-factory/build.sh           # build all
#   bash library/embedded-factory/build.sh --dry-run # preview without writes
#   bash library/embedded-factory/build.sh --check   # parity check only (no rebuild)
#   bash library/embedded-factory/build.sh --verbose # show sed transformations per file

set -euo pipefail

# ──────────────────────────────────────────────────────────────────────
# Setup
# ──────────────────────────────────────────────────────────────────────
FACTORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EMBEDDED_DIR="${FACTORY_ROOT}/library/embedded-factory"
MANIFEST="${EMBEDDED_DIR}/manifest.json"

DRY_RUN=0
CHECK_ONLY=0
VERBOSE=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --check)   CHECK_ONLY=1 ;;
    --verbose) VERBOSE=1 ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

[ ! -f "$MANIFEST" ] && { echo "ERROR: manifest.json not found at $MANIFEST" >&2; exit 1; }

log { printf '[build.sh] %s\n' "$*" >&2; }
verbose { [ "$VERBOSE" = "1" ] && printf '  [verbose] %s\n' "$*" >&2 || true; }

# ──────────────────────────────────────────────────────────────────────
# Helper: apply sed transformations per category
# ──────────────────────────────────────────────────────────────────────
apply_sed_transformations {
  local file="$1"
  local category="$2"  # agents|skills|hooks|commands

  local count=0
  while IFS=$'\t' read -r pattern replacement; do
    [ -z "$pattern" ] && continue
    # Use # as sed delimiter to avoid escaping /
    sed -i "s#${pattern}#${replacement}#g" "$file"
    count=$((count + 1))
    verbose "    sed: '$pattern' → '$replacement' in $file"
  done < <(jq -r --arg cat "$category" '
    .sed_transformations[]
    | select(.applies_to | index($cat))
    | "\(.pattern)\t\(.replacement)"
  ' "$MANIFEST")

  # Catch-all dla agents+skills: wszystkie pozostałe knowledge-base/ paths które
  # NIE są już .claude/knowledge-base/ prefixed. Perl ma lookbehind, sed nie.
  # Łapie np. knowledge-base/self-pilot-reports/, knowledge-base/version-bumper-reports/,
  # knowledge-base/plans/, knowledge-base/evolution-reports/, etc.
  if [ "$category" = "agents" ] || [ "$category" = "skills" ]; then
    if command -v perl >/dev/null 2>&1; then
      perl -i -pe 's#(?<!\.claude/)knowledge-base/#.claude/knowledge-base/#g' "$file"
      count=$((count + 1))
      verbose "    perl catch-all: knowledge-base/ → .claude/knowledge-base/ (with lookbehind guard)"
    else
      verbose "    WARN: perl not found, catch-all skipped for $file"
    fi
  fi

  verbose "    applied $count transformations to $(basename "$file")"
}

# ──────────────────────────────────────────────────────────────────────
# Helper: compute MD5 hash
# ──────────────────────────────────────────────────────────────────────
compute_md5 {
  local file="$1"
  [ -f "$file" ] && md5sum "$file" | awk '{print $1}' || echo ""
}

# ──────────────────────────────────────────────────────────────────────
# Helper: copy + transform + hash one artifact
# ──────────────────────────────────────────────────────────────────────
build_artifact {
  local source_rel="$1"
  local embedded_rel="$2"
  local category="$3"

  local source_abs="${FACTORY_ROOT}/${source_rel}"
  local embedded_abs="${EMBEDDED_DIR}/${embedded_rel}"

  if [ ! -f "$source_abs" ]; then
    log "  SKIP (source missing): $source_rel"
    return 1
  fi

  # Embedded-native artefakt (source == embedded_path) — file written natively
  # do embedded-factory/, NIE kopiujemy from source, tylko hash + skip sed
  # (assume native files są już portable: $CLAUDE_PROJECT_DIR / stdin cwd).
  local is_native=0
  if [ "$source_rel" = "library/embedded-factory/${embedded_rel}" ]; then
    is_native=1
  fi

  if [ "$DRY_RUN" = "1" ]; then
    if [ "$is_native" = "1" ]; then
      log "  DRY: native artefakt $embedded_rel — skip copy/sed, hash only"
    else
      log "  DRY: would copy $source_rel → $embedded_rel + sed transform ($category)"
    fi
    return 0
  fi

  if [ "$is_native" = "1" ]; then
    # Native: nothing to copy, file is already in place
    local hash
    hash=$(compute_md5 "$embedded_abs")
    log "  native: $embedded_rel (hash: ${hash:0:8}...)"
    echo "$hash"
    return 0
  fi

  mkdir -p "$(dirname "$embedded_abs")"

  # Folder-based skill detection: source kończy się na /SKILL.md → cp -r całego dir
  # (companion files jak injection-template.md, retrofit-checklist.md MUSZĄ trafić w paczce)
  # Quality-checker S18 fix dla cross-agent-learning sub-files.
  if [[ "$source_rel" == */SKILL.md ]] && [ "$category" = "skills" ]; then
    local source_dir
    local embedded_dir
    source_dir="$(dirname "$source_abs")"
    embedded_dir="$(dirname "$embedded_abs")"
    # Copy dir contents (preserve subdirs)
    cp -r "$source_dir"/. "$embedded_dir"/
    # Apply sed na każdym .md
    for f in "$embedded_dir"/*.md; do
      [ -f "$f" ] && apply_sed_transformations "$f" "$category"
    done
    local hash
    hash=$(compute_md5 "$embedded_abs")
    local companion_count
    companion_count=$(find "$embedded_dir" -maxdepth 1 -name "*.md" -type f ! -name "SKILL.md" | wc -l | tr -d ' ')
    log "  built (folder): $embedded_rel + $companion_count companion .md files (hash: ${hash:0:8}...)"
    echo "$hash"
    return 0
  fi

  # Single-file copy + sed transform
  cp "$source_abs" "$embedded_abs"
  apply_sed_transformations "$embedded_abs" "$category"

  local hash
  hash=$(compute_md5 "$embedded_abs")
  log "  built: $embedded_rel (hash: ${hash:0:8}...)"
  echo "$hash"
}

# ──────────────────────────────────────────────────────────────────────
# Helper: update manifest.json with hashes + build metadata
# ──────────────────────────────────────────────────────────────────────
update_manifest_hashes {
  local tmp
  tmp=$(mktemp)
  local now
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local build_count
  build_count=$(jq -r '.build_metadata.build_count // 0' "$MANIFEST")
  build_count=$((build_count + 1))
  local factory_ver
  factory_ver=$(jq -r '.version // "unknown"' "${FACTORY_ROOT}/library/library-index.json" 2>/dev/null || echo "unknown")

  jq --arg now "$now" \
     --argjson count "$build_count" \
     --arg factory_ver "$factory_ver" \
    '.generated_at = $now
     | .generator_factory_version = $factory_ver
     | .build_metadata.last_built = $now
     | .build_metadata.build_count = $count' \
    "$MANIFEST" > "$tmp" && mv "$tmp" "$MANIFEST"
}

# ──────────────────────────────────────────────────────────────────────
# Mode: --check parity only
# ──────────────────────────────────────────────────────────────────────
if [ "$CHECK_ONLY" = "1" ]; then
  log "Parity check mode (read-only)..."
  fail=0
  for category in agents skills hooks commands; do
    while IFS=$'\t' read -r embedded_rel stored_hash; do
      [ -z "$embedded_rel" ] || [ "$embedded_rel" = "null" ] && continue
      local_path="${EMBEDDED_DIR}/${embedded_rel}"
      if [ ! -f "$local_path" ]; then
        log "  FAIL: missing $embedded_rel"
        fail=$((fail + 1))
        continue
      fi
      [ "$stored_hash" = "null" ] && continue  # not built yet
      actual_hash=$(compute_md5 "$local_path")
      if [ "$actual_hash" != "$stored_hash" ]; then
        log "  FAIL: hash mismatch $embedded_rel (stored=${stored_hash:0:8} actual=${actual_hash:0:8})"
        fail=$((fail + 1))
      else
        verbose "  OK: $embedded_rel"
      fi
    done < <(jq -r --arg cat "$category" '
      .[$cat][]?
      | [.embedded_path, (.source_hash // "null")]
      | @tsv
    ' "$MANIFEST")
  done
  if [ "$fail" = "0" ]; then
    log "Parity check PASS"
    exit 0
  else
    log "Parity check FAIL ($fail issues)"
    exit 1
  fi
fi

# ──────────────────────────────────────────────────────────────────────
# Mode: full build (default)
# ──────────────────────────────────────────────────────────────────────
log "=== embedded-factory build ==="
log "Factory root: $FACTORY_ROOT"
log "Embedded dir: $EMBEDDED_DIR"
log "Mode: $([ "$DRY_RUN" = "1" ] && echo "DRY-RUN" || echo "LIVE")"
log ""

# Clean: tylko agents/ i skills/ (zawsze copy-from-source).
# Hooks/ i commands/ NIE czyścimy całkowicie — mogą zawierać native artefakty
# (source == embedded_path, np. session-start-embedded.sh). Per-file overwrite
# w build_artifact ma cp -f effect dla non-native, native zachowane.
if [ "$DRY_RUN" = "0" ]; then
  log "Cleaning output dirs (agents/ + skills/ — full clean)..."
  rm -rf "${EMBEDDED_DIR}/agents" "${EMBEDDED_DIR}/skills"
  mkdir -p "${EMBEDDED_DIR}/agents" "${EMBEDDED_DIR}/skills" "${EMBEDDED_DIR}/hooks" "${EMBEDDED_DIR}/commands"

  # Per-file clean dla non-native hooks/commands (żeby usunąć stare copy
  # gdy źródłowy plik został usunięty z library/). Native zachowane.
  while IFS=$'\t' read -r source_rel embedded_rel; do
    [ -z "$source_rel" ] || [ "$source_rel" = "null" ] && continue
    # Skip native
    [ "$source_rel" = "library/embedded-factory/${embedded_rel}" ] && continue
    rm -f "${EMBEDDED_DIR}/${embedded_rel}"
  done < <(jq -r '
    (.hooks[]?, .commands[]?)
    | [.source, .embedded_path]
    | @tsv
  ' "$MANIFEST")
fi

# Build per category
TOTAL_BUILT=0
TOTAL_SKIPPED=0

for category in agents skills hooks commands; do
  log ""
  log "Building $category..."
  while IFS=$'\t' read -r source_rel embedded_rel; do
    [ -z "$source_rel" ] || [ "$source_rel" = "null" ] && continue
    if hash=$(build_artifact "$source_rel" "$embedded_rel" "$category"); then
      if [ "$DRY_RUN" = "0" ] && [ -n "$hash" ]; then
        # Update source_hash in manifest for this artifact
        tmp=$(mktemp)
        jq --arg cat "$category" \
           --arg embedded "$embedded_rel" \
           --arg hash "$hash" \
          '(.[$cat][]? | select(.embedded_path == $embedded) | .source_hash) = $hash' \
          "$MANIFEST" > "$tmp" && mv "$tmp" "$MANIFEST"
      fi
      TOTAL_BUILT=$((TOTAL_BUILT + 1))
    else
      TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1))
    fi
  done < <(jq -r --arg cat "$category" '
    .[$cat][]?
    | [.source, .embedded_path]
    | @tsv
  ' "$MANIFEST")
done

# Update manifest metadata
if [ "$DRY_RUN" = "0" ]; then
  update_manifest_hashes
fi

log ""
log "=== Summary ==="
log "Built:   $TOTAL_BUILT artifacts"
log "Skipped: $TOTAL_SKIPPED artifacts (source missing)"
log "Mode:    $([ "$DRY_RUN" = "1" ] && echo "DRY-RUN (no files written)" || echo "LIVE")"

if [ "$DRY_RUN" = "0" ] && [ "$TOTAL_SKIPPED" -gt 0 ]; then
  log ""
  log "NOTE: $TOTAL_SKIPPED artifacts skipped (sources not yet created)."
  log "      Re-run after creating source files (lite specs, embedded-only files)."
  exit 0
fi

exit 0
