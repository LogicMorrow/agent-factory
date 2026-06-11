---
description: Generuj brief startowy (Worked/Failed/Surprises/Procedury/Anti-patterns) dla projektu — synteza lessons + reflections + activity-log + errors-*.md
allowed-tools: Task
---

# /recommendations

Wywołuje `project-recommendations-writer` (opus, universal) który syntezuje wiedzę projektową z 4 źródeł (`lessons.jsonl` + `reflections/` + `activity-log.jsonl` + `dobre-praktyki.md` + `errors-*.md` per agent) w **5-sekcyjny markdown** gotowy jako wstęp dla nowego podobnego projektu.

## Argumenty

- `<project_name>` — nazwa projektu (slug, np. `external-crm`)
- `--all` — synteza cross-project (wszystkie projekty)

## Output

`knowledge-base/recommendations/<project>-recommendations.md` (fabryka) lub `docs/recommendations/<project>-recommendations.md` (kliencki). Auto-detect ścieżki.

## Przykłady

```
/recommendations external-crm
```
→ `recommendations/external-crm-recommendations.md` (~300-500 linii). Gotowe do skopiowania jako wstęp dla nowego CRM klienta.

```
/recommendations --all
```
→ `recommendations/all-projects-recommendations.md` — agregacja cross-project (wszystkie projekty bez filter).

## Workflow

Komenda przekazuje argumenty do `Task project-recommendations-writer`. Agent:
1. Validate input
2. Resolve paths (auto-detect cwd: fabryka/kliencki)
3. Load + filter sources
4. Synteza w 5 sekcjach: Worked / Failed / Surprises / Procedury / Anti-patterns
5. Format markdown
6. Write file + emit JSON

## Powiązania

- Agent: `library/agents/universal/project-recommendations-writer.md` 
- Skille: `error-memory-framework` (E1) + `cross-agent-learning` (E2) + `model-routing`
- Plan : `knowledge-base/plans/2026-05-06--learning-loop.md`
