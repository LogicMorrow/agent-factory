# Formaty wymiarów i jednostki — wykaz drewna dekarskiego PL

Konwencja zapisu wymiarów, regex walidacyjne (gotowe do implementacji), jednostki i reguły wyboru. Konsumowane przez `pdf-document-generator` i `offer-builder`.

---

## 1. Konwencja AxBxC — trzy wzorce

### Wzorzec 1: Trzy wartości + sztuki (krokwie, jętki, płatwie, słupy, murłaty)

```
WxH×L szt.
```

Przykłady kanoniczne:
```
7×16×800  24 szt.    → krokiew 7 cm × 16 cm × 800 cm, 24 sztuki
14×14×700  8 szt.    → płatew stolcowa 14×14 cm × 700 cm, 8 sztuk
14×14×220  6 szt.    → słup 14×14 cm × 220 cm, 6 sztuk
```

Jednostka wymiarów: **cm** (domyślna, nie zapisywana przy wymiarze — zapis cm dodaj tylko w opisach słownych, nie w kolumnie wymiarów).

### Wzorzec 2: Dwie wartości + mb (łaty, kontrłaty, deski)

```
W×H mb
```

Przykłady kanoniczne:
```
4×5  640 mb     → łata 4 cm × 5 cm, 640 metrów bieżących łącznie
3×5  420 mb     → kontrłata 3 cm × 5 cm, 420 metrów bieżących łącznie
2,5×14  1200 mb → deska 2,5 cm × 14 cm, 1200 metrów bieżących łącznie
```

Ilość `mb` = suma długości wszystkich elementów tego przekroju na całym dachu.

### Wzorzec 3: Metr sześcienny (zamówienia hurtowe, opcjonalny)

```
m³
```

Przykład:
```
drewno konstrukcyjne C24 7×16  4,2 m³
```

Stosować TYLKO przy zamówieniach u dostawcy. W wykazie pozycji dla klienta: wzorce 1 lub 2.

---

## 2. Separator — reguła i akceptowane warianty

**Separator kanoniczny:** `×` (U+00D7, MULTIPLICATION SIGN)

**Akceptowane w input (normalizuj do × w output):**

| Wariant input | Przykład | Status |
|---|---|---|
| `×` (U+00D7) | `7×16×800` | Kanoniczny — emituj w output |
| `x` (ASCII lowercase) | `7x16x800` | Akceptuj, normalizuj |
| `X` (ASCII uppercase) | `7X16X800` | Akceptuj, normalizuj |
| `*` (asterisk) | `7*16*800` | Akceptuj z ostrzeżeniem, normalizuj |
| spacje + x | `7 x 16 x 800` | Akceptuj, normalizuj |
| spacje + × | `7 × 16 × 800` | Akceptuj, normalizuj |

**Nie akceptuj:**
- Separator `/` (slash) — mylony z ułamkami
- Separator `-` (myślnik) — mylony z zakresem wartości
- Separator `,` (przecinek) — mylony z separatorem dziesiętnym

---

## 3. Regex walidacyjne — gotowe do implementacji

### Regex R1 — Trzy wartości z dowolnym separatorem (krokiew, jętka, słup, murłata, płatew)

```regex
^(\d+(?:[.,]\d+)?)\s*[×xX\*]\s*(\d+(?:[.,]\d+)?)\s*[×xX\*]\s*(\d+(?:[.,]\d+)?)$
```

Matchuje:
- `7×16×800` ✓
- `7x16x800` ✓
- `7 × 16 × 800` ✓
- `7.5×16×800` ✓ (dziesiętne przez `.`)
- `7,5×16×800` ✓ (dziesiętne przez `,` — PL konwencja)

Nie matchuje:
- `7×16` (dwa segmenty — to wzorzec R2)
- `7×16×800 cm` (z jednostką — strip jednostkę przed walidacją)
- `7/16/800` ✗ (slash separator)

### Regex R2 — Dwie wartości bez długości (łata, kontrłata, deska-mb)

```regex
^(\d+(?:[.,]\d+)?)\s*[×xX\*]\s*(\d+(?:[.,]\d+)?)$
```

Matchuje:
- `4×5` ✓
- `3×5` ✓
- `2,5×14` ✓ (PL dziesiętne)

### Regex R3 — Ilość + jednostka (walidacja kolumny ilości)

```regex
^(\d+(?:[.,]\d+)?)\s*(szt\.|mb|m³|m3|m²|m2)$
```

Matchuje:
- `24 szt.` ✓
- `640 mb` ✓
- `4,2 m³` ✓
- `4.2 m3` ✓ (ASCII fallback)

Nie matchuje:
- `24 sztuk` ✗ (bez kropki)
- `640mb` ✗ (brak spacji — opcjonalnie złagodź: `^\d+\s*mb$`)
- `24 szt` ✗ (brak kropki)

### Regex R4 — Pełna linia wymiaru wzorzec 1 (krokiew etc.)

```regex
^(\d+(?:[.,]\d+)?)\s*[×xX]\s*(\d+(?:[.,]\d+)?)\s*[×xX]\s*(\d+(?:[.,]\d+)?)\s+(\d+)\s+szt\.$
```

Matchuje całą kolumnę: `7×16×800  24 szt.`

---

## 4. Dopuszczalne wartości per typ — tabela walidacyjna

| Typ | Szer. min (cm) | Szer. max (cm) | Wys. min (cm) | Wys. max (cm) | Dł. min (cm) | Dł. max (cm) | Wzorzec |
|---|---|---|---|---|---|---|---|
| Krokiew | 5 | 14 | 10 | 25 | 100 | 1800 | R1 + szt. |
| Murłata | 10 | 20 | 10 | 22 | 200 | 1600 | R1 + szt. |
| Płatew | 10 | 20 | 12 | 22 | 200 | 1000 | R1 + szt. |
| Jętka | 6 | 10 | 14 | 22 | 150 | 600 | R1 + szt. |
| Słup | 10 | 18 | 10 | 18 | 40 | 400 | R1 + szt. |
| Łata | 2 | 6 | 3 | 8 | — | — | R2 + mb |
| Kontrłata | 2 | 8 | 3 | 8 | — | — | R2 + mb |
| Deska | 1,5 | 4 | 8 | 25 | — | — | R2 + mb/szt. |

> Wartości graniczne poza tabelą nie powodują twardego blokowania — emituj ostrzeżenie walidacyjne, nie error krytyczny. Dekarz może mieć niestandardowe zamówienie.

---

## 5. Jednostki — enum i reguły

### Enum dopuszczalnych jednostek

```typescript
type WoodUnit = 'szt.' | 'mb' | 'm³' | 'm²';
```

### Reguły wyboru jednostki

| Jednostka | Kiedy stosować | Forma w dokumencie PL |
|---|---|---|
| `szt.` | Elementy liczone indywidualnie: krokwie, jętki, płatwie, słupy, murłaty | `szt.` (ze skrótem z kropką) |
| `mb` | Elementy mierzone w biegu: łaty, kontrłaty, deski (metraż) | `mb` (bez kropki — symbol, nie skrót) |
| `m³` | Zamówienia hurtowe drewna u dostawcy — całościowe wolumeny | `m³` (superscript lub `m3` ASCII fallback) |
| `m²` | Deskowanie pod gont/papę (powierzchnia połaci) — rzadko, alternatywa mb | `m²` |

### Normalizacja jednostek w input

| Input od użytkownika | Normalizuj do |
|---|---|
| `sztuk`, `sztuki`, `szt`, `st.` | `szt.` |
| `metrów bieżących`, `m.b.`, `m.b`, `mb.` | `mb` |
| `m3`, `metry sześcienne`, `m sześc.` | `m³` |
| `m2`, `m kw.`, `mkw.` | `m²` |

---

## 6. Separator dziesiętny — PL konwencja

W Polsce standardem jest **przecinek** jako separator dziesiętny: `2,5×14` (nie `2.5×14`).

Reguły dla implementacji:
- **Input:** akceptuj obydwa (`,` i `.`) — użytkownik z telefonu może użyć `.`
- **Output PDF:** normalizuj do `,` (polska konwencja)
- **Walidacja bazy danych:** przechowuj jako float, wyświetlaj z `,`

---

## 7. Przykłady pełnych wierszy wykazu

Poprawna tabela wykazu drewna (fragment):

```
Typ            | Wymiary        | Ilość   | Jedn. | Cena/jedn. | Wartość
krokiew        | 7×16×800       | 24      | szt.  | —          | —
murłata        | 14×14×1260     | 4       | szt.  | —          | —
płatew stolcowa| 14×14×700      | 8       | szt.  | —          | —
jętka          | 7×16×320       | 32      | szt.  | —          | —
łata           | 4×5            | 640     | mb    | —          | —
kontrłata      | 3×5            | 420     | mb    | —          | —
deska (gont)   | 2,5×14         | 1200    | mb    | —          | —
słup           | 14×14×220      | 6       | szt.  | —          | —
z ręki: deska  | (klient dostarcza)| 200  | mb    | —          | —
```

Kolumny `Cena/jedn.` i `Wartość` opcjonalne — gdy klient dostarcza drewno, wypełniane `—` lub pomijane.

---

## 8. Pozycja „z ręki" — specyfikacja

Pozycja z wolnym tekstem (klient ma własne drewno lub element niestandardowy):

```typescript
interface WoodItemCustom {
  type: 'custom';
  description: string;     // dowolny tekst, min 3 znaki, max 120 znaków
  dimensions?: string;     // opcjonalne, walidacja R1/R2 jeśli podane
  quantity: number;        // wymagane
  unit: WoodUnit;          // wymagane
  pricePerUnit?: number;   // opcjonalne
}
```

Walidacja: tylko `description` i `quantity` + `unit` są wymagane. `dimensions` opcjonalne — nie blokuj gdy brak.

---

## 9. Anti-patterns walidacji

1. **Twarda blokada przy wartościach poza tabelą** — emituj `WARNING`, nie `ERROR`. Dekarz wie co robi; aplikacja nie powinna mu blokować pracy.

2. **Wymaganie ceny przy każdej pozycji** — kolumna ceny jest opcjonalna. Wiersz bez ceny = wiersz z `—` w kolumnie ceny.

3. **Wymuszanie separatora `×` w input** — input z klawiatury telefonu ma `x` ASCII. Normalizuj silnie, nie blokuj.

4. **Brak obsługi przecinka dziesiętnego PL** — `2,5` to poprawny wymiar w PL. Regex bez `[.,]` = błąd dla desek i kontrłat.

5. **Przechowywanie wymiaru jako string zamiast struct** — przechowuj jako `{ w: number, h: number, l?: number, unit: 'cm' }` — nie jako string `"7×16×800"`. String tylko w warstwie display/PDF.
