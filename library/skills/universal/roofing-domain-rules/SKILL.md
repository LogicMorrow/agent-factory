---
name: roofing-domain-rules
description: Słownik domeny dekarskiej PL — 8 typów drewna konstrukcyjnego, formaty wymiarów wykazu drewna (AxBxC + jednostki mb/szt), pokrycia dachowe, obróbki blacharskie i orynnowanie. Uruchamiaj gdy agent generuje wykaz drewna, ofertę dekarską lub PDF z pozycjami kosztorysowymi dla branży dekarskiej PL.
version: 1.0.0
compatible_with: [universal]
tags: [domain, roofing, dekarstwo, poland, wood-list]
requires: []
token_cost: medium
distribution: library/skills/universal/
last_updated: 2026-05-27
last_reviewed: 2026-05-29
valid_until: 2027-05-27
---

# roofing-domain-rules

Jedno źródło prawdy o domenie dekarskiej PL — drewno konstrukcyjne, formaty wymiarów, jednostki, pokrycia, obróbki. Scope: więźba dachowa tradycyjna + pokrycia dachowe + orynnowanie. NIE obejmuje: obliczeń statycznych (PN-EN 1995 Eurokod 5), kosztorysowania GW domów (→ `construction-domain-rules`), SEO ani content.

**Cross-reference z `construction-domain-rules`:** Ten skill zawiera dekarski drill-down. Ogólny kontekst więźby w budownictwie GW (SSO/SSZ, stany deweloperskie, stawki rynkowe) → `construction-domain-rules`.

Pliki towarzyszące:
- `typy-drewna.md` — 8 typów drewna konstrukcyjnego dekarskich z definicjami, wymiarami, funkcjami
- `formaty-i-jednostki.md` — konwencja AxBxC, regex walidacyjne, jednostki mb/szt/m³
- `slownik-pokryc-i-elementow.md` — pokrycia dachowe, obróbki blacharskie, orynnowanie, okna dachowe

---

## Kiedy uruchomić

Uruchamiaj gdy:
- Agent (`pdf-document-generator`, `offer-builder`) generuje wykaz drewna lub ofertę dekarską — potrzebuje definicji typów drewna i konwencji wymiarów
- Walidacja pozycji wykazu drewna — format `7×16×800`, jednostka `szt.` vs `mb`, dopuszczalne wartości przekrojów
- Treść oferty PDF zawiera nazwy elementów dekarskich — potrzebujesz poprawnych form PL (krokiew nie krokwia, jętka nie jętki jako typ)
- Agent weryfikuje słowność pozycji kosztorysowych dekarskich (obróbki blacharskie, okuć komina, orynnowanie)

NIE uruchamiaj gdy:
- Pytanie o zakresy prac GW, SSO/SSZ, stany deweloperskie → `construction-domain-rules`
- Pytanie o SEO content dekarstwa → `construction-domain-rules` + `content-strategy-construction`
- Obliczenia statyczne więźby (PN-EN 1995 Eurokod 5) → poza scope obu skilli (zakres inżynierski)
- Kwestie RODO / archiwizacji ofert → `data-protection-rodo-pl`

---

## Kluczowe zasady

1. **Format wymiarów: `przekrój×długość`** — separator `×` (U+00D7, multiplication sign), nie `x` ASCII ani spacja+`x`+spacja. Akceptuj wszystkie w walidacji, normalizuj do `×` w output.
2. **Trzy wzorce zapisu** — krokwie/jętki/płatwie/słupy/murłaty: `WxH×L szt.`; łaty/kontrłaty: `WxH mb`; zamówienia hurtowe: `m³`. Szczegóły → `formaty-i-jednostki.md`.
3. **Synonimy mają priorytetową formę** — w dokumentach używaj: krokiew (nie krokwia), płatew (nie płatwia), jętka (nie jętki jako typ), murłata (nie murłatka). Warianty zaakceptuj jako input, normalizuj w output.
4. **Definicje dla praktyka, nie akademika** — 2-4 zdania językiem cieśli lub dekarza 50+. NIE cytuj Eurokodu w opisie pozycji wykazu.
5. **Ceny drewna opcjonalne** — wykaz drewna może być bez cen (klient dostarcza drewno) lub z cenami (<firma> dostarcza). Walidacja formatu nie może blokować wierszy bez ceny.
6. **Pozycja „z ręki"** — każdy wykaz może zawierać pozycje z wolnym tekstem (niestandardowy element). Walidacja tylko pól wymaganych (typ lub opis), nie formatu wymiarów.
7. **Brak norm PN-EN w pozycjach PDF** — nie dodawaj odniesień do Eurokodu 5 w wierszach wykazu. Klient (<operator>, 50+) nie potrzebuje norm — tylko czytelny wykaz.
8. **Jednostka jako enum** — dopuszczalne: `szt.`, `mb`, `m³`. Forma ze skrótem z kropką (`szt.`, nie `szt` ani `sztuk`). Szczegóły → `formaty-i-jednostki.md`.

---

## Przykłady: dobrze vs źle

### Para 1 — Zapis wymiaru w wykazie drewna

Dobrze:
```
krokiew | 7×16×800 | 24 szt.
łata    | 4×5      | 640 mb
płatew stolcowa | 14×14×700 | 8 szt.
```

Źle:
```
krokiew | 7x16x800cm | 24 sztuki
łata    | 4/5        | 640 mb bieżących
płatew  | 14x14x700mm| 8 szt
```

Dlaczego źle: `x` ASCII i `/` to nie standard; `cm`/`mm` przy wymiarach zbędne (konwencja: cm domyślnie dla drewna); `sztuki` nie `szt.`; `mb bieżących` to redundancja — mb = metr bieżący per definicję.

### Para 2 — Nazwa elementu i definicja

Dobrze (język praktyka):
> Murłata to gruba belka leżąca prosto na wierzchu muru. Kładzie się ją na całej długości ściany, żeby krokwie miały na czym się oprzeć i nie niszczyły muru. Zazwyczaj 14×14 lub 16×16 cm, impregnowana.

Źle (akademickie):
> Murłata (ang. wall plate) — poziomy element konstrukcji drewnianej, stanowiący belkę podwalinową więźby dachowej, przenoszącej obciążenia pionowe krokwi na ścianę nośną. Wg PN-EN 1995-1-1 Eurokod 5.

Dlaczego źle: operator, 50+, nie-IT, w terenie — opis ma być zrozumiały bez słownika budowlanego.

---

## Antywzorce

1. **Mieszanie separatorów** — `7x16×800` (jeden `x` ASCII, jeden `×`) → normalizuj do `×` lub akceptuj oba konsekwentnie. Nie emituj mieszanych formatów w output PDF.

2. **Jednostka bez kropki** — `szt` zamiast `szt.` — polska konwencja skrótów wymaga kropki. `mb` jest wyjątkiem — pisz bez kropki (metr bieżący = symbolicznie mb).

3. **Nadmierne szczegółowienie w wykazie** — pozycja wykazu to `krokiew | 7×16×800 | 24 szt.`, a NIE `krokiew 7×16 cm dł. 8 m C24 KVH impregnowane ciśnieniowo | ...`. Wykaz dekarza = lista robocza, nie specyfikacja techniczna.

4. **Pominięcie pozycji „z ręki"** — każda implementacja wykazu MUSI obsłużyć wolny tekst (klient ma swoje drewno lub niestandardowy element). Blokowanie pozycji bez predefiniowanego typu = błąd UX.

5. **Hardkodowanie cen drewna** — wykaz dekarza może być BEZ cen (klient przynosi drewno) lub Z cenami (dekarz dostarcza). Nie zakładaj że kolumna ceny jest wymagana.

6. **Kopiowanie definicji z `construction-domain-rules`** — murłata i krokiew pojawiają się tam jako elementy GW (np. tabela "Dachy i więźba"). TEN skill zawiera dekarski drill-down (wymiary, jak zapisać w wykazie, synonimy). Nie duplikuj — linkuj cross-reference.

7. **Pomylenie kontrłaty z łatą** — kontrłata biegnie wzdłuż krokwi (równolegle do spadu), łata biegnie poprzecznie (poziomo). Oba mają podobne wymiary, ale zupełnie inną funkcję. Błąd w nazwie = błędna wycena materiałów.

8. **Pominięcie obróbek w ofercie** — oferta dekarska BEZ pozycji "obróbki blacharskie" jest niekompletna. Obróbki (kosz, gąsior, wiatrownica, okuć komina) to osobna pozycja kosztorysowa, nie wchodzą w "pokrycie".

---

## Powiązania

### Downstream (konsumenci tego skilla)

- `pdf-document-generator` (agent, sonnet) — `requires: [roofing-domain-rules]`. Używa formatów wymiarów i nazw typów drewna przy generowaniu tabeli wykazu w PDF.
- `offer-builder` (agent, sonnet) — `requires: [roofing-domain-rules]`. Waliduje pozycje wyceny dekarskiej i wykazu drewna przed wywołaniem generatora PDF.

### Komplementarne

- `construction-domain-rules` (universal skill) — GW domów: SSO/SSZ, stawki rynkowe, zakresy prac ogólnobudowlanych. Zawiera wzmiankę o więźbie i murłacie jako elementy GW. TEN skill zawiera dekarski drill-down.
- `quotation-pl-rules` (universal skill) — reguły ofertowania ryczałtowego PL, VAT 8/23%, terminologia oferta vs faktura. Komplementarny: `quotation-pl-rules` = zasady finansowe, `roofing-domain-rules` = terminologia techniczna.
- `pdf-document-templates` (webapp skill) — szablony `@react-pdf/renderer`; konsumuje konwencje nazw i formatów wymiarów z tego skilla.

### Kiedy update'ować

- Przy zmianie standardów branżowych przekrojów drewna (rzadko — rynek PL stabilny).
- Gdy <operator> (operator) zgłosi nowy typ elementu używany w jego ekipie.
- Frontmatter `valid_until: 2027-05-27` — trigger do review.
