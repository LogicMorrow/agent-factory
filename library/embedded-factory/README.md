# embedded-factory v1.0.0

Mini-fabryka samouczenia się bundlowana do każdej paczki `af-pack-*`. Przekształca paczki ze **statycznych snapshotów** w **żywe mini-fabryki** — projekt zewnętrzny uczy się autonomicznie bez round-trip do `agent-factory` dla każdej drobnej poprawki.

**Wartość:**
- Projekt zewnętrzny patchuje agentów lokalnie (v1.0.0 → v1.0.1) gdy zbierze evidence
- Tworzy nowych agentów/skille/hooki bez kontaktu z fabryką
- Promuje dojrzałe lessons z powrotem do fabryki przez `/promote-lessons` (federowane uczenie się)
- Auto-start przy każdej sesji (`SessionStart` hook wstrzykuje lokalny knowledge-base do kontekstu)

## Struktura

```
library/embedded-factory/
├── manifest.json              # Schema kontrakt B, source_hash per artefakt, sed transformations
├── README.md                  # Ten plik
├── UPGRADE.md                 # Workflow /upgrade-factory + backup + rollback
├── build.sh                   # Build-script copy + sed-replace (ADR 009)
├── agents/                    # 7 agentów copy z .claude/agents/ (z sed-replace ścieżek)
├── skills/                    # 4 skille copy z library/skills/universal/
├── hooks/                     # 3 hooki (SessionStart embedded + Path 1 conversation-learning + on-error-record)
├── commands/                  # 3 slash commands (/upgrade-factory + /promote-lessons + /review-candidate-lessons)
├── scaffold/                  # Template .claude/knowledge-base/ do init w projekcie
│   └── .claude/
│       └── knowledge-base/
│           ├── lessons.jsonl  (empty)
│           ├── activity-log.jsonl (empty)
│           ├── candidate-lessons.jsonl (empty)
│           ├── reflections/   (dir + .gitkeep)
│           └── errors/        (dir + .gitkeep)
└── LITE-SPECS/                # Spec lite variants (self-pilot-lite, pattern-detector-lite)
    ├── self-pilot-lite-spec.md
    ├── pattern-detector-lite-spec.md
    └── agents.md              # Diff vs full versions wszystkich agentów embedded
```

## Meta-stack (7 agentów + 4 skille + 3 hooki + 3 commands)

### Agenci (decyzja Q2: pełny meta-stack, projekt SAM tworzy nowych)

| Agent | Model | Lite | Cel |
|---|---|---|---|
| `agent-architect` | opus | NIE | Projektuje nowych subagentów w projekcie |
| `requirements-interviewer` | opus | NIE | Wywiad biznesowy przed projektowaniem |
| `skill-builder` | opus | NIE | Buduje nowe skille w projekcie |
| `self-pilot-lite` | sonnet | TAK | Cron weekly (tylko --weekly mode, skip pilot-orchestrator) |
| `version-bumper` | sonnet | NIE | Proposals v1.0.X dla agentów w projekcie |
| `mistake-recorder` | haiku | NIE | JSON in/out, errors-{agent}.md + lessons promotion |
| `pattern-detector-lite` | sonnet | TAK | Cold start <10 (vs <50 w fabryce) |

### Skille

- `conversation-learning` v1.1.0 (Path 1 hook production)
- `cross-agent-learning` (Before starting work krok 0)
- `error-memory-framework` (errors-{agent}.md format spec)
- `model-routing` (kiedy opus/sonnet/haiku)

### Hooki

- `session-start-embedded.sh` (SessionStart — czyta lokalny knowledge-base)
- `userPromptSubmit-conversation-learning.sh` (UserPromptSubmit — Path 1 capture)
- `on-error-record.sh` (UserPromptSubmit — error keywords reminder)

### Commands

- `/upgrade-factory` — manual pull z agent-factory repo (backup + dry-run)
- `/promote-lessons` — push branch `learning/<date>` (federowane uczenie się)
- `/review-candidate-lessons` — batch HITL review pending candidates

## Instalacja w paczce af-pack-*

Embedded-factory jest **automatycznie bundlowany** w każdej paczce przez `pack-agent` v2.0.0 Krok N+1 (.E8). End-user paczki NIE musi nic robić — `git clone af-pack-<nazwa>` daje gotową strukturę.

Manualne bootstrap (rzadkie, np. retrofit istniejącej paczki):
1. `bash library/embedded-factory/build.sh` (w agent-factory) → buduje embedded-factory z sed-replace
2. `cp -r library/embedded-factory/{agents,skills,hooks,commands} packages/<paczka>/.claude/`
3. `cp -r library/embedded-factory/scaffold/.claude/* packages/<paczka>/.claude/`
4. Update `packages/<paczka>/.claude/settings.json` (add hooks SessionStart + UserPromptSubmit)
5. Commit + push do repo paczki jako v2.0.0

## Decyzje architektoniczne (ADR)

- **ADR 008:** Lite vs full architecture (które agenty mają lite warianty, granice ograniczeń)
- **ADR 009:** Copy strategy — **build-script + sed-replace** (NIE symlink) [zaakceptowany 2026-05-24]
- **ADR 010:** Self-pilot-lite design (tylko --weekly mode)
- **ADR 011:** Pattern-detector-lite cold start (próg <10 vs <50)
- **ADR 012:** Pack-agent Krok N+1 (auto-include + parity check)
- **ADR 013:** /upgrade-factory backup + dry-run
- **ADR 014:** /promote-lessons branch convention
- **ADR 015:** Lessons.jsonl schema v2 (backward compat 109 istniejących lessons)
- **ADR 016:** Cron pull-merge HITL gate

Pełne ADR w `knowledge-base/docs/embedded-factory/adr/`.

## Lifecycle

| Phase | Trigger | Action |
|---|---|---|
| **Build** | Edit source agenta/skilla w `.claude/` lub `library/` | `bash library/embedded-factory/build.sh` (manual, ewentualnie pre-commit hook w ) |
| **Pack** | `/pack <projekt>` | pack-agent v2.0.0 Krok N+1 auto-include embedded + parity check |
| **Install** | `git clone af-pack-<nazwa>` | End-user dostaje gotową strukturę |
| **Upgrade** | `/upgrade-factory` w projekcie | Manual pull + backup + dry-run + confirm |
| **Learn** | Każda sesja w projekcie | SessionStart inject + Path 1 hook capture |
| **Promote** | `/promote-lessons` w projekcie | Push branch `learning/<date>` na repo paczki |
| **Pull-merge** | Cron monthly intelligence w fabryce | Pull branches z paczek, confidence ≥3 filter, HITL gate |

## Anti-patterns

- ❌ **NIE edytować bezpośrednio plików w `library/embedded-factory/agents,skills,hooks/`** — to output build-script, edytuj source w `.claude/agents/` lub `library/skills/`/`hooks/`
- ❌ **NIE używać symlink** zamiast build-script — hardcoded ścieżki w source agentów (`knowledge-base/lessons.jsonl`) nie zostaną re-pointed (ADR 009 rationale)
- ❌ **NIE pack-agent w embedded-factory** — recursive packaging loop (paczka tworzy paczkę tworzy paczkę). pack-agent jest factory-only.
- ❌ **NIE quality-checker w embedded v1.0** — backlog v1.1, na razie projekt waliduje agentów lokalnie manualnie
- ❌ **NIE auto-apply candidate lessons bez HITL** — `/review-candidate-lessons` to ZAWSZE wymagany gate
- ❌ **NIE cross-project pollution** — lokalne lessons NIE są shared między paczkami bez federacji przez fabrykę (`/promote-lessons` → cron monthly intelligence pull-merge)

## Version compatibility

| Embedded version | Compatible factory versions | Notes |
|---|---|---|
| 1.0.0 | 2.15.0+ | Initial release  |

## References

- Master plan: `knowledge-base/plans/2026-05-24-master--11-portable-learning.md`
-  podplan: `knowledge-base/plans/2026-05-24--portable-self-learning-loop.md`
- Brief: `knowledge-base/interviews/2026-05-24-embedded-factory.md`
- Kontrakt B: master plan sekcja 6 (manifest schema)
- Kontrakt C: master plan sekcja 6 (promote-lessons → cron pull-merge)
- CLAUDE.md fabryki zasada #14 (dodawana w .E15)
