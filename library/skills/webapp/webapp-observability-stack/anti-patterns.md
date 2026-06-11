# Anti-patterns — webapp-observability-stack

8 antywzorców z wyjaśnieniem i konkretnym fixem.

---

## AP-1 — Logowanie haseł bez pino-redact

### Źle
```typescript
// Brak redact — cały body trafia do stdout
const logger = pino({ level: 'info' })

// W Route Handler:
logger.info({ body: await req.json }, 'login attempt')
// Log output: {"body":{"email":"jan@example.com","password":"tajne123"}}
// RODO violation + security breach
```

### Dobrze
```typescript
const logger = pino({
  redact: {
    paths: ['req.body.password', 'req.body.token', 'req.body.email', 'req.body.nazwisko'],
    censor: '[Redacted]',
  },
})
// Log output: {"body":{"email":"[Redacted]","password":"[Redacted]"}}
```

**Dlaczego krytyczne:** stdout w Dockerze trafia do systemu logów (Loki v2, CloudWatch, etc.).
Wycietek logów = wycietek PII klientów = RODO violation.

---

## AP-2 — Sentry bez beforeSend PII filter

### Źle
```typescript
Sentry.init({
  dsn: process.env.SENTRY_DSN,
  // Brak beforeSend — każdy błąd z kontekstem żądania idzie do Sentry SaaS
  // Breadcrumbs z inputów formularza zawierają: imię, nazwisko, telefon klienta
})
```

### Dobrze
```typescript
Sentry.init({
  dsn: process.env.SENTRY_DSN,
  beforeSend(event) {
    if (event.request?.data) delete event.request.data   // body może mieć PII
    if (event.request?.cookies) delete event.request.cookies
    if (event.user?.email) delete event.user.email
    return event
  },
  // + filtruj breadcrumbs z ui.input
})
```

**Dlaczego krytyczne:** Sentry SaaS = przetwarzanie danych na serwerach Sentry Inc. (USA).
Dane PII klientów polskich firm → wymaga DPA z Sentry (lub Standard Contractual Clauses).
Łatwiej: filtruj PII w beforeSend i problem odpada.

---

## AP-3 — `/api/health` bez DB ping (fałszywy liveness)

### Źle
```typescript
// /api/health — tylko zwraca 200
export async function GET {
  return NextResponse.json({ status: 'ok' })
  // DB może być down, kolejka zablokowana — app "ok" ale nie serwuje ruchu
}
```

### Dobrze
```typescript
// /api/ready — readiness z DB ping
export async function GET {
  try {
    await prisma.$queryRaw`SELECT 1`
    return NextResponse.json({ status: 'ok', checks: { db: 'ok' } }, { status: 200 })
  } catch {
    return NextResponse.json({ status: 'degraded', checks: { db: 'error' } }, { status: 503 })
  }
}
```

**Podział obowiązków:**
- `/api/health` = liveness (czy proces żyje) → Docker HEALTHCHECK, basic uptime
- `/api/ready` = readiness (czy może obsługiwać ruch) → load balancer, CD healthcheck
- UptimeRobot powinien pingować `/api/ready` nie `/api/health` dla pełnej detekcji

---

## AP-4 — Audit trail mutable (brak chmod 0444)

### Źle
```bash
# Snapshot bez chmod — plik można nadpisać
cp generated-offer.pdf artifacts/audit-trail/2026/05/offer-123/oferta.pdf
# Mutable = nie jest audit trail, tylko kopia
# Audytor zewnętrzny odrzuci: "pliki mogły być zmienione po fakcie"
```

### Dobrze
```bash
cp generated-offer.pdf artifacts/audit-trail/2026/05/offer-123/oferta.pdf
chmod 0444 artifacts/audit-trail/2026/05/offer-123/oferta.pdf
# Teraz: -r--r--r-- oferta.pdf — nikt nie może nadpisać bez chmod 0644 najpierw
```

**Dlaczego krytyczne:** audit trail bez immutability = puste słowo. Audytor zewnętrzny
sprawdzi timestampy plików i możliwość edycji. chmod 0444 to minimum dowodowości.

---

## AP-5 — SENTRY_DSN w kodzie (hardcode)

### Źle
```typescript
// sentry.server.config.ts
Sentry.init({
  dsn: 'https://abc123@o0.ingest.sentry.io/456',  // hardcode w pliku
  // Gitleaks/TruffleHog w CI wykryje i zablokuje PR
})
```

### Dobrze
```typescript
Sentry.init({
  dsn: process.env.SENTRY_DSN,
  enabled: Boolean(process.env.SENTRY_DSN),
  // DSN z env — brak w repo, brak w logach CI, łatwa rotacja
})
```

**Nota:** DSN jest public-safe (widoczny w bundlu JS) — ale hardcode w repo = brak kontroli
rotacji + gitleaks false positive = CI fail.

---

## AP-6 — pino level=debug na produkcji

### Źle
```bash
# .env prod
LOG_LEVEL=debug  # tysiące linii logów per request — storage bomb
```

### Dobrze
```bash
# .env prod
LOG_LEVEL=info   # tylko istotne zdarzenia
# .env.dev
LOG_LEVEL=debug  # szczegóły tylko lokalnie
```

**Dlaczego:** `debug` generuje ~10-50x więcej danych niż `info`. Na VPS z 20GB dysku
i Loki v2 → dysk pełny w dni. Plus koszty storage w Backblaze B2 przy backup audit logów.

---

## AP-7 — UptimeRobot ping na URL w pipeline CI (każdy commit)

### Źle
```yaml
# ci.yml — WRONG
- name: Verify healthcheck
  run: curl -f https://demoapp.pl/api/health  # ping PROD na każdy commit!
  # 100 commitów/dzień × CI trigger = UptimeRobot widzi spiki
  # + CI zależy od dostępności prod → jeśli prod down, CI fail (fałszywy)
```

### Dobrze
```yaml
# ci.yml — poprawne
- name: Verify Docker build healthcheck
  run: |
    docker run -d --name test-app -p 3099:3020 ghcr.io/logicmorrow/demo-app:${{ github.sha }}
    sleep 10
    curl -f http://localhost:3099/api/health
    docker stop test-app && docker rm test-app
  # Ping lokalnego kontenera w CI — izolowany, nie dotyka prod
```

UptimeRobot pinguje prod z zewnątrz co 5 min — to jego rola, nie CI.

---

## AP-8 — Brak `enabled: false` gdy DSN pusty (Sentry throws)

### Źle
```typescript
Sentry.init({
  dsn: process.env.SENTRY_DSN,  // undefined w lokalnym dev bez .env
  // Sentry loguje warning "No DSN" do console — szum w dev
  // W niektórych wersjach może rzucać błąd
})
```

### Dobrze
```typescript
Sentry.init({
  dsn: process.env.SENTRY_DSN,
  enabled: Boolean(process.env.SENTRY_DSN),  // false = Sentry jest no-op
  // Lokalnie bez DSN: Sentry nie inicjalizuje się, brak szumu
})
```

**Bonus:** Ułatwia testowanie — set `SENTRY_DSN=""` w test env aby wyłączyć Sentry
bez modyfikacji kodu.
