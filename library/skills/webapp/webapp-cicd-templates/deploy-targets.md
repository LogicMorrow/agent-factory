# Deploy targets — Coolify vs ssh-compose

## Kiedy co

| Kryterium | Coolify | ssh-compose |
|---|---|---|
| Setup complexity | Niski (webhook one-liner) | Sredni (SSH key, compose na serwerze) |
| Zero-downtime deploy | Tak (wbudowany) | Nie (docker compose up --build = downtime) |
| Rollback | UI → Redeploy (1 klik) | SSH → git checkout + compose up |
| Build | Coolify buduje na swoim serwerze | GHA lub lokalnie, push image lub git pull |
| Podglad logow deploy | Coolify UI | SSH + `docker compose logs` |
| Koszt infrastruktury | VPS z Coolify zainstalowanym | Dowolny VPS z Docker |
| Wymagany docker-compose.yml | Nie (Coolify sam buduje) | Tak (w repo) |
| Retrofit bez Coolify | Nie dotyczy | **Startowy default dla CRM** |
| Preview per PR | Tak (Coolify wbudowany) | Nie |

**Decision rule:**
- Nowy projekt + masz Coolify → `deploy_target: coolify` (default)
- Istniejacy projekt bez Coolify → `deploy_target: ssh-compose`, upgrade path ponizej

## Coolify — setup krok po kroku

### Wymagania

- Coolify zainstalowany na VPS (`curl -fsSL https://get.coolify.io | bash`)
- Aplikacja dodana w Coolify UI (Source: GitHub, buildsystem: Nixpacks lub Dockerfile)
- Webhook token wygenerowany

### Konfiguracja webhook

1. Coolify UI → Twoja aplikacja → Settings → Deploy Webhook
2. Skopiuj URL i token
3. Dodaj do GitHub Secrets:
   - `COOLIFY_WEBHOOK_URL` = URL z Coolify
   - `COOLIFY_WEBHOOK_TOKEN` = token z Coolify

### Health check w Coolify

Opcjonalnie skonfiguruj health check w Coolify UI (Settings → Healthcheck) — dodatkowa warstwa poza GHA polling:
- URL: `/api/health`
- Interval: 30s
- Timeout: 10s
- Retries: 3

## ssh-compose — setup krok po kroku

### Wymagania

- Docker + docker-compose zainstalowane na VPS
- `docker-compose.yml` w repo projektu
- Klucz SSH z dostepem do serwera

### Generowanie klucza SSH dla CI

```bash
# Generuj dedykowany klucz (nie uzyj klucza osobistego)
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_deploy_key -N ""

# Dodaj klucz publiczny do serwera
ssh-copy-id -i ~/.ssh/github_deploy_key.pub $DEPLOY_USER@$DEPLOY_HOST
# Lub recznie: cat ~/.ssh/github_deploy_key.pub >> ~/.ssh/authorized_keys na serwerze

# Klucz prywatny → GitHub Secret DEPLOY_SSH_KEY
cat ~/.ssh/github_deploy_key
```

### Konfiguracja GitHub Secrets

Wymagane sekrety (patrz `README-secrets.md`):
- `DEPLOY_SSH_KEY` — zawartosc klucza prywatnego (caly plik z -----BEGIN openssh private key-----)
- `DEPLOY_HOST` — IP lub hostname serwera
- `DEPLOY_USER` — uzytkownik SSH (np. `deploy`, `ubuntu`)

### Minimalny docker-compose.yml (CRM-like)

```yaml
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - NODE_ENV=production
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    restart: unless-stopped

volumes:
  postgres_data:
```

### Ograniczenia ssh-compose vs Coolify

- **Brak zero-downtime** — `docker compose up --build` zatrzymuje kontener na czas buildu. Mitygacja: buduj image lokalnie/w CI i pushuj do registry, potem compose pull + up.
- **Brak rollback UI** — rollback recznie przez SSH (patrz SKILL.md sekcja Rollback).
- **Brak preview per PR** — Coolify oferuje to out-of-the-box.

## Migration path: ssh-compose → Coolify

Kiedy CRM dostanie Coolify ( planu `rozbudowa-fabryki-pod-crm`):

1. Zainstaluj Coolify na VPS: `curl -fsSL https://get.coolify.io | bash`
2. Dodaj projekt CRM do Coolify UI (Source: GitHub repo, build: Dockerfile)
3. Skonfiguruj environment variables w Coolify (przenesie .env)
4. Wygeneruj webhook URL + token
5. Zaktualizuj GitHub Secrets (dodaj `COOLIFY_WEBHOOK_URL`, `COOLIFY_WEBHOOK_TOKEN`)
6. Edytuj `deploy.yml`: odkomentuj blok Coolify, zakomentuj blok ssh-compose
7. Zaktualizuj `variables.yaml`: `deploy_target: coolify`
8. Testowy deploy: push na develop → verify Coolify deployment
9. Usun stare sekrety SSH jesli nie potrzebne (lub zachowaj jako fallback)

**Czas migracji:** ~2h (instalacja Coolify + konfiguracja + test deploy).
