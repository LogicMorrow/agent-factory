# Placeholders reference — webapp-threat-model-template

Wszystkie placeholdery w templates mają format `{{UPPER_SNAKE_CASE}}`.

**ZASADA:** przed pierwszym deploy produkcyjnym wszystkie placeholdery muszą być podmienione. Skrypt weryfikujący: `grep -r '{{' docs/ SECURITY.md CHANGELOG.md` → zero wyników = gotowe.

**ZAKAZ używania:** `[TBD]`, `// TODO: fill`, `<placeholder>`, `???` — nierozróżnialne od treści po czasie.

---

## Lista placeholderów — minimalne wymagane przed audytem

| Placeholder | Opis | Przykładowa wartość | Pliki |
|---|---|---|---|
| `{{PROJECT_NAME}}` | Nazwa projektu (display) | `DemoApp` | threat-model, IR-procedure, SECURITY.md, runbook |
| `{{PROJECT_SLUG}}` | Slug do ścieżek/komend | `demo-app` | runbook |
| `{{PROD_DOMAIN}}` | Domena produkcyjna | `demoapp.pl` | SECURITY.md, runbook |
| `{{OWNER_NAME}}` | Imię+nazwisko maintainera | `operator (LogicMorrow)` | SECURITY.md, IR-procedure, runbook |
| `{{OWNER_EMAIL}}` | Email maintainera | `you@example.com` | SECURITY.md, IR-procedure, runbook |
| `{{OWNER_PHONE}}` | Telefon do eskalacji | `+48 XXX XXX XXX` | runbook |
| `{{COMPANY_NAME}}` | Nazwa firmy (admin RODO) | `Acme Sp. z o.o.` | SECURITY.md, IR-procedure |
| `{{COMPANY_NIP}}` | NIP firmy | `0000000000` | SECURITY.md, IR-procedure |
| `{{GPG_FINGERPRINT}}` | Fingerprint klucza GPG | `A1B2 C3D4 E5F6 7890 ABCD ...` | SECURITY.md |
| `{{VPS_PROD_HOST}}` | IP lub hostname VPS prod | `prod.demoapp.pl` lub `1.2.3.4` | runbook |
| `{{VPS_USER}}` | User SSH do VPS | `deploy` lub `operator` | runbook |
| `{{APP_PORT}}` | Port wewnętrzny aplikacji | `3020` | runbook |
| `{{GITHUB_ORG}}` | Organizacja GitHub | `LogicMorrow` | runbook |
| `{{DB_USER}}` | User PostgreSQL | `demoapp_app` | runbook |
| `{{DB_NAME}}` | Nazwa bazy danych | `demoapp_production` | runbook |
| `{{DB_PASSWORD}}` | Hasło DB (z Docker secrets) | `[nie w plikach — z env]` | runbook (komentarz) |
| `{{B2_BUCKET_NAME}}` | Nazwa bucketu Backblaze B2 | `demoapp-backups` | runbook |
| `{{SENTRY_ORG}}` | Slug organizacji Sentry | `logicmorrow` | runbook |
| `{{SENTRY_PROJECT}}` | Slug projektu Sentry | `demo-app` | runbook |
| `{{WORKING_HOURS}}` | Godziny robocze SLA | `8:00-18:00 CET, Mon-Fri` | runbook |
| `{{OWNER_CONTACT}}` | Kontakt do Jana | `telefon: +48 XXX XXX XXX` | IR-procedure |
| `{{RODO_ADMIN_NAME}}` | Imię+nazwisko admina RODO | `Jan Nowak` | IR-procedure |
| `{{RUNNER_REMOVAL_TOKEN}}` | Token usunięcia runnera GH | `[z GH Actions settings]` | runbook |
| `{{YYYY-MM-DD}}` | Data (wielokrotne użycie) | `2026-05-29` | wszystkie |

---

## Placeholdery opcjonalne (relewantne dla specyficznych scenariuszy)

| Placeholder | Kiedy potrzebny | Opis |
|---|---|---|
| `{{PREVIOUS_STABLE_SHA}}` | Rollback procedure | SHA ostatniego działającego deployu |
| `{{NEW_SHA}}` | Manual deploy | SHA nowego image |
| `{{BACKUP_FILE}}` | B2 restore | Nazwa pliku backup do restore |
| `{{NNN}}` | ADR-template.md | Numer ADR (3-cyfrowy: 001, 002, ...) |
| `{{TITLE}}` | ADR-template.md | Tytuł ADR |

---

## Skrypt podmiany placeholderów (przykład dla Bash)

```bash
#!/bin/bash
# Podmień podstawowe placeholdery w docs/ SECURITY.md CHANGELOG.md
# Uruchom z katalogu projektu: bash scripts/setup-docs-placeholders.sh

PROJECT_NAME="DemoApp"
PROJECT_SLUG="demo-app"
PROD_DOMAIN="demoapp.pl"
OWNER_NAME="operator (LogicMorrow)"
OWNER_EMAIL="you@example.com"
COMPANY_NAME="Acme Sp. z o.o."
COMPANY_NIP="0000000000"
GITHUB_ORG="LogicMorrow"
APP_PORT="3020"
TODAY=$(date +%Y-%m-%d)

FILES="docs/threat-model.md docs/runbook.md docs/IR-procedure.md SECURITY.md CHANGELOG.md docs/adr/*.md"

for FILE in $FILES; do
  [ -f "$FILE" ] || continue
  sed -i \
    -e "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" \
    -e "s/{{PROJECT_SLUG}}/${PROJECT_SLUG}/g" \
    -e "s/{{PROD_DOMAIN}}/${PROD_DOMAIN}/g" \
    -e "s/{{OWNER_NAME}}/${OWNER_NAME}/g" \
    -e "s/{{OWNER_EMAIL}}/${OWNER_EMAIL}/g" \
    -e "s/{{COMPANY_NAME}}/${COMPANY_NAME}/g" \
    -e "s/{{COMPANY_NIP}}/${COMPANY_NIP}/g" \
    -e "s/{{GITHUB_ORG}}/${GITHUB_ORG}/g" \
    -e "s/{{APP_PORT}}/${APP_PORT}/g" \
    -e "s/{{YYYY-MM-DD}}/${TODAY}/g" \
    "$FILE"
  echo "Processed: $FILE"
done

# Weryfikacja: czy zostały jakieś nieprzetworzone placeholdery?
REMAINING=$(grep -r '{{' docs/ SECURITY.md CHANGELOG.md 2>/dev/null | grep -v '{{.*}}.*#' | wc -l)
if [ "$REMAINING" -gt 0 ]; then
  echo "WARNING: $REMAINING placeholders remaining — uzupełnij ręcznie:"
  grep -r '{{' docs/ SECURITY.md CHANGELOG.md 2>/dev/null | grep -v '{{.*}}.*#'
else
  echo "OK: zero placeholders remaining"
fi
```

---

## Weryfikacja przed audytem (zero-placeholder check)

```bash
# Zero-placeholder gate — run before audit
REMAINING=$(grep -rn '{{[A-Z_]*}}' docs/ SECURITY.md CHANGELOG.md 2>/dev/null | wc -l)
if [ "$REMAINING" -gt 0 ]; then
  echo "AUDIT-READY FAIL: $REMAINING unreplaced placeholders:"
  grep -rn '{{[A-Z_]*}}' docs/ SECURITY.md CHANGELOG.md
  exit 1
fi

# Zero [TBD] / TODO gate
BAD=$(grep -rn '\[TBD\]\|// TODO:\|<placeholder>' docs/ SECURITY.md CHANGELOG.md 2>/dev/null | wc -l)
if [ "$BAD" -gt 0 ]; then
  echo "AUDIT-READY FAIL: $BAD TODO/TBD placeholders found:"
  grep -rn '\[TBD\]\|// TODO:\|<placeholder>' docs/ SECURITY.md CHANGELOG.md
  exit 1
fi

echo "PASS: zero placeholders, zero TODOs"
```
