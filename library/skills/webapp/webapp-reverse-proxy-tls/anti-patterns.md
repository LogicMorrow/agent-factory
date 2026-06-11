# Anti-patterns — webapp-reverse-proxy-tls
# Skill: webapp-reverse-proxy-tls v1.0.0

6 antywzorców z severity, przykładem złym, dobrym i konsekwencją.

---

## AP1 — CSP `'unsafe-eval'` w produkcji (severity: CRITICAL)

**Problem:** `script-src 'unsafe-eval'` pozwala na wykonanie dowolnego JavaScript przez `eval`,
`Function`, `setTimeout(string)`. XSS injection + `eval` = Remote Code Execution w przeglądarce.

**Źle:**
```typescript
// src/middleware.ts
const csp = "script-src 'self' 'unsafe-eval' 'unsafe-inline'"
// Atakujący może wstrzyknąć: <img onerror="eval(atob('alert(document.cookie)'))" src=x>
```

**Dobrze:**
```typescript
// src/middleware.ts
const scriptSrc = `'nonce-${nonce}' 'strict-dynamic'`
// Next.js 14 App Router NIE wymaga unsafe-eval w produkcji
// Jeśli biblioteka 3rd-party wymaga unsafe-eval → rozważ zamianę biblioteki
```

**Konsekwencja:** BLOKER przy audit OWASP ASVS L2 V14.4.3. Automatic FAIL quality-checker.

**Diagnoza:** `grep -r "unsafe-eval" src/` — jeśli znajdziesz, usuń lub zamień bibliotekę.

---

## AP2 — Brak HSTS lub zbyt krótki max-age (severity: HIGH)

**Problem:** Bez HSTS przeglądarka przy pierwszym połączeniu może być SSL-stripped
(atak MITM podmienia HTTPS na HTTP zanim przeglądarka dowie się o HTTPS).

**Źle:**
```
# Brak Strict-Transport-Security header
# lub:
Strict-Transport-Security: max-age=300
# 5 minut = za krótko, HSTS preload odrzuca wartości < 31536000
```

**Dobrze:**
```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

**Konsekwencja:**
- `max-age` < 31536000 → odrzucone przez hstspreload.org → brak ochrony preload
- `includeSubDomains` wymagane dla preload list — bez niego subdomeny podatne
- Brak headera = F na observatory.mozilla.org

**Pułapka `preload`:** po dodaniu do preload list usunięcie HSTS zajmuje **miesiące** (przeglądarki cache'ują).
Przed dodaniem `preload` upewnij się że WSZYSTKIE subdomeny obsługują HTTPS.

---

## AP3 — `X-Frame-Options ALLOWALL` lub brak (severity: HIGH)

**Problem:** Bez `X-Frame-Options DENY` apka może być osadzona w `<iframe>` na złośliwej stronie.
Clickjacking attack = nakładka na iframe → ofiara klika "prześlij ofertę" myśląc że klika "zamknij".

**Źle:**
```
X-Frame-Options: ALLOWALL
# lub brak headera
# Atakujący może: <iframe src="https://demoapp.pl/oferta/123" style="opacity:0">
```

**Dobrze:**
```
X-Frame-Options: DENY
# + w CSP:
frame-ancestors 'none'
```

**Uwaga:** `X-Frame-Options` vs `frame-ancestors`:
- Oba ustawiaj (backwards compatibility z IE)
- `frame-ancestors` w CSP jest nowocześniejszy i bardziej szczegółowy
- Konflikty: jeśli oba ustawione, `frame-ancestors` ma pierwszeństwo w nowoczesnych przeglądarkach

**Wyjątek (gdy NOT to set DENY):** embed własnej apki w innej własnej domenie.
Wtedy: `X-Frame-Options: SAMEORIGIN` lub `frame-ancestors 'self' https://trusted-parent.com`.
Dla DemoApp: zawsze `DENY` (brak embed scenariusz).

---

## AP4 — Rate limit za luźny lub brak (severity: HIGH)

**Problem:** Bez rate limitu na login → brute-force attack. Bez rate limitu na PDF gen →
DoS przez wyczerpanie CPU serwera (każdy PDF = 0.5-2s obliczeniowe).

**Źle:**
```typescript
// src/app/api/auth/login/route.ts — BRAK rate limitu
export async function POST(req: Request) {
  const { email, password } = await req.json
  const user = await db.user.findUnique({ where: { email } })
  // Atakujący może próbować milion haseł per minutę
}
```

**Źle (za luźny limit):**
```typescript
// 1000 prób / minutę = brute-force dalej możliwy
const RATE_LIMIT_LOGIN = 1000
```

**Dobrze:**
```typescript
// 5 prób / 15 minut — standard OWASP ASVS L2 V2.2.1
const RATE_LIMIT_LOGIN = 5
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000

export const POST = withLoginRateLimit(loginHandler)
```

**Dobrze (dodatkowa ochrona — bcrypt timing):**
```typescript
// Zawsze wykonuj bcrypt.compare nawet gdy user nie istnieje
// Unikasz timing attack (czas odpowiedzi = sygnał czy email istnieje)
const validPassword = user
  ? await bcrypt.compare(password, user.passwordHash)
  : await bcrypt.compare(password, DUMMY_HASH)  // stały czas
```

---

## AP5 — Caddy bez `tls {email}` = self-signed certificate (severity: MEDIUM)

**Problem:** Bez dyrektywy `tls email@example.com` lub bez globalnego `email` w bloku `{}`,
Caddy generuje self-signed certificate. Przeglądarka wyświetla "Twoje połączenie jest niezabezpieczone".
Jan 50+ nie-IT może nie wiedzieć co zrobić → brak dostępu do apki.

**Źle:**
```caddyfile
demoapp.pl {
  # Brak dyrektywy tls — Caddy użyje self-signed cert
  reverse_proxy app:3020
}
```

**Dobrze:**
```caddyfile
{
  email you@example.com  # ← globalnie, raz
}

demoapp.pl {
  tls you@example.com    # ← lub ta dyrektywa per-host
  reverse_proxy app:3020
}
```

**Debugging:**
```bash
# Sprawdź czy Caddy pobił certyfikat Let's Encrypt
docker compose logs proxy | grep -E "(certificate|ACME|tls)"
# Oczekiwane: "certificate obtained successfully"

# Sprawdź issuer certyfikatu
openssl s_client -connect demoapp.pl:443 < /dev/null 2>/dev/null | grep "issuer"
# Oczekiwane: issuer=O=Let's Encrypt (NIE: issuer=O=Caddy Self-Signed)
```

**Let's Encrypt rate limits:** 5 certyfikatów per domena per tydzień.
Do testów TLS: użyj Caddy staging ACME (`acme_ca https://acme-staging-v02.api.letsencrypt.org/directory`).

---

## AP6 — CSP `report-uri` do zewnętrznej domeny nie wpisanej w `connect-src` (severity: MEDIUM)

**Problem:** Przeglądarka wysyła CSP violations raport jako POST do `report-uri`.
Jeśli endpoint jest zewnętrzną domeną NIE wymienioną w `connect-src` → raport jest blokowany przez... CSP.
Wynik: CSP działa, violations się zdarzają, ale raporty nie docierają. Debugging niemożliwy.

**Źle:**
```
Content-Security-Policy:
  connect-src 'self';
  report-uri https://sentry.io/api/12345/security/?sentry_key=xxx
# Błąd: sentry.io nie jest w connect-src → report blocked
```

**Dobrze:**
```
Content-Security-Policy:
  connect-src 'self' https://sentry.io https://o*.ingest.sentry.io;
  report-uri https://o12345.ingest.sentry.io/api/12345/security/?sentry_key=xxx
# Sentry endpoint jest w connect-src → raport dociera
```

**Alternatywa (własny endpoint):**
```
  connect-src 'self';
  report-uri /api/csp-report
# /api/csp-report = 'self' → zawsze dozwolone
```

**Migracja do `report-to` (nowoczesny standard):**
```
# Deprecated: report-uri → report-to (RFC 7469)
# report-to wymaga dodatkowego headera Report-To
# Na chwilę obecną (2026): report-uri wciąż powszechnie wspierany — zostań przy nim
# Migruj na report-to gdy Caddy + przeglądarki mają pełne wsparcie
```
