---
# ADR front-matter — wypełnij wszystkie pola
status: proposed
# Status enum: proposed | accepted | deprecated | superseded-by-ADR-NNNN
date: YYYY-MM-DD
# data wpisu ADR (zawsze dzisiaj; jeśli retroaktywny — zob. sekcja Context)
decision_by: "<imię lub role, np. operator / arch-team>"
kind: infrastructure
# kind enum: infrastructure | code | process | security
related: []
# ścieżki względne do powiązanych ADR-ów i runbooków
# przykład: ["../runbooks/redis-down.md", "./0001-storage-choice.md"]
last_reviewed: YYYY-MM-DD
---

# ADR-NNNN: <Tytuł — co zostało zdecydowane, rzeczownikowo>

<!-- Przykład tytułu: "Redis jako mechanizm pub/sub dla WebSocket" -->

## Status

`proposed` | `accepted` | `deprecated` | `superseded-by-ADR-NNNN`

<!-- Jeśli superseded — dodaj link: Supersedowany przez [ADR-NNNN](./NNNN-xxx.md) -->

---

## Context

<!-- Dlaczego ta decyzja jest potrzebna? Jakie ograniczenia, wymagania, problemy? -->
<!-- Min. 3-5 zdań. Bez kontekstu ADR traci wartość za 6 miesięcy. -->

<!-- Jeśli ADR retroaktywny: -->
<!-- > ADR retroaktywny. Decyzja faktycznie podjęta YYYY-MM-DD. Rekonstrukcja na podstawie <commit/Slack/notatki>. -->

---

## Alternatives Considered

<!-- Min. 2 alternatywy (test 3-czynnikowy: kontrowersja = ≥2 rozważane) -->

### Option A: <nazwa opcji> *(wybrany)*

**Pro:**
- ...

**Con:**
- ...

### Option B: <nazwa opcji>

**Pro:**
- ...

**Con:**
- ...

### Option C: <nazwa opcji> *(opcjonalnie)*

**Pro:**
- ...

**Con:**
- ...

---

## Decision

<!-- Co wybrano i dlaczego. Odpowiedź na pytanie "dlaczego A a nie B?" -->
<!-- Konkretne, bez akademickości. 3-6 zdań wystarczy. -->

Wybieramy **Option A** ponieważ: ...

---

## Success Criteria

<!-- OBOWIĄZKOWE. Jak poznamy że decyzja była dobra? Metryki, termin, observable outcomes. -->
<!-- Przykład: "Redis pub/sub obsługuje >100 concurrent connections z latency <50ms przez 30 dni od wdrożenia." -->

1. ...
2. ...
3. Ocena po: YYYY-MM-DD (sugerowany: 3-6 miesięcy od daty ADR)

---

## Rollback Plan

<!-- Opcjonalne. Jak cofnąć jeśli Success criteria nie osiągnięte? -->
<!-- Pomiń sekcję jeśli rollback jest oczywisty lub niemożliwy (zaznacz wtedy: "Nieodwracalne — patrz Context"). -->

Jeśli Success criteria nie są osiągnięte do YYYY-MM-DD:
1. ...
2. ...

---

## Consequences

<!-- Konsekwencje decyzji — dobre i złe. Co staje się łatwiejsze, co trudniejsze? -->
<!-- Co team MUSI zrobić w wyniku tej decyzji? -->

**Dobre:**
- ...

**Trudne / Tech-debt:**
- ...

**Wymagane działania:**
- [ ] ...

---

## Related

<!-- Linki do powiązanych dokumentów — runbooki, inne ADR-y, PR-y, issues -->

- Runbook: [<nazwa>](<ścieżka>)
- ADR: [ADR-NNNN](<ścieżka>)
- PR: #<numer>
