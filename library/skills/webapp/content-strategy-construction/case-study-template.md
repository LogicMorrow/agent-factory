# Case Study Template — GW PL

Pełen template case study dla firmy generalnego wykonawcy. Format markdown (MDX-compatible).
Pola `{{PLACEHOLDER}}` = wymień przed publikacją.

---

## Jak używać tego template

1. Skopiuj sekcje poniżej do nowego pliku `content/case-studies/YYYY-MM-slug.mdx`
2. Uzupełnij pola `{{...}}` realnymi danymi inwestycji
3. Użyj widełek dla kosztów (NIE konkretna kwota) — patrz sekcja "Koszt"
4. Zdjęcia: placeholdery, zastąp linkami z CDN projektu
5. Anti-pattern: fake metrics — sekcja na dole

---

## Frontmatter case study

```yaml
---
title: "{{CASE_STUDY_TITLE}}"
slug: "{{SLUG}}"
date: "{{YYYY-MM-DD}}"
category: "case-study"
location:
  voivodeship: "{{WOJEWÓDZTWO}}"
  county: "{{POWIAT}}"
  city: "{{MIASTO}}"
building:
  type: "dom-jednorodzinny"  # | blizniak | budynek-gospodarczy | hala
  area_m2: {{M2_PUB}}
  floors: {{LICZBA_KONDYGNACJI}}
  technology_walls: "{{TECHNOLOGIA_SCIAN}}"  # ceramika-poryzowana | silikat | ytong
  technology_roof: "{{TECHNOLOGIA_DACHU}}"   # blachodachowka | dachowka-ceramiczna | blacha-plaska
scope: "{{ZAKRES}}"  # sso | ssz | stan-deweloperski | pod-klucz
timeline:
  start: "{{YYYY-MM}}"
  end: "{{YYYY-MM}}"
  duration_months: {{LICZBA}}
cost_range:
  from: {{PLN_MIN}}
  to: {{PLN_MAX}}
  currency: "PLN"
  disclaimer: "Widełki rynkowe PL — zależą od regionu, specyfikacji i czasu realizacji"
schema_type: "Article"
author: "{{IMIE_NAZWISKO_AUTORA}}"
author_experience: "{{LATA_DOSWIADCZENIA}} lat doświadczenia w budownictwie"
tags: ["case-study", "dom-jednorodzinny", "{{WOJEWÓDZTWO}}", "{{TECHNOLOGIA_SCIAN}}"]
---
```

---

## Treść case study

### Klient i wyzwanie

**Data realizacji:** {{MIESIĄC_SŁOWNIE}} {{YYYY}}
**Lokalizacja:** {{MIEJSCOWOŚĆ}}, {{WOJEWÓDZTWO}}
**Inwestycja:** {{TYP_BUDYNKU}}, {{M2}} m² powierzchni użytkowej

{{OPIS_KLIENTA_BEZ_DANYCH_OSOBOWYCH}}

Przykład: *"Rodzina z dwójką dzieci szukała generalnego wykonawcy do budowy domu jednorodzinnego pod Warszawą. Kluczowe oczekiwania: stały harmonogram, transparentna komunikacja i dotrzymanie widełek budżetowych uzgodnionych na etapie kosztorysu."*

**Główne wyzwania projektu:**
- {{WYZWANIE_1}} (np. "Grunt z wysoko zalegającą wodą gruntową — wymagał płyty fundamentowej zamiast standardowych ław")
- {{WYZWANIE_2}} (np. "Ograniczony budżet przy standardzie ceramiki poryzowanej — optymalizacja przez wybór jednej warstwy z ociepleniem")
- {{WYZWANIE_3}} (opcjonalnie)

---

### Rozwiązanie techniczne

**Wybrana technologia:**
- **Fundamenty:** {{TYP_FUNDAMENTU}} (np. płyta fundamentowa C25/30, gr. 30 cm, XPS 12 cm) — wybór uzasadniony warunkami gruntowymi. Definicja typów fundamentów → `construction-domain-rules` sekcja 2.1.
- **Ściany:** {{MATERIAŁ_ŚCIAN}} (np. ceramika poryzowana Porotherm 25 P+W, technologia 2-warstwowa ze styropianem 15 cm)
- **Strop:** {{TYP_STROPU}} (np. Teriva I, z zabetonowaniem i wieńcami żelbetowymi 25×25 cm)
- **Więźba:** {{TYP_WIEZBY}} (np. płatwiowo-kleszczowa, drewno C24, impregnowane)
- **Dach:** {{POKRYCIE}} (np. blachodachówka stalowa, kolor antracyt, folia niskooporna + łaty 4×6)
- **Stolarka zewnętrzna (SSZ):** {{STOLARKA}} (np. okna PVC trzyszybowe, drzwi zewnętrzne antywłamaniowe RC2)

**Zakres prac:** {{ZAKRES_SŁOWNIE}} — od {{ETAP_OD}} do {{ETAP_DO}}.
Definicje stanów deweloperskich (SSO/SSZ) → `construction-domain-rules` sekcja 1.

**Dlaczego ta technologia:**
{{UZASADNIENIE_WYBORU}} (np. "Płyta fundamentowa ze względu na wysoki poziom wód gruntowych (0,8 m poniżej terenu). Ceramika poryzowana dla dobrej akumulacji cieplnej i oddychalności ścian. Więźba płatwiowo-kleszczowa — dom ma 11,5 m szerokości, kratownice byłyby droższe.")

---

### Realizacja — harmonogram

| Etap | Zakres | Czas realizacji | Uwagi |
|---|---|---|---|
| 1 | Geodezja i wytyczenie | {{CZAS}} | — |
| 2 | Fundamenty ({{TYP}}) | {{CZAS}} | {{UWAGA}} |
| 3 | Mury parteru | {{CZAS}} | {{MATERIAŁ}} |
| 4 | Strop nad parterem | {{CZAS}} | {{TYP}} |
| 5 | Mury piętra | {{CZAS}} / n.d. | — |
| 6 | Wieniec + strop piętra | {{CZAS}} / n.d. | — |
| 7 | Więźba dachowa | {{CZAS}} | {{TYP_WIĘŻBY}} |
| 8 | Pokrycie dachu | {{CZAS}} | {{POKRYCIE}} |
| 9 | Stolarka zewnętrzna | {{CZAS}} | Okna + drzwi |
| 10 | Instalacje rough-in | {{CZAS}} | Elektryka, wod-kan, c.o. |
| 11 | Odbiory techniczne | {{CZAS}} | Kierownik budowy |
| 12 | Pozwolenie na użytkowanie | {{CZAS}} | Lub zawiadomienie o zakończeniu |

**Łączny czas realizacji:** {{MIESIĘCY}} miesięcy ({{MIESIĄC_START}} {{ROKU_START}} – {{MIESIĄC_KONIEC}} {{ROKU_KONIEC}})

---

### Koszt

> **DISCLAIMER:** Podane widełki to orientacyjne koszty rynkowe PL {{ROK}} dla porównywalnego standardu. Faktyczne ceny zależą od regionu, aktualnych cen materiałów, specyfikacji i czasu realizacji. Nie są ofertą handlową. Skonsultuj indywidualną wycenę z GW.

| Etap / Zakres | Widełki kosztów | Uwagi |
|---|---|---|
| Fundamenty | {{PLN_MIN}} – {{PLN_MAX}} PLN | Per m² lub lump-sum |
| Mury + stropy + wieńce | {{PLN_MIN}} – {{PLN_MAX}} PLN | Robocizna + materiał |
| Więźba + dach | {{PLN_MIN}} – {{PLN_MAX}} PLN | Robocizna + materiał |
| Stolarka zewnętrzna | {{PLN_MIN}} – {{PLN_MAX}} PLN | Okna + drzwi |
| **Razem (zakres {{ZAKRES}})** | **{{PLN_TOTAL_MIN}} – {{PLN_TOTAL_MAX}} PLN** | **Widełki rynkowe** |

Rynkowe widełki per etap → `construction-domain-rules` sekcja 7.

---

### Rezultat

- **Czas realizacji:** {{MIESIĘCY}} miesięcy — {{OCENA}} harmonogramu (dotrzymany / skrócony o X tyg. / opóźniony z powodu {{PRZYCZYNA}})
- **Koszt:** w granicach ustalonych widełek budżetowych
- **Stan odbioru:** {{ZAKRES}} — odbiór protokołem z kierownikiem budowy
- **Uwagi jakościowe:** {{UWAGI}} (np. "Brak usterek na etapie odbioru fundamentów i murów. Jedna poprawka przy uszczelnieniu okien — usunięta w ciągu 48h.")

---

### Zdjęcia

> Zdjęcia zastąp linkami z CDN lub systemu CMS projektu.

```
{{PHOTO_BEFORE_FOUNDATION}} — teren przed pracami
{{PHOTO_FOUNDATION_DONE}} — fundamenty po zakończeniu
{{PHOTO_WALLS_FIRST_FLOOR}} — mury parteru w trakcie
{{PHOTO_ROOF_STRUCTURE}} — więźba dachowa
{{PHOTO_ROOF_DONE}} — pokrycie dachu
{{PHOTO_WINDOWS_INSTALLED}} — stolarka zewnętrzna
{{PHOTO_FINAL_FRONT}} — budynek finalny od frontu
{{PHOTO_FINAL_BACK}} — budynek finalny od ogrodu
```

Alt-text pattern: `"[typ budynku] [lokalizacja] — [etap], realizacja GW {{NAZWA_FIRMY}} {{ROK}}"`

---

### Opinia klienta

> *"{{CYTAT_DOSŁOWNY_LUB_PLACEHOLDER}}"*
>
> — {{IMIĘ}}, {{MIEJSCOWOŚĆ}} {{ROK}}

Jeśli brak zgody na publikację: `{{TESTIMONIAL_PLACEHOLDER}}` — wyświetlaj blok "Opinia dostępna na prośbę" lub pomiń sekcję.

---

## Sample case study — fikcyjny, realistyczny PL

> Poniżej kompletnie wypełniony przykład. Dane fikcyjne, plausible dla rynku mazowieckiego 2024.

---

### Dom jednorodzinny 152 m² — SSZ, gmina Piaseczno k. Warszawy

**Data realizacji:** Maj 2024
**Lokalizacja:** Piaseczno, woj. mazowieckie
**Inwestycja:** Dom jednorodzinny parterowy z poddaszem użytkowym, 152 m² PUB

Inwestorzy planowali budowę od 3 lat — projekt gotowy adaptowany do działki 1200 m². Kluczowe oczekiwanie: budowa do stanu zamkniętego (SSZ) przed końcem maja 2024 (dzieci szkolne, przeprowadzka w czerwcu).

**Wyzwania:**
- Grunt częściowo nienośny (fill w zachodniej części działki) — wymagał wymiany gruntu lub płyty
- Projekt zakładał dach czterospadowy — więźba niestandardowa, wymagała indywidualnego projektu ciesielskiego
- Termin napięty: 13 miesięcy od wmurowania kamienia węgielnego

**Technologia:**
- **Fundamenty:** Ławy żelbetowe C25/30 + częściowa wymiana gruntu (2,5 m³ w narożniku NW), wieniec fundamentowy
- **Ściany:** Ceramika poryzowana Porotherm 25 P+W, technologia 2-warstwowa, ocieplenie EPS 15 cm
- **Strop:** Teriva I nad parterem, monolityczny nad garażem (nieregularny układ)
- **Więźba:** Płatwiowo-kleszczowa, drewno C24, projekt ciesielski AGPD, impregnacja ciśnieniowa
- **Dach:** Dachówka ceramiczna Creaton Kapstadt, kolor grafitowy, folia niskooporna + kontrłaty + łaty 4×6
- **Stolarka:** Okna PVC trzyszybowe Uw=0,9, drzwi zewnętrzne Hormann RC2

**Zakres:** Fundamenty → SSZ (etapy 1-10 z 12-etapowego planu)

| Etap | Czas | Uwagi |
|---|---|---|
| Geodezja + wytyczenie | 1 tydzień | kwiecień 2023 |
| Fundamenty (ławy + wymiana gruntu) | 5 tygodni | kwiecień-maj 2023 |
| Mury parteru | 7 tygodni | maj-lipiec 2023 |
| Strop Teriva + monolit garażu | 3 tygodnie | lipiec 2023 |
| Mury piętra (poddasze) | 6 tygodni | sierpień-wrzesień 2023 |
| Wieniec attykowy | 1 tydzień | wrzesień 2023 |
| Więźba dachowa | 3 tygodnie | październik 2023 |
| Pokrycie dachu | 2 tygodnie | październik-listopad 2023 |
| Przerwa zimowa | 10 tygodni | grudzień 2023 – luty 2024 |
| Stolarka zewnętrzna | 2 tygodnie | marzec 2024 |
| Odbiory + dokumentacja | 3 tygodnie | kwiecień-maj 2024 |

**Łączny czas realizacji:** 13 miesięcy (kwiecień 2023 – maj 2024)

**Koszt:**

> DISCLAIMER: Widełki rynkowe PL 2023-2024 dla porównywalnego standardu, woj. mazowieckie. Nie są ofertą handlową.

| Zakres | Widełki |
|---|---|
| Fundamenty (ławy + wymiana gruntu) | 45 000 – 60 000 PLN |
| Mury + stropy + wieńce | 110 000 – 140 000 PLN |
| Więźba dachowa (niestandardowa) | 35 000 – 45 000 PLN |
| Pokrycie dachu (dachówka ceramiczna) | 40 000 – 55 000 PLN |
| Stolarka zewnętrzna | 55 000 – 70 000 PLN |
| **Razem (SSZ, 152 m²)** | **285 000 – 370 000 PLN** |

**Rezultat:** Termin dotrzymany — odbiór SSZ 15 maja 2024. Zero usterek na protokole odbioru murów i dachu. Jedna usterka przy stolarce (uszczelnienie narożnika NE) — usunięta w 24h przez wykonawcę stolarki.

**Opinia:**
> *"Harmonogram był napięty i wiedzieliśmy o tym od początku. Ekipa dotrzymała słowa — w maju 2024 mieliśmy dom zamknięty, co było dla nas kluczowe ze względu na przeprowadzkę. Komunikacja przebiegała sprawnie, każdy etap był jasno raportowany."*
>
> — Inwestor, Piaseczno 2024

---

## Anti-pattern: fake metrics

**Nie rób tak:**
- "Zbudowaliśmy ten dom za 287 543 PLN" — to konkretna kwota Twojej firmy, nie widełki rynkowe
- "Klient był zachwycony — 5 gwiazdek" bez żadnego cytatu lub źródła
- "Budowa zajęła dokładnie 12 miesięcy i 3 dni" — precision theater bez wartości dla czytelnika
- Zdjęcia z Google Images jako before/after

**Rób tak:**
- Widełki kosztów z disclaimerem
- Cytat klienta z imieniem i miejscowością (lub placeholder z wyjaśnieniem)
- Konkretny czas z kontekstem (sezon, przerwy zimowe)
- Własne zdjęcia z budowy — E-E-A-T Evidence wymaga autentycznych materiałów
