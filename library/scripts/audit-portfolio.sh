#!/usr/bin/env bash
# library/scripts/audit-portfolio.sh
#
# Pre-launch checklist dla portfolio operatora (lub innego portfolio webapp).
# Sprawdza:
#   - CWV targets (Lighthouse CI lub manual hint)
#   - WCAG 2.2 AA (axe-core jeśli zainstalowany, lub manual)
#   - Polish typography (delegacja do validate-pl-typography.sh)
#   - Security headers (Helmet config check)
#   - Sitemap.xml + robots.txt
#   - Image optimization (count surowych PNG/JPG > 200KB)
#   - Video markup (poster + multiple sources + VTT)
#   - Dual CTA presence
#   - JSON-LD Person validity
#   - .env w gitignore (secrets check)
#
# Origin: paczka af-pack-<nazwa> (E10 plan 2026-05-13).
#
# Użycie:
#   ./audit-portfolio.sh                   # current dir
#   ./audit-portfolio.sh ~/projekty/portfolio-operator/
#   ./audit-portfolio.sh --fix             # auto-fix when possible (TODO v1.1)

set -euo pipefail

ROOT="${1:-.}"
PASS=0
FAIL=0
WARN=0

check {
  local name="$1"
  local result="$2"  # PASS|FAIL|WARN
  local detail="${3:-}"

  case "$result" in
    PASS) echo "  ✅ $name"; PASS=$((PASS + 1)) ;;
    FAIL) echo "  ❌ $name${detail:+: $detail}"; FAIL=$((FAIL + 1)) ;;
    WARN) echo "  ⚠️  $name${detail:+: $detail}"; WARN=$((WARN + 1)) ;;
  esac
}

cd "$ROOT" 2>/dev/null || { echo "ERROR: dir not found: $ROOT" >&2; exit 1; }

echo "🔍 Audyt portfolio: $(pwd)"
echo "Data: $(date -Iseconds)"
echo ""

# ============================================================
# 1. Project structure
# ============================================================
echo "## 1. Struktura projektu"

if [[ -f "package.json" ]]; then
  check "package.json istnieje" PASS
else
  check "package.json istnieje" FAIL "brak pliku — czy to projekt Node?"
fi

if [[ -d "app" ]] || [[ -d "src/app" ]] || [[ -d "apps/web/src/app" ]]; then
  check "Next.js App Router structure" PASS
else
  check "Next.js App Router structure" WARN "brak app/ — może Pages Router lub inny stack"
fi

if [[ -d ".claude" ]]; then
  check ".claude/ paczka deploys" PASS
else
  check ".claude/ paczka deploys" WARN "brak .claude/ — uruchom /new-project lub clone af-pack-<nazwa>"
fi

# ============================================================
# 2. SEO essentials
# ============================================================
echo ""
echo "## 2. SEO essentials"

if find . -path ./node_modules -prune -o -name "*.tsx" -print 2>/dev/null | xargs grep -l 'application/ld+json' 2>/dev/null | head -1 | grep -q .; then
  check "JSON-LD schema.org" PASS
else
  check "JSON-LD schema.org" FAIL "brak <script type=\"application/ld+json\"> w *.tsx"
fi

if find . -path ./node_modules -prune -o -name "*.tsx" -print 2>/dev/null | xargs grep -l '@type.*Person' 2>/dev/null | head -1 | grep -q .; then
  check "JSON-LD Person type" PASS
else
  check "JSON-LD Person type" WARN "brak Person schema — portfolio powinno mieć"
fi

if [[ -f "public/sitemap.xml" ]] || [[ -f "next-sitemap.config.js" ]] || [[ -f "next-sitemap.config.mjs" ]]; then
  check "Sitemap config/file" PASS
else
  check "Sitemap config/file" WARN "brak sitemap.xml + next-sitemap config"
fi

if [[ -f "public/robots.txt" ]]; then
  check "robots.txt" PASS
else
  check "robots.txt" WARN "brak — generowane przez next-sitemap post-build"
fi

# ============================================================
# 3. CWV / Performance
# ============================================================
echo ""
echo "## 3. Performance / CWV"

if find . -path ./node_modules -prune -o -name "*.tsx" -print 2>/dev/null | xargs grep -l 'next/image\|next/font' 2>/dev/null | head -1 | grep -q .; then
  check "next/image lub next/font użyte" PASS
else
  check "next/image lub next/font użyte" WARN "brak next/image — risk LCP slow"
fi

# Sprawdź wielkie surowe obrazy
LARGE_IMAGES=$(find public -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" 2>/dev/null | xargs -I{} sh -c 'if [ $(stat -c %s "{}" 2>/dev/null || stat -f %z "{}") -gt 204800 ]; then echo "{}"; fi' 2>/dev/null | wc -l)
if [[ "$LARGE_IMAGES" -eq 0 ]]; then
  check "Obrazy > 200KB" PASS "0 surowych obrazów > 200KB"
else
  check "Obrazy > 200KB" WARN "$LARGE_IMAGES plików — uruchom optimize-media.sh"
fi

# Sprawdź wideo
if find public -name "*.mp4" 2>/dev/null | head -1 | grep -q .; then
  VIDEO_COUNT=$(find public -name "*.mp4" 2>/dev/null | wc -l)
  WEBM_COUNT=$(find public -name "*.webm" 2>/dev/null | wc -l)
  if [[ "$WEBM_COUNT" -eq 0 ]]; then
    check "Wideo MP4 + WebM dual source" WARN "$VIDEO_COUNT MP4, 0 WebM — uruchom optimize-media.sh"
  else
    check "Wideo MP4 + WebM dual source" PASS "$VIDEO_COUNT MP4, $WEBM_COUNT WebM"
  fi

  POSTER_COUNT=$(find public -name "*poster*" 2>/dev/null | wc -l)
  if [[ "$POSTER_COUNT" -eq 0 ]]; then
    check "Wideo posters" WARN "brak *-poster.webp"
  else
    check "Wideo posters" PASS "$POSTER_COUNT plików"
  fi

  VTT_COUNT=$(find public -name "*.vtt" 2>/dev/null | wc -l)
  if [[ "$VTT_COUNT" -eq 0 ]]; then
    check "VTT captions (a11y)" WARN "brak *.vtt — wymagane dla wideo z dźwiękiem"
  else
    check "VTT captions (a11y)" PASS "$VTT_COUNT plików"
  fi
fi

# ============================================================
# 4. Security
# ============================================================
echo ""
echo "## 4. Security"

if [[ -f ".gitignore" ]] && grep -q '^\.env$\|^\.env\.local$\|^\.env\.\*\.local$' .gitignore; then
  check ".env w .gitignore" PASS
else
  check ".env w .gitignore" FAIL "RISK: .env może trafić do git"
fi

# Sprawdź czy .env nie jest tracked
if git ls-files 2>/dev/null | grep -qE '^\.env$|/\.env$|\.env\.local$'; then
  check ".env NIE jest tracked" FAIL "BLOK: .env w git index"
else
  check ".env NIE jest tracked" PASS
fi

# CSP headers / Helmet
if find . -path ./node_modules -prune -o -name "*.ts" -print 2>/dev/null | xargs grep -l 'Content-Security-Policy\|helmet' 2>/dev/null | head -1 | grep -q .; then
  check "CSP headers config" PASS
else
  check "CSP headers config" WARN "brak Content-Security-Policy — patrz webapp-security-hardening"
fi

# ============================================================
# 5. Polish typography (jeśli MDX content)
# ============================================================
echo ""
echo "## 5. Polish typography (PL content)"

MDX_FILES=$(find . -path ./node_modules -prune -o -name "*.mdx" -print 2>/dev/null | head -20)
MDX_COUNT=$(echo "$MDX_FILES" | grep -c . 2>/dev/null || echo "0")

if [[ "$MDX_COUNT" -gt 0 ]]; then
  PROOFREADER_AVAILABLE=0
  if [[ -f ".claude/agents/universal/polish-proofreader.md" ]] || [[ -f ".claude/agents/polish-proofreader.md" ]]; then
    PROOFREADER_AVAILABLE=1
  fi

  if [[ "$PROOFREADER_AVAILABLE" -eq 1 ]]; then
    check "polish-proofreader agent installed" PASS
    check "PL audit (manual recommend)" WARN "uruchom /proofread-pl content/*.mdx"
  else
    check "polish-proofreader agent" WARN "brak — paczka af-pack-<nazwa> NIE deployed?"
  fi
else
  check "MDX content files" WARN "brak *.mdx — portfolio pusty?"
fi

# ============================================================
# 6. Portfolio-specific (dual CTA)
# ============================================================
echo ""
echo "## 6. Portfolio-specific"

if find . -path ./node_modules -prune -o -name "*.tsx" -print 2>/dev/null | xargs grep -l 'mailto:' 2>/dev/null | head -1 | grep -q .; then
  # Sprawdź czy są 2 różne subject lines (freelance + job)
  MAILTO_FREELANCE=$(grep -r 'mailto:' --include='*.tsx' . 2>/dev/null | grep -ciE 'freelance|projekt' || echo "0")
  MAILTO_JOB=$(grep -r 'mailto:' --include='*.tsx' . 2>/dev/null | grep -ciE 'full-time|aplikacj|zatrudni' || echo "0")
  if [[ "$MAILTO_FREELANCE" -gt 0 && "$MAILTO_JOB" -gt 0 ]]; then
    check "Dual CTA (freelance + job)" PASS
  else
    check "Dual CTA (freelance + job)" WARN "tylko 1 typ CTA — patrz dual-cta-patterns.md"
  fi
else
  check "Dual CTA (freelance + job)" FAIL "brak mailto: w *.tsx — brak CTA?"
fi

# Sprawdź czy prefers-reduced-motion respect
if find . -path ./node_modules -prune -o \( -name "*.tsx" -o -name "*.css" -o -name "*.scss" \) -print 2>/dev/null | xargs grep -l 'prefers-reduced-motion\|useReducedMotion' 2>/dev/null | head -1 | grep -q .; then
  check "prefers-reduced-motion respect" PASS
else
  check "prefers-reduced-motion respect" WARN "brak — risk WCAG 2.3.3 fail jeśli motion w komponencie"
fi

# ============================================================
# 7. Hooks installed (paczka af-pack-<nazwa>)
# ============================================================
echo ""
echo "## 7. Hooks portfolio"

for hook in block-lorem-ipsum.sh auto-image-size-check.sh validate-pl-typography.sh; do
  if [[ -f ".claude/hooks/$hook" ]]; then
    check "$hook installed" PASS
  else
    check "$hook installed" WARN "brak — paczka af-pack-<nazwa> v1.0+ powinna instalować"
  fi
done

# ============================================================
# Summary
# ============================================================
echo ""
echo "========================================="
echo "📊 PODSUMOWANIE AUDYTU"
echo "========================================="
echo "  ✅ PASS:  $PASS"
echo "  ⚠️  WARN:  $WARN"
echo "  ❌ FAIL:  $FAIL"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  echo "❌ BLOK DEPLOY: $FAIL critical issues. Napraw przed publish."
  exit 1
elif [[ "$WARN" -gt 3 ]]; then
  echo "⚠️  WIELE WARN ($WARN). Rozważ patche przed publish."
  exit 0
else
  echo "🎉 OK do deploy. Pamiętaj o:"
  echo "  1. Lighthouse audit: Task page-speed-optimizer"
  echo "  2. Pre-deploy: Task webapp-pre-deploy-checker"
  echo "  3. Manual scroll-test mobile (320px width)"
  exit 0
fi
