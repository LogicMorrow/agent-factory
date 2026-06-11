---
name: polish-language-seo
description: PL-specific SEO — fleksja w keyword research (7 przypadków × liczba × rodzaj), polskie SERP behavior, top 16+ PL katalogów biznesowych (OLX, Allegro, Otodom, Aleo, Panorama Firm, Oferia, MuratorPlus etc.), stop words PL, transliteration ąęłńóśźż → ASCII URL slugs. Konsumowany przez seo-strategist, seo-content-writer, local-seo-specialist, competitor-watcher.
version: 1.0.0
compatible_with: [universal]
tags: [seo, language, polish, pl]
requires: [seo-fundamentals]
token_cost: medium
distribution: library/skills/universal/
last_updated: 2026-05-11
---

# polish-language-seo

Wiedza PL-specyficzna dla SEO — jak język polski wpływa na keyword research, URL slug, content, katalogi lokalne i zachowanie użytkownika PL w SERP. Nadbudowa nad `seo-fundamentals` (meta, schema, sitemap — JEST TAM). Tu: LANGUAGE — fleksja, transliteration, polskie narzędzia, katalogi PL.

**Bundle pliki:**
- `SKILL.md` — wiedza referencyjna (ten plik)
- `polish-catalogs.json` — 16+ katalogów PL z metadanymi (URL, audience, NAP fields, priorytet)
- `fleksja-examples.md` — pełna deklinacja 15 słów branży budowlanej (singular + plural × 7 przypadków)

**Prerequisite:** `seo-fundamentals` wdrożone. Bez bazowego fundamentu (meta, sitemap, robots) PL-optymalizacja nie daje pełnego efektu.

## When to use this skill

Uruchamiaj gdy:
- `seo-strategist` robi keyword research na projekcie PL (aggregacja wariantów fleksyjnych)
- `seo-content-writer` generuje URL slug per artykuł (transliteration + stop words)
- `seo-auditor` ocenia czy konkurent używa fleksji efektywnie
- `local-seo-specialist` planuje citation building (które PL katalogi mają priorytet HIGH)
- `competitor-watcher` monitoruje ranking PL i widzi query z wariantami fleksyjnymi

NIE uruchamiaj gdy:
- Brakuje meta tagów, sitemapy, robots.txt → `seo-fundamentals`
- Potrzebujesz Google Business Profile krok po kroku, NAP consistency, GEO → `regional-seo-poland` (E4)
- Planujesz content strategy, pełen style guide PL, brand voice → `content-strategy-construction` (5B)
- Szukasz topical clusters, E-E-A-T, CWV optimization → `seo-advanced`

---

## 1. Fleksja PL w keyword research

Język polski ma **7 przypadków × 2 liczby × 3 rodzaje = do 42 form gramatycznych** jednego słowa. Narzędzia SEO en-US traktują każdą formę jako oddzielny keyword — to zawyża volume fragmentacji.

### Zasada aggregacji

**"Treat all fleksja variants as one keyword cluster — sum volumes, primary = singular nominative."**

Przykład: "fundament" + "fundamentu" + "fundamentem" + "fundamenty" + "fundamentów" + ... = jeden cluster "fundament*" z sumą volume.

### Narzędzia keyword research dla PL (ranking skuteczności)

| Narzędzie | Fleksja PL | Uwagi |
|---|---|---|
| **Senuto** | Najlepsze — baza PL-native | Polskie SERP data bezpośrednio, top wybór dla PL |
| **Surfer SEO PL** | Dobre — NLP PL-aware | Content scoring z rozumieniem morfologii PL |
| **Ahrefs (PL locale)** | Akceptowalne | Wymaga manualnej grupacji wariantów fleksyjnych |
| **Google Trends PL** | Dobre — darmowe | Sezonowość queries PL, porównanie wariantów |
| **Google Search Console** | Obowiązkowe (free) | Realne query data z projektu — bazowy monitoring |

Pełna deklinacja 15 słów branży budowlanej → `fleksja-examples.md`.

### Jak agregować w praktyce

1. Seed keyword: "fundament" (singular nominative)
2. Wygeneruj wszystkie warianty (7 przypadków × 2 liczby = do 14 form)
3. W Senuto/Ahrefs: sprawdź każdy wariant, zsumuj volume
4. Planuj content pod primary form, użyj wariantów naturalnie w treści

---

## 2. Polskie SERP behavior

### Search engine market share PL (2026)

| Silnik | Share PL | Uwagi |
|---|---|---|
| **Google.pl** | ~95% | Dominujący, jedyny ważny dla SEO PL |
| **Bing.pl** | ~4-5% | Marginalny, ale Bing = Copilot AI base |
| **Yandex** | <1% | Nieistotny dla projektów PL |

**Praktyczna konsekwencja:** optymalizuj wyłącznie pod Google.pl. Bing/Yandex = zero inwestycji dodatkowej.

### Social media impact na SEO PL

| Platforma | Rola PL | Wskazówka SEO |
|---|---|---|
| **Facebook** | Dominujący social PL — viral content | og:image 1200×630px, og:description CTA |
| **LinkedIn** | B2B — firmy, rekrutacja, eksperci | LinkedIn preview = og: tags |
| **Twitter/X** | Niska adopcja PL | twitter:card = bonus, nie priorytet |
| **TikTok** | Rosnący (gen Z PL) | Video content — nie bezpośredni ranking signal |

### Query behavior PL vs EN

| Cecha | PL user | EN-US user |
|---|---|---|
| Długość query | 4-7 słów typowo | 2-3 słów typowo |
| Query pełne zdania | Częstsze ("jak zbudować fundament pod dom") | Rzadsze |
| Voice search PL | Wzrasta po 2024 (pełne zdania, pytania) | Dojrzały rynek |

**Implikacja dla content:** PL title/H2 jako pełne pytanie ("Jak zbudować fundament pod dom jednorodzinny?") wygrywają Featured Snippet + PAA + voice.

---

## 3. Polskie katalogi biznesowe

Top 8 katalogów priorytet HIGH dla branży budowlanej (GW) — szczegółowe metadane wszystkich 16+ katalogów → `polish-catalogs.json`.

| Katalog | Audience | Priority (GW) | Uwaga |
|---|---|---|---|
| **Google Business Profile** | Lokalni klienci szukający usług w okolicy | HIGH | Deep w `regional-seo-poland` — tu reference |
| **OLX** | Lokalny intent B2C — najpopularniejszy PL | HIGH | #1 PL classified, ogromny organic traffic |
| **Aleo** | B2B — przetargi, firmy budowlane, kooperacja | HIGH | Baza kontrahentów B2B, kluczowy dla GW |
| **Panorama Firm** | Lokalne firmy usługowe, wszystkie branże | HIGH | Google Maps integration, citation |
| **Oferia** | Zlecenia usługowe, wyceny | HIGH | Aktywne zapytania od klientów |
| **BudGet** | Branżowy budowlany — kosztorysy, oferty | HIGH | Niszowy budowlany — target audience idealne |
| **FirmyBudowlane.pl** | Branżowy — firmy budowlane PL | HIGH | Specjalizowany katalog — wysoka relevance |
| **MuratorPlus** | Architekci, inwestorzy, branża budowlana | HIGH | Autorytet branżowy, B2B i prosument |

Pełna lista 16+ katalogów z `format_nap`, `submission_method`, `cost`, `last_verified` → `polish-catalogs.json`.

**Zasada weryfikacji aktualności:** sprawdzaj `last_verified` per katalog — jeśli >12 miesięcy, zweryfikuj czy katalog nadal działa przed submission.

---

## 4. Stop words PL

### Top 20 stop words polskich

```
i, w, na, dla, do, z, że, jak, bo, się,
to, ten, ta, te, jest, ma, są, nie, tak, aby
```

Plus warianty: nie → nic, przez, przy, po, pod, nad, o, a, ale, ze, ku, czy, lub.

### Wpływ na SEO

**URL slug:** stop words skracają URL — usuwaj je.
- DOBRZE: `/fundamenty-dom-jednorodzinny` (bez "pod", "dla")
- ZLE: `/fundamenty-pod-dom-jednorodzinny-dla-inwestora`

**Meta title budget:** Google obcina po ~60 znakach. PL stop words są krótkie (2-3 litery), ale przy 4-5 stop wordach w tytule konsumują ~15-20 znaków cennego miejsca. Primary keyword musi być PIERWSZE.

**Content density:** PL ma proporcjonalnie więcej stop words niż EN — keyword density 1-2% dla PL jest normalna, en-US heurystyki (>2%) przeszacowują.

---

## 5. Transliteration ąęłńóśźż → ASCII

### Standard: ASCII-only URL (zalecane)

Polskie znaki diakrytyczne w URL = anti-pattern. Powody:

1. **Social share mangling** — Facebook, Messenger, SMS mogą uciekować URL, psując link
2. **Copy-paste issues** — niektóre edytory/klienty email przekodowują PL znaki
3. **Backward compatibility** — stare przeglądarki (IE, starsze Android WebView) łamią się przy PL chars
4. **Analytics** — Google Analytics może traktować `/ściany` i `/sciany` jako 2 różne strony

### Mapa transliteracji

```
ą → a    ę → e    ł → l    ń → n
ó → o    ś → s    ź → z    ż → z
ć → c    ź → z
```

### Implementacja

**Opcja A — biblioteka (rekomendowana):**
```
npm: @sindresorhus/slugify z opcją {locale: 'pl'}
lub: slugify z mapą PL chars
```

**Opcja B — custom mapping (gdy brak npm):**
```javascript
// pseudokod — full impl w seo-content-writer (5B)
const PLmap = {ą:'a', ę:'e', ł:'l', ń:'n', ó:'o', ś:'s', ź:'z', ż:'z', ć:'c'};
const slug = str.replace(/[ąęłńóśźżć]/g, c => PLmap[c]).toLowerCase.replace(/\s+/g, '-');
```

**Redirect 301 z historycznych URL z PL chars:**
Jeśli strona miała `/ściany-w-budynku`, ustaw redirect 301 → `/sciany-w-budynku`. Bez redirecta: split link equity.

---

## 6. URL slug PL — zasady i przykłady

### Zasady

1. Kebab-case (tylko myślniki, bez underscores)
2. Transliteration ąęłńóśźż → ASCII (sekcja 5)
3. Stop words PL usuń (sekcja 4)
4. Max ~60 znaków całkowita długość path segment
5. Primary keyword jak najwcześniej w URL

### Przykłady "dobrze vs źle"

**Scenariusz:** artykuł o fundamentach pod dom jednorodzinny.

```
DOBRZE: /blog/fundamenty-pod-dom-jednorodzinny
        (keyword first, stop word "pod" OK — kontekst semantyczny, czytelny)

ZLE #1: /blog/fundamenty-pod-dom-jednorodzinny-w-mazowieckiem
        (region jako URL → anti-pattern; region = tag, kategoria lub osobna strona lokalna)

ZLE #2: /blog/fundamenty-pod-dom-jednorodzinny-niska-cena-najlepszy-wykonawca
        (keyword stuffing — manual penalty risk, spamerski wygląd w SERP)
```

**Scenariusz 2:** artykuł "Ściany żelbetowe — ile kosztują?"

```
DOBRZE: /blog/sciany-zelbetowe-ile-kosztuja
        (transliteration: ściany→sciany, żelbetowe→zelbetowe, kosztują→kosztuja)

ZLE #1: /blog/ściany-żelbetowe-ile-kosztują
        (PL chars w URL — social mangling, encoding issues)

ZLE #2: /blog/%C5%9Bciany-%C5%BCelbetowe-ile-kosztuj%C4%85
        (URL-encoded Unicode — nieczytelny dla użytkownika, social niezdatny)
```

---

## 7. Polski content style guide (preview)

**Pełen style guide PL → `content-strategy-construction` + `seo-content-writer` (5B).** Tu preview + boundary.

### Formal vs informal (decyzja per projekt)

| Typ firmy | Ton | Przykład |
|---|---|---|
| Firma budowlana B2B/B2C | **Formal** | "Realizujemy budowę domów jednorodzinnych" |
| Startup tech, e-commerce młodzi | Informal | "Robimy strony, które konwertują" |
| Kancelaria, finanse, medycyna | **Formal zawsze** | "Świadczymy usługi prawne w zakresie..." |

**Reguła:** jednorazowa decyzja na START projektu. NIE mieszaj formal+informal w jednym tekście — "Nasza firma buduje" + "Robimy to najlepiej" = niespójność sygnalizująca brak profesjonalizmu.

### Konstrukcje PL-native (vs kalki z angielskiego)

```
ZLE (kalka en):  "My jesteśmy liderami w branży"
DOBRZE (PL):     "Realizujemy projekty dla wymagających inwestorów"

ZLE (kalka en):  "Oferujemy serwis najwyższej jakości"
DOBRZE (PL):     "Wykonujemy prace z 10-letnim doświadczeniem"
```

**Pełen słownik kalk + adaptacji PL → `seo-content-writer` (5B).**

---

## Boundary with seo-fundamentals

**seo-fundamentals (E1):** URL slug 1 paragraf (`ą→a`, kebab-case), `og:locale: pl_PL`, `hreflang: pl` — generic, en-US pattern.

**polish-language-seo (TU):** fleksja PL keyword research (7 przypadków), polskie SERP behavior (Google.pl 95%), katalogi PL (16+ z metadanymi), transliteration DEEP, stop words PL, URL slug PL z przykładami.

| Pytanie | Skill |
|---|---|
| "Jak ustawić hreflang dla PL?" | `seo-fundamentals` |
| "Warianty 'budowa domu' we wszystkich przypadkach?" | `polish-language-seo` → `fleksja-examples.md` |
| "Jakie katalogi PL zgłosić dla firmy budowlanej?" | `polish-language-seo` → `polish-catalogs.json` |

---

## Boundary with seo-advanced

**seo-advanced (E2):** generyczny intent mapping + content gap — szablony niezależne od języka, CWV optimization, E-E-A-T per industry, topical clusters.

**polish-language-seo (TU):** PL SERP behavior (Google.pl dominance, Facebook social mix), PL-specific query patterns (4-7 słów, voice search PL), polskie katalogi.

| Pytanie | Skill |
|---|---|
| "Jak analizować topical clusters?" | `seo-advanced` |
| "Jak zachowują się PL użytkownicy w SERP?" | `polish-language-seo` |
| "Jak optymalizować pod Featured Snippet?" | `seo-advanced` |

---

## Boundary with regional-seo-poland (E4)

**Kluczowa granica: LANGUAGE vs GEO.**

**polish-language-seo (TU):** jak pisać/szukać PO POLSKU — fleksja, transliteration, stop words, PL query patterns.

**regional-seo-poland (E4):** gdzie geograficznie — województwa, powiaty, Google Business Profile (deep), NAP consistency, citation building (strategia), reviews playbook, local SERP.

| Pytanie | Skill |
|---|---|
| "Jak deklinować 'Warszawa' we wszystkich przypadkach?" | `polish-language-seo` |
| "Jak skonfigurować GBP dla firmy w Warszawie?" | `regional-seo-poland` |
| "Jak pisać URL slug po polsku?" | `polish-language-seo` |
| "Jak budować cytowania NAP w woj. mazowieckim?" | `regional-seo-poland` |

---

## Anti-patterns

| Anti-pattern | Problem | Naprawa |
|---|---|---|
| **Warianty fleksyjne jako osobne keywords** | Volume "fundamentu" + "fundament" = fałszywe podwojenie. Keyword plan przeszacowany 2-3× | Grupuj warianty jako jeden cluster — sum volume, primary = singular nominative |
| **PL chars w URL slug** | `ściany-żelbetowe` → social mangling, copy-paste łamie link, split link equity | Transliteration ASCII-only. Redirect 301 z historycznych PL-char URLs |
| **URL-encoded Unicode w URL** | `/blog/%C5%9Bciany-%C5%BCelbetowe` — nieczytelny dla człowieka, w social wygląda jak spam | Slugify z PL locale lub custom mapa PL→ASCII |
| **en-US tooling bez PL adapter** | Ahrefs raw, SemRush EN locale — undercount volume dla PL (bo fleksja fragmentuje) | Senuto jako primary dla PL, lub manualna agregacja wariantów w Ahrefs |
| **Stop words PL w URL slug** | `/fundamenty-w-domu-dla-inwestora` — długi, stop words zjadają limit 60 znaków | Usuń stop words z URL: `/fundamenty-dom-inwestor` |
| **Ignorowanie OLX/Aleo/Panorama Firm** | Pominięcie top PL katalogów = brak lokalnych citations, gorszy local pack | Zgłoś do top 8 HIGH priority wg `polish-catalogs.json` |
| **Voice search PL ignored** | Po 2024 voice queries PL rosną — krótkie odpowiedzi FAQ format nieobecne | Dodaj sekcje FAQ z pytaniami pełnozdaniowymi (H2 = pytanie + odpowiedź 40-60 słów) |
| **Mieszanie formal + informal w jednym tekście** | "Nasza firma realizuje" + "robimy to szybko" = niespójność brand voice | Decyzja formal/informal na START projektu, konsekwentna przez cały content |
| **Tłumaczenie en-US content 1:1** | "Leverage our expertise" → "Wykorzystaj naszą wiedzę ekspercką" — kalka, nie PL-native | Adaptacja do naturalnego PL, nie tłumaczenie. Test: czy native speaker tak by powiedział? |

---

## How to extend / customize

**Inna branża niż budowlana:** `fleksja-examples.md` ma "Adapter pattern" w nagłówku — zamień 15 słów na słowa kluczowe własnej branży. Wzorzec deklinacji (7 przypadków × 2 liczby) pozostaje ten sam.

**Nowe katalogi PL:** otwórz `polish-catalogs.json` → skopiuj jeden wpis → podmień pola. Pole `_comment` wyjaśnia semantykę każdego pola. Aktualizuj `_meta.total_catalogs`.

**Priorytet katalogów dla innej branży:** `polish-catalogs.json` ma `priority_for_construction` (HIGH/MED/LOW). Dodaj analogiczne pole `priority_for_{twoja_branza}` i zmień wartości.

---

## References

- **Google Search Central PL — URL structure:** https://developers.google.com/search/docs/crawling-indexing/url-structure
- **Senuto Blog — keyword research PL:** https://www.senuto.com/pl/blog/
- **Ahrefs Blog PL — keyword research PL market:** https://ahrefs.com/blog/pl/
- **web.dev — URL best practices:** https://web.dev/articles/url-structure
- **slugify npm (sindresorhus):** https://github.com/sindresorhus/slugify
- **Polskie stop words (jednostki publiczne):** https://github.com/stopwords-iso/stopwords-pl
- **Google Trends PL:** https://trends.google.pl/trends/?geo=PL
