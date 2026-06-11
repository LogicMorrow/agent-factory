---
name: webapp-security-hardening
description: Użyj gdy projekt webapp ma lukę w: HTTPS (brak SSL), security headers, rate-limiting, secrets management. Retrofit-friendly. Caddy default, Nginx fallback, sops+age dla secrets, hono-rate-limiter dla API.
category: webapp
tags: [security, https, headers, rate-limit, secrets, retrofit, webapp]
compatible_with: [webapp]
version: 1.0
token_cost: low
requires: []
---

# webapp-security-hardening

Skill retrofitu bezpieczeństwa dla istniejących projektów webapp. Primary use case: projekt działa na `http://IP:port` bez reverse proxy, bez headers, bez rate-limitu, z sekretami w `.env` bez szyfrowania.

Komplementarny z `webapp-standards/security.md` (5 zasad baseline). Ten skill mówi **jak wdrożyć**, tamten mówi **co musi być**.

## Kiedy używać

Uruchom gdy projekt ma co najmniej jedną z tych luk:

1. **Brak HTTPS** — projekt dostępny na `http://IP:port` lub `docker-compose.yml` bez reverse proxy (nginx/Caddy/Traefik).
2. **Brak security headers** — curl na endpoint nie zwraca `Strict-Transport-Security`, `Content-Security-Policy`, `X-Frame-Options`.
3. **Brak rate-limitingu** — endpoint `/auth/login` lub `/auth/password-reset` nie ma ograniczenia liczby żądań (podatność na brute-force).
4. **Sekrety niezabezpieczone** — `.env` z hardcoded wartościami, brak szyfrowania at-rest, brak procedury rotacji.

Nie uruchamiaj gdy projekt jest na etapie lokalnego dev — hardening dotyczy staging/prod.

## Tabela decyzyjna — który sub-plik dla której luki

| Luka | Sub-plik | Szac. czas retrofit |
|---|---|---|
| Brak HTTPS / brak reverse proxy | [`https-retrofit.md`](https-retrofit.md) | 20-40 min |
| Brak security headers (CSP, HSTS, etc.) | [`security-headers.md`](security-headers.md) | 15-30 min |
| Brak rate-limitu na auth/API | [`rate-limiting.md`](rate-limiting.md) | 20-40 min |
| Sekrety w `.env` bez szyfrowania | [`secrets-management.md`](secrets-management.md) | 30-60 min |

## Retrofit workflow — typowa kolejność

Dla projektu z wieloma lukami wykonaj w tej kolejności:

```
1. HTTPS (https-retrofit.md)        → fundament, bez tego headers przez HTTP nie mają sensu
2. Security headers (security-headers.md) → po HTTPS, skonfiguruj HSTS/CSP/etc.
3. Rate-limiting (rate-limiting.md)  → auth endpoints muszą być zabezpieczone
4. Secrets management (secrets-management.md) → szyfruj .env i usuń z repo
```

Quickstart 15-minutowy (HTTPS + headers dla CRM-like VPS):
1. Skopiuj `Caddyfile` z `https-retrofit.md` (sekcja Retrofit), podmień domenę i port.
2. Dodaj service `caddy` do `docker-compose.yml` z volume `caddy_data:/data`.
3. Skopiuj blok headers z `security-headers.md` (sekcja Caddy), wklej do `Caddyfile`.
4. `docker-compose up -d caddy` — Caddy automatycznie pobierze certyfikat Let's Encrypt.
5. Sprawdź: `curl -I https://twoja-domena.pl` — powinien zwrócić `Strict-Transport-Security`.

## Antywzorce

Unikaj tych sytuacji — są pułapki spotykane w retroficie webapp:

1. **Retrofit bez kolejności** — wdrażanie rate-limit / secrets **przed** HTTPS. Rate-limit nad HTTP ujawnia tokeny w middleware, a secrets przesyłane HTTP są kompromitowane. Zawsze: HTTPS → headers → rate-limit → secrets.
2. **Caddy + ręczne certy** — ignorowanie auto-LE Caddy i wgrywanie certów z certbota do Caddyfile (`tls /path/cert.pem /path/key.pem`). Traci cały sens Caddy. Używaj auto-HTTPS, chyba że masz wildcard cert z organizacji.
3. **Kopiuj-wklej CSP z internetu bez audytu** — generyczne CSP (`script-src 'unsafe-inline'`) łamie ochronę XSS. CSP musi być dostosowane do konkretnej aplikacji — zacznij od restrykcyjnego, loguj violations, luzuj punktowo.
4. **Rate-limit per-endpoint bez globalnego** — sam Hono middleware bez Caddy globalnego = DDoS flood może wyczerpać zasoby procesu Node zanim middleware zadziała. Zawsze dwupoziomowe (kalibracja w `rate-limiting.md`).
5. **Commit `.env.sops.yaml` bez testu odszyfrowania** — zaszyfrowany plik bez walidacji że klucz age działa = po 6 miesiącach nikt nie wie jak to otworzyć. Część QUICKSTART w `secrets-management.md` obejmuje test decrypt.
6. **Hardening na dev/localhost** — uruchamianie Caddy z Let's Encrypt lokalnie marnuje certyfikaty (LE rate-limit per domena). Retrofit dotyczy staging/prod, dev zostaje na `localhost:port` bez SSL.

## Czego NIE robi

- **NIE skanuje projektu** pod kątem luk → agent `webapp-security-scanner`.
- **NIE zastępuje baseline checklisty** → `library/skills/webapp/webapp-standards/security.md`.
- **NIE pokrywa pełnego OWASP Top 10** — tylko priorytetowe (HTTPS/headers/rate-limit/secrets).
- **NIE zajmuje się WAF** (Cloudflare WAF, ModSecurity) — out of scope dla self-hosted VPS.
- **NIE robi pre-deploy checku** → agent `webapp-pre-deploy-checker`.
- **NIE pokrywa autoryzacji/RBAC** — osobny skill/agent.
- **NIE używa SaaS secrets jako default** — domyślnie sops+age (SaaS wzmiankowane w `secrets-management.md`).
- **NIE jest tutorialem dla początkujących** — zakłada znajomość Docker, Hono, curl.

## Powiązania

- **`webapp-standards/security.md`** (`library/skills/webapp/webapp-standards/security.md`) — baseline checklist (5 zasad: JWT/HttpOnly, .env, bcrypt, HTTPS, logi). Czytaj zanim zaczniesz retrofit — najpierw sprawdź co jest wymagane, potem jak wdrożyć.
- **`webapp-security-scanner`** (agent, `library/agents/webapp/`) — skanuje projekt i zgłasza luki. Uruchom przed retrofitem żeby wiedzieć co naprawić, i po retroficie dla weryfikacji.
- **`webapp-pre-deploy-checker`** (agent, `library/agents/webapp/`) — pre-deploy checklist. Uruchom po retroficie przed deployem na prod.
- **OWASP Top 10** — https://owasp.org/www-project-top-ten/ — szerszy kontekst zagrożeń web (ten skill pokrywa A02/A05/A07 z listy).
