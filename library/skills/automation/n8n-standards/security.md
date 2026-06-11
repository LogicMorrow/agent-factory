# Bezpieczeństwo n8n

## N8N_ENCRYPTION_KEY — zasada krytyczna
```
N8N_ENCRYPTION_KEY= # openssl rand -hex 32
```
- **Wygeneruj raz, nigdy nie zmieniaj** po pierwszym wdrożeniu
- Zmiana klucza unieważnia **wszystkie** zaszyfrowane credentiale w n8n — tracisz dostęp do wszystkich integracji
- Przechowuj klucz w bezpiecznym miejscu (password manager, vault) — bez niego nie odtworzysz credentiali
- Klucz TYLKO w `.env`, nigdy w `docker-compose.yml` bezpośrednio

## Sekrety — zasada
```
.env.example  — opis zmiennych, ZERO wartości (w repozytorium)
.env          — wartości (NIGDY w repozytorium, .gitignore)
```

Klucze API (SendGrid, Pipedrive, Anthropic, Google, itp.):
1. W `.env` na VPS jako zmienna środowiskowa
2. W n8n Credentials UI (zaszyfrowane N8N_ENCRYPTION_KEY)
3. **NIGDY** wklejone bezpośrednio do HTTP Request node — eksport workflow ujawnia sekrety

## Autoryzacja webhooków

### HMAC (preferowane dla zewnętrznych systemów)
```
Header: X-Signature: sha256=<HMAC-SHA256(secret, raw_body)>
Weryfikacja w n8n: Code node porównuje hash
```
```javascript
// Code node — weryfikacja HMAC
const crypto = require('crypto');
const signature = $headers['x-signature'];
const body = JSON.stringify($input.first.json);
const expected = 'sha256=' + crypto
  .createHmac('sha256', process.env.WEBHOOK_SECRET)
  .update(body)
  .digest('hex');
if (signature !== expected) throw new Error('Invalid signature');
```

### Bearer Token (proste integracje)
```
Header: Authorization: Bearer ${WEBHOOK_TOKEN}
```

### Basic Auth n8n UI
```
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}  # min 20 znaków
```

## HTTPS — obowiązkowo na prod
- Let's Encrypt przez Nginx lub Caddy
- `N8N_PROTOCOL=https` w env
- `WEBHOOK_URL=https://n8n.firma.pl/` (ze schematem i slash na końcu)
- HTTP na prod = FAIL security review

## Baza danych — bezpieczeństwo
- Dedykowany user PostgreSQL (nie superuser, nie `postgres`)
- Minimalnie: CONNECT, SELECT, INSERT, UPDATE, DELETE na bazie n8n
- Baza niedostępna publicznie — tylko sieć Docker
- `DB_PASSWORD` min 20 znaków losowych

## Checklist security review n8n
- [ ] `N8N_ENCRYPTION_KEY` ustawiony, min 64 znaki, tylko w `.env`
- [ ] `.env` w `.gitignore`
- [ ] Klucze API w n8n Credentials, nie w node'ach bezpośrednio
- [ ] `N8N_PROTOCOL=https` na prod
- [ ] `WEBHOOK_URL` ze schematem `https://`
- [ ] `N8N_BASIC_AUTH_ACTIVE=true` na prod
- [ ] Dedykowany user bazy (nie superuser)
- [ ] Webhooki zewnętrzne z HMAC lub Bearer Token

## Antywzorce
- ❌ Zmiana `N8N_ENCRYPTION_KEY` na działającym systemie
- ❌ `N8N_ENCRYPTION_KEY` w docker-compose.yml bezpośrednio
- ❌ API key wklejony do HTTP Request node — widoczny w eksporcie workflow
- ❌ `WEBHOOK_URL=http://` na prod
- ❌ `N8N_BASIC_AUTH_ACTIVE=false` na prod
