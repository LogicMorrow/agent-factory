---
name: webapp-standards
description: Kompletne standardy budowy aplikacji webowych operatora — stos, architektura, TypeScript, testy, security, CI/CD, Docker, baza, git. Uruchamiaj przy każdej pracy nad projektem webowym: bootstrap, code review, deploy, debug.
---

# Standardy Webapp — DemoTargi / LogicMorrow

Obowiązkowe standardy dla każdego projektu webowego. Bez wyjątków i bez alternatyw — spójność pozwala wymieniać elementy bez przepisywania całości.

## Podpliki (czytaj odpowiednie wg kontekstu)
- [`stack.md`](stack.md) — stos technologiczny, wersje, konfiguracja TypeScript
- [`architecture.md`](architecture.md) — monorepo Turborepo, warstwy API, separacja
- [`testing.md`](testing.md) — Vitest, Playwright, progi CI
- [`security.md`](security.md) — JWT, autoryzacja, sekrety, HTTPS
- [`deployment.md`](deployment.md) — Docker, GitHub Actions, środowiska, pre-deploy checklist
- [`database.md`](database.md) — Prisma, migracje, backup, schemat

## 5 zasad które nigdy nie mają wyjątku
1. **TypeScript strict wszędzie** — `noUncheckedIndexedAccess: true`, zero `!` non-null assertion, zero `any`.
2. **JWT wyłącznie w HttpOnly cookie** — localStorage = natychmiastowy FAIL security review.
3. **Sekrety tylko w `.env`** — repozytorium zawiera wyłącznie `.env.example` z opisami, zero wartości.
4. **Docker od pierwszego commita** — dev/staging/prod to osobne środowiska z osobnymi bazami.
5. **Kod zamrożony po deploy na prod** — tag Git (v1.0.0), tylko hotfix od tagu.

## Powiązania
- Agents: `webapp-bootstrapper`, `webapp-code-reviewer`, `webapp-security-scanner`, `webapp-pre-deploy-checker`
- Skills: `model-routing` (do doboru modelu przy code review i architekturze)
