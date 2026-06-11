# Boilerplate — exact pliki konfiguracyjne n8n

## `docker-compose.yml`
```yaml
services:
  n8n:
    image: n8nio/n8n:1.70.0
    restart: unless-stopped
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=db
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${DB_NAME}
      - DB_POSTGRESDB_USER=${DB_USER}
      - DB_POSTGRESDB_PASSWORD=${DB_PASSWORD}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - N8N_HOST=${N8N_HOST}
      - N8N_PORT=5678
      - N8N_PROTOCOL=${N8N_PROTOCOL:-https}
      - WEBHOOK_URL=${WEBHOOK_URL}
      - N8N_LOG_LEVEL=info
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
      - EXECUTIONS_DATA_SAVE_ON_ERROR=all
      - EXECUTIONS_DATA_SAVE_ON_SUCCESS=none
      - EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=168
    ports:
      - '5678:5678'
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U ${DB_USER} -d ${DB_NAME}']
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  n8n_data:
  postgres_data:
```

## `.env.example`
```bash
# === BAZA DANYCH ===
DB_USER=n8nuser
DB_PASSWORD=              # min 20 znaków losowych: openssl rand -base64 15
DB_NAME=n8ndb

# === N8N ===
N8N_ENCRYPTION_KEY=       # openssl rand -hex 32 — NIGDY nie zmieniać po wdrożeniu!
N8N_HOST=                 # np. n8n.firma.pl (bez https://)
N8N_PROTOCOL=https        # https na prod, http na dev

# === WEBHOOKI ===
WEBHOOK_URL=              # np. https://n8n.firma.pl/ (ze schematem i slash na końcu!)

# === BASIC AUTH ===
N8N_BASIC_AUTH_USER=
N8N_BASIC_AUTH_PASSWORD=  # min 20 znaków

# === ZEWNĘTRZNE API (przykłady — dostosuj per projekt) ===
# SENDGRID_API_KEY=
# PIPEDRIVE_API_KEY=
# ANTHROPIC_API_KEY=
```

## `scripts/backup.sh`
```bash
#!/bin/bash
set -euo pipefail

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_DIR:-/backups}"
KEEP_DAYS="${KEEP_DAYS:-7}"
CONTAINER_DB="${CONTAINER_DB:?Set CONTAINER_DB env variable}"
DB_USER="${DB_USER:?Set DB_USER env variable}"
DB_NAME="${DB_NAME:?Set DB_NAME env variable}"

mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting backup..."

# Dump bazy
docker exec "$CONTAINER_DB" pg_dump \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  -Fc \
  -f "/tmp/n8n-backup-${DATE}.dump"

# Skopiuj z kontenera na host
docker cp "${CONTAINER_DB}:/tmp/n8n-backup-${DATE}.dump" \
  "${BACKUP_DIR}/n8n-backup-${DATE}.dump"

# Cleanup w kontenerze
docker exec "$CONTAINER_DB" rm "/tmp/n8n-backup-${DATE}.dump"

# Retencja
find "$BACKUP_DIR" -name "n8n-backup-*.dump" -mtime +"$KEEP_DAYS" -delete

echo "[$(date)] Backup done: ${BACKUP_DIR}/n8n-backup-${DATE}.dump"
```

## `.gitignore`
```
.env
.env.local
backups/*.dump
backups/*.sql
node_modules/
*.log
```

## `nginx.conf` (skeleton — dostosuj domenę)
```nginx
server {
    listen 80;
    server_name n8n.firma.pl;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name n8n.firma.pl;

    ssl_certificate /etc/letsencrypt/live/n8n.firma.pl/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/n8n.firma.pl/privkey.pem;

    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (n8n wymaga)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```
