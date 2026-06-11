# format-spec — error-memory-framework

Pelna specyfikacja formatu pliku `errors-{agent-name}.md`.
Cel: `mistake-recorder` (E3) implementuje producenta BEZ dodatkowych pytan o format.

---

## 1. Naglowek sekcji (wymagany)

```
## YYYY-MM-DD — {short-title}
```

**Regex parsujacy:**
```
^## (\d{4}-\d{2}-\d{2}) — (.+)$
```

| Element | Wymagania |
|---|---|
| `YYYY-MM-DD` | ISO-8601, data zapisu (nie data wystapienia bledu jesli rozna) |
| ` — ` | Separator: spacja + en-dash (U+2013) + spacja. NIE myslnik ASCII `-`. |
| `{short-title}` | 3-10 slow, distinctive. Zakazane: "Error", "Bug", "Problem", "Failed" jako jedyne slowo |

**Prawidlowy naglowek:**
```
## 2026-05-07 — Agent wywoluje docker compose config mimo blokady hooka
```

**Nieprawidlowy naglowek:**
```
## 2026-05-07 - Error in agent        <- myslnik zamiast en-dash, generic title
## 05-07-2026 — Format bledu          <- odwrocona data
## 2026-05-07 — Error                 <- generic single-word title
```

---

## 2. Wymagane pola (4)

Format kazdego pola: `- **{field-name}:** {value}` — bullet list, bold label, dwukropek, spacja, wartosc.

**Regex parsujacy pole:**
```
^- \*\*(\w+(?:-\w+)*):\*\* (.+)$
```

### 2.1 `error-summary`

```
- **error-summary:** Krotki opis bledu (1 linia, max 200 znakow)
```

- 1 linia (bez newline w wartosci)
- Distinctive: opisuje KONKRETNY blad, nie klase
- Uzywany do obliczenia hash idempotency
- Zakazane jako cala wartosc: "Error", "Failed", "Bug", "Exception", "Blad"

### 2.2 `cause-root`

```
- **cause-root:** Dlaczego sie zdarzylo. Moze byc wieloliniowe z kontynuacja przez wciec.
```

- 1-3 linie (jesli wieloliniowe — kontynuacja przez 2-spacyjny indent, ale parser obsluguje tylko 1 linie per pole — rozdziel srednikiem)
- Odpowiada na pytanie "dlaczego", nie "co"
- Przyklad: "Agent zakladal ze LLM zwroci valid JSON bez walidacji; brak try/catch w implementacji"

### 2.3 `prevention`

```
- **prevention:** Konkretny action item — co zrobic inaczej nastepnym razem
```

- 1 linia
- Action item, nie diagnoza (zaczyna sie od czasownika lub "Zawsze/Nigdy/Waliduj/Sprawdz")
- Przyklad: "Waliduj JSON.parse w try/catch zanim przekazesz output do nastepnego kroku"

### 2.4 `severity`

```
- **severity:** HIGH
```

- Enum: `HIGH` | `MED` | `LOW` (wielkie litery, bez cudzysłowow)
- Kazda inna wartosc = invalid entry (mistake-recorder odrzuca)

---

## 3. Pole opcjonalne

### 3.1 `context`

```
- **context:** link do reflection / commit / issue / innego wpisu
```

- Opcjonalne — pomiń gdy brak referencji
- Przyklad wartosci:
  - `.claude/knowledge-base/reflections/2026-05-06-secrets-handling-skill.md`
  - `commit: a1b2c3d`
  - `poprzedni wpis: 2026-04-15 — Agent wywoluje docker compose config`
  - `issue: github.com/LogicMorrow/agent-factory/issues/42`

---

## 4. Idempotency hash

**Komentarz HTML na koncu sekcji wpisu** (po ostatnim polu, przed nastepna sekcja `##`):

```html
<!-- hash: a1b2c3d4e5f6789012345678901234ab -->
```

- MD5 z `error-summary` po normalizacji: lowercase + trim + collapse whitespace
- 32 znaki hex (standardowy MD5)
- Parsowanie przez `grep`: `grep -oP '(?<=<!-- hash: )[a-f0-9]{32}(?= -->)'`

**Algorytm normalizacji:**
```bash
NORMALIZED=$(echo "$error_summary" | tr '[:upper:]' '[:lower:]' | xargs | tr -s ' ')
HASH=$(echo -n "$NORMALIZED" | md5sum | cut -d' ' -f1)
```

**Przed kazdym appendem mistake-recorder sprawdza:**
```bash
grep -q "<!-- hash: $HASH -->" "errors-${agent}.md" && echo "NOOP" && exit 0
```

---

## 5. Pelny szablon wpisu

```markdown
## 2026-05-07 — {Distinctive short title describing the specific error}
- **error-summary:** Krotki, distinctive opis bledu (1 linia, max 200 znakow)
- **cause-root:** Dlaczego sie zdarzylo; jesli wiecej przyczyn rozdziel srednikiem
- **prevention:** Konkretny action item zaczynajacy sie od czasownika
- **severity:** HIGH
- **context:** (usun linie jesli brak kontekstu)
<!-- hash: 00000000000000000000000000000000 -->
```

---

## 6. Przyklad walidnego wpisu

```markdown
## 2026-05-06 — Agent wywoluje docker compose config mimo blokady hooka
- **error-summary:** Agent wywoluje `docker compose config` mimo aktywnego hooka block-env-leak.sh
- **cause-root:** Agent nie zaladowal skilla secrets-handling przed planowaniem komendy; hook zablokował ale agent ponowil probe
- **prevention:** Zawsze sprawdz czy hook block-env-leak.sh jest aktywny i uzywaj `docker compose config --no-interpolate`
- **severity:** HIGH
- **context:** .claude/knowledge-base/reflections/2026-05-06-secrets-handling-skill.md
<!-- hash: 3d7f2a8b1c9e4f5a6b0c2d3e4f5a6b7c -->
```

---

## 7. Przyklad niewalidnych wpisow

### 7.1 Brak wymaganego pola `severity`

```markdown
## 2026-05-07 — Brak walidacji JSON output
- **error-summary:** Agent zakladal ze LLM zwroci valid JSON
- **cause-root:** Brak try/catch
- **prevention:** Waliduj JSON.parse
<!-- hash: abc123... -->
```

**Blad:** brak pola `severity` → invalid entry → mistake-recorder odrzuca z bledem "missing required field: severity".

### 7.2 Severity poza enum

```markdown
## 2026-05-07 — Timeout na API
- **error-summary:** Agent timeoutal na wolnym endpoint
- **cause-root:** Siec byla wolna
- **prevention:** Dodaj retry
- **severity:** CRITICAL
<!-- hash: def456... -->
```

**Blad:** `severity: CRITICAL` poza enum {HIGH, MED, LOW} → invalid → odrzuc.

### 7.3 Nieprawidlowy naglowek

```markdown
## 07-05-2026 - Error
- **error-summary:** Cos sie stalo
- **severity:** LOW
```

**Bledy (3):** odwrocona data, myslnik ASCII zamiast en-dash, generic title, brak hash.

---

## 8. Severity escalation pattern

Blad zapisany jako MED moze z czasem okazac sie HIGH (np. pojawia sie w kolejnych projektach).

**Zasada immutable log:** NIE modyfikuj istniejacego wpisu — to narusza idempotency i traceability.

**Postepowanie przy eskalacji severity:**
1. Dodaj nowy wpis z wyzszym severity
2. W `context:` nowego wpisu zawrzyj date i title poprzedniego
3. Poprzedni wpis pozostaje bez zmian

```markdown
## 2026-05-20 — Agent wywoluje docker compose config mimo blokady hooka (eskalacja)
- **error-summary:** Agent wywoluje docker compose config mimo blokady hooka — wzorzec cross-project
- **cause-root:** Wykryto ten sam pattern w projekcie CRM i fabryce; nie jest to blad jednego projektu
- **prevention:** Zawsze sprawdz secrets-handling skill przed planowaniem komend docker compose
- **severity:** HIGH
- **context:** poprzedni wpis: 2026-05-06 — Agent wywoluje docker compose config mimo blokady hooka (MED)
<!-- hash: <nowy-hash-z-roznego-summary> -->
```

**Uwaga:** nowy wpis ma INNE `error-summary` (dodano "(eskalacja)" lub zmieniono opis) → inny hash → nie jest duplikatem.

---

## 9. Cleanup archive format

Po rotacji (>100 wpisow LUB >180 dni) najstarsze 25% trafia do `errors-{agent}.archive.md`.

**Format archiwum:** identyczny z plikiem aktywnym — te same sekcje `## YYYY-MM-DD — {title}`.
Mozna odczytac te same regex'ami. Brak dodatkowego nagłowka ani metadanych archiwum.

**Separator archiwum** (opcjonalny — dodawany przez mistake-recorder przy kazdej rotacji):

```markdown
---
<!-- archived: 2026-07-15, entries: 25, from: 2026-01-01, to: 2026-04-15 -->
---
```

---

## 10. Path validation rules

Przed kazdym Write `mistake-recorder` sprawdza sciezke:

```bash
TARGET_DIR=$(dirname "$target_path")
REALPATH=$(realpath "$target_path" 2>/dev/null)

# Check 1: katalog musi byc .claude/memory/
echo "$REALPATH" | grep -q '/.claude/memory/' || { echo "REJECT: path outside allowlist"; exit 1; }

# Check 2: nazwa pliku musi pasowac do wzorca
basename "$target_path" | grep -qE '^errors-[a-z0-9-]+\.(md|archive\.md)$' || { echo "REJECT: invalid filename pattern"; exit 1; }

# Check 3: nie wolno pisac do lessons.jsonl przez Write (tylko append przez osobna akcje)
echo "$target_path" | grep -q 'lessons.jsonl' && { echo "REJECT: use promotion action, not direct Write"; exit 1; }
```

---

## 11. Parsing reference (pelne regex)

| Element | Regex |
|---|---|
| Naglowek sekcji | `^## (\d{4}-\d{2}-\d{2}) — (.+)$` |
| Pole wymagane/opcjonalne | `^- \*\*(\w+(?:-\w+)*):\*\* (.+)$` |
| Hash komentarz | `<!-- hash: ([a-f0-9]{32}) -->` |
| Separator archiwum | `<!-- archived: (\d{4}-\d{2}-\d{2}), entries: (\d+), .*-->` |
| Severity enum check | `^(HIGH\|MED\|LOW)$` |

**Sprawdzenie liczby wpisow:**
```bash
grep -c '^## [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} — ' "errors-${agent}.md"
```

**Wydobycie najstarszej daty:**
```bash
grep -oP '(?<=^## )\d{4}-\d{2}-\d{2}' "errors-${agent}.md" | sort | head -1
```

---

## 12. Walidacja wpisu — checklist dla mistake-recorder

Przed appendem nowego wpisu sprawdz w kolejnosci:

- [ ] Sciezka docelowa w allowlist (sekcja 10)
- [ ] Hash MD5 nie istnieje w pliku (idempotency, sekcja 4)
- [ ] Naglowek pasuje do regex (sekcja 1)
- [ ] Pole `error-summary` istnieje i jest distinctive (sekcja 2.1)
- [ ] Pole `cause-root` istnieje (sekcja 2.2)
- [ ] Pole `prevention` istnieje (sekcja 2.3)
- [ ] Pole `severity` istnieje i jest HIGH|MED|LOW (sekcja 2.4)
- [ ] Cleanup check (sekcja 7 SKILL.md) — rotuj jesli potrzeba PRZED appendem
- [ ] Jesli severity=HIGH → append do `lessons.jsonl` (sekcja 5 SKILL.md)
