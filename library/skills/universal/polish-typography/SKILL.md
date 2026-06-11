---
name: polish-typography
description: "Wzorce poprawnej polskiej typografii i interpunkcji — szerszy niż polish-language-seo (które jest tylko o SEO). Reguły: nbsp przed jednoznakowymi (a/i/o/u/w/z), cudzysłowy „...”, półpauza — vs dywiz - vs minus −, daty/liczebniki/jednostki z nbsp, top 30 typowych błędów (z stała się / po przez / co raz). Konsumowany przez polish-proofreader, portfolio-content-writer, seo-content-writer, tech-doc-writer. NIE używać do SEO-specific (URL slugi, polskie katalogi → polish-language-seo)."
version: 1.0.0
compatible_with: [universal, webapp, ai-agents]
tags: [typography, language, polish, pl, content, proofreading]
requires: []
token_cost: low
distribution: library/skills/universal/
last_updated: 2026-05-13
---

# polish-typography

Wiedza referencyjna o poprawnej polskiej typografii i interpunkcji dla tekstów portfolio, blogów, dokumentacji i UI copy. Komplementarny z `polish-language-seo` (SEO domain), tu: **content quality + lint**.

**Bundle pliki:**
- `SKILL.md` — reguły referencyjne (ten plik)
- `common-errors.md` — top 30 typowych błędów PL z poprawkami
- `regex-patterns.json` — patterns dla agenta `polish-proofreader` (lint heuristics)

## When to use this skill

Uruchamiaj gdy:
- `portfolio-content-writer` generuje copy w MDX (E6 plan paczki portfolio)
- `polish-proofreader` lintuje plik .md/.mdx/.tsx (E5)
- `seo-content-writer` pisze blog post PL ( paczki SEO — patch v1.1 z requires `polish-typography`)
- `tech-doc-writer` generuje README/runbook po polsku
- operator manualnie sprawdza tekst przed publikacją

## Pre-execution context loading (per cross-agent-learning skill)

Agent konsumujący ten skill MA czytać przed startem:
- `.claude/memory/errors-{agent-name}.md` (jeśli istnieje)
- `lessons.jsonl` tail 20 filtered `tag:polish-typography`
- `reflections/` last 3 zawierające `polish-typography`

## Reguły podstawowe

### 1. Nbsp (` `, w MDX: `&nbsp;`) przed jednoznakowymi spójnikami i przyimkami

**Zasada:** jednoznakowy spójnik/przyimek nie może zostać na końcu wiersza. Wstaw nbsp.

**Lista jednoznakowych do zabezpieczenia:**
- Spójniki: `a`, `i`, `o`, `u`, `w`, `z`
- Czasem: `że` (rzadko jednowyrazowo na końcu wiersza, ale dla pewności)

**Przykłady:**
```
ŹLE:  Zajmuję się analityką i sprzedażą B2B oraz
      AI engineeringiem.
DOBRZE: Zajmuję się analityką i&nbsp;sprzedażą B2B
        oraz AI&nbsp;engineeringiem.

ŹLE:  Współpraca z [client] przyniosła wzrost o
      30%.
DOBRZE: Współpraca z&nbsp;[client] przyniosła wzrost
        o&nbsp;30%.
```

**W MDX/React:** używaj `&nbsp;` lub `{' '}` (NIE zwykła spacja).
**W kontekście code/className:** IGNORUJ — to nie tekst do czytania.

### 2. Cudzysłowy — drukarskie „…", NIE proste "…"

**Zasada:** w polskim tekście używamy cudzysłowów drukarskich `„…”` (`„…”`).

**Przykłady:**
```
ŹLE:  operator nazywa to "hybrydą AI + sprzedaży".
DOBRZE: operator nazywa to „hybrydą AI + sprzedaży”.

ŹLE:  'agentów AI'
DOBRZE: „agentów AI"
```

**Cudzysłowy zagnieżdżone:** `«…»` lub `'...'` (apostrofy) wewnątrz `„…"`.

**Wyjątek:** w kodzie (JS strings, JSON), nazwach plików, URL — pozostaw `"` lub `'`.

### 3. Półpauza `—`, dywiz `-`, minus `−`

Trzy różne znaki, trzy różne funkcje.

| Znak | Unicode | Użycie |
|---|---|---|
| **Dywiz** `-` | U+002D | Wyrazy złożone: `polsko-angielski`, `social-media`, `cold-mailing`. Bez spacji. |
| **Półpauza** `—` | U+2014 | Wtrącenia, listy, dialog: `Portfolio — wizytówka pracy`. Ze spacjami z obu stron. |
| **Minus** `−` | U+2212 | Matematyka, ujemne wartości: `−5°C`, `−30%`. Używaj rzadko. |

**Przykłady:**
```
ŹLE:  AI engineer - analityk - sprzedaż B2B.
DOBRZE: AI engineer — analityk — sprzedaż B2B.

ŹLE:  Polsko - angielski tłumacz.
DOBRZE: Polsko-angielski tłumacz.

ŹLE:  Temperatura -5 stopni.
DOBRZE (PL): Temperatura −5 stopni. (lub: minus 5 stopni)
```

### 4. Liczby, jednostki, procenty — nbsp przed jednostką

```
ŹLE:  5%, 100zł, 30km, 2GB
DOBRZE: 5&nbsp;%, 100&nbsp;zł, 30&nbsp;km, 2&nbsp;GB
```

**Wyjątek:** stopnie temperatury (`5°C`, `−10°C`) — bez spacji.

### 5. Daty po polsku

```
ŹLE:  13. maja 2026 roku
DOBRZE: 13 maja 2026 roku

ŹLE:  W roku 2026 zacząłem...
DOBRZE: W 2026 roku zacząłem... (kolokacja PL)

ŹLE:  od 2026/05/13 do 2026/05/20
DOBRZE: od 13 maja do 20 maja 2026 r. (lub: 13–20 maja 2026)
```

### 6. Skróty — z kropką, mała litera kolejna

```
DOBRZE: np. analityka danych, tj. SQL, itd.
ŹLE:   Np. analityka, Tj. SQL (duża litera po kropce skrótu)
```

**Lista popularnych:** `np.`, `tj.`, `itd.`, `itp.`, `m.in.`, `pn.`, `wt.`, `tzw.`, `tzn.`

### 7. Wielkie litery w tytułach — styl zdaniowy

PL nie używa "Title Case" jak EN. Tytuł = jak zdanie: pierwsze słowo + nazwy własne.

```
EN: How I Built My Portfolio
PL ŹLE: Jak Zbudowałem Swoje Portfolio
PL DOBRZE: Jak zbudowałem swoje portfolio
```

### 8. Przecinki — przed spójnikami podrzędnymi

```
DOBRZE: Wiem, że to działa. (przecinek przed "że")
DOBRZE: Robię to, ponieważ lubię. (przecinek przed "ponieważ")
ŹLE:   Wiem że to działa.

DOBRZE: Współpracuję z firmami w Polsce i za granicą.
       (BEZ przecinka przed "i" — łączy równorzędne)
```

**Klocek "Mimo że":** BEZ przecinka między, BEZ "po".
```
ŹLE:  Pomimo, że pracuję sam, dostarczam projekty.
ŹLE:  Pomimo że pracuję sam, dostarczam projekty.
DOBRZE: Mimo że pracuję sam, dostarczam projekty.
```

### 9. Wyliczenia — kropka, średnik lub przecinek?

- **Krótkie wyliczenia (1-3 słowa)** → przecinek, ostatnie z "i" lub "oraz".
- **Długie wyliczenia (>3 słowa, zdania)** → średnik między, kropka na końcu listy.
- **Lista bulletów** → na końcu każdego punktu kropka jeśli pełne zdanie; bez kropki jeśli noun phrase.

### 10. Apostrofy w nazwach obcych

```
DOBRZE: operatora z LogicMorrow → operatora z&nbsp;LogicMorrow
DOBRZE: Google'a, Facebook'a (apostrof prosty ' przed końcówką PL deklinacji)
ŹLE:   Googlea, Facebooka (bez apostrofu — czytanie błędne)
```

**Wyjątek:** spolszczone nazwy bez apostrofu: `Microsoft`, `IBM`, `Amazon` zwykle z polskimi końcówkami bez apostrofu (`Microsoftem`, `IBM-u`, `Amazonem`).

## Lista whitelisted terms (dla portfolio operatora / AI domain)

Słowa angielskie NIE wymagają poprawy — domena:
- `prompt`, `LLM`, `embedding`, `agent`, `workflow`, `API`, `tool`, `function calling`, `RAG`, `fine-tuning`, `inference`, `token`, `context`, `MCP`, `Claude`, `GPT`, `Sonnet`, `Opus`, `Haiku`
- `freelance`, `freelancing`, `cold mailing`, `B2B`, `outreach`, `pipeline`, `lead-gen`
- `analytics`, `dashboard`, `SQL`, `Python`, `pandas`, `notebook`, `ETL`, `BI`
- Frameworks: `Next.js`, `React`, `Tailwind`, `TypeScript`, `Framer Motion`, `Vercel`
- Marki: `LogicMorrow`, `Anthropic`, `OpenAI`, `LinkedIn`, `GitHub`, `X` (Twitter)

**Konsekwencja:** `polish-proofreader` NIE flaguje tych słów jako "nieznane".

## Whitelisted scope (gdzie NIE lintować)

- Code blocks ` ``` ... ``` `
- Inline code `` ` ... ` ``
- `className="..."` w JSX/TSX
- `<code>...</code>` w MDX/HTML
- Frontmatter YAML (klucze techniczne)
- URL, ścieżki plików
- Komentarze techniczne w plikach .ts/.tsx (`// ...`, `/* ... */`)

## Przykład full-paragraph (idiomatyczny PL)

**ŹLE (przed proofread):**
> Buduję portfolio jako wizytówkę pracy - chcę pokazać 4 obszary: analitykę danych, sprzedaż b2b z cold mailingiem, inżynierię AI (agenty CC + agenty LLM) oraz generowanie grafiki/wideo AI. To powstaje po to żeby pracodawcy i klienci freelance widzieli kim jestem i co robię w jednym miejscu.

**DOBRZE (po proofread):**
> Buduję portfolio jako wizytówkę pracy&nbsp;— chcę pokazać cztery obszary: analitykę danych, sprzedaż B2B z&nbsp;cold mailingiem, inżynierię AI (agenty CC + agenty LLM) oraz generowanie grafiki i&nbsp;wideo AI. Portfolio powstaje po to, żeby pracodawcy i&nbsp;klienci freelance widzieli, kim jestem i&nbsp;co robię, w&nbsp;jednym miejscu.

**Zmiany:**
1. `pracy - chcę` → `pracy&nbsp;— chcę` (półpauza zamiast dywizu + nbsp)
2. `4 obszary` → `cztery obszary` (liczby ≤10 słownie w narracji)
3. `b2b` → `B2B` (akronim wielkimi)
4. `z cold` → `z&nbsp;cold` (nbsp po jednoznakowym z)
5. `i wideo` → `i&nbsp;wideo` (nbsp po i)
6. `po to żeby` → `po to, żeby` (przecinek przed żeby)
7. `widzieli kim` → `widzieli, kim` (przecinek przed zdaniem podrzędnym)
8. `co robię` → `co robię,` (przecinek między zdaniami współrzędnymi)
9. `w jednym` → `w&nbsp;jednym` (nbsp po w)
10. `To powstaje` → `Portfolio powstaje` (jasna referencja zamiast zaimka)

## Procedury (use case)

### Procedura A: lint pojedynczego pliku

1. Agent `polish-proofreader` czyta plik
2. Ekstrakcja tekstu (omiń whitelisted scope — code, className)
3. Aplikuj `regex-patterns.json` (sekcja `common-errors`)
4. Sprawdź whitelist (AI terms NIE flag)
5. Wygeneruj report `proofreading-reports/<date>-<basename>.md` z propozycjami `line:col | issue | suggested fix | confidence`
6. **HITL gate:** operator approve każdej zmiany przed apply

### Procedura B: pre-publish audit

Przed deploy portfolio:
1. `polish-proofreader --path=portfolio/content/**/*.mdx --all`
2. Manualny review reportu
3. Apply zmian + commit
4. Hook `validate-pl-typography.sh` (PostToolUse Write) — warning non-blocking jeśli regress

## Czego skill NIE robi

- **Nie sprawdza fleksji per case** — to robi `polish-language-seo/fleksja-examples.md` (deklinacja keywords)
- **Nie sprawdza składni gramatycznej (kolokacji rzadkich)** — wymaga LLM judgment, nie regex. Agent `polish-proofreader` może oznaczyć HIGH-confidence kolokacji, ale nie wszystkie.
- **Nie tłumaczy** — to nie translator, tylko polish quality.
- **Nie generuje contentu** — to robi `portfolio-content-writer` (E6) lub `seo-content-writer`.

## Referencje

- Edward Polański (red.) — *Wielki słownik ortograficzny PWN*
- Jan Miodek — *Słownik ojczyzny polszczyzny*
- *Polskie zasady pisowni* — sjp.pwn.pl/zasady
- Witold Mańczak — *Polska fonetyka i morfologia historyczna*
- (Internet) sjp.pwn.pl, poradnia językowa PWN, korpus.pl

## Status

v1.0.0 (2026-05-13) — initial release dla paczki `af-pack-<nazwa>` (E1 plan `2026-05-13-paczka-portfolio-operator.md`).
