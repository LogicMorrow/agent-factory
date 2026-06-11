# HTTPS Retrofit — Caddy default, Nginx fallback

## Dlaczego Caddy default (nie nginx)

- **Auto Let's Encrypt bez crona** — Caddy automatycznie pobiera i odnawia certyfikaty TLS. Zero `certbot`, zero `cron`, zero "certyfikat wygasł o 3:00 bo cron nie zadziałał".
- **Jeden plik konfiguracyjny** (`Caddyfile`) — 5-10 linii zamiast 40+ linii nginx config z oddzielnymi blokami HTTP/HTTPS.
- **HTTP/3 (QUIC) out-of-box** — nginx wymaga osobnej kompilacji lub `quic` branch.
- **Wbudowany reverse proxy** — jeden binary, zero dodatkowych modułów.
- **TLS 1.3 default** — starsze protokoły wyłączone bez dodatkowej konfiguracji.

Nginx fallback: sekcja na dole, gdy projekt ma istniejący nginx config z dystrybucją systemu.

---

## Retrofit (istniejący projekt)

### Sytuacja wyjściowa
Projekt działa na `http://203.0.113.10:3001` (lub podobnie), `docker-compose.yml` bez reverse proxy.

### Krok 1 — Caddyfile

Utwórz `Caddyfile` w katalogu głównym projektu:

```caddyfile
twoja-domena.pl {
    reverse_proxy api:3001
}
```

Caddy sam:
- Pobiera certyfikat Let's Encrypt dla `twoja-domena.pl`.
- Przekierowuje HTTP (80) → HTTPS (443).
- Serwuje TLS 1.3.

Dla wielu aplikacji w jednym docker-compose:

```caddyfile
twoja-domena.pl {
    reverse_proxy api:3001
}

app2.twoja-domena.pl {
    reverse_proxy web:3000
}
```

### Krok 2 — docker-compose.yml

Dodaj service `caddy` do istniejącego `docker-compose.yml`:

```yaml
services:
  caddy:
    image: caddy:2-alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"   # HTTP/3
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - api

  # pozostałe service'y bez zmian...
  api:
    # USUŃ expose port na host — tylko Caddy ma dostęp
    # ports: - "3001:3001"   <-- zakomentuj lub usuń
    expose:
      - "3001"

volumes:
  caddy_data:
  caddy_config:
```

Uwaga: po dodaniu Caddy usuń bezpośrednie `ports` z serwisów backendowych — tylko Caddy powinien być dostępny z zewnątrz.

### Krok 3 — DNS i deploy

```bash
# 1. Ustaw rekord A w DNS: twoja-domena.pl → IP_VPS
# 2. Poczekaj na propagację (1-5 min dla większości providerów)
# 3. Deploy
docker-compose up -d caddy

# 4. Sprawdź certyfikat
curl -I https://twoja-domena.pl
# Oczekiwany nagłówek: Strict-Transport-Security: max-age=31536000 (dodany w security-headers.md)

# 5. Sprawdź redirect HTTP → HTTPS
curl -I http://twoja-domena.pl
# Oczekiwany: 301 Moved Permanently + Location: https://twoja-domena.pl
```

### Lokalne testy przed deployem (bez domeny)

```caddyfile
:443 {
    tls internal
    reverse_proxy api:3001
}
```

`tls internal` generuje self-signed certyfikat — przeglądarka zgłosi ostrzeżenie, ale TLS działa.

---

## New project (greenfield)

Dla nowego projektu od zera ten sam `Caddyfile` + blok w `docker-compose.yml` powyżej. Żadnej różnicy — Caddy jest idempotentny przy certyfikatach (nie generuje duplikatów).

---

## Nginx fallback (projekty z istniejącym nginx)

Użyj gdy: projekt ma nginx zainstalowany systemowo (nie przez Docker) i nie możesz go zastąpić.

### nginx.conf snippet (HTTPS + reverse proxy)

```nginx
server {
    listen 80;
    server_name twoja-domena.pl;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name twoja-domena.pl;

    ssl_certificate     /etc/letsencrypt/live/twoja-domena.pl/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/twoja-domena.pl/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        proxy_pass         http://localhost:3001;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}
```

### Certbot (nginx) — jednorazowo + cron

```bash
# Instalacja (Ubuntu/Debian)
apt install certbot python3-certbot-nginx

# Certyfikat
certbot --nginx -d twoja-domena.pl

# Cron odnawiania (dodaj do crontab -e)
0 3 * * * certbot renew --quiet
```

Porównanie wysiłku: Caddy = 0 komend dla TLS, Nginx = 4 kroki + cron + pilnowanie daty wygaśnięcia.

---

## Antywzorce

- ❌ Zostawianie portów backendowych (3001, 3000) otwartych na zewnątrz po dodaniu Caddy — reverse proxy traci sens.
- ❌ `tls self_signed` na produkcji — przeglądarka blokuje, HSTS nie zadziała.
- ❌ Brak `caddy_data` volume — przy restarcie kontenera certyfikaty znikają i Caddy trafi na rate-limit Let's Encrypt (50 cert/domen/tydzień).
- ❌ Nginx bez `proxy_set_header X-Forwarded-Proto $scheme` — aplikacja nie wie że request przyszedł przez HTTPS.

## Oficjalne docs

- Caddy: https://caddyserver.com/docs/
- Let's Encrypt rate limits: https://letsencrypt.org/docs/rate-limits/
- Nginx: https://nginx.org/en/docs/http/configuring_https_servers.html
