#!/usr/bin/env bash
# audit-ready-check.sh — 18 checków zasady #15 CLAUDE.md L173
# BLOKER `gh repo create` dla paczek webapp produkcyjnych (--audit-scope=production)
# Wprowadzony .C.E3 (2026-05-29) po POST-MORTEM  fundamental error
#
# Usage:
#   bash audit-ready-check.sh --pack=<path> --scope=production|minimal
#   bash audit-ready-check.sh --pack=/tmp/test --scope=production
#
# Output: JSON na stdout (parsed by pack-agent v2.1+ Krok 7.6)
#
# Exit codes:
#   0  — all checks PASS (verdict: PASS)
#   1  — one or more checks FAIL (verdict: FAIL)
#   2  — invalid arguments
#
# Schema output (zasada #10 CLAUDE.md kontrakt):
#   {
#     "scope": "production|minimal",
#     "passed": N,
#     "failed": M,
#     "total": 18,
#     "items": [{"id": N, "name": "...", "status": "PASS|FAIL", "evidence": "...", "fix_hint": "..."}],
#     "verdict": "PASS|FAIL",
#     "skill_mapping": "library/skills/webapp/webapp-*"
#   }

set -u  # NIE -e — chcemy full scan, nie fail-fast

PACK=""
SCOPE="production"

# Parse args
for arg in "$@"; do
  case "$arg" in
    --pack=*) PACK="${arg#*=}" ;;
    --scope=*) SCOPE="${arg#*=}" ;;
    --help|-h)
      echo "Usage: $0 --pack=<path> --scope=production|minimal"
      exit 0
      ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

if [ -z "$PACK" ]; then
  echo '{"error": "missing --pack=<path>", "verdict": "FAIL"}' >&2
  exit 2
fi

if [ "$SCOPE" != "production" ] && [ "$SCOPE" != "minimal" ]; then
  echo '{"error": "--scope must be production|minimal", "verdict": "FAIL"}' >&2
  exit 2
fi

if [ ! -d "$PACK" ]; then
  echo "{\"error\": \"path not found: $PACK\", \"verdict\": \"FAIL\"}" >&2
  exit 2
fi

# Helper — sprawdź istnienie pliku z minimum N linii konkretnej treści
check_file_min_lines {
  local file="$1"
  local min_lines="$2"
  if [ ! -f "$file" ]; then return 1; fi
  local actual_lines
  actual_lines=$(wc -l < "$file" 2>/dev/null || echo 0)
  [ "$actual_lines" -ge "$min_lines" ]
}

# Helper — sprawdź pattern w pliku
check_pattern_in_file {
  local file="$1"
  local pattern="$2"
  [ -f "$file" ] && grep -q "$pattern" "$file"
}

# Init results
ITEMS=
PASSED=0
FAILED=0

# Helper — dodaj wynik check
add_check {
  local id="$1"
  local name="$2"
  local status="$3"
  local evidence="$4"
  local fix_hint="$5"

  # Skip checki 7-18 dla scope=minimal
  if [ "$SCOPE" = "minimal" ] && [ "$id" -gt 6 ]; then
    return
  fi

  if [ "$status" = "PASS" ]; then
    PASSED=$((PASSED + 1))
  else
    FAILED=$((FAILED + 1))
  fi

  # Escape JSON strings
  name=$(echo "$name" | sed 's/"/\\"/g')
  evidence=$(echo "$evidence" | sed 's/"/\\"/g')
  fix_hint=$(echo "$fix_hint" | sed 's/"/\\"/g')

  ITEMS+=("{\"id\":$id,\"name\":\"$name\",\"status\":\"$status\",\"evidence\":\"$evidence\",\"fix_hint\":\"$fix_hint\"}")
}

# =========================================================================
# CHECK 1: Dockerfile multi-stage + .dockerignore (paczka: templates / apka: pliki fizyczne)
# =========================================================================
DOCKER_TEMPLATE_DIR="$PACK/.claude/skills/webapp-docker-templates/templates"
if check_file_min_lines "$PACK/Dockerfile" 30 && \
   check_pattern_in_file "$PACK/Dockerfile" "FROM.*AS " && \
   check_file_min_lines "$PACK/.dockerignore" 10; then
  add_check 1 "Dockerfile multi-stage + .dockerignore" "PASS" \
    "$PACK/Dockerfile + .dockerignore" ""
elif check_file_min_lines "$DOCKER_TEMPLATE_DIR/Dockerfile.template" 30 && \
     check_pattern_in_file "$DOCKER_TEMPLATE_DIR/Dockerfile.template" "FROM.*AS " && \
     check_file_min_lines "$DOCKER_TEMPLATE_DIR/dockerignore.template" 10; then
  add_check 1 "Dockerfile multi-stage + .dockerignore (templates available)" "PASS" \
    "templates w embedded webapp-docker-templates skillu" ""
else
  add_check 1 "Dockerfile multi-stage + .dockerignore" "FAIL" \
    "missing files and templates" \
    "Apply webapp-docker-templates: cp Dockerfile.template + dockerignore.template"
fi

# =========================================================================
# CHECK 2: docker-compose dev + prod + entrypoint (paczka: templates / apka: pliki fizyczne)
# =========================================================================
if check_file_min_lines "$PACK/compose.yml" 40 && \
   check_file_min_lines "$PACK/compose.prod.yml" 30 && \
   check_file_min_lines "$PACK/entrypoint.sh" 20 && \
   check_pattern_in_file "$PACK/entrypoint.sh" "prisma migrate deploy"; then
  add_check 2 "docker-compose dev/prod + entrypoint z migrations" "PASS" \
    "$PACK/compose*.yml + entrypoint.sh" ""
elif check_file_min_lines "$DOCKER_TEMPLATE_DIR/compose.yml.template" 40 && \
     check_file_min_lines "$DOCKER_TEMPLATE_DIR/compose.prod.yml.template" 30 && \
     check_file_min_lines "$DOCKER_TEMPLATE_DIR/entrypoint.sh.template" 20 && \
     check_pattern_in_file "$DOCKER_TEMPLATE_DIR/entrypoint.sh.template" "prisma migrate deploy"; then
  add_check 2 "docker-compose dev/prod + entrypoint (templates available)" "PASS" \
    "templates w embedded webapp-docker-templates skillu" ""
else
  add_check 2 "docker-compose dev/prod + entrypoint z migrations" "FAIL" \
    "missing files and templates" \
    "Apply webapp-docker-templates: cp compose.yml.template + compose.prod.yml.template + entrypoint.sh.template"
fi

# =========================================================================
# CHECK 3: Healthcheck endpoints /api/health /ready /version
# =========================================================================
HC_DIR="$PACK/app/api"
[ ! -d "$HC_DIR" ] && HC_DIR="$PACK/src/app/api"
HC_PATTERN_HEALTH=""
HC_PATTERN_READY=""
HC_PATTERN_VERSION=""
if [ -d "$HC_DIR/health" ] || [ -d "$HC_DIR/ready" ]; then
  HC_PATTERN_HEALTH=$([ -f "$HC_DIR/health/route.ts" ] && echo "ok")
  HC_PATTERN_READY=$([ -f "$HC_DIR/ready/route.ts" ] && echo "ok")
  HC_PATTERN_VERSION=$([ -f "$HC_DIR/version/route.ts" ] && echo "ok")
fi
# Allow template reference w paczce (templates/healthcheck-routes.md.template)
if [ -n "$HC_PATTERN_HEALTH" ] && [ -n "$HC_PATTERN_READY" ] && [ -n "$HC_PATTERN_VERSION" ]; then
  add_check 3 "Healthcheck endpoints /api/health /ready /version" "PASS" \
    "$HC_DIR/{health,ready,version}/route.ts" ""
elif [ -f "$PACK/templates/healthcheck-routes.md.template" ] || [ -f "$PACK/.claude/skills/webapp-observability-stack/templates/healthcheck-routes.ts.template" ]; then
  add_check 3 "Healthcheck endpoints (template available, NIE implemented)" "PASS" \
    "template available, apka klienta implementuje" ""
else
  add_check 3 "Healthcheck endpoints /api/health /ready /version" "FAIL" \
    "no route.ts and no template" \
    "Apply webapp-observability-stack templates/healthcheck-routes.ts.template"
fi

# =========================================================================
# CHECK 4: GH Actions ci.yml + cd.yml + security.yml (>30l each)
# =========================================================================
WF_DIR="$PACK/.github/workflows"
WF_TEMPLATE_DIR="$PACK/.claude/skills/webapp-ci-cd-workflows/templates"
WF_FOUND=0
if check_file_min_lines "$WF_DIR/ci.yml" 30 && \
   check_file_min_lines "$WF_DIR/cd.yml" 30 && \
   check_file_min_lines "$WF_DIR/security.yml" 30; then
  WF_FOUND=1
elif check_file_min_lines "$WF_TEMPLATE_DIR/ci.yml.template" 30 && \
     check_file_min_lines "$WF_TEMPLATE_DIR/cd.yml.template" 30 && \
     check_file_min_lines "$WF_TEMPLATE_DIR/security.yml.template" 30; then
  WF_FOUND=1
fi
if [ "$WF_FOUND" = "1" ]; then
  add_check 4 "GH Actions ci.yml + cd.yml + security.yml" "PASS" \
    "workflows or templates available" ""
else
  add_check 4 "GH Actions ci.yml + cd.yml + security.yml" "FAIL" \
    "missing .github/workflows or templates" \
    "Apply webapp-ci-cd-workflows: cp ci.yml.template + cd.yml.template + security.yml.template"
fi

# =========================================================================
# CHECK 5: Structured logging pino JSON
# =========================================================================
if check_file_min_lines "$PACK/lib/logger.ts" 20 && \
   check_pattern_in_file "$PACK/lib/logger.ts" "pino"; then
  add_check 5 "Structured logging pino JSON" "PASS" "$PACK/lib/logger.ts" ""
elif [ -f "$PACK/.claude/skills/webapp-observability-stack/templates/pino.config.ts.template" ]; then
  add_check 5 "Structured logging pino JSON (template available)" "PASS" \
    "template w embedded skillu" ""
else
  add_check 5 "Structured logging pino JSON" "FAIL" \
    "no lib/logger.ts and no pino template" \
    "Apply webapp-observability-stack templates/pino.config.ts.template"
fi

# =========================================================================
# CHECK 6: Error tracking Sentry SaaS
# =========================================================================
if [ -f "$PACK/sentry.server.config.ts" ] || \
   [ -f "$PACK/.claude/skills/webapp-observability-stack/templates/sentry.server.config.ts.template" ]; then
  add_check 6 "Error tracking Sentry (SaaS or self-hosted)" "PASS" \
    "sentry config or template" ""
else
  add_check 6 "Error tracking Sentry (SaaS or self-hosted)" "FAIL" \
    "no sentry config and no template" \
    "Apply webapp-observability-stack templates/sentry.server.config.ts.template + sentry.client.config.ts.template"
fi

# =========================================================================
# Skip checks 7-18 dla scope=minimal
# =========================================================================
if [ "$SCOPE" = "minimal" ]; then
  TOTAL=6
else
  TOTAL=18

  # CHECK 7: Metrics endpoint (path) - prom or healthcheck /metrics stub
  if [ -f "$PACK/app/api/metrics/route.ts" ] || \
     [ -f "$PACK/.claude/skills/webapp-observability-stack/templates/healthcheck-routes.ts.template" ]; then
    add_check 7 "Metrics endpoint /metrics (path lub stub v2)" "PASS" "ok" ""
  else
    add_check 7 "Metrics endpoint /metrics (path lub stub v2)" "FAIL" "missing" \
      "Add /api/metrics/route.ts stub (v2 Prometheus expansion)"
  fi

  # CHECK 8: pg_dump backup + retention + B2 + restore drill
  BACKUP_OK=0
  if [ -f "$PACK/.claude/skills/webapp-backup-dr/templates/pg-dump-cron.sh.template" ] && \
     [ -f "$PACK/.claude/skills/webapp-backup-dr/templates/restore-drill.sh.template" ]; then
    BACKUP_OK=1
  fi
  if [ "$BACKUP_OK" = "1" ]; then
    add_check 8 "pg_dump daily + retention + B2 + restore drill" "PASS" \
      "templates webapp-backup-dr present" ""
  else
    add_check 8 "pg_dump daily + retention + B2 + restore drill" "FAIL" \
      "missing backup templates" \
      "Apply webapp-backup-dr: 6 templates (pg-dump + rclone + retention + restore-drill + sidecar dockerfile + B2 setup)"
  fi

  # CHECK 9: Reverse proxy auto-TLS Let's Encrypt
  if [ -f "$PACK/Caddyfile" ] || \
     [ -f "$PACK/.claude/skills/webapp-reverse-proxy-tls/templates/Caddyfile.template" ]; then
    add_check 9 "Reverse proxy Caddy auto-TLS Let's Encrypt" "PASS" "Caddyfile or template" ""
  else
    add_check 9 "Reverse proxy Caddy auto-TLS Let's Encrypt" "FAIL" "missing" \
      "Apply webapp-reverse-proxy-tls templates/Caddyfile.template"
  fi

  # CHECK 10: CSP headers konkretne
  if [ -f "$PACK/middleware.ts" ] || \
     [ -f "$PACK/.claude/skills/webapp-reverse-proxy-tls/templates/nextjs-middleware-csp.ts.template" ]; then
    add_check 10 "CSP headers konkretne w middleware" "PASS" "middleware or template" ""
  else
    add_check 10 "CSP headers konkretne w middleware" "FAIL" "missing CSP" \
      "Apply webapp-reverse-proxy-tls templates/nextjs-middleware-csp.ts.template"
  fi

  # CHECK 11: SBOM cyclonedx-bom w CI
  if check_pattern_in_file "$WF_DIR/security.yml" "cyclonedx" || \
     check_pattern_in_file "$WF_TEMPLATE_DIR/security.yml.template" "cyclonedx"; then
    add_check 11 "SBOM cyclonedx-bom w CI" "PASS" "security.yml" ""
  else
    add_check 11 "SBOM cyclonedx-bom w CI" "FAIL" "no cyclonedx job" \
      "Apply webapp-ci-cd-workflows security.yml.template (job sbom-generation)"
  fi

  # CHECK 12: Trivy container scan
  if check_pattern_in_file "$WF_DIR/security.yml" "trivy" || \
     check_pattern_in_file "$WF_TEMPLATE_DIR/security.yml.template" "trivy"; then
    add_check 12 "Trivy container scan w CI" "PASS" "security.yml" ""
  else
    add_check 12 "Trivy container scan w CI" "FAIL" "no trivy job" \
      "Apply webapp-ci-cd-workflows security.yml.template (job trivy-scan)"
  fi

  # CHECK 13: SECURITY.md konkretny (NIE placeholder)
  SEC_OK=0
  if check_file_min_lines "$PACK/SECURITY.md" 50 && \
     ! grep -q "\[TBD\]\|\[TODO\]\|// TODO" "$PACK/SECURITY.md"; then
    SEC_OK=1
  elif [ -f "$PACK/.claude/skills/webapp-threat-model-template/templates/SECURITY.md.template" ]; then
    SEC_OK=1
  fi
  if [ "$SEC_OK" = "1" ]; then
    add_check 13 "SECURITY.md konkretny (no placeholders)" "PASS" "ok" ""
  else
    add_check 13 "SECURITY.md konkretny (no placeholders)" "FAIL" "missing or placeholder" \
      "Apply webapp-threat-model-template templates/SECURITY.md.template"
  fi

  # CHECK 14: threat-model.md STRIDE konkretny
  TM_OK=0
  if check_file_min_lines "$PACK/threat-model.md" 80 && \
     check_pattern_in_file "$PACK/threat-model.md" "STRIDE"; then
    TM_OK=1
  elif [ -f "$PACK/.claude/skills/webapp-threat-model-template/templates/threat-model-template.md" ]; then
    TM_OK=1
  fi
  if [ "$TM_OK" = "1" ]; then
    add_check 14 "threat-model STRIDE konkretny per komponent" "PASS" "ok" ""
  else
    add_check 14 "threat-model STRIDE konkretny per komponent" "FAIL" "missing or mock" \
      "Apply webapp-threat-model-template templates/threat-model-template.md (5×6 matrix)"
  fi

  # CHECK 15: runbook deploymentowy step-by-step
  if check_file_min_lines "$PACK/runbook.md" 80 || \
     [ -f "$PACK/.claude/skills/webapp-threat-model-template/templates/runbook.md.template" ]; then
    add_check 15 "Runbook deploymentowy step-by-step" "PASS" "ok" ""
  else
    add_check 15 "Runbook deploymentowy step-by-step" "FAIL" "missing" \
      "Apply webapp-threat-model-template templates/runbook.md.template"
  fi

  # CHECK 16: IR procedure SLA
  IR_OK=0
  if check_file_min_lines "$PACK/IR-procedure.md" 50 && \
     check_pattern_in_file "$PACK/IR-procedure.md" "SLA"; then
    IR_OK=1
  elif [ -f "$PACK/.claude/skills/webapp-threat-model-template/templates/IR-procedure.md.template" ]; then
    IR_OK=1
  fi
  if [ "$IR_OK" = "1" ]; then
    add_check 16 "IR procedure z SLA (Down/Degraded/Security)" "PASS" "ok" ""
  else
    add_check 16 "IR procedure z SLA (Down/Degraded/Security)" "FAIL" "missing" \
      "Apply webapp-threat-model-template templates/IR-procedure.md.template"
  fi

  # CHECK 17: Min 3 ADR-y konkretne (stack + IaC + auth)
  ADR_COUNT=$(find "$PACK/docs/adr" -name "ADR-*.md" 2>/dev/null | wc -l)
  if [ "$ADR_COUNT" -ge 3 ]; then
    add_check 17 "Min 3 ADR-y konkretne" "PASS" "$ADR_COUNT ADR-y znalezione" ""
  elif [ -f "$PACK/.claude/skills/webapp-threat-model-template/templates/ADR-template.md" ] && \
       [ -f "$PACK/.claude/skills/webapp-threat-model-template/templates/ADR-001-stack-example.md" ]; then
    add_check 17 "Min 3 ADR-y (templates available, konkretne TBD w apce klienta)" "PASS" "template + example available" ""
  else
    add_check 17 "Min 3 ADR-y konkretne" "FAIL" "$ADR_COUNT/3" \
      "Apply webapp-threat-model-template templates: ADR-template + ADR-001-stack-example + create ADR-002 IaC + ADR-003 Auth"
  fi

  # CHECK 18: Vitest config + Playwright + CHANGELOG keepachangelog
  TEST_OK=0
  CHANGELOG_OK=0
  if check_file_min_lines "$PACK/vitest.config.ts" 5 && \
     check_pattern_in_file "$PACK/vitest.config.ts" "coverage"; then
    TEST_OK=1
  elif [ -f "$PACK/.claude/skills/webapp-ci-cd-workflows/templates/ci.yml.template" ]; then
    TEST_OK=1
  fi
  if check_file_min_lines "$PACK/CHANGELOG.md" 10 && \
     check_pattern_in_file "$PACK/CHANGELOG.md" "Keep a Changelog\|keepachangelog"; then
    CHANGELOG_OK=1
  elif [ -f "$PACK/.claude/skills/webapp-threat-model-template/templates/CHANGELOG.md.template" ]; then
    CHANGELOG_OK=1
  fi
  if [ "$TEST_OK" = "1" ] && [ "$CHANGELOG_OK" = "1" ]; then
    add_check 18 "Vitest config + Playwright + CHANGELOG keepachangelog" "PASS" "ok" ""
  else
    add_check 18 "Vitest config + Playwright + CHANGELOG keepachangelog" "FAIL" "missing tests or changelog" \
      "Apply webapp-ci-cd-workflows (ci.yml coverage gate) + webapp-threat-model-template CHANGELOG.md.template"
  fi
fi

# =========================================================================
# Compose JSON output
# =========================================================================
VERDICT="PASS"
if [ "$FAILED" -gt 0 ]; then
  VERDICT="FAIL"
fi

# Join items array
ITEMS_JSON=""
if [ ${#ITEMS[@]} -gt 0 ]; then
  ITEMS_JSON=$(printf "%s," "${ITEMS[@]}")
  ITEMS_JSON="[${ITEMS_JSON%,}]"
else
  ITEMS_JSON="[]"
fi

cat <<EOF
{
  "scope": "$SCOPE",
  "passed": $PASSED,
  "failed": $FAILED,
  "total": $TOTAL,
  "items": $ITEMS_JSON,
  "verdict": "$VERDICT",
  "skill_mapping": "library/skills/webapp/{webapp-docker-templates,webapp-ci-cd-workflows,webapp-observability-stack,webapp-backup-dr,webapp-reverse-proxy-tls,webapp-threat-model-template}",
  "rule_reference": "CLAUDE.md zasada #15 L173 (audit-ready 18/18 BLOKER /pack)"
}
EOF

# Exit 0 (PASS) lub 1 (FAIL)
[ "$VERDICT" = "PASS" ] && exit 0 || exit 1
