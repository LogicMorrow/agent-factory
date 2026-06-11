---
name: single-user-auth-pl
description: Minimalistyczny auth jednoosobowy dla webapp PL — iron-session 8 + bcryptjs cost 12+ + zxcvbn min score 3 + opt-in TOTP feature flag (TOTP_REQUIRED=false default), bez RBAC, RODO-aware logging (pino-redact PII), audit log per session/action. Stack spójny z external-crm. v2.0.0 REBUILD  (vs Auth.js v5 w v1.0.0). Uruchamiaj gdy bootstrap webapp produkcyjnego single-user pod audit-ready 18/18.
tools: Read, Write
model: sonnet
version: "2.0.0"
compatible_with: [webapp]
requires: [webapp-security-hardening, data-protection-rodo-pl]
tags: [auth, iron-session, bcrypt, zxcvbn, totp, single-user, rodo, audit-log, , rebuild]
token_cost: medium
distribution: library/skills/webapp/
last_updated: 2026-05-29
last_reviewed: 2026-05-29
valid_until: 2027-05-29
breaking_changes_from: "1.0.0"
breaking_changes_note: "v2.0.0 reversal Auth.js v5 → iron-session 8 + bcryptjs + zxcvbn (lesson  POST-MORTEM). Stack spójny z external-crm produkcyjnym. TOTP opt-in feature flag zamiast hard-coded TOTP v1.0.0. Audit log pino-redact zamiast NextAuth audit callback. Argon2id → bcryptjs (deps alignment CRM). Sesja 8h cookieOptions zamiast 30-dniowej JWT."
---

# Single-User Auth PL — iron-session 8 + bcryptjs + zxcvbn

Minimalistyczny auth dla aplikacji z jednym użytkownikiem. Zero multi-tenancy, zero RBAC, zero invite flow.
Stack identyczny z external-crm produkcyjnym — sprawdzony, audit-ready.

> **BREAKING v2.0.0:** Ten skill zastępuje v1.0.0 oparty na Auth.js v5. NIE używaj Auth.js v5 w projektach
> wymagających stack-spójności z external-crm. Szczegóły w `breaking_changes_note` frontmattera.

---

## 1. Kiedy uruchomić

Uruchom gdy:
- Aplikacja ma **dokładnie 1 użytkownika** (właściciel firmy, admin panel, single-tenant SaaS)
- Brak ról, brak invite flow, brak multi-tenancy
- Stack: **Next.js 14.2 LTS** (lub 15) + Prisma 5+ + PostgreSQL 16
- Projekt wymaga **spójności z external-crm** (iron-session 8 to shared dependency)
- Wymagany audit_log z PII redaction (RODO) + gotowość OWASP ASVS L2

Nie uruchamiaj gdy:
- Potrzebujesz wielu użytkowników → wybierz Clerk / Supabase Auth / NextAuth z adapter
- Potrzebujesz SSO / OAuth social login → Auth.js v5 z provider list
- Masz już Auth.js v5 zainstalowane i migracja jest niedopuszczalna kosztowo

---

## 2. Kluczowe zasady

1. **SESSION_SECRET min 32 znaków**, `openssl rand -hex 32` — walidacja Zod przy starcie; brak = exit 1.
2. **bcryptjs cost 12+** — `BCRYPT_COST=12` env (konfigurowalne, nie hardcoded). Nigdy MD5/SHA1/plaintext.
3. **zxcvbn min score 3** dla nowych haseł + min 12 znaków + PL blacklist (imiona, nazwy firm, "haslo").
4. **Sesja 8h httpOnly** + Secure (prod) + SameSite=lax + path=/ — cookieName z env `COOKIE_NAME`.
5. **lastActivity w SessionData** — refresh co request; sesja wygasa po 8h bezużycia (middleware check).
6. **Rate limit 5 fail / 15 min** na endpoint logowania (Hono rate-limiter lub in-memory LRU).
7. **TOTP feature flag `TOTP_REQUIRED=false`** — domyślnie wyłączony, włącz przed audytem. Middleware sprawdza flagę.
8. **Audit log append-only** z pino-redact PII — `ip_hash` SHA-256 zamiast IP, `user_agent_hash` zamiast UA.
9. **Prisma model AuditLog** z RULE no_delete + no_update — integralność na poziomie DB.
10. **CLI reset hasła** przez `pnpm tsx scripts/reset-password.ts` — brak UI reset w v1.

---

## 3. Pliki tematyczne (indeks)

| Plik | Zawartość |
|---|---|
| [`templates/iron-session.config.ts.template`](templates/iron-session.config.ts.template) | Config iron-session 8 + SessionData interface + Zod validateEnv |
| [`templates/auth-actions.ts.template`](templates/auth-actions.ts.template) | Server Actions: login + logout + setupTotp + verifyTotp |
| [`templates/middleware.ts.template`](templates/middleware.ts.template) | Next.js middleware: session check + lastActivity refresh + TOTP enforcement |
| [`templates/password-validators.ts.template`](templates/password-validators.ts.template) | zxcvbn integration + bcrypt hash + PL blacklist |
| [`templates/audit-log.ts.template`](templates/audit-log.ts.template) | pino-redact audit logger + writeAuditLog + akcje v1 |
| [`anti-patterns.md`](anti-patterns.md) | 6 antywzorców v2.0.0 (iron-session specific) |
| [`audit-log-schema.md`](audit-log-schema.md) | Prisma model AuditLog + retencja 5 lat + export RODO |
| [`placeholders-reference.md`](placeholders-reference.md) | Wszystkie zmienne szablonów + env vars + defaults |
| [`workflow-konsumenta.md`](workflow-konsumenta.md) | 7 kroków od cp templates do seed admin user |
| [`totp-feature-flag-guide.md`](totp-feature-flag-guide.md) | Kiedy/jak włączyć TOTP + UX dla seniora 50+ |

---

## 4. Przykłady: dobrze vs źle

### Para 1 — SESSION_SECRET i konfiguracja sesji

**Źle:**
```ts
export const sessionOptions: IronSessionOptions = {
  cookieName: "app-session",
  password: "supersecretpassword123",        // hardcoded, <32 znaków, w git
  cookieOptions: { secure: false },
};
```
Hardcoded secret = każdy z dostępem do repo ma klucz szyfrowania sesji.

**Dobrze:**
```ts
validateEnv; // exit 1 jeśli SESSION_SECRET brak lub <32 znaków
export const sessionOptions: IronSessionOptions = {
  cookieName: `${process.env.COOKIE_NAME ?? "demoapp"}_session`,
  password: process.env.SESSION_SECRET!,
  cookieOptions: {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: 60 * 60 * 8,   // 8h — OWASP ASVS L2 §3.3.1
  },
};
```

---

### Para 2 — password strength z zxcvbn

**Źle:**
```ts
async function changePassword(newPassword: string) {
  if (newPassword.length < 8) throw new Error("Za krótkie");
  const hash = await bcrypt.hash(newPassword, 10); // cost 10 < wymagane 12
}
```
Cost 10 = cracking ~4x szybszy niż cost 12. Brak zxcvbn = "Zima2026!" przejdzie.

**Dobrze:**
```ts
const PL_BLACKLIST = ["haslo", "hasło", "demoapp", "jankowalski", "admin", "qwerty"];

export function validatePasswordStrength(password: string) {
  if (password.length < 12) return { valid: false, feedback: "Min 12 znaków." };
  const result = zxcvbn(password, PL_BLACKLIST);
  if (result.score < 3) return { valid: false, score: result.score, feedback: "Za słabe." };
  return { valid: true, score: result.score, feedback: "OK" };
}

export async function hashPassword(password: string): Promise<string> {
  const cost = Math.max(parseInt(process.env.BCRYPT_COST ?? "12", 10), 12);
  return bcrypt.hash(password, cost);
}
```

---

### Para 3 — audit log z PII redaction vs bez

**Źle:**
```ts
await db.auditLog.create({ data: {
  action: "offer.create",
  metadata: { clientName: "Jan Kowalski", ip: "192.168.1.100" }, // PII plaintext
}});
```

**Dobrze:**
```ts
function hashPII(v: string) { return createHash("sha256").update(v).digest("hex").slice(0,16); }

await writeAuditLog({
  action: "offer.create",
  userId: session.userId,
  ipHash: hashPII(req.ip ?? ""),
  userAgentHash: hashPII(req.headers["user-agent"] ?? ""),
  metadata: { offerId: newOffer.id, clientIdHash: hashPII(client.phone) },
});
```

---

## 5. Antywzorce

Pełna lista w [`anti-patterns.md`](anti-patterns.md). Skrót krytycznych:

1. **SESSION_SECRET hardcoded lub <32 znaków** — KRYTYCZNY, wyciek = deszyfrowanie wszystkich sesji
2. **bcrypt cost <12** — brute-force 4-16x szybszy, audyt OWASP ASVS §2.4.1 FAIL
3. **Brak rate limit na /login** — 10 000 prób/min, konto do złamania w minutach
4. **zxcvbn skip dla "admin"** — audyt ASVS §2.1.2 FAIL; "admin" to szczególnie wrażliwe konto
5. **TOTP wymagany bez UX guidance** — Jan 50+ nie-IT: bouncing przy pierwszym QR code
6. **IP plaintext w audit_log** — IP = dane osobowe RODO; SHA-256 hash obowiązkowy

---

## 6. Instalacja zależności

```bash
pnpm add iron-session@^8.0.4 bcryptjs@^2.4.3 zxcvbn@^4.4.2 pino pino-pretty zod
pnpm add -D @types/bcryptjs @types/zxcvbn
# TOTP: pnpm add @otplib/preset-default qrcode && pnpm add -D @types/qrcode
```

---

## 7. Środowisko — zmienne wymagane

```bash
SESSION_SECRET=""           # openssl rand -hex 32 → min 32 znaków, WYMAGANE
COOKIE_NAME="demoapp"
BCRYPT_COST="12"
TOTP_REQUIRED="false"       # "true" przed audytem zewnętrznym
RATE_LIMIT_LOGIN_WINDOW_MS="900000"
RATE_LIMIT_LOGIN_MAX="5"
```

Pełna specyfikacja w [`placeholders-reference.md`](placeholders-reference.md).

---

## 8. Seed i reset hasła

```bash
pnpm tsx scripts/seed-admin.ts      # jednorazowy setup
pnpm tsx scripts/reset-password.ts  # CLI reset (brak UI — OWASP best practice)
```

---

## 9. TOTP feature flag

Default: `TOTP_REQUIRED=false`. Aktywacja przed audytem: `TOTP_REQUIRED=true`.
Szczegóły + UX dla seniora 50+ → [`totp-feature-flag-guide.md`](totp-feature-flag-guide.md).

---

## 10. Powiązania

- **`webapp-security-hardening`** (skill) — CSP, HSTS, rate limit Hono. **Wymagany.**
- **`data-protection-rodo-pl`** (skill) — retencja 5 lat, art. 15/17, export endpoint. **Wymagany.**
- **`secrets-handling`** (skill) — .env konwencje, rotacja, gitleaks pre-commit.
- **`webapp-standards`** (skill) — baza standardów Next.js 14.2 LTS.
- **`code-implementer`** (agent) — implementuje auth-actions, middleware, seed script.
- **`webapp-security-scanner`** (agent) — skanuje pod OWASP ASVS L2.
- **ADR-003** (DemoApp) — iron-session vs Auth.js v5 trade-offy, lesson POST-MORTEM .

---

## 11. Before starting work

Przed użyciem tego skilla przeczytaj:
- `knowledge-base/reflections/` last 3 (wzorce auth dla DemoApp)
- `knowledge-base/lessons.jsonl` tail 20 (szczególnie lesson POST-MORTEM )
- `knowledge-base/interviews/2026-05-29--reset-demoapp.md` sekcja 4.3

---

## 12. ACTIVITY-LOG

```
Pola wymagane: ts, actor, action, artifact, skill, skill_version, notes
actor:         "skill-builder" | "code-implementer" | "quality-checker"
action:        "skill_created" | "skill_rebuilt" | "skill_used" | "skill_reviewed"
skill:         "single-user-auth-pl"
skill_version: "2.0.0"
```
