# Procedura rotacji sekretow — krok po kroku

Uruchom gdy: sekret pojawil sie w context window konwersacji, hook `post-bash-secrets-filter.sh`
wystepowal DETECTED, lub podejrzewasz kompromitacje klucza z innego powodu.

**Disclaimer:** komendy ponizej sa generyczne. Przed wykonaniem zweryfikuj
je z karta projektu (`knowledge-base/projects/<projekt>.md`) i stackiem
(`docker-compose.yml`, `package.json`). Nie wykonuj slepie — dostosuj nazwy
kontenerow, serwisow i zmiennych do swojego projektu.

---

## Krok 1: Identyfikacja — ktore sekrety przeciekly

### Detection regex — uruchom na eksporcie sesji lub transkrypcie

Jesli masz export sesji (HTML / tekst) lub access do logu — przeszukaj wzorcami:

```bash
# Na eksporcie HTML sesji (jesli dostepny):
grep -oE '[A-Z_]+(PASSWORD|SECRET|TOKEN|API_KEY|AUTH_KEY)[[:space:]]*=[[:space:]]*[^[:space:]"'"'"']{8,}' session-export.txt

# Alternatywnie — szerszy pattern lacznie z vendorami:
grep -oE '(eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}|sk-ant-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9]{40,}|ghp_[A-Za-z0-9]{30,}|glpat-[A-Za-z0-9_-]{20,}|AKIA[A-Z0-9]{16})' session-export.txt

# PEM klucze prywatne:
grep -c 'BEGIN.*PRIVATE KEY' session-export.txt
```

Jesli nie masz eksportu — manualne review ostatnich 10-20 wiadomosci w sesji.
Szukaj linii wyglajacych jak `NAZWA=dlugi-losowy-ciag`.

### Checklist: co sprawdzic

- [ ] `POSTGRES_PASSWORD` / `DB_PASSWORD` — rotacja w PostgreSQL
- [ ] `JWT_SECRET` / `SESSION_SECRET` / `COOKIE_SECRET` — rotacja + invalidate sesji
- [ ] `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` — rotacja w dashboardzie providera
- [ ] `GITHUB_TOKEN` / `GH_PAT` — rotacja na github.com/settings/tokens
- [ ] Inne klucze API (Stripe, SendGrid, itp.) — rotacja w konsoli providera

---

## Krok 2: Rotacja per service

Dla kazdego sekretu z listy powyzej — wykonaj odpowiednia procedure.

### PostgreSQL — zmiana hasla uzytkownika

```bash
# Wygeneruj nowe haslo
NEW_PG_PASS="$(openssl rand -base64 32)"
echo "Nowe haslo wygenerowane (nie wyswietlam — zostanie zapisane do .env)"

# Polacz sie z postgres i zmien haslo
docker exec -i <container_name_postgres> psql -U postgres <<SQL
ALTER USER <db_user> WITH PASSWORD '${NEW_PG_PASS}';
SQL

# Zaktualizuj .env (bez wyswietlania)
sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${NEW_PG_PASS}|" .env
```

Zamien `<container_name_postgres>` na faktyczna nazwe kontenera (np. `crm_postgres`)
i `<db_user>` na nazwe uzytkownika z `docker-compose.yml`.

### JWT / Session Secret — regeneracja

```bash
# Wygeneruj nowy sekret (64 bajty = 86 znakow base64)
NEW_JWT="$(openssl rand -base64 64)"

# Zaktualizuj .env
sed -i "s|^JWT_SECRET=.*|JWT_SECRET=${NEW_JWT}|" .env
```

Po zmianie JWT_SECRET — WSZYSTKIE aktywne sesje sa nieważne automatycznie
(token signature nie passuje weryfikacji). Jesli sesje sa przechowywane w bazie
lub Redis — wykonaj krok 3.

### API Key providera (Anthropic, OpenAI, GitHub, etc.)

Nie mozna zrotowac programatycznie — wymagany interfejs webowy:

| Provider | URL rotacji |
|---|---|
| Anthropic | https://console.anthropic.com/settings/keys |
| OpenAI | https://platform.openai.com/api-keys |
| GitHub PAT | https://github.com/settings/tokens |
| GitLab PAT | https://gitlab.com/-/profile/personal_access_tokens |
| AWS IAM | https://console.aws.amazon.com/iam/home#/security_credentials |

Po rotacji — zaktualizuj `.env`:
```bash
# Wklej nowy klucz (nie wyswietlaj starego — juz skompromitowany)
sed -i "s|^ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=<nowy_klucz>|" .env
```

---

## Krok 3: Invalidate sesji jesli JWT

Jesli aplikacja przechowuje sesje po stronie serwera (baza lub Redis):

### Postgres — czyszczenie sesji

```bash
docker exec -i <container_name_postgres> psql -U postgres -d <dbname> <<SQL
-- Dopasuj do faktycznej struktury tabeli sesji w swoim projekcie
DELETE FROM sessions;
-- lub: DELETE FROM user_sessions WHERE expires_at < NOW + INTERVAL '0 seconds';
-- lub: TRUNCATE sessions;
SQL
```

### Redis — flush sesji

```bash
docker exec -i <container_name_redis> redis-cli FLUSHDB
# lub selektywnie:
docker exec -i <container_name_redis> redis-cli KEYS "sess:*" | xargs docker exec -i <container_name_redis> redis-cli DEL
```

Weryfikacja projektu: sprawdz `docker-compose.yml` czy Redis jest uzywany.
Jesli nie ma kontenera redis → ten krok pomijasz.
Szczegoly stacku sesji: karta projektu `knowledge-base/projects/<projekt>.md`.

---

## Krok 4: Update .env + restart compose + smoke test

```bash
# Weryfikacja ze .env ma zaktualizowane wartosci (sprawdz klucze, nie wartosci)
grep -E '^(POSTGRES_PASSWORD|JWT_SECRET|ANTHROPIC_API_KEY)=' .env | sed 's/=.*/=<UPDATED>/'

# Restart compose
docker compose down
docker compose up -d

# Poczekaj na start (dostosuj czas do projektu)
sleep 10

# Smoke test — sprawdz ze serwisy odpowiadaja
docker compose ps
docker exec <container_name_postgres> pg_isready -U postgres

# Jesli webapp — sprawdz health endpoint
curl -f http://localhost:<port>/api/health 2>/dev/null && echo "OK" || echo "FAIL"
```

Jesli `docker compose up -d` failuje z bledem autentykacji postgres:
sprawdz czy `sed -i` w kroku 2 poprawnie zaktualizowal wszystkie zmienne (lacznie
z POSTGRES_USER, DATABASE_URL jesli jest osobna zmienna).

---

## Krok 5: Log incident

Wpis do logu incydentu. Minimum co zapisac:

```bash
# Szybki log do .claude/security-incidents.log (lokalny)
cat >> .claude/security-incidents.log << INCIDENT
---
timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
type: secret-exposed-in-chat
secrets_rotated:
  - POSTGRES_PASSWORD: tak
  - JWT_SECRET: tak
  - <inne>: tak/nie
sessions_invalidated: tak/nie
compose_restarted: tak
smoke_test: pass/fail
notes: <opisz co sie stalo>
INCIDENT
echo "Log incident zapisany."
```

Jesli projekt jest objety runbookiem vps-security — dopisz wpis tam:
`<your-org>/vps-security/docs/05-INCIDENT-RESPONSE.md`

Format i wymagania runbooku: patrz ten plik bezposrednio (nie duplikujemy
zawartosci — separation of concerns).

---

## Checklist konczaca rotacje

- [ ] Krok 1: zidentyfikowalem ktore sekrety byly widoczne
- [ ] Krok 2: sprotujem kazdy sekret z listy
- [ ] Krok 3: invalidated sesje (jesli JWT)
- [ ] Krok 4: zaktualizowalem `.env`, zrobilem restart, smoke test przeszedl
- [ ] Krok 5: zalogowalem incident
- [ ] Po rotacji: nie uzywaj starych wartosci sekretow nigdzie (bookmarki, notatki, inne pliki)

Po kompletnej rotacji mozna wznowic sesje pracy.
