# Rate Limiting — Caddy globalny + Hono per-endpoint

## Architektura dwupoziomowa

```
Ruch → [Caddy: DDoS shield 100/min/IP] → [Hono: brute-force guard per-endpoint] → App
```

**Caddy** (poziom 1): szeroka siatka — blokuje flood/DDoS zanim dobije do aplikacji.
**Hono** (poziom 2): granularna ochrona — brute-force na auth, sensowne limity na API.

### Kalibracja (R5 — ważne)

Reguła: **Caddy globalny MUSI być wyższy niż suma Hono per-endpoint dla typowego użytkownika.**

Przykład — user robi w ciągu 1 minuty:
- 5 prób logowania (`/auth/login`: 5/min)
- 60 żądań API (`/api/*`: 60/min)
- Suma: **65/min**

Caddy limit: **100/min** → 65 < 100 → Caddy przepuszcza wszystko, Hono decyduje o logice per-endpoint.

Gdyby Caddy miał limit 50/min → Caddy blokuje normalnego użytkownika po 50 requestach, Hono nigdy nie policzy do swoich limitów brute-force → błędne metryki, frustracja.

---

## Retrofit (istniejący projekt)

### Poziom 1 — Caddy rate limit

Wymaga modułu `caddy-ratelimit` (nie ma w oficjalnym obrazie — użyj `xcaddy` lub custom build):

```bash
# Opcja A: custom image w docker-compose
# Dockerfile.caddy:
# FROM caddy:2-builder AS builder
# RUN xcaddy build --with github.com/mholt/caddy-ratelimit
# FROM caddy:2-alpine
# COPY --from=builder /usr/bin/caddy /usr/bin/caddy
```

Alternatywa bez custom build — użyj wbudowanego `limit_except` + zewnętrznego fail2ban, albo przenieś globalny rate-limit do Hono (patrz Hono global middleware poniżej).

Caddyfile z `caddy-ratelimit`:

```caddyfile
{
    order rate_limit before reverse_proxy
}

twoja-domena.pl {
    rate_limit {
        zone global {
            key {remote_host}
            events 100
            window 1m
        }
    }
    reverse_proxy api:3001
}
```

Prosta alternatywa (globalny middleware Hono zamiast Caddy dla rate-limit):
Jeśli nie chcesz custom build Caddy, możesz przenieść global rate-limit do Hono (patrz poniżej — `globalLimiter`). Caddy zostaje wyłącznie dla TLS/headers.

### Poziom 2 — Hono per-endpoint (`hono-rate-limiter`)

```bash
npm install hono-rate-limiter
```

```typescript
import { rateLimiter } from 'hono-rate-limiter';
import type { Hono } from 'hono';

// Globalny (DDoS fallback gdy brak caddy-ratelimit)
const globalLimiter = rateLimiter({
  windowMs: 60 * 1000,      // 1 minuta
  limit: 100,                // 100 req/min/IP
  standardHeaders: 'draft-6',
  keyGenerator: (c) => c.req.header('x-forwarded-for') ?? c.env?.remoteAddress ?? 'unknown',
});

// Login — brute-force guard
const loginLimiter = rateLimiter({
  windowMs: 60 * 1000,      // 1 minuta
  limit: 5,                  // 5 prób/min/IP
  message: { error: 'Too many login attempts. Try again in 1 minute.' },
  standardHeaders: 'draft-6',
  keyGenerator: (c) => c.req.header('x-forwarded-for') ?? 'unknown',
});

// Password reset — ostrzejszy
const passwordResetLimiter = rateLimiter({
  windowMs: 15 * 60 * 1000, // 15 minut
  limit: 3,                  // 3 próby/15min/IP
  message: { error: 'Too many reset attempts. Try again in 15 minutes.' },
  standardHeaders: 'draft-6',
  keyGenerator: (c) => c.req.header('x-forwarded-for') ?? 'unknown',
});

// API — sensowny limit
const apiLimiter = rateLimiter({
  windowMs: 60 * 1000,      // 1 minuta
  limit: 60,                 // 60 req/min/IP
  standardHeaders: 'draft-6',
  keyGenerator: (c) => c.req.header('x-forwarded-for') ?? 'unknown',
});

export function applyRateLimiting(app: Hono) {
  // Globalny (użyj gdy brak caddy-ratelimit)
  app.use('*', globalLimiter);

  // Per-endpoint
  app.use('/auth/login', loginLimiter);
  app.use('/auth/password-reset', passwordResetLimiter);
  app.use('/api/*', apiLimiter);
}
```

Rejestruj middleware przed route handlerami:

```typescript
// index.ts
import { applyRateLimiting } from './middleware/rate-limiting';

const app = new Hono;
applyRateLimiting(app);  // PRZED route handlers

app.route('/auth', authRoutes);
app.route('/api', apiRoutes);
```

### Uwaga: `x-forwarded-for` przez Caddy

Gdy Caddy jest przed Hono, `c.req.header('x-forwarded-for')` zawiera rzeczywiste IP użytkownika (Caddy je ustawia). Upewnij się że Caddyfile przekazuje nagłówek:

```caddyfile
twoja-domena.pl {
    reverse_proxy api:3001 {
        header_up X-Forwarded-For {remote_host}
    }
}
```

---

## New project (greenfield)

Identyczna konfiguracja. Zacznij od Hono middlewares (5 min pracy), Caddy rate limit dodaj gdy projekt rośnie.

---

## Antywzorce

- ❌ Caddy limit niższy niż suma Hono limitów — Caddy blokuje zanim Hono policzy, metryki bez sensu.
- ❌ `keyGenerator` zwracający stały string — wszystkie żądania liczą się do jednego bucketu.
- ❌ Brak `x-forwarded-for` w keyGenerator za proxy — wszystkie requesty mają IP proxy, nie użytkownika.
- ❌ Rate limit bez nagłówka `Retry-After` — klient nie wie kiedy może spróbować ponownie (standardHeaders: 'draft-6' rozwiązuje to).
- ❌ Ustawianie limitu tylko na `/auth/login` bez `/auth/register` — rejestracja też podatna na spam.

## Weryfikacja

```bash
# Test login rate limit (powinien odrzucić po 5 próbach)
for i in $(seq 1 7); do
  echo "Attempt $i:"
  curl -s -o /dev/null -w "%{http_code}" -X POST https://twoja-domena.pl/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@test.pl","password":"wrong"}'
  echo ""
done
# Oczekiwane: 200/401 x5, potem 429 x2
```

## Oficjalne docs

- hono-rate-limiter: https://github.com/rhinobase/hono-rate-limiter
- caddy-ratelimit: https://github.com/mholt/caddy-ratelimit
- HTTP 429 spec: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/429
