# docs/ — Mapa dokumentacji projektu <PROJEKT>

> **Hard gate CI:** ten plik musi istnieć i mieć content. Zaktualizuj gdy dodajesz nowy dokument do `docs/`.
> Ostatnia aktualizacja: YYYY-MM-DD (CI soft gate: ostrzeżenie po 90 dniach bez zmian)

## Poziom dojrzałości dokumentacji

`L<1|2|3>` — szczegóły: [`technical-docs-standards` skill](link-do-skilla)

---

## Mapa dokumentów

### Architecture

| Dokument | Opis | Status |
|----------|------|--------|
| [`architecture/overview.md`](./architecture/overview.md) | System context, container view, tech stack, key flows, data model | aktualny |

### ADR — Architecture Decision Records

| ID | Tytuł | Status | Data |
|----|-------|--------|------|
| [0001](./adr/0001-<nazwa>.md) | <Tytuł> | accepted | YYYY-MM-DD |
| [0002](./adr/0002-<nazwa>.md) | <Tytuł> | accepted | YYYY-MM-DD |

Pełna lista: [`adr/`](./adr/)

### Runbooks — Procedury operacyjne

| Runbook | Severity | MTTR Target | Ostatnie użycie |
|---------|----------|-------------|-----------------|
| [`runbooks/deploy.md`](./runbooks/deploy.md) | p1 | 15 min | YYYY-MM-DD |
| [`runbooks/rollback.md`](./runbooks/rollback.md) | p0 | 10 min | YYYY-MM-DD |
| [`runbooks/incident-response.md`](./runbooks/incident-response.md) | p0 | 30 min | — |

Prerekvizyt wspólne: [`runbooks/_shared-prerequisites.md`](./runbooks/_shared-prerequisites.md)

### API *(L2+)*

| Dokument | Opis |
|----------|------|
| [`api/README.md`](./api/README.md) | Base URL, auth, rate limits, error format, examples |
| [`api/openapi.yaml`](./api/openapi.yaml) | Auto-generated OpenAPI spec (lub link do `/api/docs`) |

### Onboarding *(L2+)*

[`onboarding.md`](./onboarding.md) — jak zacząć pracę z projektem

### Security *(L3)*

[`security/`](./security/) — model bezpieczeństwa, hardening checklist

### Postmortems *(L3)*

[`postmortems/`](./postmortems/) — analiza incydentów produkcyjnych

### Tech Debt

[`TECH_DEBT.md`](./TECH_DEBT.md) — spis bypassy `emergency-merge` z planami spłaty

---

## Konwencje

- **ADR numeracja:** 4-cyfrowa, globalna (`0001`, `0002`...), kebab-case tytułu
- **Runbook nazwa:** `<procedura>.md` (deploy, rollback, <komponent>-down, incident-response)
- **Linki wewnętrzne:** ścieżki względne od `docs/` (weryfikowane przez `validate-docs.sh`)
- **Diagramy:** Mermaid w plikach Markdown, `.puml` + `.svg` dla PlantUML

## Jak dodać nowy dokument

1. Utwórz plik w odpowiednim podfolderze
2. Dodaj wpis do tej tabeli
3. Zaktualizuj `last_updated` na górze pliku
4. Jeśli ADR `kind: infrastructure` — dodaj powiązany runbook lub uzasadnij w `related`
