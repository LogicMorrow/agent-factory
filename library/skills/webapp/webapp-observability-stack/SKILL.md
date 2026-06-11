---
name: webapp-observability-stack
description: Templates konkretne — pino JSON structured logging z PII redaction + Sentry SaaS integration (@sentry/nextjs) + healthcheck endpoints `/api/health` `/api/ready` `/api/version` + UptimeRobot setup procedure + audit-trail hook patterns (referencja do audit-trail-on-offer-write.sh). Dla webapp produkcyjnych Next.js 14.2 LTS. Pokrywa zasadę #15 CLAUDE.md punkty 5 (logging), 6 (metrics path), 7 (error tracking). Uruchamiaj gdy bootstrap webapp produkcyjnego pod audit-ready 18/18.
tools: Read, Write
model: sonnet
version: "1.0.0"
compatible_with: [webapp]
requires: [webapp-docker-templates]
tags: [observability, logging, pino, sentry, healthcheck, uptime, audit-trail, audit-ready, , zasada-15-pkt-5-6-7]
token_cost: medium
distribution: library/skills/webapp/
last_updated: 2026-05-29
last_reviewed: 2026-05-29
valid_until: 2027-05-29
---

# webapp-observability-stack

## 1. Purpose

Skill dostarcza **gotowe do podmienienia** szablony observability dla webapp produkcyjnych LogicMorrow.
Każdy template jest funkcjonalny — nie zawiera `# TODO implement` ani `YOUR_VALUE_HERE`.

**Dla kogo:** każdy webapp produkcyjny oparty o Next.js 14.2 LTS (DemoApp, external-crm,
przyszłe projekty). Stack referencyjny: external-crm (`@sentry/nextjs`, pnpm 10.33.2, Node 22).

**Powiązanie z zasadą #15 CLAUDE.md:**
- Pkt 5 — Structured logging JSON (pino + pino-redact PII)
- Pkt 6 — Metrics endpoint przygotowany jako v2 path (`/metrics` stub gotowy do Prometheus)
- Pkt 7 — Error tracking Sentry SaaS free tier (5k events/mo, `@sentry/nextjs 10`)

Brak tych konfiguracji = BLOKER przy `/pack` dla audit-scope=production.

**Co NIE jest w scope:**
- Dockerfile/compose → skill `webapp-docker-templates`
- CI/CD workflows → skill `webapp-ci-cd-workflows`
- Security headers/rate-limiting → skill `webapp-reverse-proxy-tls`
- Backup DR → skill `webapp-backup-dr`

---

## 2. Before starting work (cross-agent-learning v1.1.0)

1. **Sprawdź `errors-webapp-observability-stack.md`** (pełna treść) jeśli istnieje w `.claude/memory/`
   projektu — apply silently rule.
2. **Przeczytaj ostatnie 3 reflections** z `knowledge-base/reflections/` z `sentry` / `pino` /
   `observability` w nazwie lub treści.
3. **Przejrzyj `knowledge-base/lessons.jsonl` tail 20** — szczególnie lessons dotyczące Sentry DSN,
   pino-redact, healthcheck DB ping.

Budget: 5k tokenów. Apply silently — nie raportuj, po prostu uwzględnij.

**Znane pułapki (z briefu , 2026-05-29):**
- `@sentry/nextjs 10` wymaga `instrumentation.ts` (App Router) — NIE starego `_app.tsx` pattern.
- pino-redact ścieżki są case-sensitive — `req.body.Password` ≠ `req.body.password`.
- `/api/ready` MUSI pingować DB (`$queryRaw\`SELECT 1\`` Prisma) — liveness bez DB ping nie wystarczy do audit.
- UptimeRobot darmowy interval to **5 minut minimum** — nie 1 min.
- `SENTRY_DSN` jest public-safe (nie secret), `SENTRY_AUTH_TOKEN` jest sekretny (upload source maps).

---

## 3. Templates dostarczane

Katalog `templates/` tego skilla:

| Plik | Rozmiar | Opis |
|---|---|---|
| `pino.config.ts.template` | ~100 linii | Logger JSON, pino-redact PII, request middleware, async context |
| `sentry.server.config.ts.template` | ~90 linii | Sentry server: DSN env, adaptive sample rate, beforeSend PII filter |
| `sentry.client.config.ts.template` | ~70 linii | Sentry client (browser): uproszczony, replay wyłączony (privacy) |
| `healthcheck-routes.ts.template` | ~150 linii | 3 Route Handlers Next.js 14: /health /ready /version |
| `uptimerobot-setup.md.template` | ~80 linii | Procedura konfiguracji UptimeRobot 5-min ping krok po kroku |
| `audit-trail-hook-template.sh.template` | ~80 linii | Bash hook template: snapshot PDF+JSON+MD5→audit-trail/ chmod 0444 |
| `observability-env-vars.md.template` | ~60 linii | Lista ENV vars z opisem i przykładami dla DemoApp |

---

## 4. Zasada #15 mapping

| Punkt #15 | Co pokrywa | Plik template |
|---|---|---|
| **Pkt 5** — Structured logging JSON do stdout | pino + pino-redact PII, request middleware, correlation ID | `pino.config.ts.template` |
| **Pkt 6** — Metrics endpoint Prometheus `/metrics` v2 path | `/api/health` z `uptime` + stub `/metrics` comment w healthcheck route | `healthcheck-routes.ts.template` |
| **Pkt 7** — Error tracking Sentry (SaaS/self-hosted) | `@sentry/nextjs 10` server + client config, DSN z env, PII filter | `sentry.server.config.ts.template` + `sentry.client.config.ts.template` |

**Punkty 1-4, 8-18 zasady #15** pokrywają inne skille. Pełna mapa: `webapp-docker-templates` (1-3),
`webapp-ci-cd-workflows` (4,11,12), `webapp-backup-dr` (8), `webapp-reverse-proxy-tls` (9-10),
`webapp-threat-model-template` (13-17).

---

## 5. Konwencja placeholderów

Wszystkie templates używają formatu `{{VARIABLE_NAME}}` do sed-replace. Top-3 zmienne specyficzne dla tego skilla:

| Zmienna | Opis | Przykład |
|---|---|---|
| `{{SENTRY_DSN}}` | Sentry Data Source Name (public-safe) | `https://abc123@o0.ingest.sentry.io/456` |
| `{{PROD_URL}}` | URL produkcyjny aplikacji | `https://demoapp.pl` |
| `{{LOG_LEVEL}}` | Poziom logowania (default info) | `info` |

Pełna lista 12 zmiennych z opisem i przykładami → [placeholders-reference.md](./placeholders-reference.md)

---

## 6. Workflow konsumenta

5-krokowy skrót:
1. `cp` templates do projektu z zachowaniem ścieżek
2. Sed-replace wszystkich `{{VARIABLE}}` (skrypt w placeholders-reference.md)
3. Dodaj ENV vars do `.env.example` z `observability-env-vars.md.template`
4. `pnpm add pino pino-http pino-redact @sentry/nextjs`
5. Test: `curl /api/health /api/ready /api/version` + sprawdź event w Sentry

Pełny workflow z każdym krokiem rozpisanym → [workflow-konsumenta.md](./workflow-konsumenta.md)

---

## 7. Sentry integration

Sentry SaaS free tier (5k events/mo) — wystarczające dla 50-200 sessions/mc (DemoApp).
Konfiguracja obejmuje DSN z env, adaptive sample rate (1.0 dev / 0.1 prod), PII filtering
w `beforeSend`, oraz upload source maps w CI (`SENTRY_AUTH_TOKEN`).

Pełna procedura (account setup, DSN, alert routing, ignore patterns, source maps CI) →
[sentry-integration.md](./sentry-integration.md)

---

## 8. Audit-trail hook patterns

Hook `audit-trail-on-offer-write.sh` (z paczki , referencja) — snapshot każdej oferty:
PDF + JSON metadata + MD5 hash + timestamp ISO → `artifacts/audit-trail/<YYYY>/<MM>/<offer-id>/`.
Immutable storage (chmod 0444 po zapisie). Append do `artifacts/audit-trail/index.jsonl`.

Template basha → `templates/audit-trail-hook-template.sh.template`

Pełne patterns (hook implementation, immutable storage, retencja 5 lat RODO, recovery) →
[audit-trail-patterns.md](./audit-trail-patterns.md)

---

## 9. Przykłady użycia

- Mała apka single-user (DemoApp): pino level=info, Sentry free, UptimeRobot 1 monitor
- Średnia multi-tenant: pino level=warn+sampling, Sentry Business, UptimeRobot Pro
- Retrofit istniejącej apki bez downtime: dodanie pino middleware bez przerwy serwisu

Rozpisane przykłady "dobrze vs źle" → [examples.md](./examples.md)

---

## 10. Anti-patterns

Skrócona lista — **nigdy nie rób:**
1. Logowanie haseł/tokenów bez pino-redact (`password` w plaintext w stdout)
2. Sentry bez `beforeSend` PII filter (imiona/emaile klientów w breadcrumbs)
3. `/api/health` bez DB ping (liveness ≠ readiness — healthcheck fałszywy PASS)
4. Audit-trail mutable (brak chmod 0444 → plik można nadpisać → brak dowodowości)
5. Sentry DSN w kodzie (hardcode w `.sentry*config.ts` zamiast env var)

Pełna lista 8 antywzorców z wyjaśnieniem i fix → [anti-patterns.md](./anti-patterns.md)

---

## 11. Done criteria

Skill zastosowany poprawnie gdy:

- [ ] `pino.config.ts` zaimportowany w `app/layout.tsx` lub middleware (logger globally available)
- [ ] `pino-redact` paths zawierają min: `password`, `token`, `email`, `phone`, `nazwisko`, `adres`
- [ ] `instrumentation.ts` (Sentry App Router) obecny w root projektu
- [ ] `SENTRY_DSN` w `.env.example` (NIE w `.env` commited do git)
- [ ] `SENTRY_AUTH_TOKEN` w GitHub Secrets (NIE nigdzie w plikach)
- [ ] `/api/health` odpowiada `{status:"ok"}` w < 100ms
- [ ] `/api/ready` odpowiada z `checks.db: "ok"` lub `checks.db: "error"` i HTTP 503
- [ ] `/api/version` odpowiada z `version` + `build_sha`
- [ ] UptimeRobot monitor aktywny (ping na `{{PROD_URL}}/api/health` co 5 min)
- [ ] audit-trail directory `artifacts/audit-trail/` w `.gitignore` (NIE commitować PDFów)
- [ ] `artifacts/audit-trail/index.jsonl` w `.gitignore` (NIE commitować indeksu)
- [ ] Sentry: test event widoczny w dashboard (verify DSN poprawny)

---

## 12. ACTIVITY-LOG template

Po zastosowaniu skilla agent/Claude emituje wpis (format z `knowledge-base/activity-log.README.md`):

```
ACTIVITY-LOG: {
  "ts": "<ISO-8601>",
  "actor": "skill-builder",
  "action": "skill_applied",
  "artifact": "<projekt>/.claude/",
  "skill": "webapp-observability-stack",
  "skill_version": "1.0.0",
  "notes": "pino+redact+sentry+healthcheck+uptimerobot+audit-trail, zasada #15 pkt 5+6+7 covered"
}
```

Tryby logowania:
- **Agent z `Bash`** → appenduje bezpośrednio: `echo '<json>' >> knowledge-base/activity-log.jsonl`
- **Agent bez `Bash`** → emituje prefiks `ACTIVITY-LOG:` jako ostatnią linię outputu, main Claude appenduje

Referencja konwencji → `knowledge-base/activity-log.README.md`
