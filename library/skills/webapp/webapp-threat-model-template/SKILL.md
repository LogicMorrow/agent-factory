---
name: webapp-threat-model-template
description: Templates konkretne (NIE placeholdery TODO) — 4 ADR-y (Stack/IaC/Auth+TOTP/PDF) + threat-model.md STRIDE per komponent (app/db/proxy/backup/ci-cd) + SECURITY.md konkretny (vuln disclosure + GPG + supported versions + rotacja sekretów) + runbook.md (pre-deploy/deploy/rollback/restore/healthcheck/IR escalation) + IR-procedure.md z SLA (Down 2h/8h, Degraded 4h/24h, Security 1h/immediate) + CHANGELOG.md keepachangelog. Pokrywa zasadę #15 CLAUDE.md punkty 13-17, 18. Uruchamiaj gdy bootstrap webapp produkcyjnego pod audit-ready 18/18.
tools: Read, Write
model: opus
version: "1.0.0"
compatible_with: [webapp]
requires: [webapp-docker-templates, webapp-ci-cd-workflows, webapp-observability-stack, webapp-backup-dr, webapp-reverse-proxy-tls]
tags: [threat-model, stride, adr, security-md, runbook, incident-response, changelog, audit-ready, , zasada-15-pkt-13-14-15-16-17-18]
token_cost: high
distribution: library/skills/webapp/
last_updated: 2026-05-29
last_reviewed: 2026-05-29
valid_until: 2027-05-29
---

# webapp-threat-model-template

## 1. Kiedy uruchomić

Gdy bootstrapujesz **webapp produkcyjny wymagający audytu** (OWASP ASVS L2, RODO, security pentest).
Konkretne triggery:
- Bootstrap nowego projektu — punkt kontrolny "audit-ready 18/18" (zasada #15 CLAUDE.md pkt 13-18)
- Przed pierwszym deploy produkcyjnym — weryfikacja czy wszystkie docs są skompletowane
- Przed oddaniem do zewnętrznego audytora IT — komplet dokumentacji bezpieczeństwa

**Wymagania wstępne:** skille z `requires` MUSZĄ być wdrożone (Docker, CI/CD, Observability, Backup, Proxy).

Nie uruchamiaj: dla projektów CLI, automation, lub webapp bez wymagań audytowych.

---

## 2. Templates — pliki tematyczne

Ze względu na zakres (6 templates + 5 plików tematycznych) treść jest w katalogu `templates/` i:

| Plik | Sekcja | Rozmiar |
|---|---|---|
| `templates/ADR-template.md` | Format Martin Fowler ADR | ~80l |
| `templates/ADR-001-stack-example.md` | Wypełniony ADR-001 dla DemoApp | ~150l |
| `templates/threat-model-template.md` | STRIDE 5 komponentów × 6 threats | ~200l |
| `templates/SECURITY.md.template` | SECURITY.md konkretny + GPG + rotacja | ~150l |
| `templates/runbook.md.template` | Runbook + pre-deploy + rollback + restore | ~250l |
| `templates/IR-procedure.md.template` | IR procedure SLA + post-mortem template | ~150l |
| `templates/CHANGELOG.md.template` | keepachangelog 1.1.0 format | ~80l |
| `placeholders-reference.md` | Lista wszystkich `{{PLACEHOLDER}}` | ~120l |
| `workflow-konsumenta.md` | 10 kroków produkcji docs od zera | ~150l |
| `adr-writing-guide.md` | Jak pisać ADR-y + antywzorce | ~150l |
| `examples.md` | ADR-001 pełny + threat-model 1 komponent | ~200l |
| `anti-patterns.md` | 6 krytycznych antywzorców (lesson ) | ~150l |

---

## 3. Kluczowe zasady

1. **Konkretna treść, nie placeholdery `[TBD]`** — każdy template zawiera realną zawartość, tylko zmienne `{{VAR}}` do podmiany (lesson , paczka v1.0 fundamental error).
2. **4 ADR-y minimum** — Stack + IaC + Auth+TOTP + PDF engine. Decyzja bez `Alternatives considered` = odrzucona przez audytora.
3. **STRIDE matrix 5 × 6** — każda cell: poziom ryzyka H/M/L + konkretna mitigation + referencja do kodu lub ADR.
4. **SECURITY.md z GPG fingerprint** — nie tylko "wyślij email", ale publiczny klucz GPG i timeline disclosure (90 dni standard).
5. **Runbook z konkretnymi komendami** — nie "verify deployment succeeded", ale `curl -sf http://localhost:3020/api/ready | jq .status` z retry loop.
6. **IR procedure z SLA numbers** — Down: 2h reakcja/8h MTTR; Degraded: 4h/24h; Security breach: 1h/natychmiastowa izolacja/post-mortem 48h.
7. **CHANGELOG od wersji 1.0.0** — keepachangelog.com 1.1.0, nigdy nie startuj od wersji 0.x bez `## [Unreleased]`.

---

## 4. Kolejność tworzenia docs (zasada #15 pkt 13-18)

```
1. ADR-001 Stack        → zasada #15 pkt 17 (minimum 3 ADR-y)
2. ADR-002 IaC          → zasada #15 pkt 17
3. ADR-003 Auth+TOTP    → zasada #15 pkt 17
4. ADR-004 PDF engine   → zasada #15 pkt 17 (opcjonalny 4.)
5. threat-model.md      → zasada #15 pkt 14 (STRIDE per komponent)
6. SECURITY.md          → zasada #15 pkt 13 (vuln disclosure konkretny)
7. runbook.md           → zasada #15 pkt 15 (step-by-step deploy)
8. IR-procedure.md      → zasada #15 pkt 16 (SLA numbers)
9. CHANGELOG.md         → zasada #15 pkt 18 (keepachangelog)
```

---

## 5. Przykłady — dobrze vs źle

### Para 1 — SECURITY.md

**Zle (placeholder,  fundamental error):**
```markdown
## Reporting vulnerabilities
Contact us at security@example.com.
[TBD — add GPG key here]
Supported versions: [TODO]
```

**Dobrze (konkretna treść):**
```markdown
## Reporting vulnerabilities
Email: security@demoapp.pl
GPG key fingerprint: `A1B2 C3D4 E5F6 7890 ABCD  EF12 3456 7890 ABCD EF12`
Public key: https://keys.openpgp.org/search?q=security@demoapp.pl
Timeline: 90-day disclosure, critical (CVSS ≥9.0) → 7 days
Supported versions: current production only (single-user, no legacy support)
```

### Para 2 — Runbook krok deploy

**Zle (abstrakcyjne):**
```markdown
## Deploy
1. Build the container
2. Verify deployment succeeded
3. Check for errors
```

**Dobrze (konkretne komendy):**
```markdown
## Deploy procedure
```bash
# Step 1: Pull new image (via CD job)
docker compose -f compose.prod.yml pull app

# Step 2: Rolling restart
docker compose -f compose.prod.yml up -d app

# Step 3: Healthcheck verification (10 retries × 3s)
for i in {1..10}; do
  STATUS=$(curl -sf http://localhost:3020/api/ready | jq -r .status 2>/dev/null)
  [ "$STATUS" = "ok" ] && echo "HEALTHY after ${i}s" && break
  sleep 3
done

# Step 4: Rollback if not healthy
[ "$STATUS" != "ok" ] && docker compose -f compose.prod.yml up -d --scale app=0 && \
  docker tag ghcr.io/logicmorrow/demo-app:previous ghcr.io/logicmorrow/demo-app:latest && \
  docker compose -f compose.prod.yml up -d app
```

---

## 6. Antywzorce

Szczegółowo w `anti-patterns.md`. Krytyczne (lesson ):

| AP# | Antywzorzec | Skutek |
|---|---|---|
| AP1 | SECURITY.md z `[TBD]` zamiast treści | Audytor odrzuca — punkt 13 #15 FAIL |
| AP2 | STRIDE bez mitigations (tylko H/M/L) | Threat model bezużyteczny dla audytora |
| AP3 | ADR bez `Alternatives considered` | Jednostronna decyzja = nie ADR |
| AP4 | Runbook z "verify deploy succeeded" bez komend | Na incydencie traci się godziny |
| AP5 | IR procedure bez SLA numbers | Brak baseline = nie można mierzyć MTTR |
| AP6 | CHANGELOG bez `## [Unreleased]` sekcji | Keepachangelog format violation |

---

## 7. Powiązania

- **`webapp-docker-templates`** — dostarcza Dockerfile/compose które runbook.md opisuje krok po kroku
- **`webapp-ci-cd-workflows`** — threat-model ci-cd komponent opisuje ryzyka tych workflowów
- **`webapp-observability-stack`** — runbook.md healthcheck krok referencuje endpointy z tego skilla
- **`webapp-backup-dr`** — runbook.md "Restore from B2" procedura pochodzi z tego skilla
- **`webapp-reverse-proxy-tls`** — threat-model proxy komponent pokrywa ryzyka Caddy v2
- **`single-user-auth-pl`**  — ADR-003 Auth+TOTP opisuje decyzje implementowane przez ten skill
- **`data-protection-rodo-pl`** — SECURITY.md retencja danych i disclosure muszą być spójne z RODO
- **`tech-doc-writer`** — agent do generowania docs na podstawie tych templates
- **`doc-validator`** — waliduje wygenerowane docs (runbook|adr|security) wg template
- **`quality-checker`** — waliduje ten skill (frontmatter, <300 linii, ≥2 przykłady)

---

## 8. Placeholdery — zasada podmiany

Wszystkie placeholdery w templates mają format `{{UPPER_SNAKE_CASE}}`. Lista w `placeholders-reference.md`.

**ZAKAZ używania:** `[TBD]`, `// TODO: fill this`, `<placeholder>`, `???` — są nierozróżnialne od rzeczywistej treści po upływie czasu i powodują fałszywe PASS w audit-ready check.

**Minimalny zestaw do podmiany przed audit:**
- `{{PROD_DOMAIN}}` — domena produkcyjna (np. `demoapp.pl`)
- `{{GPG_FINGERPRINT}}` — fingerprint klucza GPG security@domena
- `{{PROJECT_NAME}}` — nazwa projektu (np. `DemoApp`)
- `{{OWNER_NAME}}` — właściciel/maintainer (np. `operator, LogicMorrow`)
- `{{COMPANY_NAME}}` — firma (np. `Acme Sp. z o.o.`)

---

## 9. Audit-ready pkt 13-18 — checklista wyjścia

```
[ ] ADR-001 Stack — status: Accepted, Alternatives present
[ ] ADR-002 IaC — status: Accepted, Alternatives present
[ ] ADR-003 Auth+TOTP — status: Accepted, feature flag documented
[ ] ADR-004+ — minimum 1 dodatkowy (PDF engine lub custom)
[ ] threat-model.md — wszystkie 30 cells H/M/L + mitigation
[ ] SECURITY.md — email + GPG fingerprint + rotacja cadence + supported versions
[ ] runbook.md — pre-deploy + deploy + rollback + restore + healthcheck + IR escalation
[ ] IR-procedure.md — SLA numbers (Down/Degraded/Security) + post-mortem template
[ ] CHANGELOG.md — [Unreleased] sekcja + 1.0.0 z Security entries
[ ] 0 placeholderów [TBD]/TODO w żadnym z powyższych
```

---

## 10. Struktura katalogów w projekcie docelowym

```
docs/
├── adr/
│   ├── ADR-001-stack.md
│   ├── ADR-002-iac.md
│   ├── ADR-003-auth-totp.md
│   └── ADR-004-pdf-engine.md
├── threat-model.md
├── runbook.md
└── IR-procedure.md
SECURITY.md          (root, widoczny na GitHub)
CHANGELOG.md         (root, keepachangelog)
README.md            (root, quick start + arch overview)
```

---

## 11. Before starting work

Przed użyciem tego skilla wczytaj:
- `knowledge-base/reflections/` ostatnie 3 dotyczące  — wzorce i uniki
- `knowledge-base/lessons.jsonl` tail 20 — szczególnie lesson  (fundamental error: placeholdery zamiast treści)
- `knowledge-base/interviews/2026-05-29--reset-demoapp.md` sekcja 7 — ground truth dla templates

---

## 12. Powiązania zewnętrzne (referencje)

- Martin Fowler ADR format: https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions
- STRIDE methodology: https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats
- keepachangelog: https://keepachangelog.com/en/1.1.0/
- OWASP ASVS L2 controls: https://owasp.org/www-project-application-security-verification-standard/
- GPG key hosting: https://keys.openpgp.org/

---

## 13. ACTIVITY-LOG

Po zapisaniu SKILL.md i templates emituj wpis (lub appenduj jeśli masz Bash):

```json
{
  "ts": "<ISO-8601>",
  "actor": "skill-builder",
  "action": "skill_created",
  "artifact": "library/skills/webapp/webapp-threat-model-template/",
  "skill": "webapp-threat-model-template",
  "skill_version": "1.0.0",
  "notes": " A.E11 — webapp-threat-model-template v1.0.0, pokrywa zasadę #15 pkt 13-17+18, 6 templates (ADR template + ADR-001 wypełniony + threat-model STRIDE + SECURITY.md + runbook + IR procedure + CHANGELOG), 5 plików tematycznych"
}
```
