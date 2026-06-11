#!/usr/bin/env bash
# validate-docs.sh — walidacja dokumentacji technicznej
# Wyjście: 0 = OK, 1 = hard fail (blokuje merge), 2 = soft warning only
#
# Zależności: bash >=4, yq v4 (mikefarah), git
# Użycie:
#   ./validate-docs.sh              — hard gates + soft gates
#   ./validate-docs.sh --soft-only  — tylko soft gates (ostrzeżenia)
#   ./validate-docs.sh --warn-only  — wszystko jako warning (retrofit mode)
#
# Zmienne środowiskowe (opcjonalne, z GitHub Actions):
#   PR_BODY    — treść PR (dla hard gate #4: ERD-updated)
#   PR_LABELS  — etykiety PR (dla bypass: emergency-merge)

set -euo pipefail

# ─── Kolory i helpers ─────────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

HARD_FAIL=0
SOFT_WARNINGS=
SOFT_ONLY="${1:-}"
WARN_ONLY="${1:-}"

log_fail    { echo -e "${RED}FAIL${NC}: $1"; HARD_FAIL=1; }
log_warn    { SOFT_WARNINGS+=("$1"); echo -e "${YELLOW}WARN${NC}: $1"; }
log_ok      { echo -e "${GREEN}OK${NC}:   $1"; }

# ─── Wykryj katalog docs/ ─────────────────────────────────────────────────────
DOCS_DIR="docs"
if [ ! -d "$DOCS_DIR" ]; then
  if [ "$SOFT_ONLY" != "--soft-only" ]; then
    log_fail "Katalog docs/ nie istnieje. Utwórz go i dodaj docs/README.md"
  fi
  exit $( [ $HARD_FAIL -eq 1 ] && echo 1 || echo 0 )
fi

ADR_DIR="$DOCS_DIR/adr"
RUNBOOK_DIR="$DOCS_DIR/runbooks"

# ─── Sprawdź czy yq jest dostępne ─────────────────────────────────────────────
if ! command -v yq &>/dev/null; then
  echo "ERROR: yq nie znaleziony. Zainstaluj: https://github.com/mikefarah/yq"
  exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════════
# HARD GATES (blokują merge)
# ═══════════════════════════════════════════════════════════════════════════════

if [ "$SOFT_ONLY" != "--soft-only" ]; then

  echo ""
  echo "=== HARD GATES ==="

  # ── Hard Gate #1: ADR front-matter status wymagany i w enum ─────────────────
  if [ -d "$ADR_DIR" ]; then
    while IFS= read -r -d '' adr_file; do
      # Wyodrębnij front-matter (między pierwszymi ---)
      frontmatter=$(awk '/^---/{if(++c==2) exit} c>=1' "$adr_file" 2>/dev/null || true)

      if [ -z "$frontmatter" ]; then
        log_fail "Brak YAML front-matter w $adr_file"
        continue
      fi

      status=$(echo "$frontmatter" | yq '.status // ""' 2>/dev/null || echo "")

      if [ -z "$status" ] || [ "$status" = "null" ]; then
        log_fail "Brak 'status' w front-matter: $adr_file"
        continue
      fi

      # Sprawdź enum: proposed | accepted | deprecated | superseded-by-ADR-*
      if ! echo "$status" | grep -qE '^(proposed|accepted|deprecated|superseded-by-ADR-[0-9]+)$'; then
        log_fail "Nieprawidłowa wartość 'status: $status' w $adr_file (dozwolone: proposed|accepted|deprecated|superseded-by-ADR-NNNN)"
      else
        log_ok "ADR status OK: $adr_file ($status)"
      fi

    done < <(find "$ADR_DIR" -name "*.md" -print0 2>/dev/null)
  else
    log_warn "Katalog $ADR_DIR nie istnieje — pomijam walidację ADR"
  fi

  # ── Hard Gate #2: Runbook front-matter severity wymagany i w enum ────────────
  if [ -d "$RUNBOOK_DIR" ]; then
    while IFS= read -r -d '' rb_file; do
      # Pomiń pliki pomocnicze (README, _shared-*)
      basename_rb=$(basename "$rb_file")
      if [[ "$basename_rb" == "README.md" ]] || [[ "$basename_rb" == _shared-* ]]; then
        continue
      fi

      frontmatter=$(awk '/^---/{if(++c==2) exit} c>=1' "$rb_file" 2>/dev/null || true)

      if [ -z "$frontmatter" ]; then
        log_fail "Brak YAML front-matter w $rb_file"
        continue
      fi

      severity=$(echo "$frontmatter" | yq '.severity // ""' 2>/dev/null || echo "")

      if [ -z "$severity" ] || [ "$severity" = "null" ]; then
        log_fail "Brak 'severity' w front-matter: $rb_file"
        continue
      fi

      if ! echo "$severity" | grep -qE '^(p0|p1|p2|p3)$'; then
        log_fail "Nieprawidłowa wartość 'severity: $severity' w $rb_file (dozwolone: p0|p1|p2|p3)"
      else
        log_ok "Runbook severity OK: $rb_file ($severity)"
      fi

    done < <(find "$RUNBOOK_DIR" -name "*.md" -not -name "_shared-*" -print0 2>/dev/null)
  else
    log_warn "Katalog $RUNBOOK_DIR nie istnieje — pomijam walidację runbooków"
  fi

  # ── Hard Gate #3: Broken internal links w docs/ ───────────────────────────────
  echo ""
  echo "--- Sprawdzam broken internal links ---"

  while IFS= read -r -d '' md_file; do
    # Wyodrębnij linki Markdown [text](path) — tylko ścieżki lokalne (nie http/https/#)
    while IFS= read -r link; do
      # Pomiń linki zewnętrzne i kotwice
      if echo "$link" | grep -qE '^https?://|^#|^mailto:'; then
        continue
      fi

      # Zbuduj ścieżkę absolutną od pliku
      dir_of_file=$(dirname "$md_file")
      full_path="$dir_of_file/$link"

      # Normalizuj ścieżkę (usuń ../ itp.)
      normalized=$(realpath -m "$full_path" 2>/dev/null || echo "$full_path")

      if [ ! -f "$normalized" ] && [ ! -d "$normalized" ]; then
        log_fail "Broken link w $md_file: [$link] → $normalized nie istnieje"
      fi

    done < <(grep -oP '\[([^\]]+)\]\(\K[^)]+(?=\))' "$md_file" 2>/dev/null || true)

  done < <(find "$DOCS_DIR" -name "*.md" -print0 2>/dev/null)

  # ── Hard Gate #4: Schema/migration change bez ERD update ─────────────────────
  echo ""
  echo "--- Sprawdzam schema/migration changes ---"

  # Wykryj zmienione pliki (CI: git diff; lokalnie: git status)
  CHANGED_FILES_LIST=""
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    # W CI: porównaj z base branch
    BASE_BRANCH="${GITHUB_BASE_REF:-main}"
    CHANGED_FILES_LIST=$(git diff --name-only "origin/$BASE_BRANCH...HEAD" 2>/dev/null || git diff --name-only HEAD~1..HEAD 2>/dev/null || true)
  fi

  SCHEMA_CHANGED=0
  if echo "$CHANGED_FILES_LIST" | grep -qE '(schema\.sql|\.sql$|migrations/|prisma/schema\.prisma)'; then
    SCHEMA_CHANGED=1
  fi

  ARCH_TOUCHED=0
  if echo "$CHANGED_FILES_LIST" | grep -q "docs/architecture/"; then
    ARCH_TOUCHED=1
  fi

  ERD_UPDATED_IN_PR=0
  PR_BODY_CONTENT="${PR_BODY:-}"
  if echo "$PR_BODY_CONTENT" | grep -qE 'ERD-updated:\s*(yes|n/a)'; then
    ERD_UPDATED_IN_PR=1
  fi

  if [ "$SCHEMA_CHANGED" -eq 1 ]; then
    if [ "$ARCH_TOUCHED" -eq 0 ] && [ "$ERD_UPDATED_IN_PR" -eq 0 ]; then
      log_fail "Schema/migration zmieniona bez aktualizacji docs/architecture/ i bez 'ERD-updated: yes|n/a' w PR body"
      echo "  Dodaj 'ERD-updated: yes' (zaktualizowano ERD) lub 'ERD-updated: n/a' (zmiana nie wpływa na ERD) w opisie PR."
    else
      log_ok "Schema change — ERD update potwierdzony"
    fi
  fi

fi  # end HARD GATES

# ═══════════════════════════════════════════════════════════════════════════════
# SOFT GATES (ostrzeżenia, nie blokują)
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo "=== SOFT GATES ==="

TODAY=$(date +%s)
TWELVE_MONTHS_AGO=$(( TODAY - 365 * 24 * 3600 ))
NINETY_DAYS_AGO=$(( TODAY - 90 * 24 * 3600 ))

# ── Soft Gate #1: ADR accepted > 12 miesięcy bez last_reviewed update ─────────
if [ -d "$ADR_DIR" ]; then
  while IFS= read -r -d '' adr_file; do
    frontmatter=$(awk '/^---/{if(++c==2) exit} c>=1' "$adr_file" 2>/dev/null || true)
    [ -z "$frontmatter" ] && continue

    status=$(echo "$frontmatter" | yq '.status // ""' 2>/dev/null || echo "")
    last_reviewed=$(echo "$frontmatter" | yq '.last_reviewed // ""' 2>/dev/null || echo "")

    if [ "$status" = "accepted" ] && [ -n "$last_reviewed" ] && [ "$last_reviewed" != "null" ]; then
      reviewed_ts=$(date -d "$last_reviewed" +%s 2>/dev/null || echo 0)
      if [ "$reviewed_ts" -lt "$TWELVE_MONTHS_AGO" ]; then
        log_warn "ADR $adr_file: status=accepted ale last_reviewed=$last_reviewed (>12 miesięcy temu). Rozważ przegląd."
      fi
    elif [ "$status" = "accepted" ] && ( [ -z "$last_reviewed" ] || [ "$last_reviewed" = "null" ] ); then
      log_warn "ADR $adr_file: status=accepted bez pola last_reviewed"
    fi

  done < <(find "$ADR_DIR" -name "*.md" -print0 2>/dev/null)
fi

# ── Soft Gate #2: Orphan ADR kind:infrastructure bez runbooka w related ────────
if [ -d "$ADR_DIR" ]; then
  while IFS= read -r -d '' adr_file; do
    frontmatter=$(awk '/^---/{if(++c==2) exit} c>=1' "$adr_file" 2>/dev/null || true)
    [ -z "$frontmatter" ] && continue

    kind=$(echo "$frontmatter" | yq '.kind // ""' 2>/dev/null || echo "")
    related=$(echo "$frontmatter" | yq '.related // [] | length' 2>/dev/null || echo "0")

    if [ "$kind" = "infrastructure" ]; then
      # Sprawdź czy w related jest jakiś plik z runbooks/
      has_runbook=$(echo "$frontmatter" | yq '.related // [] | .[] | select(contains("runbook"))' 2>/dev/null || true)
      if [ -z "$has_runbook" ] && [ "$related" -eq 0 ]; then
        log_warn "ADR $adr_file: kind=infrastructure bez powiązanego runbooka w 'related'. Patrz references/adr-runbook-pairing.md"
      fi
    fi

  done < <(find "$ADR_DIR" -name "*.md" -print0 2>/dev/null)
fi

# ── Soft Gate #3: docs/README.md niezmieniony > 90 dni ────────────────────────
DOCS_README="$DOCS_DIR/README.md"
if [ -f "$DOCS_README" ]; then
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    last_commit_ts=$(git log -1 --format="%ct" -- "$DOCS_README" 2>/dev/null || echo 0)
    if [ "$last_commit_ts" -gt 0 ] && [ "$last_commit_ts" -lt "$NINETY_DAYS_AGO" ]; then
      last_date=$(git log -1 --format="%ci" -- "$DOCS_README" 2>/dev/null || echo "nieznana")
      log_warn "$DOCS_README niezmieniony od $last_date (>90 dni). Zaktualizuj mapę dokumentacji."
    fi
  fi
else
  log_fail "Brak $DOCS_README — wymagany hard gate. Utwórz plik z mapą dokumentacji."
  # To faktycznie hard gate (brak indeksu = hard fail) ale umieszczamy tutaj jako fallback
  HARD_FAIL=1
fi

# ── Soft Gate #4: Nowe endpointy bez docs/api/ touched (L2+) ──────────────────
# Sprawdź tylko jeśli projekt używa L2+ (heurystyka: docs/api/ istnieje)
if [ -d "$DOCS_DIR/api" ]; then
  API_TOUCHED=0
  if echo "$CHANGED_FILES_LIST" | grep -q "docs/api/"; then
    API_TOUCHED=1
  fi

  # Heurystyka: wykryj nowe endpointy w diff (proste — patrz na dodane linie z /api/ lub router.get/post)
  NEW_ENDPOINTS=0
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    BASE_BRANCH="${GITHUB_BASE_REF:-main}"
    endpoint_diff=$(git diff "origin/$BASE_BRANCH...HEAD" 2>/dev/null | grep -E '^\+.*(app\.(get|post|put|delete|patch)|router\.(get|post|put|delete|patch)|@(Get|Post|Put|Delete|Patch))' | grep -v '^+++' || true)
    if [ -n "$endpoint_diff" ]; then
      NEW_ENDPOINTS=1
    fi
  fi

  if [ "$NEW_ENDPOINTS" -eq 1 ] && [ "$API_TOUCHED" -eq 0 ]; then
    log_warn "Wykryto potencjalnie nowe endpointy API bez zmian w docs/api/. Zaktualizuj docs/api/README.md (L2+ requirement)."
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Podsumowanie
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo "=== PODSUMOWANIE ==="

if [ ${#SOFT_WARNINGS[@]} -gt 0 ]; then
  echo -e "${YELLOW}Soft warnings: ${#SOFT_WARNINGS[@]}${NC}"
fi

if [ "$WARN_ONLY" = "--warn-only" ]; then
  echo "Tryb warn-only (retrofit) — hard fails traktowane jako ostrzeżenia"
  exit 0
fi

if [ "$HARD_FAIL" -eq 1 ]; then
  echo -e "${RED}HARD FAIL — merge zablokowany.${NC}"
  echo "Bypass: dodaj label 'emergency-merge' + 'TECH-DEBT: <opis>' w PR body + wpis w docs/TECH_DEBT.md"
  exit 1
fi

if [ ${#SOFT_WARNINGS[@]} -gt 0 ]; then
  echo -e "${GREEN}Hard gates: OK${NC} | ${YELLOW}Soft warnings: ${#SOFT_WARNINGS[@]}${NC}"
  exit 2
fi

echo -e "${GREEN}Wszystkie walidacje OK.${NC}"
exit 0
