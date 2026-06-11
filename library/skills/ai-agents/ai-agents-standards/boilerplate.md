# Boilerplate — gotowe pliki konfiguracyjne

## `package.json`
```json
{
  "name": "ai-agents-app",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "engines": { "node": "22.x" },
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc -p tsconfig.json",
    "start": "node dist/index.js",
    "typecheck": "tsc --noEmit",
    "lint": "eslint .",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "db:migrate": "node --loader tsx src/db/migrate.ts",
    "validate": "npm run typecheck && npm run lint && npm run format:check"
  },
  "dependencies": {
    "@anthropic-ai/sdk": "^0.32.1",
    "hono": "^4.6.0",
    "@hono/node-server": "^1.13.0",
    "@hono/zod-validator": "^0.4.1",
    "ioredis": "^5.4.1",
    "pg": "^8.13.1",
    "zod": "^3.23.8",
    "zod-to-json-schema": "^3.23.5",
    "pino": "^9.5.0",
    "p-retry": "^6.2.0",
    "uuid": "^11.0.3"
  },
  "devDependencies": {
    "@types/node": "^22.9.0",
    "@types/pg": "^8.11.10",
    "@types/uuid": "^10.0.0",
    "typescript": "5.7.2",
    "tsx": "^4.19.2",
    "vitest": "^2.1.5",
    "@vitest/coverage-v8": "^2.1.5",
    "eslint": "^9.15.0",
    "typescript-eslint": "^8.15.0",
    "prettier": "^3.4.1",
    "nock": "^13.5.6"
  }
}
```

## `tsconfig.json`
```json
{
  "compilerOptions": {
    "target": "ES2023",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2023"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "exactOptionalPropertyTypes": true,
    "forceConsistentCasingInFileNames": true,
    "isolatedModules": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "declaration": false,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
```

## `.env.example`
```bash
# === ANTHROPIC ===
ANTHROPIC_API_KEY=          # sk-ant-...

# === SERVER ===
PORT=3000
NODE_ENV=development

# === DATABASE ===
DATABASE_URL=postgresql://aiuser:CHANGE_ME@db:5432/ai_agents

# === REDIS ===
REDIS_URL=redis://redis:6379

# === SECURITY ===
JWT_SECRET=                 # openssl rand -hex 32  (min 64 znaki)
SESSION_SECRET=             # openssl rand -hex 32

# === LIMITS ===
MAX_TURNS_PER_SESSION=20
DAILY_COST_LIMIT_USD=5.00
RATE_LIMIT_PER_MINUTE=60

# === OBSERVABILITY ===
LOG_LEVEL=info
SENTRY_DSN=                 # opcjonalnie
```

## `docker-compose.yml`
```yaml
services:
  app:
    build: .
    restart: unless-stopped
    ports:
      - '3000:3000'
    environment:
      - NODE_ENV=${NODE_ENV:-production}
      - PORT=3000
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
      - SESSION_SECRET=${SESSION_SECRET}
      - LOG_LEVEL=${LOG_LEVEL:-info}
      - MAX_TURNS_PER_SESSION=${MAX_TURNS_PER_SESSION:-20}
      - DAILY_COST_LIMIT_USD=${DAILY_COST_LIMIT_USD:-5.00}
      - RATE_LIMIT_PER_MINUTE=${RATE_LIMIT_PER_MINUTE:-60}
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./src/db/migrations:/docker-entrypoint-initdb.d
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U ${DB_USER} -d ${DB_NAME}']
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: ['redis-server', '--appendonly', 'yes']
    volumes:
      - redis_data:/data
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
      interval: 10s
      timeout: 3s
      retries: 5

volumes:
  postgres_data:
  redis_data:
```

## `Dockerfile`
```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=builder /app/dist ./dist
USER node
CMD ["node", "dist/index.js"]
```

## `src/config/anthropic.ts`
```typescript
import Anthropic from "@anthropic-ai/sdk";

if (!process.env.ANTHROPIC_API_KEY) {
  throw new Error("ANTHROPIC_API_KEY is required");
}

export const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
  maxRetries: 0, // retry obsługujemy w agent-loop/run.ts
});

export const MODELS = {
  reasoning: "claude-opus-4-7",
  standard: "claude-sonnet-4-6",
  fast: "claude-haiku-4-5-20251001",
} as const;
```

## `src/config/limits.ts`
```typescript
export const LIMITS = {
  maxTurnsPerSession: Number(process.env.MAX_TURNS_PER_SESSION ?? 20),
  dailyCostLimitUsd: Number(process.env.DAILY_COST_LIMIT_USD ?? 5),
  rateLimitPerMinute: Number(process.env.RATE_LIMIT_PER_MINUTE ?? 60),
  hitlTimeoutMs: 60 * 60 * 1000,
  sessionTtlSeconds: 3600,
} as const;
```

## `src/index.ts` (bootstrap)
```typescript
import { serve } from "@hono/node-server";
import { logger } from "./observability/logger.js";
import { migrateDb } from "./db/migrate.js";
import { createApp } from "./http/server.js";

async function main {
  await migrateDb;
  logger.info("db migrated");

  const app = createApp;
  const port = Number(process.env.PORT ?? 3000);

  const server = serve({ fetch: app.fetch, port },  => {
    logger.info({ port }, "http server ready");
  });

  const shutdown = async (signal: string) => {
    logger.info({ signal }, "shutting down");
    server.close( => process.exit(0));
  };

  process.on("SIGTERM",  => shutdown("SIGTERM"));
  process.on("SIGINT",  => shutdown("SIGINT"));
}

main.catch((err) => {
  logger.fatal({ err }, "bootstrap failed");
  process.exit(1);
});
```

## `src/http/server.ts` (Hono app)
```typescript
import { Hono } from "hono";
import { bearerAuth } from "hono/bearer-auth";
import { logger as honoLogger } from "hono/logger";
import { chatStreamRoute } from "../stream/chat.js";
import { notificationsStreamRoute } from "../stream/notifications.js";
import { pendingActionsRoutes } from "./routes/pending-actions.js";
import { verifyJwt } from "./middleware/jwt.js";

export function createApp {
  const app = new Hono;

  app.use("*", honoLogger);
  app.use("*", verifyJwt); // ustawia c.set("userId", ...)

  app.post("/chat/stream", chatStreamRoute);
  app.get("/notifications/stream", notificationsStreamRoute);
  app.route("/pending-actions", pendingActionsRoutes);

  app.get("/health", (c) => c.json({ ok: true }));

  return app;
}
```

## `src/stream/chat.ts` (POST /chat/stream)
```typescript
import type { Context } from "hono";
import { streamSSE } from "hono/streaming";
import { z } from "zod";
import { runAgent } from "../agent-loop/run.js";
import { agentRegistry } from "../agents/registry.js";
import { logger } from "../observability/logger.js";

const bodySchema = z.object({
  conversationId: z.string.uuid,
  agentName: z.string,
  message: z.string.min(1).max(10_000),
});

export async function chatStreamRoute(c: Context) {
  const parsed = bodySchema.safeParse(await c.req.json);
  if (!parsed.success) return c.json({ error: "invalid input" }, 400);

  const { conversationId, agentName, message } = parsed.data;
  const userId = c.get("userId") as string;

  const agent = agentRegistry.get(agentName);
  if (!agent) return c.json({ error: "unknown agent" }, 404);

  return streamSSE(c, async (stream) => {
    try {
      await runAgent({
        conversationId,
        userId,
        agentName,
        systemPrompt: agent.systemPrompt,
        tools: agent.tools,
        userInput: message,
        onStream: async (chunk) => {
          await stream.writeSSE({ data: JSON.stringify({ type: "token", text: chunk }) });
        },
      });
      await stream.writeSSE({ data: JSON.stringify({ type: "done" }) });
    } catch (err) {
      logger.error({ err, conversationId }, "agent stream error");
      await stream.writeSSE({ data: JSON.stringify({ type: "error", message: "internal error" }) });
    }
  });
}
```

## `src/stream/notifications.ts` (GET /notifications/stream)
```typescript
import type { Context } from "hono";
import { streamSSE } from "hono/streaming";
import { sub } from "../state/redis.js";
import { logger } from "../observability/logger.js";

export async function notificationsStreamRoute(c: Context) {
  const userId = c.get("userId") as string;
  const channel = `sse:user:${userId}`;

  return streamSSE(c, async (stream) => {
    await stream.writeSSE({ data: JSON.stringify({ type: "connected" }) });

    const onMessage = async (_ch: string, payload: string) => {
      try {
        await stream.writeSSE({ data: payload });
      } catch (err) {
        logger.warn({ err, userId }, "sse write failed");
      }
    };

    await sub.subscribe(channel);
    sub.on("message", onMessage);

    // Poczekaj na zamknięcie połączenia
    await stream.pipe(
      new ReadableStream({
        cancel {
          sub.off("message", onMessage);
          sub.unsubscribe(channel);
        },
      }),
    );
  });
}
```

## `src/agent-loop/run.ts` (szkielet)
```typescript
import { anthropic, MODELS } from "../config/anthropic.js";
import { LIMITS } from "../config/limits.js";
import { buildContext } from "./context.js";
import { executeTool } from "../tools/execute.js";
import { tokenUsageRepo } from "../db/repositories/token-usage.repo.js";
import { calculateCost } from "../observability/cost.js";
import { logger } from "../observability/logger.js";
import pRetry from "p-retry";
import type Anthropic from "@anthropic-ai/sdk";

export async function runAgent(params: {
  conversationId: string;
  userId: string;
  agentName: string;
  systemPrompt: string;
  tools: readonly Tool[];
  userInput: string;
  onStream: (chunk: string) => Promise<void>;
}): Promise<{ text: string; stopReason: string }> {
  const log = logger.child({
    conversationId: params.conversationId,
    userId: params.userId,
    agentName: params.agentName,
  });

  const messages = await buildContext(params.conversationId);
  messages.push({ role: "user", content: params.userInput });

  let turn = 0;
  let finalText = "";

  while (turn < LIMITS.maxTurnsPerSession) {
    turn += 1;
    const t0 = Date.now;

    const response = await pRetry(
       => anthropic.messages.create({
        model: MODELS.standard,
        max_tokens: 2048,
        system: [
          { type: "text", text: params.systemPrompt, cache_control: { type: "ephemeral" } },
        ],
        tools: params.tools.map(toAnthropicFormat),
        messages,
      }),
      { retries: 3, minTimeout: 1000, factor: 2 },
    );

    await tokenUsageRepo.insert({
      conversation_id: params.conversationId,
      user_id: params.userId,
      agent_name: params.agentName,
      model: response.model,
      input_tokens: response.usage.input_tokens,
      cache_read_tokens: response.usage.cache_read_input_tokens ?? 0,
      cache_creation_tokens: response.usage.cache_creation_input_tokens ?? 0,
      output_tokens: response.usage.output_tokens,
      cost_usd: calculateCost(response.model, response.usage),
      latency_ms: Date.now - t0,
    });

    for (const block of response.content) {
      if (block.type === "text") {
        finalText += block.text;
        await params.onStream(block.text);
      }
    }

    if (response.stop_reason !== "tool_use") {
      return { text: finalText, stopReason: response.stop_reason ?? "end_turn" };
    }

    messages.push({ role: "assistant", content: response.content });
    const toolResults: Anthropic.ToolResultBlockParam[] = [];
    for (const block of response.content) {
      if (block.type === "tool_use") {
        const result = await executeTool(block.name, block.input, params.tools, {
          userId: params.userId,
          conversationId: params.conversationId,
          logger: log,
        });
        toolResults.push({
          type: "tool_result",
          tool_use_id: block.id,
          content: result.content,
          is_error: result.isError,
        });
      }
    }
    messages.push({ role: "user", content: toolResults });
  }

  log.warn({ turn }, "MAX_TURNS_EXCEEDED");
  return { text: finalText + "\n\n[System: limit turn przekroczony]", stopReason: "max_turns" };
}
```

## `.gitignore`
```
node_modules/
dist/
.env
.env.local
coverage/
*.log
.DS_Store
tests/cassettes/*.local.json
```

## `.eslintrc` i `.prettierrc`
Identyczne jak w webapp-standards/boilerplate.md (flat config ESLint 9, Prettier 3.4). Nie duplikuję — importuj z webapp-standards lub powtórz te same pliki.
