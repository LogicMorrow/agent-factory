# Standardy testów

## Podział testów
| Typ | Narzędzie | Co testuje | Gdzie |
|---|---|---|---|
| Jednostkowe | Vitest | Services, utils, logika | obok pliku: `auth.service.test.ts` |
| Integracyjne | Vitest + Hono testClient | Endpointy API | `src/routes/__tests__/` |
| E2e | Playwright | Krytyczne ścieżki użytkownika | `e2e/` |

## Progi CI (obowiązkowe, blokują merge)
```
Pokrycie linii:    ≥ 80%
Pokrycie funkcji:  ≥ 80%
Pokrycie gałęzi:   ≥ 75%
TypeScript errors: = 0
ESLint warnings:   = 0 (--max-warnings 0)
```

## Vitest — zasady
```typescript
// Plik testu obok testowanego:
// auth.service.ts → auth.service.test.ts

// Mockowanie:
vi.mock('../repositories/user.repository')

// Nazwa opisuje zachowanie, nie implementację:
it('zwraca błąd gdy email już istnieje')   // ✓
it('testuje registerUser')                 // ✗
```

## Playwright — tylko krytyczne ścieżki
Testuj TYLKO:
- Logowanie i wylogowanie
- Główny flow biznesowy (core feature projektu)
- Kontrola dostępu (rola A nie widzi strony roli B)

**Nie duplikuj testów jednostkowych w e2e.**

Playwright odpala się TYLKO na PR do `main` — zbyt wolne na każdy push.

## Co NIE testujemy
- Migracje Prisma
- Entry pointy (`index.ts`, `server.ts`)
- Zewnętrzne API (mockujemy przez `vi.mock` lub MSW)
- Gettery/settery bez logiki

## Zasady pisania testów
1. **Deterministyczne** — nie zależą od kolejności wykonania
2. **Izolowane** — każdy test czyści po sobie (beforeEach/afterEach)
3. **Zero prawdziwych wywołań zewnętrznych API** — zawsze mock
4. **Arrange-Act-Assert** — czytelna struktura

## Uruchamianie
```bash
npm run test           # Vitest watch
npm run test:coverage  # Z raportem pokrycia
npm run test:e2e       # Playwright
npm run validate       # typecheck + lint + test (musi być zielony przed commitem)
```
