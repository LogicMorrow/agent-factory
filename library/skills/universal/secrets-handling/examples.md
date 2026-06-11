# secrets-handling — przykłady (7 case'ów)

Plik pomocniczy do `SKILL.md`. Kazdy case pokazuje realna sytuacje z projektu
z `.env` w cwd (Docker Compose, Next.js, n8n, dowolny backend).

---

## Case 1: Chce zobaczyc strukture docker-compose.yml

**Co uzytkownik chce osiagnac:** sprawdzic jakie serwisy, porty i sieci sa
zdefiniowane w `docker-compose.yml`, zeby napisac komende `docker compose up`.

❌ Niebezpieczne podejscie:
```
docker compose config
```
Dlaczego zle: Docker Compose v2 zawsze wczytuje `.env` z cwd i rozwijazmienne
inline w output. `POSTGRES_PASSWORD`, `JWT_SECRET`, wszystkie API keys pojawia sie
w stdout → trafiaja do context window Claude → log konwersacji.

✅ Bezpieczne podejscie:
```
docker compose config --no-interpolate
```
Dlaczego OK: flaga `--no-interpolate` zatrzymuje podstawianie. Output zawiera
literalne `${POSTGRES_PASSWORD}` — struktura widoczna, wartosc ukryta.

Alternatywnie (parse-only, bez zadnego czytania `.env`):
```
yq eval '.services | keys' docker-compose.yml
yq eval '.services.postgres' docker-compose.yml
```
`yq` nie wczytuje `.env` w ogole — najczystsze podejscie gdy interesuje tylko
struktura YAML, nie resolved wartosci.

---

## Case 2: Chce sprawdzic czy POSTGRES_PASSWORD jest w .env

**Co uzytkownik chce osiagnac:** weryfikacja ze zmienna istnieje w pliku `.env`
przed uruchomieniem migracji.

❌ Niebezpieczne podejscie:
```
cat .env
```
lub
```
grep POSTGRES_PASSWORD .env
```
Dlaczego zle: `cat` wyswietla caly plik. `grep` bez `-c` wyswietla dopasowana
linie z wartoscia (`POSTGRES_PASSWORD=abc123secret`). Obydwa trafia do context
window.

✅ Bezpieczne podejscie:
```
grep -c '^POSTGRES_PASSWORD=' .env
```
Dlaczego OK: `-c` zwraca tylko liczbe (1 lub 0) — czy klucz istnieje, bez wartosci.

Alternatywnie jesli sprawdzasz czy klucz jest non-empty:
```
grep -q '^POSTGRES_PASSWORD=.\+' .env && echo "SET" || echo "EMPTY OR MISSING"
```
`-q` = quiet mode, brak output wartosci. Exit code decyduje o wyniku.

---

## Case 3: Container nie startuje, chce zobaczyc logi

**Co uzytkownik chce osiagnac:** sprawdzic blad startupowy w logu kontenera Postgres.

❌ Niebezpieczne podejscie (nie zawsze — ale ryzyko):
```
docker logs crm_postgres
```
Dlaczego potencjalnie zle: niektorzy aplikacje wypisuja do logow konfiguracje
startupowa wlacznie ze zmiennymi srodowiskowymi (np. `POSTGRES_PASSWORD received`
w debug mode). `post-bash-secrets-filter.sh` (warstwa 3) skanuje ten output.

✅ Bezpieczne podejscie:
```
docker logs --tail 30 crm_postgres 2>&1 | grep -v 'PASSWORD\|SECRET\|TOKEN\|KEY='
```
Dlaczego OK: `grep -v` odfiltrowuje linie z nazwami sekretow przed outputem.
Wartosc sie nie pojawia jesli jest na tej samej linii co label.

Jesli warstwa 3 (`post-bash-secrets-filter.sh`) jest zainstalowana i zablokuje
`docker logs` — nie walcz z hookiem. Sprawdz logi przez dostep do kontenera
bez eksponowania sekretow:
```
docker exec crm_postgres pg_isready -U postgres
docker inspect crm_postgres | yq '.[].State'
```

---

## Case 4: Chce zaktualizowac wartosc JWT_SECRET w .env

**Co uzytkownik chce osiagnac:** zrotowac JWT secret po incydencie — nadpisac
stara wartosc nowa bez wyswietlania pliku.

❌ Niebezpieczne podejscie:
```
cat .env
# skopiuj, zmien w edytorze, wklej
```
lub (rownie zle):
```
nano .env
# edytor moze byc nieprzyjazny w headless SSH
```
Dlaczego zle: `cat` przed edycja ujawnia wszystkie wartosci do context window.
`nano` nie jest niebezpieczny sam w sobie, ale Claude Code moze przeczytac plik
jako preview.

✅ Bezpieczne podejscie:
```
NEW_SECRET="$(openssl rand -base64 48)"
sed -i "s|^JWT_SECRET=.*|JWT_SECRET=${NEW_SECRET}|" .env
echo "JWT_SECRET zaktualizowany. Nowa wartosc: [nie wyswietlam — sprawdz .env]"
```
Dlaczego OK: `sed -i` modyfikuje plik in-place bez wyswietlania zawartosci.
`openssl rand` generuje nowy sekret w zmiennej shell — wartosc nie jest echoed.
Nowa wartosc nie pojawia sie w context window Claude.

Uwaga: ta komenda eksponuje `NEW_SECRET` jako zmienna shell przez chwile.
Jesli to nie jest akceptowalne, wygeneruj sekret out-of-band i wklej recznie
(poza sesja Claude).

---

## Case 5: Chce commitowac zmiane w docker-compose.yml

**Co uzytkownik chce osiagnac:** commitowac aktualizacje obrazu w `docker-compose.yml`
bez przypadkowego dodania `.env` do commita.

❌ Niebezpieczne podejscie:
```
git add .
git commit -m "update compose"
```
Dlaczego zle: `git add .` doda `.env` jesli nie ma go w `.gitignore`. Raz
w historii git — sekret widoczny przez `git log -p` nawet po usunieciu pliku.

✅ Bezpieczne podejscie:
```
# Sprawdz czy .env jest w .gitignore
grep -q '\.env$' .gitignore || echo "UWAGA: .env nie jest w .gitignore"

# Dodaj tylko konkretne pliki
git add docker-compose.yml
git status  # weryfikacja przed commitem
git commit -m "chore(compose): update postgres image to 16.2"
```
Dlaczego OK: jawne `git add <plik>` zamiast `git add .` eliminuje ryzyko
przypadkowego dodania `.env`.

Jesli `.env` juz jest tracked (przez pomylke z przeszlosci):
```
git rm --cached .env
echo ".env" >> .gitignore
git commit -m "fix: remove .env from tracking, add to .gitignore"
```
Jesli sekret trafil juz do historii — konieczny BFG Repo Cleaner (patrz
`rotation-procedure.md`).

---

## Case 6: Hook falszywie zablokował moja komende

**Co uzytkownik chce osiagnac:** uruchomic komende ktora hook zidentyfikowal
jako niebezpieczna, ale uzytkownik wie ze jest bezpieczna (np. `grep -c`
ktory hook zinterpretował jako ryzykowny).

❌ Niebezpieczne podejscie:
```
# Wymuszenie przez obejscie hooka — NIE ROB TEGO
CLAUDE_HOOK_BYPASS=1 bash -c "cat .env"
```
lub znajdowanie innych sposobow na uruchomienie komendy z pomieciem hookow.

Dlaczego zle: hook jest celowy. Omijanie = brak obrony. Nawet jesli ta konkretna
komenda jest bezpieczna — precedens omijania hookow otwiera droge do przyszlych
pomylek.

✅ Bezpieczne podejscie:
```
# Krok 1: Przeczytaj message hooka — zawiera konkretna alternatywe
# Krok 2: Jesli alternatywa nie istnieje, dodaj wyjątek do ALLOWED_PATTERNS:

# Otwórz plik hooka
# vim library/hooks/block-env-leak.sh (lub w projekcie: .claude/hooks/block-env-leak.sh)

# Znajdz tablice ALLOWED_PATTERNS i dodaj regex:
# 'twoj-wzorzec-regex-opisujacy-bezpieczna-komende'

# Krok 3: Uzasadnij komentarzem DLACZEGO ta komenda jest bezpieczna
# Krok 4: Uruchom komende ponownie — hook przepusci
```
Dlaczego OK: `ALLOWED_PATTERNS` to mechanizm whitelist do update'u. Zmieniasz
regule, nie omijasz enforcement.

Jesli masz watpliwosci czy update jest własciwy — zapytaj operatora przed
modyfikacja hooka.

---

## Case 7: Sekret JUZ widac w chacie — uruchom rotation-procedure

**Co uzytkownik chce osiagnac:** wartości `POSTGRES_PASSWORD=abc123secret` lub
podobna pojawila sie w oknie konwersacji. Co teraz?

❌ Niebezpieczne podejscie:
```
# Kontynuuj sesje, "przeciez to tylko lokalnie"
# Lub: zmien wartosc "pozniej"
```
Dlaczego zle: sekret ktory trafil do context window trafil do logu konwersacji
(Anthropic API). Nie wiadomo kiedy i jak logi sa rotowane. Zasada zerowego
zaufania: sekret ktory byl widoczny = sekret skompromitowany.

✅ Bezpieczne podejscie:
```
# Natychmiast przejdz do rotation-procedure.md
# library/skills/universal/secrets-handling/rotation-procedure.md

# Kolejnosc:
# 1. Identyfikuj ktore sekrety sa widoczne (nie wszystkie musza byc skompromitowane)
# 2. Dla kazdego — rotacja (postgres ALTER USER, openssl rand dla JWT, dashboard dla API keys)
# 3. Jesli JWT — invalidate istniejacych sesji
# 4. Update .env, restart compose, smoke test
# 5. Log incident
```
Dlaczego OK: szybka rotacja minimalizuje okno ekspozycji. Nawet jesli sekret
byl widoczny sekundy — rotacja jest wlasciwa odpowiedzia.

Pelna procedura krok po kroku z konkretnymi komendami:
`library/skills/universal/secrets-handling/rotation-procedure.md`
