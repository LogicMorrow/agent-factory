# Bezpieczeństwo — zasady bezwzględne

## Autoryzacja JWT
```
Biblioteki: @hono/jwt + bcryptjs (rounds: 12)
Access token: 24h, przechowywany w HttpOnly cookie
Refresh token: 7 dni (opcjonalny), też HttpOnly cookie
```

**HttpOnly cookie = ochrona przed XSS. localStorage = FAIL bez dyskusji.**

## Middleware autoryzacji
- Plik: `src/middleware/auth.middleware.ts`
- Weryfikuje każdy chroniony endpoint
- Role sprawdzane po stronie API — zmiana URL przez użytkownika nic nie daje

## Specyfikacja ról (obowiązkowa w dokumentacji)
Każdy projekt musi zawierać:
1. **Tabela ról** — rola | uprawnienia | dostępne ekrany
2. **Page inventory** — URL | nazwa | wymagana rola
3. **User flows** — sekwencje akcji → podstawa testów e2e Playwright

## Sekrety i zmienne środowiskowe
```
Repozytorium: tylko .env.example z opisami, ZERO wartości
Runtime: .env per środowisko (dev/staging/prod) — nigdy w repo
JWT_SECRET: min 64 znaki → openssl rand -hex 32
```

Obowiązkowe sekcje `.env`:
- Baza danych (DATABASE_URL)
- Aplikacja (PORT, NODE_ENV, FRONTEND_URL)
- JWT (JWT_SECRET, JWT_REFRESH_SECRET)
- Sentry DSN
- Dodatkowe per projekt (klucze API, itp.)

**Każdy klient ma własne klucze API — zero współdzielenia.**

## HTTPS
- Prod: obowiązkowo — Let's Encrypt przez Nginx lub Caddy
- HTTP → HTTPS redirect zawsze włączony
- API: authorization header lub cookie, nigdy query param

## Checklist security review
- [ ] JWT w HttpOnly cookie (nie localStorage, nie sessionStorage)
- [ ] `.env` nie w repozytorium, `.env.example` aktualny
- [ ] JWT_SECRET ≥ 64 znaki
- [ ] Wszystkie endpointy chronione (lub świadoma decyzja udokumentowana)
- [ ] Hasła hashowane bcryptjs (rounds: 12), nigdy MD5/SHA
- [ ] Baza niedostępna publicznie (localhost/Docker network)
- [ ] User bazy z minimalnymi uprawnieniymi (nie superuser)
- [ ] Logi nie zawierają sekretów ani PII

## Antywzorce
- ❌ `localStorage.setItem('token', ...)` — XSS risk, FAIL
- ❌ Sekret w kodzie lub komentarzu
- ❌ `POSTGRES_PASSWORD=postgres` na staging/prod
- ❌ Publiczny endpoint bez dokumentacji decyzji biznesowej
- ❌ `bcrypt.rounds < 10`

> Dla pełnego retrofitu HTTPS/headers/rate-limit/sops → skill `webapp-security-hardening` (`library/skills/webapp/webapp-security-hardening/`).
