# Antywzorce — single-user auth v2.0.0 (iron-session 8 + bcryptjs)

> **v2.0.0 REBUILD:** Antywzorce zaktualizowane pod stack iron-session 8 + bcryptjs + zxcvbn.
> Poprzednia wersja (Auth.js v5) → zob. git history. Lesson: POST-MORTEM .

---

## AP-1: SESSION_SECRET hardcoded lub < 32 znaków (KRYTYCZNY)

**Problem:**
```ts
// lib/session.ts — KRYTYCZNY BŁĄD
export const sessionOptions = {
  cookieName: "app-session",
  password: "mysecretpassword",          // hardcoded, w git, <32 znaków
  cookieOptions: { secure: false },       // HTTP w produkcji
};
```

**Konsekwencja:** SESSION_SECRET to klucz AES szyfrujący ciastko iron-session. Wyciek przez:
- Commit do publicznego repo (gitleaks tego nie złapie bez pre-commit hooka)
- `.env` bez `.gitignore` wpisu
- `docker inspect` bez secrets

= attacker deszyfruje każdą sesję, podrabia ciastko z dowolnym `userId`. Pełny dostęp bez znajomości hasła.

Iron-session wymaga min 32 znaków entropii — krótszy secret = brak pełnej przestrzeni AES-256.

**Poprawka:**
```bash
# Generuj raz, trzymaj w Docker secrets / .env (poza gitem)
openssl rand -hex 32
# → SESSION_SECRET=a3f8c2d1e4b9... (64 znaki hex)
```
```ts
// validateEnv exit 1 przy starcie jeśli SESSION_SECRET brak lub <32 znaków
// Zob. templates/iron-session.config.ts.template
```

---

## AP-2: bcrypt cost < 12 (OWASP ASVS §2.4.1 FAIL)

**Problem:**
```ts
// Zbyt niski cost factor
const hash = await bcrypt.hash(password, 8);   // cost 8 = ~50ms
const hash = await bcrypt.hash(password, 10);  // cost 10 = ~200ms (default biblioteki)
```

**Konsekwencja:**
- Cost 8: GPU cracking 50k haseł/s → hasło 8-znakowe = kilka minut
- Cost 10: 10k haseł/s → kilka godzin
- Cost 12: 2.5k haseł/s → kilka dni dla silnego hasła

OWASP ASVS §2.4.1 wymagane: bcrypt cost ≥ 12 (lub Argon2id).
Audytor zewnętrzny sprawdza koszt przez `$2a$XX$...` w hachu — `$2a$10$` = FAIL.

**Poprawka:**
```ts
// lib/password-validators.ts — BCRYPT_COST env, min 12 enforced
const BCRYPT_COST = Math.max(parseInt(process.env.BCRYPT_COST ?? "12", 10), 12);
const hash = await bcrypt.hash(password, BCRYPT_COST);
```
```env
BCRYPT_COST=12   # zwiększ do 13-14 gdy CPU serwera to zniesie (<1s login UX)
```

---

## AP-3: Brak rate limit na endpoincie logowania (OWASP ASVS §2.2.1 FAIL)

**Problem:**
```ts
// app/api/login/route.ts — brak jakiegokolwiek rate limitowania
export async function POST(req: Request) {
  const { email, password } = await req.json;
  const isValid = await bcrypt.compare(password, storedHash);
  // Atakujący może próbować 24/7 bez żadnego ograniczenia
}
```

**Konsekwencja:**
```bash
# Brute-force script — 10 000 prób w kilka minut
for i in $(seq 1 10000); do
  curl -X POST https://app.pl/api/login \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"owner@firm.pl\",\"password\":\"guess$i\"}"
done
```
Nawet przy cost 12 bcrypt (~400ms/próba server-side) — jeśli atakujący ma 10 wątków = 25 prób/s = 1500/min.

**Poprawka:**
```ts
// lib/rate-limit.ts — LRU in-memory lub Redis
import { LRUCache } from "lru-cache";

const loginAttempts = new LRUCache<string, number[]>({
  max: 500,
  ttl: parseInt(process.env.RATE_LIMIT_LOGIN_WINDOW_MS ?? "900000", 10), // 15 min
});

export function checkLoginRateLimit(key: string): boolean {
  const attempts = loginAttempts.get(key) ?? [];
  const maxAttempts = parseInt(process.env.RATE_LIMIT_LOGIN_MAX ?? "5", 10);
  return attempts.length >= maxAttempts;
}
```
Dodatkowo: Hono rate-limiter na poziomie Route Handler dla API routes.

---

## AP-4: zxcvbn pomijane dla konta właściciela / "admin user"

**Problem:**
```ts
// Seed script bez walidacji siły hasła
async function seedAdminUser {
  const hash = await bcrypt.hash("Admin123!", 12); // przechodzi bez zxcvbn — score = 1
  await db.user.create({ data: { email: "admin@firm.pl", passwordHash: hash } });
  // "Admin123!" = score 1/4 w zxcvbn → słabe hasło dla najważniejszego konta
}
```

**Konsekwencja:** Konto właściciela to JEDYNE konto w aplikacji. Jego przejęcie = pełny dostęp do wszystkich danych. Hasło "Admin123!" znajdzie się na każdej liście breached passwords (Have I Been Pwned). OWASP ASVS §2.1.7 wymaga sprawdzenia wyciekłych haseł.

Audytor zewnętrzny testuje siłę hasła generowanego przez seed script — słabe hasło = FAIL.

**Poprawka:**
```ts
// scripts/seed-admin.ts — wymaga hasła z CLI z walidacją zxcvbn
import { validatePasswordStrength, hashPassword } from "@/lib/password-validators";
import * as readline from "readline/promises";

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const password = await rl.question("Podaj hasło właściciela (min 12 znaków, score ≥3): ");

const validation = validatePasswordStrength(password);
if (!validation.valid) {
  console.error("Hasło odrzucone:", validation.feedback);
  process.exit(1);
}

const hash = await hashPassword(password, true); // skipStrengthCheck=true bo już sprawdzono
```

---

## AP-5: TOTP_REQUIRED=true bez UX guidance dla seniora (Jan 50+)

**Problem:**
```env
# .env — włączony z dnia na dzień bez przygotowania
TOTP_REQUIRED=true
```
```
# Efekt: Jan loguje się rano, widzi ekran "Podaj kod TOTP"
# Nie wie co to "authenticator", nie wie skąd wziąć kod
# Bouncing: telefon do operatora, utrata zaufania do systemu
```

**Konsekwencja:** Dla osoby 50+ nie-IT nieoczekiwana zmiana flow logowania = blokada. Jeśli TOTP nie jest wcześniej przygotowane (setup + przetestowane + backup codes zapisane) → użytkownik zablokowany w środku dnia pracy.

**Poprawka — sekwencja prawidłowa:**
1. Wdróż z `TOTP_REQUIRED=false` (default)
2. Jan konfiguruje TOTP z pomocą operatora (onboarding 1 sesja)
3. Jan testuje TOTP przez 1-2 tygodnie z `TOTP_REQUIRED=false` (dobrowolnie)
4. Backup codes zapisane w bezpiecznym miejscu
5. Dopiero wtedy: `TOTP_REQUIRED=true` — Jan zna flow

Szczegółowy guide w [`totp-feature-flag-guide.md`](totp-feature-flag-guide.md).

---

## AP-6: IP plaintext w audit_log (RODO violation)

**Problem:**
```ts
// RODO art. 5 violation — IP to dana osobowa
await db.auditLog.create({
  data: {
    action: "login.fail",
    metadata: {
      ip: "192.168.1.100",              // PII plaintext
      userAgent: "Mozilla/5.0 ...",     // fingerprinting = PII
      email: "wlasciciel@firm.pl",      // PII plaintext — nigdy!
    },
  },
});
```

**Konsekwencja:** Adres IP jest daną osobową w rozumieniu RODO (może identyfikować osobę fizyczną — Trybunał Sprawiedliwości UE C-582/14). Wyciek audit_log = wyciek danych osobowych. Audyt RODO = FAIL.

**Poprawka:**
```ts
// lib/audit-log.ts — pino-redact + SHA-256 hash
function hashPII(value: string): string {
  return createHash("sha256").update(value).digest("hex").slice(0, 16);
}

await db.auditLog.create({
  data: {
    action: "login.fail",
    ipHash: hashPII(request.ip ?? ""),            // hash, nie IP
    userAgentHash: hashPII(request.headers["user-agent"] ?? ""),
    metadata: {
      email_hash: hashPII(email),                 // hash emaila do korelacji, nie plaintext
    },
  },
});
```
Hash SHA-256 (pierwsze 16 hex) pozwala korelować zdarzenia (ten sam IP = ta sama sekwencja) bez przechowywania oryginalnych danych osobowych. Pseudonimizacja wg RODO art. 89.
