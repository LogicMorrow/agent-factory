# Pozycje kosztorysowe — Katalog kategorii

## Zasady ogólne

Każda pozycja kosztorysowa w ofercie ryczałtowej PL ma:
- `label_pl` — czytelny tekst po polsku wyświetlany klientowi (nie kod techniczny)
- `category` — enum do wewnętrznej klasyfikacji systemu (routing, ikony, sortowanie)
- `amount_net_pln` — kwota netto w PLN (liczba zmiennoprzecinkowa, 2 miejsca po przecinku)
- `notes` — opcjonalne uwagi widoczne w trybie `detailed` PDF

Regula wyświetlania: `label_pl` jest jedynym tekstem widocznym dla klienta. `category` jest wewnętrzna — nigdy nie wyświetlaj surowej wartości enum na PDF.

## Domena: Dekarstwo (referencja domenowa)

Kategorie obsługiwane natywnie przez kategorie `roofing | gutters | windows | flashings | chimney | custom`:

| Kategoria (enum) | Domyślny label_pl | Opis zakresu |
|---|---|---|
| `roofing` | Pokrycie + więźba dachowa | Montaż pokrycia (blachodachówka, dachówka, papa, gont) + konstrukcja więźby (krokwie, murłaty, płatwie, jętki). Główna pozycja dekarska. |
| `gutters` | Orynnowanie | Montaż rynien, rur spustowych, haków, złączek, kolan, dekli, wpustów. |
| `windows` | Montaż okien dachowych | Montaż okien połaciowych (Velux, Fakro, inne) wraz z kołnierzami uszczelniającymi. Podaj liczbę okien w `notes`. |
| `flashings` | Obróbki dekarskie | Obróbki blacharskie: kominy, wiatrownice, gąsiory, koszowe, pasy nadrynnowe, kalenicy. |
| `chimney` | Montaż okuć kominowych | Okucia (okócia) kominowe: czapy, nasady, deflektory, opierzenia kominów. Podaj liczbę kominów w `notes`. |
| `custom` | (dowolny tekst) | Pozycja niestandardowa — dowolny opis w `label_pl`. |

### Przykłady poprawnych pozycji dekarskich

```json
[
  {
    "label_pl": "Pokrycie + więźba dachowa",
    "category": "roofing",
    "amount_net_pln": 18500.00,
    "notes": "Blachodachówka matowa RAL 7016, więźba sosnowa KVH"
  },
  {
    "label_pl": "Orynnowanie",
    "category": "gutters",
    "amount_net_pln": 3200.00,
    "notes": "Rynny stalowe ocynkowane fi 125, rury spustowe fi 90"
  },
  {
    "label_pl": "Montaż okien dachowych",
    "category": "windows",
    "amount_net_pln": 2400.00,
    "notes": "3 szt. Velux GGL FK06 wraz z kołnierzami EDW"
  },
  {
    "label_pl": "Obróbki dekarskie",
    "category": "flashings",
    "amount_net_pln": 1800.00,
    "notes": "Opierzenia kominów, wiatrownice, gąsiory blacha stalowa"
  },
  {
    "label_pl": "Okucia kominowe",
    "category": "chimney",
    "amount_net_pln": 600.00,
    "notes": "2 kominy, czapy betonowe + nasady obrotowe"
  },
  {
    "label_pl": "Demontaż starego pokrycia",
    "category": "custom",
    "amount_net_pln": 1200.00,
    "notes": "Wywóz gruzu i utylizacja w cenie"
  }
]
```

### Pozycja „z ręki" (custom) — zasady

Pozycja `custom` jest nieograniczona — klient widzi dokładnie to co wpisał wykonawca w `label_pl`. Stosuj gdy:
- Zakres nie pasuje do żadnej standardowej kategorii
- Klient ma specjalne wymagania (np. "Izolacja termiczna poddasza — wełna mineralna 20 cm")
- Prace towarzyszące (np. "Rusztowanie i transport materiałów")
- Rabat lub korekta (ujemna kwota netto — system musi obsługiwać wartości ujemne dla rabatów)

## Domena rozszerzalna (v2+)

Kategorie zarezerwowane dla przyszłych domen — `category` enum jest już zdefiniowany:

| Kategoria (enum) | Domena v2 | Przykładowe `label_pl` |
|---|---|---|
| `plumbing` | Hydraulika | "Montaż instalacji wodnej", "Wymiana pionu" |
| `electrical` | Elektryka | "Instalacja elektryczna", "Montaż rozdzielnicy" |
| `masonry` | Murarstwo / tynkarstwo | "Wymurowanie ściany działowej", "Tynkowanie" |
| `other` | Inne domeny | Dowolna usługa budowlana nieobjęta powyższymi |

Rozszerzenie do v2 wymaga tylko dodania nowych presetów `label_pl` w UI — `category` enum i logika PDF nie wymagają modyfikacji.

## Metryki pomocnicze (nie pozycje kosztorysowe)

Metryki wpływają na kalkulację przez wykonawcę, ale NIE są osobnymi pozycjami w ofercie ryczałtowej. Są metadanymi zlecenia:

| Metryka | Typ | Zastosowanie |
|---|---|---|
| `roof_area_m2` | number | Szacowanie robocizny pokrycia (wewnętrzna kalkulacja wykonawcy) |
| `chimney_count` | integer | Podpowiedź przy wypełnianiu pozycji `chimney` |
| `roof_window_count` | integer | Podpowiedź przy wypełnianiu pozycji `windows` |

Metryki przechowywane w zleceniu dla wewnętrznych potrzeb — nie trafiają do JSON kontraktu `QuotationPdfInput` (nie są widoczne na PDF klienta, chyba że w `notes` przy pozycji).

## Walidacja nazw polskich (label_pl)

Wymagania dla `label_pl`:
- Minimalna długość: 3 znaki
- Maksymalna długość: 120 znaków (limit tabelki PDF)
- Znaki dopuszczalne: litery PL (ą, ę, ó, ś, ź, ż, ć, ń, ł + wielkie), cyfry, spacje, przecinki, myślniki, nawiasy, kropki, ukośniki
- Brak cudzysłowów specjalnych — używaj `"` i `'` ASCII (PDF renderer może nie obsługiwać typograficznych)
- Wielka litera na początku — konwencja PL dla nazw własnych w tabelkach
