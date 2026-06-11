# Workflow konsumenta — 7 kroków od szablonów do działającego auth

Jak użyć skilla `single-user-auth-pl` v2.0.0 w nowym projekcie Next.js 14.2 LTS.

---

## Krok 1 — Skopiuj szablony do projektu

```bash
# Z katalogu agent-factory (lub paczki)
SKILL_DIR="library/skills/webapp/single-user-auth-pl"
PROJECT_DIR="~/projekty/demo-app/app-nextjs"

# Kopiuj szablony (usuwając .template suffix)
cp "$SKILL_DIR/templates/iron-session.config.ts.template" \
   "$PROJECT_DIR/src/lib/session.ts"

cp "$SKILL_DIR/templates/auth-actions.ts.template" \
   "$PROJECT_DIR/src/lib/auth-actions.ts"

cp "$SKILL_DIR/templates/middleware.ts.template" \
   "$PROJECT_DIR/src/middleware.ts"

cp "$SKILL_DIR/templates/password-validators.ts.template" \
   "$PROJECT_DIR/src/lib/password-validators.ts"

cp "$SKILL_DIR/templates/audit-log.ts.template" \
   "$PROJECT_DIR/src/lib/audit-log.ts"
```

---

## Krok 2 — Zamień placeholders (sed)

```bash
cd "$PROJECT_DIR/src"

# Zastąp wszystkie placeholders we skopiowanych plikach
for f in lib/session.ts lib/auth-actions.ts middleware.ts \
          lib/password-validators.ts lib/audit-log.ts; do
  sed -i \
    -e 's/{{COOKIE_NAME}}/demoapp/g' \
    -e 's/{{APP_NAME}}/DemoApp/g' \
    -e 's/{{USER_TABLE}}/user/g' \
    -e 's/{{OWNER_NAME}}/jankowalski/g' \
    "$f"
done

echo "Placeholders zastąpione."
```

Sprawdź czy nie zostały żadne placeholders:
```bash
grep -rn '{{' src/lib/session.ts src/lib/auth-actions.ts src/middleware.ts \
  src/lib/password-validators.ts src/lib/audit-log.ts
# Output pusty = OK
```

---

## Krok 3 — Instalacja zależności

```bash
cd "$PROJECT_DIR"

# iron-session + bcryptjs + zxcvbn (stack external-crm)
pnpm add iron-session@^8.0.4 bcryptjs@^2.4.3 zxcvbn@^4.4.2

# TypeScript typy
pnpm add -D @types/bcryptjs @types/zxcvbn

# TOTP (jeśli planujesz TOTP)
pnpm add @otplib/preset-default qrcode
pnpm add -D @types/qrcode

# Structured logging
pnpm add pino pino-pretty

# Walidacja env (jeśli nie ma Zod)
pnpm add zod
```

Weryfikacja wersji po instalacji:
```bash
pnpm list iron-session bcryptjs zxcvbn
# iron-session    8.x.x
# bcryptjs        2.4.x
# zxcvbn          4.4.x
```

---

## Krok 4 — Prisma: dodaj model AuditLog + pola TOTP do User

```bash
# schema.prisma — dodaj zawartość z audit-log-schema.md (sekcja "Prisma model AuditLog")
# + pola totpSecret, totpSecretPending, totpBackupCodes do modelu User
# (zob. placeholders-reference.md sekcja "Prisma schema — dodatkowe pola User dla TOTP")

# Generuj migrację
cd "$PROJECT_DIR"
pnpm prisma migrate dev --name add_auth_audit_log

# WAŻNE: uruchom raw SQL dla RULE append-only (Prisma tego nie generuje)
# Plik: prisma/migrations/manual-audit-log-rules.sql
psql $DATABASE_URL -f prisma/migrations/manual-audit-log-rules.sql
```

Zawartość `prisma/migrations/manual-audit-log-rules.sql`:
```sql
-- Append-only enforcement audit_log
CREATE RULE no_delete_audit_log AS ON DELETE TO audit_log DO INSTEAD NOTHING;
CREATE RULE no_update_audit_log AS ON UPDATE TO audit_log DO INSTEAD NOTHING;
```

---

## Krok 5 — Zmienne środowiskowe

```bash
# Kopiuj .env.example
cp "$SKILL_DIR/placeholders-reference.md" . # otwórz i skopiuj sekcję .env.example
# LUB ręcznie:
cat > "$PROJECT_DIR/.env.local" << 'EOF'
SESSION_SECRET=""
COOKIE_NAME="demoapp"
BCRYPT_COST="12"
TOTP_REQUIRED="false"
RATE_LIMIT_LOGIN_WINDOW_MS="900000"
RATE_LIMIT_LOGIN_MAX="5"
USER_EMAIL_DEFAULT="wlasciciel@demoapp.pl"
USER_INITIAL_PASSWORD=""
LOG_LEVEL="info"
EOF

# Wygeneruj SESSION_SECRET
SESSION_SECRET=$(openssl rand -hex 32)
echo "SESSION_SECRET=$SESSION_SECRET" >> .env.local
echo "SESSION_SECRET wygenerowany i zapisany."

# Weryfikacja — min 32 znaki
echo -n "$SESSION_SECRET" | wc -c
# Musi być >= 64 (hex = 2 znaki per bajt)
```

---

## Krok 6 — Seed admin user

```bash
# Utwórz plik scripts/seed-admin.ts (wzorzec z AP-4 anti-patterns.md)
# Następnie uruchom:

cd "$PROJECT_DIR"
pnpm tsx scripts/seed-admin.ts

# Skrypt zapyta interactive o hasło właściciela
# Podaj hasło z zxcvbn score ≥ 3 (min 12 znaków, nie ze słownika)
# Przykład dobrego hasła: "Dekarz!Mazowieckie2026#Dach"
# Przykład złego hasła:   "Admin123!" (score 1/4 — zostanie odrzucone)
```

---

## Krok 7 — Test logowania

```bash
# Start dev server
cd "$PROJECT_DIR"
pnpm dev
```

Checklist manualny:
- [ ] Otwórz http://localhost:3020/login — formularz logowania widoczny
- [ ] Zaloguj się z credentialami z seed — redirect do /dashboard
- [ ] Sprawdź ciastko w DevTools → Application → Cookies:
  - Nazwa: `demoapp_session`
  - HttpOnly: tak
  - SameSite: Lax
  - Secure: nie (dev) / tak (prod)
- [ ] Otwórz nową kartę → http://localhost:3020/dashboard — działa (sesja aktywna)
- [ ] Wyloguj → redirect /login
- [ ] Sprawdź DB: `SELECT action, ts FROM audit_log ORDER BY ts DESC LIMIT 10;`
  - login.success i logout widoczne
  - ip_hash i user_agent_hash to hashe (nie plaintext)
- [ ] Test złego hasła × 5 → HTTP 429 (rate limit)
- [ ] Sprawdź pino log w terminalu: JSON, brak PII w plaintext

Jeśli wszystko OK → uruchom `quality-checker` przed merge do main.

---

## Uwagi dodatkowe

**Reset hasła (brak UI — CLI only):**
```bash
pnpm tsx scripts/reset-password.ts
# Skrypt pyta o nowe hasło, waliduje zxcvbn, zapisuje nowy hash do DB
```

**Docker:**
W `compose.yml` przekaż `SESSION_SECRET` przez Docker secrets lub env file, NIE przez wartość w compose.yml:
```yaml
services:
  app:
    env_file:
      - .env.prod  # poza gitem, na serwerze
```

**gitleaks (pre-commit):**
```bash
# Skopiuj .gitleaks.toml z external-crm (pre-commit security hook)
cp ~/external-crm/.gitleaks.toml "$PROJECT_DIR/"
# Weryfikacja: gitleaks protect --staged
```
