# Threat Model — {{PROJECT_NAME}}

**Last updated:** {{YYYY-MM-DD}}
**Author:** {{OWNER_NAME}}
**STRIDE methodology:** Spoofing / Tampering / Repudiation / Information disclosure / Denial of Service / Elevation of Privilege
**Standard:** OWASP ASVS Level 2

---

## Architektura systemu (komponenty)

1. **app** — Next.js 14.2 + Hono 4.7 + Prisma 5 (aplikacja webowa)
2. **db** — PostgreSQL 16 (baza danych w kontenerze)
3. **proxy** — Caddy v2 (reverse proxy + auto-TLS)
4. **backup** — pg_dump sidecar + rclone → Backblaze B2
5. **ci-cd** — GitHub Actions (CI: github-hosted) + self-hosted runner VPS (CD)

**Granica systemu:** VPS produkcyjny za Caddy + B2 off-site + GitHub repo

---

## Matrix STRIDE × Komponenty

Poziomy ryzyka: **H** = High (działanie wymagane), **M** = Medium (monitoring wymagany), **L** = Low (akceptowalne)

| Komponent | Spoofing | Tampering | Repudiation | Info disclosure | DoS | EoP |
|---|---|---|---|---|---|---|
| **app** | H — session theft | M — XSS injection | M — brak audit log | H — PII leak API | M — rate limit bypass | H — auth bypass TOTP |
| **db** | L — single user | H — SQL injection via Prisma | H — brak migrations log | H — direct DB access | L — single user load | M — Prisma privilege escal. |
| **proxy** | L — Caddy auto-TLS cert | M — header injection | L — Caddy access log istnieje | L — TLS encryption | M — DDoS VPS IP | L — proxy isolated container |
| **backup** | L — B2 application key auth | M — backup tampering B2 | M — brak backup history log | H — backup dump leak | L — async, non-blocking | L — B2 read-only bucket policy |
| **ci-cd** | M — secrets leak GH | M — workflow injection | M — GH audit log istnieje | H — secrets w build logs | L — GH-hosted rate limits | M — self-hosted runner privilege |

---

## Per-component szczegółowe analizy

### App component

#### Spoofing (HIGH) — Session theft via XSS / cookie steal
**Opis:** Atakujący kradnie cookie sesji przez XSS lub network sniffing (HTTP bez TLS).
**Mitigations:**
- HttpOnly + Secure + SameSite=Lax cookies (`iron-session` config)
- CSP strict: nonce-based (`script-src 'nonce-{nonce}'`, no unsafe-inline)
- HSTS preload (max-age=31536000, includeSubDomains)
- Session rotation przy każdym login + privilege escalation
**Code references:**
- `lib/auth/session.ts` — iron-session cookie config (HttpOnly: true, Secure: true)
- `middleware.ts` — Next.js middleware: CSP nonce injection + HSTS header
**ADR reference:** ADR-003 Auth+TOTP

#### Tampering (MEDIUM) — XSS code injection / CSRF
**Opis:** Wstrzyknięcie malicious JS przez niezdezynfekowany input (nazwa klienta, opis pozycji).
**Mitigations:**
- `zod` schema validation na każdym API endpoint (Server Actions + Route Handlers)
- Prisma parametrized queries (brak raw SQL interpolation)
- CSP blokuje inline scripts (nonce-based)
- Content-Type: application/json wymagane dla API (rejects form-encoded bypass)
**Code references:**
- `lib/validation/offer-schema.ts` — zod schemas
- `app/api/offers/route.ts` — zod parse przed Prisma query

#### Repudiation (MEDIUM) — brak audit log ofert
**Opis:** Brak możliwości udowodnienia kto/kiedy modyfikował ofertę (OWASP ASVS V7.2).
**Mitigations:**
- Hook `audit-trail-on-offer-write.sh` — snapshot każdej oferty (PDF + JSON + MD5 + timestamp ISO)
- `artifacts/audit-trail/<YYYY>/<MM>/<offer-id>/` — immutable (chmod 0444 po zapisie)
- Pino structured logging każdej operacji na ofertach z userId + IP
**Code references:**
- `.claude/hooks/audit-trail-on-offer-write.sh`
- `lib/logger.ts` — pino config z redaction PII

#### Information disclosure (HIGH) — PII leak przez API
**Opis:** Endpoint zwraca dane klientów (imię/nazwisko/telefon/adres) bez autoryzacji lub przez over-fetching.
**Mitigations:**
- Middleware auth check przed każdym page/API (`middleware.ts` matcher)
- Prisma `select` explicit (nigdy `findMany` bez select — brak over-fetching)
- pino-redact: `['req.headers.authorization', 'res.body.phone', 'res.body.address']`
- HTTPS-only (Caddy TLS, HSTS)
**Code references:**
- `middleware.ts:8-25` — session validation + redirect unauthorized
- `lib/offers/queries.ts` — explicit Prisma select list

#### DoS (MEDIUM) — Rate limit bypass na PDF generation
**Opis:** PDF generation jest CPU-heavy (~500ms). 100 concurrent requests → VPS OOM.
**Mitigations:**
- Hono rate limiter: PDF endpoint 30 req/hour per session
- Caddy: 1000 req/min per IP
- Docker resource limits: `deploy.resources.limits.cpus: "1.5"` w compose.prod.yml
**Code references:**
- `app/api/pdf/route.ts` — Hono middleware `rateLimiter({ windowMs: 3600000, max: 30 })`
- `Caddyfile:18` — rate_limit directive

#### Elevation of Privilege (HIGH) — Auth bypass / TOTP skip
**Opis:** Atakujący pomija TOTP lub sesję przez manipulację cookie/token.
**Mitigations:**
- TOTP feature flag `TOTP_REQUIRED=true` przed audytem (wymagane OWASP ASVS V2.8)
- iron-session sealed cookie (HMAC-SHA256, tamper-proof)
- bcryptjs cost 12 dla hasła (brute-force mitigation)
- zxcvbn score ≥3 dla nowych haseł
- Login: 5 prób / 15 min lockout (Hono rate limiter)
**Code references:**
- `lib/auth/login.ts` — bcryptjs.compare + iron-session.set + TOTP check conditional

---

### DB component

#### Tampering (HIGH) — SQL injection via Prisma
**Opis:** Parametrized queries Prisma chronią przed typowym SQL injection, ale raw queries (`$queryRaw`) mogą być podatne.
**Mitigations:**
- ZAKAZ `$queryRaw` z interpolowanymi zmiennymi — ESLint rule `no-prisma-raw-template`
- Prisma query log w dev mode — audyt podejrzanych queries
- PostgreSQL user app ma tylko `SELECT/INSERT/UPDATE/DELETE` — brak `DROP/TRUNCATE`
**Code references:**
- `.eslintrc.json` — custom rule `no-prisma-raw-template`
- `prisma/schema.prisma` — db user `demoapp_app` (limited privileges)

#### Information disclosure (HIGH) — Direct DB access
**Opis:** Port PostgreSQL 5432 eksponowany na zewnątrz VPS.
**Mitigations:**
- Docker network `demoapp_internal` — db container NIE jest w publicznej sieci
- compose.prod.yml: brak `ports` dla db service (tylko internal network)
- Firewall VPS: port 5432 closed (tylko app container via internal network)
**Code references:**
- `compose.prod.yml:db.networks` — tylko `demoapp_internal`

#### Repudiation (HIGH) — brak migrations log
**Opis:** Brak historii kto/kiedy uruchomił migrację schema.
**Mitigations:**
- Prisma migrations folder w git (`prisma/migrations/`) — każda migracja jako commit
- `entrypoint.sh`: `prisma migrate deploy` loguje do stdout (pino captures)
- Migration name konwencja: `YYYYMMDDHHMMSS_opis_zmiany`
**Code references:**
- `entrypoint.sh:8` — `pnpm prisma migrate deploy 2>&1 | pino-pretty`

---

### Proxy component

#### Tampering (MEDIUM) — Header injection
**Opis:** Malicious upstream headers mogą być forwarded do klienta.
**Mitigations:**
- Caddy: `header` directive removes/overrides dangerous headers
- Security headers set explicitly: `X-Frame-Options DENY`, `X-Content-Type-Options nosniff`
- Caddy nie forwarduje `X-Powered-By` (Next.js fingerprint hidden)
**Code references:**
- `Caddyfile:12-22` — explicit header block

#### DoS (MEDIUM) — DDoS na IP VPS
**Opis:** Volumetric attack na VPS IP address.
**Mitigations:**
- Caddy `rate_limit` moduł: 1000 req/min per IP
- Cloudflare proxy (opcja v2 — nie w v1, VPS IP nie jest ukryty)
- Docker compose resource limits (CPU/RAM cap)
**Code references:**
- `Caddyfile:5` — `rate_limit {remote_ip} 1000r/m`

---

### Backup component

#### Information disclosure (HIGH) — Backup dump leak
**Opis:** pg_dump zawiera pełne PII klientów. Wyciek z B2 = naruszenie RODO.
**Mitigations:**
- B2 bucket: private (NIE public), access tylko przez application key
- B2 application key: read-write tylko do bucket `demoapp-backups` (scoped)
- Encryption at rest: B2 server-side encryption enabled
- Master key offline (operator), nie w repozytorium
- Backup manifest: MD5 każdego dumpa (integrity verification)
**Code references:**
- `backup/backup.sh:45` — `rclone copy --b2-server-side-encryption AES256`

#### Tampering (MEDIUM) — Backup tampering w B2
**Opis:** Atakujący z dostępem do B2 key nadpisuje backup przed restore drillem.
**Mitigations:**
- B2 Object Lock (immutability) — włączone dla buckets `demoapp-backups`
- B2 application key: read-only variant dla restore drillu (osobny klucz)
- MD5 checksum verification przy restore: `md5sum backup.dump == backup.md5`
**Code references:**
- `backup/restore-drill.sh:18` — md5sum verification step

---

### CI/CD component

#### Information disclosure (HIGH) — Secrets w build logs
**Opis:** Docker build args, env variables mogą się pojawić w GH Actions logs.
**Mitigations:**
- GitHub Secrets (`${{ secrets.VARIABLE }}`) — nie interpolowane w `run:` bezpośrednio
- `.github/workflows/cd.yml`: `--build-arg` NIE używany (secrets przez runtime env, nie image)
- gitleaks pre-commit hook: wykrywa secrets przed push
- SBOM: `cyclonedx-bom` nie zawiera runtime secrets
**Code references:**
- `.github/workflows/cd.yml:env` — tylko non-secret BUILD_SHA
- `.gitleaks.toml` — rules dla common secret patterns

#### EoP (MEDIUM) — Self-hosted runner privilege
**Opis:** Compromised self-hosted runner na VPS prod → dostęp do docker socket → privilege escalation.
**Mitigations:**
- Runner user: `github-runner` (dedicated, non-root)
- docker group: tylko `github-runner`, nie sudo
- Runner tylko do CD job (brak dostępu do CI secrets)
- Runner directory: `/home/github-runner/_work` (sandbox)
- Workflow: `runs-on: self-hosted` tylko w `cd.yml` (nie w `ci.yml` / `security.yml`)
**Code references:**
- `docs/runbook.md#runner-setup` — runner installation guide

---

## Ryzyka residualne (akceptowane)

| Ryzyko | Uzasadnienie akceptacji | Review |
|---|---|---|
| TOTP optional w v1 | Jan 50+ nie-IT, feature flag włączony przed audytem | Przed audytem zewnętrznym |
| Cloudflare brak | Single VPS IP exposed; DDoS mitigation tylko Caddy rate limit | v2 jeśli wzrost traffic |
| Manual pentest brak | ZAP automated DAST w CI; manual 5-15k PLN nieproporcjonalny dla 1-user | v2 jeśli wymóg ubezpieczyciela |
| Prometheus/Grafana brak | UptimeRobot + Sentry wystarczą dla 1-user; 3 kontenery extra = overkill | v2 jeśli metryki business potrzebne |

---

## Revision history

| Date | Author | Change |
|---|---|---|
| {{YYYY-MM-DD}} | {{OWNER_NAME}} | Initial threat model —  |
