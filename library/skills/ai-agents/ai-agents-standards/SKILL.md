---
name: ai-agents-standards
description: Standardy budowania agentów AI opartych o Anthropic SDK + WebSocket + Redis + PostgreSQL. Uruchamiaj gdy projektujesz, reviewujesz lub refaktoryzujesz kod agenta AI (LogicMorrow typ projektu `ai-agents`).
---

# Standardy AI agents — fundament

6 zasad absolutnych których NIGDY nie łamiemy w projektach `ai-agents`.

## Zasada 1 — `ANTHROPIC_API_KEY` tylko w `.env`
- Klucz API Anthropic **NIGDY** w kodzie źródłowym, repo, workflow JSON, logach.
- W `.env` na prod VPS, w `.env.example` tylko nazwa zmiennej bez wartości.
- Klient SDK czyta przez `process.env.ANTHROPIC_API_KEY` — brak zmiennej = hard crash przy starcie.
- Rotacja klucza: raz na 6 miesięcy lub natychmiast po incydencie.

## Zasada 2 — Prompt caching obowiązkowy dla treści >1024 tokenów
- Każdy system prompt, lista narzędzi lub długi kontekst >1024 tokenów **MUSI** mieć `cache_control: { type: "ephemeral" }`.
- Cache zmniejsza koszt powtarzalnych wywołań 10x — to nie optymalizacja, to standard.
- Cache breakpoints umieszczamy po stabilnych częściach (system prompt, tools), PRZED zmienną historią konwersacji.
- Szczegóły: `prompts.md`.

## Zasada 3 — Zasada najmniejszych uprawnień dla narzędzi (tool safety)
- Każdy agent ma **jawną whitelistę narzędzi** — nie dziedziczy globalnej listy.
- Narzędzia dostające dostęp do DB/filesystem/API mają **ograniczony scope** (np. `read_customer` działa tylko na własnych klientach usera, nie całej tabeli).
- Narzędzia destruktywne (delete, send, charge, publish) **ZAWSZE** przechodzą przez HITL (zasada 4).
- Szczegóły: `tools.md`.

## Zasada 4 — HITL dla akcji destruktywnych i nieodwracalnych
Human-in-the-Loop wymagane dla:
- Wysłanie emaila do zewnętrznego odbiorcy
- Obciążenie karty / wykonanie płatności
- DELETE/UPDATE w bazie danych produkcyjnej
- Publikacja treści publicznej (post, ogłoszenie)
- Zmiana uprawnień/ról użytkowników
- Zewnętrzne webhooki do systemów zewnętrznych (CRM, Slack, Meta Ads)

Wzorzec: agent tworzy rekord w `pending_actions`, user akceptuje przez UI, agent kontynuuje. Szczegóły: `hitl.md`.

## Zasada 5 — Max turns per session (ochrona przed pętlą)
- Twardy limit: **20 tool_use turns** per jedna odpowiedź użytkownika.
- Override per agent dozwolony (np. research agent: 50), ale wymaga uzasadnienia w kodzie.
- Po przekroczeniu: agent zwraca ostatnią częściową odpowiedź + `error: MAX_TURNS_EXCEEDED`, loguje incident.
- **Zawsze** pilnuj że pętla kończy się gdy `stop_reason !== "tool_use"`.

## Zasada 6 — Cost tracking per user/session od dnia 1
- Każde wywołanie API zapisuje do `token_usage`: `user_id`, `session_id`, `agent_name`, `model`, `input_tokens`, `cache_read_tokens`, `cache_creation_tokens`, `output_tokens`, `timestamp`.
- Dashboard kosztów: per user / per agent / per dzień.
- Alert gdy pojedynczy user przekroczy budżet dzienny (konfiguracyjny, default $5/dzień).
- **Bez tego nie wiesz kto pali tokeny** — standard od pierwszego uruchomienia.

## Powiązania
- `stack.md` — wersje bibliotek, schema DB
- `architecture.md` — warstwy systemu
- `prompts.md` — pisanie promptów, caching
- `tools.md` — definicje narzędzi, bezpieczeństwo
- `hitl.md` — Human-in-the-Loop w praktyce
- `production.md` — observability, retry, testing
- `boilerplate.md` — gotowe pliki konfiguracyjne
