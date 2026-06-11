# Przykłady — webapp-threat-model-template

Kompletne przykłady wypełnione dla DemoApp.

---

## Przykład 1: ADR-002 IaC (wypełniony kompletnie)

```markdown
# ADR-002 — IaC: Docker Compose + Caddy v2 + Backblaze B2

**Status:** Accepted
**Date:** 2026-05-29
**Decider:** operator (LogicMorrow) — zatwierdzone explicite w wywiadzie 2026-05-29

## Context

Infrastruktura dla webapp single-user (Jan) na VPS produkcyjnym.
Wymogi: KISS (single-host), audit-ready (OWASP ASVS L2), łatwy rollback, off-site backup.
Istniejące zasoby: VPS OVH (4 vCPU, 8 GB RAM) z Dockerem — spójność z external-crm.

Opcje rozważane:
1. Docker Compose (single-host orchestration)
2. Docker Swarm (multi-node orchestration)
3. K3s (Kubernetes lightweight)
4. Nomad (HashiCorp)

## Decision

Wybrano Docker Compose + Caddy v2 + Backblaze B2.

Docker Compose to KISS na single-host VPS — zero overhead k8s/swarm, Compose v2 ma
healthcheck dependencies i resource limits wystarczające dla OWASP ASVS L2.
Caddy v2 zastępuje nginx+certbot (auto-TLS, 10-linii Caddyfile).
B2 ($0.005/GB/mo) zamiast S3 (~5x tańsze, S3-compatible API).

## Consequences

### Pozytywne
- Compose: zrozumiałe przez operatora, brak narzut k8s, deployment = `docker compose up -d`
- Caddy: auto-TLS Let's Encrypt bez certbotowego crona, Caddyfile 10 linii vs nginx 100
- B2: 5x tańsze niż AWS S3, S3-compatible (rclone/boto3 bez zmian), retention rules support

### Negatywne
- Compose: brak HA — VPS awaria = downtime (akceptowalne dla 1-user, SLA Down 8h MTTR)
- B2 vendor lock: migracja do S3 = config change w rclone tylko, ryzyko low

### Neutralne / Ryzyka
- Docker Swarm odrzucono (single-host overkill) — jeśli DemoApp rośnie do multi-tenant v3 → K3s evaluation
- B2 data residency: US-East (default). EU region dostępny (b2:us-west-002). RODO: szyfrowanie client-side mitiguje.

## Alternatives considered

| Option | Pros | Cons | Why rejected |
|---|---|---|---|
| Docker Swarm | Nadal single-file, HA możliwe | Multi-node wymaga ≥3 VPS (quorum), single-host swarm = overhead bez korzyści | Single-host VPS; HA niepotrzebne dla 1-user v1 |
| K3s (Kubernetes) | Pełne k8s na edge, HA, ecosystem | 3 kontenery tylko (app+db+proxy) = overkill; learning curve; ~500MB RAM overhead | Overkill dla 3 kontenerów; deadline 10 dni |
| Nomad | Prosty scheduler, muli-region | Mały community PL; niezgodny z CRM stack; HashiCorp license change 2023 | Stack nieznany operatorowi; BSL license risk |
| nginx + certbot | Znane, duże community | Certbot cron maintenance, nginx SSL config 50+ linii vs Caddyfile 10 | Caddy czytelniejsze, zero cron maintenance, audit-OK |
| AWS S3 | Standard, dojrzałe | 5x droższe od B2, zbędna kompleksność AWS IAM dla 1-bucket | Cost optimization; B2 S3-compatible = zero migration lock |

## References

- Docker Compose docs: https://docs.docker.com/compose/
- Caddy v2 docs: https://caddyserver.com/docs/
- Backblaze B2 S3-compatible: https://www.backblaze.com/docs/cloud-storage-s3-compatible-api
- Brief wywiadu  sekcja 5: knowledge-base/interviews/2026-05-29--reset-demoapp.md#5

## Change history

| Date | Author | Change |
|---|---|---|
| 2026-05-29 | operator (LogicMorrow) | Initial — zatwierdzone w wywiadzie  reset |
```

---

## Przykład 2: Threat model — komponent CI/CD (jeden komponent szczegółowo)

```markdown
### CI/CD component — analiza szczegółowa

**Opis komponentu:** GitHub Actions CI (github-hosted runners) + CD (self-hosted runner na VPS prod) + ghcr.io container registry

#### Spoofing (MEDIUM) — GitHub secrets leak → impersonation

**Ryzyko:** M (medium)
**Opis:** Wyciek GitHub Secrets (`DATABASE_URL`, `GH_PAT_DEPLOY`, `SENTRY_DSN`) przez
insecure workflow lub workflow injection pozwala atakującemu podszywać się pod deploy pipeline.

**Mitigations:**
1. Secrets przez `${{ secrets.VAR }}` — nigdy hardcoded w `run:` komendach
2. `.github/workflows/cd.yml` — `permissions: contents: read` (principle of least privilege)
3. gitleaks pre-commit: blokuje push jeśli wzorzec secretu w diff
4. `CODEOWNERS: .github/workflows/ @your-org/security-reviewers` — workflow changes require review

**Code references:**
- `.github/workflows/cd.yml:permissions` — explicit least privilege
- `.gitleaks.toml` — secret patterns detection

---

#### Tampering (MEDIUM) — Workflow injection via untrusted input

**Ryzyko:** M (medium)
**Opis:** PR z zewnętrznego forka może wstrzyknąć kod do workflow przez `${{ github.event.pull_request.title }}` w `run:` komendzie.

**Mitigations:**
1. `pull_request_target` trigger ZAKAZANY (niebezpieczny dla public repos)
2. Używamy `pull_request` z `permissions: read-only` na fork PRs
3. Pinowanie actions do commit SHA zamiast tag: `uses: actions/checkout@v4` → `uses: actions/checkout@abc123`
4. Brak zewnętrznych contributors (private repo) — ryzyko ograniczone

**Code references:**
- `.github/workflows/ci.yml:on.pull_request` — bezpieczny trigger

---

#### Repudiation (MEDIUM) — GitHub audit log

**Ryzyko:** M (medium) — mitigated przez istniejący GitHub audit log
**Opis:** Brak local audit log kto uruchomił deploy, ale GitHub Enterprise ma audit log. Free tier ma 90-day retention w UI.

**Mitigations:**
1. GitHub org audit log: Settings → Audit log → filter by repo `demo-app`
2. Deploy log w `artifacts/audit-trail/deploy-history.log` (append-only, każdy deploy)
3. Docker image tags: SHA-pinned (każdy deploy traceabl do commit)

---

#### Information disclosure (HIGH) — Secrets w build logs

**Ryzyko:** H (high)
**Opis:** Docker build args mogą się pojawić w GH Actions logs jeśli przekazane jako `--build-arg` zamiast runtime env. Pino logi mogą logować secrets jeśli pino-redact nie skonfigurowany.

**Mitigations:**
1. `--build-arg` ZAKAZANE dla secrets — secrets przez Docker runtime env (nie image layer)
2. `compose.prod.yml`: secrets przez `env_file: .env.prod` (nie w image, nie w compose.yml)
3. pino-redact konfiguracja: `redact: ['*.password', '*.token', '*.secret', 'req.headers.authorization']`
4. GH Actions: `::add-mask::${{ secrets.VAR }}` dla custom secrets logowanych w run

**Code references:**
- `.github/workflows/cd.yml` — brak `--build-arg` dla secrets
- `lib/logger.ts:12-18` — pino-redact config

---

#### DoS (LOW) — GitHub-hosted runner limits

**Ryzyko:** L (low) — GitHub-hosted mają built-in rate limits
**Opis:** 2000 min/mo dla private repos (free tier). Exhaustion możliwa przy bardzo częstych pushach.

**Mitigations:**
1. Path filters: `ci.yml` uruchamia się tylko przy zmianach w `src/**` `lib/**` `.github/workflows/**`
2. Concurrency groups: `concurrency: { group: ci-${{ github.ref }}, cancel-in-progress: true }`
3. Monitor: GH Settings → Billing → Actions minutes usage

---

#### Elevation of Privilege (MEDIUM) — Self-hosted runner privilege escalation

**Ryzyko:** M (medium)
**Opis:** Compromise self-hosted runner na VPS prod → dostęp do docker socket → privilege escalation do root.

**Mitigations:**
1. Dedicated user `github-runner` (non-root, no sudo)
2. docker group: tylko `github-runner` (konieczne do `docker compose`)
3. runner directory isolated: `/home/github-runner/_work` (nie `/opt/demo-app`)
4. Runner tylko w `cd.yml` (nie w `ci.yml` lub `security.yml` — te na GH-hosted)
5. Quarterly runner update (aktualizuj binary, nie uruchamiaj stale)

**Code references:**
- `docs/runbook.md#self-hosted-runner-maintenance` — runner setup guide
```

---

## Przykład 3: Porównanie SECURITY.md dobry vs zły (lesson )

###  fundamental error (placeholder)

```markdown
# Security Policy

## Supported Versions
[TODO: add supported versions]

## Reporting a Vulnerability
Please email security@example.com.
[TBD — add GPG key]

## Rotation schedule
[TODO: document rotation schedule]
```

**Dlaczego fail:** `[TBD]` i `[TODO]` są nierozróżnialne od "nieistniejącej treści". Audytor widzi ten plik i wie natychmiast, że security posture jest niepoważny.

### Właściwy SECURITY.md (template wypełniony)

```markdown
# Security Policy — DemoApp

## Reporting a vulnerability
Email: security@demoapp.pl
GPG fingerprint: `A1B2 C3D4 E5F6 7890 ABCD  EF12 3456 7890 ABCD EF12`
Public key: https://keys.openpgp.org/search?q=security@demoapp.pl
Timeline: 90-day standard. Critical (CVSS ≥9.0) → 7-day emergency patch.

## Supported versions
Latest production only. Single-user application, no legacy support.

## Rotation cadence
- DB password: quarterly (Jan/Apr/Jul/Oct)
- B2 application key: yearly + emergency
- GitHub PAT: every 6 months
- TLS: auto-renewed by Caddy (no manual intervention)
[...]
```

Audytor widzi konkretne wartości, terminy, proces — security posture jest wiarygodny.
