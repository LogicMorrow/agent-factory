# Flow logowania — single-user auth

## Diagram (happy path + TOTP)

```
Uzytkownik → POST /api/auth/signin
                  │
                  ▼
         Rate limit check
         (5 fail / 15 min)
                  │ OK
                  ▼
         Verify credentials
         Argon2id.verify(hash, password)
                  │ PASS
                  ├── TOTP disabled ──────────────────► Utwórz sesje JWT/DB
                  │                                     Set-Cookie: httpOnly
                  │                                     Redirect → /dashboard
                  │ TOTP enabled
                  ▼
         Log: login.totp_required
         Redirect → /auth/totp
                  │
                  ▼
         POST /api/auth/totp/verify
         Verify TOTP code (TOTP.verify)
                  │ PASS
                  ▼
         Log: login.success
         Utwórz sesje JWT/DB
         Redirect → /dashboard

FAIL paths:
  - credentials invalid → log: login.fail + increment rate-limit counter
  - TOTP invalid        → log: login.totp_fail + increment rate-limit counter
  - rate limit exceeded → 429 Too Many Requests + lockout 15 min
```

---

## Auth.js v5 — konfiguracja Credentials provider

```ts
// auth.ts
import NextAuth from 'next-auth';
import Credentials from 'next-auth/providers/credentials';
import argon2 from '@node-rs/argon2';
import { db } from '@/lib/db';
import { validateEnv } from '@/lib/env-validation';
import { checkRateLimit, recordFailedAttempt } from '@/lib/rate-limit';
import { writeAuditLog } from '@/lib/audit-log';

validateEnv; // Fail fast — rzuca Error jesli brak wymaganych vars

export const { handlers, auth, signIn, signOut } = NextAuth({
  providers: [
    Credentials({
      credentials: {
        username: { label: 'Uzytkownik', type: 'text' },
        password: { label: 'Haslo', type: 'password' },
      },
      async authorize(credentials, request) {
        if (!credentials?.username || !credentials?.password) return null;

        const ip = request.headers.get('x-forwarded-for') ?? 'unknown';

        // Rate limit check
        const rl = await checkRateLimit(ip);
        if (rl.blocked) {
          await writeAuditLog({
            action_type: 'login.fail',
            metadata: { reason: 'rate_limited', ip },
          });
          throw new Error('RATE_LIMITED');
        }

        const owner = await db.owner.findFirst;
        const validUsername = credentials.username === process.env.OWNER_USERNAME;
        const validPassword = owner
          ? await argon2.verify(process.env.OWNER_PASSWORD_HASH!, credentials.password as string)
          : false;

        if (!validUsername || !validPassword) {
          await recordFailedAttempt(ip);
          await writeAuditLog({
            action_type: 'login.fail',
            metadata: { ip, user_agent: request.headers.get('user-agent') },
          });
          return null;
        }

        // Sprawdz czy TOTP wlaczone
        if (owner.totpEnabled) {
          await writeAuditLog({
            actor_user_id: owner.id,
            action_type: 'login.totp_required',
            metadata: { ip },
          });
          throw new Error('TOTP_REQUIRED');
        }

        await writeAuditLog({
          actor_user_id: owner.id,
          action_type: 'login.success',
          metadata: { ip, user_agent: request.headers.get('user-agent') },
        });

        return { id: owner.id, name: owner.username };
      },
    }),
  ],
  session: {
    strategy: 'jwt',         // lub 'database' jesli Prisma adapter
    maxAge: 30 * 24 * 60 * 60, // 30 dni
  },
  cookies: {
    sessionToken: {
      options: {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
        maxAge: 30 * 24 * 60 * 60,
      },
    },
  },
  callbacks: {
    async jwt({ token, user }) {
      if (user) token.id = user.id;
      return token;
    },
    async session({ session, token }) {
      session.user.id = token.id as string;
      return session;
    },
  },
  pages: {
    signIn: '/login',
    error: '/login',
  },
});
```

---

## Middleware — ochrona wszystkich tras

```ts
// middleware.ts
import { auth } from '@/auth';
import { NextResponse } from 'next/server';

const PUBLIC_PATHS = ['/login', '/api/auth'];

export default auth((req) => {
  const isPublic = PUBLIC_PATHS.some((p) => req.nextUrl.pathname.startsWith(p));
  if (!isPublic && !req.auth) {
    return NextResponse.redirect(new URL('/login', req.url));
  }
});

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
```

---

## Logout

```ts
// app/api/auth/signout/route.ts
import { signOut } from '@/auth';
import { writeAuditLog } from '@/lib/audit-log';
import { auth } from '@/auth';

export async function POST {
  const session = await auth;
  if (session?.user?.id) {
    await writeAuditLog({
      actor_user_id: session.user.id,
      action_type: 'logout',
      metadata: {},
    });
  }
  await signOut({ redirect: false });
  return new Response(null, { status: 204 });
}
```

---

## Seed script — tworzenie wlasciciela

```ts
// scripts/seed-owner.ts
import argon2 from '@node-rs/argon2';
import { db } from '@/lib/db';

async function seedOwner {
  const username = process.env.OWNER_USERNAME;
  const passwordHash = process.env.OWNER_PASSWORD_HASH;

  if (!username || !passwordHash) {
    console.error('BLAD: Brak OWNER_USERNAME lub OWNER_PASSWORD_HASH w .env');
    process.exit(1);
  }

  // Weryfikacja ze hash jest prawidlowy (nie plaintext)
  if (!passwordHash.startsWith('$argon2') && !passwordHash.startsWith('$2b')) {
    console.error('BLAD: OWNER_PASSWORD_HASH nie wyglada jak hash (Argon2id lub bcrypt).');
    console.error('Uruchom: npm run generate-hash aby uzyskac poprawny hash.');
    process.exit(1);
  }

  const existing = await db.owner.count;
  if (existing > 0) {
    console.log('Owner juz istnieje. Seed pominieto.');
    process.exit(0);
  }

  await db.owner.create({
    data: { username, passwordHash, totpEnabled: false },
  });

  console.log(`Owner "${username}" utworzony pomyslnie.`);
}

seedOwner.catch(console.error);
```

### Generowanie hasha (nie w runtime — tylko lokalnie przed deployem)

```bash
# scripts/generate-hash.ts
npx ts-node -e "
import argon2 from '@node-rs/argon2';
const hash = await argon2.hash('TWOJE_HASLO_TUTAJ');
console.log('OWNER_PASSWORD_HASH=' + hash);
"
# Skopiuj output do .env
# NIGDY nie commituj pliku .env do git
```

---

## CLI reset hasla (v1)

```ts
// scripts/reset-password.ts
// Uruchom: npm run reset-password -- --password=NoweHaslo123

import argon2 from '@node-rs/argon2';
import { db } from '@/lib/db';
import { writeAuditLog } from '@/lib/audit-log';

const password = process.argv.find((a) => a.startsWith('--password='))?.split('=')[1];
if (!password || password.length < 12) {
  console.error('Uzyj: npm run reset-password -- --password=MinimumDwanascieZnakow');
  process.exit(1);
}

const hash = await argon2.hash(password);
const owner = await db.owner.findFirst;
if (!owner) { console.error('Brak ownera w DB.'); process.exit(1); }

await db.owner.update({ where: { id: owner.id }, data: { passwordHash: hash } });
await writeAuditLog({
  actor_user_id: owner.id,
  action_type: 'settings.update',
  metadata: { change: 'password_reset_via_cli' },
});

console.log('Haslo zmienione. Nowy hash zapisany w DB.');
```

---

## Ekrany (screen-by-screen)

### /login

- Jedno pole "Uzytkownik" (type=text, autocomplete=username)
- Jedno pole "Haslo" (type=password, autocomplete=current-password)
- Przycisk "Zaloguj sie" (min-h-[48px])
- Blad z serwera: "Bledny login lub haslo" (NIE rozrozniaj — security)
- Blad rate-limit: "Za duzo prob. Sprobuj za 15 minut."
- Brak linku "Zarejestruj sie", "Zapomniałem hasla" — to single-user app

### /auth/totp (gdy TOTP wlaczone)

- Komunikat: "Podaj kod z aplikacji authenticator"
- Jedno pole 6-cyfrowe (type=text, inputmode=numeric, pattern=[0-9]{6})
- Przycisk "Weryfikuj" (min-h-[48px])
- Link "Cofnij do logowania" (wraca, nie tworzy sesji)

### /dashboard (po zalogowaniu)

- Brak ekranu profilu/konta — zbedny dla single-user
- Wylogowanie = przycisk w naglowku → POST /api/auth/signout
