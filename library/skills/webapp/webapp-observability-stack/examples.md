# Przykłady użycia — webapp-observability-stack

---

## Przykład 1 — Mała apka single-user (DemoApp)

**Kontekst:** 1 użytkownik (Jan), 5-20 ofert/miesiąc, VPS 2 vCPU / 4GB RAM.
Cel: audit-ready 18/18 przy minimalnych zasobach.

### Dobrze

```typescript
// lib/logger.ts — pino z redact, level=info
export const logger = pino({
  level: 'info',
  redact: { paths: ['req.body.password', 'req.body.email', 'req.body.nazwisko'], censor: '[Redacted]' },
  base: { app: 'demo-app', env: process.env.NODE_ENV },
  timestamp: pino.stdTimeFunctions.isoTime,
})

// app/api/offers/route.ts — request logging z correlation ID
export async function POST(req: Request) {
  return withRequestLogger(req, async (log) => {
    log.info({ action: 'create_offer' }, 'offer creation started')
    const result = await createOffer(data)
    log.info({ offerId: result.id }, 'offer created successfully')
    return NextResponse.json(result)
  })
}
```

**Wynik:**
- Log: `{"level":30,"time":"2026-05-29T10:00:00.000Z","app":"demo-app","requestId":"uuid","action":"create_offer","msg":"offer creation started"}`
- PII: `nazwisko` w body nie trafia do stdout
- Sentry: free 5k events/mo — wystarczy dla 200 sessions/mc
- UptimeRobot: 1 monitor HTTP na `/api/health`, alert na email operatora
- Koszt: $0/mc

### Źle

```typescript
// Logowanie RAW request body (zawiera PII klienta)
console.log('Request body:', JSON.stringify(req.body))
// Output: {"nazwisko":"Kowalski","adres":"ul. Polna 5, Warszawa","telefon":"500100200"}
// RODO violation — PII w logach = brak compliance
```

---

## Przykład 2 — Średnia apka multi-tenant

**Kontekst:** 10 firm dekarskich, 5 userów per firma, ~500 ofert/miesiąc, multi-tenant.
Nie dotyczy DemoApp v1 — przykład dla przyszłej ewolucji lub innego projektu.

### Dobrze

```typescript
// logger z tenant context
export function getTenantLogger(tenantId: string, userId: string) {
  return logger.child({ tenantId, userId })
  // NIE loguj tenant name/email — tylko ID
}

// Sentry z tenant tag (NIE PII)
Sentry.setTag('tenant_id', tenantId)
// Sentry.setUser({ email: user.email })  // NIE — RODO
Sentry.setUser({ id: userId })             // OK — anonymizowany identyfikator
```

```typescript
// sentry.server.config.ts — niższy sample rate
tracesSampleRate: 0.02,  // 2% dla 500 req/s — nie przepełni free tier

// UptimeRobot Pro (50 monitorów, 1-min interval)
// Osobny monitor per tenant subdomain
```

### Źle

```typescript
// Sample rate 1.0 dla wysokiego ruchu = przepełnienie free tier w dni
tracesSampleRate: 1.0,  // 500 req/s × 86400s × 0.02 = 864k traces/dzień = LIMIT EXCEEDED
```

---

## Przykład 3 — Retrofit istniejącej apki bez downtime

**Kontekst:** Istniejąca apka Next.js 14 bez żadnego observability. Dodajemy pino + Sentry
bez przerwy w działaniu.

### Krok po kroku bez downtime

** — pino (zero-risk, additive):**
```bash
pnpm add pino pino-redact pino-pretty
# Dodaj lib/logger.ts z templates/pino.config.ts.template
# WAŻNE: NIE usuwaj console.log jeszcze — dodaj logger.info równolegle
```

```typescript
// Tymczasowo — dualne logowanie w przejściu
console.log('offer created:', offerId)    // stare — zostaje tymczasowo
logger.info({ offerId }, 'offer created') // nowe
```

** — healthcheck endpoints (zero-risk, additive):**
```bash
# Utwórz app/api/health/route.ts, app/api/ready/route.ts, app/api/version/route.ts
# Endpointy NIE modyfikują istniejącego kodu — są czysto additive
# Test lokalnie przed deploymentem
```

** — Sentry (additive, z feature flag):**
```typescript
// next.config.js — Sentry disabled jeśli brak DSN
// withSentryConfig wraps nextConfig - no-op jeśli SENTRY_DSN nie ustawiony
```

```bash
# Deploy z SENTRY_DSN=""  (Sentry disabled) → weryfikuj deployment poprawny
# Następny deploy z SENTRY_DSN="https://..." → Sentry włączony
```

** — UptimeRobot:**
```bash
# Setup w UptimeRobot po tym jak /api/health jest na prod
# Nie wymaga zmian kodu
```

** — cleanup:**
```bash
# Usuń console.log zastąpione przez logger.*
# Weryfikuj pino-redact działa: sprawdź stdout nie zawiera PII
grep -i 'password\|nazwisko\|email' <(docker logs demo-app 2>&1 | tail -100)
# Oczekiwany output: "[Redacted]" lub brak wyników
```

### Wynik retrofitu

- Czas wdrożenia: ~2h (bez downtime)
- Zero breaking changes w istniejącym kodzie
- Audit-ready po : zasada #15 pkt 5, 6 (stub), 7 PASS
