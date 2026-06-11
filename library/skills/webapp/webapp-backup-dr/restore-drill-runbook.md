# Restore Drill Runbook — webapp-backup-dr v1.0.0

Runbook dla: monthly automated drill + manual restore + recovery scenarios.

---

## 1. Monthly Automated Drill

### Co się dzieje automatycznie (1-szy miesiąca 4:00)

```
cron 0 4 1 * * → restore-drill.sh
  ├── download latest backup z B2/daily/
  ├── start ephemeral postgres:16-alpine container (DRILL_CONTAINER)
  ├── pg_restore → drill DB (izolowana, NIE live)
  ├── validate rowcount diff <1% (każda tabela)
  ├── validate schema diff = 0 (lista tabel public.*)
  ├── generate report.json
  └── cleanup (docker rm + rm -rf /tmp/drill-*)
```

### Sprawdź wynik po automatycznym drill

```bash
# Ostatni log drill
docker compose exec backup tail -50 /var/log/drill.log

# Szukaj linii: "=== RESTORE DRILL PASS ===" lub "=== RESTORE DRILL FAIL ==="
grep "RESTORE DRILL" <(docker compose exec backup cat /var/log/drill.log) | tail -3
```

### Jeśli automated drill FAIL

1. Sprawdź pełny log: `docker compose exec backup cat /var/log/drill.log`
2. Sprawdź dostępność B2: `docker compose exec backup rclone lsf --config=/etc/rclone.conf b2remote:<BUCKET>/daily/ | head -5`
3. Sprawdź dostępność source DB: `docker compose exec backup pg_isready -h db -p 5432 -U <user>`
4. Uruchom manual drill z verbose: `docker compose exec backup bash -x /usr/local/bin/restore-drill.sh --manual`
5. Jeśli problem strukturalny — eskaluj do recovery scenario B/C poniżej.

---

## 2. Manual Restore Drill

Gdy chcesz zweryfikować działanie poza harmonogramem (np. po dużej migracji schematu):

```bash
# Standardowy manual drill (latest B2 backup)
docker compose exec backup /usr/local/bin/restore-drill.sh --manual

# Drill z konkretnym plikiem backup
docker compose exec backup /usr/local/bin/restore-drill.sh \
  --manual \
  --backup-file=/backups/daily/{{PROJECT_NAME}}-20260501-030042.sql.gz
```

---

## 3. Recovery Scenarios

### Scenario A — Przypadkowe usunięcie danych (most common)

**Sytuacja:** ktoś usunął rekordy z tabeli `offers`. Potrzebujemy przywrócić dane z wczorajszego dumpa.

**RPO:** 24h (last daily backup).

```bash
# 1. Znajdź odpowiedni backup
docker compose exec backup ls -lh /backups/daily/ | tail -10

# 2. Jeśli brak lokalnie — pobierz z B2
docker compose exec backup rclone copy \
  --config=/etc/rclone.conf \
  b2remote:<B2_BUCKET>/daily/<nazwa_pliku>.sql.gz \
  /backups/daily/

# 3. Restore TYLKO konkretnej tabeli (NIE pełne restore)
gunzip -c /backups/daily/<nazwa>.sql.gz > /tmp/dump.custom
docker compose exec db pg_restore \
  -U <DB_USER> -d <DB_NAME> \
  --table=offers \
  --data-only \
  --disable-triggers \
  /tmp/dump.custom

# 4. Weryfikacja
docker compose exec db psql -U <DB_USER> -d <DB_NAME> \
  -c "SELECT COUNT(*) FROM offers;"
```

### Scenario B — Corrupt backup file

**Sytuacja:** ostatni dump jest uszkodzony (pg_restore zwraca error).

```bash
# 1. Sprawdź integralność lokalnych backupów
docker compose exec backup bash -c \
  'for f in /backups/daily/*.sql.gz; do gzip -t "$f" && echo "OK: $f" || echo "CORRUPT: $f"; done'

# 2. Sprawdź poprzednie backupy (weekly jeśli daily uszkodzone)
docker compose exec backup ls -lh /backups/weekly/

# 3. Restore z ostatniego działającego weekly
gunzip -c /backups/weekly/<nazwa>.sql.gz | docker run --rm -i postgres:16-alpine \
  pg_restore --list | head -20  # sprawdź zawartość
```

### Scenario C — Full DB loss (VPS failure / disk failure)

**Sytuacja:** PostgreSQL container lub dysk stracony. Potrzebujemy pełnego restore z B2.

**UWAGA:** Przed restore — upewnij się że nowy PostgreSQL container jest pusty lub zatrzymany stary.

```bash
# 1. Zatrzymaj aplikację (prevent new writes)
docker compose stop app

# 2. Pobierz najnowszy backup z B2
mkdir -p /tmp/restore/
rclone copy \
  --config=<ścieżka do rclone.conf> \
  b2remote:<B2_BUCKET>/daily/ \
  /tmp/restore/ \
  --filter "+ *.sql.gz" --max-age=2d
ls -lh /tmp/restore/

# 3. Uruchom świeży PostgreSQL container (jeśli główny down)
docker compose up -d db
# Poczekaj na gotowość
docker compose exec db pg_isready -U <DB_USER>

# 4. Utwórz bazę jeśli nie istnieje
docker compose exec db createdb -U postgres <DB_NAME> 2>/dev/null || true
docker compose exec db psql -U postgres -c "GRANT ALL ON DATABASE <DB_NAME> TO <DB_USER>;"

# 5. Restore
gunzip -c /tmp/restore/<najnowszy>.sql.gz | docker compose exec -T db \
  pg_restore \
  -U <DB_USER> -d <DB_NAME> \
  --exit-on-error \
  --single-transaction \
  --no-privileges --no-owner

# 6. Smoke test
docker compose exec db psql -U <DB_USER> -d <DB_NAME> \
  -c "SELECT schemaname, tablename, n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC LIMIT 10;"

# 7. Uruchom aplikację
docker compose start app
curl -sf http://localhost:<APP_PORT>/api/ready | jq .
```

### Scenario D — Partial restore (schema diff mismatch po migracji)

**Sytuacja:** restore-drill zgłasza schema diff FAIL po deployment z nowymi migracjami.

```bash
# To może być false positive — nowe kolumny/tabele dodane w deployment
# Weryfikacja:
docker compose exec db psql -U <DB_USER> -d <DB_NAME> \
  -c "SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY 1;" \
  > /tmp/current_schema.txt

# Porównaj z zawartością dump
gunzip -c <backup>.sql.gz | docker run --rm -i postgres:16-alpine \
  pg_restore --list | grep "TABLE" | awk '{print $NF}' | sort > /tmp/dump_schema.txt

diff /tmp/current_schema.txt /tmp/dump_schema.txt
# Jeśli diff = tylko nowe tabele dodane w najnowszym deploy → OK, zaktualizuj baseline
# Jeśli diff = brakujące tabele w backup → investigate przed restore
```

---

## 4. Validation Thresholds

| Sprawdzenie | Próg PASS | Akcja przy FAIL |
|---|---|---|
| rowcount diff per tabela | <1% | Investigate — może być legitimne (deletes w ciągu dnia) lub corrupt |
| schema diff (tabele) | = 0 | Sprawdź scenario D; może być false positive po migracji |
| gzip integrity | 0 errors | Backup corrupt — użyj poprzedniego |
| pg_restore exit code | = 0 | Sprawdź logi pg_restore, może być partial restore |

---

## 5. Kontakt i eskalacja

**Incident SLA (z briefu ):**
- Down (full unavailability): 2h reakcja, 8h MTTR
- Data loss suspected: 1h reakcja, immediate isolation

**Krok po incydencie:** append do `knowledge-base/lessons.jsonl` z `severity: HIGH` oraz update `docs/runbook.md` o nowy scenario jeśli nie był opisany.
