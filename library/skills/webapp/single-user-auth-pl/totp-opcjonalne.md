# TOTP opcjonalne — flow wlaczania, QR generation, weryfikacja

## Zasady projektowe

1. **Domyslnie wylaczone** — wlasciciel firmy moze nie chciec QR code. Brak wymuszania w v1.
2. **Enforcement-ready** — jeden parametr `REQUIRE_TOTP=true` w `.env` wymusza TOTP dla wszystkich logikowan.
3. **Graceful disable** — wylaczenie TOTP wymaga podania aktualnego kodu (nie mozna wylaczycz bez dostepu do aplikacji auth).
4. **Backup codes** — generuj 10 jednorazowych kodow backup przy wlaczeniu TOTP. Jesli uzytkownik zgubi telefon — uzywa backup code i wyłącza TOTP przez CLI.

---

## Biblioteka

```bash
npm install @otplib/preset-default qrcode
npm install --save-dev @types/qrcode
```

- `@otplib/preset-default` — TOTP generation + verify (TOTP-konformny z RFC 6238)
- `qrcode` — generowanie QR code jako base64 PNG (dla `/settings/totp/enable`)

---

## Flow wlaczania TOTP

```
Uzytkownik → GET /settings/totp/enable
               │
               ▼
         Generuj sekret TOTP (32 bajty random base32)
         Zaszyfruj: OWNER_TOTP_SECRET = encrypt(secret, AUTH_SECRET)
         Nie zapisuj do DB jeszcze — tylko w sesji tymczasowej
               │
               ▼
         Wygeneruj QR code URL:
         otpauth://totp/<PLACEHOLDER_APP_NAME>:<OWNER_USERNAME>?secret=<BASE32>&issuer=<PLACEHOLDER_APP_NAME>
               │
               ▼
         Zwroc: QR code PNG (base64) + sekret w postaci tekstu
         (uzytkownik skanuje QR w Google Authenticator / Bitwarden)
               │
               ▼
         Uzytkownik → POST /api/settings/totp/enable
         Body: { code: "123456", backupCodes: null }
               │
               ▼
         Weryfikuj kod TOTP (otplib.totp.check(code, secret))
               │ PASS
               ▼
         Zapisz sekret do DB (zaszyfrowany):
         owner.totpSecret = encrypt(secret, AUTH_SECRET)
         owner.totpEnabled = true
               │
               ▼
         Generuj 10 backup codes (crypto.randomBytes, base32)
         Zapisz hash kazdego kodu do DB
         Zwroc plaintext kodow JEDNORAZOWO (uzytkownik musi zapisac)
               │
               ▼
         Log: settings.update { change: 'totp_enabled' }
```

---

## Implementacja API

### POST /api/settings/totp/enable

```ts
// app/api/settings/totp/enable/route.ts
import { authenticator } from '@otplib/preset-default';
import { auth } from '@/auth';
import { db } from '@/lib/db';
import { encryptSecret } from '@/lib/crypto';
import { writeAuditLog } from '@/lib/audit-log';

export async function POST(request: Request) {
  const session = await auth;
  if (!session?.user?.id) return new Response('Unauthorized', { status: 401 });

  const { code, pendingSecret } = await request.json;

  // Weryfikuj czy kod pasuje do sekretu tymczasowego
  const isValid = authenticator.verify({ token: code, secret: pendingSecret });
  if (!isValid) {
    return Response.json({ error: 'Nieprawidlowy kod TOTP' }, { status: 400 });
  }

  // Generuj backup codes
  const backupCodes = Array.from({ length: 10 },  =>
    // 8 znakow alfanumerycznych
    Array.from(crypto.getRandomValues(new Uint8Array(5)))
      .map((b) => b.toString(36).padStart(2, '0'))
      .join('')
      .slice(0, 8)
      .toUpperCase
  );

  const bcryptImport = await import('bcryptjs');
  const backupCodeHashes = await Promise.all(
    backupCodes.map((c) => bcryptImport.default.hash(c, 10))
  );

  const encryptedSecret = encryptSecret(pendingSecret);

  await db.owner.update({
    where: { id: session.user.id },
    data: {
      totpEnabled: true,
      totpSecret: encryptedSecret,
      backupCodes: backupCodeHashes,
    },
  });

  await writeAuditLog({
    actor_user_id: session.user.id,
    action_type: 'settings.update',
    metadata: { change: 'totp_enabled' },
  });

  // Zwroc kody JEDNORAZOWO — po tym nie mozna odtworzyc
  return Response.json({ backupCodes });
}
```

### POST /api/settings/totp/disable

```ts
// app/api/settings/totp/disable/route.ts
import { authenticator } from '@otplib/preset-default';
import { auth } from '@/auth';
import { db } from '@/lib/db';
import { decryptSecret } from '@/lib/crypto';
import { writeAuditLog } from '@/lib/audit-log';

export async function POST(request: Request) {
  const session = await auth;
  if (!session?.user?.id) return new Response('Unauthorized', { status: 401 });

  const { code } = await request.json;

  const owner = await db.owner.findFirst;
  if (!owner?.totpEnabled || !owner.totpSecret) {
    return Response.json({ error: 'TOTP nie jest wlaczone' }, { status: 400 });
  }

  const secret = decryptSecret(owner.totpSecret);
  const isValid = authenticator.verify({ token: code, secret });

  if (!isValid) {
    return Response.json({ error: 'Nieprawidlowy kod TOTP' }, { status: 400 });
  }

  await db.owner.update({
    where: { id: session.user.id },
    data: {
      totpEnabled: false,
      totpSecret: null,
      backupCodes: [],
    },
  });

  await writeAuditLog({
    actor_user_id: session.user.id,
    action_type: 'settings.update',
    metadata: { change: 'totp_disabled' },
  });

  return new Response(null, { status: 204 });
}
```

### POST /api/auth/totp/verify (w trakcie logowania)

```ts
// app/api/auth/totp/verify/route.ts
import { authenticator } from '@otplib/preset-default';
import { db } from '@/lib/db';
import { decryptSecret } from '@/lib/crypto';
import { writeAuditLog } from '@/lib/audit-log';
import { checkRateLimit, recordFailedAttempt } from '@/lib/rate-limit';

export async function POST(request: Request) {
  const ip = request.headers.get('x-forwarded-for') ?? 'unknown';
  const rl = await checkRateLimit(ip);
  if (rl.blocked) {
    return Response.json({ error: 'Zbyt wiele prob. Sprobuj pozniej.' }, { status: 429 });
  }

  const { code, pendingUserId } = await request.json;

  const owner = await db.owner.findFirst;
  if (!owner || !owner.totpSecret) {
    return Response.json({ error: 'Blad konfiguracji' }, { status: 500 });
  }

  const secret = decryptSecret(owner.totpSecret);
  const isValid = authenticator.verify({ token: code, secret });

  if (!isValid) {
    await recordFailedAttempt(ip);
    await writeAuditLog({
      actor_user_id: owner.id,
      action_type: 'login.totp_fail',
      metadata: { ip },
    });
    return Response.json({ error: 'Nieprawidlowy kod' }, { status: 400 });
  }

  await writeAuditLog({
    actor_user_id: owner.id,
    action_type: 'login.success',
    metadata: { ip, via: 'totp' },
  });

  // Stworz sesje przez signIn callback (nalezy przekazac flage z tymczasowego stanu)
  // Implementacja zalezna od sesji tymczasowej (cookie lub Redis pending_auth)
  return Response.json({ success: true });
}
```

---

## Generowanie QR code (server-side)

```ts
// lib/totp-setup.ts
import { authenticator } from '@otplib/preset-default';
import QRCode from 'qrcode';

interface TOTPSetup {
  secret: string;        // base32, przekazywany do API przy potwierdzeniu
  qrCodeDataUrl: string; // base64 PNG dla <img src="...">
  manualEntry: string;   // plaintext sekret dla manualnego wpisania
}

export async function generateTOTPSetup(
  username: string,
  appName: string,       // placeholder z konfiguracji projektu
): Promise<TOTPSetup> {
  const secret = authenticator.generateSecret(32);

  const otpauthUrl = authenticator.keyuri(username, appName, secret);

  const qrCodeDataUrl = await QRCode.toDataURL(otpauthUrl, {
    width: 256,
    margin: 2,
    color: { dark: '#000000', light: '#ffffff' },
  });

  return {
    secret,
    qrCodeDataUrl,
    manualEntry: secret,
  };
}
```

**UWAGA:** `appName` jest parametrem konfiguracyjnym projektu (placeholder), nie hardcoded nazwy firmy.

---

## Szyfrowanie sekretu TOTP w DB

Sekret TOTP w bazie musi byc zaszyfrowany — samo hashowanie nie wystarczy bo musi byc odwracalne przy weryfikacji.

```ts
// lib/crypto.ts
import { createCipheriv, createDecipheriv, randomBytes } from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const KEY = Buffer.from(process.env.AUTH_SECRET!.slice(0, 32), 'utf8'); // 32 bajty

export function encryptSecret(plaintext: string): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv(ALGORITHM, KEY, iv);
  const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final]);
  const tag = cipher.getAuthTag;
  return `${iv.toString('hex')}:${tag.toString('hex')}:${encrypted.toString('hex')}`;
}

export function decryptSecret(ciphertext: string): string {
  const [ivHex, tagHex, encryptedHex] = ciphertext.split(':');
  const iv = Buffer.from(ivHex, 'hex');
  const tag = Buffer.from(tagHex, 'hex');
  const encrypted = Buffer.from(encryptedHex, 'hex');
  const decipher = createDecipheriv(ALGORITHM, KEY, iv);
  decipher.setAuthTag(tag);
  return decipher.update(encrypted).toString('utf8') + decipher.final('utf8');
}
```

---

## Prisma schema — pola TOTP

```prisma
model Owner {
  id            String    @id @default(cuid)
  username      String    @unique
  passwordHash  String
  totpEnabled   Boolean   @default(false)
  totpSecret    String?   // AES-256-GCM encrypted base32 secret
  backupCodes   String[]  // bcrypt hashes of 10 backup codes
  createdAt     DateTime  @default(now)
  updatedAt     DateTime  @updatedAt

  auditLogs     AuditLog[]
}
```

---

## Enforcement TOTP (gotowe do wlaczenia)

W `.env`:
```env
REQUIRE_TOTP=true
```

W `auth.ts` po weryfikacji credentials:
```ts
const requireTotp = process.env.REQUIRE_TOTP === 'true';
if (requireTotp && !owner.totpEnabled) {
  // Wymusz konfiguracje TOTP przed pierwszym zalogowaniem
  throw new Error('TOTP_SETUP_REQUIRED');
}
```

Dodaj stronie `/auth/totp-setup` z instrukcja konfiguracji. Audytor zada `REQUIRE_TOTP=true` → zmien env, restart → od nastepnego logowania wymuszony.
