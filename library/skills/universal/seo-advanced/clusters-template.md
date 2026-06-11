# Topical Clusters Template

Plik pomocniczy do `seo-advanced` SKILL.md sekcja 3. Pełny template hub+spoke dla branży budowlanej (przykład PL) + adapter pattern dla innych branż.

---

## Template: Budowa domu jednorodzinnego (Construction PL)

**Seed keyword:** `budowa domu jednorodzinnego`
**Branża:** budownictwo mieszkaniowe
**Rynek:** Polska (PL)
**Hub URL:** `/uslugi/budowa-domu-jednorodzinnego`

---

### Hub page

| Pole | Wartość |
|---|---|
| **URL** | `/uslugi/budowa-domu-jednorodzinnego` |
| **Title tag** | `Budowa domu jednorodzinnego — Kompletny przewodnik 2026 \| GW Budownictwo` |
| **H1** | `Budowa domu jednorodzinnego — wszystko co musisz wiedzieć` |
| **Intent** | Commercial + Informational (mixed — pillar content) |
| **Word count** | 3500-5000 słów |
| **CTA** | "Bezpłatna wycena budowy domu" (hard CTA, widoczny 3x: góra / środek / dół) |
| **Struktura** | Intro → TOC → sekcje dla każdego spoke tematu (200-400 słów każda + link do spoke) → CTA |
| **Internal links out** | Do wszystkich 7 spokes (anchor text per wiersz tabeli poniżej) |
| **Schema** | Service + AggregateRating + BreadcrumbList |

---

### Spoke pages (7 sub-topics)

| # | URL | H1 | Intent | Word count | Anchor text z hub | Link do hub | CTA |
|---|---|---|---|---|---|---|---|
| S1 | `/blog/fundamenty-pod-dom-rodzaje-koszty` | Fundamenty pod dom jednorodzinny — rodzaje i koszty 2026 | Informational | 2000 | "rodzaje fundamentów" | Tak — "Wróć do przewodnika budowy domu" | Pobierz kalkulator kosztów fundamentów |
| S2 | `/blog/wybor-sciany-pustak-vs-cegla-silikatowa` | Ściany zewnętrzne domu — pustak ceramiczny vs cegła silikatowa vs beton komórkowy | Informational | 1800 | "wybór technologii ścian" | Tak | Zapytaj o wycenę murów |
| S3 | `/blog/stropy-gestozebrowe-vs-monolityczne` | Stropy w domu jednorodzinnym — gęstożebrowe vs monolityczne vs Teriva | Informational | 2200 | "typy stropów" | Tak | Porównaj rozwiązania dla swojego projektu |
| S4 | `/blog/wiezba-dachowa-rodzaje` | Więźba dachowa — rodzaje, drewno C24 vs KVH, koszty 2026 | Informational | 1600 | "więźba dachowa" | Tak | Zapytaj o projekt więźby |
| S5 | `/blog/pokrycie-dachu-blacha-vs-dachowka` | Pokrycie dachu — blacha trapezowa vs dachówka ceramiczna vs gont | Commercial | 2000 | "wybór pokrycia dachu" | Tak | Zapytaj o wycenę dachu |
| S6 | `/blog/stan-surowy-otwarty-zamkniety-definicje` | Stan surowy otwarty i zamknięty — definicje, co zawiera, koszty | Informational | 1500 | "stan surowy otwarty i zamknięty" | Tak | Sprawdź etapy budowy i cennik |
| S7 | `/blog/harmonogram-budowy-domu-etapy` | Harmonogram budowy domu — kolejność etapów i czasy realizacji | Informational | 1800 | "harmonogram budowy" | Tak | Pobierz przykładowy harmonogram (PDF) |

---

### Internal linking matrix

```
Hub (/uslugi/budowa-domu-jednorodzinnego)
  └── link out → S1 (anchor: "rodzaje fundamentów")
  └── link out → S2 (anchor: "wybór technologii ścian")
  └── link out → S3 (anchor: "typy stropów")
  └── link out → S4 (anchor: "więźba dachowa")
  └── link out → S5 (anchor: "wybór pokrycia dachu")
  └── link out → S6 (anchor: "stan surowy otwarty i zamknięty")
  └── link out → S7 (anchor: "harmonogram budowy")

S1 → Hub (anchor: "Wróć do kompletnego przewodnika budowy domu")
S1 → S6 (sibling, anchor: "stan surowy otwarty — co obejmuje") [naturalny kontekst]

S2 → Hub
S2 → S3 (sibling, anchor: "stropy pod wybrane ściany")

S3 → Hub
S3 → S2 (sibling, anchor: "ściany zewnętrzne a dobór stropu")

S4 → Hub
S4 → S5 (sibling, anchor: "pokrycie dachu po montażu więźby")

S5 → Hub
S5 → S4 (sibling, anchor: "więźba dachowa — przygotowanie pod dachówkę/blachę")

S6 → Hub
S6 → S7 (sibling, anchor: "harmonogram etapów — po stanie surowym zamkniętym")

S7 → Hub
S7 → S6 (sibling, anchor: "stan surowy w harmonogramie")
```

**Zasada sibling links:** max 2 sibling links per spoke (nie twórz pełnej siatki — priority jest HUB).

---

### Schema per page

**Hub page:**
```json
{
  "@type": "Service",
  "name": "Budowa domu jednorodzinnego",
  "url": "https://domain.pl/uslugi/budowa-domu-jednorodzinnego"
}
```
+ `BreadcrumbList`: `Strona główna → Usługi → Budowa domu jednorodzinnego`

**Spoke pages (example S1):**
```json
{
  "@type": "Article",
  "headline": "Fundamenty pod dom jednorodzinny — rodzaje i koszty 2026",
  "author": { "@type": "Person", "name": "{{AUTHOR}}" }
}
```
+ `BreadcrumbList`: `Strona główna → Blog → Fundamenty pod dom`
+ `FAQPage` (jeśli strona ma sekcję FAQ/PA) — dodaje szanse Featured Snippet / PAA

---

## Adapter pattern — jak zaadaptować dla innej branży

4 kroki dostosowania templateu do nowej branży lub tematu:

### Krok 1 — Zmień seed keyword i hub URL

```
Budownictwo:  "budowa domu jednorodzinnego"   → /uslugi/budowa-domu-jednorodzinnego
Medical:      "leczenie kręgosłupa"            → /uslugi/leczenie-kregoslupa
Finance:      "planowanie emerytury"           → /uslugi/planowanie-emerytury
Legal:        "prawo nieruchomości"            → /uslugi/prawo-nieruchomosci
```

### Krok 2 — Zidentyfikuj 5-8 sub-topics

Narzędzia:
1. Google Suggest — dopisuj kolejne słowa do seed keyword
2. People Also Ask w SERP dla seed keyword (top 5-8 pytań = kandydaci na spokes)
3. Ahrefs "Also rank for" lub Semrush "Related keywords" per seed
4. Manual SERP review top 3-5 wyników — ich H2/H3 = kandydaci sub-topics

Walidacja per spoke-kandidat:
- Volume >50/mc (GSC lub Ahrefs)
- Relevance >7/10 (czy naturalnie pasuje pod hub temat?)
- Keyword difficulty <50 (inaczej za długo na efekty dla nowej strony)

### Krok 3 — Dostosuj word count i CTA

Word count zależy od głębokości tematu per branża:

| Branża | Hub | Spoke |
|---|---|---|
| Construction (techniczna, wiele aspektów) | 3500-5000 słów | 1500-2500 słów |
| Medical (specjalistyczna, regulatory) | 3000-4000 słów | 1200-2000 słów |
| Finance (prawo + liczby) | 2500-3500 słów | 1000-1800 słów |
| Legal (kontekst prawny) | 2500-3500 słów | 1000-1800 słów |

CTA per intent:
- Hub (commercial/mixed) → hard CTA ("Bezpłatna wycena", "Umów konsultację")
- Spoke informational → soft CTA ("Pobierz checklist", "Zapisz na newsletter")
- Spoke commercial → medium CTA ("Sprawdź ofertę", "Porównaj warianty")

### Krok 4 — Zmień anchor texts

Anchor texts muszą być deskryptywne i nawiązywać do tematu docelowego spoke.

```
Nie:   "kliknij tutaj", "więcej", "sprawdź"
Tak:   "rodzaje fundamentów pod dom", "wybór pokrycia dachu"
```

Proporcje anchor text:
- ~60% partial match (np. "fundamenty pod dom jednorodzinny")
- ~20% exact match (np. "rodzaje fundamentów")
- ~20% branded / generic descriptive (np. "nasz przewodnik po fundamentach")

---

## Checklist przed opublikowaniem klastra

- [ ] Hub page opublikowany z linkami do wszystkich planowanych spokes (linki aktywne od początku — zaplanuj URL z góry)
- [ ] Min 5 spokes opublikowanych (topical authority próg)
- [ ] Każda spoke linkuje wstecznie do huba
- [ ] Hub ma TOC z linkami do spokes
- [ ] Wszystkie anchor texts deskryptywne (nie "kliknij tutaj")
- [ ] Schema per page przetestowana w Google Rich Results Test
- [ ] BreadcrumbList na każdej stronie (hub + spokes)
- [ ] GSC: prześlij sitemap po opublikowaniu nowych URL
- [ ] Monitoruj GSC "Performance" per spoke URL — po 4-6 tygodniach sprawdź ranking (nowe strony potrzebują ~30 dni na indeksowanie i ranking stabilizację)
