# Architektura AI agents

## Warstwy systemu

```
┌─────────────────────────────────────────────────────────────┐
│ Client (React, Next.js, etc.)                              │
│   POST /chat/stream     → SSE: tokeny agenta na bieżąco    │
│   GET  /notifications/stream → SSE: HITL events (push)     │
│   PATCH /pending-actions/:id → REST: approve / reject       │
└───────┬───────────────────────────────┬─────────────────────┘
        │ HTTP + SSE (tekst/event-stream)│
┌───────┴───────────────────────────────┴─────────────────────┐
│ HTTP Server (Hono.js + @hono/node-server)                  │
│   - JWT Bearer auth na każdym endpoincie                   │
│   - POST /chat/stream → startuje Agent Loop, pipeuje SSE   │
│   - GET /notifications/stream → subscribe Redis sse:user:X │
│   - PATCH /pending-actions/:id → resolver HITL             │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────────────────┐
│ Agent Loop (per-conversation)                              │
│   1. Load history (Redis lub PG)                           │
│   2. Call Anthropic API (streaming + prompt caching)       │
│   3. Handle tool_use → execute or queue HITL               │
│   4. Handle tool_result → back to step 2                   │
│   5. Stop when stop_reason === "end_turn"                  │
└───────┬───────────────────────┬─────────────────────────────┘
        │                       │
┌───────┴────────┐     ┌────────┴──────────┐
│ Anthropic API  │     │ Tools (whitelist) │
│  - messages    │     │  - DB queries     │
│  - streaming   │     │  - External APIs  │
│  - caching     │     │  - HITL gates     │
└────────────────┘     └───────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ State & Persistence                                        │
│   Redis:       aktywna sesja (TTL 1h), pub/sub SSE, locks  │
│   PostgreSQL:  conversations, messages, pending_actions,    │
│                token_usage (persistent)                     │
└─────────────────────────────────────────────────────────────┘
```

## Podział modułów (monorepo `apps/` lub pojedynczy projekt `src/`)

```
src/
├── config/
│   ├── models.ts          # { reasoning, standard, fast }
│   ├── limits.ts          # MAX_TURNS, rate limits
│   └── anthropic.ts       # singleton SDK client
├── agents/
│   ├── base-agent.ts      # klasa bazowa BaseAgent
│   ├── <nazwa-agenta>/
│   │   ├── index.ts       # eksport klasy AgentX extends BaseAgent
│   │   ├── system-prompt.ts
│   │   ├── tools.ts       # whitelist narzędzi dla tego agenta
│   │   └── <nazwa-agenta>.test.ts
│   └── registry.ts        # mapowanie name → klasa agenta
├── tools/
│   ├── base-tool.ts       # interfejs Tool
│   ├── <narzędzie>.ts     # Zod schema + handler
│   └── hitl-wrapper.ts    # wrapper dodający HITL do destruktywnych narzędzi
├── agent-loop/
│   ├── run.ts             # główna pętla: messages → API → tools → repeat
│   ├── stream.ts          # parsowanie streamu
│   └── context.ts         # budowanie contextu (history + cache markers)
├── state/
│   ├── redis.ts           # klient Redis
│   ├── session.ts         # load/save aktywnej sesji
│   └── history.ts         # persist PG, summarization
├── hitl/
│   ├── create-pending.ts  # zapis do pending_actions + pub/sub notification
│   ├── wait-decision.ts   # subskrypcja na decyzję (timeout)
│   └── resolver.ts        # endpoint PATCH /pending-actions/:id
├── observability/
│   ├── token-tracker.ts   # zapis do token_usage po każdym call
│   ├── cost.ts            # kalkulacja kosztu (model pricing table)
│   └── logger.ts          # pino + correlation IDs
├── stream/
│   ├── chat.ts            # POST /chat/stream — SSE z tokenami agenta
│   └── notifications.ts   # GET /notifications/stream — SSE HITL events
├── db/
│   ├── client.ts          # PG pool
│   ├── migrations/
│   └── repositories/      # conversations.repo.ts, messages.repo.ts itd.
└── index.ts               # bootstrap (DB migrate → Redis → HTTP → start)
```

## Zasady podziału
1. **Jeden agent = jedna klasa** dziedzicząca po `BaseAgent`. System prompt, tools i override'y są w folderze agenta.
2. **Agent loop jest wspólny** — nie duplikujemy kodu pętli tool_use per agent.
3. **Tools są oddzielone** od agentów. Agent tylko importuje narzędzia z whitelisty.
4. **Żaden agent nie pisze bezpośrednio do DB** — przechodzi przez `repositories/`.
5. **Żadne narzędzie nie komunikuje się z SSE bezpośrednio** — przez `observability/logger.ts` lub event busa.

## Model deployu
- **Jeden proces Node** obsługuje wiele sesji równolegle (async). Multi-instance via Redis pub/sub dla fan-out SSE.
- **Skalowanie horyzontalne:** dodajesz kolejne instancje za load balancerem. SSE connection trzyma się instancji, HITL events docierają przez Redis pub/sub do właściwej instancji.
- **Graceful shutdown:** SIGTERM → zamknij nowe połączenia → dokończ aktywne tury (timeout 30s) → zamknij procesy.

## Responsywność — wymagane
- **Streaming obowiązkowy.** User widzi tokeny na bieżąco. Non-streaming = FAIL review.
- **Pierwsza wiadomość w <500ms** od odebrania inputu (potwierdzenie że agent zaczął pracę, nawet jeśli to tylko "myślę...").
- **Tool execution w tle** — agent informuje "używam narzędzia X" i kontynuuje stream gdy przyjdzie wynik.
