# examples — error-memory-framework

5 walidnych case'ow + 3 niewalidne wpisy z wyjasnieniam.
Kazdy case zawiera: kontekst, uzasadnienie severity, gotowy wpis do skopiowania.

---

## WALIDNE WPISY

---

### Case 1 — HIGH: Agent ignoruje hook block-env-leak i wywoluje docker compose config

**Kontekst:** 2026-05-06, external-crm, sesja  etap B2. Agent 8 razy w jednej sesji
wywolal `docker compose config` mimo ze hook `block-env-leak.sh` blokowal komende. Za kazdym razem
nastepowala rotacja `POSTGRES_PASSWORD`. Wzorzec cross-project: dotyczy kazdego projektu z `.env`.

**Uzasadnienie severity HIGH:** pattern architektoniczny (agent nie zaladowal skilla przed planowaniem),
repeatable (potwierdzony 8x w sesji), cross-project (kazdy projekt z docker compose jest podatny).
Promotion do `lessons.jsonl` — inne agenty w innych projektach powinny wiedziec.

**Wpis dla:** `errors-agent-architect.md` lub `errors-skill-builder.md` (agenty ktore planuja komendy)

```markdown
## 2026-05-06 — Agent wywoluje docker compose config mimo blokady hooka
- **error-summary:** Agent wywoluje `docker compose config` mimo aktywnego hooka block-env-leak.sh powodujac ekspozycje sekretow
- **cause-root:** Agent nie zaladowal skilla secrets-handling przed planowaniem komendy; hook blokuje ale agent ponawia probe zamiast uzywac bezpiecznej alternatywy
- **prevention:** Zawsze zaladuj skill secrets-handling gdy w projekcie istnieje plik `.env`; uzywaj `docker compose config --no-interpolate` lub `yq eval '.services' docker-compose.yml`
- **severity:** HIGH
- **context:** knowledge-base/reflections/2026-05-06-secrets-handling-skill.md
<!-- hash: 4a7f2b8c1d9e3f5a6b0c2d4e5f6a7b8c -->
```

**Promotion do lessons.jsonl:**
```json
{"date":"2026-05-06","agent":"agent-architect","error_summary":"Agent wywoluje docker compose config mimo aktywnego hooka block-env-leak.sh powodujac ekspozycje sekretow","cause_root":"Agent nie zaladowal skilla secrets-handling przed planowaniem komendy; hook blokuje ale agent ponawia probe zamiast uzywac bezpiecznej alternatywy","prevention":"Zawsze zaladuj skill secrets-handling gdy w projekcie istnieje plik .env; uzywaj docker compose config --no-interpolate lub yq eval","source":"error-memory","severity":"HIGH"}
```

---

### Case 2 — HIGH: Skill-builder pomija sekcję Czego NIE robi

**Kontekst:**  plan rozbudowy fabryki, etap 12 — 2/3 nowych skilli nie mialo sekcji "Czego NIE robi"
(R3 retroaktywny check). Quality-checker blokowal — skill-builder musial wracac i poprawiac.
Wzorzec systemowy: kazdy skill wymaga tej sekcji, brak = BLOCKER.

**Uzasadnienie severity HIGH:** pattern architektoniczny (projektowanie skilli bez checklisty),
powtarzalny (wystapil przy 2 z 3 skilli w jednej sesji), cross-project (kazdy nowy skill jest dotkniety).
Lesson #8 severity HIGH — juz w `lessons.jsonl`, ale wpis w `errors-skill-builder.md` dla lokalnej pamieci.

**Wpis dla:** `errors-skill-builder.md`

```markdown
## 2026-05-07 — Skill-builder pomija sekcje Czego NIE robi w SKILL.md
- **error-summary:** Skill-builder zapisuje SKILL.md bez sekcji "Czego NIE robi" — quality-checker blokuje jako BLOCKER
- **cause-root:** Brak wewnetrznej checklisty sekcji przed finalnym zapisem; skill-design-patterns wymaga tej sekcji ale nie jest sprawdzana automatycznie przed Write
- **prevention:** Przed kazdym zapisem SKILL.md sprawdz czy istnieje sekcja "Czego NIE robi" — uzyj grep: `grep -q "Czego NIE robi" SKILL.md || echo "MISSING SECTION"`
- **severity:** HIGH
- **context:** knowledge-base/plans/2026-05-06-master-rozbudowa-fabryki-9-problemow.md, Lesson #8
<!-- hash: 9b3c5d7e1f2a4b6c8d0e2f4a6b8c0d2e -->
```

---

### Case 3 — MED: Test setup rm -rf usuwa katalog .git

**Kontekst:** Podczas pisania skryptu setup dla testow integracyjnych agenta, komenda
`rm -rf $WORK/.[!.]*` (czyszczenie ukrytych plikow w katalogu roboczym) usunela katalog `.git`
gdy `$WORK` nie byl prawidlowo ustawiony i wskazal na korzen projektu.
Blad jednorazowy, ale memorable — utrata historii git.

**Uzasadnienie severity MED:** blad w obrebbie jednego projektu (setup testow), powtarzalny wzorzec
(wzorzec "glob usuwajacy .git" moze sie powtorzyc przy nastepnych skryptach setup), ale nie cross-project
(specyficzny dla skryptow cleanup w tym projekcie). NIE promotion do lessons.jsonl.

**Wpis dla:** `errors-quality-checker.md` (agent odpowiedzialny za testy)

```markdown
## 2026-05-07 — Test setup rm -rf usuwa katalog .git gdy WORK ustawiony na root
- **error-summary:** Komenda `rm -rf $WORK/.[!.]*` usunela katalog `.git` gdy zmienna WORK wskazywala na root projektu
- **cause-root:** Brak walidacji ze $WORK nie jest rootem projektu przed glob delete; glob `.[!.]*` pasuje do `.git`, `.claude`, `.env`
- **prevention:** Zawsze sprawdz `[[ "$WORK" != "$(git rev-parse --show-toplevel)" ]]` przed rm -rf na ukrytych plikach; uzyj bezpieczniejszego: `find $WORK -maxdepth 1 -name '.[!.]*' ! -name '.git' -delete`
- **severity:** MED
- **context:** setup-test skrypt w .claude/scripts/setup-integration-test.sh
<!-- hash: 2c4e6a8b0d2f4e6a8b0c2d4e6f8a0b2c -->
```

---

### Case 4 — MED: grep -qE z patternem zaczynajacym sie od myslnika

**Kontekst:** Agent uzyl komendy `grep -qE "-pattern" file.md` gdzie wzorzec zaczynal sie
od myslnika `-`. grep interpretowal myslnik jako opcje zamiast wzorzec — komenda
zwracala blad "invalid option". Blad subtilny — trudny do debugowania bo error message
nie wskazuje na przyczyne.

**Uzasadnienie severity MED:** pattern w obrebbie jednego projektu (skrypty bash agenta),
powtarzalny (kazde uzycie grep z dynamicznym patternem moze trafic na ten problem),
ale nie cross-project architecture level. Wart pamietania dla przyszlych skryptow.

**Wpis dla:** `errors-mistake-recorder.md` (agent ktory bedzie uzywac grep intensywnie)

```markdown
## 2026-05-07 — grep -qE z patternem zaczynajacym sie od myslnika traktowany jak opcja
- **error-summary:** `grep -qE "$PATTERN" file` gdzie PATTERN zaczyna sie od `-` powoduje blad "invalid option" zamiast wyszukiwac wzorzec
- **cause-root:** grep interpretuje argument zaczynajacy sie od `-` jako opcje CLI; dynamiczne patterny nie sa zabezpieczone separatorem `--`
- **prevention:** Zawsze uzywaj separatora `--` przed patternem: `grep -qE -- "$PATTERN" file`; alternatywnie: `grep -qE "^${PATTERN}" file` lub `grep -qF -- "$PATTERN" file`
- **severity:** MED
<!-- hash: 7f9b1d3e5a7c9f1b3d5e7a9c1f3b5d7e -->
```

---

### Case 5 — LOW: Agent-architect timeout na slow API request podczas projektu

**Kontekst:** Podczas sesji projektowania agenta, agent-architect czekal na odpowiedz API
przez >60s i skonczylo sie timeoutem. Blad byl spowodowany chwilowa niestabilnoscia
zewnetrznego API — powtorzenie komendy po 30s zadzialalalo normalnie.

**Uzasadnienie severity LOW:** jednorazowy fail (nie powtorzyl sie), niepowtarzalny pattern
(przyczyna = niestabilnosc zewnetrzna), nie systemowy. Nie wymaga promotion ani aggregacji.
Warty pamietania "na wszelki wypadek" ale nie zmienia zachowania agenta.

**Wpis dla:** `errors-agent-architect.md`

```markdown
## 2026-05-07 — Timeout na zewnetrznym API podczas sesji projektowania
- **error-summary:** agent-architect zakonczyl sesje timeoutem (>60s) podczas wywolania zewnetrznego API
- **cause-root:** Chwilowa niestabilnosc zewnetrznego serwisu; powtorzenie po 30s zadzialalalo
- **prevention:** Przy timeout retry po 30s (jednokrotnie); jesli drugi timeout — zglos operatorowi i przerwij sesje
- **severity:** LOW
<!-- hash: 1a3c5e7b9d1f3a5c7e9b1d3f5a7c9e1b -->
```

---

## NIEWALIDNE WPISY

---

### Niewalidny 1 — Brak wymaganego pola severity

**Dlaczego odrzucony:** Brak pola `severity` — pole jest wymagane. `mistake-recorder` odrzuca
z bledem: "missing required field: severity". Bez severity nie mozna wykonac promotion rule
ani okreslic czy wpis trafi do `lessons.jsonl`.

```markdown
## 2026-05-07 — Brak walidacji JSON output
- **error-summary:** Agent zakladal ze LLM zwroci valid JSON bez walidacji formatu
- **cause-root:** Brak try/catch wokol JSON.parse w implementacji agenta
- **prevention:** Waliduj JSON.parse w try/catch zanim przekazesz output do nastepnego kroku
<!-- hash: abc123def456789012345678901234ab -->
```

**Blad:** brak linii `- **severity:** HIGH|MED|LOW`

**Poprawka:** dodaj `- **severity:** MED` przed komentarzem hash.

---

### Niewalidny 2 — Severity poza enum + brak hash

**Dlaczego odrzucony (2 bledy):**
1. `severity: CRITICAL` — poza enum {HIGH, MED, LOW}. Mistake-recorder odrzuca: "invalid severity value: CRITICAL"
2. Brak komentarza `<!-- hash: ... -->` — bez hash idempotency nie dziala; drugi append tego samego bledu zostanie zduplikowany

```markdown
## 2026-05-07 — Timeout na wolnym API endpoint
- **error-summary:** Agent zawieszal sie na timeout podczas debug sesji przez wolny endpoint
- **cause-root:** Zewnetrzne API mialo 99% latency spike w czasie sesji
- **prevention:** Dodaj retry logic z exponential backoff
- **severity:** CRITICAL
```

**Poprawka:**
```markdown
- **severity:** LOW
<!-- hash: <md5-of-normalized-error-summary> -->
```

---

### Niewalidny 3 — Zly naglowek (odwrocona data + myslnik zamiast en-dash)

**Dlaczego odrzucony:** Naglowek nie pasuje do regex `^## (\d{4}-\d{2}-\d{2}) — (.+)$`.
Dwa problemy:
1. Data w formacie `DD-MM-YYYY` zamiast `YYYY-MM-DD` — parser nie rozpozna wpisu
2. Myslnik ASCII `-` zamiast en-dash `—` (U+2013) — separator nie pasuje

Efekt: wpis nie jest parsowany, blok nie jest rozpoznawany jako sekcja `error-memory`.

```markdown
## 07-05-2026 - Problem z parserem
- **error-summary:** Parser nie rozpoznal formatu daty
- **cause-root:** Uzywano formatu DD-MM-YYYY
- **prevention:** Uzywaj ISO-8601 YYYY-MM-DD
- **severity:** LOW
<!-- hash: fed321cba987654321fedcba987654321 -->
```

**Poprawka:**
```markdown
## 2026-05-07 — Parser nie rozpoznaje formatu daty DD-MM-YYYY
```

**Dygresja:** en-dash (`—`) vs myslnik (`-`) — w terminalu: `echo "—"` lub kopiuj z tego pliku.
W bash: `ENDASH=$'\xe2\x80\x94'` (UTF-8 encoding U+2013).

---

## PRZYKLAD ROTATED ARCHIVE

Gdy plik glowny ma >100 wpisow (lub najstarszy >180 dni), mistake-recorder przenosi
najstarsze 25% do `errors-{agent}.archive.md`:

**Fragment `errors-agent-architect.archive.md` po rotacji:**

```markdown
---
<!-- archived: 2026-07-15, entries: 25, from: 2026-01-01, to: 2026-04-01 -->
---

## 2026-01-15 — Architektura bez sekcji Czego NIE robi
- **error-summary:** Agent zaprojektowany bez sekcji "Czego NIE robi" — retroaktywny patch potrzebny
- **cause-root:** Szablon agenta nie mial tej sekcji jako wymaganej
- **prevention:** Dodaj sekcje "Czego NIE robi" do szablonu agenta jako obowiazkowa
- **severity:** HIGH
- **context:** Lesson #3 w knowledge-base/lessons.jsonl
<!-- hash: 0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d -->

## 2026-02-03 — Model routing uzywany bez skilla
...
```

Format archiwum jest identyczny z plikiem aktywnym — te same sekcje, te same regex.
Separator `<!-- archived: ... -->` jest opcjonalny ale pomaga w audycie.
