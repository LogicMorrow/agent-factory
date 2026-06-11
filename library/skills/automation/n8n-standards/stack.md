# Stos technologiczny n8n

## Platforma główna
| Technologia | Wersja | Uwaga |
|---|---|---|
| n8n | 1.70.0 (self-hosted) | Sprawdzaj aktualną stable: hub.docker.com/r/n8nio/n8n/tags |
| PostgreSQL | 16-alpine | OBOWIĄZKOWO — nie SQLite |
| Nginx lub Caddy | latest stable | Reverse proxy + Let's Encrypt |
| Docker | 27.x | Od pierwszego commita |
| Docker Compose | v2 | |

## Kiedy n8n wystarczy
- Logika workflow jest wizualna — połączenia nodów, warunki, transformacje
- Integracje z zewnętrznymi API przez gotowe nody n8n
- Harmonogramy, webhooki, proste przepływy danych
- Zespół bez programistów lub z minimalnym kodem

## Kiedy przejść na automation-native (TypeScript + Hono + Prisma)
Przejście obowiązkowe gdy **≥1** z poniższych:
- n8n jest za wolny wydajnościowo dla danego obciążenia
- Logika jest zbyt złożona dla visual workflow (skomplikowane transformacje, algorytmy)
- Potrzeba kolejkowania zadań → BullMQ + Redis
- Potrzeba własnej bazy z historią, raportowaniem, panelem klienta

## Stos automation-native
Identyczny jak webapp — **patrz `webapp-standards/stack.md`**:
- Node.js 22.x + TypeScript 5.7.x (strict) + Hono.js 4.6
- PostgreSQL 16 + Prisma 5.22
- BullMQ + Redis (dla kolejkowania async)
- TypeScript/ESLint/Prettier/Vitest/Husky — identyczna konfiguracja jak webapp

## Struktura repozytorium
```
projekt-nazwa/
├── n8n-workflows/          ← eksportowane definicje workflow (JSON)
├── backups/                ← punkty przywracania
├── scripts/
│   └── backup.sh           ← automatyczny backup (executable, chmod +x)
├── docs/                   ← dokumentacja workflow i integracji
├── docker-compose.yml
├── .env.example
├── .gitignore
└── .github/
    └── workflows/          ← opcjonalnie CI dla automation-native
```

Projekty automation-n8n **nie mają** `src/` ani testów Vitest — logika w workflow JSON.
Projekty automation-native mają `src/workflows/[nazwa]/` — patrz `stack.md` → sekcja native.

## Środowiska
- **Mała automatyzacja**: dev + prod (staging opcjonalny)
- **Średnia/duża**: dev + staging + prod, każde z osobnym `.env` i osobną bazą
- Po zatwierdzeniu etapu: tag Git (`v1.0.0`) → kod zamrożony
- Eksport workflow `.json` do repo po każdym zatwierdzonym etapie
