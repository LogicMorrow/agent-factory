---
description: Wyświetla 10 metryk zdrowia fabryki (operationalization score) — iteration cycle, cross-agent-learning adoption, lessons taxonomy coverage, real piloty, proposals queue.  pkt B5.
---

# /factory-status — health check fabryki

## Cel

One-command audit fabryki — 10 metryk pokazujących **operationalization score**. Uruchom co kilka dni żeby zobaczyć czy learning loop faktycznie działa.

**Origin:**  (Operationalize Learning Loop) — pkt B5, 2026-05-13. Audyt 2026-05-13 ustalił baseline (3/10 operationalization). Ten slash to ongoing thermometer.

## Workflow

1. `Bash: bash library/scripts/factory-status.sh` — wykonuje analizę przez Python + jq
2. Output formatted markdown raport
3. Activity-log entry `factory_status_run` po analizie

## Output (przykład)

```
=== Agent-Factory Status (2026-05-XX) ===

📦 Library:
  - 33 agentów (7 iterated v>1.0, 26 unchanged v1.0.0)
  - 29 skilli (1 iterated, 28 v1.0.0)
  - 6 hooks (+2 NEW : post-iteration-error-detect, validate-lesson-schema)

🔄 Iteration cycle (target: ≤50% on v1.0):
  - Agentów na v1.0.X: 26/33 (79%) — TARGET ≤50% (16/33)
  - Skilli na v1.0.X: 28/29 (96%) — TARGET ≤50% (14/29)
  - Średni czas od ostatniego patcha: X dni (median)

🧠 Learning loop:
  - Cross-agent-learning adoption: 33/33 (100%) ✅ TARGET MET ( A5)
  - Mistake-recorder usage (30d): X errors files (target ≥10) — czy auto-hook fires?
  - Lessons taxonomy: X% unknown category (target ≤5%) — czy schema enforce działa?
  - Lessons total: 71 (60 z maja, 11 z kwietnia)

🎯 Real piloty (target: ≥30%):
  - Agentów z .real-test-status.json: X/33 (target ≥10)

📋 Improvement-proposals queue:
  - Open (folder): 13 (12 stale >14d)
  - Closed/Implemented: 1 (plan-executor-universal-agent)

🚀 Releases:
  - Paczki af-pack: 3 (external-crm, seo-construction, example-pack)
  - Najnowszy tag: af-pack-<nazwa> v1.1.0 (2026-05-13)
  - Library-index version: v2.11.0 → v2.12.0-rc1 ( KOMPLET)

✅ DoD : X/14 spełnione
  ✓ A1: pack-agent gate
  ✓ A2: auto-mistake hook (5/5 tests)
  ✓ A3: lessons schema (6/6 tests)
  ✓ A4: cron docs + pre-commit symlink
  ✓ A5: cross-agent-learning 33/33
  ⏳ B1: version-bumper (in progress)
  ⏳ B2: pilot-orchestrator (pending)
  ⏳ ...

🔥 Top 3 stale agents (>30d, ≥2 lessons HIGH+MED match):
  1. offer-analyzer v1.0.1 (15d, 4 lessons) → candidate dla version-bumper
  2. cv-builder v1.0.1 (15d, 3 lessons) → candidate
  3. tech-doc-writer v1.1.0 (X dni, 2 lessons) → candidate

💡 Recommended actions (this week):
  - Run /version-bumper --all ( B1 ready)
  - Review knowledge-base/improvement-proposals/*.md (12 stale)
  - Run /run-pilot --agent=cv-builder z fixtures ( B2 ready)
```

## Activity-log

```bash
echo '{"ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","actor":"factory-status","action":"factory_status_run","artifact":"stdout","status":"ok"}' >> knowledge-base/activity-log.jsonl
```
