# Prompty — pisanie, cache, zarządzanie historią

## Struktura system prompt (obowiązkowa)

Każdy system prompt składa się z 5 sekcji w tej kolejności:

```
1. Rola (kim jest agent)
2. Kontekst (informacje stałe — firma, produkt, user)
3. Zasady (czego MA i NIE MA robić)
4. Narzędzia (lista + kiedy których używać)
5. Format odpowiedzi (struktura, język, ton)
```

**Dlaczego w tej kolejności:** model czyta top-down. Rola ustala perspektywę, zasady ograniczają przestrzeń, narzędzia definiują możliwe akcje, format kontroluje output.

**Długość:** 400-1500 tokenów. Powyżej 1500 → refaktor na pliki tematyczne + retrieval, nie pakuj wszystkiego w prompt.

## Prompt caching — wzorzec

Cache markers umieszczamy po sekcjach **stabilnych**, PRZED częściami **zmiennymi**:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic;

const response = await client.messages.create({
  model: MODELS.standard,
  max_tokens: 2048,
  system: [
    {
      type: "text",
      text: SYSTEM_PROMPT,  // >1024 tokenów → cachowalne
      cache_control: { type: "ephemeral" },
    },
  ],
  tools: [
    ...TOOLS,
  ],
  // ostatnie narzędzie z cache_control → cache obejmuje cały tools block
  messages: conversationHistory,  // NIE cachujemy — zmienia się co turn
});
```

**Zasady:**
1. **System prompt zawsze z cache_control** jeśli >1024 tokenów.
2. **Tools block zawsze z cache_control** jeśli ≥4 narzędzia (długi schemat JSON).
3. **Max 4 cache breakpoints** w jednym requeście (limit API).
4. **NIE cachujemy** wiadomości użytkownika ani odpowiedzi agenta — historia zmienia się co turn.
5. **Cache TTL 5 minut** (ephemeral) — do stałego ruchu wystarczy.

### Weryfikacja że cache działa
W odpowiedzi API sprawdź `usage.cache_read_input_tokens`:
- `> 0` → cache HIT
- `= 0` → cache MISS (pierwszy request lub TTL expired)

Oczekiwany hit rate po warm-upie: **>80%**. Poniżej → sprawdź czy prompty nie mają losowych elementów (timestamp, uuid) przed cache breakpoint.

## Konwersacja — strategia kontekstu

### Reguła: NIE wysyłaj całej historii co turn
Po 20 wiadomościach kontekst zaczyna być drogi. Stosujemy:

1. **Pełna historia** ≤ 10 ostatnich wiadomości — wysyłamy jak jest.
2. **Historia > 10 wiadomości** — aktywujemy summarization:
   - Najstarsze wiadomości → jedno podsumowanie (system message tekst)
   - Ostatnie 10 wiadomości → pełne
3. **Summarization wykonywany przez Haiku** (tanio), cacheable w Redis na session lifetime.

### Kod (pseudokod)
```typescript
async function buildContext(conversationId: string): Promise<Message[]> {
  const all = await messageRepo.findByConversation(conversationId);
  if (all.length <= 10) return all;
  
  const summary = await getOrCreateSummary(conversationId, all.slice(0, -10));
  const recent = all.slice(-10);
  
  return [
    { role: "user", content: `[Streszczenie wcześniejszej rozmowy]\n${summary}` },
    ...recent,
  ];
}
```

### Kiedy summarization się uruchamia
- Po `message count % 10 === 0` (np. co 10 nowych wiadomości) — w tle, nie blokuje agenta
- Lub gdy total token count aktualnej historii > 8000 (aprox)

## System prompt — przykład (szablon)

```typescript
export const SYSTEM_PROMPT = `
# Rola
Jesteś asystentem sprzedaży w firmie DemoTargi. Pomagasz pracownikom
obsługiwać zapytania od wystawców targowych B2B.

# Kontekst
- Firma: DemoTargi (demo-targi.example), B2B, wystawcy na targach
- Produkty: stoiska, projektowanie, montaż
- User to pracownik działu sprzedaży (ma pełny dostęp do CRM)

# Zasady
1. Pytaj zanim zmienisz rekord w CRM — zawsze przez pending_actions.
2. Przy wątpliwości co do danych klienta — pytaj, nie zgaduj.
3. Nie proponuj cen bez konsultacji z cennikiem (narzędzie \`get_pricing\`).
4. Nie wysyłaj emaili bezpośrednio — wszystko przez \`send_email\` z HITL.

# Dostępne narzędzia
- \`search_customer\`: wyszukaj klienta po nazwie/NIP/email (read-only, OK bez HITL)
- \`get_customer_details\`: szczegóły klienta (read-only)
- \`get_pricing\`: cennik aktualny (read-only)
- \`create_task\`: utwórz zadanie w CRM (zmiana DB — HITL)
- \`send_email\`: wyślij email do klienta (destrukcyjne — HITL)
- \`update_customer\`: zmień dane klienta (destrukcyjne — HITL)

# Format odpowiedzi
- Po polsku, zwięźle, konkretnie.
- Gdy używasz narzędzia — najpierw krótko powiedz co robisz.
- Na końcu długiej odpowiedzi — lista następnych kroków (bullet points).
`.trim;
```

## Wersjonowanie promptów
- Prompty **NIE siedzą inline** w logice agent loop.
- Każdy agent ma `agents/<nazwa>/system-prompt.ts` z eksportowaną stałą.
- Zmiany promptu przechodzą przez PR review (dokładnie jak kod).
- **Nie A/B testujemy promptów na produkcji bez feature flag** — jeśli testujesz, to dwie wersje za flagą, 50/50.

## Antywzorce
- ❌ System prompt z losowymi elementami (timestamp, uuid) — niszczy cache
- ❌ Wrzucanie całej dokumentacji firmowej do system promptu — użyj retrieval/tools
- ❌ Instrukcje zależne od czasu ("pamiętaj że dziś jest wtorek") — przekaż datę jako wiadomość user, nie w system
- ❌ Hardcode nazwy modelu w prompcie — model nie czyta o sobie, to dezinformacja
- ❌ Kopiowanie tego samego długiego prompta do 5 agentów — wydziel wspólną część jako `lib/prompts/shared.ts`
