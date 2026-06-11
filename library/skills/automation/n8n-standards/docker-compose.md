# Docker Compose — konfiguracja obowiązkowa

## Pełna konfiguracja (z boilerplate.md)
Zawsze korzystaj z `boilerplate.md` dla exact zawartości pliku. Poniżej kluczowe wyjaśnienia decyzji.

## Krytyczne ustawienia n8n (każde musi być obecne)

| Zmienna | Wartość | Dlaczego |
|---|---|---|
| `DB_TYPE` | `postgresdb` | SQLite = FAIL |
| `N8N_ENCRYPTION_KEY` | `${N8N_ENCRYPTION_KEY}` | Nigdy hardcoded, nigdy zmieniana po wdrożeniu |
| `N8N_PROTOCOL` | `https` (prod) | HTTP = security FAIL |
| `WEBHOOK_URL` | pełny publiczny URL ze schematem | Bez tego webhooki zwracają localhost |
| `EXECUTIONS_DATA_SAVE_ON_ERROR` | `all` | Każdy błąd zapisany do analizy |
| `EXECUTIONS_DATA_SAVE_ON_SUCCESS` | `none` | Sukcesy nie zapychają bazy |
| `EXECUTIONS_DATA_PRUNE` | `true` | Auto-czyszczenie |
| `EXECUTIONS_DATA_MAX_AGE` | `168` (7 dni) | Bez tego baza puchnie, n8n zwalnia |
| `restart` | `unless-stopped` | Auto-restart po crashu/restarcie VPS |

## Healthcheck bazy (obowiązkowy)
```yaml
db:
  healthcheck:
    test: ['CMD-SHELL', 'pg_isready -U ${DB_USER} -d ${DB_NAME}']
    interval: 10s
    timeout: 5s
    retries: 5
```
n8n musi mieć `depends_on: db: condition: service_healthy` — inaczej startuje przed bazą i crasha.

## 13 pułapek — checklist przed deployem

1. **N8N_ENCRYPTION_KEY** ustawiony i NIE zmieniony od poprzedniego deploy
2. **DB_TYPE=postgresdb** — nie postgresdb_env, nie SQLite
3. **WEBHOOK_URL** = pełny URL ze schematem (`https://n8n.firma.pl/`) — ze slash na końcu
4. **N8N_PROTOCOL=https** na prod
5. **Konkretny tag** obrazu — `n8nio/n8n:1.70.0`, nie `latest`
6. **EXECUTIONS_DATA_MAX_AGE=168** obecne
7. **Healthcheck** bazy skonfigurowany, `depends_on: service_healthy`
8. **Backup skonfigurowany** — cron aktywny, oba poziomy (baza + workflow)
9. **Credentiale zewnętrznych API** w n8n Credentials (zaszyfrowane), nie wklejone bezpośrednio do nodes
10. **POSTGRES_USER** to nie superuser — dedykowany user n8n
11. **Baza niedostępna publicznie** — tylko Docker network
12. **Wolumeny** zdefiniowane (n8n_data, postgres_data) — bez wolumenów dane giną przy restarcie
13. **restart: unless-stopped** na obu serwisach

## Antywzorce
- ❌ `image: n8nio/n8n:latest` — wersja zmienia się bez wiedzy, breakingi
- ❌ Brak `depends_on: condition: service_healthy` — n8n startuje przed bazą
- ❌ `WEBHOOK_URL=http://` na prod — webhooki nie działają przez HTTPS
- ❌ `N8N_ENCRYPTION_KEY` pusty lub hardcoded w docker-compose.yml
- ❌ Brak `EXECUTIONS_DATA_PRUNE=true` — baza rośnie bez ograniczeń
