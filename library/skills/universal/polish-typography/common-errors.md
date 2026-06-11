# common-errors.md — top 30 typowych błędów PL

Lista najczęstszych błędów typograficznych i językowych w polskim tekście portfolio / blog / docs. Każdy wpis: **ŹLE → DOBRZE → uzasadnienie**.

Konsumowany przez `polish-proofreader` (E5 paczki portfolio) jako reference. Regex-y dla automatycznej detekcji w `regex-patterns.json`.

## Sekcja A: błędy ortograficzne / literówki

### 1. "z stała się" → "się stała"
```
ŹLE:  Sprzedaż z stała się moją pasją.
DOBRZE: Sprzedaż stała się moją pasją.
```
**Powód:** "z" niepotrzebne. Forma to `stała się` (perf), nie `z stała się`.

### 2. "po przez" → "poprzez"
```
ŹLE:  Komunikuję się po przez cold mailing.
DOBRZE: Komunikuję się poprzez cold mailing.
```
**Powód:** `poprzez` to jeden wyraz (przyimek złożony).

### 3. "co raz" → "coraz"
```
ŹLE:  Co raz więcej firm używa AI.
DOBRZE: Coraz więcej firm używa AI.
```
**Powód:** `coraz` to przysłówek stopniujący, jeden wyraz.

### 4. "na pewno" → poprawne (NIE "napewno")
```
ŹLE:  Napewno warto spróbować.
DOBRZE: Na pewno warto spróbować.
```
**Powód:** `na pewno` to dwa wyrazy, zawsze osobno.

### 5. "w ogóle" → poprawne (NIE "wogóle")
```
ŹLE:  Wogóle nie korzystam z CRM.
DOBRZE: W ogóle nie korzystam z CRM.
```

### 6. "naprawdę" → poprawne (NIE "na prawdę")
```
ŹLE:  Na prawdę polecam Claude'a.
DOBRZE: Naprawdę polecam Claude'a.
```
**Powód:** `naprawdę` (przysłówek) ≠ `na prawdę` (przyimek + rzeczownik, "trafić na prawdę").

### 7. "tym bardziej, że" — przecinek
```
ŹLE:  Polecam tym bardziej że to działa.
DOBRZE: Polecam, tym bardziej że to działa.
```

## Sekcja B: błędy interpunkcyjne

### 8. Przecinek przed "że", "który", "aby", "ponieważ", "jeśli"

```
ŹLE:  Wiem że to działa.
DOBRZE: Wiem, że to działa.

ŹLE:  Klient który mnie zatrudnił był zadowolony.
DOBRZE: Klient, który mnie zatrudnił, był zadowolony.

ŹLE:  Robię to aby pomóc.
DOBRZE: Robię to, aby pomóc.

ŹLE:  Działa ponieważ jest proste.
DOBRZE: Działa, ponieważ jest proste.

ŹLE:  Jeśli zechcesz odezwij się.
DOBRZE: Jeśli zechcesz, odezwij się.
```

### 9. Brak przecinka przed "i", "oraz", "lub" (gdy łączą równorzędne)
```
ŹLE:  Buduję agenty, i pisze copy.
DOBRZE: Buduję agenty i piszę copy.

ŹLE:  Cold mailing, lub social selling.
DOBRZE: Cold mailing lub social selling.
```
**Wyjątek:** gdy "i" oddziela zdania (każde ma swoje orzeczenie i podmiot), przecinek BYWA.

### 10. "Mimo że" — bez przecinka i bez "po"
```
ŹLE:  Pomimo, że pracuję sam, dostarczam.
ŹLE:  Pomimo że pracuję sam, dostarczam.
DOBRZE: Mimo że pracuję sam, dostarczam.
```

### 11. Cudzysłowy — drukarskie „…", NIE proste "…"
```
ŹLE:  operator mówi "to działa".
DOBRZE: operator mówi „to działa".
```

## Sekcja C: błędy typograficzne (znaki)

### 12. Półpauza w wtrąceniach (ze spacjami)
```
ŹLE:  AI engineer - analityk - sprzedaż.
DOBRZE: AI engineer — analityk — sprzedaż.
```

### 13. Dywiz w złożeniach (bez spacji)
```
ŹLE:  Polsko - angielski tłumacz.
DOBRZE: Polsko-angielski tłumacz.
```

### 14. Nbsp przed jednoznakowymi (a, i, o, u, w, z)
```
ŹLE:  Pracuję z firmami z Polski i z zagranicy.
DOBRZE: Pracuję z&nbsp;firmami z&nbsp;Polski i&nbsp;z&nbsp;zagranicy.
```

### 15. Nbsp przed jednostką
```
ŹLE:  Wzrost o 30%, koszt 100zł, ETA 5 min.
DOBRZE: Wzrost o&nbsp;30&nbsp;%, koszt 100&nbsp;zł, ETA 5&nbsp;min.
```

### 16. Trzy kropki — wielokropek …
```
ŹLE:  Działa świetnie...
DOBRZE: Działa świetnie… (jeden znak …, Unicode U+2026)
```

## Sekcja D: błędy językowe / styl

### 17. "celem X" → "aby X" / "żeby X"
```
ŹLE:  Celem zwiększenia konwersji wdrożyłem A/B test.
DOBRZE: Aby zwiększyć konwersję, wdrożyłem A/B test.
```
**Powód:** kalka z urzędniczego stylu.

### 18. "dokonać X-u" → użyj czasownika
```
ŹLE:  Dokonałem analizy lejka sprzedażowego.
DOBRZE: Przeanalizowałem lejek sprzedażowy.
```

### 19. "ilość" vs "liczba"
```
ŹLE:  Ilość klientów wzrosła.
DOBRZE: Liczba klientów wzrosła.
```
**Reguła:** `liczba` dla policzalnych, `ilość` dla niepoliczalnych (`ilość wody`, `ilość czasu`).

### 20. "w roku 2026" → "w 2026 roku"
```
ŹLE:  W roku 2026 zacząłem freelance.
DOBRZE: W 2026 roku zacząłem freelance.
```
**Powód:** standardowa kolokacja PL.

### 21. "ze względu na" / "z powodu" — overuse
```
ŹLE:  Ze względu na fakt, że klienci wymagają...
DOBRZE: Klienci wymagają... (lub: Ponieważ klienci wymagają...)
```

### 22. "tudzież", "albowiem", "atoli" — archaizmy
```
ŹLE:  Buduję agenty AI tudzież piszę copy.
DOBRZE: Buduję agenty AI oraz piszę copy.
```

### 23. "spożytkować" → "wykorzystać"
```
ŹLE:  Spożytkowałem wiedzę z analityki.
DOBRZE: Wykorzystałem wiedzę z analityki.
```

### 24. "natomiast" — overuse zamiast "i", "ale"
```
ŹLE:  Pracuję sam, natomiast skaluję narzędziami AI.
DOBRZE: Pracuję sam, ale skaluję narzędziami AI.
```
**Reguła:** `natomiast` = formalne kontrastowanie. Używaj rzadko.

### 25. Powtórzenia zaimków ("to", "który", "więc")
```
ŹLE:  Portfolio to projekt który pokazuje to co robię. To więc moja wizytówka.
DOBRZE: Portfolio pokazuje, czym się zajmuję. To moja wizytówka.
```

## Sekcja E: błędy formatowania (MDX/HTML specific)

### 26. Kropka po nagłówku
```
ŹLE:  ## Co robię.
DOBRZE: ## Co robię
```
**Reguła:** nagłówki bez kropki na końcu.

### 27. Wielka litera w listach (bullet points)
```
DOBRZE (zdania pełne, z kropką na końcu):
- Buduję agentów AI.
- Piszę cold maile.
- Analizuję dane.

DOBRZE (frazy bez kropek):
- agenty AI
- cold mailing
- analityka danych

ŹLE (mieszane):
- Buduję agentów.
- cold mailing
- analizuję dane
```

### 28. Tabele — wielka litera w headerach
```
DOBRZE: | Obszar | Tools | Outcome |
ŹLE:    | obszar | tools | outcome |
```

## Sekcja F: błędy "false friends" PL-EN

### 29. "ewentualnie" ≠ "eventually"
```
PL "ewentualnie" = EN "possibly"
EN "eventually" = PL "ostatecznie", "w końcu"

ŹLE (z kalki):  Ewentualnie wdrożymy to w produkcji.
                (intencja: "w końcu", ale PL czyta "may be")
DOBRZE: Ostatecznie wdrożymy to w produkcji.
```

### 30. "kontrolować" ≠ "to control"
```
PL "kontrolować" = sprawdzać (audit)
EN "to control" = PL "sterować", "zarządzać"

ŹLE:  Kontroluję jakość kodu. (jeśli intencja: zarządzam)
DOBRZE: Zarządzam jakością kodu. (lub: Sprawdzam jakość kodu — jeśli audit)
```

## Sekcja G: dodatkowe wskazówki dla portfolio (operator-specific)

- **Akronimy:** `B2B`, `AI`, `LLM`, `CC` (Claude Code), `MCP`, `API` — wielkimi literami, bez kropek między.
- **Nazwa "Claude Code"** — z wielkiej, NIE "claude code". Skrót `CC` ok w kontekście tech.
- **"agenty AI" vs "agenci AI"** — oba poprawne, ale `agenty` (nijaki) konsekwentnie w jednym tekście.
- **"freelancing" / "freelance"** — anglicyzm, OK w domenie. NIE tłumacz na "wolny strzelec" (corporate-speak).
- **"cold mailing"** — anglicyzm zaakceptowany. Alternatywy: `pozyskiwanie B2B przez email`, `outreach mailowy`.
- **"hobby"** — pisz w cudzysłowach „hobby" w pierwszym wystąpieniu jeśli sekcja, potem bez.

## Procedura użycia common-errors.md

Agent `polish-proofreader`:
1. Parse plik input
2. Dla każdej sekcji A-F apply regex z `regex-patterns.json`
3. Match → propozycja `original | suggested | rule_id | confidence`
4. Whitelist: skip jeśli wewnątrz code block / className / inline code
5. Confidence:
   - **HIGH (95%+):** sekcja A, B, F (jednoznaczne błędy)
   - **MEDIUM (70-90%):** sekcja C, E (typografia — może być intencjonalne)
   - **LOW (50-70%):** sekcja D (styl — subiektywne)
6. Output: `proofreading-reports/<date>-<basename>.md` z `line:col | rule_id | original | suggested | confidence`

## Status

v1.0.0 (2026-05-13) — initial 30 błędów. Update kwartalnie z lessons.jsonl tag:polish-typography.
