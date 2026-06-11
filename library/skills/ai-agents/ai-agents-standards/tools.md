# Narzędzia (tools) — definicja, walidacja, bezpieczeństwo

## Struktura narzędzia

Każde narzędzie to obiekt implementujący interfejs `Tool`:

```typescript
import { z } from "zod";

export interface Tool<TInput = unknown, TOutput = unknown> {
  name: string;
  description: string;        // dla modelu — KIEDY użyć, nie jak
  inputSchema: z.ZodType<TInput>;
  destructive: boolean;       // wymusza HITL jeśli true
  handler: (input: TInput, ctx: ToolContext) => Promise<TOutput>;
}

export interface ToolContext {
  userId: string;
  conversationId: string;
  logger: Logger;
}
```

## Przykład: narzędzie read-only (bez HITL)

```typescript
import { z } from "zod";
import { customerRepo } from "../db/repositories/customer.repo";

const InputSchema = z.object({
  query: z.string.min(2).max(100).describe("nazwa/NIP/email klienta"),
  limit: z.number.int.min(1).max(20).default(10),
});

export const searchCustomerTool: Tool<z.infer<typeof InputSchema>, Customer[]> = {
  name: "search_customer",
  description: "Wyszukuje klientów po nazwie, NIP lub emailu. Użyj gdy user prosi o znalezienie klienta. Zwraca max 20 wyników.",
  inputSchema: InputSchema,
  destructive: false,
  handler: async (input, ctx) => {
    ctx.logger.info({ tool: "search_customer", input }, "executing");
    // Principle of least privilege: tylko klienci dostępni dla tego usera
    return customerRepo.searchForUser(ctx.userId, input.query, input.limit);
  },
};
```

## Przykład: narzędzie destruktywne (wymusza HITL)

```typescript
const SendEmailSchema = z.object({
  to: z.string.email,
  subject: z.string.min(1).max(200),
  body: z.string.min(1).max(10000),
});

export const sendEmailTool: Tool<z.infer<typeof SendEmailSchema>, { messageId: string }> = {
  name: "send_email",
  description: "Wysyła email do odbiorcy zewnętrznego. Wymaga zatwierdzenia przez użytkownika przed wykonaniem.",
  inputSchema: SendEmailSchema,
  destructive: true,  // ⚠️ wymusza przejście przez hitlWrapper
  handler: async (input, ctx) => {
    // Ten handler uruchomi się TYLKO po user.approve
    const result = await emailService.send(input);
    ctx.logger.info({ messageId: result.messageId }, "email sent");
    return result;
  },
};
```

## Eksport narzędzi do Anthropic API

SDK oczekuje formatu `ToolUnion`. Generujemy z `Tool`:

```typescript
import { zodToJsonSchema } from "zod-to-json-schema";

export function toAnthropicFormat(tool: Tool): Anthropic.Tool {
  return {
    name: tool.name,
    description: tool.description,
    input_schema: zodToJsonSchema(tool.inputSchema, {
      target: "openApi3",
      $refStrategy: "none",
    }) as Anthropic.Tool.InputSchema,
  };
}
```

## Whitelist per agent

Każdy agent deklaruje listę dostępnych narzędzi — NIE ma globalnej puli.

```typescript
// agents/sales-assistant/tools.ts
import { searchCustomerTool } from "../../tools/search-customer";
import { getPricingTool } from "../../tools/get-pricing";
import { sendEmailTool } from "../../tools/send-email";

export const SALES_ASSISTANT_TOOLS = [
  searchCustomerTool,
  getPricingTool,
  sendEmailTool,
] as const;
```

**Dlaczego:** agent nie powinien "przypadkiem" mieć dostępu do narzędzi z innego obszaru. Whitelist per agent wymusza świadomość zakresu.

## Wykonywanie narzędzia w agent loop

```typescript
async function executeTool(
  toolName: string,
  toolInput: unknown,
  agentTools: readonly Tool[],
  ctx: ToolContext,
): Promise<ToolResult> {
  const tool = agentTools.find(t => t.name === toolName);
  if (!tool) {
    return { isError: true, content: `Tool '${toolName}' not available for this agent` };
  }

  // 1. Walidacja inputu przez Zod
  const parsed = tool.inputSchema.safeParse(toolInput);
  if (!parsed.success) {
    return { isError: true, content: `Invalid input: ${parsed.error.message}` };
  }

  // 2. Destruktywne → HITL
  if (tool.destructive) {
    const decision = await requestApproval({
      toolName: tool.name,
      toolInput: parsed.data,
      userId: ctx.userId,
      conversationId: ctx.conversationId,
    });
    if (decision.status !== "approved") {
      return { isError: false, content: `User ${decision.status} this action.` };
    }
  }

  // 3. Wykonanie
  try {
    const result = await tool.handler(parsed.data, ctx);
    return { isError: false, content: JSON.stringify(result) };
  } catch (err) {
    ctx.logger.error({ err, tool: tool.name }, "tool execution failed");
    return { isError: true, content: `Tool '${tool.name}' failed: ${errorMessage(err)}` };
  }
}
```

## Zasady bezpieczeństwa

### 1. Walidacja Zod jest OBOWIĄZKOWA
Nigdy nie ufaj `toolInput` od modelu. Model może wyhalucynować typ. Parsuj zanim użyjesz.

### 2. Ograniczony scope
Każde narzędzie dostaje `userId` w contexcie. Handler MUSI filtrować dane do tego usera — nie ma narzędzia "dostań wszystkich klientów" bez filtra.

```typescript
// ❌ ŹLE
handler: async (input) => customerRepo.findAll

// ✅ DOBRZE
handler: async (input, ctx) => customerRepo.findForUser(ctx.userId)
```

### 3. Input sanitization
SQL injection, path traversal, SSRF — model może wprowadzić złośliwe wartości jeśli user go prompt-injectnie. Walidacja Zod + dodatkowe checki:
- Ścieżki plików: whitelist katalogów
- URL-e: whitelist domen
- SQL: zawsze parametryzowane zapytania (to akurat robi ORM/repo — nie konstruuj SQL ze stringów)

### 4. Tool description — co pisać
- **KIEDY** użyć narzędzia (trigger), nie **JAK** działa wewnętrznie
- Przykładowe sytuacje z życia
- Ograniczenia (max items, rate limit)

```
✅ "Wyszukuje klientów po nazwie, NIP lub emailu. Użyj gdy user prosi o znalezienie klienta. Zwraca max 20 wyników."

❌ "Wykonuje SELECT z JOIN na tabelach customers i users z WHERE LIKE."
```

### 5. Error handling — nie pokazuj modelowi stack trace
W `ToolResult` wysyłaj czytelny komunikat. Stack trace leć do logger'a.

```typescript
// ❌ ŹLE
return { isError: true, content: err.stack }

// ✅ DOBRZE
logger.error({ err }, "tool failed");
return { isError: true, content: "Narzędzie nie zadziałało: timeout bazy danych." };
```

## Antywzorce
- ❌ Jedno "mega-narzędzie" `execute_database_query` z free-form SQL
- ❌ Tool bez `destructive: true` gdy faktycznie modyfikuje dane
- ❌ `handler` który woła kilka endpointów zewnętrznych sekwencyjnie bez timeout
- ❌ Tool description po angielsku gdy reszta promptów po polsku (model się gubi w językach)
- ❌ Return JSON-string jako content dla nie-JSON danych — model nie musi parsować; return plain text
