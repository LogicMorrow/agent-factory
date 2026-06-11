# Placeholders Reference — webapp-backup-dr v1.0.0

Wszystkie zmienne `{{VARIABLE_NAME}}` używane w templates backup-dr.

## Zmienne wspólne z webapp-docker-templates

Te zmienne MUSZĄ być spójne z wartościami w `Dockerfile`, `compose.yml`, `compose.prod.yml`.

| Zmienna | Opis | Przykład DemoApp | Typ |
|---|---|---|---|
| `{{PROJECT_NAME}}` | Nazwa projektu lowercase-kebab. Prefiks w nazwach plików dumpa. | `demo-app` | string |
| `{{DB_HOST}}` | Hostname bazy danych w sieci compose (service name) | `db` | hostname |
| `{{DB_PORT}}` | Port PostgreSQL | `5432` | int |
| `{{DB_NAME}}` | Nazwa bazy danych | `demoapp_production` | string |
| `{{DB_USER}}` | Użytkownik bazy | `demoapp_user` | string |
| `{{BACKUP_SCHEDULE}}` | Cron schedule dla daily pg_dump | `0 3 * * *` | cron |
| `{{BACKUP_RETENTION_DAYS}}` | Liczba daily backupów do zachowania | `7` | int |

## Zmienne wyłącznie backup-dr

| Zmienna | Opis | Przykład DemoApp | Typ |
|---|---|---|---|
| `{{B2_BUCKET}}` | Nazwa Backblaze B2 bucket (globalnie unikalny) | `demo-app-backups` | string |

## Zmienne przekazywane jako env vars (NIE w plikach konfig)

Te wartości NIGDY nie trafiają do pliku konfiguracyjnego, skryptu ani git.
Przekazywane wyłącznie przez `env_file` w compose lub przez Docker secrets.

| Zmienna env | Opis | Gdzie ustawiać |
|---|---|---|
| `DB_PASSWORD` | Hasło do PostgreSQL | `.env.backup` lub Docker secret |
| `B2_APPLICATION_KEY_ID` | Backblaze Application Key ID (nie Master Account ID!) | `.env.backup` lub Docker secret |
| `B2_APPLICATION_KEY` | Backblaze Application Key (secret) | `.env.backup` lub Docker secret |

## Sed-replace script (wszystkie zmienne naraz)

```bash
#!/usr/bin/env bash
# Uruchom z katalogu projektu po skopiowaniu templates/
# Podmień wartości <...> na realne przed uruchomieniem

PROJECT_NAME="<np. demo-app>"
DB_HOST="<np. db>"
DB_PORT="<np. 5432>"
DB_NAME="<np. demoapp_production>"
DB_USER="<np. demoapp_user>"
BACKUP_SCHEDULE="<np. 0 3 * * *>"
BACKUP_RETENTION_DAYS="<np. 7>"
B2_BUCKET="<np. demo-app-backups>"

BACKUP_SKILL_DIR="$(realpath ~/agent-factory/library/skills/webapp/webapp-backup-dr/templates)"
mkdir -p docker/backup/

# Kopiuj templates
cp "${BACKUP_SKILL_DIR}/backup-sidecar.dockerfile.template" docker/backup/Dockerfile
cp "${BACKUP_SKILL_DIR}/pg-dump-cron.sh.template"           docker/backup/pg-dump-cron.sh
cp "${BACKUP_SKILL_DIR}/rclone.conf.template"               docker/backup/rclone.conf
cp "${BACKUP_SKILL_DIR}/retention-rotation.sh.template"     docker/backup/retention-rotation.sh
cp "${BACKUP_SKILL_DIR}/restore-drill.sh.template"          docker/backup/restore-drill.sh

# Sed-replace
FILES=(
    docker/backup/Dockerfile
    docker/backup/pg-dump-cron.sh
    docker/backup/rclone.conf
    docker/backup/retention-rotation.sh
    docker/backup/restore-drill.sh
)

SUBS=(
    "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g"
    "s/{{DB_HOST}}/${DB_HOST}/g"
    "s|{{DB_PORT}}|${DB_PORT}|g"
    "s/{{DB_NAME}}/${DB_NAME}/g"
    "s/{{DB_USER}}/${DB_USER}/g"
    "s|{{BACKUP_SCHEDULE}}|${BACKUP_SCHEDULE}|g"
    "s/{{BACKUP_RETENTION_DAYS}}/${BACKUP_RETENTION_DAYS}/g"
    "s/{{B2_BUCKET}}/${B2_BUCKET}/g"
)

for f in "${FILES[@]}"; do
    for s in "${SUBS[@]}"; do
        sed -i "${s}" "${f}"
    done
    echo "Processed: ${f}"
done

# Weryfikacja — żadne {{}} nie powinny zostać
REMAINING=$(grep -rn '{{' docker/backup/ 2>/dev/null | wc -l)
if [[ "${REMAINING}" -gt 0 ]]; then
    echo "WARN: ${REMAINING} unreplaced placeholder(s) found:"
    grep -rn '{{' docker/backup/
else
    echo "OK: all placeholders replaced"
fi
```

## Weryfikacja po podmienienie

```bash
# Sprawdź że żadne {{}} nie zostały
grep -rn '{{' docker/backup/ && echo "UNREPLACED FOUND" || echo "OK"

# Sprawdź że credentials NIE wyciekły do plików
grep -rn 'applicationKey\|B2_APPLICATION_KEY=' docker/backup/ && echo "CREDENTIAL LEAK!" || echo "OK"
```
