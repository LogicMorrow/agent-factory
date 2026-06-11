# Placeholders i zmienne środowiskowe — single-user-auth-pl v2.0.0

Kompletna lista zmiennych używanych w templatech. Zastąp przez `sed` lub ręcznie przed użyciem.

---

## Zmienne szablonów (placeholders w plikach .template)

| Placeholder | Gdzie używany | Przykładowa wartość | Opis |
|---|---|---|---|
| `{{COOKIE_NAME}}` | `iron-session.config.ts.template` | `demoapp` | Prefix nazwy cookie iron-session. Unikalna per app. |
| `{{APP_NAME}}` | `auth-actions.ts.template`, `password-validators.ts.template` | `DemoApp` | Nazwa aplikacji (trafia do TOTP issuer + blacklisty haseł) |
| `{{USER_TABLE}}` | `auth-actions.ts.template` | `user` | Nazwa modelu Prisma przechowującego hasło i TOTP secret |
| `{{OWNER_NAME}}` | `password-validators.ts.template` | `jankowalski` | Imię właściciela (trafia do blacklisty haseł zxcvbn) |

### Jak zastąpić (sed):
```bash
# Jedna komenda — zastąp wszystkie placeholders w katalogu
cd src/lib/auth
for f in *.ts; do
  sed -i \
    -e 's/{{COOKIE_NAME}}/demoapp/g' \
    -e 's/{{APP_NAME}}/DemoApp/g' \
    -e 's/{{USER_TABLE}}/user/g' \
    -e 's/{{OWNER_NAME}}/jankowalski/g' \
    "$f"
done
```

---

## Zmienne środowiskowe (env vars)

### Wymagane (brak = exit 1 przy starcie)

| Zmienna | Typ | Opis | Jak wygenerować |
|---|---|---|---|
| `SESSION_SECRET` | string, min 32 znaków | Klucz AES-256 szyfrujący cookie iron-session | `openssl rand -hex 32` |

### Opcjonalne z defaultami

| Zmienna | Default | Dopuszczalne wartości | Opis |
|---|---|---|---|
| `COOKIE_NAME` | `"demoapp"` | dowolny string bez spacji | Prefix nazwy cookie (`{COOKIE_NAME}_session`) |
| `BCRYPT_COST` | `"12"` | `"12"` do `"15"` | bcrypt cost factor (min 12 enforced kod. Wyższy = wolniejszy login ale trudniejszy cracking.) |
| `TOTP_REQUIRED` | `"false"` | `"true"` \| `"false"` | Feature flag TOTP. `true` = middleware wymusza weryfikację TOTP |
| `RATE_LIMIT_LOGIN_WINDOW_MS` | `"900000"` | liczba ms (15 min = 900000) | Okno czasowe dla rate limit logowania |
| `RATE_LIMIT_LOGIN_MAX` | `"5"` | liczba prób | Maks. prób logowania w oknie przed lockout |
| `USER_EMAIL_DEFAULT` | `""` | email właściciela | Używany przez seed-admin.ts jako default email |
| `USER_INITIAL_PASSWORD` | `""` | hasło (wymagane zxcvbn score ≥3) | Używany przez seed-admin.ts (opcjonalnie, lepiej podać interactive) |
| `LOG_LEVEL` | `"info"` | `"debug"` \| `"info"` \| `"warn"` \| `"error"` | Poziom logów pino |
| `NODE_ENV` | `"development"` | `"development"` \| `"production"` \| `"test"` | Wpływa na `secure` flag cookie + pino transport |

---

## .env.example (gotowy do skopiowania)

```bash
# single-user-auth — zmienne środowiskowe
# Skopiuj do .env i uzupełnij SESSION_SECRET
# NIGDY nie commituj .env z SESSION_SECRET do gitu

# WYMAGANE — wygeneruj: openssl rand -hex 32
SESSION_SECRET=""

# Opcjonalne — dostosuj do projektu
COOKIE_NAME="demoapp"
BCRYPT_COST="12"
TOTP_REQUIRED="false"
RATE_LIMIT_LOGIN_WINDOW_MS="900000"
RATE_LIMIT_LOGIN_MAX="5"

# Seed
USER_EMAIL_DEFAULT="wlasciciel@demoapp.pl"
USER_INITIAL_PASSWORD=""

# Observability
LOG_LEVEL="info"
```

---

## Prisma schema — dodatkowe pola User dla TOTP

```prisma
// Do dodania w modelu User ({{USER_TABLE}}):
model User {
  id                  String    @id @default(cuid)
  email               String    @unique
  passwordHash        String
  /// Aktywny secret TOTP (Base32). null = TOTP nie skonfigurowane.
  totpSecret          String?
  /// Oczekujący secret TOTP (przed potwierdzeniem pierwszego kodu)
  totpSecretPending   String?
  /// Backup codes (hashed bcrypt) — 10 szt. jednorazowych
  totpBackupCodes     String[]
  createdAt           DateTime  @default(now)
  updatedAt           DateTime  @updatedAt

  @@map("users")
}
```

---

## Porty i konfiguracja lokalna (DemoApp)

| Zasób | Port | Zmienne |
|---|---|---|
| Next.js dev server | `3020` | — |
| PostgreSQL dev | `5435` | `DATABASE_URL=postgresql://demoapp:password@localhost:5435/demoapp_dev` |
| PostgreSQL prod (Docker) | wewnętrzny `5432` | `DATABASE_URL=postgresql://demoapp:${DB_PASS}@db:5432/demoapp` |

Uwaga: porty `3020` i `5435` dobrane tak by nie kolidować z external-crm (`3000`, `5434`).
