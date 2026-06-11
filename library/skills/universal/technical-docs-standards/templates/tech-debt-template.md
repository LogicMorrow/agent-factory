# TECH_DEBT.md — Rejestr Technicznego Długu

> Plik tworzony automatycznie przy pierwszym bypass `emergency-merge`.
> Comiesięczny sweep: `/review-lessons` — meta-reviewer raportuje przeterminowane wpisy.
> Lokalizacja: `docs/TECH_DEBT.md` (nie `TECH_DEBT.md` w root — `docs/` jest walidowane przez CI).

---

## Aktywne wpisy

| # | Data | PR | Opis długu | Plan spłaty | Owner | Termin | Status |
|---|------|----|-----------|-------------|-------|--------|--------|
| 1 | YYYY-MM-DD | [#NNN](link) | `TECH-DEBT: <opis z PR body>` | <konkretny plan: co, kiedy> | <imię> | YYYY-MM-DD | open |

---

## Zamknięte wpisy

| # | Data | PR | Opis długu | Zamknięte | PR zamknięcia |
|---|------|----|-----------|-----------|---------------|
| — | — | — | — | — | — |

---

## Zasady

1. **Każdy bypass `emergency-merge` wymaga wpisu tutaj** w ciągu 24h od merge (jeśli nie automatycznie przez CI).
2. **Termin spłaty** musi być konkretny — nie "kiedyś". Maksymalny sensowny termin: 30 dni dla hard gates, 90 dni dla soft gates.
3. **Owner** = osoba odpowiedzialna za spłatę, nie osoba która zrobiła bypass.
4. **Comiesięczny sweep:** meta-reviewer przy `/review-lessons` raportuje wpisy starsze niż termin → propozycja escalacji lub zamknięcia.
5. **Powtarzający się pattern** (ten sam owner >3x/miesiąc) → meta-reviewer zgłasza `improvement-proposals/` z rekomendacją zmiany procesu.

---

## Szablon wpisu (kopiuj przy każdym bypass)

```markdown
| <numer> | <YYYY-MM-DD> | [#<numer>](<link do PR>) | TECH-DEBT: <skopiuj z PR body> | <konkretny plan spłaty> | <owner> | <YYYY-MM-DD termin> | open |
```

---

## Historia sweepów

| Data | Reviewer | Wpisy aktywne | Wpisy przeterminowane | Akcja |
|------|---------|---------------|----------------------|-------|
| YYYY-MM-DD | meta-reviewer | N | N | <opis> |
