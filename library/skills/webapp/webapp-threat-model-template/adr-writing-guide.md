# ADR Writing Guide — jak pisać Architecture Decision Records

Wzorce pisania ADR-ów + antywzorce wykryte w praktyce (lesson  fundamental error).

---

## Co to jest ADR i dlaczego ważne

**ADR (Architecture Decision Record)** = dokument pojedynczej decyzji architektonicznej:
- "Dlaczego wybraliśmy X zamiast Y i Z"
- Kontekst jest TERAZ, ale ADR działa przez lata — kiedy przyjdzie audytor lub nowy developer

**Format:** Michael Nygard (2011) + rozszerzenia praktyczne.

**Gdzie żyją:** `docs/adr/ADR-NNN-tytuł.md` w repozytorium — w git, z historią zmian.

---

## Anatomia dobrego ADR

### 1. Tytuł — konkretny, bez "Implementation of"

**Zle:** `ADR-003 — Implementation of authentication`
**Dobrze:** `ADR-003 — Auth stack: iron-session + bcryptjs + optional TOTP (nie Auth.js v5)`

Tytuł powinien zawierać DECYZJĘ, nie abstrakcję.

### 2. Status — nie zostawiaj "Proposed" na zawsze

- **Proposed** — draft, nie zatwierdzony
- **Accepted** — zatwierdzony, wdrożony lub w trakcie wdrożenia
- **Deprecated** — wycofany, ale nieważniejszy bo superseded
- **Superseded by ADR-XXX** — zastąpiony nowszą decyzją

**Reguła:** ADR w stanie "Proposed" przez >7 dni → pytanie do decydenta.

### 3. Context — opisz problem, nie rozwiązanie

**Zle:**
```markdown
## Context
Musieliśmy wybrać framework autentykacji dla naszej aplikacji.
```

**Dobrze:**
```markdown
## Context
Budujemy single-user webapp z wymaganiem OWASP ASVS L2. Użytkownik (50+, nie-IT)
musi mieć możliwość logowania hasłem + opcjonalne TOTP. external-crm używa iron-session
8 produkcyjnie (sprawdzone 6 miesięcy). Deadline 10 dni → stack nieznany operatorowi = ryzyko.
Opcja Auth.js v5 ma TOTP built-in, ale ~25 dependencies vs 3 iron-session.
```

Context MUSI zawierać: ograniczenia, wymogi, istniejący kontekst, dlaczego decyzja jest potrzebna TERAZ.

### 4. Decision — 1-3 zdania, konkretnie

**Zle:**
```markdown
## Decision
Wybrano iron-session.
```

**Dobrze:**
```markdown
## Decision
Wybrano iron-session 8 + bcryptjs + zxcvbn + opcjonalne TOTP przez otplib.
Uzasadnienie: spójność z external-crm (iron-session produkcyjnie od 6 mies.), 3 deps zamiast 25,
pełna kontrola nad cookie handling (audit-OK), TOTP opcjonalne via feature flag dla UX Jana.
```

### 5. Consequences — symetryczne (dobre I złe)

ADR bez negatywnych konsekwencji = ADR niezpełny.

**Zle:**
```markdown
## Consequences
iron-session jest lekkie i sprawdzone. Dobrze działa z NextJS.
```

**Dobrze:**
```markdown
### Pozytywne
- 3 deps zamiast 25 (Auth.js v5) — mniejsza powierzchnia ataku
- iron-session sprawdzony produkcyjnie w external-crm (6 miesięcy, zero incydentów)
- Pełna kontrola nad cookie config (HttpOnly, Secure, SameSite) — ważne dla OWASP ASVS V3

### Negatywne
- TOTP wymaga ręcznej implementacji (~2h) vs Auth.js v5 built-in
- Brak OAuth social providers (Google/GitHub login) — out-of-scope v1, ale ogranicza v2

### Neutralne / Ryzyka
- iron-session 9 może zmienić API — pin do 8.x w package.json
```

### 6. Alternatives — każda opcja z powodem odrzucenia

**Zasada:** audytor ZAWSZE pyta "dlaczego nie X". Alternatives jest odpowiedzią z góry.

Minimum 2-3 opcje (wybrana + ≥2 odrzucone).

**Format tabeli:**
```markdown
| Option | Pros | Cons | Why rejected |
|---|---|---|---|
| Auth.js v5 | TOTP built-in, OAuth | 25+ deps, "magia", niezgodny z CRM | Over-engineered dla 1-user; CRM patterny nieprzenoszalne |
| Keycloak | Enterprise-grade, MFA, RBAC | 3+ kontenery, Java, overkill dla 1-user | Stack complexity 10x; deadline 10 dni nieakceptowalne |
| iron-session 8 (wybrana) | 3 deps, sprawdzone, audit-OK | TOTP ręczna impl (+2h) | N/A — wybrana |
```

---

## Kiedy tworzyć ADR

Utwórz ADR gdy decyzja:
- Jest **trudno odwracalna** (zmiana stacku, DB, auth)
- Ma **long-term konsekwencje** (będzie trwała >6 miesięcy)
- Generuje **dyskusję** (więcej niż jedna sensowna opcja)
- Dotyczy **bezpieczeństwa lub audytu** (audytor zapyta)

NIE twórz ADR dla:
- Wyboru formattera kodu (Prettier vs ESLint-prettier)
- Nazwy zmiennej
- Konfiguracji edytora

---

## Kiedy supersede ADR

Gdy decyzja jest rewidowana (nie wycofana):

```markdown
# ADR-003 — Auth stack: iron-session + bcryptjs + optional TOTP

**Status:** Superseded by ADR-007
```

```markdown
# ADR-007 — Auth stack v2: TOTP mandatory (enforcement na produkcji)

**Status:** Accepted
**Date:** 2026-07-01

## Context
ADR-003 zostawił TOTP_REQUIRED=false (UX dla Jana). Audytor zewnętrzny (2026-06-30)
zażądał enforcement TOTP przed certyfikacją. Deadline: 30 dni.
```

---

## Antywzorce ADR (lesson  + praktyka)

### AP-ADR-1: ADR jako "notatka ze spotkania"

```markdown
# ADR-002
Spotkaliśmy się i zdecydowaliśmy że użyjemy Docker Compose.
```

Brak: Context, Alternatives, Consequences. Bezużyteczne dla audytora.

### AP-ADR-2: Alternatives = echo decyzji

```markdown
## Alternatives
Mogliśmy użyć Docker Swarm, ale wybraliśmy Compose.
```

Brak: dlaczego Swarm odrzucono. Audytor i tak zapyta.

### AP-ADR-3: Status "Proposed" przez >7 dni

ADR w Proposed to nie ADR — to draft. Nic nie blokuje decyzji poza brakiem zatwierdzenia.

### AP-ADR-4: ADR dla każdej małej decyzji

5 ADR-ów w tygodniu o konfiguracji eslint = szum. ADR dla formattera kodu to anty-wzorzec.

### AP-ADR-5: ADR bez daty i decydenta

"ADR-001 — Stack" bez daty i bez "kto zatwierdził" = nieweryfikowalne dla audytora.

### AP-ADR-6: Consequences wyłącznie pozytywne

Każda decyzja ma trade-offy. Jeśli nie widzisz wad — nie myślisz wystarczająco głęboko.

---

## Przykładowy przepływ tworzenia ADR (15 min workflow)

1. **Trigger:** pojawia się decyzja architektoniczna
2. **Draft (5 min):** wypełnij Context + Decision — najważniejsze
3. **Alternatives (5 min):** wymień opcje odrzucone z powodami
4. **Consequences (5 min):** ≥2 pozytywne + ≥1 negatywna
5. **Status:** Proposed → wyślij do review (operator)
6. **After review:** zmień Status na Accepted + data zatwierdzenia
7. **Commit:** `git add docs/adr/ADR-NNN-*.md && git commit -m "docs(adr): ADR-NNN — [tytuł]"`

---

## ADR numbering convention

```
ADR-001 — Stack (frontend + backend + db)
ADR-002 — IaC (Docker + Caddy + hosting)
ADR-003 — Auth + security (auth stack + TOTP strategy)
ADR-004 — Domain-specific engine (PDF / email / payments)
ADR-005+ — Kolejne decyzje w numeracji chronologicznej
```

**Nie zostawiaj dziur w numeracji.** Jeśli ADR-003 jest superseded przez ADR-007, ADR-003 pozostaje w folderze ze statusem "Superseded by ADR-007".
