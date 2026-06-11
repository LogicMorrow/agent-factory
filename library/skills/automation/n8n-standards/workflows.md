# Dokumentacja workflow i webhooki

## Obowiązkowy format dokumentacji każdego workflow
Każdy workflow opisany w `docs/` w pełnym formacie:

```markdown
## Workflow: [nazwa]

**Trigger:** webhook / harmonogram (cron: `0 9 * * 1-5`) / ręczny / zdarzenie n8n

**Cel:** [co ma się wydarzyć po zakończeniu — 1 zdanie]

### Kroki
| Nr | Node | Input | Output | Warunek |
|---|---|---|---|---|
| 1 | Webhook | HTTP POST /webhook/kontakt | JSON payload | walidacja pól |
| 2 | IF | dane z kroku 1 | rozgałęzienie | email present? |
| 3 | HTTP Request | dane z kroku 2 | response CRM | — |

### Obsługa błędów
- **4xx z zewnętrznego API:** [co robimy — log + alert / retry / ignore]
- **5xx z zewnętrznego API:** retry 3x z backoff 60s → jeśli nadal fail → alert na [email/Slack] + zapis do fallback
- **Błąd ogólny (node crash):** [gdzie alert, format alertu]
- **Alert format:** `{"workflow": "nazwa", "error": "opis", "timestamp": "ISO", "data": {...}}`

### Dane wejściowe (JSON schema)
```json
{
  "email": "string (wymagane)",
  "name": "string (wymagane)",
  "phone": "string (opcjonalne)"
}
```

### Dane wyjściowe
[Gdzie trafiają — baza / mail / CRM / następny workflow]
```

## Specyfikacja webhooków — format obowiązkowy

Dla każdego webhooka przychodzącego:

```markdown
### Webhook: [nazwa]
- **URL:** `/webhook/[ścieżka]`
- **Prod URL:** `https://n8n.firma.pl/webhook/[ścieżka]`
- **Metoda:** POST
- **Autoryzacja:** HMAC signature / Bearer Token / Basic Auth / brak
  - HMAC preferowany dla webhooków od zewnętrznych systemów
  - Header: `X-Signature: sha256=<hash>`
  - Weryfikacja: `HMAC-SHA256(secret, body) === signature`
- **Źródło:** [nazwa systemu który wysyła]

**Przykładowy payload:**
```json
{ "event": "contact.created", "data": { "email": "..." } }
```

**Walidacja:**
- Wymagane pola: `event`, `data.email`
- Typy: email musi być valid format
- Reakcja na niepoprawny payload: HTTP 400 `{"error": "Missing required field: email"}`

**Response sukces:** HTTP 200 `{"status": "ok"}`
**Response błąd walidacji:** HTTP 400 `{"error": "opis błędu"}`
```

## Idempotentność — wymaganie dla każdego workflow
Każdy workflow który tworzy dane (kontakt w CRM, rekord w bazie) musi być idempotentny:
- Ten sam payload dwa razy = jeden rezultat, nie dwa duplikaty
- Implementacja: sprawdź przed zapisem (`IF email exists → skip/update`)
- Przetestuj scenariusz duplikatu (patrz `testing.md`)

## Credentiale w node'ach — zakaz
Klucze API do zewnętrznych usług ZAWSZE w:
1. `.env` (na VPS) + n8n Credentials UI (zaszyfrowane N8N_ENCRYPTION_KEY)

NIGDY wklejone bezpośrednio do HTTP Request node lub innego node'a — bo eksport workflow ujawnia sekrety.
