# Workflow konsumenta — webapp-backup-dr v1.0.0

7 kroków od skopiowania templates do weryfikacji pierwszego drilla.

---

## Krok 1 — Skopiuj i podmień templates

```bash
# Z katalogu projektu (~/<projekt>/)
SKILL_DIR="$(realpath ~/agent-factory/library/skills/webapp/webapp-backup-dr)"

mkdir -p docker/backup/
cp "${SKILL_DIR}/templates/backup-sidecar.dockerfile.template" docker/backup/Dockerfile
cp "${SKILL_DIR}/templates/pg-dump-cron.sh.template"           docker/backup/pg-dump-cron.sh
cp "${SKILL_DIR}/templates/rclone.conf.template"               docker/backup/rclone.conf
cp "${SKILL_DIR}/templates/retention-rotation.sh.template"     docker/backup/retention-rotation.sh
cp "${SKILL_DIR}/templates/restore-drill.sh.template"          docker/backup/restore-drill.sh
```

Następnie uruchom sed-replace ze skryptu w `placeholders-reference.md` (podmień zmienne na realne wartości projektu).

**Weryfikacja:**
```bash
grep -rn '{{' docker/backup/ && echo "UNREPLACED" || echo "OK"
```

---

## Krok 2 — B2 bucket setup

Przejdź przez `templates/b2-bucket-setup.md.template` (podmień `{{PROJECT_NAME}}` i `{{B2_BUCKET}}`).

Wynik kroku: posiadasz `B2_APPLICATION_KEY_ID` i `B2_APPLICATION_KEY`.

---

## Krok 3 — Env vars

Utwórz `.env.backup` (NIE w git):

```bash
cat > .env.backup << 'EOF'
DB_PASSWORD=<haslo_bazy>
B2_APPLICATION_KEY_ID=<key_id_z_B2>
B2_APPLICATION_KEY=<key_secret_z_B2>
B2_BUCKET=<nazwa_bucket>
EOF
chmod 600 .env.backup
echo ".env.backup" >> .gitignore
```

---

## Krok 4 — Dodaj sidecar do compose

W `compose.prod.yml` (lub `compose.yml` dla devu):

```yaml
services:
  backup:
    build:
      context: ./docker/backup
      dockerfile: Dockerfile
    container_name: ${PROJECT_NAME}-backup
    restart: unless-stopped
    env_file:
      - .env.backup
    environment:
      DB_HOST: db
      DB_PORT: "5432"
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
    volumes:
      - backups:/backups
    depends_on:
      db:
        condition: service_healthy
    networks:
      - internal

volumes:
  backups:
    driver: local
```

> Jeśli korzystasz z `webapp-docker-templates` — sidecar `backup` jest już zdefiniowany w compose.yml.template. Zaktualizuj `build.context` na `./docker/backup` i `env_file` na `.env.backup`.

---

## Krok 5 — Build i uruchom sidecar

```bash
# Build obrazu backup sidecar
docker compose -f compose.prod.yml build backup

# Uruchom tylko sidecar (bez restartu app+db)
docker compose -f compose.prod.yml up -d backup

# Sprawdź logi startu
docker compose -f compose.prod.yml logs backup
```

Oczekiwany output logu: `crond started` bez errorów.

---

## Krok 6 — Weryfikacja pierwszego dumpa (manual trigger)

```bash
# Trigger manualny (nie czekaj do 3:00)
docker compose exec backup /usr/local/bin/pg-dump-cron.sh

# Sprawdź lokalny plik
docker compose exec backup ls -lh /backups/daily/

# Sprawdź B2
docker compose exec backup \
  rclone lsf --config=/etc/rclone.conf b2remote:<B2_BUCKET>/daily/ | tail -5
```

Oczekiwany wynik: plik `{{PROJECT_NAME}}-YYYYMMDD-HHMMSS.sql.gz` widoczny lokalnie i na B2.

---

## Krok 7 — Weryfikacja restore drill (manual)

```bash
# Manual drill (sprawdza że restore działa przed pierwszym automated)
docker compose exec backup /usr/local/bin/restore-drill.sh --manual

# Sprawdź report JSON
docker compose exec backup cat /tmp/drill-*/report.json
```

Oczekiwany wynik `report.json`:
```json
{
  "overall": "PASS",
  "rowcount_check": "PASS",
  "schema_check": "PASS"
}
```

---

## Harmonogram automatyczny (po wdrożeniu)

| Job | Cron | Opis |
|---|---|---|
| pg-dump-cron.sh | `0 3 * * *` | Daily backup + B2 sync |
| retention-rotation.sh | `5 3 * * *` | Rotation 7d/4w/12m |
| restore-drill.sh | `0 4 1 * *` | Monthly drill (1-szy miesiąca 4:00) |

Logi dostępne:
```bash
docker compose exec backup cat /var/log/backup.log
docker compose exec backup cat /var/log/drill.log
```
