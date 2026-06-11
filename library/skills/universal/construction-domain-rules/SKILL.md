---
name: construction-domain-rules
description: Wiedza branżowa generyczna GW PL — stany deweloperskie (SSO/SSZ), zakresy prac GW (fundamenty/mury/stropy/wieńce/kominy/dachy + więźba), słownik branżowy 60-80 terminów PL, typy umów (zlecenie/dzieło/B2B/roboty budowlane), normy PN-EN (Eurokod EC0-EC6 + PN-EN 206), pozwolenia/zgłoszenia (Prawo Budowlane 2026), stawki rynkowe PL 2024-2026 widełki. Konsumowany przez seo-content-writer, calculator-builder. Domy jednorodzinne/bliźniaki do 500m² + budynki gospodarcze do kilkuset m². Uruchamiaj gdy content agent pisze o budownictwie GW i potrzebuje poprawnej terminologii PL, definicji SSO/SSZ, zakresów prac lub ram prawnych.
version: 1.0.0
compatible_with: [universal]
tags: [domain, construction, gw, poland, building]
requires: []
token_cost: medium
distribution: library/skills/universal/
last_updated: 2026-05-11
last_reviewed: 2026-05-11
valid_until: 2027-05-11
---

# construction-domain-rules

Jedno źródło prawdy o domenie budowlanej GW PL. Scope: domy jednorodzinne i bliźniaki do 500m² + budynki gospodarcze (garaże, hale, zakłady) do kilkuset m². NIE obejmuje: deweloperki wieloapartamentowej, infrastruktury drogowej, mostów.

Szczegóły w plikach towarzyszących:
- `slownik-branzowy.md` — 65 terminów PL z definicjami, synonimami, EN equivalent (selektywnie)
- `normy-pn-en.md` — Eurokod EC0-EC6 + PN-EN 206 + quick-reference element→norma
- `pozwolenia-vs-zgloszenia.md` — flowchart decyzyjny + 5 scenariuszy + 3 anti-patterns

---

## 1. Stany deweloperskie SSO/SSZ

### Definicje standardowe PL

| Stan | Co zawiera | Czego NIE zawiera |
|---|---|---|
| **SSO (Stan Surowy Otwarty)** | Fundamenty + mury nośne + stropy + wieńce + więźba dachowa + pokrycie wstępne (papa/folia wstępnego krycia) | Okna, drzwi, kominy wykończone, docelowe pokrycie dachu |
| **SSZ (Stan Surowy Zamknięty)** | SSO + okna zewnętrzne + drzwi zewnętrzne + dach pokryty docelowo + kominy ukończone | Okna/drzwi wewnętrzne, tynki, posadzki, instalacje |
| **Stan deweloperski** | SSZ + tynki wewnętrzne + posadzki (wylewka) + instalacje (elektryka rough-in, wod-kan, c.o.) | Wykończenie wnętrz (płytki, podłogi, malowanie, drzwi wewnętrzne) |
| **Stan pod klucz** | Pełne wykończenie + odbiory techniczne + zdolność do zamieszkania | — |

**Kluczowe rozróżnienie SSO vs SSZ:** Jedyną różnicą są okna/drzwi ZEWNĘTRZNE, dach pokryty docelowo oraz kominy ukończone. W SSO dach jest zabezpieczony wstępnie (papa lub folia), ale nie ma docelowego pokrycia (dachówka, blacha).

**Uwaga dla contentu:** Definicja SSO/SSZ jest standardem polskim. Unikaj sformułowań regionalnych ("u nas SSO znaczy...") — stosuj definicję powyżej jako jedyne źródło prawdy.

### Typowe stawki za etap (widełki rynkowe PL 2024-2026)

| Stan | Dom 100m² | Dom 150m² | Dom 200m² |
|---|---|---|---|
| SSO | 150 000 – 220 000 PLN | 200 000 – 300 000 PLN | 260 000 – 380 000 PLN |
| SSZ | 220 000 – 320 000 PLN | 300 000 – 430 000 PLN | 390 000 – 570 000 PLN |

> **DISCLAIMER:** Stawki są widełkami rynkowymi PL 2024-2026 dla orientacji. Faktyczne ceny zależą od regionu, materiałów, technologii i czasu realizacji. Weryfikuj aktualne stawki przed wyceną — skonsultuj się z lokalnym GW lub kosztorysantem.

---

## 2. Zakresy prac GW

### 2.1 Domy jednorodzinne i bliźniaki

#### Fundamenty

| Typ | Opis | Zastosowanie |
|---|---|---|
| Ławy fundamentowe | Poziomy element żelbetowy pod ścianą nośną | Grunty nośne, standard budownictwa jednorodzinnego |
| Płyta fundamentowa | Monolityczna żelbetowa płyta pod całym budynkiem | Grunty słabe, wysoki poziom wody gruntowej, domy pasywne |
| Stopy fundamentowe | Punktowe elementy żelbetowe pod słupami | Konstrukcje słupowe, budynki gospodarcze |
| Wieniec fundamentowy | Obwodowy element żelbetowy spinający ławy | Uzupełnienie ław, zawsze razem z ławami |

#### Mury

| Materiał | Producenci przykładowi | Warianty | Uwagi |
|---|---|---|---|
| Ceramika poryzowana | Porotherm (Wienerberger), MAX | Bloczki 25-44 cm, 1-warstwowe lub 2-warstwowe z ociepleniem | Dobra akumulacja ciepła, paroprzepuszczalna |
| Silikat | SILKA (H+H) | Bloczki i pustaki, wymagają ocieplenia | Wysoka gęstość, dobra akustyka |
| Beton komórkowy (ytong) | YTONG (Xella), H+H Solbet, SOLBET | Bloczki 24-48 cm, odmiany: PP2-PP6 | Dobra izolacyjność cieplna, lekki |
| Pustak żwirobetonowy | ALFA, BK | Standardowe pustaki | Najtańszy materiał, wymaga ocieplenia |

Technologie murowania: **1-warstwowe** (ściana nośna + izolacja termiczna jako jeden materiał, np. ytong 36 cm) vs **2-warstwowe** (ściana nośna + osobna warstwa ocieplenia styropian/wełna mineralna).

#### Stropy

| Typ stropu | Opis | Zastosowanie |
|---|---|---|
| Teriva I/II/III | Belki żelbetowe + wypełnienie bloczkami ceramicznymi lub betonowymi | Standard budownictwa jednorodzinnego |
| Gęstożebrowy FERT | Belki żelbetowe lub sprężone + wypełnienie | Większe rozpiętości, alternatywa Teriva |
| Monolityczny żelbet | Płyta żelbetowa wylewana na deskowaniu | Duże rozpiętości, nieregularne układy, garaże podziemne |
| Prefabrykowany HC (Hollow Core) | Płyty kanałowe prefabrykowane | Szybki montaż, hale, budynki gospodarcze |
| Drewniany belkowy | Belki drewniane + deski/ślepa podłoga | Budynki drewniane, renowacje zabytkowe |

#### Wieńce

Wieńce żelbetowe — obwodowe elementy spinające konstrukcję. Typy:
- **Fundamentowy** — w poziomie posadowienia, łączy ławy fundamentowe
- **Kondygnacyjny** — nad każdą kondygnacją, pod stropem lub nad oknem (podokienny/nadokienny)
- **Attykowy** — w poziomie oparcia więźby dachowej

Zbrojenie: stal A-IIIN (B500SP), minimum 4 pręty Ø12, strzemiona Ø6 co 20-25 cm.

#### Kominy

| Typ | Producenci przykładowi | Zastosowanie |
|---|---|---|
| Ceramika wkład + bloczek | SCHIEDEL, JEREMIAS, TONA | Kotły na paliwa stałe (węgiel, pellet, drewno), kominki |
| Systemowe blacha kwasoodporna (flex) | SCHIEDEL Flex, lokalni dystrybutorzy | Gazowe i olejowe, renowacja starych kominów |
| Komin 3-w-1 (wentylacja + spaliny + powietrze) | SCHIEDEL Rondo, JEREMIAS | Kotły kondensacyjne, centrale wentylacyjne |

#### Dachy i więźba

| Typ więźby | Opis | Zastosowanie |
|---|---|---|
| Płatwiowo-kleszczowa | Krokwie oparte na płatwiach + jętki/kleszcze poziome | Domy >10 m szerokości, rozpiętości 10-16 m |
| Krokwiowa | Krokwie opierają się bezpośrednio na wieńcu i kalenicy | Domy do 10 m szerokości, proste dachy 2-spadowe |
| Kratownice prefabrykowane drewniane (wiązary) | Fabryczne wiązary z MDF-płatkami | Szybki montaż, powtarzalne geometrie, hale |
| Dach płaski | Strop żelbetowy + izolacja + membrana | Budownictwo nowoczesne, biura, hale |

Elementy więźby: krokiew, jętka, kleszcz, płatew, podwalina, murłata, kalenica, kosz, okap. Szczegóły w `slownik-branzowy.md`.

Pokrycia dachowe: dachówka ceramiczna/cementowa, blachodachówka, blacha płaska (tytan-cynk, miedź, stal powlekana), papa termozgrzewalna, membrana EPDM (dachy płaskie).

### 2.2 Budynki gospodarcze (garaże, hale, zakłady)

Różnice kluczowe względem domów jednorodzinnych:

| Element | Dom jednorodzinny | Budynek gospodarczy |
|---|---|---|
| Fundamenty | Ławy + wieniec (standard) | Stopy fundamentowe (częściej), ławy pod ściany |
| Konstrukcja | Mury ceramiczne/silikat/ytong | Stal (słupy + rygiel C) popularna — norma EC3 |
| Kominy wewnętrzne | Tak (kominki, kotły) | Rzadko (zewnętrzne rury dymowe) |
| Dachy | 2-4 spadowe, więźba drewniana | 1-spadowe, 2-spadowe lub łukowe (hale) |
| Normy | EC2 (beton), EC5 (drewno) | EC3 (stal) + EC1 (oddziaływania) |

---

## 3. Słownictwo branżowe PL — top 10 terminów

Pełny słownik 65 terminów → `slownik-branzowy.md`.

| Termin | Definicja skrócona | Uwaga |
|---|---|---|
| Wieniec żelbetowy | Obwodowy element żelbetowy spinający ściany na poziomie kondygnacji | Kluczowy element konstrukcji — bez wieńca brak integralności |
| Więźba dachowa | Drewniana (lub stalowa) konstrukcja nośna dachu | Rodzaje: płatwiowo-kleszczowa, krokwiowa, kratownicowa |
| Strop Teriva | Popularny strop gęstożebrowy z belek i bloczków | Najczęstszy strop w domach jednorodzinnych PL |
| SSO | Stan Surowy Otwarty — sekcja 1 | Fundament → dach wstępnie, bez okien |
| SSZ | Stan Surowy Zamknięty — sekcja 1 | SSO + okna/drzwi zewnętrzne + dach docelowy |
| Ława fundamentowa | Poziomy element żelbetowy pod ścianą nośną | Strip foundation (EN) |
| Porotherm / Ytong / SILKA | Marki handlowe ceramiki/betonu komórkowego/silikatów | W contencie: "ceramika poryzowana, np. Porotherm" |
| Płyta fundamentowa | Monolityczna żelbetowa podstawa całego budynku | Raft foundation (EN) |
| Murłata | Belka drewniana leżąca na wieńcu, podstawa więźby | Wall plate (EN) |
| Kierownik budowy | Uprawiony inżynier nadzorujący realizację — obowiązek przy pozwoleniu | Obligatoryjny przy pozwoleniu na budowę |

---

## 4. Typy umów — ramy prawne KC

> **DISCLAIMER PRAWNY:** Poniższe informacje mają charakter ogólny i edukacyjny. Nie stanowią porady prawnej. Przed zawarciem umowy skonsultuj się z prawnikiem lub notariuszem specjalizującym się w prawie budowlanym.

| Typ umowy | Podstawa prawna | Kiedy stosować | Ryzyko |
|---|---|---|---|
| **Umowa zlecenia** | KC art. 734-751 | Nadzór budowy, usługi cykliczne, kierownik budowy | Brak gwarancji rezultatu — zleceniobiorca odpowiada za staranne działanie, nie efekt |
| **Umowa o dzieło** | KC art. 627-646 | Konkretne prace z mierzalnym rezultatem (mury jednej kondygnacji, komin) | Rękojmia 2 lata od odbioru; ZUS: nie ma obowiązku składek (ryzyko: ZUS może zakwestionować) |
| **Umowa B2B (działalność gospodarcza)** | Ustawa o działalności gospodarczej + KC | Podwykonawcy prowadzący JDG — cykliczne prace | Wymaga weryfikacji czy podwykonawca faktycznie prowadzi DG; ryzyko przekwalifikowania przez ZUS |
| **Umowa o roboty budowlane** | KC art. 647-658 | Całościowe prace GW (SSO, SSZ, kompleksowa realizacja) | Wymaga projektu budowlanego jako załącznika; solidarna odpowiedzialność za wynagrodzenie podwykonawców (art. 6471 KC) |

**Kiedy umowa o roboty budowlane jest OBOWIĄZKOWA:**
- Prace na podstawie projektu budowlanego
- Inwestycja wymagająca pozwolenia na budowę lub zgłoszenia
- Zaangażowanie podwykonawców (solidarna odpowiedzialność KC 6471)

**Tabela decyzyjna:**

| Scenariusz | Rekomendowana umowa |
|---|---|
| Zlecam wykonanie całego domu GW | Roboty budowlane (KC 647) |
| Wynajmuję murarza na miesiąc | Zlecenie lub dzieło (zależy od charakteru) |
| Podwykonawca — firma z NIP | B2B |
| Drobna usługa — wylanie posadzki | Dzieło (KC 627) |
| Kierownik budowy | Zlecenie (KC 734) |

---

## 5. Normy PN-EN i Eurokod — podstawy

Szczegółowe karty każdej normy → `normy-pn-en.md`. Poniżej orientacyjna tabela mapowania.

| Eurokod | Numer PN-EN | Temat | Typowe zastosowanie GW |
|---|---|---|---|
| EC0 | PN-EN 1990 | Podstawy projektowania konstrukcji (bezpieczeństwo, stany graniczne) | Wszystkie konstrukcje — fundament metodologii |
| EC1 | PN-EN 1991 | Oddziaływania na konstrukcje (śnieg, wiatr, ciężar własny) | Obliczenia obciążeń dachu, stropów |
| EC2 | PN-EN 1992 | Konstrukcje betonowe | Fundamenty, stropy żelbetowe, wieńce |
| EC3 | PN-EN 1993 | Konstrukcje stalowe | Hale, budynki gospodarcze stalowe |
| EC5 | PN-EN 1995 | Konstrukcje drewniane | Więźba dachowa, stropy drewniane |
| EC6 | PN-EN 1996 | Konstrukcje murowe | Ściany z cegły, bloczków, silikatów |
| — | PN-EN 206 | Beton — wymagania, właściwości, produkcja | Klasy betonu (C20/25, C25/30) w fundamentach/wieńcach |

**Dla contentu:** Pisz "PN-EN 1992 Eurokod 2" (pełna nazwa) — nie skracaj do "EC2" bez rozwinięcia. Podaj pełną nazwę przy pierwszym użyciu, skrót możliwy w dalszej części tekstu.

---

## 6. Pozwolenia i zgłoszenia (Prawo Budowlane 2026)

Pełny flowchart decyzyjny + 5 scenariuszy → `pozwolenia-vs-zgloszenia.md`.

### Skrócona zasada decyzyjna

| Inwestycja | Wymagane | Podstawa |
|---|---|---|
| Dom parterowy do 70m² (bez poddasza użytkowego) | Zgłoszenie UPRO (milcząca zgoda 21 dni) | Art. 29 ust. 1 pkt 1a Prawo Budowlane |
| Dom powyżej 70m² lub z użytkowym poddaszem | Pozwolenie na budowę | Art. 28 Prawo Budowlane |
| Budynek gospodarczy do 35m² | Zgłoszenie | Art. 29 ust. 1 Prawo Budowlane |
| Garaż wolnostojący do 35m² | Zgłoszenie | Art. 29 ust. 1 Prawo Budowlane |
| Zmiana sposobu użytkowania | Zgłoszenie zmiany użytkowania | Art. 71 Prawo Budowlane |
| Każdy dom z pozwoleniem | Pozwolenie na użytkowanie lub zawiadomienie o zakończeniu | Art. 54-57 Prawo Budowlane |

**Nowelizacja 2022 (obowiązuje nadal w 2026):** Próg zgłoszenia dla domów jednorodzinnych podniesiony do 70m² (wcześniej 35m²). Warunek: parterowy, wolnostojący, jednorodzinny, nie w zbliżeniu do granicy działki <3m.

---

## 7. Stawki rynkowe PL 2024-2026 (widełki)

> **DISCLAIMER:** Stawki są widełkami rynkowymi PL 2024-2026 dla orientacji. Faktyczne ceny zależą od regionu (różnice 15-30% między Warszawą a wschodem PL), materiałów, technologii, warunków geotechnicznych i czasu realizacji. Weryfikuj aktualne stawki przed wyceną — skonsultuj się z lokalnym GW lub kosztorysantem. Nie wykorzystuj tych widełek jako oferty handlowej.

| Pozycja | Jednostka | Widełki 2024-2026 | Uwagi |
|---|---|---|---|
| Fundamenty (ławy żelbetowe) | PLN/mb | 180 – 280 PLN/mb | Zależy od szerokości i głębokości ław |
| Płyta fundamentowa | PLN/m² | 350 – 550 PLN/m² | Z izolacją (XPS + folia) |
| Mury (ceramika poryzowana, standardowa) | PLN/m² | 120 – 200 PLN/m² | Robocizna + materiał, ściana 25-30 cm |
| Mury (beton komórkowy ytong) | PLN/m² | 100 – 160 PLN/m² | Robocizna + materiał |
| Strop Teriva (z zabetonowaniem) | PLN/m² | 180 – 280 PLN/m² | Kompleksowo z wieńcami |
| Wieniec żelbetowy | PLN/mb | 80 – 150 PLN/mb | Przekrój 25×25 lub 30×25 cm |
| Więźba dachowa (płatwiowo-kleszczowa) | PLN/m² rzutu | 120 – 200 PLN/m² | Drewno C24, impregnowane |
| Pokrycie dachu (blachodachówka) | PLN/m² połaci | 80 – 140 PLN/m² | Robocizna + materiał + folia + łaty |
| Pokrycie dachu (dachówka ceramiczna) | PLN/m² połaci | 120 – 220 PLN/m² | Robocizna + materiał + folia + łaty |
| Komin systemowy SCHIEDEL | PLN/mb | 600 – 1200 PLN/mb | Zależy od średnicy i systemu |

**Szacunki etapów (dom 150m², standard, region PL):**
- SSO: 200 000 – 300 000 PLN
- SSZ: 300 000 – 430 000 PLN (SSO + okna/drzwi zewnętrzne + dach docelowy + kominy)

---

## 8. How to override per region

Ten skill zawiera dane generyczne PL. Dla projektów regionalnych (mazowieckie, małopolskie, mazowieckie) stosuj:

1. **Stawki regionalne:** mnożnik orientacyjny — Warszawa/Trójmiasto ×1.3-1.5, Polska wschodnia ×0.85-0.95 względem mediany PL. Zawsze z disclaimerem.
2. **Lokalne przepisy:** MPZP (Miejscowy Plan Zagospodarowania Przestrzennego) per gmina — może zawierać wymogi wyższe niż Prawo Budowlane (np. nachylenie dachu, pokrycie, kolor elewacji). Sprawdź w miejscowym urzędzie lub na geoportal.gov.pl.
3. **Lokalni dostawcy materiałów:** nazwy firm handlowych pozostają generyczne w tym skilli (np. "ceramika poryzowana, np. Porotherm"). Projekt-specific overrides w karcie projektu.

---

## Kiedy uruchomić

Uruchamiaj gdy:
- Content agent pisze artykuł / landing page / FAQ o budowie domu w Polsce — wymaga poprawnej terminologii SSO/SSZ, nazw materiałów, zakresów prac
- Kalkulator GW wymaga danych wejściowych o etapach i stawkach
- Potrzebujesz wiedzieć jaki typ umowy stosować przy pracach budowlanych
- Pytanie dotyczy norm PN-EN dla elementów budowlanych (beton, mur, drewno, stal)
- Potrzebujesz wiedzieć czy inwestycja wymaga pozwolenia czy zgłoszenia

NIE uruchamiaj gdy:
- Pytanie o SEO content strategy → `content-strategy-construction`
- Pytanie o lokalne katalogi firm budowlanych → `regional-seo-poland`
- Pytanie o keyword research i fleksję PL → `polish-language-seo`
- Wykończenia wnętrz, instalacje elektryczne/sanitarne (poza rough-in) → poza scope GW tego skilla

---

## Anti-patterns

1. **Hardkodowane ceny firmowe zamiast widełek rynkowych** — nigdy "Koszt fundamentów u nas to 200 zł/mb". Zawsze: "Stawki rynkowe 180-280 PLN/mb (2024-2026), weryfikuj u lokalnego GW".

2. **Porady prawne bez disclaimera** — nigdy "Możesz zbudować dom 80m² bez pozwolenia". Zawsze: podaj podstawę prawną, dodaj disclaimer "skonsultuj z prawnikiem/architektem przed decyzją".

3. **Mylenie SSO/SSZ z lokalnymi interpretacjami** — SSO BEZ okien i z dachem wstępnym (papa/folia), SSZ Z oknami/drzwiami zewnętrznymi i dachem docelowym. Nie akceptuj "u nas SSO to już z oknami".

4. **Powierzchowne cytowanie Eurokodu** — nie pisz "zgodnie z PN-EN" bez wskazania numeru. Poprawnie: "zgodnie z PN-EN 1992 Eurokod 2 (konstrukcje betonowe)".

5. **Ignorowanie nowelizacji Prawa Budowlanego** — próg zgłoszenia to 70m² parterowy (od 2022, obowiązuje w 2026), NIE 35m² jak w starszych przepisach.

6. **Pominięcie disclaimera o aktualizacji stawek** — stawki materiałów i robocizny zmieniają się z inflacją. Frontmatter `valid_until: 2027-05-11` wymusza review.

7. **Marketing firmowy zamiast generic wiedzy** — nie "polecamy bloczki YTONG" lecz "bloczki betonu komórkowego (np. YTONG/H+H/SOLBET)". Skill jest generyczny — nazwy handlowe jako przykłady, nie rekomendacje.

8. **Mylenie kratownic prefabrykowanych z więźbą płatwiowo-kleszczową** — to dwa różne systemy. Kratownice (wiązary) to prefabrykaty fabryczne; więźba płatwiowo-kleszczowa to konstrukcja ciesielska tworzona na budowie.

9. **Stosowanie typu umowy bez weryfikacji charakteru prac** — umowa o dzieło NIE zawsze jest odpowiednia dla robót budowlanych; umowa o roboty budowlane (KC 647) jest właściwa przy inwestycji z projektem budowlanym.

10. **Brak odpowiedzialności solidarnej przy podwykonawcach** — przy umowie o roboty budowlane (KC 647) inwestor odpowiada solidarnie za wynagrodzenie podwykonawcy (art. 6471 KC). Pomiń ten punkt w contencie = błąd merytoryczny.

---

## Powiązania

### Downstream (skille i agenty które konsumują ten skill)

- `seo-content-writer`  — agent content opus; `requires: [construction-domain-rules]`. Używa sekcji 1-3 do poprawnej terminologii w artykułach blog/landing.
- `calculator-builder`  — agent kalkulatorów; `requires: [construction-domain-rules]`. Używa sekcji 7 (stawki widełki) jako dane wejściowe do kalkulatorów kosztów.
- `local-seo-specialist`  — opcjonalnie; używa terminologii GW przy opisach GBP.

### Boundary z `polish-language-seo` 

- **TU (construction-domain-rules):** Co to jest SSO/SSZ, definicje branżowe, zakresy prac, terminy PL z definicjami.
- **polish-language-seo:** Fleksja terminów w keyword research ("budowa domu", "budowie domu", "budowę domu" — 7 przypadków), polskie SERP behavior, katalogi PL.
- **Reguła:** "Co znaczy SSO?" → ten skill. "Ile wariantów fleksyjnych ma 'ława fundamentowa'?" → `polish-language-seo`.

### Boundary z `regional-seo-poland` 

- **TU (construction-domain-rules):** Generyczna wiedza GW PL — normy, stany, zakresy, stawki ogólnopolskie.
- **regional-seo-poland:** Lokalne GBP, NAP consistency, cite-building katalogi PL, słownik województw i powiatów.
- **Reguła:** "Jakie normy stosuje się do fundamentów?" → ten skill. "Jak skonfigurować GBP dla firmy GW w Warszawie?" → `regional-seo-poland`.

### Kiedy update'ować ten skill

- Co 12 miesięcy weryfikuj sekcję 7 (stawki) — inflacja i zmiany cen materiałów.
- Przy każdej nowelizacji Prawa Budowlanego — sprawdź sekcję 6 (pozwolenia/zgłoszenia).
- Przy nowych normach PN-EN — aktualizuj `normy-pn-en.md` i tabelę w sekcji 5.
- Frontmatter `valid_until: 2027-05-11` — trigger do review przed tą datą.

---

## References

1. **Prawo Budowlane** — Dz.U. 1994 nr 89 poz. 414 z późn. zm. (nowelizacje 2022+): isap.sejm.gov.pl
2. **PKN — Polski Komitet Normalizacyjny** (normy PN-EN, Eurokody): pkn.pl/normy/szukaj
3. **GUS Budownictwo** — statystyki kosztów i stawek: stat.gov.pl/obszary-tematyczne/przemysl-budownictwo
4. **Eurokody PN-EN (zharmonizowane)** — EC0 through EC9: pkn.pl/eurokody
5. **Kodeks Cywilny** (umowy: zlecenie art. 734, dzieło art. 627, roboty budowlane art. 647-658): isap.sejm.gov.pl
6. **Geoportal.gov.pl** — MPZP (Miejscowe Plany Zagospodarowania Przestrzennego): geoportal.gov.pl
