---
description: Wygeneruj raport ewolucji agentów fabryki (kto się zmienił, ile razy, dlaczego, czy lepiej) — META meta-agenta factory-only
allowed-tools: Task
---

# /agent-evolution

Wywołuje `agent-evolution-reviewer` (opus, META factory-only) — synteza cross-agent w czasie. Agent czyta `library-index.json` + `git log --follow` per agent + reflections + lessons.jsonl, cross-references version bumps z trigger lessons (heurystyki: lessons ±3d, reflections ±7d). Plus trend analysis dla agentów z metrykami SC (np. tech-doc-writer 5 metryk z ADR-0005, threshold 5%).

## Argumenty

- `--since <YYYY-MM-DD>` — wymagane, ISO format (np. `--since=2026-04-23`)
- `--agent <name>` — opcjonalne, default `--all`
- `--output <path>` — opcjonalne, default `knowledge-base/evolution-reports/<since>-<filter|all>.md`

## Output

Markdown raport (~200-400 linii per agent) w 3 sekcjach:
- **Summary cross-cutting** — agentów przeanalizowanych, łącznie patchy, top 3 przyczyny patchy
- **Per-agent details** — wersja start/current, lista patchy z przyczynami, lessons HIGH count, verdict (rosnąca jakość | stable | concerning)
- **Trend metryk SC** — gdy agent ma metrics, per-metryka per-iteracja (np. `M1: 4.20 → 4.65 uptrend +10%`)

## Przykłady

```
/agent-evolution --since=2026-04-23 --agent=tech-doc-writer
```
→ `knowledge-base/evolution-reports/2026-04-23-tech-doc-writer.md`. Timeline v1.0 → v1.0.1 z trigger lesson #11 + 5 SC metrics single-point analysis.

```
/agent-evolution --since=2026-04-23 --all
```
→ `knowledge-base/evolution-reports/2026-04-23-all.md`. Cross-cutting summary (top 3 przyczyny patchy, agenty bez/z najwięcej zmian) + per-agent per pojedynczy agent.

## Workflow

Komenda przekazuje argumenty do `Task agent-evolution-reviewer`. Agent:
1. Validate args (since_date ISO format)
2. Load library-index.json + filter agents (po --agent lub all)
3. Per agent (parallel): git log --follow + reflections (Glob *<name>*) + lessons.jsonl (Grep <name>)
4. Cross-reference (lessons ±3d, reflections ±7d) → atrybucja przyczyny version bumps
5. Synteza raportu w 3 sekcjach (Summary + Per-agent + Trend)
6. Write file + emit JSON

## Uwagi

- **META factory-only** — agent NIE dystrybuuje przez `/pack` do projektów klienckich (custom field `distribution: factory-only` w frontmatter).
- **Komplementarny do** `meta-reviewer` (lessons → systemowe proposals) i `project-recommendations-writer` (cross-PROJECT). Ten agent agreguje **cross-AGENT w CZASIE**.

## Powiązania

- Agent: `.claude/agents/agent-evolution-reviewer.md` (META, )
- Skille: `error-memory-framework` (E1) + `cross-agent-learning` (E2) + `model-routing`
- Plan : `knowledge-base/plans/2026-05-06--learning-loop.md`
