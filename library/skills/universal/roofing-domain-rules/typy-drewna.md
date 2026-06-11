# Typy drewna konstrukcyjnego dekarskiego — PL

8 typów używanych w więźbach dachowych tradycyjnych (krokwiowa, płatwiowo-kleszczowa, stolcowa, jętkowa). Każdy typ: definicja, funkcja, typowe wymiary PL, zapis w wykazie drewna, synonimy.

---

## 1. Krokiew (krokwie)

**Definicja:** Ukośna belka biegnąca od kalenicy (albo od płatwi) aż do okapu. To kręgosłup każdego dachu — na krokwiach leżą kontrłaty i łaty, a na łatach pokrycie. W prostym domu 2-spadowym krokwie tworzą literę „A" patrząc z boku.

**Funkcja:** Element nośny połaci — przenosi ciężar pokrycia, śniegu i wiatru na murłatę (lub płatew), a stamtąd na mur.

**Typowe wymiary PL:**

| Zastosowanie | Przekrój (cm) | Rozstaw (cm) | Długość typowa |
|---|---|---|---|
| Dom do 8 m szerokości | 7×16 lub 8×16 | 80–90 | do 6 m |
| Dom 8–12 m, duże obciążenie śniegiem | 8×18 lub 10×18 | 80–100 | 6–9 m |
| Dach z oknem dachowym (wzmocnienie) | 8×20 lub 10×20 | 80–90 | według projektu |

Minimalne: 5×10 cm (mała altana, powiata). Maksymalne w typowej budowie: 14×25 cm.

**Zapis w wykazie:**
```
krokiew | 7×16×800 | 24 szt.
```
Format: `przekrój_szer×przekrój_wys×długość [cm]` + ilość w sztukach.

**Synonimy:** krokwia (forma regionalna, akceptuj w input), raftery (angielski, nie używać w PL dokumencie). Forma standardowa: **krokiew** (M. l.poj.) / krokwie (l.mn.).

---

## 2. Murłata

**Definicja:** Gruba belka drewniana leżąca poziomo na wierzchu ściany nośnej (na wieńcu żelbetowym). Można powiedzieć że to „podwalina dachu" — krokwie opierają się o murłatę, nie bezpośrednio o mur. Zawsze impregnowana, bo leży blisko zimnego muru i może absorbować wilgoć.

**Funkcja:** Rozdziela obciążenie od krokwi na całą długość ściany. Kotwiowana do wieńca żelbetowego prętami lub kotwami gwintowanymi — musi być dobrze przymocowana, żeby wiatr nie uniósł dachu.

**Typowe wymiary PL:**

| Typ dachu | Przekrój (cm) | Uwagi |
|---|---|---|
| Dom jednorodzinny, standard | 14×14 lub 16×16 | Najczęściej spotykane w PL |
| Dom z dużym obciążeniem lub rozpiętością | 16×18 lub 18×18 | Wschód PL — strefa śniegowa III–IV |
| Budynek gospodarczy | 12×12 lub 14×14 | Mniejsze obciążenia |

Minimalne: 12×12 cm. Maksymalne: 18×20 cm (rzadko).

**Zapis w wykazie:**
```
murłata | 14×14×1260 | 4 szt.
```
Format: jak krokiew — przekrój × długość, ilość w sztukach. Długość = długość ściany (np. 12,60 m → 1260 cm).

**Synonimy:** murłatka (zdrobnienie, potoczne — zaakceptuj w input), podwalina dachu (opis, nie synonim techniczny). Forma standardowa: **murłata**.

---

## 3. Płatew (w tym stolcowa)

**Definicja:** Pozioma belka nośna biegnąca wzdłuż kalenicy lub połaci (równolegle do okapu), podpierająca krokwie w połowie lub w kilku miejscach ich długości. Bez płatwi krokwie musiałyby być bardzo grube — płatew zmniejsza ich rozpiętość. Płatew **stolcowa** leży na słupach pionowych (stąd więźba stolcowa).

**Funkcja:** Redukuje rozpiętość krokwi, umożliwia budowę dachu nad szerokim domem (powyżej ~10 m). Płatew kalenicy nosi krokwie przy kalenicy; płatew pośrednia — w połowie połaci.

**Typy:**

| Typ | Pozycja | Typowe wymiary |
|---|---|---|
| Płatew stolcowa (kalenicowa) | Na szczycie, przy kalenicy | 14×14–16×16 cm |
| Płatew pośrednia | W połowie połaci, na słupach | 12×14–14×16 cm |
| Płatew murłatowa | = murłata — przy okap, na murze | 14×14–16×16 cm |

**Typowe wymiary PL:**

| Zastosowanie | Przekrój (cm) | Długość typowa |
|---|---|---|
| Dom do 12 m, standard | 14×14 | 3–7 m (między ścianami szczytowymi lub podporami) |
| Dom 12–16 m, duże rozpiętości | 16×16 lub 14×18 | 4–8 m |

Minimalne: 10×12 cm (nieduża budowla). Maksymalne: 18×20 cm.

**Zapis w wykazie:**
```
płatew stolcowa | 14×14×700 | 8 szt.
płatew pośrednia | 12×14×650 | 6 szt.
```
Format: typ (z dookreśleniem stolcowa/pośrednia) + przekrój × długość + ilość w sztukach.

**Synonimy:** płatwia (forma regionalna / odmienna, akceptuj), belka płatwiowa (opis). Forma standardowa: **płatew** (M. l.poj.) / płatwie (l.mn.).

---

## 4. Łata

**Definicja:** Cienka beleczka biegnąca poziomo (prostopadle do krokwi), na której bezpośrednio układa się pokrycie dachowe — dachówki, blachodachówki lub inne. Na każdej łacie siedzi cały rząd dachówek. Rozstaw łat zależy od rodzaju pokrycia (każdy producent podaje swoją miarę).

**Funkcja:** Podpora dla pokrycia dachu. Gwoździe lub klamry trzymające dachówkę wbijają się w łatę. Bez łat pokrycie nie miałoby w co się zaprzeć.

**Typowe wymiary PL:**

| Pokrycie | Przekrój łaty (cm) | Rozstaw (cm) | Zapis ilości |
|---|---|---|---|
| Dachówka ceramiczna / betonowa | 4×5 lub 5×5 | 30–35 (wg karty dachówki) | mb |
| Blachodachówka | 3×5 lub 4×5 | 35–40 | mb |
| Gont bitumiczny / pełne deskowanie | 2,5×10 (deska) | ciągłe | mb lub szt. |

**Zapis w wykazie:**
```
łata | 4×5 | 640 mb
```
Format: przekrój (bez długości jednostkowej) + ilość łączna w metrach bieżących. Metr bieżący (mb) = sumaryczna długość wszystkich łat na całym dachu.

**Synonimy:** listwa łatowania (opis), batten (angielski — nie używać). Forma standardowa: **łata** (M. l.poj.) / łaty (l.mn.).

---

## 5. Kontrłata

**Definicja:** Cienka beleczka przybijana bezpośrednio do krokwi, wzdłuż jej biegu (równolegle do spadu), na którą dopiero przybija się łaty. Jej zadaniem jest stworzenie szczeliny wentylacyjnej pod pokryciem — powietrze może przepływać od okapu do kalenicy pod dachówkami, co zapobiega kondensacji i przedłuża życie pokrycia.

**Funkcja:** Wentylacja przestrzeni pod pokryciem + podwyższenie łat nad membraną dachową (folią wstępnego krycia).

**Typowe wymiary PL:**

| Zastosowanie | Przekrój (cm) | Uwagi |
|---|---|---|
| Standard (dachówka, blacha) | 2,5×5 lub 3×5 | Minimalna szczelina 25 mm |
| Dach z dodatkową warstwą ocieplenia | 5×5 lub 6×5 | Większa szczelina = lepsza wentylacja |

**Zapis w wykazie:**
```
kontrłata | 3×5 | 420 mb
```
Format: analogiczny jak łata — przekrój + ilość łączna w mb.

**Synonimy:** listwa kontrłaty (opis), contre-latte (fr. — nie używać). Forma standardowa: **kontrłata** (M. l.poj.) / kontrłaty (l.mn.).

---

## 6. Jętka

**Definicja:** Pozioma belka łącząca dwie naprzeciwległe krokwie mniej więcej w połowie ich długości — tworzy poprzeczkę w literze „A". Trzyma krokwie razem i zapobiega ich rozchylaniu się pod ciężarem śniegu. Więźba z jętkami to **więźba jętkowa** — najprostsza i najczęstsza w domach do ~10 m szerokości.

**Funkcja:** Napięcie między krokwiami (ściąganie rozparcia). Bez jętki (lub kleszcza) krokwie rozchyliłyby się i wypchnęły mury na zewnątrz.

**Typowe wymiary PL:**

| Zastosowanie | Przekrój (cm) | Długość typowa |
|---|---|---|
| Dom do 8 m, lekkie pokrycie | 6×16 lub 7×16 | 2,5–3,5 m (~ 1/3 rozpiętości) |
| Dom do 10 m lub ciężkie pokrycie | 8×16 lub 8×18 | 3–4,5 m |

Jętka zazwyczaj montowana na 1/3–1/2 wysokości trójkąta krokwiowego od góry.

**Zapis w wykazie:**
```
jętka | 7×16×320 | 32 szt.
```
Format: jak krokiew — przekrój × długość + ilość w sztukach.

**Synonimy:** kleszcz (technicznie różny — kleszcze to dwie deski obustronne, jętka to jedna belka środkowa; jednak w mowie potocznej mylone — zaakceptuj, rozróżnij w kontekście), tie beam (angielski — nie używać). Forma standardowa: **jętka** (M. l.poj.) / jętki (l.mn.).

---

## 7. Deska

**Definicja:** Cienki, szeroki element z drewna tartego. W więźbie dekarz używa desek do: szalowania (podbicia) okapów, pełnego deskowania pod gont bitumiczny lub papę, wypełnienia szczytów (deskowanie ścianki kolankowej), listw wiatrownicowych. Wymiary i zastosowanie zależą od funkcji.

**Funkcja:** Kilka różnych funkcji zależnie od miejsca montażu:
- **Deskowanie pod gont** — pełna warstwa pod pokryciem bitumicznym
- **Podbicie okapu** — zamknięcie przestrzeni pod okapem od dołu (estetyka + wentylacja sterowana)
- **Szalowanie szczytu** — pionowe deski zamykające trójkąt szczytowy
- **Listwa wiatrownicowa** — ochrona wiatrownicą boczną krawędzi połaci

**Typowe wymiary PL:**

| Zastosowanie | Grubość (cm) | Szerokość (cm) | Zapis ilości |
|---|---|---|---|
| Deskowanie pod gont | 2,5 | 10–14 | mb lub m² |
| Podbicie okapu | 1,5–2,5 | 10–20 | mb |
| Szalowanie szczytu | 2,5–3 | 10–20 | szt. lub mb |

**Zapis w wykazie:**
```
deska 2,5×14 — deskowanie pod gont | 1 200 mb
deska 2,5×14 — podbicie okapu | 85 mb
```
Zalecane dookreślenie funkcji po myślniku — dekarz ma różne deski na dachu i musi wiedzieć co po co.

**Synonimy:** folia + deska (nie — folia to osobny element), plank (angielski — nie używać), deska szalunkowa (jeśli nie dedykowana pod pokrycie). Forma standardowa: **deska** (M. l.poj.) / deski (l.mn.).

---

## 8. Słup

**Definicja:** Pionowy element więźby stolcowej — stoi między płatwią a belką stropową lub leżnią. Trzyma płatew w powietrzu, żeby płatew mogła podpierać krokwie. Bez słupów płatew by się ugięła. W więźbie stolcowej słupy są sercem całej konstrukcji.

**Funkcja:** Podpora pionowa dla płatwi stolcowej (i pośrednich). Przenosi obciążenie przez płatew na strop lub na leżnię drewnianą.

**Typowe wymiary PL:**

| Zastosowanie | Przekrój (cm) | Wysokość |
|---|---|---|
| Dom do 12 m, płatew kalenicowa | 12×12 lub 14×14 | zależy od geometrii — od 0,8 do 3 m |
| Dom z dwoma rzędami płatwi | 14×14 lub 16×16 | od 0,5 do 2,5 m |

Słupy zawsze w parach symetrycznie (jeden po każdej stronie kalenicy lub pośrednio), rozstaw 2–4 m.

**Zapis w wykazie:**
```
słup | 14×14×220 | 6 szt.
```
Format: jak krokiew — przekrój × długość + ilość w sztukach. Długość = wysokość słupa.

**Synonimy:** stojak (potoczne, akceptuj), kolumna (nie — architektoniczne), post (angielski — nie używać). Forma standardowa: **słup** (M. l.poj.) / słupy (l.mn.).

---

## Tabela zbiorcza — szybka referencja

| Element | Przekrój min (cm) | Przekrój max (cm) | Jednostka | Forma PL |
|---|---|---|---|---|
| Krokiew | 5×10 | 14×25 | szt. | krokiew / krokwie |
| Murłata | 12×12 | 18×20 | szt. | murłata / murłaty |
| Płatew | 10×12 | 18×20 | szt. | płatew / płatwie |
| Łata | 2,5×4 | 5×6 | mb | łata / łaty |
| Kontrłata | 2,5×4 | 6×6 | mb | kontrłata / kontrłaty |
| Jętka | 6×14 | 10×20 | szt. | jętka / jętki |
| Deska | 1,5×8 | 3,5×20 | mb / m² | deska / deski |
| Słup | 10×10 | 16×18 | szt. | słup / słupy |

> Wartości min/max to orientacyjne granice typowych przekrojów w PL budownictwie jednorodzinnym. Obliczenia statyczne według PN-EN 1995-1-1 (Eurokod 5) leżą poza scope'em tego skilla.
