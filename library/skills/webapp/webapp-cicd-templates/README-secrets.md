# GitHub Secrets — konfiguracja per environment

## Architektura sekretow

```
GitHub repo
├── Secrets (repo-level)      — wspoldzielone miedzy environments
└── Environments
    ├── staging               — auto deploy (brak approval)
    │   └── Secrets           — env-scoped (nadpisuja repo-level)
    └── production            — manual approval required
        └── Secrets           — env-scoped
```

Zasada: sekrety env-scoped (staging / production) nadpisuja repo-level przy tym samym kluczu. Uzyj env-scoped dla wartosci roznych miedzy staging/prod (np. URLe, tokeny Coolify per env).

## Lista sekretow

### Coolify target (`deploy_target: coolify`)

| Secret | Environment | Opis |
|---|---|---|
| `COOLIFY_WEBHOOK_URL` | staging + production | URL webhook z Coolify UI (rozny per app) |
| `COOLIFY_WEBHOOK_TOKEN` | staging + production | Token z Coolify Settings → Deploy Webhook |

### ssh-compose target (`deploy_target: ssh-compose`)

| Secret | Environment | Opis |
|---|---|---|
| `DEPLOY_SSH_KEY` | staging + production | Zawartosc klucza prywatnego ED25519 |
| `DEPLOY_HOST` | staging + production | IP lub hostname serwera |
| `DEPLOY_USER` | staging + production | Uzytkownik SSH (np. `ubuntu`, `deploy`) |

### Opcjonalne (wspolne)

| Secret | Scope | Warunek |
|---|---|---|
| `SLACK_WEBHOOK_URL` | repo-level | Tylko gdy `slack_alerts: true` w variables.yaml |

## Krok-po-kroku: GitHub UI

### Krok 1 — Utworz environments

1. GitHub repo → **Settings** → **Environments** (lewy panel)
2. Kliknij **New environment**
3. Wpisz `staging` → **Configure environment**
4. Powtorz dla `production`

### Krok 2 — Skonfiguruj protection rule dla production

1. W environment `production` → **Environment protection rules**
2. Wlacz **Required reviewers** → dodaj siebie (`LogicMorrow`)
3. Opcjonalnie: **Deployment branches** → `Selected branches` → dodaj `main`

Efekt: deploy na production wymaga recznego klikniecia "Approve" w GitHub UI po przejsciu CI.

### Krok 3 — Dodaj sekrety do environments

Dla kazdego environment (`staging`, `production`):

1. Kliknij environment → **Add secret**
2. Dla Coolify target dodaj:
   - `COOLIFY_WEBHOOK_URL` → URL z Coolify UI (staging: URL aplikacji stagingowej, prod: URL aplikacji prod)
   - `COOLIFY_WEBHOOK_TOKEN` → Token z Coolify Settings

3. Dla ssh-compose target dodaj:
   - `DEPLOY_SSH_KEY` → wklej **cala zawartosc** klucza prywatnego (lacznie z `-----BEGIN OPENSSH PRIVATE KEY-----`)
   - `DEPLOY_HOST` → IP lub hostname
   - `DEPLOY_USER` → np. `ubuntu`

### Krok 4 — Opcjonalny Slack

Jesli `slack_alerts: true`:
1. Settings → Secrets and variables → Actions → **New repository secret**
2. Dodaj `SLACK_WEBHOOK_URL` → URL z Slack App (Incoming Webhooks)

## Weryfikacja

```bash
# Sprawdz czy secrets sa dostepne w workflow
# W Actions → run → krok z secrets → wartosc zaslepiona (***) = OK

# Sprawdz environment protection
gh api repos/{owner}/{repo}/environments
```

## Rotacja sekretow

Coolify token: Coolify UI → Settings → Regenerate → zaktualizuj GitHub Secret.

SSH key: wygeneruj nowy (`ssh-keygen -t ed25519`), dodaj nowy klucz publiczny na serwer (`ssh-copy-id`), zaktualizuj GitHub Secret, usun stary klucz z `~/.ssh/authorized_keys`.

Slack webhook: Slack App → Incoming Webhooks → Regenerate URL → zaktualizuj GitHub Secret.

**Zasada:** nigdy nie commituj sekretow do repo. Jesli przypadkowo trafiles sekret do git — natychmiast obrot token i sprawdz `git log` czy byl push.
