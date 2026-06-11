# Workflow konsumenta — webapp-reverse-proxy-tls
# Skill: webapp-reverse-proxy-tls v1.0.0

7 kroków od skopiowania templates do verified production deployment.
Czas szacowany: 45-90 minut (zależy od DNS propagacji).

---

## Krok 0 — Prerequisity (sprawdź przed startem)

- [ ] `webapp-docker-templates` już zastosowany (`Dockerfile`, `compose.yml`, `compose.prod.yml` istnieją)
- [ ] `compose.yml` ma service `proxy` z obrazem `caddy:2-alpine`
- [ ] DNS A record dla `{{PROD_DOMAIN}}` → IP VPS (propagacja 5-30 min)
- [ ] Port 80 i 443 otwarty na VPS (`ufw allow 80 && ufw allow 443`)
- [ ] VPS ma dostęp do internetu (Let's Encrypt ACME challenge HTTP-01)

---

## Krok 1 — Skopiuj templates do projektu

```bash
SKILL_DIR="$HOME/agent-factory/library/skills/webapp/webapp-reverse-proxy-tls"
PROJECT_DIR="$HOME/projekty/{{PROJECT_NAME}}"  # podmień

mkdir -p "$PROJECT_DIR/src/lib"
mkdir -p "$PROJECT_DIR/docs"

# Caddyfile (prod + dev)
cp "$SKILL_DIR/templates/Caddyfile.template" "$PROJECT_DIR/Caddyfile"
cp "$SKILL_DIR/templates/Caddyfile-dev.template" "$PROJECT_DIR/Caddyfile-dev"

# Next.js middleware CSP
cp "$SKILL_DIR/templates/nextjs-middleware-csp.ts.template" "$PROJECT_DIR/src/middleware.ts"

# Hono rate limiting
cp "$SKILL_DIR/templates/rate-limit-hono.ts.template" "$PROJECT_DIR/src/lib/rate-limit.ts"

# Checklist weryfikacji
cp "$SKILL_DIR/templates/security-headers-checklist.md.template" "$PROJECT_DIR/docs/security-headers-checklist.md"

echo "Templates skopiowane."
```

---

## Krok 2 — Sed-replace placeholders

Użyj skryptu z `placeholders-reference.md` sekcja "Kompletny przykład" lub:

```bash
cd "$PROJECT_DIR"

# Minimalne zmienne wymagane
DOMAIN="demoapp.pl"         # podmień
EMAIL="you@example.com"  # podmień
PORT="3020"                # podmień

for f in Caddyfile Caddyfile-dev src/middleware.ts src/lib/rate-limit.ts docs/security-headers-checklist.md; do
  sed -i \
    -e "s/{{PROD_DOMAIN}}/$DOMAIN/g" \
    -e "s/{{ADMIN_EMAIL}}/$EMAIL/g" \
    -e "s/{{APP_PORT}}/$PORT/g" \
    -e "s/{{RATE_LIMIT_LOGIN}}/5/g" \
    -e "s/{{RATE_LIMIT_PDF}}/30/g" \
    -e "s/{{RATE_LIMIT_GLOBAL}}/100/g" \
    "$f"
done

# Weryfikacja
REMAINING=$(grep -rn '{{' Caddyfile src/middleware.ts src/lib/rate-limit.ts 2>/dev/null | wc -l)
echo "Pozostałe placeholders: $REMAINING (cel: 0)"
```

---

## Krok 3 — Dostosuj CSP sources per projekt

W `src/middleware.ts` — edytuj tablice `ADDITIONAL_*`:

```typescript
// Sentry (zalecane dla DemoApp)
const ADDITIONAL_SCRIPT_SOURCES = 'https://browser.sentry-cdn.com'
const ADDITIONAL_CONNECT_SOURCES = 'https://sentry.io https://o*.ingest.sentry.io'

// Brak Google Fonts (Tailwind + self-hosted fonts)
const ADDITIONAL_STYLE_SOURCES = ''
const ADDITIONAL_IMG_SOURCES = ''
const CSP_REPORT_URI = ''  // lub Sentry CSP endpoint
```

Sprawdź `templates/csp-policy.md.template` → sekcja "Whitelist 3rd-party per use-case".

---

## Krok 4 — DNS A record + port verification

```bash
VPS_IP="<IP VPS>"  # podmień

# Sprawdź DNS propagację
dig +short {{PROD_DOMAIN}}
# Oczekiwane: $VPS_IP

# Sprawdź porty
nc -zv $VPS_IP 80
nc -zv $VPS_IP 443
# Oczekiwane: Connection to $VPS_IP port [80|443] succeeded!
```

Jeśli DNS nie propagował → poczekaj 5-30 min lub flushuj cache:
```bash
# Linux
sudo systemd-resolve --flush-caches
# macOS
dscacheutil -flushcache && sudo killall -HUP mDNSResponder
```

---

## Krok 5 — Docker Compose up (proxy + cert)

```bash
cd "$PROJECT_DIR"

# Upewnij się że compose.yml ma volume caddy_data dla certyfikatów
grep -A2 "caddy_data" compose.yml
# Oczekiwane: caddy_data: (volume declaration)

# Start proxy (Let's Encrypt auto-fetch)
docker compose up -d proxy

# Obserwuj logi — szukaj "certificate obtained successfully"
docker compose logs -f proxy
# Oczekiwane w logach:
#   {"level":"info","msg":"certificate obtained successfully","domain":"{{PROD_DOMAIN}}"}
#   {"level":"info","msg":"serving initial configuration"}

# Timeout: 60 sekund na pobranie certyfikatu
# Jeśli błąd: "failed to get certificate" → sprawdź DNS + port 80
```

---

## Krok 6 — Start aplikacji + weryfikacja TLS

```bash
# Start całego stosu
docker compose up -d

# Poczekaj na healthcheck
sleep 35

# Weryfikacja HTTPS
curl -sf "https://{{PROD_DOMAIN}}/api/health" | python3 -m json.tool
# Oczekiwane: {"status":"ok","timestamp":"...","uptime":...}

# Weryfikacja certyfikatu
openssl s_client -connect {{PROD_DOMAIN}}:443 -servername {{PROD_DOMAIN}} < /dev/null 2>/dev/null \
  | grep -E "(Verify return|subject|issuer)"
# Oczekiwane: Verify return code: 0 (ok) + Let's Encrypt issuer
```

---

## Krok 7 — Security headers verify (checklist)

```bash
DOMAIN="{{PROD_DOMAIN}}"

echo "=== Security Headers Verification ==="

check_header {
  local name="$1" expected="$2"
  local value
  value=$(curl -sI "https://${DOMAIN}" | grep -i "^${name}:" | head -1 | sed 's/^[^:]*: *//')
  if echo "$value" | grep -q "$expected"; then
    echo "[PASS] $name: $value"
  else
    echo "[FAIL] $name: got '$value', expected contains '$expected'"
  fi
}

check_header "Strict-Transport-Security" "max-age=31536000"
check_header "X-Frame-Options" "DENY"
check_header "X-Content-Type-Options" "nosniff"
check_header "Referrer-Policy" "strict-origin-when-cross-origin"
check_header "Content-Security-Policy" "nonce-"

# CSP unsafe-eval check (must be empty)
UNSAFE=$(curl -sI "https://${DOMAIN}" | grep -i "content-security-policy" | grep "unsafe-eval")
if [ -z "$UNSAFE" ]; then
  echo "[PASS] CSP: brak unsafe-eval (OK)"
else
  echo "[FAIL] CSP: zawiera unsafe-eval! → BLOKER"
fi

echo ""
echo "=== Narzędzia online ==="
echo "securityheaders.com: https://securityheaders.com/?q=${DOMAIN}"
echo "observatory.mozilla.org: https://observatory.mozilla.org/analyze/${DOMAIN}"
echo "csp-evaluator: https://csp-evaluator.withgoogle.com/"
echo ""
echo "Target: securityheaders.com A+, observatory A+, csp-evaluator no HIGH findings"
echo "Zasada #15 pkt 9-10 PASS po wszystkich zielonych."
```

---

## Rollback (jeśli coś pójdzie nie tak)

```bash
# Zatrzymaj proxy
docker compose stop proxy

# Sprawdź logi błędów
docker compose logs proxy --tail=50

# Najczęstsze problemy:
# 1. "DNS challenge failed" → sprawdź DNS propagację + port 80
# 2. "connection refused app:3020" → app container nie startuje (healthcheck fail)
# 3. "bad config" → błąd składni Caddyfile → walidacja: caddy validate --config Caddyfile

# Walidacja Caddyfile bez uruchamiania
docker run --rm -v "$PWD/Caddyfile:/etc/caddy/Caddyfile" caddy:2-alpine caddy validate --config /etc/caddy/Caddyfile
```
