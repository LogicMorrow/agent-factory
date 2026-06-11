# VAT PL — Usługi budowlano-montażowe (stan prawny 2026)

Podstawa prawna: Ustawa z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2004 nr 54 poz. 535 z późn. zm.), art. 41 ust. 12–12c.

## Stawki obowiązujące

| Stawka | Zakres |
|---|---|
| **8%** | Usługi budowlano-montażowe, remonty i konserwacje dotyczące **budynków mieszkalnych** (PKOB 111–121) o powierzchni użytkowej **do 300 m²** lub lokali mieszkalnych do 150 m² |
| **23%** | Wszystkie pozostałe: budynki niemieszkalne (garaże, obiekty gospodarcze, komercyjne), usługi dotyczące budynków mieszkalnych powyżej 300 m², dostawa materiałów sprzedawanych samodzielnie |
| **0%** | Eksport poza EOG — poza zakresem typowych ofert PL. Nie stosuj bez weryfikacji prawnej. |

## Drzewo decyzyjne — jaka stawka VAT?

```
Czy oferta dotyczy usługi (montaż, remont, konserwacja)?
├─ TAK → Jaki jest obiekt?
│   ├─ Budynek MIESZKALNY (PKOB 111-121, domy, bloki, bliźniaki)
│   │   └─ Czy powierzchnia użytkowa ≤ 300 m²?
│   │       ├─ TAK  → VAT 8%
│   │       └─ NIE  → VAT 23%
│   └─ Budynek NIEMIESZKALNY (garaż, budynek gospodarczy, sklep, biuro)
│       └─ VAT 23% (zawsze)
└─ NIE → To jest dostawa materiałów (sprzedaż drewna, blachy, itp.)
    └─ VAT 23% (zawsze, niezależnie od budynku)
```

## Dekarstwo — szczegóły

### Usługi objęte stawką 8%
- Pokrycie dachu + więźba dachowa na **budynku mieszkalnym ≤300 m²**
- Orynnowanie (montaż rynien i rur spustowych) na budynku mieszkalnym ≤300 m²
- Montaż okien dachowych (Velux, Fakro, itp.) na budynku mieszkalnym ≤300 m²
- Montaż obróbek dekarskich (kominowych, wiatrownicy, gąsiorów, koszowych) na budynku mieszkalnym ≤300 m²
- Montaż okuć kominowych na budynku mieszkalnym ≤300 m²

Warunek konieczny: usługa musi być nierozerwalnie związana z budynkiem (wbudowana, nie sprzedaż luzem).

### Usługi objęte stawką 23%
- Każda z powyższych usług wykonana na **budynku gospodarczym, garażu, obiekcie komercyjnym**
- Każda z powyższych usług na budynku mieszkalnym **>300 m²** (duże domy, rezydencje)
- Usługa na budynku o nieznanej / niezweryfikowanej klasyfikacji — domyślnie 23% do czasu wyjaśnienia

### Drewno jako pozycja w ofercie — krytyczne rozróżnienie

| Sytuacja | Klasyfikacja | VAT |
|---|---|---|
| Drewno **wbudowane** w więźbę (część usługi budowlanej) | Usługa montażu | 8% (jeśli bud. mieszk. ≤300 m²) |
| Drewno **sprzedawane osobno** (klient kupuje materiał, sam montuje lub inny wykonawca) | Dostawa towaru | 23% zawsze |
| Drewno na **oddzielnym wykazie** bez usługi montażu | Dostawa towaru | 23% zawsze |
| Mieszana oferta (materiały + usługa) z **jedną ceną** | Usługa dominująca | 8% jeśli bud. mieszk. ≤300 m² (ale ryzyko podatkowe — lepiej rozdzielić pozycje) |

**Rekomendacja:** rozdzielaj pozycje materialną od usługowej w ofercie, jeśli różnią się stawką VAT. Jedna stawka na całej ofercie to wygodne uproszenie, ale przy kontroli US może być zakwestionowane.

## Klasyfikacja obiektu — jak ustalić

Kolejność weryfikacji:
1. **Zapytaj klienta** — przeznaczenie budynku (dom jednorodzinny, bliźniak, budynek gosp.)
2. **Wypis z rejestru gruntów / mapa ewidencyjna** — PKOB/KŚT widoczny przy nieruchomościach
3. **Pozwolenie na budowę** — typ obiektu budowlanego
4. **W razie wątpliwości:** wystawiaj 23% i poinformuj klienta, lub wnioskuj o WIS (Wiążąca Informacja Stawkowa) w US

Jeśli klient podał: "dom jednorodzinny" lub "budynek mieszkalny" i nie wspomniał o >300 m² — stosuj 8%.

## Pole `vat_rate` w systemie — walidacja

```typescript
type VatRate = 0.08 | 0.23;  // tylko te dwie wartości dla ofert dekarskich PL

function resolveVatRate(buildingType: 'residential' | 'non-residential', areaM2: number | null): VatRate {
  if (buildingType === 'residential' && (areaM2 === null || areaM2 <= 300)) {
    return 0.08;
  }
  return 0.23;
}
```

Jeśli `areaM2` nieznane, a buildingType = 'residential' → domyślnie 0.08 z adnotacją w polu `vat_note` (np. "Stawka 8% zastosowana dla budynku mieszkalnego. Podana przez klienta powierzchnia: nieznana. Obowiązuje dla budynków ≤300 m².").

## Uzasadnienie VAT w dokumencie oferty

Wymagane pole `vat_justification` w danych oferty — widoczne w stopce PDF lub adnotacji:

Przykład dla 8%:
> "Stawka VAT 8% — usługi budowlano-montażowe dotyczące budynku mieszkalnego o powierzchni do 300 m² (art. 41 ust. 12 ustawy o VAT)"

Przykład dla 23%:
> "Stawka VAT 23% — usługi dotyczące obiektu niemieszklanego / budynku o pow. >300 m²"

To pole chroni wykonawcę przy kontroli skarbowej — pokazuje świadomą decyzję klasyfikacyjną, nie przypadkowy wybór.
