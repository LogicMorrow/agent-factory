# knowledge-base/ — the system's memory

> ⚠️ **Everything in this directory is fictional.** It exists to illustrate how the factory's learning loop works in the public mirror. The real knowledge base (with actual client projects) lives in the private factory and never leaves it.

This is where the factory remembers. Each subdirectory plays a role in the [learning loop](../docs/how-it-works.md):

| Path | What lives here | Written by |
|---|---|---|
| `projects/` | One **project card** per project — the single source of truth about a project's stack, goal, ports, constraints. | `project-profiler` |
| `interviews/` | Business **briefs** produced before any agent/skill is designed. | `requirements-interviewer` |
| `reflections/` | An agent-architect **reflection** after each component is built — what worked, what to avoid. | `agent-architect` |
| `lessons.jsonl` | Append-only **lessons** distilled from finished projects. Injected back into agents at design time. | `/log-lesson` |
| `activity-log.jsonl` | Append-only event stream — "what the factory did". | every meta-agent |

The example below tells one coherent story: a fictional online bookstore (`example-lumen-bookstore`) needed an agent to catch inventory-sync bugs, so the factory interviewed, designed `inventory-sync-checker`, reflected on it, and recorded two reusable lessons.

- Project card → [`projects/example-lumen-bookstore.md`](projects/example-lumen-bookstore.md)
- Brief → [`interviews/2026-01-15-inventory-sync-checker.md`](interviews/2026-01-15-inventory-sync-checker.md)
- Reflection → [`reflections/2026-01-16-inventory-sync-checker.md`](reflections/2026-01-16-inventory-sync-checker.md)
- Lessons → [`lessons.jsonl`](lessons.jsonl)
