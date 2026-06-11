# Stack AI agents — wersje i schema

## Wersje bibliotek (bez alternatyw)
| Paczka | Wersja | Uwaga |
|---|---|---|
| `@anthropic-ai/sdk` | `^0.32.1` | Oficjalny SDK TypeScript |
| `hono` | `^4.6.x` | HTTP server + SSE — zgodny z webapp-standards |
| `@hono/node-server` | `^1.13.x` | Adapter Node.js dla Hono |
| `ioredis` | `^5.4.1` | Redis client (production-grade, wspiera cluster) |
| `pg` | `^8.13.x` | PostgreSQL client (lub Prisma 5.22 jeśli projekt już używa) |
| `zod` | `^3.23.x` | Walidacja narzędzi i payloadów |
| `pino` | `^9.5.x` | Logger (JSON output, wysoka wydajność) |
| `p-retry` | `^6.2.x` | Retry z exp backoff dla API calls |
| `node` | `22.x LTS` | Runtime |
| `typescript` | `5.7.x` | Strict mode + noUncheckedIndexedAccess |

## Models (per zadanie)
| Zadanie | Model | Dlaczego |
|---|---|---|
| Główny reasoning, decyzje, planowanie | `claude-opus-4-7` | Najinteligentniejszy, kosztowny — używaj oszczędnie |
| Standardowe zadania agenta (tool use, odpowiedzi) | `claude-sonnet-4-6` | Balans ceny i jakości — domyślny |
| Klasyfikacja, routing, streszczenia, prostsze odpowiedzi | `claude-haiku-4-5-20251001` | Najtańszy, szybki — do wysokiej objętości |

**Zasada:** nigdy nie hardcoduj nazwy modelu w wielu miejscach. Zdefiniuj `MODELS = { reasoning: 'claude-opus-4-7', standard: 'claude-sonnet-4-6', fast: 'claude-haiku-4-5-20251001' }` w `config/models.ts` i importuj.

## Infrastruktura
- **Docker Compose** — Node app + Redis 7 + PostgreSQL 16, wszystko jako kontener
- **Redis** — aktywne sesje agenta (TTL 1h), pub/sub dla SSE fan-out między instancjami
- **PostgreSQL 16** — historia konwersacji, pending actions, token usage (persistence długoterminowa)

## Schema PostgreSQL (minimalna)

```sql
-- Konwersacje (jedna per sesja agenta)
CREATE TABLE conversations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid,
  user_id     UUID NOT NULL,
  agent_name  TEXT NOT NULL,
  title       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW,
  archived    BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX idx_conversations_user ON conversations(user_id, updated_at DESC);

-- Wiadomości (pełna historia, source of truth)
CREATE TABLE messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  role            TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'tool_result')),
  content         JSONB NOT NULL,  -- pełny content block array z Anthropic API
  stop_reason     TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW
);
CREATE INDEX idx_messages_conv ON messages(conversation_id, created_at);

-- Akcje oczekujące na zatwierdzenie (HITL)
CREATE TABLE pending_actions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL,
  tool_name       TEXT NOT NULL,
  tool_input      JSONB NOT NULL,
  reason          TEXT,         -- co agent chce zrobić i dlaczego
  status          TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'rejected', 'expired')) DEFAULT 'pending',
  decided_at      TIMESTAMPTZ,
  decided_by      UUID,
  expires_at      TIMESTAMPTZ NOT NULL DEFAULT (NOW + INTERVAL '1 hour'),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW
);
CREATE INDEX idx_pending_actions_user ON pending_actions(user_id, status, created_at DESC);

-- Śledzenie kosztów (per wywołanie API)
CREATE TABLE token_usage (
  id                     BIGSERIAL PRIMARY KEY,
  conversation_id        UUID,
  user_id                UUID NOT NULL,
  agent_name             TEXT NOT NULL,
  model                  TEXT NOT NULL,
  input_tokens           INTEGER NOT NULL,
  cache_read_tokens      INTEGER NOT NULL DEFAULT 0,
  cache_creation_tokens  INTEGER NOT NULL DEFAULT 0,
  output_tokens          INTEGER NOT NULL,
  cost_usd               NUMERIC(10, 6) NOT NULL,
  latency_ms             INTEGER,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW
);
CREATE INDEX idx_token_usage_user_date ON token_usage(user_id, created_at DESC);
CREATE INDEX idx_token_usage_agent_date ON token_usage(agent_name, created_at DESC);
```

## Schema Redis (klucze)
```
session:<conversation_id>              → JSON: aktualny stan konwersacji (wiadomości od ostatniego summary), TTL 3600s
lock:agent:<conversation_id>           → "1", TTL 30s, blokuje równoległe odpowiedzi w tej samej sesji
rate:user:<user_id>:minute             → INCR licznik requestów per user per minute, TTL 60s
sse:user:<user_id>                     → kanał pub/sub dla HITL events do SSE /notifications/stream
pending_action:<action_id>:resolver    → kanał pub/sub z decyzją user'a (approved/rejected)
```

## Zmienne środowiskowe (`.env`)
```bash
# === Anthropic ===
ANTHROPIC_API_KEY=            # sk-ant-...

# === Server ===
PORT=3000
NODE_ENV=production

# === Database ===
DATABASE_URL=postgresql://aiuser:***@db:5432/ai_agents

# === Redis ===
REDIS_URL=redis://redis:6379

# === Security ===
JWT_SECRET=                   # min 64 znaki losowe
SESSION_SECRET=               # min 64 znaki losowe

# === Limits ===
MAX_TURNS_PER_SESSION=20
DAILY_COST_LIMIT_USD=5.00     # per user
RATE_LIMIT_PER_MINUTE=60      # per user

# === Observability ===
LOG_LEVEL=info                # debug/info/warn/error
SENTRY_DSN=                   # opcjonalnie
```
