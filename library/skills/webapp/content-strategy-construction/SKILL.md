---
name: content-strategy-construction
description: Content marketing strategy GW PL — case studies template, koszty m² long-tail keywords, 12 etapów budowy guide, 25+ FAQ items, blog clustering (informational→commercial→transactional intent funnel), seasonal calendar PL (sezon budowlany marzec-listopad). Konsumowany przez seo-content-writer. Uruchamiaj gdy agent pisze content dla strony firmy GW lub piszesz plan content roadmap dla projektu budowlanego Next.js/MDX.
version: 1.0.0
compatible_with: [webapp]
tags: [content, strategy, construction, gw, marketing]
requires: [construction-domain-rules]
token_cost: medium
distribution: library/skills/webapp/
last_updated: 2026-05-11
---

# content-strategy-construction

Framework content marketingu dla firm GW PL. Dostarcza struktury hub-spoke, intent funnel (informational→commercial→transactional), 12-etapowy przewodnik budowy, seasonal calendar i template case studies.

**Scope:** strony internetowe firm GW — domy jednorodzinne, bliźniaki, budynki gospodarcze do kilkuset m². Stack: Next.js + MDX.

**NIE duplikuje definicji z `construction-domain-rules`** — terminologia SSO/SSZ, stawki, normy → referuj do tamtego skilla.

Pliki towarzyszące:
- `case-study-template.md` — pełen template markdown + 1 sample case study (fikcyjny GW mazowieckie)
- `seasonal-calendar-pl.yaml` — 12 miesięcy × focus + 4 fazy roczne + sekcja B2B hale
- `blog-cluster-map.md` — 3 huby × 7-10 spoków + adapter pattern (4. hub regionalny)

---

## 1. Kiedy uruchomić

Uruchom gdy:
- `seo-content-writer` produkuje artykuł dla strony GW — dostarcza mu strukturę H1/H2/H3, internal linking i CTA
- Planujesz content roadmap Q1-Q4 dla projektu webapp GW — seasonal calendar i hub-map
- Tworzysz nowy wpis case study — template z polami metryki zaufania
- Strategist SEO pyta o intencje użytkownika w branży budowlanej — 3-tier intent funnel
- Planujesz FAQ stronę lub sekcję — tabela 25 pozycji gotowa do użycia

NIE uruchamiaj gdy:
- Potrzebujesz definicji SSO/SSZ lub stawek m² → `construction-domain-rules`
- Robisz keyword research per projekt → `seo-strategist` agent + `seo-advanced`
- Audytujesz techniczne SEO strony → `seo-auditor`
- Kwestia fleksji PL lub lokalnych katalogów → `polish-language-seo` / `regional-seo-poland`

---

## 2. Kluczowe zasady

### 2.1 Intent funnel — 3-poziomowa architektura contentu

Każdy artykuł musi mieć przypisaną intencję wyszukiwania:

| Tier | Intencja | Przykładowe queries | CTA | Format |
|---|---|---|---|---|
| **Informational (top)** | Edukacja, badanie tematu | "ile etapów ma budowa domu", "co to jest SSO", "jak wygląda więźba dachowa" | Pobierz checklistę / Zapisz się do newslettera | Długi poradnik 2000-3000 słów, FAQ, słownik |
| **Commercial (middle)** | Porównanie, ocena opcji | "ceramika vs ytong co lepsze", "kosztorys vs ryczałt różnice", "dobry GW jak wybrać" | Porównaj oferty / Sprawdź portfolio | Artykuł porównawczy 1200-2000 słów, tabele, "vs" |
| **Transactional (bottom)** | Gotowość zakupu | "wycena domu jednorodzinnego mazowieckie", "generalny wykonawca warszawa", "zapytaj o ofertę GW" | Wypełnij formularz / Zadzwoń | Landing page, krótki tekst, wyraźny CTA |

**Reguła mieszania:** każdy artykuł ma JEDNO dominujące tier. Informational article nie powinien mieć transactional CTA "Zamów teraz" — bounce rate rośnie.

### 2.2 Hub-and-spoke — topical authority

Struktura 3 hubów (detaliczna mapa → `blog-cluster-map.md`):

```
Hub 1: "Etapy budowy domu jednorodzinnego" (informational hub)
  └─ Spoke 1.x: artykuły per etap (12 etapów = 12 spoków)

Hub 2: "Koszty budowy domu — breakdown 2026" (commercial/informational hub)
  └─ Spoke 2.x: artykuły per typ pracy/materiał (8+ spoków)

Hub 3: "Jak wybrać dobrego GW" (commercial hub)
  └─ Spoke 3.x: poradniki dla inwestora (7 spoków)
```

Każdy spoke **linkuje do huba** (internal link) i do 2-3 powiązanych spoków. Hub linkuje do wszystkich swoich spoków.

### 2.3 Seasonality PL — sezon budowlany

**Sezon budowlany:** marzec-listopad. **Peak research:** styczeń-marzec (planowanie inwestycji). Szczegóły → `seasonal-calendar-pl.yaml`.

| Faza roczna | Miesiące | Intent dominujący | Focus content |
|---|---|---|---|
| Peak research | Styczeń-marzec | Informational | Koszty, etapy, planowanie budowy |
| Active decision | Kwiecień-czerwiec | Commercial | Porównania, wybór GW, umowy |
| Build engagement | Lipiec-październik | Transactional | Case studies, portfolio, wycena |
| Off-season retention | Listopad-grudzień | Informational (evergreen) | FAQ, słownik, planowanie 2027 |

### 2.4 E-E-A-T markers dla GW

Budowanie autorytetu (construction = YMYL-adjacent):
1. **Experience:** case study z datą, lokalizacją, m², zdjęcia before/after
2. **Expertise:** powołanie na PN-EN (np. "zgodnie z PN-EN 1992 Eurokod 2"), kwalifikacje kierownika budowy
3. **Authoritativeness:** link do wpisu w CEiDG/KRS, referencje od inwestorów
4. **Trustworthiness:** jasny NIP/REGON, adres fizyczny, certyfikaty

Minimum 2 E-E-A-T markery per artykuł. Template w sekcji "Brand voice" poniżej.

---

## 3. Case studies — template (preview)

Pełen template + sample case study → `case-study-template.md`.

### Pola obowiązkowe (metryki zaufania)

| Pole | Format | Przykład |
|---|---|---|
| Data realizacji | Miesiąc RRRR | "Lipiec 2024" |
| Lokalizacja | Powiat/województwo | "Warszawa, woj. mazowieckie" |
| Typ inwestycji | Opis budynku | "Dom jednorodzinny, bryła prosta, 2 kondygnacje" |
| Powierzchnia | m² PUB | "152 m² powierzchni użytkowej" |
| Zakres prac | Stan deweloperski | "Od stanu zerowego (fundamenty) do SSZ" — definicja w `construction-domain-rules` |
| Czas realizacji | Widełki lub konkretny | "14 miesięcy (4/2023 – 5/2024)" |
| Koszt orientacyjny | Widełki, disclaimer obowiązkowy | "290 000 – 310 000 PLN (SSZ), widełki rynkowe — zależą od regionu i specyfikacji" |
| Metodologia | Technologia ścian, dachu | "Ceramika poryzowana, strop Teriva, więźba płatwiowo-kleszczowa" |

### Sekcje case study

1. **Klient i wyzwanie** — profil inwestora (bez danych osobowych), główny problem do rozwiązania
2. **Rozwiązanie** — wybrana technologia z uzasadnieniem (REFERUJ `construction-domain-rules` sekcja 2 dla definicji materiałów)
3. **Realizacja** — przebieg 12 etapów (tabela etap/czas/uwaga)
4. **Rezultat** — metryki: czas realizacji, koszt (widełki), ocena inwestora
5. **Zdjęcia** — placeholders `{{PHOTO_BEFORE_FOUNDATION}}`, `{{PHOTO_WALLS_IN_PROGRESS}}`, `{{PHOTO_FINAL_FRONT}}`
6. **Opinia klienta** — cytat (z opcją `{{TESTIMONIAL_PLACEHOLDER}}` jeśli brak zgody na publikację)

**Anti-pattern:** fake metrics lub konkretna kwota bez disclaimera ("Zbudowaliśmy za 287 543 PLN" — ta kwota oznacza konkretną wycenę Twojej firmy, nie widełki rynkowe).

---

## 4. Koszty m² per typ — long-tail keywords playbook

REFERUJ `construction-domain-rules` sekcja 7 dla aktualnych widełek. Ten skill definiuje STRATEGIĘ artykułów, nie same liczby.

### Top 10 long-tail queries informational (z 30+ pełnej listy)

| Query PL | Intent | Artykuł format | Avg. słów | CTA |
|---|---|---|---|---|
| ile kosztuje fundament płytowy | Informational | H1 query + widełki + faktory | 1800-2200 | Pobierz checklistę |
| ile kosztuje strop teriva | Informational | H1 query + typy + porównanie | 1500-2000 | Zapytaj o wycenę (soft) |
| koszt budowy domu jednorodzinnego 100m2 | Informational | H1 breakdown + tabela etapów | 2500-3000 | Kalkulator kosztów |
| ile kosztuje więźba dachowa płatwiowo-kleszczowa | Informational | H1 + definicja + widełki + alternatywy | 1600-2000 | Pobierz poradnik |
| jak wybrać generalnego wykonawcę | Commercial | H1 checklist 10 punktów | 2000-2500 | Sprawdź nasze portfolio |
| różnice SSO vs SSZ co zawiera | Informational | H1 + tabela + FAQ | 1200-1600 | Powiązane: etapy budowy |
| ceramika vs ytong co lepsze | Commercial | H1 + tabela porównawcza | 1500-2000 | Zapytaj eksperta |
| ile trwa budowa domu jednorodzinnego | Informational | H1 + harmonogram + zmienne | 1800-2200 | Pobierz harmonogram |
| koszt komina systemowego SCHIEDEL | Informational | H1 + typy + widełki | 1200-1600 | Powiązane: etapy dachu |
| pozwolenie na budowę domu 2026 | Informational | H1 + flowchart + kroki | 2000-2500 | Skonsultuj z nami |

### Blueprint artykułu kosztowego (long-tail)

```
H1: "Ile kosztuje [element] — widełki [rok]"
H2: "Co wpływa na koszt [elementu]?"
  H3: Materiały
  H3: Robocizna
  H3: Warunki geotechniczne / specyfika budynku
H2: "Widełki cenowe [elementu] w Polsce [rok]"
  [tabela: region / standard / premium]
H2: "Kiedy [element] jest droższy?"
H2: "FAQ"
  [3-5 pytań z FAQPage schema]
H2: "[element] — jak wybrać wykonawcę?"
CTA: miękki (poradnik/checklista) jeśli informational
```

**Keyword density:** primary keyword 1.0-1.5%, secondary 0.5-1.0%. Nie przekraczaj 2% — Google Helpful Content Guidelines.

---

## 5. Etapy budowy — 12-etapowy przewodnik

### Tabela 12 etapów z content angles

| # | Etap | Typowy czas | Content angle (type artykułów) |
|---|---|---|---|
| 1 | Działka + projekt + pozwolenie | 3-6 mies. | Informational: "jak wybrać działkę", "projekt gotowy vs indywidualny", "pozwolenie na budowę krok po kroku" |
| 2 | Geodezja i wytyczenie | 1-2 tyg. | Informational: "co to jest wytyczenie budynku", "kiedy potrzebna geodezja" |
| 3 | Fundamenty | 3-8 tyg. | Informational+Commercial: "typy fundamentów", "ławy vs płyta", "ile kosztuje fundament" → Spoke 1.2 |
| 4 | Mury parteru | 4-10 tyg. | Commercial: "ceramika vs ytong vs silikat — porównanie", "1-warstwowe vs 2-warstwowe" |
| 5 | Strop nad parterem | 1-3 tyg. | Informational: "ile kosztuje strop teriva", "strop monolityczny vs teriva kiedy" |
| 6 | Mury piętra (jeśli dotyczy) | 3-6 tyg. | Commercial: reprise materiałów, "dom parterowy vs piętrowy — koszty" |
| 7 | Wieniec + strop piętra | 1-3 tyg. | Informational: "po co są wieńce żelbetowe", "jak powstaje wieniec attykowy" |
| 8 | Więźba dachowa | 2-4 tyg. | Commercial+Informational: "płatwiowo-kleszczowa vs kratownica", "ile kosztuje więźba" |
| 9 | Pokrycie dachu | 1-3 tyg. | Commercial: "blachodachówka vs dachówka ceramiczna", "membrana EPDM kiedy" |
| 10 | Stolarka SSZ (okna/drzwi) | 1-2 tyg. | Transactional-adjacent: "jak wybrać okna energooszczędne", "co wchodzi w SSZ" |
| 11 | Instalacje rough-in | 4-8 tyg. | Informational: "co to jest rough-in", "kolejność instalacji elektryka/wod-kan/c.o." |
| 12 | Odbiory + pozwolenie na użytkowanie | 1-4 tyg. | Informational: "jak uzyskać pozwolenie na użytkowanie", "co sprawdza inspektor" |

**Czas łączny (orientacyjny):** SSO: 8-16 miesięcy, SSZ: 12-20 miesięcy od pozwolenia. Disclaimer: zależy od pogody, dostępności wykonawców, decyzji inwestora.

**Referuj `construction-domain-rules` sekcja 1** dla definicji SSO/SSZ i sekcja 2 dla zakresów per etap.

### Hub article "12 etapów budowy domu" — struktura

```
H1: "12 etapów budowy domu jednorodzinnego — kompletny przewodnik [rok]"
H2: "Skrócony harmonogram budowy" [tabela 12 etapów]
H2: "Etap 1: Działka, projekt, pozwolenie na budowę"
  [300-400 słów + link do Spoke 1.1]
H2: "Etap 2: Geodezja i wytyczenie budynku"
  [200-300 słów]
... [każdy etap]
H2: "FAQ — budowa domu krok po kroku"
  [5 pytań FAQPage schema]
H2: "Ile kosztuje budowa domu krok po kroku?"
  [link do Hub 2]
CTA: "Skontaktuj się z nami — bezpłatna wycena" (soft CTA)
```

---

## 6. FAQ — 25 itemów zintegrowanych

Tabela gotowa do implementacji jako `FAQPage` schema (JSON-LD). Format odpowiedzi: max 200 znaków dla PAA box + rozwinięcie w treści.

| # | Pytanie PL | Intencja | Target keyword | Format odpowiedzi |
|---|---|---|---|---|
| 1 | Ile etapów ma budowa domu jednorodzinnego? | Informational | "etapy budowy domu" | Liczba + krótka lista, link do hub |
| 2 | Co to jest SSO i co zawiera? | Informational | "SSO stan surowy otwarty" | Definicja (REFERUJ construction-domain-rules §1) |
| 3 | Czym różni się SSO od SSZ? | Informational | "różnica SSO SSZ" | Tabela 2-kolumnowa |
| 4 | Ile trwa budowa domu do SSZ? | Informational | "ile trwa budowa domu" | Widełki 12-20 mies. + zmienne |
| 5 | Ile kosztuje fundament płytowy? | Informational | "koszt fundament płytowy" | Widełki PLN/m² + disclaimer |
| 6 | Ile kosztuje strop Teriva? | Informational | "ile kosztuje strop teriva" | Widełki PLN/m² + disclaimer |
| 7 | Ile kosztuje więźba dachowa? | Informational | "koszt więźba dachowa" | Widełki PLN/m² rzutu + typy |
| 8 | Co lepsze: ceramika czy ytong? | Commercial | "ceramika vs ytong" | Tabela pros/cons + "zależy od" |
| 9 | Strop Teriva czy monolityczny — kiedy co wybrać? | Commercial | "teriva vs monolityczny" | Decision table |
| 10 | Ile schnie strop Teriva przed dalszymi pracami? | Informational | "kiedy schnie strop teriva" | Konkretny czas (28 dni dla betonu C25/30) |
| 11 | Jakie kominy do domu pasywnego? | Informational | "kominy dom pasywny" | Typy + uzasadnienie |
| 12 | Jak wybrać dobrego generalnego wykonawcę? | Commercial | "jak wybrać GW" | 5 kryteriów + link do Hub 3 |
| 13 | Kosztorys czy ryczałt — co wybrać? | Commercial | "kosztorys vs ryczałt budowa" | Pros/cons per scenariusz |
| 14 | Czy potrzebuję pozwolenia na budowę domu 100m²? | Informational | "pozwolenie na budowę domu" | Zależy od typu (REFERUJ construction-domain-rules §6) |
| 15 | Czy dom parterowy do 70m² można zbudować bez pozwolenia? | Informational | "dom bez pozwolenia 70m2" | Zgłoszenie UPRO — warunki |
| 16 | Jak liczyć powierzchnię użytkową domu? | Informational | "jak liczyć m2 domu" | Norma PN-ISO 9836 + przykład |
| 17 | Co to jest wieniec żelbetowy i po co jest? | Informational | "wieniec żelbetowy co to" | Definicja + funkcja w konstrukcji |
| 18 | Czym różni się więźba płatwiowo-kleszczowa od kratownic? | Informational | "płatwiowo-kleszczowa vs kratownica" | Porównanie ciesielskie vs prefab |
| 19 | Ile waży strop Teriva na 1 m²? | Informational | "waga stropu teriva" | Ciężar własny typ I/II/III |
| 20 | Jak uzyskać pozwolenie na użytkowanie? | Informational | "pozwolenie na użytkowanie" | Krok po kroku (REFERUJ construction-domain-rules §6) |
| 21 | Czym jest umowa o roboty budowlane? | Informational | "umowa o roboty budowlane" | KC 647 — cechy + kiedy stosować (REFERUJ construction-domain-rules §4) |
| 22 | Co powinna zawierać umowa z GW? | Commercial | "umowa z generalnym wykonawcą" | 8 obowiązkowych punktów |
| 23 | Jak długo trwa fundamentowanie domu jednorodzinnego? | Informational | "czas fundamenty dom" | 3-8 tygodni + zmienne |
| 24 | Kiedy zacząć budowę domu — jaka pora roku? | Informational | "kiedy zaczynać budowę domu" | Sezonowość + argumenty |
| 25 | Ile kosztuje budowa domu 150m² w stanie surowym? | Informational | "koszt budowy domu 150m2 SSO SSZ" | Widełki z tabeli (REFERUJ construction-domain-rules §1) + disclaimer |

**Schema implementation:** każde FAQ → `FAQPage` + `Question` + `Answer` JSON-LD. Max 10 pytań w jednym `FAQPage` bloku — Google może nie wyświetlić więcej w SERP.

---

## 7. Blog clustering — 3-tier intent funnel

Detaliczna mapa hubów i spoków → `blog-cluster-map.md`.

### Tier mapping per hub

| Hub | Tier dominujący | Queries avg. volume | Konwersja |
|---|---|---|---|
| Hub 1: Etapy budowy | Informational | Wysokie (10k-100k/mies.) | Niska bezpośrednia — buduje trust |
| Hub 2: Koszty budowy | Informational + Commercial | Wysokie (5k-50k/mies.) | Średnia — generuje leady pre-zakupowe |
| Hub 3: Jak wybrać GW | Commercial | Średnie (1k-10k/mies.) | Wysoka — gotowość zakupu |

### Internal linking guide

- Artykuł informational → linkuje do powiązanego artykułu commercial (np. "Teriva vs monolityczny")
- Artykuł commercial → linkuje do landing page transactional (oferta, formularz)
- Każdy spoke → linkuje do swojego huba (anchor: tytuł huba)
- Hub → linkuje do każdego spoka (anchor: tytuł spoka)

Minimum internal linki per artykuł: 3 (hub + 2 powiązane spoki lub FAQ).

---

## 8. Brand voice — 3 warianty

### Ekspercki (E-E-A-T builder)

> "Fundament płytowy to monolityczna konstrukcja z betonu zbrojonego klasy minimum C25/30, zbrojona siatką dwukierunkową w dwóch warstwach. Stosuje się ją przy gruntach słabonośnych (grunt nośny poniżej 80 kPa) lub wysokim poziomie wody gruntowej, gdzie ławy fundamentowe nie zapewniałyby wymaganej nośności zgodnie z PN-EN 1997 Eurokod 7."

Stosuj: artykuły techniczne, FAQ z definicjami, normy. E-E-A-T marker: powołanie na normę PN-EN.

### Przyjazny (trust builder)

> "Decydując się na fundament płytowy, zyskujesz solidną bazę dla całego domu — dosłownie monolityczną płytę betonu, która równomiernie rozkłada ciężar budynku. To dobre rozwiązanie, gdy grunt na Twojej działce jest miękki lub gdy poziom wody gruntowej jest wysoki. Więcej kosztuje od tradycyjnych ław, ale daje spokój ducha na kolejne dekady."

Stosuj: blogi poradnikowe, artykuły "jak wybrać", case studies dla inwestorów indywidualnych.

### Techniczny (spec sheet)

> "Płyta fundamentowa: beton C25/30 lub C30/37, grubość 25-35 cm (zależna od obciążeń), zbrojenie siatkowe dwukierunkowe Ø10-12 co 15-20 cm (dołem i górą), izolacja termiczna XPS min. 10 cm, folia PE 0,2 mm pod płytą. Szczegóły projektowe per EC2 (PN-EN 1992) i EC7 (PN-EN 1997)."

Stosuj: porównania materiałów, tabele specyfikacji, opisy technologii dla inwestorów z doświadczeniem.

**Reguła:** jeden artykuł = jeden voice. Nie mieszaj eksperta z przyjaznym w obrębie jednego wpisu — disonans brzmi sztucznie.

---

## 9. Sezonowy content calendar PL — preview

Pełna specyfikacja YAML → `seasonal-calendar-pl.yaml`.

| Miesiąc | Faza | Intent | Top topic |
|---|---|---|---|
| Styczeń | Peak research | Informational | "planowanie budowy 2026", "ile kosztuje dom" |
| Luty | Peak research | Informational | "etapy budowy", "wybór projektu", "kosztorys wstępny" |
| Marzec | Active decision | Commercial | "wybór GW", "porównania materiałów" |
| Kwiecień | Active decision | Commercial | "umowa z GW", "kosztorys vs ryczałt" |
| Maj | Active decision | Transactional | "zapytaj o wycenę", "portfolio GW" |
| Czerwiec | Build engagement | Transactional | "case studies", "realizacje" |
| Lipiec | Build engagement | Transactional+Commercial | "realizacje w toku", "wybór materiałów wykończenia" |
| Sierpień | Build engagement | Commercial | "case studies SSZ", "blog z budowy" |
| Wrzesień | Build engagement | Commercial | "case studies finalne", "zdjęcia finalne" |
| Październik | Off-season | Informational | "planowanie na 2027", "FAQ evergreen" |
| Listopad | Off-season | Informational | "słownik budowlany", "FAQ zimowe" |
| Grudzień | Off-season | Informational | "recap roku", "trendy 2027", "planowanie" |

**Cadence rekomendowana:** 2-3 wpisy/tydzień w peak (styczeń-marzec), 1-2/tydzień w sezonie, 1/tydzień off-season.

---

## Anti-patterns

1. **Single-article thinking** — publikacja pojedynczych artykułów bez hub-spoke struktury. Blog bez hubów = brak topical authority → Google nie widzi Cię jako eksperta. Każdy artykuł musi być spiekiem huba lub samym hubem.

2. **Brak seasonality** — publikacja "ile kosztuje fundament" w listopadzie (peak research jest styczeń-marzec). Niesezonowy content nie traci wartości, ale traci okno promocji kiedy zapytania są najwyższe.

3. **Mieszanie intentów** — transactional CTA "Zamów teraz" na informational artykule o etapach budowy = wysoki bounce rate. CTA musi być miękki na top-of-funnel (pobierz checklistę, przeczytaj więcej).

4. **Duplikacja z `construction-domain-rules`** — kopiowanie definicji SSO/SSZ lub tabel stawek do contentu zamiast referencji. Duplikacja łamie DRY i powoduje rozbieżności przy aktualizacji. Zawsze REFERUJ `construction-domain-rules` sekcję 1 (SSO/SSZ) i sekcję 7 (stawki).

5. **external-crm integration** — ZAKAZ. Zero placeholder z nazwami firm operatora lub linków do konkretnych systemów CRM.

6. **Hardkodowane firm-specific case studies** — case study z konkretnymi kwotami Twojej firmy (nie widełkami) = oferta handlowa, nie content. Używaj: `{{CASE_STUDY_COST_FROM}}`, `{{CASE_STUDY_COST_TO}}` lub widełek rynkowych z disclaimerem.

7. **Brand voice mixing** — ekspercki + przyjazny w jednym akapicie. Wybierz jeden voice per artykuł i trzymaj go konsekwentnie.

8. **AI-disclaimers w contencie** — nigdy nie pisz "Ten artykuł został wygenerowany przez AI". Google deranks oznaczony AI-content. Artykuł musi mieć autora-człowieka (imię, doświadczenie) dla E-E-A-T.

9. **Brak internal linking w spoках** — spoke bez linku do huba = izolowany artykuł. Minimum 3 internal linki per artykuł (hub + 2 powiązane spoki lub FAQ).

10. **Widełki bez disclaimera** — każdy koszt w contencie MUSI mieć disclaimer "stawki rynkowe PL [rok], weryfikuj aktualne ceny u lokalnego GW". Brak = potencjalne roszczenia od inwestora który wziął te kwoty za ofertę.

---

## Powiązania

### Downstream — skille i agenty które konsumują ten skill

- **`seo-content-writer`** (, `requires: [content-strategy-construction, construction-domain-rules]`) — primary konsument. Używa sekcji 4 (long-tail blueprint), sekcji 5 (12 etapów), sekcji 6 (FAQ tabela), sekcji 8 (brand voice samples).
- **`seo-strategist`**  — przy planowaniu content roadmap Q1-Q4 używa seasonal-calendar-pl.yaml i blog-cluster-map.md jako framework.

### Upstream (dependencies)

- **`construction-domain-rules`** (, `requires:` mandatory) — jedyne źródło prawdy dla definicji SSO/SSZ, stawek, terminologii, norm. Ten skill REFERUJE, nie duplikuje.

### Boundary z `construction-domain-rules` (E1)

- **TU (content-strategy-construction):** Jak pisać content (struktura, intent, clustering, calendar, brand voice, case study format).
- **construction-domain-rules:** Co to jest SSO/SSZ, jakie są stawki, jak się nazywają elementy budowlane, normy PN-EN, Prawo Budowlane.
- **Reguła:** "Jak ułożyć artykuł o fundamentach?" → TEN skill. "Jakie są typy fundamentów i ile kosztują?" → `construction-domain-rules`.

### Boundary z `seo-fundamentals` / `seo-advanced` / `polish-language-seo` 

- **TU (content-strategy-construction):** Content marketing strategy — struktura, clustering, seasonality, case studies, FAQ, brand voice. Framework do PLANOWANIA treści.
- **seo-fundamentals:** Technical SEO — meta tagi, Schema.org JSON-LD, sitemap, robots.txt, canonical.
- **seo-advanced:** Core Web Vitals, E-E-A-T markery, topical authority scoring, SERP features (featured snippets, PAA).
- **polish-language-seo:** Fleksja polskich keywordów (7 przypadków), polskie SERP behavior, katalogi PL.
- **Reguła:** "Jaka struktura H1/H2/H3 dla artykułu o kosztach?" → TEN skill. "Jaki JSON-LD schema dla FAQPage?" → `seo-fundamentals`. "Ile wariantów fleksyjnych ma 'fundament płytowy'?" → `polish-language-seo`.

### Kiedy update'ować ten skill

- Przy zmianie algorytmu Google (SGE/AI Overview zmienia priorytet intentów) — sekcja 2.1 intent funnel
- Co 12 miesięcy — sekcja 7 tabela monthly topics + `seasonal-calendar-pl.yaml` (cadence i topic fresh)
- Gdy `construction-domain-rules` ma nową wersję — sprawdź czy referowania w sekcjach 3, 4, 5, 6 nadal wskazują właściwe sekcje
- Gdy `seo-content-writer` (E3) dostanie nową wersję z nowym kontraktem wejściowym — sekcja 2.4 E-E-A-T markers

---

## References

1. **Google Helpful Content guidelines** (Search Essentials 2024): developers.google.com/search/docs/fundamentals/creating-helpful-content
2. **Search Engine Journal — Hub and Spoke Content Strategy**: searchenginejournal.com/hub-spoke-content-strategy
3. **Content Marketing Institute — Intent-Based Content Planning**: contentmarketinginstitute.com/intent-based-content
4. **HubSpot — Topic Cluster Model & Pillar Pages**: hubspot.com/pillar-page-topic-cluster
5. **Google Search Central — FAQPage structured data**: developers.google.com/search/docs/appearance/structured-data/faqpage
6. **NN Group — User Intent in Search**: nngroup.com/articles/search-intent
