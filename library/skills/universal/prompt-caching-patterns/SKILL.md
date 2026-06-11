---
name: prompt-caching-patterns
description: Wzorce użycia Anthropic prompt caching dla repetitive contexts. Saved 80-90% input token cost dla stable system prompts/tools. Trigger  B4. Use case primary - Anthropic SDK (NIE Claude Code CLI). Trigger sekundarny - cross-agent-learning context (lessons + reflections last 3) jako cacheable target gdy agent fires multiple razy w sesji.
type: skill
version: 1.0.0
category: universal
tags: [tokens, performance, caching, anthropic-sdk, cost-optimization]
distribution: standard
compatible_with: [universal, agent-factory, ai-agents]
requires: [model-routing, token-budget-tracking]
token_cost: low
---

# prompt-caching-patterns

## Cel

Dokumentować Anthropic prompt caching pattern — saved 80-90% input token cost dla repetitive contexts. Cel: każdy agent który fires multiple razy z **identycznym system prompt** powinien używać caching.

**Audyt baseline:** 0 agentów fabryki używa prompt caching ( B4 = pierwsze adopcja).

## Anthropic prompt cache podstawy

### TTL: 5 minut

Cache jest invalidated po 5 min bez hit. **Konsekwencja:** dla agentów wywoływanych co >5 min cache miss = cache useless.

**Use cases dla caching:**
- ✅ Agent wywoływany 10× sequentialnie w 5 min (np. weekly-health-report scan)
- ✅ Pipeline 5 agentów wywoływanych jeden po drugim z shared context
- ❌ Agent wywoływany 1×/dzień (cache zawsze miss)

### Cache priority (Anthropic spec)

Cache markery aplikowane w kolejności:
1. **System prompt** (najwyższy priorytet — typowo największy stable context)
2. **Tools** definitions
3. **Examples** (few-shot)
4. **Input** messages (najniższy — rzadko stable)

**Praktyka:** marker `cache_control: {type: "ephemeral"}` na końcu STABLE bloku.

## Pattern 1 — Cross-agent-learning context cache

**Use case:** agent czyta `errors-{name}.md + reflections + lessons.jsonl` w "Before starting work" ( retrofit 100%). Te 3 źródła są **STABLE w sesji** (rzadko zmieniają się w trakcie 5 min).

**Implementation (Anthropic SDK):**

```python
import anthropic

client = anthropic.Anthropic

# Build context (STABLE)
context = f"""
You are agent {agent_name}.

# Pre-execution context (cross-agent-learning E2):

## Errors-{agent_name}.md:
{errors_content}

## Last 3 reflections:
{reflections_content}

## Lessons.jsonl tail 20:
{lessons_content}

# Workflow (Krok 1-7):
...
"""

response = client.messages.create(
    model="claude-opus-4-7",
    max_tokens=2048,
    system=[
        {
            "type": "text",
            "text": context,
            "cache_control": {"type": "ephemeral"}  # cache STABLE block
        }
    ],
    messages=[{"role": "user", "content": user_task}]
)

# Sprawdź czy cache hit
print(f"Cache read: {response.usage.cache_read_input_tokens} tokens")
print(f"Cache write: {response.usage.cache_creation_input_tokens} tokens")
print(f"Input (after cache): {response.usage.input_tokens} tokens")
```

**Saved tokens:**
- Bez cache: każdy run = full input tokens (np. 5000 input × 5 runs = 25 000 tokens)
- Z cache: pierwsze run pisze cache (5000 tokens × 1.25 multiplier), kolejne 4 odczytują (5000 × 0.10 × 4 = 2000)
- **Saved:** 25000 → 8250 = **67% saved**

## Pattern 2 — Tools definitions cache (wieloagentowy pipeline)

**Use case:** Pipeline 5 agentów (np. requirements-interviewer → agent-architect → quality-checker → pilot-orchestrator → pack-agent) z SHARED tools list (Read, Write, Bash, Grep).

**Implementation:**

```python
SHARED_TOOLS = [...]  # 6 narzędzi z definicji

# Każdy agent w pipeline:
response = client.messages.create(
    model="claude-opus-4-7",
    max_tokens=2048,
    tools=SHARED_TOOLS,  # NIE cache_control bezpośrednio
    system=[
        {"type": "text", "text": "Agent X system prompt..."},
        # Tools są wewnątrz Anthropic API — cache się dzieje przez tool_choice + identyczne tools array
    ],
    messages=[...]
)
```

**Saved:** 6 tools × ~500 tokens definition = 3000 tokens × 5 calls = 15k tokens. Z cache = ~3k tokens ALL pipeline.

## Pattern 3 — Examples (few-shot) cache

**Use case:** cv-builder ma 3 example CV templates (sales/admin/tech) jako few-shot. Cv-builder wywoływany 10× w sesji aplikacji = templates STABLE.

**Implementation:**

```python
response = client.messages.create(
    system=[
        {"type": "text", "text": agent_definition},
        {
            "type": "text",
            "text": f"# Templates examples:\n\n## Sales:\n{sales_template}\n\n## Admin:\n{admin_template}\n\n## Tech:\n{tech_template}",
            "cache_control": {"type": "ephemeral"}  # cache examples block
        }
    ],
    ...
)
```

## Use case fabryki — kiedy aplikować

**HIGH priority (apply ASAP):**
1. **Cross-agent-learning** — 33/33 agentów ma "Before starting work" sekcję czytającą 3 stabilne źródła. Cache target.
2. **Pipeline meta-agentów** — version-bumper → architect → quality-checker chain. Shared tools cache.
3. **Multi-fixture pilot** — pilot-orchestrator wywołuje agenta 3-5× na różnych fixtures. Agent definition cache.

**MED priority:**
- Templates (cv-builder 3 CSS)
- Rubryki (offer-scoring-rubric)

**LOW priority (cache miss likely):**
- Single-run agenty (`/factory-status` 1×/sesja)
- Cron-based (>5 min między runs)

## Limitations (Anthropic SDK only)

⚠️ **Claude Code CLI NIE expose prompt caching API.** Cache działa AUTOMATYCZNIE w Claude Code (Anthropic optymalizuje), ale user NIE kontroluje markers.

**Konsekwencja:**
- Skill stosuje się PRIMARILY do paczek klientów używających `anthropic` SDK directly (Python)
- W fabryce (Claude Code CLI) — automatic caching, brak ręcznej kontroli
- Use case dla fabryki: wzorzec architektoniczny przy projektowaniu paczek `af-pack-*`

## Cost analysis

**Bez caching (5 runs cv-builder, 5000 input tokens each):**
- Total input: 25 000 tokens × $15/M (opus) = $0.375

**Z caching (5 runs, 5000 input × cache):**
- Cache write (1×): 5000 × 1.25 × $15/M = $0.094 (1.25× multiplier dla write)
- Cache read (4×): 5000 × 0.10 × $15/M × 4 = $0.030 (0.10× discount dla read)
- Total: $0.124 (**67% saved**)

**Roczne oszczędności:** zależne od adoption. Estymata dla fabryki przy weekly version-bumper + self-pilot + pilot-orchestrator runs:
- Bez caching: ~$50-100/mc
- Z caching: ~$15-30/mc
- **Saved:** ~$30-70/mc

## Anti-patterns

- ❌ **Cache na input messages** — rzadko STABLE, cache miss prawie zawsze
- ❌ **Cache markers w środku zmiennego contextu** — invalidate cache całego bloku
- ❌ **Cache cross-sesja** — TTL 5 min, NIE persistent
- ❌ **Forget cache stats** — emit `cache_read_input_tokens` w activity-log dla audit
- ❌ **Cache w paczkach single-run** — jeśli agent fires 1×/dzień → cache useless

## Update procedure skilla

- Q+1 review Anthropic pricing model dla cache (1.25× write / 0.10× read może się zmienić)
- Q+1 verify SDK API stable
- Monitor cache hit rates real-world (po adopcji w pipeline meta-agentów)

---

**Version:** 1.0.0 ( B4)
**Konsumenci:** paczki klienta z Anthropic SDK, pipeline meta-agentów fabryki (po Anthropic SDK integration future)
**Last review:** 2026-05-13
