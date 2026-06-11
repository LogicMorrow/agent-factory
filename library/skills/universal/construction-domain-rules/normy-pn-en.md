# Normy PN-EN i Eurokody — GW PL

Plik towarzyszący do `SKILL.md` skilla `construction-domain-rules`.
Zakres: EC0-EC6 + PN-EN 206. Poziom: przystępny dla content writera — co norma reguluje i kiedy stosować w GW. BEZ wzorów obliczeniowych.

Linki do PKN: `https://pkn.pl/normy/szukaj/PN-EN-XXXX` (podstawienie numeru).

---

## Quick reference: element konstrukcyjny → norma

| Element GW | Norma główna | Norma uzupełniająca |
|---|---|---|
| Fundamenty (żelbet) | PN-EN 1992 Eurokod 2 (beton) | PN-EN 1997 Eurokod 7 (geotechnika) |
| Płyta fundamentowa | PN-EN 1992 Eurokod 2 | PN-EN 1997 Eurokod 7 |
| Mury (ceramika, ytong, silikat) | PN-EN 1996 Eurokod 6 | PN-EN 1990 Eurokod 0 (bezpieczeństwo) |
| Stropy żelbetowe (Teriva, monolityczne) | PN-EN 1992 Eurokod 2 | PN-EN 1991 Eurokod 1 (obciążenia) |
| Wieńce żelbetowe | PN-EN 1992 Eurokod 2 | — |
| Więźba dachowa (drewno) | PN-EN 1995 Eurokod 5 | PN-EN 1991 Eurokod 1 (śnieg, wiatr) |
| Hale stalowe, budynki gospodarcze stalowe | PN-EN 1993 Eurokod 3 | PN-EN 1990 + PN-EN 1991 |
| Beton do fundamentów i wieńców | PN-EN 206 | PN-EN 1992 Eurokod 2 |
| Obciążenia śniegiem (cały kraj PL) | PN-EN 1991-1-3 Eurokod 1 | załącznik krajowy PN |
| Obciążenia wiatrem | PN-EN 1991-1-4 Eurokod 1 | załącznik krajowy PN |

---

## EC0 — PN-EN 1990 Eurokod 0

**Pełny tytuł:** PN-EN 1990:2004 Eurokod — Podstawy projektowania konstrukcji

**Zakres (co i dlaczego):** Definiuje metodologię projektowania wszystkich konstrukcji budowlanych: stany graniczne (nośności GN i użytkowania GU), poziomy niezawodności, kombinacje obciążeń. To "meta-norma" — wszystkie pozostałe Eurokody odwołują się do EC0 jako fundamentu metodologicznego.

**Link PKN:** https://pkn.pl/normy/szukaj/PN-EN-1990

**Kiedy stosować w GW:** Każda konstrukcja projektowana wg Eurokodów korzysta z EC0 implicite. Content: gdy piszesz "bezpieczeństwo konstrukcji", "stany graniczne nośności" — to zakres EC0. Dla content writera: nie cytuj EC0 bezpośrednio — wystarczy wspomnieć o "standardach bezpieczeństwa PN-EN".

---

## EC1 — PN-EN 1991 Eurokod 1

**Pełny tytuł:** PN-EN 1991 Eurokod 1 — Oddziaływania na konstrukcje (seria części 1-1 do 1-7)

**Zakres (co i dlaczego):** Definiuje obciążenia na konstrukcje: ciężar własny materiałów, obciążenia użytkowe stropów i podłóg, obciążenia śniegiem, wiatrem, pożarowe i wyjątkowe (np. uderzenia). W Polsce obowiązują załączniki krajowe (NA) z wartościami stref klimatycznych.

**Link PKN:** https://pkn.pl/normy/szukaj/PN-EN-1991

**Kiedy stosować w GW:**
- **Obciążenia śniegiem (EC1-1-3):** Projektant więźby dachowej uwzględnia strefę śniegową dla regionu PL (mapy PN-EN 1991-1-3 NA). Polska ma 5 stref śniegowych — Tatry ≠ niziny centralne.
- **Obciążenia wiatrem (EC1-1-4):** Więźba i hale stalowe — strefa wiatru PL ze strefy 1 (niziny) do 3 (wybrzeże, góry).
- **Obciążenia użytkowe stropów (EC1-1-1):** Strop w domu jednorodzinnym: kategoria A (mieszkalne) = 2.0 kN/m² + 2.0 kN/m² (ściany działowe).

**W contencie:** "Projektant dobiera przekrój krokwi uwzględniając lokalne obciążenie śniegiem według PN-EN 1991-1-3 (Eurokod 1, część śnieg) i strefę klimatyczną danej lokalizacji."

---

## EC2 — PN-EN 1992 Eurokod 2

**Pełny tytuł:** PN-EN 1992-1-1:2008 Eurokod 2 — Projektowanie konstrukcji z betonu

**Zakres (co i dlaczego):** Norma projektowania wszystkich elementów żelbetowych i sprężonych: fundamentów, wieńców, stropów monolitycznych, płyt, belek, słupów. Określa minimalne zbrojenie, otuliny betonowe, klasy betonu i wymagania wykonawcze.

**Link PKN:** https://pkn.pl/normy/szukaj/PN-EN-1992

**Kiedy stosować w GW:**
- **Fundamenty:** Wymiarowanie ław fundamentowych (szerokość, wysokość, zbrojenie). Klasa betonu minimalna dla fundamentów: C20/25 (standard) lub C25/30 (agresywne środowisko).
- **Wieńce żelbetowe:** Zbrojenie minimalne (4 pręty Ø12, strzemiona Ø6 co 20-25 cm) wynika z EC2.
- **Stropy monolityczne:** Grubość płyty, siatki zbrojeniowe, oparcia.

**W contencie:** "Wieniec żelbetowy wykonany zgodnie z PN-EN 1992 Eurokod 2 (konstrukcje betonowe) — minimum 4 pręty Ø12 ze stali B500SP i strzemiona Ø6 co 20 cm."

---

## EC3 — PN-EN 1993 Eurokod 3

**Pełny tytuł:** PN-EN 1993-1-1:2006 Eurokod 3 — Projektowanie konstrukcji stalowych

**Zakres (co i dlaczego):** Norma projektowania elementów stalowych: słupów, rygli, belek, łączników (śruby, spoiny). Określa klasy przekrojów stalowych, warunki stateczności, połączenia.

**Link PKN:** https://pkn.pl/normy/szukaj/PN-EN-1993

**Kiedy stosować w GW:**
- **Hale przemysłowe i gospodarcze:** Szkielet stalowy (słupy HEB/IPE + rygiel C/Z) projektowany wg EC3.
- **Elementy stalowe w budownictwie mieszkaniowym:** Belki stalowe nad dużymi otworami, słupy nośne.
- **Zadaszenia i wiaty:** Konstrukcje stalowe wiat garażowych i budynków pomocniczych.

**W contencie:** "Szkielet hali stalowej z słupami HEB 200 zaprojektowany zgodnie z PN-EN 1993 Eurokod 3 (konstrukcje stalowe) — dobrany do strefowego obciążenia wiatrem i śniegiem."

---

## EC5 — PN-EN 1995 Eurokod 5

**Pełny tytuł:** PN-EN 1995-1-1:2010 Eurokod 5 — Projektowanie konstrukcji drewnianych

**Zakres (co i dlaczego):** Norma projektowania elementów drewnianych i drewnopodobnych (LVL, CLT, sklejka): krokwi, płatwi, murłat, stropów belkowych, ram, kratownic. Określa klasy użytkowania drewna, minimalne przekroje, łączniki (gwoździe, śruby, wkręty, płatki kolczaste).

**Link PKN:** https://pkn.pl/normy/szukaj/PN-EN-1995

**Kiedy stosować w GW:**
- **Więźba dachowa (płatwiowo-kleszczowa, krokwiowa):** Dobór przekrojów drewna litego (C24, C30 wg PN-EN 338) na podstawie EC5 i obciążeń z EC1.
- **Kratownice prefabrykowane (wiązary):** Projektowane przez producenta wg EC5 z płatkami kolczastymi.
- **Stropy drewniane:** Belki drewniane pod podłogi — EC5 i wymagania akustyczne (powiązane z PN-EN ISO 717).

**W contencie:** "Więźba dachowa z drewna C24 impregnowanego ciśnieniowo, zaprojektowana wg PN-EN 1995 Eurokod 5 (konstrukcje drewniane) — dobrana do obciążenia śniegiem i wiatrem dla lokalizacji."

---

## EC6 — PN-EN 1996 Eurokod 6

**Pełny tytuł:** PN-EN 1996-1-1:2010 Eurokod 6 — Projektowanie konstrukcji murowych

**Zakres (co i dlaczego):** Norma projektowania ścian murowanych: z cegły, bloczków ceramicznych, silikatowych, betonu komórkowego, pustaka. Określa wymagania wytrzymałościowe, minimalne grubości ścian nośnych, warunki kotwienia stropów, wymagania dla zapraw.

**Link PKN:** https://pkn.pl/normy/szukaj/PN-EN-1996

**Kiedy stosować w GW:**
- **Ściany nośne ceramiczne / ytong / silikat:** Minimalny wymiar ściany nośnej wg EC6: 24 cm (ceramika/silikat), 20 cm (ytong przy odpowiedniej wytrzymałości bloczka).
- **Nadproża murowe:** Długość oparcia nadproży nad otworami drzwiowymi/okiennymi.
- **Ściany piwniczne:** Wymagania grubości przy obciążeniu parciem gruntu.

**W contencie:** "Ściany nośne z bloczków ceramicznych Porotherm 25 zaprojektowane zgodnie z PN-EN 1996 Eurokod 6 (konstrukcje murowe) — minimalna grubość ściany nośnej 24 cm."

---

## PN-EN 206 — Beton

**Pełny tytuł:** PN-EN 206:2013+A2:2021 Beton — Wymagania, właściwości, produkcja i zgodność

**Zakres (co i dlaczego):** Norma nie projektowania ale produkcji i wymagań dla betonu: klasy wytrzymałościowe (C12/15 do C100/115), klasy ekspozycji (XC, XF, XA — korozja, mróz, chemiczna), konsystencje, wymagania składników. Beton dla fundamentów i wieńców musi spełniać PN-EN 206.

**Link PKN:** https://pkn.pl/normy/szukaj/PN-EN-206

**Kiedy stosować w GW:**
- **Zamawianie betonu z wytwórni (betoniarnia):** Klasa betonu C25/30, klasa ekspozycji XC2 (fundamenty — kontakt z gruntem) lub XF1 (mróz), konsystencja S3-S4.
- **Kontrola jakości:** Świadectwo zgodności betonu (deklaracja właściwości użytkowych) wymagane przy odbiorze betonu z wytwórni.
- **Beton układany zimą:** Ograniczenia temperatury otoczenia wg PN-EN 206 (powyżej +5°C dla standardowego betonu).

**W contencie:** "Beton C25/30 klasy ekspozycji XC2 wg PN-EN 206 — standard dla fundamentów budynków w kontakcie z gruntem."

---

## Przykład scenariuszowy — dom jednorodzinny 150m²

Projektant sporządzając projekt techniczny domu 150m² stosuje kolejno:

1. **EC0** — ustala poziom niezawodności (RC2 dla budownictwa mieszkaniowego) i kombinacje obciążeń
2. **EC1** — oblicza obciążenia śniegiem (strefa PL lokalizacji), wiatrem, ciężar własny stropów (kat. A = 2.0 kN/m²)
3. **EC2** — wymiaruje płytę fundamentową C25/30, wieńce żelbetowe, strop monolityczny (jeśli wybrany)
4. **EC5** — dobiera przekroje krokwi i płatwi więźby dachowej (drewno C24), sprawdza ugięcia
5. **EC6** — weryfikuje nośność ścian nośnych (ytong 36 cm lub ceramika 25 cm) na obciążenia ze stropu
6. **PN-EN 206** — specyfikuje beton do fundamentów i wieńców zamawianego z wytwórni
