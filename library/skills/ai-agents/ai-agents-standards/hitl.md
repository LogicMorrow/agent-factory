# Human-in-the-Loop (HITL) — wzorzec i implementacja

## Definicja i uzasadnienie

HITL to **wymuszona pauza agenta** przed wykonaniem akcji destruktywnej. Agent:
1. Zgłasza zamiar (tool_use z `destructive: true`)
2. System tworzy rekord w `pending_actions`, wysyła SSE event do usera przez GET /notifications/stream
3. User w UI widzi żądanie, klika Approve / Reject (opcjonalnie edit inputu)
4. Agent dostaje decyzję, kontynuuje lub zwraca tekstową odpowiedź "anulowano"

## Lista akcji zawsze wymagających HITL
- Wysłanie emaila do zewnętrznego odbiorcy
- Obciążenie karty / wykonanie płatności
- `UPDATE` / `DELETE` w bazie produkcyjnej
- Publikacja treści publicznej (post, ogłoszenie, komentarz)
- Zmiana uprawnień/ról użytkowników
- Zewnętrzne API modyfikujące stan (CRM create/update, Slack post, Meta Ads campaign)
- Uruchomienie automatyzacji masowej (n8n webhook z mailingiem do >10 odbiorców)

**Reguła wyjątku:** narzędzie może pominąć HITL gdy usera instrukcje mówią wprost "bez pytania" **I** agent zapisze to jako user preference na czas sesji (nie na stałe). To świadoma delegacja odpowiedzialności — loguj każde takie użycie.

## Schema bazy (już w `stack.md`)

```sql
CREATE TABLE pending_actions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL,
  tool_name       TEXT NOT NULL,
  tool_input      JSONB NOT NULL,
  reason          TEXT,
  status          TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'rejected', 'expired')) DEFAULT 'pending',
  decided_at      TIMESTAMPTZ,
  decided_by      UUID,
  expires_at      TIMESTAMPTZ NOT NULL DEFAULT (NOW + INTERVAL '1 hour'),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW
);
```

## Flow krok po kroku

```
agent → tool_use (destruktywne)
  ↓
tools/hitl-wrapper.ts:
  1. INSERT pending_actions (status='pending', expires_at=NOW+1h)
  2. Redis PUB channel `sse:user:<user_id>` → { type: 'pending_action', action_id, tool_name, tool_input, reason }
  3. SUBSCRIBE Redis `pending_action:<action_id>:resolver` z timeoutem 1h
  ↓
Client (SSE na GET /notifications/stream):
  - Dostaje event, pokazuje modal: "Agent chce wysłać email do X z treścią Y. Zatwierdzić?"
  - User klika Approve / Reject (opcjonalnie edytuje input)
  ↓
PATCH /pending-actions/:id { status: 'approved', tool_input?: {...} }:
  1. UPDATE pending_actions SET status='approved', decided_at=NOW, decided_by=user_id
  2. Redis PUB `pending_action:<action_id>:resolver` → { status, tool_input }
  ↓
hitl-wrapper.ts (oczekujący na subscribe):
  - Otrzymuje decyzję
  - Jeśli approved → wykonuje tool.handler z zatwierdzonym inputem
  - Jeśli rejected → zwraca ToolResult("User odrzucił tę akcję.")
  - Jeśli timeout (1h) → UPDATE status='expired', zwraca ToolResult("Akcja wygasła.")
  ↓
agent kontynuuje z tool_result
```

## Kod — HITL wrapper

```typescript
// tools/hitl-wrapper.ts
import { pendingActionRepo } from "../db/repositories/pending-action.repo";
import { redis, pub, sub } from "../state/redis";

export interface ApprovalRequest {
  toolName: string;
  toolInput: unknown;
  userId: string;
  conversationId: string;
  reason?: string;
}

export async function requestApproval(req: ApprovalRequest): Promise<{
  status: "approved" | "rejected" | "expired";
  toolInput?: unknown;
}> {
  const action = await pendingActionRepo.create({
    conversationId: req.conversationId,
    userId: req.userId,
    toolName: req.toolName,
    toolInput: req.toolInput,
    reason: req.reason,
  });

  // Powiadom frontend przez SSE (GET /notifications/stream subskrybuje ten kanał)
  await pub.publish(
    `sse:user:${req.userId}`,
    JSON.stringify({
      type: "pending_action",
      actionId: action.id,
      toolName: action.tool_name,
      toolInput: action.tool_input,
      reason: action.reason,
      expiresAt: action.expires_at,
    }),
  );

  // Czekaj na decyzję (max 1h, timeout = expired)
  return new Promise((resolve) => {
    const channel = `pending_action:${action.id}:resolver`;
    const timeoutMs = 60 * 60 * 1000;
    const timer = setTimeout(async  => {
      sub.unsubscribe(channel);
      await pendingActionRepo.markExpired(action.id);
      resolve({ status: "expired" });
    }, timeoutMs);

    sub.subscribe(channel);
    sub.once("message", (_ch, payload) => {
      clearTimeout(timer);
      sub.unsubscribe(channel);
      const decision = JSON.parse(payload) as {
        status: "approved" | "rejected";
        toolInput?: unknown;
      };
      resolve(decision);
    });
  });
}
```

## Endpoint resolvera (REST)

```typescript
// http/routes/pending-actions.ts
import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import { pendingActionRepo } from "../../db/repositories/pending-action.repo.js";
import { pub } from "../../state/redis.js";

export const pendingActionsRoutes = new Hono;

pendingActionsRoutes.patch(
  "/:id",
  zValidator("json", z.object({
    status: z.enum(["approved", "rejected"]),
    toolInput: z.unknown.optional,
  })),
  async (c) => {
    const id = c.req.param("id");
    const body = c.req.valid("json");
    const userId = c.get("userId"); // ustawiony przez middleware JWT

    const action = await pendingActionRepo.findById(id);
    if (!action) return c.json({ error: "not found" }, 404);
    if (action.user_id !== userId) return c.json({ error: "forbidden" }, 403);
    if (action.status !== "pending") return c.json({ error: "already decided" }, 409);
    if (new Date(action.expires_at) < new Date) return c.json({ error: "expired" }, 410);

    await pendingActionRepo.decide(id, body.status, userId);
    await pub.publish(
      `pending_action:${id}:resolver`,
      JSON.stringify({ status: body.status, toolInput: body.toolInput ?? action.tool_input }),
    );
    return c.json({ ok: true });
  },
);
```

## UI — minimalne wymagania
- Modal pojawia się natychmiast po SSE event `pending_action` z GET /notifications/stream
- Wyświetla: nazwę narzędzia (po polsku, ludzkim językiem), input (sformatowany, nie raw JSON), reason (dlaczego agent chce)
- 3 akcje: **Approve**, **Approve with changes** (edytujesz JSON lub formularz), **Reject**
- Timer pokazujący czas do expires_at
- Lista wszystkich pending_actions dostępna w osobnym widoku "Do zatwierdzenia"

## Zasady UX
- **Human-friendly nazwy** — nie `send_email`, tylko "Wyślij email do Jan Kowalski <jan@firma.pl>"
- **Widoczna konsekwencja** — "Ta akcja wyśle email do zewnętrznego odbiorcy i nie może być cofnięta"
- **Edycja inputu** — user ma prawo zmienić treść zanim zatwierdzi (np. poprawić email)
- **Historia decyzji** — widoczna lista zatwierdzonych/odrzuconych z timestampami (audyt)

## Observability
- Loguj każdą decyzję: `logger.info({ action_id, status, latency_ms }, "hitl decision")`
- Metryka `hitl_decision_latency_seconds` — histogram (ile user czeka zanim klika)
- Alert gdy `expired_ratio > 30%` (za dużo akcji wygasa — UX problem)

## Antywzorce
- ❌ Wykonanie akcji destruktywnej bez HITL "bo user jest zajęty" — zawsze pending_action
- ❌ HITL dla read-only — spowalnia bez potrzeby, zjada cierpliwość usera
- ❌ Timeout 5 minut — za krótki, user może być na spotkaniu. 1h jest standardem.
- ❌ Jednorazowa zgoda na "wszystkie future akcje tego typu" bez limitu czasowego — za bardzo otwarta furtka
- ❌ Wysyłanie pending_action tylko emailem (nie przez SSE) — user nie zauważy natychmiast
