# Blog Cluster Map — GW PL

3 huby × spoki (21-30 artykułów) + adapter pattern (4. hub regionalny).
Format: markdown nested list. Internal linking guide na końcu.

Każdy spoke = 1 artykuł. Hub = mega-artykuł łączący wszystkie spoki.
Detaliczna strategia intent per spoke → `SKILL.md` sekcja 7 (funnel).
Stawki i definicje terminów → `construction-domain-rules`.

---

## Hub 1: Etapy budowy domu jednorodzinnego — kompletny przewodnik

**URL slug:** `/blog/etapy-budowy-domu-jednorodzinnego`
**Intent:** Informational (top of funnel)
**Target keyword:** "etapy budowy domu jednorodzinnego"
**Format:** Mega-guide 3000-4000 słów + tabela 12 etapów + FAQ 5 pytań
**Internal links outbound:** wszystkie Spoke 1.x (z anchor = tytuł spoka)
**E-E-A-T:** autor = kierownik budowy + referencja PN-EN 1992

### Spoki Hub 1

- **Spoke 1.1 — Działka + projekt + pozwolenie na budowę**
  - URL: `/blog/dzialka-projekt-pozwolenie-budowa-domu`
  - Intent: Informational
  - Keyword: "jak uzyskać pozwolenie na budowę domu"
  - Format: Guide 2000-2500 słów + flowchart decyzyjny
  - Referuj: `construction-domain-rules` sekcja 6 (pozwolenia/zgłoszenia)
  - Internal links: Hub 1 ← + Spoke 1.2 (fundamenty) + FAQ (#14, #15)

- **Spoke 1.2 — Fundamenty — typy, koszty, czas realizacji**
  - URL: `/blog/fundamenty-pod-dom-jednorodzinny`
  - Intent: Informational + Commercial
  - Keyword: "fundamenty pod dom jednorodzinny koszt"
  - Format: Guide 2000-2500 słów + tabela typów + widełki
  - Referuj: `construction-domain-rules` sekcja 2.1 (fundamenty) + sekcja 7 (stawki)
  - Internal links: Hub 1 ← + Hub 2 Spoke 2.1 (koszt fundament) + Spoke 1.3

- **Spoke 1.3 — Mury — ceramika vs silikat vs YTONG — porównanie**
  - URL: `/blog/ceramika-vs-ytong-vs-silikat-mury-porownanie`
  - Intent: Commercial
  - Keyword: "ceramika vs ytong porównanie"
  - Format: Porównanie 1800-2200 słów + tabela pros/cons + tabela kosztów
  - Referuj: `construction-domain-rules` sekcja 2.1 (materiały mury)
  - Internal links: Hub 1 ← + Spoke 1.4 (strop) + Hub 2 Spoke 2.3

- **Spoke 1.4 — Strop — Teriva vs monolityczny — kiedy co wybrać**
  - URL: `/blog/strop-teriva-vs-monolityczny-kiedy-co`
  - Intent: Commercial + Informational
  - Keyword: "strop teriva vs monolityczny"
  - Format: Porównanie 1600-2000 słów + decision table
  - Referuj: `construction-domain-rules` sekcja 2.1 (stropy)
  - Internal links: Hub 1 ← + Spoke 1.2 + Hub 2 Spoke 2.2 + FAQ (#10)

- **Spoke 1.5 — Więźba dachowa — płatwiowo-kleszczowa vs kratownice**
  - URL: `/blog/wiezba-dachowa-platwiowo-kleszczowa-vs-kratownice`
  - Intent: Commercial + Informational
  - Keyword: "więźba dachowa płatwiowo-kleszczowa"
  - Format: Porównanie 1800-2000 słów + kiedy co stosować + koszt
  - Referuj: `construction-domain-rules` sekcja 2.1 (dachy i więźba)
  - Internal links: Hub 1 ← + Spoke 1.6 + Hub 2 Spoke 2.3 + FAQ (#18)

- **Spoke 1.6 — Pokrycie dachu — blachodachówka vs dachówka ceramiczna**
  - URL: `/blog/pokrycie-dachu-blachodachowka-vs-dachowka-ceramiczna`
  - Intent: Commercial
  - Keyword: "blachodachówka vs dachówka ceramiczna"
  - Format: Porównanie 1500-1800 słów + tabela kosztów i trwałości
  - Referuj: `construction-domain-rules` sekcja 2.1 (pokrycia dachowe)
  - Internal links: Hub 1 ← + Spoke 1.5 + Hub 2 Spoke 2.4

- **Spoke 1.7 — SSO vs SSZ — różnice, co zawiera każdy stan**
  - URL: `/blog/sso-vs-ssz-roznice-co-zawiera`
  - Intent: Informational
  - Keyword: "różnica SSO SSZ co zawiera"
  - Format: Explainer 1200-1600 słów + tabela 2-kolumnowa + FAQ
  - Referuj: `construction-domain-rules` sekcja 1 (definicje SSO/SSZ)
  - Internal links: Hub 1 ← + Spoke 1.2 + Hub 3 Spoke 3.2 + FAQ (#2, #3)

- **Spoke 1.8 — Odbiory techniczne i pozwolenie na użytkowanie**
  - URL: `/blog/odbior-techniczny-pozwolenie-uzytkowanie`
  - Intent: Informational
  - Keyword: "pozwolenie na użytkowanie jak uzyskać"
  - Format: Guide 1800-2200 słów + checklist odbioru
  - Referuj: `construction-domain-rules` sekcja 6
  - Internal links: Hub 1 ← + Spoke 1.1 + FAQ (#20)

**Liczba spoków Hub 1: 8**

---

## Hub 2: Koszty budowy domu — kompletny breakdown 2026

**URL slug:** `/blog/koszty-budowy-domu-jednorodzinnego-2026`
**Intent:** Informational + Commercial (middle of funnel)
**Target keyword:** "koszty budowy domu jednorodzinnego 2026"
**Format:** Mega-guide 3000-4000 słów + tabela etapów z widełkami + disclaimer
**Internal links outbound:** wszystkie Spoke 2.x
**E-E-A-T:** autor + disclaimer stawki rynkowe + data aktualizacji
**REFERUJ:** `construction-domain-rules` sekcja 7 dla aktualnych widełek

### Spoki Hub 2

- **Spoke 2.1 — Ile kosztuje fundament płytowy — widełki 2026**
  - URL: `/blog/ile-kosztuje-fundament-plytowy`
  - Intent: Informational
  - Keyword: "ile kosztuje fundament płytowy"
  - Format: Cost breakdown 1800-2200 słów + tabela (region × standard × premium) + CTA miękki
  - Referuj: `construction-domain-rules` sekcja 7 (stawki płyta: 350-550 PLN/m²)
  - Internal links: Hub 2 ← + Hub 1 Spoke 1.2 + Spoke 2.5 + FAQ (#5)

- **Spoke 2.2 — Ile kosztuje strop Teriva — widełki i porównanie**
  - URL: `/blog/ile-kosztuje-strop-teriva`
  - Intent: Informational
  - Keyword: "ile kosztuje strop teriva"
  - Format: Cost breakdown 1600-2000 słów + tabela typu I/II/III
  - Referuj: `construction-domain-rules` sekcja 7 (stawki Teriva: 180-280 PLN/m²)
  - Internal links: Hub 2 ← + Hub 1 Spoke 1.4 + FAQ (#6, #10)

- **Spoke 2.3 — Ile kosztuje więźba dachowa — typy i widełki**
  - URL: `/blog/ile-kosztuje-wiezba-dachowa`
  - Intent: Informational
  - Keyword: "ile kosztuje więźba dachowa"
  - Format: Cost breakdown 1600-2000 słów + tabela per typ
  - Referuj: `construction-domain-rules` sekcja 7 (stawki więźba: 120-200 PLN/m² rzutu)
  - Internal links: Hub 2 ← + Hub 1 Spoke 1.5 + Spoke 2.4 + FAQ (#7)

- **Spoke 2.4 — Ile kosztuje pokrycie dachu — blacha vs dachówka**
  - URL: `/blog/ile-kosztuje-pokrycie-dachu`
  - Intent: Informational
  - Keyword: "koszt pokrycia dachu 2026"
  - Format: Cost breakdown 1500-1800 słów + tabela materiał × cena/m² połaci
  - Referuj: `construction-domain-rules` sekcja 7 (blachodachówka: 80-140, dachówka: 120-220 PLN/m² połaci)
  - Internal links: Hub 2 ← + Hub 1 Spoke 1.6 + Spoke 2.3

- **Spoke 2.5 — Koszt budowy domu 100m² — pełny breakdown**
  - URL: `/blog/koszt-budowy-domu-100m2`
  - Intent: Informational
  - Keyword: "koszt budowy domu 100m2"
  - Format: Mega cost breakdown 2500-3000 słów + tabela per etap + SSO vs SSZ
  - Referuj: `construction-domain-rules` sekcja 1 (tabela SSO/SSZ 100m²) + sekcja 7
  - Internal links: Hub 2 ← + Spoke 2.6 + Hub 1 Spoke 1.7 + FAQ (#25)

- **Spoke 2.6 — Koszt budowy domu 150m² — pełny breakdown**
  - URL: `/blog/koszt-budowy-domu-150m2`
  - Intent: Informational
  - Keyword: "koszt budowy domu 150m2"
  - Format: Mega cost breakdown 2500-3000 słów (analogiczny do 2.5)
  - Referuj: `construction-domain-rules` sekcja 1 (tabela SSO/SSZ 150m²) + sekcja 7
  - Internal links: Hub 2 ← + Spoke 2.5 + Spoke 2.7 + FAQ (#25)

- **Spoke 2.7 — Kosztorys vs ryczałt — co wybrać przy budowie domu**
  - URL: `/blog/kosztorys-vs-ryczalt-budowa-domu`
  - Intent: Commercial
  - Keyword: "kosztorys vs ryczałt budowa domu"
  - Format: Porównanie 1500-1800 słów + tabela pros/cons + decision tree
  - Referuj: `construction-domain-rules` sekcja 4 (typy umów)
  - Internal links: Hub 2 ← + Hub 3 Spoke 3.3 + FAQ (#13)

- **Spoke 2.8 — Ile kosztuje komin systemowy — SCHIEDEL i alternatywy**
  - URL: `/blog/ile-kosztuje-komin-systemowy`
  - Intent: Informational
  - Keyword: "komin systemowy koszt SCHIEDEL"
  - Format: Cost breakdown 1200-1600 słów + tabela typ × mb
  - Referuj: `construction-domain-rules` sekcja 7 (stawki komin: 600-1200 PLN/mb) + sekcja 2.1 (typy kominów)
  - Internal links: Hub 2 ← + Hub 1 Spoke 1.7 + FAQ (#11)

**Liczba spoków Hub 2: 8**

---

## Hub 3: Jak wybrać dobrego generalnego wykonawcę — poradnik dla inwestora

**URL slug:** `/blog/jak-wybrac-generalnego-wykonawce`
**Intent:** Commercial (middle of funnel)
**Target keyword:** "jak wybrać generalnego wykonawcę"
**Format:** Guide 2500-3000 słów + 10-punktowa checklista + FAQ
**Internal links outbound:** wszystkie Spoke 3.x

### Spoki Hub 3

- **Spoke 3.1 — 10 sygnałów dobrego generalnego wykonawcy**
  - URL: `/blog/sygnaly-dobrego-generalnego-wykonawcy`
  - Intent: Commercial
  - Keyword: "cechy dobrego generalnego wykonawcy"
  - Format: Listicle 1800-2200 słów + rozwinięcie każdego punktu
  - Internal links: Hub 3 ← + Spoke 3.2 + Spoke 3.3 + case studies

- **Spoke 3.2 — Umowa o roboty budowlane — co powinna zawierać**
  - URL: `/blog/umowa-o-roboty-budowlane-co-zawierac`
  - Intent: Commercial
  - Keyword: "umowa o roboty budowlane co powinna zawierać"
  - Format: Guide 2000-2500 słów + 8 obowiązkowych punktów + disclaimer prawny
  - Referuj: `construction-domain-rules` sekcja 4 (umowy KC 647)
  - Internal links: Hub 3 ← + Spoke 3.3 + FAQ (#21, #22)

- **Spoke 3.3 — Kosztorys vs ryczałt — różnice dla inwestora**
  - URL: `/blog/kosztorys-vs-ryczalt-dla-inwestora` (lub cross-link do Hub 2 Spoke 2.7)
  - Intent: Commercial
  - Keyword: "kosztorys ryczałt różnice inwestor"
  - Format: Short guide 1200-1500 słów lub redirect do Spoke 2.7 z anchor
  - Internal links: Hub 3 ← + Spoke 3.2 + Hub 2 Spoke 2.7

- **Spoke 3.4 — Harmonogram budowy — jak go negocjować z GW**
  - URL: `/blog/harmonogram-budowy-jak-negocjowac`
  - Intent: Commercial
  - Keyword: "harmonogram budowy domu jak negocjować"
  - Format: Guide 1500-1800 słów + przykładowy harmonogram tabelaryczny
  - Internal links: Hub 3 ← + Hub 1 (wszystkie etapy) + Spoke 3.2

- **Spoke 3.5 — GW vs budowa systemem gospodarczym — co się opłaca**
  - URL: `/blog/gw-vs-system-gospodarczy-co-sie-oplaca`
  - Intent: Commercial
  - Keyword: "budowa systemem gospodarczym vs generalny wykonawca"
  - Format: Porównanie 1800-2200 słów + tabela pros/cons + kalkulacja
  - Internal links: Hub 3 ← + Hub 2 Spoke 2.5 + Spoke 3.1

- **Spoke 3.6 — Referencje i opinie klientów — jak weryfikować GW**
  - URL: `/blog/jak-weryfikowac-referencje-generalnego-wykonawcy`
  - Intent: Commercial
  - Keyword: "referencje generalny wykonawca jak sprawdzić"
  - Format: Guide 1400-1800 słów + checklist weryfikacji
  - Internal links: Hub 3 ← + case studies (Hub 1 i Hub 2 powiązane) + Spoke 3.1

- **Spoke 3.7 — Gwarancja i rękojmia przy umowie z GW — prawa inwestora**
  - URL: `/blog/gwarancja-rekojmia-umowa-gw-prawa-inwestora`
  - Intent: Commercial
  - Keyword: "gwarancja budowa domu prawa inwestora"
  - Format: Guide 1600-2000 słów + disclaimer prawny
  - Referuj: `construction-domain-rules` sekcja 4 (umowy KC, rękojmia 2 lata)
  - Internal links: Hub 3 ← + Spoke 3.2 + FAQ (#22)

**Liczba spoków Hub 3: 7**

---

## Adapter pattern — Hub 4 (regionalny, project-specific)

Ten cluster map obejmuje 3 huby generyczne. Dla konkretnego projektu GW dodaj 4. hub regionalny:

**Hub 4: Generalny wykonawca [REGION] — portfolio i realizacje**

```
Hub 4 slug: /blog/generalny-wykonawca-[region]-portfolio
Intent: Transactional (bottom of funnel)
Target keyword: "generalny wykonawca [MIASTO/WOJEWÓDZTWO]"

Spoki Hub 4 (project-specific — wypełnij per projekt):
- Spoke 4.1: "Realizacje [ROK] — domy jednorodzinne [REGION]"
- Spoke 4.2: "Portfolio — SSZ [REGION]" (galeria + case studies)
- Spoke 4.3: "Wycena budowy domu [REGION] — jak to u nas działa"
- Spoke 4.4: "Opinie klientów [REGION] — co mówią inwestorzy"
- Spoke 4.5: "O nas — firma GW [REGION], doświadczenie i certyfikaty"
```

**Kiedy używać adaptera:**
- Masz projekt konkretnej firmy GW z geograficznym scope (np. "GW mazowieckie")
- Chcesz zbudować local SEO obok topical authority
- `regional-seo-poland` skill definiuje słownik województw/powiatów + NAP consistency dla Hub 4

**Nie wbudowuj Hub 4 do tego skilla** — jest project-specific i zawiera dane firmy.

---

## Internal Linking Guide

### Zasady ogólne

1. **Hub → wszystkie spoki:** Hub artykuł ma sekcję "Powiązane artykuły" lub inline linki do każdego spoka
2. **Spoke → swój hub:** Każdy spoke ma w treści (nie tylko stopce) naturalny link do huba. Anchor text = tytuł huba lub jego fragment
3. **Spoke → 2-3 powiązane spoki:** W obrębie tego samego huba lub cross-hub jeśli content powiązany tematycznie
4. **Spoke kosztowy → definicja:** Artykuły z Hub 2 linkują do odpowiedniego spoke w Hub 1 gdzie jest kontekst etapu
5. **Minimum 3 internal linki per artykuł** (hub + 2 spoki)

### Przykłady dobrych anchor tekstów

| Zamiast | Użyj |
|---|---|
| "kliknij tutaj" | "kompletny przewodnik po etapach budowy" |
| "więcej informacji" | "ile kosztuje fundament płytowy — widełki 2026" |
| "sprawdź" | "różnice SSO vs SSZ — tabela porównawcza" |
| "dowiedz się" | "jak wybrać dobrego generalnego wykonawcę" |

### Cross-hub linking matrix

| Z | Do | Anchor sugestia |
|---|---|---|
| Hub 1 Spoke 1.2 (fundamenty) | Hub 2 Spoke 2.1 (koszt fundament) | "koszt fundamentu płytowego — widełki" |
| Hub 2 Spoke 2.5 (koszt 100m²) | Hub 1 (12 etapów hub) | "etapy budowy domu — co wchodzi w każdy koszt" |
| Hub 3 Spoke 3.1 (dobry GW) | Hub 1 Spoke 1.7 (SSO vs SSZ) | "sprawdź czy GW poprawnie definiuje SSO i SSZ" |
| Case study | Hub 1 (12 etapów) | "na której etapie byliśmy — harmonogram budowy" |
| FAQ any | Powiązany spoke | [tytuł spoka jako anchor] |

### Schema.org dla clustera

Każdy hub i spoke powinien mieć:
- `Article` schema (title, author, datePublished, dateModified)
- `BreadcrumbList`: Strona główna > Blog > [Hub] > [Spoke]
- Spoki z pytaniami: `FAQPage` dla sekcji FAQ
- Hub artykuły: opcjonalnie `HowTo` dla przewodników etapowych

Szczegóły implementacji Schema.org → `seo-fundamentals` skill.

---

## Podsumowanie klastra

| Hub | Spoki | Intent główny | Artykułów razem |
|---|---|---|---|
| Hub 1: Etapy budowy | 8 (Spoke 1.1-1.8) | Informational | 9 (hub + 8 spoków) |
| Hub 2: Koszty budowy | 8 (Spoke 2.1-2.8) | Informational + Commercial | 9 (hub + 8 spoków) |
| Hub 3: Jak wybrać GW | 7 (Spoke 3.1-3.7) | Commercial | 8 (hub + 7 spoków) |
| Hub 4: Regionalny | ~5 (project-specific) | Transactional | ~6 (adapter) |
| **RAZEM (bez Hub 4)** | **23 spoki** | **mieszany** | **26 artykułów** |

26 artykułów = fundament topical authority dla domeny GW. Publikacja 2-3/tydzień → 10-13 tygodni do kompletnego klastra (Peak Research → Active Decision).
