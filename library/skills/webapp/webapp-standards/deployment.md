# Deployment — Docker, CI/CD, środowiska

## Trzy środowiska
| Środowisko | Gdzie | Cel |
|---|---|---|
| dev | Lokalnie | Development, hot reload |
| staging | Testowy VPS (nie klienta) | QA, testy e2e, weryfikacja przed prod |
| prod | VPS klienta | Produkcja |

Każde środowisko: osobny `.env`, osobna baza danych.

## Docker — zasady
- Docker **od pierwszego commita** — nie "potem dodamy"
- Obrazy z konkretnym tagiem: `postgres:16-alpine`, `node:22-alpine` — **nigdy `latest`**
- Dockerfile produkcyjny: multi-stage (builder + runner)
- Runner: `NODE_ENV=production`, `npm ci --only=production`

```dockerfile
# Przykład Dockerfile (api)
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --only=production
COPY --from=builder /app/dist ./dist
CMD ["node", "dist/index.js"]
```

## docker-compose.dev.yml — wymagane
```yaml
services:
  db:
    image: postgres:16-alpine
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 5s
      timeout: 5s
      retries: 5
  api:
    depends_on:
      db:
        condition: service_healthy
```

## GitHub Actions CI pipeline
Uruchamia się na: push do `main`/`develop`, PR do `main`/`develop`.

```
checkout → Node 22 → npm ci → typecheck → lint → format:check
→ migracje Prisma (PostgreSQL 16-alpine service) → testy + pokrycie
→ upload Codecov
```

Playwright e2e: TYLKO na PR do `main`.

## Git workflow
```
main       — produkcja, zawsze stabilna
develop    — aktywny development
feature/X  — nowa funkcjonalność
hotfix/X   — pilna naprawa na prod
```

Po deploy na prod:
1. Utwórz tag: `git tag v1.0.0 && git push origin v1.0.0`
2. Kod zamrożony — **zero refaktoryzacji "przy okazji"**
3. Hotfix: `git checkout v1.0.0 && git checkout -b hotfix/opis` → fix → nowy tag v1.0.1 → merge do main i develop

## Checklist pre-deploy (każdy deploy na staging/prod)
- [ ] `npm run validate` — zielony (typecheck + lint + test)
- [ ] `test:coverage` ≥ 80%
- [ ] `npm run build` produkcyjny wykonany
- [ ] `.env.example` aktualny
- [ ] Migracje przetestowane na staging (NIE bezpośrednio na prod)
- [ ] `docker-compose up --build` działa na świeżym środowisku
- [ ] Testy e2e Playwright przeszły na staging
- [ ] Logi nie zawierają sekretów ani PII
- [ ] Backup bazy skonfigurowany (pg_dump cron, retencja ≥ 7 dni)
- [ ] Monitoring: Sentry + uptime monitor (UptimeRobot)
