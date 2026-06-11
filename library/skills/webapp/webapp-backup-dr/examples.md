# Przykłady użycia — webapp-backup-dr v1.0.0

---

## Przykład 1 — DemoApp (single-user, VPS)

**Kontekst:** Jan, 50+, wyceny dekars. RPO 24h, single VPS, małe dane.

### Wartości placeholderów

```bash
PROJECT_NAME="demo-app"
DB_HOST="db"
DB_PORT="5432"
DB_NAME="demoapp_production"
DB_USER="demoapp_user"
BACKUP_SCHEDULE="0 3 * * *"
BACKUP_RETENTION_DAYS="7"
B2_BUCKET="demo-app-backups"
```

### .env.backup (NIE w git)

```bash
DB_PASSWORD=<silne_haslo_min_24_znaki>
B2_APPLICATION_KEY_ID=<z_B2_console>
B2_APPLICATION_KEY=<z_B2_console>
B2_BUCKET=demo-app-backups
```

### Fragment compose.prod.yml

```yaml
services:
  backup:
    build:
      context: ./docker/backup
      dockerfile: Dockerfile
    container_name: demo-app-backup
    restart: unless-stopped
    env_file: .env.backup
    environment:
      DB_HOST: db
      DB_PORT: "5432"
      DB_NAME: demoapp_production
      DB_USER: demoapp_user
    volumes:
      - backups:/backups
    depends_on:
      db:
        condition: service_healthy

volumes:
  backups:
```

### Oczekiwana struktura backupów po 1 miesiącu

```
/backups/
├── daily/
│   ├── demo-app-20260529-030042.sql.gz  (readonly, newest)
│   ├── demo-app-20260528-030038.sql.gz
│   └── ... (7 plików)
├── weekly/
│   ├── demo-app-20260525-030041.sql.gz  (niedziela)
│   └── ... (4 pliki)
└── monthly/
    └── demo-app-20260501-030039.sql.gz  (1-szy miesiąca)
```

---

## Przykład 2 — Retrofit istniejącej apki bez downtime

**Kontekst:** apka już działa na produkcji, chcemy dodać backup bez restartu.

### Problem

Nie możemy robić `docker compose down` bo apka ma aktywnych użytkowników.

### Rozwiązanie — add backup sidecar only

```bash
# Krok 1: Zbuduj obraz backup (bez zmiany innych kontenerów)
docker compose -f compose.prod.yml build backup

# Krok 2: Uruchom TYLKO nowy sidecar (nie restartuje app/db/proxy)
docker compose -f compose.prod.yml up -d backup

# Krok 3: Sprawdź że sidecar działa
docker compose -f compose.prod.yml ps backup
# → powinien być "running (healthy)"

# Krok 4: Manual test dump (przed czekaniem do 3:00)
docker compose exec backup /usr/local/bin/pg-dump-cron.sh
# → powinien się zakończyć "pg-dump-cron DONE"

# Krok 5: Weryfikuj B2
docker compose exec backup \
  rclone lsf --config=/etc/rclone.conf b2remote:<B2_BUCKET>/daily/
```

**Dobra praktyka vs zła:**

```
DOBRZE: docker compose up -d backup          # tylko sidecar
ZLE:    docker compose down && docker compose up -d   # restart wszystkiego
```

---

## Przykład 3 — Kiedy NIE używać tego skilla (stub multi-tenant)

**Kontekst:** apka SaaS z 50+ tenantami, każdy ma swoją bazę.

### Problem

Ten skill zakłada **jedną bazę PostgreSQL** i **jeden backup sidecar**. Przy multi-tenant każda baza wymaga osobnego pg_dump — inaczej `--dbname` w pg-dump-cron.sh jest jedna konkretna.

### Co zrobić

Opcja A (najprostsza): uruchom kilka instancji sidecar z różnymi env vars (`DB_NAME_1`, `DB_NAME_2`).

Opcja B (lepiej): rozszerz `pg-dump-cron.sh` o iterację po listę baz:
```bash
# Zamiast jednej DB_NAME, iteruj po liście
for db_name in "${DB_NAMES[@]}"; do
    DUMP_FILE="${BACKUP_DIR}/${PROJECT_NAME}-${db_name}-${TIMESTAMP}.sql.gz"
    PGPASSWORD="${DB_PASSWORD}" pg_dump --dbname="${db_name}" ...
done
```

Opcja C (enterprise): WAL-G z backup wszystkich baz z jednego pg cluster — poza scope tego skilla.

**Ten skill jest optymalny dla:** single-DB webapp, single-user lub multi-user z jedną shared DB.

---

## Przykład 4 — Weryfikacja B2 retention po 35 dniach

Po miesiącu pracy sprawdź że retention działa poprawnie:

```bash
# Local count
docker compose exec backup bash -c '
  echo "Daily: $(ls /backups/daily/*.sql.gz 2>/dev/null | wc -l) (expect ≤7)"
  echo "Weekly: $(ls /backups/weekly/*.sql.gz 2>/dev/null | wc -l) (expect ≤4)"
  echo "Monthly: $(ls /backups/monthly/*.sql.gz 2>/dev/null | wc -l) (expect ≤12)"
'

# B2 count
docker compose exec backup \
  rclone lsf --config=/etc/rclone.conf b2remote:<B2_BUCKET>/daily/ | wc -l

# Jeśli B2 ma więcej niż lokalnie — normalnie (B2 nie czyści automatycznie)
# retention-rotation.sh czyści TYLKO lokalnie; B2 lifecycle rules są osobne
```
