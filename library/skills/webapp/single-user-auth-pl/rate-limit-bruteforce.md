# Rate limiting i ochrona przed brute-force

## Strategia

**Cel:** ochrona `/api/auth/signin` i `/api/auth/totp/verify` przed atakami brute-force.

**Zasady:**
- Max 5 nieudanych prob / 15 min na IP → lockout 15 min
- Cooldown 1s miedzy kazda proba (anti-automation)
- Single-user = in-memory wystarczy (jeden serwer, jeden uzytkownik)
- Upgrade path na Redis opisany ponizej

---

## In-memory (v1 — single-user, single-server)

```ts
// lib/rate-limit.ts

interface RateLimitEntry {
  failCount: number;
  firstFail: number;    // timestamp ms
  lockedUntil?: number; // timestamp ms (jesli locked)
  lastAttempt?: number; // timestamp ms (cooldown)
}

// In-memory store — restartuje sie przy restarcie serwera
// Dla single-user to akceptowalne (brak persistence = brak problemu z atakiem po restarcie)
const store = new Map<string, RateLimitEntry>;

const MAX_FAILS = 5;
const WINDOW_MS = 15 * 60 * 1000; // 15 min
const LOCKOUT_MS = 15 * 60 * 1000; // 15 min lockout
const COOLDOWN_MS = 1000;          // 1s miedzy probami

export interface RateLimitResult {
  blocked: boolean;
  reason?: 'locked' | 'cooldown';
  retryAfterMs?: number;
}

export function checkRateLimit(ip: string): RateLimitResult {
  const now = Date.now;
  const entry = store.get(ip);

  if (!entry) {
    return { blocked: false };
  }

  // Sprawdz lockout
  if (entry.lockedUntil && now < entry.lockedUntil) {
    return {
      blocked: true,
      reason: 'locked',
      retryAfterMs: entry.lockedUntil - now,
    };
  }

  // Lockout wygasl — resetuj
  if (entry.lockedUntil && now >= entry.lockedUntil) {
    store.delete(ip);
    return { blocked: false };
  }

  // Sprawdz window wygasniecia
  if (now - entry.firstFail > WINDOW_MS) {
    store.delete(ip);
    return { blocked: false };
  }

  // Cooldown miedzy probami
  if (entry.lastAttempt && now - entry.lastAttempt < COOLDOWN_MS) {
    return {
      blocked: true,
      reason: 'cooldown',
      retryAfterMs: COOLDOWN_MS - (now - entry.lastAttempt),
    };
  }

  return { blocked: false };
}

export function recordFailedAttempt(ip: string): void {
  const now = Date.now;
  const entry = store.get(ip);

  if (!entry) {
    store.set(ip, { failCount: 1, firstFail: now, lastAttempt: now });
    return;
  }

  // Jesli window wygasl — resetuj licznik
  if (now - entry.firstFail > WINDOW_MS) {
    store.set(ip, { failCount: 1, firstFail: now, lastAttempt: now });
    return;
  }

  const newCount = entry.failCount + 1;

  if (newCount >= MAX_FAILS) {
    store.set(ip, {
      ...entry,
      failCount: newCount,
      lastAttempt: now,
      lockedUntil: now + LOCKOUT_MS,
    });
    return;
  }

  store.set(ip, { ...entry, failCount: newCount, lastAttempt: now });
}

export function resetRateLimit(ip: string): void {
  store.delete(ip);
}

// Czyszczenie starych wpisow (uruchamiaj co 5 min przez setInterval lub cron)
export function cleanupExpiredEntries: void {
  const now = Date.now;
  for (const [ip, entry] of store.entries) {
    const expired =
      (!entry.lockedUntil && now - entry.firstFail > WINDOW_MS) ||
      (entry.lockedUntil && now >= entry.lockedUntil);
    if (expired) store.delete(ip);
  }
}
```

### Cleanup task (app/api/cron/cleanup-rate-limit/route.ts lub setInterval w server.ts)

```ts
// W server.ts lub custom Next.js server:
import { cleanupExpiredEntries } from '@/lib/rate-limit';

// Co 5 minut
setInterval(cleanupExpiredEntries, 5 * 60 * 1000);
```

---

## Redis (v2 — upgrade path)

Gdy:
- Wdrozenie na wiele instancji (scale out)
- Chcesz persistencji rate-limit po restarcie
- Chcesz monitorowania przez Redis dashboardy

```bash
npm install ioredis
```

```ts
// lib/rate-limit-redis.ts
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL!);

const MAX_FAILS = 5;
const WINDOW_SECS = 15 * 60;  // 15 min
const LOCKOUT_SECS = 15 * 60; // 15 min

export async function checkRateLimit(ip: string): Promise<RateLimitResult> {
  const lockKey = `auth:lock:${ip}`;
  const failKey = `auth:fail:${ip}`;

  const locked = await redis.get(lockKey);
  if (locked) {
    const ttl = await redis.ttl(lockKey);
    return { blocked: true, reason: 'locked', retryAfterMs: ttl * 1000 };
  }

  return { blocked: false };
}

export async function recordFailedAttempt(ip: string): Promise<void> {
  const failKey = `auth:fail:${ip}`;
  const lockKey = `auth:lock:${ip}`;

  const count = await redis.incr(failKey);

  if (count === 1) {
    await redis.expire(failKey, WINDOW_SECS);
  }

  if (count >= MAX_FAILS) {
    await redis.setex(lockKey, LOCKOUT_SECS, '1');
    await redis.del(failKey);
  }
}
```

**Env var dodatkowy przy upgrade:**
```env
REDIS_URL=redis://localhost:6379
```

---

## Odpowiedzi HTTP dla klienta

### Zablokowany (lockout)

```json
HTTP 429 Too Many Requests
Retry-After: 900
Content-Type: application/json

{
  "error": "Za duzo nieudanych prob logowania. Sprobuj ponownie za 15 minut.",
  "retryAfterSeconds": 900
}
```

### Cooldown (1s miedzy probami)

```json
HTTP 429 Too Many Requests
Retry-After: 1
Content-Type: application/json

{
  "error": "Poczekaj chwile przed kolejna proba."
}
```

### Bezpieczna wiadomosc bledu logowania

NIE rozrozniaj w odpowiedzi: "bledny login" od "bledne haslo". Zawsze:
```json
HTTP 401 Unauthorized
{
  "error": "Bledny login lub haslo."
}
```

Rozroznienie "login vs haslo" to user enumeration — attacker wie ze login jest poprawny i moze skupic sie na hasle.

---

## Dlaczego in-memory wystarczy dla single-user

| Argument | In-memory | Redis |
|---|---|---|
| Liczba serwerow | 1 | ≥2 |
| Restart serwera | Resetuje liczniki (akceptowalne — attacker musiałby restartowac serwer) | Persystentne przez restarty |
| Koszt | 0 (wbudowany w Node) | Docker/VPS Redis |
| Zuzyta pamiec | <1KB dla 1 IP | N/A |
| Deployment dla 1 usera | Wystarczajace | Nadmiarowe w v1 |

Dla projektu single-user na jednym VPS: in-memory jest odpowiednim wyborem na v1. Redis → v2 gdy potrzebujesz multi-instance lub Docker Swarm.
