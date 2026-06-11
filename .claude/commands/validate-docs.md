---
description: Waliduj plik dokumentacji (runbook | adr | api-doc | architecture | onboarding) wg template + links + YAML/JSON snippets + 5 metryk SC z ADR-0005
allowed-tools: Task
---

# /validate-docs

Wywołuje `doc-validator` (opus, universal) — manualna walidacja istniejącego dokumentu. Ten sam agent który `tech-doc-writer` v1.1+ wywołuje automatycznie po napisaniu doc, ale uruchamiany ad-hoc dla istniejących plików (np. legacy docs sprzed  lub docs napisane manualnie).

## Argumenty

- `<doc_path>` — ścieżka do pliku doc (relative do cwd lub absolute)
- `--type=<TYPE>` — opcjonalne, wymuszone gdy auto-detect z path nie działa. Wartości: `runbook | adr | api-doc | architecture | onboarding`

## Output

`<doc_path>.validation.md` — szczegółowy raport markdown sąsiednio do walidowanego pliku. Zawiera:
- Score 0-5 wg 5 metryk SC z ADR-0005
- Lista issues z severity (HIGH/MED/LOW), kategorii (missing-section/broken-link/invalid-yaml/etc.) i numerami linii
- Sumaryczny verdict PASS (≥4.0/5.0) lub FAIL

Plus JSON na stdout dla pipeline integration.

## Przykłady

```
/validate-docs docs/runbooks/redis-down.md
```
→ Auto-detect: path zawiera `runbooks/` → `doc_type=runbook`. Walidacja vs template `library/skills/universal/technical-docs-standards/templates/runbook.md`.

```
/validate-docs docs/adr/0005-hono-backend.md --type=adr
```
→ Wymuszony `doc_type=adr`. Walidacja sekcji Status/Context/Decision/Consequences/Alternatives + scope adherence + linki w cytowaniach.

```
/validate-docs docs/api/users.md --type=api-doc
```
→ Sprawdza endpointy (regex `^### (GET|POST|PUT|DELETE)`), schemas YAML (yq validity), examples JSON (jq).

## Workflow

Komenda przekazuje argumenty do `Task doc-validator`. Agent:
1. Validate input + auto-detect doc_type (jeśli `--type` brak)
2. Load template z `technical-docs-standards/templates/{doc_type}.md`
3. Parse doc + section check
4. Links + snippets check (Bash: curl/yq/jq, graceful degradation jeśli brak)
5. Score 5 metryk SC + issues list
6. Write `<doc>.validation.md` + emit JSON

## Edge cases

- **Cyclic validation guard:** jeśli `doc_path` kończy się na `.validation.md` → reject (nie waliduj raportu walidacji).
- **Missing template:** jeśli `templates/{doc_type}.md` nie istnieje → status `error`, lista wymaganych templates.
- **Missing tools:** brak `curl`/`yq`/`jq` → metryka N/A + WARN, total score liczony tylko z dostępnych.

## Powiązania

- Agent: `library/agents/universal/doc-validator.md` 
- Skill: `library/skills/universal/technical-docs-standards/` (templates + ADR-0005)
- Auto-call: `tech-doc-writer` v1.1.0+ ( — self-validation w sekcji "7. Self-validation")
- Plan : `knowledge-base/plans/2026-05-06--docvalidator-retrofit.md`
