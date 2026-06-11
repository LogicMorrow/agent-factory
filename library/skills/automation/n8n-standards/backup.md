# Backup — dwa obowiązkowe poziomy

Oba poziomy MUSZĄ być skonfigurowane. Brak któregokolwiek = FAIL pre-deploy check.

## Poziom 1 — Backup bazy PostgreSQL (codzienny)

```bash
#!/bin/bash
# scripts/backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"
KEEP_DAYS=7
CONTAINER_DB="nazwa_kontenera_db"  # np. projekt-db-1

mkdir -p "$BACKUP_DIR"

# Dump bazy
docker exec "$CONTAINER_DB" pg_dump \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  -Fc \
  -f "/tmp/n8n-backup-${DATE}.dump"

# Skopiuj z kontenera
docker cp "$CONTAINER_DB:/tmp/n8n-backup-${DATE}.dump" \
  "${BACKUP_DIR}/n8n-backup-${DATE}.dump"

# Usuń z kontenera
docker exec "$CONTAINER_DB" rm "/tmp/n8n-backup-${DATE}.dump"

# Retencja — usuń backupy starsze niż KEEP_DAYS
find "$BACKUP_DIR" -name "n8n-backup-*.dump" -mtime +"$KEEP_DAYS" -delete

echo "Backup completed: n8n-backup-${DATE}.dump"
```

**Cron (codziennie 2:00):**
```
0 2 * * * /path/to/scripts/backup.sh >> /var/log/n8n-backup.log 2>&1
```

**Restore:**
```bash
docker exec -i $CONTAINER_DB pg_restore -U "$DB_USER" -d "$DB_NAME" < backup.dump
```

## Poziom 2 — Backup workflow n8n (tygodniowy + przed zmianami)

**Export:**
```bash
# Ręczny (przed każdą większą zmianą):
docker exec [kontener-n8n] n8n export:workflow \
  --all \
  --output=/home/node/.n8n/backups/workflows-$(date +%Y%m%d).json

# Cron tygodniowy (niedziela 3:00):
0 3 * * 0 docker exec [kontener-n8n] n8n export:workflow \
  --all \
  --output=/home/node/.n8n/backups/n8n-$(date +\%Y\%m\%d).json

# Usuń stare (>7 dni):
find /backups/workflows/ -name "*.json" -mtime +7 -delete
```

**Import z backupu:**
```bash
docker exec [kontener-n8n] n8n import:workflow \
  --input=/home/node/.n8n/backups/workflows-YYYYMMDD.json
```

**Wersjonowanie w repo:**
```bash
# Po każdym zatwierdzonym etapie — skopiuj JSON do repo:
docker exec [kontener-n8n] n8n export:workflow --all --output=/tmp/workflows.json
cp /tmp/workflows.json ./n8n-workflows/workflows-v1.0.0.json
git add n8n-workflows/
git commit -m "chore: eksport workflow przed tagiem v1.0.0"
```

## Weryfikacja backup (checklist)
- [ ] `scripts/backup.sh` jest wykonywalny (`chmod +x scripts/backup.sh`)
- [ ] Cron aktywny — `crontab -l` pokazuje wpisy
- [ ] Test ręczny: `bash scripts/backup.sh` kończy bez błędów
- [ ] Plik `.dump` powstał w `/backups/`
- [ ] Test restore na środowisku testowym (nie prod)
- [ ] Workflow export JSON w repo i aktualny
