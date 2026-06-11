# Fork & use

Three ways to get value out of this repo, from lightest to fullest.

## 1. Cherry-pick agents and skills

The fastest path. Browse `library/` and copy what fits your project.

```bash
git clone https://github.com/LogicMorrow/agent-factory.git
# a universal code reviewer + the model-routing skill:
cp -r agent-factory/library/agents/universal/commit-reviewer.md your-project/.claude/agents/
cp -r agent-factory/library/skills/universal/model-routing      your-project/.claude/skills/
```

Each agent is a self-contained Markdown file with YAML frontmatter (`description`, `tools`, `model`, metadata). Skills are folders with a `SKILL.md` plus supporting references. Read the frontmatter `description` — it tells you exactly *when* the agent should fire.

## 2. Run the factory to build a tailored package

Open the repo in [Claude Code](https://claude.com/claude-code) and let the workflow do the design work.

```bash
cd agent-factory && claude
```

Then drive it with slash commands:

- `/new-agent` — interview → architect → quality-check → a new agent.
- `/new-skill` — same flow for a knowledge pack.
- `/new-project` — scaffold a fresh project with matching agents/skills.
- `/pack` — bundle a portable `.claude/` package and push it to its own repo.

The interview step is deliberate: the factory won't design from assumptions, it asks first.

## 3. Adopt the whole workflow

If you want your own self-improving factory:

1. Fork the repo.
2. Replace `knowledge-base/` examples with your own project cards (`/project-profile`).
3. Wire the learning loop: the `Stop` / `UserPromptSubmit` hooks under `.claude/` and `library/embedded-factory/` capture lessons; the `/review-lessons` and `/log-lesson` commands curate them.
4. Keep your real client data **private**. If you publish a mirror, mirror it through a default-deny allowlist + an anti-PII scan gate (the pattern this repo itself uses).

## Conventions worth knowing

- **`model-routing` is mandatory** — every agent picks the cheapest capable model.
- **Every agent has a "what it does NOT do" section** that routes to the right neighbor — this keeps agents single-purpose.
- **Browse the `library/` folders** to see everything available — each agent/skill declares how it relates to others in its frontmatter (`requires`, `compatible_with`).
- **Metadata is real** — `version`, `tags`, `token_cost` and dependency fields are maintained, not decorative.

## Requirements

- [Claude Code](https://claude.com/claude-code) for running the workflow (cherry-picking individual files needs nothing).
- `git` and, for packaging to GitHub, the `gh` CLI.
