---
name: webapp-backup-dr
description: Templates konkretne — pg_dump cron sidecar Docker + rclone Backblaze B2 sync + retention rotation 7d daily/4w weekly/12m monthly + monthly automated restore drill skrypt z validation (rowcount diff <1%, schema diff = 0). Dla webapp produkcyjnych PostgreSQL 16. Pokrywa zasadę #15 CLAUDE.md punkt 8. Uruchamiaj gdy bootstrap webapp produkcyjnego pod audit-ready 18/18.
tools: Read, Write
model: sonnet
version: "1.0.0"
compatible_with: [webapp]
requires: [webapp-docker-templates]
tags: [backup, dr, pg-dump, backblaze-b2, rclone, retention, restore-drill, audit-ready, , zasada-15-pkt-8]
token_cost: medium
distribution: library/skills/webapp/
last_updated: 2026-05-29
last_reviewed: 2026-05-29
valid_until: 2027-05-29
---

# webapp-backup-dr

## 1. Purpose

Skill dostarcza **gotowe do podmienienia** szablony Backup & DR dla webapp produkcyjnych PostgreSQL 16 + Docker Compose. Każdy plik jest funkcjonalny — brak `# TODO implement`, brak `YOUR_VALUE_HERE`. Używa konwencji `{{VARIABLE_NAME}}` zgodnej z `webapp-docker-templates`.

**Dla kogo:** każdy webapp LogicMorrow z PostgreSQL 16 w Docker Compose + wymaganiem audit-ready (DemoApp, external-crm, przyszłe).

**Powiązanie z zasadą #15 CLAUDE.md:** skill pokrywa punkt 8 z 18 wymaganych (backup + DR). Brak tych plików = BLOKER przy `/pack`.

---

## 2. Before starting work (cross-agent-learning v1.1.0)

1. **Sprawdź `errors-webapp-backup-dr.md`** w `.claude/memory/` projektu jeśli istnieje — apply silently.
2. **Przeczytaj ostatnie 3 reflections** z `knowledge-base/reflections/` zawierające `backup` lub `dr` w nazwie/treści.
3. **Przejrzyj `knowledge-base/lessons.jsonl` tail 20** — szczególnie lessons dot. pg_dump, rclone, B2, cron.

Budget: 5k tokenów. Apply silently.

**Znane pułapki:**
- `pg_dump` w kontenerze alpine wymaga `--no-privileges --no-owner` dla przenośności restore.
- `rclone sync` vs `rclone copy` — używaj `copy` dla backup (sync usuwa pliki na zdalnym!).
- B2 `Object Lock` wymaga `--b2-hard-delete=false` w rclone, by plik był locked (immutable).
- `pg_restore` na ephemerycznym kontenerze: `--exit-on-error` + `--single-transaction` dla atomowości.
- Retention script idempotentny — uruchomiony 2× w tej samej sekundzie NIE może usunąć za dużo.

---

## 3. Pliki skilla

### 3.1 Templates (6 plików w `templates/`)

| Plik | Opis |
|---|---|
| `backup-sidecar.dockerfile.template` | Dockerfile backup sidecar (postgres:16-alpine + rclone + cron + curl) |
| `pg-dump-cron.sh.template` | Daily pg_dump + gzip + rclone copy → B2, wywołany przez crond |
| `rclone.conf.template` | Konfiguracja rclone dla B2 — auth przez env vars |
| `retention-rotation.sh.template` | Rotation: 7d daily / 4w weekly / 12m monthly. Idempotentny. |
| `restore-drill.sh.template` | Monthly drill: B2 download → pg_restore → validate rowcount+schema → report JSON |
| `b2-bucket-setup.md.template` | Manual procedura B2: bucket + app key + encryption + lifecycle rules |

### 3.2 Pliki tematyczne (5 plików)

| Plik | Opis |
|---|---|
| `placeholders-reference.md` | Wszystkie zmienne `{{VARIABLE_NAME}}` z opisem i przykładami |
| `workflow-konsumenta.md` | 7 kroków: bootstrap → B2 setup → compose up → verify → drill |
| `restore-drill-runbook.md` | Runbook monthly automated + manual restore (recovery scenarios) |
| `examples.md` | 3 przykłady użycia (DemoApp, retrofit, multi-tenant stub) |
| `anti-patterns.md` | 5+ antywzorców ze skutkami i korekcją |

---

## 4. Zasada #15 mapping

| Punkt #15 | Co pokrywa | Plik template |
|---|---|---|
| **Pkt 8** — pg_dump daily cron + retention 7d/4w/12m + restore drill runbook + off-site backup | Daily cron backup sidecar + retention rotation + monthly restore drill z validation + B2 sync | Wszystkie 6 templates |

**Punkty 1-7, 9-18** — inne skille paczki (`webapp-docker-templates`, `webapp-cicd-templates`, `webapp-security-hardening`, etc.).

---

## 5. Konwencja placeholderów

Zmienne zgodne z `webapp-docker-templates` (te same nazwy gdzie pokrywają się zakresy):

| Zmienna | Opis | Przykład DemoApp |
|---|---|---|
| `{{PROJECT_NAME}}` | Nazwa projektu lowercase-kebab | `demo-app` |
| `{{DB_HOST}}` | Hostname DB w sieci compose | `db` |
| `{{DB_PORT}}` | Port PostgreSQL | `5432` |
| `{{DB_NAME}}` | Nazwa bazy | `demoapp_production` |
| `{{DB_USER}}` | Użytkownik bazy | `demoapp_user` |
| `{{BACKUP_SCHEDULE}}` | Cron schedule | `0 3 * * *` |
| `{{BACKUP_RETENTION_DAYS}}` | Daily retention | `7` |
| `{{B2_BUCKET}}` | Nazwa bucket B2 | `demo-app-backups` |

Zmienne wyłącznie backup (nie w `webapp-docker-templates`): `B2_BUCKET`, `BACKUP_DIR`, `DRILL_CONTAINER_NAME`, `DRILL_DB_NAME`. Pełna lista → `placeholders-reference.md`.

---

## 6. Kluczowe zasady

1. **B2 credentials NIGDY hardcoded** — wyłącznie przez env vars `B2_APPLICATION_KEY_ID` i `B2_APPLICATION_KEY`. Weryfikacja: `grep -r "applicationKeyId" templates/` = 0 matches z wartością.
2. **Encryption w dwóch warstwach** — B2 server-side encryption (SSE-B2) + lokalnie `chmod 0444` po zapisie dumpa.
3. **`rclone copy` nie `rclone sync`** — sync kasuje pliki na B2. Używaj copy zawsze przy backupie.
4. **Restore drill = osobny ephemeral container** — NIGDY nie restoruj do live DB. Container startuje, validate, remove.
5. **Retention idempotentny** — skrypt sprawdza timestampy w nazwach plików, nie polega na `mtime`. Bezpieczny dla retry.
6. **Rowcount validation <1% diff** — porównanie przed/po restore przez `psql -c "SELECT COUNT(*) FROM <table>"`.

---

## 7. Antywzorce

Szczegółowa lista → `anti-patterns.md`. Kluczowe skróty:

| Antywzorzec | Skutek | Korekta |
|---|---|---|
| B2 credentials w git | Security incident, rotacja wszystkich kluczy | Env vars + gitleaks pre-commit |
| `rclone sync` zamiast `copy` | Usunięcie backupów na B2 gdy lokalnie brak | Zawsze `rclone copy` |
| Brak monthly drill | Discover corrupt backup przy realnym disaster | `restore-drill.sh` w cron monthly |
| Restore na live DB | Data loss / corruption | Tylko ephemeral container |
| Retention zbyt krótka (<7d) | Brak możliwości odtworzenia po późno wykrytym błędzie | Standard 7d/4w/12m |

---

## 8. Przykłady

Pełne przykłady → `examples.md`. Streszczenie:

**DemoApp (single-user, VPS):** `{{PROJECT_NAME}}=demo-app`, `{{BACKUP_SCHEDULE}}=0 3 * * *`, `{{B2_BUCKET}}=demo-app-backups`. Drill co 1-szy miesiąca o 4:00.

**Retrofit (istniejąca apka bez downtime):** dodaj backup sidecar do compose.prod.yml bez restartu app container (`docker compose up -d backup`). Pierwsze B2 sync można uruchomić manualnie przed włączeniem crona.

---

## 9. Weryfikacja po wdrożeniu

```bash
# Test ręczny pg_dump
docker compose exec backup /usr/local/bin/pg-dump-cron.sh

# Sprawdź czy dump jest na B2
rclone ls b2:{{B2_BUCKET}}/daily/ | tail -5

# Test retention (dry-run)
docker compose exec backup /usr/local/bin/retention-rotation.sh --dry-run

# Test restore drill manualnie
docker compose exec backup /usr/local/bin/restore-drill.sh --manual
```

---

## 10. Powiązania

| Komponent | Relacja |
|---|---|
| `webapp-docker-templates` | REQUIRED — backup sidecar w compose.yml tego skilla. Ten skill rozszerza sidecar. |
| `webapp-security-hardening` | Uzupełnia — hardening secrets + gitleaks pre-commit blokuje credential leak |
| `webapp-cicd-templates` | Opcjonalne — CI może triggerować monthly drill w schedule job |
| `data-protection-rodo-pl` | Kontekst — retencja backup MUSI być spójna z retencją RODO (5 lat dla ofert) |
| `restore-drill-runbook.md` | Plik tematyczny — szczegółowy runbook dla ops (monthly + manual + scenarios) |

---

## 11. Czas wdrożenia

| Etap | Czas |
|---|---|
| B2 bucket setup (manual) | ~15 min |
| Sed-replace placeholderów | ~5 min |
| `docker compose up -d backup` + test dump | ~10 min |
| Verify B2 sync | ~5 min |
| Restore drill manual verify | ~15 min |
| **Łącznie** | **~50 min** |

---

## 12. ACTIVITY-LOG

Każdy agent/Claude używający tego skilla MUSI zalogować zdarzenie po zapisaniu backupowego artefaktu:

```json
{
  "ts": "<ISO-8601 timestamp>",
  "actor": "<nazwa agenta lub 'main-claude'>",
  "action": "backup_configured",
  "artifact": "<ścieżka do projektu, np. ~/projekty/demo-app/>",
  "skill": "webapp-backup-dr",
  "skill_version": "1.0.0",
  "notes": "<co skonfigurowano — np. 'B2 bucket + cron sidecar + retention + drill scheduled'>"
}
```

Append do `knowledge-base/activity-log.jsonl`. Agent bez `Bash` emituje jako ostatnią linię z prefixem `ACTIVITY-LOG: `.
