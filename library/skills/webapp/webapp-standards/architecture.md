# Architektura — monorepo i warstwy

## Struktura monorepo (Turborepo)
```
projekt/
├── apps/
│   ├── web/          Next.js 15 — frontend
│   └── api/          Hono.js — backend REST
├── packages/
│   └── db/           Prisma schema + client (współdzielony)
├── turbo.json
├── package.json      npm workspaces
└── docker-compose.dev.yml
```

## Warstwy w apps/api/src/ — ścisły podział
```
src/
├── routes/           Tylko routing — mapowanie URL na controller
├── controllers/      Walidacja request/response, parsowanie body, kody HTTP
├── services/         Logika biznesowa — niezależna od HTTP i bazy danych
├── repositories/     Dostęp do bazy przez Prisma — tylko zapytania, zero logiki
├── middleware/       auth, logging, rate-limit, error-handling
└── types/            Typy współdzielone między warstwami
```

## Zasada separacji (dlaczego to ważne)
- **Service nie wie że istnieje baza** — woła repository przez interfejs
- **Controller nie wie że istnieje logika** — woła service, tłumaczy na HTTP
- **Efekt:** za rok można wymienić ORM lub przenieść serwis do mikroserwisu bez przepisywania kontrolerów

## Reguły warstw
| Warstwa | Może wołać | Nie może wołać |
|---|---|---|
| routes/ | controllers/ | services/, repositories/ |
| controllers/ | services/ | repositories/, Prisma |
| services/ | repositories/ | Prisma bezpośrednio, HTTP |
| repositories/ | Prisma | services/, HTTP |
| middleware/ | — | services/, repositories/ |

## Struktura Next.js (apps/web/)
```
src/
├── app/              App Router — layout, pages, loading, error
├── components/       Komponenty UI (shadcn/ui + własne)
├── hooks/            Custom React hooks
├── lib/              TanStack Query clientów, Zustand stores, utils
├── types/            Typy frontendowe
└── middleware.ts     Auth redirect
```

## Antywzorce
- ❌ Prisma bezpośrednio w controller — musi iść przez repository
- ❌ Fetch w komponencie bez TanStack Query
- ❌ Logika biznesowa w route — musi iść do service
- ❌ Współdzielony stan w localStorage — Zustand
