---
name: seo-advanced
description: SEO competitive edge — Core Web Vitals optimization (WHAT+WHY+HIGH-LEVEL HOW), E-E-A-T markers per industry (construction/medical/finance/legal), topical clusters (hub+spoke), intent mapping, content gap analysis, SERP features (featured snippets, PAA, AI Overview/SGE), schema markup nesting. Nadbudowa nad seo-fundamentals dla stron które chcą rankować TOP 10 w konkurencyjnych SERPach. Uruchamiaj gdy techniczna podstawa (seo-fundamentals) jest wdrożona i strona nadal rankuje 30-50 zamiast top 10.
version: 1.0.0
compatible_with: [universal]
tags: [seo, advanced, optimization]
requires: [seo-fundamentals]
token_cost: medium
distribution: library/skills/universal/
last_updated: 2026-05-11
---

# seo-advanced

Wiedza competitive SEO — jeden poziom wyżej niż techniczna podstawa z `seo-fundamentals`. Skill zakłada, że strona ma już MUST-DO baseline (meta, schema, sitemap, robots, canonical, CWV progi wdrożone). Tu wchodzi NICE-TO-HAVE + competitive edge. Przykłady branżowe: budownictwo (firma GW), skill UNIWERSALNY.

**Prerequisite check:** przed użyciem tego skilla sprawdź czy `seo-fundamentals` jest wdrożony (`requires: [seo-fundamentals]`). Bez bazowego fundamentu zaawansowane techniki nie dają pełnego efektu.

**Bundle pliki:**
- `SKILL.md` — wiedza referencyjna (ten plik)
- `eeat-checklist.md` — szczegółowy checklist E-E-A-T per branża (construction, medical, finance, legal, generic)
- `clusters-template.md` — template hub+spoke budowlanka + adapter pattern
- `schema-nesting-examples.json` — ready-to-use JSON-LD templates z placeholderami (Article+Author, FAQPage, HowTo, AggregateRating, BreadcrumbList)

## When to use this skill

Uruchamiaj gdy:
- Strona ma wdrożone MUST-DO (meta, schema, sitemap, robots, canonical, CWV progi) i nadal nie rankuje top 10
- Planujesz strategię topical authority (hub+spoke clusters) dla nowej lub istniejącej strony
- Analizujesz keyword gaps vs top-3 SERP — co konkurenci mają a my nie
- Projektujesz content E-E-A-T dla branży YMYL-adjacent (budowlanka, medycyna, finanse, prawo)
- Optymalizujesz pod SERP features (Featured Snippets, PAA, AI Overview/SGE)
- Wdrażasz zaawansowane schema nesting (Article + Author + Publisher, HowTo, AggregateRating)
- Agent `seo-strategist` (E5), `seo-auditor` (E6), `seo-content-writer` (5B) lub `competitor-watcher` (5D) analizuje lub tworzy content

NIE uruchamiaj gdy:
- Brakuje podstawowych meta tagów, sitemapy, robots.txt → `seo-fundamentals`
- Potrzebujesz deep code fixes dla CWV (Next.js preload, Partytown, dynamic imports) → `page-speed-optimizer` (5C)
- Szukasz wzorców fleksji PL w keyword research → `polish-language-seo` (E3)
- Konfigurujesz Google Business Profile krok po kroku → `regional-seo-poland` (E4)

---

## 1. Core Web Vitals 2026 — WHAT + WHY + HIGH-LEVEL HOW

**Scope:** thresholds (powtórka z seo-fundamentals dla self-completeness), WHY każda metryka ważna, HIGH-LEVEL jak poprawić. DEEP code fixes (preload, Partytown, Next/Image priority, font-display) → `page-speed-optimizer` (5C).

### LCP — Largest Contentful Paint

| Level | Threshold | Znaczenie |
|---|---|---|
| Good | <2.5s | Google premiuje — ranking signal |
| Needs Improvement | 2.5-4.0s | Neutralny — brak premii ani kary |
| Poor | >4.0s | Negatywny ranking signal |

**Co jest mierzonym elementem:** hero image, hero video poster, blok H1+paragraf (jeśli największy visible element w viewport).

**WHY:** użytkownik postrzega stronę jako "załadowaną" w momencie gdy wyświetli się główny content. LCP odzwierciedla tę percepcję — bezpośrednio koreluje z bounce rate.

**HIGH-LEVEL HOW:** preload hero image (`<link rel="preload" as="image">` lub Next/Image `priority`), optymalizacja formatu (AVIF/WebP), eliminacja render-blocking CSS/JS powyżej fold, SSR/SSG zamiast client-side hydration dla first paint.

### INP — Interaction to Next Paint

| Level | Threshold |
|---|---|
| Good | <200ms |
| Needs Improvement | 200-500ms |
| Poor | >500ms |

**NEW od marca 2024** — zastąpiło FID (First Input Delay). Kluczowa różnica: INP mierzy ALL interakcje przez cały czas życia strony (kliknięcia, dotknięcia, klawiatura), nie tylko pierwszą.

**WHY:** strony heavy JS (kalkulatory wycen, konfigurator budowlany) mają problem z INP mimo dobrego LCP. Google traktuje responsywność jako sygnał jakości UX.

**HIGH-LEVEL HOW:** zmniejsz JS main thread work (Long Tasks >50ms → podziel), Scheduler API (`scheduler.yield`), web workers dla CPU-heavy operacji, debounce heavy event handlers. Debug: Chrome DevTools Performance → "Long Tasks" + INP attribution.

### CLS — Cumulative Layout Shift

| Level | Threshold |
|---|---|
| Good | <0.1 |
| Needs Improvement | 0.1-0.25 |
| Poor | >0.25 |

**WHY:** niezapowiedziane skoki layoutu niszczą UX — użytkownik klika "Zamów wycenę" i trafia w reklamę bo przycisk się przesunął po załadowaniu banera.

**HIGH-LEVEL HOW:** zawsze `width` + `height` na `<img>`/`<video>` (reserved space), `font-display: swap` z `size-adjust`, reserved space pod ads/embeds/iframes, nie wstrzykuj content powyżej istniejącego layoutu po załadowaniu.

### Lab vs Field — krytyczna różnica

| Typ | Narzędzia | Dane | Użycie |
|---|---|---|---|
| **Lab** | Lighthouse CLI, PageSpeed Insights (lab tab) | Symulacja 4G, kontrolowane warunki | Debug — szybka iteracja |
| **Field** | CrUX, PageSpeed Insights (field tab), `web-vitals` npm | Real users 28 dni, prawdziwe sieci | Google ranking — liczy się w algorytmie |

**Wniosek:** Lab 95+ nie gwarantuje Field >90 (różne urządzenia, wolne sieci). Google ranking używa Field data. Monitoruj obie. Dodatkowe narzędzia: `Calibre` / `SpeedCurve` (paid monitoring z alertami).

---

## 2. E-E-A-T markers (per industry)

**E-E-A-T (Experience-Expertise-Authoritativeness-Trustworthiness)** — framework Google Search Quality Rater Guidelines (2022+). Kluczowy dla YMYL i YMYL-adjacent.

**Dlaczego budowlanka = YMYL-adjacent:** inwestycja 300-600k PLN, bezpieczeństwo konstrukcji, decyzja na 20+ lat. Google traktuje takie tematy jak finansowe — wymaga sygnałów prawdziwej ekspertyzy.

### 4 filary E-E-A-T

| Filar | Pytanie Google | Sygnały |
|---|---|---|
| **Experience** (NOWY 2022) | Czy autor ma realne doświadczenie? | Case studies z własnymi projektami, zdjęcia z realizacji |
| **Expertise** | Czy autor zna się na temacie? | Certyfikaty, licencje, lata praktyki, publikacje |
| **Authoritativeness** | Czy branża uznaje autora/stronę? | Cytowania, członkostwo w stowarzyszeniach, media |
| **Trustworthiness** | Czy można zaufać stronie? | HTTPS, kontakt widoczny, regulamin, zweryfikowane opinie |

### Wspólne markers (każda branża)

- Author bio na każdej stronie article (imię, foto, krótki bio, link do pełnego profilu)
- `Article` schema z embedded `Author` (→ `schema-nesting-examples.json`)
- `Organization` schema w footerze z `sameAs` do social + kontakt
- HTTPS + valid SSL, kontakt w footer (tel, email, adres)
- Polityka prywatności + regulamin + cookies
- Customer reviews (`AggregateRating` w `Service` — tylko prawdziwe opinie)

### Per industry preview (szczegółowy checklist → `eeat-checklist.md`)

| Industry | Experience | Expertise | Authority | Trust |
|---|---|---|---|---|
| **Construction** | Case studies (m², lokalizacja, before/after) | Uprawnienia PIIB (numer) | Członkostwo PIIB / Izba Budowlana | OC kontraktorskie, gwarancja 5 lat, NIP/KRS |
| **Medical** | Anonimizowane case studies, lata praktyki | Numer PWZ, specjalizacje, certyfikaty | Publikacje (PubMed), stanowiska szpitalne | RODO, OC zawodowe, regulamin teleporad |
| **Finance** | Track record, ROI case studies | Licencje KNF, CFA/ACCA/FRM | Wpisy KNF, CFA Institute membership | Audyt zewnętrzny, KNF compliance |
| **Legal** | Sprawy wygrane (anonimizowane) | Wpis KIRP/NRA (numer) | Stanowiska w samorządzie, publikacje | OC wymagane prawem, tajemnica zawodowa |
| **Generic fallback** | Lata działalności, testimonials | Certyfikaty branżowe | Przynależność do izb, press mentions | Dane rejestrowe, kontakt, regulamin |

**Adapter pattern:** aby dodać nową branżę — skopiuj wiersz "Generic fallback" + podmień markers per regulator. Pełna instrukcja w `eeat-checklist.md`.

---

## 3. Topical clusters (hub + spoke model)

Topical clusters = strategia sygnalizująca Google "ta strona jest autorytetem w temacie X".

**Hub page (pillar):** ~3000-5000 słów, breadth (cały temat wysoko), linki do wszystkich spokes, URL top-level (`/uslugi/<temat>`), target keyword broad.

**Spoke pages:** ~1500-2500 słów, depth (jeden aspekt głęboko), link wstecznie do huba, URL: `/blog/<sub-temat>`, target keyword specific.

### Reguły implementacji

- Min 5 spokes per hub (próg topical authority — mniej = Google traktuje jako pojedyncze strony)
- Każda spoke linkuje do huba min raz (anchor text opisowy, nie "kliknij tutaj")
- Hub linkuje do wszystkich spokes (TOC + inline links w treści)
- Spokes mogą linkować sibling — OK, ale priorytet zawsze hub
- Nowe spokes: aktualizuj TOC w hub PRZED publikacją

### Przykład budowlanka GW (wysoki poziom)

```
Hub: /uslugi/budowa-domu-jednorodzinnego (3500 słów)
  ├── /blog/fundamenty-pod-dom-rodzaje-koszty         (2000 słów, informational)
  ├── /blog/wybor-sciany-pustak-vs-cegla-silikatowa   (1800 słów, informational)
  ├── /blog/stropy-gestozebrowe-vs-monolityczne        (2200 słów, informational)
  ├── /blog/wiezba-dachowa-rodzaje                    (1600 słów, informational)
  ├── /blog/pokrycie-dachu-blacha-vs-dachowka         (2000 słów, commercial)
  ├── /blog/stan-surowy-otwarty-zamkniety-definicje   (1500 słów, informational)
  └── /blog/harmonogram-budowy-domu-etapy             (1800 słów, informational)
```

Pełny template: URL, word count, intents, anchor texts, CTA per spoke, internal linking matrix, checklist przed publikacją → `clusters-template.md`.

---

## 4. Intent mapping (4 typy intencji)

Google SERP analizuje intent query i rankuje treści które mu odpowiadają. Intent mismatch = ranking 30+, nawet przy technicznie dobrej stronie.

| Intent | Trigger słowa kluczowe | Format content | CTA |
|---|---|---|---|
| **Informational** | "jak", "co to", "dlaczego", "różnica między" | Blog post / guide / poradnik | Pobierz checklist, Zapisz się — soft CTA |
| **Commercial** | "najlepszy", "ranking", "porównanie", "opinie" | Comparison / review / listicle | Sprawdź ofertę, Porównaj — medium CTA |
| **Transactional** | "cena", "koszt", "wycena", "kalkulator", "zamów" | Service page / pricing / calculator | Zamów wycenę, Wyślij zapytanie — hard CTA |
| **Navigational** | Brand keyword, "adres", "kontakt" | Brand landing / contact / about | Skontaktuj się, Dojazd |

### Jak określić intent

1. Wpisz keyword w Google (polska wersja)
2. Przejrzyj top 3-5 wyników organicznych (bez reklam)
3. Blog posty dominują → informational; landing pages → transactional; listicle rankingowe → commercial
4. Dopasuj format własnej strony do dominującego w SERP

**Narzędzia (automatyzacja):** Semrush "Search Intent" filter, Ahrefs "Keyword Intent" column.

**Przykłady PL (budowlanka):**
- "jak zbudować dom jednorodzinny krok po kroku" → Informational → blog post
- "najlepsza firma budowlana Warszawa" → Commercial → review / listing
- "kosztorys budowy domu 150m2 kalkulator" → Transactional → pricing / calculator
- "GW Budownictwo Warszawa kontakt" → Navigational → contact / about

---

## 5. Content gap analysis (vs top-3 SERP)

**Cel:** znaleźć keywords/topics które top-3 SERP pokrywają a nasza strona nie.

### Workflow

1. Wybierz seed keyword (np. "budowa domu jednorodzinnego")
2. Google SERP → top 3-5 wyników organicznych (NIE reklamy)
3. Per konkurent: jakie podstrony rankują (Ahrefs "Top Pages", Semrush "Organic Research")
4. Zbierz ich top keywords → cross-reference: co mają a my NIE
5. Filter: volume >50/mc + relevance >7/10 + difficulty osiągalny
6. Output: 20-50 keyword gaps → priorytetyzuj wg volume × relevance / difficulty

### Narzędzia — paid

Ahrefs "Content Gap" (~99 USD/mc), Semrush "Keyword Gap" (~120 USD/mc), SE Ranking (~50 USD/mc), Sistrix (mocny na PL/DE).

### Narzędzia — free baseline

- **Google Search Console** — Performance → Queries (nasze pozycje + braki)
- **Manual SERP review** — czytaj title/H1/H2/H3 top 3 + People Also Ask
- **Google Suggest** (autocomplete) — dopisuj kolejne litery/słowa do seed
- **AnswerThePublic** (free tier 3 queries/dzień), **Ubersuggest** (free tier ~3/dzień)

### Output format

```
Gap analysis seed: "budowa domu jednorodzinnego"
1. "koszt budowy domu 100m2 2026"   vol:1200/mc  KD:35  comp:3/3 ma, my:NIE
2. "fundament płytowy cena za m2"   vol:800/mc   KD:25  comp:2/3 ma, my:NIE
3. "pozwolenie na budowę dokumenty" vol:600/mc   KD:20  comp:3/3 ma, my:NIE
→ Priorytet: #1 (volume max) + #3 (KD niski = łatwy do rankowania)
```

---

## 6. SERP feature optimization

SERP features = elementy ponad/pomiędzy standardowymi wynikami organicznymi. Cel: maksymalizacja share of SERP real estate.

### Featured Snippets (pozycja 0)

Google wyświetla wybrany fragment powyżej pierwszego wyniku organicznego (query informational).

**Format który wygrywa:** H2/H3 jako pytanie dosłownie (`## Ile kosztuje budowa domu jednorodzinnego?`) + pierwszy paragraf 40-60 słów z bezpośrednią odpowiedzią + opcjonalnie tabela/lista. Schema FAQPage + HowTo wzmacniają szanse.

### People Also Ask (PAA)

4-8 powiązanych pytań w akordeonowym bloku. Optymalizacja: FAQ section z pytaniami z Google Suggest + AnswerThePublic, schema `FAQPage` (Q jako H3, odpowiedź 40-80 słów). JSON-LD template → `schema-nesting-examples.json`.

### AI Overview / SGE (Search Generative Experience)

Google Gemini i Bing Copilot generują syntetyczną odpowiedź, cytując wybrane źródła.

**Jak content musi być structured żeby AI cytował:**
- Jasna odpowiedź w pierwszym paragrafie pod nagłówkiem
- Schema FAQPage + HowTo (parsowane przez AI Overview)
- Autorytarne linki (PN-EN normy, izby branżowe, oficjalne dokumenty)
- E-E-A-T markers widoczne (autor z certyfikatem, Organization schema)
- Krótkie precyzyjne zdania (AI cituje fragmenty)

**Trade-off:** AI Overview = mniej kliknięć, ale brand awareness + autorytet rośnie gdy jesteś cytowanym źródłem.

**ZAKAZ:** fake authority — deepfake autora, AI-generated credentials. Google SGE + Helpful Content Update 2024+ wykrywają wzorce i penalizują.

**robots.txt:** `GPTBot: Disallow` blokuje OpenAI/Perplexity, NIE Google SGE (Google używa Googlebot). Szczegóły → `seo-fundamentals` sekcja 4.

### Image Pack, Video Pack, Knowledge Panel

| Feature | Optymalizacja |
|---|---|
| **Image Pack** | `alt` deskryptywny, filename SEO (`fundament-plytowy-dom.jpg`, NIE `IMG_1234.jpg`), schema `ImageObject` w Article, kontekst tekstowy obok obrazu |
| **Video Pack** | Schema `VideoObject` na stronie, tytuł + opis YouTube z keyword, transcript (tekst) pod video |
| **Knowledge Panel** | Wikipedia/Wikidata entry, `Organization` schema z `sameAs`, Google Business Profile zweryfikowany (→ `regional-seo-poland`) |

---

## 7. Schema markup nesting + advanced

**Scope:** seo-fundamentals pokrywa 6 schema typów standalone. Advanced = NESTING (jedna embedded w drugiej) + zaawansowane typy (HowTo, AggregateRating, BreadcrumbList nested).

**Ready-to-use JSON-LD templates z placeholderami** → `schema-nesting-examples.json`.

### Dostępne templates

| Template | Zawartość | Kiedy używać |
|---|---|---|
| `article_nested_author_publisher` | Article + Person (z `hasCredential`, `memberOf`) + Organization + ImageObject | Każdy blog post / poradnik z autorem |
| `faqpage_nested_qa` | FAQPage + Question + Answer (x N) | Sekcja FAQ — Featured Snippet + PAA |
| `howto_step_by_step` | HowTo + HowToStep (z image per step) | Przewodniki "jak zrobić" — rich result w SERP |
| `service_with_aggregate_rating` | Service + Organization + AggregateRating | Service page z ocenami (tylko prawdziwe!) |
| `breadcrumblist_nested` | BreadcrumbList + ListItem (3 poziomy) | Nawigacja okruszkowa — zawsze spójna z wizualną |

### Zasady nesting

1. `author` w Article to `Person` embedded — nie standalone `@type: Person`
2. `publisher` w Article to `Organization` embedded — nie reference do innego `@id`
3. `AggregateRating` tylko przy PRAWDZIWYCH opiniach — `reviewCount` musi być zgodny z rzeczywistą liczbą
4. FAQPage — max jeden `@type: FAQPage` per strona (nie stackuj dwóch)
5. BreadcrumbList musi być spójna z wizualnym breadcrumb na stronie

### Walidacja (obowiązkowa przed deployem)

- `validator.schema.org` — składnia Schema.org
- **Google Rich Results Test** — https://search.google.com/test/rich-results — eligible na rich results w SERP

**Zasada:** każdy snippet PRZED wdrożeniem produkcyjnym musi przejść Rich Results Test bez błędów.

---

## Boundary with seo-fundamentals

**seo-fundamentals:** MUST-DO baseline — meta, 6 schema typów standalone, sitemap, robots, canonical, hreflang, CWV progi (tylko liczby), security headers.

**seo-advanced (TU):** NICE-TO-HAVE + competitive — CWV WHY+HOW, E-E-A-T per industry, topical clusters, intent mapping, content gap, SERP features, schema nesting + HowTo/AggregateRating.

| Pytanie | Skill |
|---|---|
| "Jakie są progi CWV?" | `seo-fundamentals` |
| "Jak osiągnąć LCP <2.5s?" | `seo-advanced` (high-level) + `page-speed-optimizer` (kod) |
| "Jak zrobić standalone LocalBusiness schema?" | `seo-fundamentals` |
| "Jak zrobić Article z embedded Author + Publisher?" | `seo-advanced` → `schema-nesting-examples.json` |
| "Co to E-E-A-T?" | `seo-advanced` |
| "Jak zrobić sitemap.xml?" | `seo-fundamentals` |

---

## Boundary with page-speed-optimizer (5C)

**seo-advanced (TU):** WHAT (definicja metryki) + WHY (mechanizm UX/ranking) + HIGH-LEVEL HOW (nazewnictwo techniki — preload, priority hint, web worker, Scheduler API).

**page-speed-optimizer (5C):** DEEP code — konkretny Next.js 15 (`<Image priority>`, `<link rel="preload" fetchpriority="high">`), Partytown GA4 setup, `font-display: optional` + `size-adjust`, CSS critical inline, third-party script isolation.

| Pytanie | Skill |
|---|---|
| "Co to INP i dlaczego ważny?" | `seo-advanced` |
| "Jak skonfigurować Partytown dla GA4 w Next.js 15?" | `page-speed-optimizer` |
| "Dlaczego preload ważny dla LCP?" | `seo-advanced` |
| "Konkretny kod `<Image priority>` dla hero?" | `page-speed-optimizer` |

---

## Boundary with polish-language-seo (E3)

**seo-advanced (TU):** generyczny intent mapping + content gap — szablony niezależne od języka. Przykłady PL, ale bez analizy fleksji.

**polish-language-seo (E3):** fleksja PL w keyword research (7 przypadków — "budowa domu" / "budowy domu"), polskie SERP behavior, polskie katalogi lokalne (OLX, Allegro, Aleo, Panorama Firm), transliteration DEEP.

---

## Anti-patterns

| Anti-pattern | Problem | Naprawa |
|---|---|---|
| **Lab obsession** | Lighthouse 98 lab ≠ Field >90. Google ranking używa CrUX field. Optymalizacja pod lab = strata czasu | Monitoruj Field (PageSpeed Insights field tab, `web-vitals` RUM). Lab = debug tool, nie cel |
| **Fake E-E-A-T authority** | AI-generated author photos, kopiowane certyfikaty, ghost-written credentials. Helpful Content Update 2024+ → kara manualna lub deranking | Tylko realne credencje. Bio z prawdziwym zdjęciem, linki do weryfikowalnych rejestrów (PIIB, NIL, KNF) |
| **Topical cluster bez search demand** | Hub+spoke pod taksonomię wewnętrzną bez sprawdzenia volume. Zero traffic = strata zasobów | Walidacja volume PRZED tworzeniem klastra (GSC + Google Suggest → min 50/mc per spoke) |
| **Intent mismatch** | Transactional query ("cena fundamentów m2") obsłużony blog postem → high bounce, niski ranking | Manual SERP check: jakie formaty Google pokazuje per query? Dopasuj format strony |
| **Schema spam** | `Review` z wymyślonych opinii, `Recipe` na artykuł niespożywczy. Manual penalty risk | Tylko schema odpowiadające prawdziwemu content. Rich Results Test PRZED wdrożeniem |
| **AI Overview cloaking** | Inny content dla Googlebot (SGE) vs użytkownicy. Manual ban + permanent deindexing | Identyczny content dla botów i ludzi. E-E-A-T organicznie, nie ukryte dla botów |
| **Doorway clusters** | Thin spoke pages 300-500 słów tylko dla rankowania. Helpful Content → deranking whole domain | Min 1500 słów per spoke z unikalną wartością. Lepiej 5 wartościowych niż 15 thin pages |
| **One-page-all-intents** | Jedna strona na informational + transactional + commercial → Google nie klasyfikuje → niskie pozycje wszędzie | Dedykowana strona per intent. Blog = informational, service page = transactional |
| **Gap analysis tracking all** | Lista 500+ keyword gaps bez priorytetyzacji → brak postępu | Max 20-50 high-value gaps per cykl. Iteracyjne wypełnianie, nie big bang |

---

## How to extend / customize

**Nowa branża w E-E-A-T:** otwórz `eeat-checklist.md` → "Generic fallback" → kopiuj sekcję → podmień markers per regulator branżowy → dodaj wiersz w tabeli sekcji 2 tego SKILL.md.

**Nowy topical cluster:** otwórz `clusters-template.md` → "Adapter pattern" → 4 kroki (seed keyword, 5-8 sub-topics, word count, anchor texts).

**Nowe schema typy:** `schema-nesting-examples.json` → dodaj nowy klucz (np. `jobposting_nested_org`) → waliduj Rich Results Test → commit.

Dodatkowe schema warte uwagi: `JobPosting` (budowlanka rekrutuje → Google for Jobs), `Event` (dni otwarte inwestycji). Dokumentacja: https://schema.org/JobPosting, https://schema.org/Event.

---

## References

- **Google Search Central — E-E-A-T + Helpful Content:** https://developers.google.com/search/docs/fundamentals/creating-helpful-content
- **Google Search Quality Rater Guidelines (PDF):** https://static.googleusercontent.com/media/guidelines.raterhub.com/en//searchqualityevaluatorguidelines.pdf
- **web.dev — Core Web Vitals:** https://web.dev/articles/vitals
- **web.dev — INP deep dive:** https://web.dev/articles/inp
- **web.dev — CLS:** https://web.dev/articles/cls
- **Google Search Central — Structured Data:** https://developers.google.com/search/docs/appearance/structured-data
- **Google Rich Results Test:** https://search.google.com/test/rich-results
- **Schema.org — Article / HowTo / FAQPage:** https://schema.org/Article, https://schema.org/HowTo, https://schema.org/FAQPage
- **Ahrefs Blog — Topical Authority:** https://ahrefs.com/blog/topical-authority/
- **Search Engine Journal — Search Intent:** https://www.searchenginejournal.com/search-intent/
- **web-vitals npm (RUM):** https://github.com/GoogleChrome/web-vitals
