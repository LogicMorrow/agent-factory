# ADR-001 — Stack frontend+backend dla webapp produkcyjnego single-user

**Status:** Accepted
**Date:** 2026-05-29
**Decider:** operator (LogicMorrow) — zatwierdzone explicite w wywiadzie 2026-05-29

---

## Context

Budujemy webapp do wyceny robocizny dekarskiej + generowania PDF dla firmy Acme Sp. z o.o.
Pojedynczy użytkownik (Jan Nowak, 50+, nie-IT). Deadline MVP: 8 czerwca 2026 (10 dni).

**Wymogi:**
- Audit-ready: OWASP ASVS Level 2 + RODO
- Generowanie 2 PDF (oferta + wykaz drewna) z polską typografią
- Desktop-first webapp (70-80% użycia: laptop biurowy), mobile (Safari iPhone) read-only
- Stack spójny z istniejącym external-crm (Next.js 14.2.35 / pnpm 10 / TypeScript strict)
- Jakość ponad skróty (constraint operatora)

**Opcje rozważane:**
1. Next.js 14.2 LTS (fullstack) + Prisma 5 + iron-session 8 + Tailwind 4 + shadcn pattern
2. Next.js 15 RC + Auth.js v5 + bare pg
3. Remix + Drizzle + iron-session

---

## Decision

Wybrano **Next.js 14.2 LTS + Prisma 5 + iron-session 8 + bcryptjs + Tailwind 4 + shadcn pattern**.

Spójność ze sprawdzonym produkcyjnie stackiem external-crm (Next 14.2.35) minimalizuje ryzyko breaking changes w 10-dniowym oknie. Prisma przyspiesza development przez auto-generated migrations i typed client. iron-session jest lżejsze niż Auth.js v5 (mniej deps, więcej kontroli), sprawdzone audytowo w LogicMorrow.

---

## Consequences

### Pozytywne
- Spójność stacku z external-crm — operator zna wzorce, krótszy onboarding
- Prisma migrations auto-generowane — deadline 10 dni bez ręcznego pisania SQL
- Prisma Studio jako no-code podgląd danych dla Jana (bez dodatkowych narzędzi)
- iron-session: fewer deps vs Auth.js v5, pełna kontrola nad cookie handling, audit-OK
- TypeScript strict: błędy kompilacji zamiast runtime, wymagane przez OWASP ASVS L2
- shadcn pattern (komponenty kopiowane, nie biblioteka): pełna kontrola tokenów liquid-glass

### Negatywne
- Prisma vs bare pg: Prisma overhead ~10-20ms per query (akceptowalne dla 1 usera, 5-20 ofert/mc)
- Next.js 14.2 EOL w przyszłości — migracja do 15+ planowana jako v2 task (ryzyko low, 2+ lata)
- iron-session wymaga ręcznej implementacji TOTP (vs Auth.js v5 built-in) — extra dev time ~2h

### Neutralne / Ryzyka
- Next.js 15 RC nie wybrano — zbyt wiele breaking changes w 10-dniowym oknie (App Router + Server Actions zmiany). Evaluation na v2.
- shadcn pattern zamiast Mantine — Mantine ma gotowe komponenty, ale external version-lock jest sprzeczny z control over liquid-glass tokens. Trade-off: więcej pracy tworzenia komponentów vs pełna kontrola stylowania.

---

## Alternatives considered

| Option | Pros | Cons | Why rejected |
|---|---|---|---|
| **Next.js 15 RC** | Nowszy, performance improvements, lepszy bundler | Breaking changes w App Router + Server Actions, RC status (nie production-ready), niezgodność z CRM stack | Za dużo ryzyka na 10-dniowy deadline; evaluation na v2 |
| **Auth.js v5** | Built-in TOTP, OAuth providers, wbudowana sesja | 5x więcej zależności vs iron-session, "magia" utrudnia audyt, niezgodność z CRM wzorcem | CRM używa iron-session sprawdzone audytowo; mniej deps = mniejsza powierzchnia ataku |
| **bare pg (nie Prisma)** | Pełna kontrola SQL, mniejszy overhead, jak CRM | Ręczne migracje (krytyczne przy 10-dniowym deadline), brak Prisma Studio, brak typed queries | Deadline + schema mały + Prisma daje typowanie bez "skrótów" (constraint operatora) |
| **Drizzle ORM** | Lekki, bliżej SQL niż Prisma, rosnący ekosystem | Mniejszy community vs Prisma, mniej dojrzałe migrations, nieznany operatorowi | Nieznany stack = ryzyko onboardingu; Prisma sprawdzone w LogicMorrow |
| **Mantine UI** | Gotowe komponenty, niski czas dev | External version-lock, trudna customizacja tokenów liquid-glass, brak shadcn integration | Liquid-glass design system wymaga pełnej kontroli tokenów; shadcn pattern kopiowanie = zero lock |
| **Remix + Drizzle** | Modern stack, wbudowany form handling | Nieznany operatorowi, inny model niż CRM (Route Handlers vs Remix loaders), ryzyko learning curve | Stack niezgodny z CRM; czas nauki w 10 dni nieakceptowalny |

---

## References

- external-crm package.json: `~/your-app/package.json` (Next 14.2.35, pnpm 10.33.2)
- Brief wywiadu  sekcja 4: `knowledge-base/interviews/2026-05-29--reset-demoapp.md#4-stack`
- Prisma docs — migrations: https://www.prisma.io/docs/guides/migrate
- iron-session docs: https://github.com/vvo/iron-session
- OWASP ASVS L2 control V2.1 (Password Security): https://owasp.org/www-project-application-security-verification-standard/

---

## Change history

| Date | Author | Change |
|---|---|---|
| 2026-05-29 | operator (LogicMorrow) | Initial — zatwierdzone w wywiadzie  reset |
