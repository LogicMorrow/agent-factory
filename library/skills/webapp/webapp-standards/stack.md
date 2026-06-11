# Stos technologiczny — obowiązkowy

Wersje są zamrożone. Zmiana wersji = świadoma decyzja z wpisem do `knowledge-base/lessons.jsonl`.

## Backend
| Technologia | Wersja | Rola |
|---|---|---|
| Node.js | 22.x LTS | Runtime |
| TypeScript | 5.7.x | Język (strict: true) |
| Hono.js | 4.6 | Framework HTTP |

## Frontend
| Technologia | Wersja | Uwaga |
|---|---|---|
| Next.js | 15 (App Router) | Bez Pages Router |
| React | 19 | |
| Tailwind CSS | 3.4 | |
| Shadcn/ui | per komponent | Instalacja CLI, nie npm package |

## Baza danych
| Technologia | Wersja | Rola |
|---|---|---|
| PostgreSQL | 16 | Baza (nigdy latest w Docker) |
| Prisma | 5.22 | ORM + migracje |

## State / Walidacja
| Technologia | Wersja | Rola |
|---|---|---|
| TanStack Query | 5.62 | Data fetching + cache |
| Zustand | 5.0 | Globalny stan UI |
| Zod | 3.23 | Walidacja schematów |

## Narzędzia jakości
| Technologia | Wersja | Rola |
|---|---|---|
| ESLint | 9.15 | @typescript-eslint/strict-type-checked |
| Prettier | 3.4 | semi:true, singleQuote:true, tabWidth:2, printWidth:100 |
| Husky | 9.1 | Pre-commit hooks |
| lint-staged | 15.2 | Prettier + ESLint na staged files |
| Vitest | 2.1 | Testy jednostkowe i integracyjne |
| Playwright | 1.48 | Testy e2e |

## Infrastruktura
| Technologia | Wersja | Uwaga |
|---|---|---|
| Docker | 27.x | Od pierwszego commita |
| Docker Compose | v2 | Nigdy v1 |
| Turborepo | 2.3 | Monorepo manager |
| GitHub Actions | — | CI/CD |

## Konfiguracja TypeScript (obowiązkowa w każdym pakiecie)
```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "exactOptionalPropertyTypes": true,
    "forceConsistentCasingInFileNames": true,
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler"
  }
}
```

## Krytyczne reguły ESLint
```
no-explicit-any: error
no-floating-promises: error
await-thenable: error
no-misused-promises: error
consistent-type-imports: error
import/order: [error, { alphabetize: true }]
```

## Zakazy bezwzględne
- ❌ `any` w TypeScript
- ❌ `!` non-null assertion (obsługuj `T | undefined` wprost)
- ❌ `eslint-disable` bez udokumentowanego powodu
- ❌ `"latest"` jako tag Docker image
- ❌ `npm install <paczka>` bez sprawdzenia czy jest w standardach
