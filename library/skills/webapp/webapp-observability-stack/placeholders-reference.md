# Placeholders Reference — webapp-observability-stack

Pełna lista zmiennych `{{VARIABLE_NAME}}` używanych we wszystkich templates tego skilla.
Format sed-replace: `s/{{VARIABLE_NAME}}/wartość/g`

---

## Zmienne wymagane

| Zmienna | Opis | Przykład (DemoApp) | Template(s) |
|---|---|---|---|
| `{{PROJECT_NAME}}` | Nazwa projektu lowercase-kebab | `demo-app` | pino.config + sentry.server + healthcheck |
| `{{PROD_URL}}` | URL produkcyjny BEZ trailing slash | `https://demoapp.pl` | uptimerobot-setup |
| `{{SENTRY_DSN}}` | Sentry DSN (public-safe, z Sentry dashboard) | `https://abc@o0.ingest.sentry.io/123` | env-vars |
| `{{ADMIN_EMAIL}}` | Email admina (alert contacts UptimeRobot) | `you@example.com` | uptimerobot-setup |
| `{{SENTRY_ORG}}` | Slug organizacji Sentry | `logicmorrow` | sentry.server.config |
| `{{SENTRY_PROJECT}}` | Slug projektu Sentry | `demo-app` | sentry.server.config |

## Zmienne opcjonalne

| Zmienna | Opis | Przykład | Default |
|---|---|---|---|
| `{{LOG_LEVEL}}` | Poziom logowania pino | `info` | `info` |
| `{{UPTIMEROBOT_API_KEY}}` | API key UptimeRobot (dla programmatic pause) | `ur12345-abc` | brak |
| `{{APP_PORT}}` | Port aplikacji (spójność z webapp-docker-templates) | `3020` | `3000` |

---

## Sed-replace script (bash)

Użyj tego skryptu zamiast ręcznego edytowania każdego pliku:

```bash
#!/usr/bin/env bash
# replace-placeholders.sh — run once after copying templates

set -euo pipefail

PROJECT_NAME="{{PROJECT_NAME}}"   # ← zmień tutaj
PROD_URL="{{PROD_URL}}"           # ← zmień tutaj
SENTRY_DSN="{{SENTRY_DSN}}"       # ← zmień tutaj
ADMIN_EMAIL="{{ADMIN_EMAIL}}"     # ← zmień tutaj
SENTRY_ORG="{{SENTRY_ORG}}"       # ← zmień tutaj
SENTRY_PROJECT="{{SENTRY_PROJECT}}" # ← zmień tutaj

FILES=(
  "lib/logger.ts"
  "sentry.server.config.ts"
  "sentry.client.config.ts"
  "app/api/health/route.ts"
  "app/api/ready/route.ts"
  "app/api/version/route.ts"
  ".env.example"
  "docs/uptimerobot-setup.md"
)

for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || continue
  sed -i \
    -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" \
    -e "s|{{PROD_URL}}|${PROD_URL}|g" \
    -e "s|{{SENTRY_DSN}}|${SENTRY_DSN}|g" \
    -e "s|{{ADMIN_EMAIL}}|${ADMIN_EMAIL}|g" \
    -e "s|{{SENTRY_ORG}}|${SENTRY_ORG}|g" \
    -e "s|{{SENTRY_PROJECT}}|${SENTRY_PROJECT}|g" \
    "$f"
  echo "  replaced: $f"
done

echo "Done. Verify: grep -r '{{' . --include='*.ts' --include='*.md' --include='*.sh'"
```

---

## Spójność z webapp-docker-templates

Zmienne współdzielone (muszą mieć identyczne wartości w obu skillach):

| Zmienna | webapp-docker-templates | webapp-observability-stack |
|---|---|---|
| `{{PROJECT_NAME}}` | TAK | TAK |
| `{{APP_PORT}}` | TAK | TAK (w env-vars) |
| `{{PROD_URL}}` | NIE (skill docker nie używa) | TAK |

Jeśli używasz obu skilli — uruchom replace-placeholders.sh raz dla wszystkich plików projektu.

---

## Weryfikacja po replace

```bash
# Sprawdź czy nie zostały żadne niepodmienione zmienne
grep -r '{{' . \
  --include='*.ts' \
  --include='*.tsx' \
  --include='*.md' \
  --include='*.sh' \
  --include='*.yml' \
  | grep -v '.claude/' \
  | grep -v 'node_modules/'

# Oczekiwany output: brak (pustyi / zero lines)
```
