# Struktura oferty ryczałtowej PL

## Oferta vs inne dokumenty — różnice prawne

| Dokument | Status prawny | Moment wystawienia | Wiąże kogo? |
|---|---|---|---|
| **Oferta handlowa** | Oświadczenie woli (KC art. 66) — pre-kontraktowe | Przed podpisaniem umowy | Oferenta przez okres ważności |
| **Umowa / zamówienie** | Umowa cywilnoprawna | Po akceptacji oferty | Obie strony |
| **Faktura VAT** | Dokument księgowy (ustawa o VAT) | Po realizacji lub na zaliczkę | Dokumentuje zobowiązanie |
| **Kosztorys inwestorski** | Dokument techniczny (normy KNR/KNNR) | W fazie projektowej | Orientacyjny, nie wiąże |

**Kluczowa różnica**: oferta ryczałtowa NIE jest fakturą — nie dokumentuje VAT dla US. Faktura jest wystawiana osobno po realizacji prac lub na zaliczkę (osobny workflow poza zakresem tego skilla).

Oferta ryczałtowa jest zasadna gdy:
- Zakres prac jest jasno określony i stabilny (brak ryzyka scope-creep)
- Wartość usługi <50 000 zł netto
- Klient indywidualny (B2C) lub micro-B2B bez skomplikowanych warunków płatności
- Krótki czas realizacji (do kilku tygodni)

Oferta ryczałtowa NIE jest zasadna gdy:
- Umowa o roboty budowlane z kontrahentem B2B — wymaga kosztorysu + umowy KC art. 647+
- Zakres prac jest nieokreślony lub może się zmieniać (remont generalny bez projektu)
- Kontrakty >50 000 zł — warto rozważyć kosztorys szczegółowy dla ochrony obu stron
- Przetargi publiczne (obowiązuje PZP)

## Obowiązkowe elementy oferty PL

Brak któregokolwiek elementu oznaczony jako **[BLOKUJĄCY]** powoduje, że dokument może nie być prawnie skuteczną ofertą w rozumieniu KC art. 66.

| Element | Wymagalność | Uwagi |
|---|---|---|
| Data wystawienia | **[BLOKUJĄCY]** | Format: DD.MM.RRRR |
| Dane oferenta (firma, NIP, adres, telefon) | **[BLOKUJĄCY]** | Pełna nazwa prawna + NIP |
| Dane zamawiającego (imię, nazwisko lub firma, adres) | **[BLOKUJĄCY]** | Dla B2C: imię+nazwisko+adres budowy |
| Przedmiot oferty (opis usługi) | **[BLOKUJĄCY]** | Konkretny zakres, nie ogólnik |
| Cena netto | **[BLOKUJĄCY]** | W PLN, 2 miejsca po przecinku |
| Stawka VAT i kwota VAT | **[BLOKUJĄCY]** | Z uzasadnieniem (patrz `vat-pl-uslugi-budowlane.md`) |
| Cena brutto | **[BLOKUJĄCY]** | Suma netto + VAT |
| Ważność oferty | **[BLOKUJĄCY]** | Domyślnie 14 dni od daty wystawienia |
| Warunki płatności | zalecany | Schemat zaliczkowy lub inny |
| Termin wykonania | zalecany | Podawany jako przedział dat lub tygodnie od zlecenia |
| Podpis / pieczątka | zalecany | Wymagany przy ofertach B2B; PDF z danymi firmy wystarcza dla B2C |
| Numer oferty | opcjonalny | Format: `OF/<rok>/<numer>`, ułatwia archiwizację |

## Domyślne warunki płatności (dekarski standard)

Standard branżowy dla usług dekarskich PL:
- **30% zaliczki** przy podpisaniu umowy / akceptacji oferty
- **70% po odbiorze robót** (odbiór pisemny lub telefoniczny + data)

Alternatywne schematy do wyboru w systemie:
- Płatność w całości po odbiorze (mniejsze projekty B2C)
- 50% zaliczki + 50% po odbiorze (większe projekty)
- Płatność etapowa (przy pracach wielotygodniowych — zalecane negocjacje per-projekt)

Domyślny termin płatności: **14 dni** od daty wykonania / wystawienia faktury końcowej.

## Formuły kalkulacji

```
suma_netto = sum(item.amount_net_pln for item in items)
vat_amount = round_bankers(suma_netto × vat_rate, 2)
suma_brutto = round_bankers(suma_netto + vat_amount, 2)
```

### Zaokrąglenia — reguła bankowa (round half to even, IEEE 754)

Wybór: **reguła bankowa** (round half to even) — standard stosowany w systemach finansowych PL, zgodny z normą ISO 80000-1.

Przykład: `0.5 → 0` (zaokrąglenie do parzystego), `1.5 → 2`, `2.5 → 2`, `3.5 → 4`.

Zaokrąglaj **tylko wynik końcowy** (vat_amount i suma_brutto). Nigdy nie zaokrąglaj `amount_net_pln` pośrednich pozycji przed zsumowaniem.

```typescript
function roundBankers(value: number, decimals: number): number {
  const factor = Math.pow(10, decimals);
  const shifted = value * factor;
  const floor = Math.floor(shifted);
  const diff = shifted - floor;
  if (Math.abs(diff - 0.5) < Number.EPSILON) {
    // dokładnie .5 — zaokrąglij do parzystego
    return (floor % 2 === 0 ? floor : floor + 1) / factor;
  }
  return Math.round(shifted) / factor;
}
```

### Format liczb PL

```typescript
function formatAmountPl(amount: number): string {
  return amount.toLocaleString('pl-PL', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }) + ' PLN';
  // Wynik: "1 500,00 PLN" (separator tysięcy = spacja, dziesiętny = przecinek)
}
```

## Kontrakt z pdf-document-templates

JSON schema przekazywane do skilla `pdf-document-templates` przy generowaniu PDF oferty:

```typescript
interface QuotationPdfInput {
  // --- Metadane dokumentu ---
  document_number: string;          // "OF/2026/001"
  issue_date: string;               // ISO 8601: "2026-05-27"
  valid_until: string;              // ISO 8601: "2026-06-10"

  // --- Dane firmy (stałe, z konfiguracji app) ---
  company: {
    name: string;                   // "<firma> sp. z o.o."
    nip: string;                    // "<NIP>"
    owner_name: string;             // "<operator>"
    phone: string;                  // "<TELEFON>"
    address?: string;               // opcjonalnie
    iban?: string;                  // opcjonalnie, do przelewów
  };

  // --- Dane klienta ---
  client: {
    name: string;                   // imię i nazwisko lub nazwa firmy
    address: string;                // adres budowy / korespondencyjny
    phone?: string;
    nip?: string;                   // dla B2B
  };

  // --- Opis zlecenia ---
  job: {
    description: string;            // "Remont dachu — ul. Kwiatowa 5, Kraków"
    building_type: 'residential' | 'non-residential';
    building_area_m2?: number;      // powierzchnia użytkowa; null = nieznana
    estimated_duration?: string;    // "3–4 tygodnie od zlecenia"
  };

  // --- Pozycje kosztorysowe ---
  items: QuotationItem[];

  // --- Finanse ---
  vat_rate: 0.08 | 0.23;
  vat_justification: string;        // uzasadnienie stawki — wymagane
  payment_terms: {
    advance_percent: number;        // np. 30
    remaining_percent: number;      // np. 70
    payment_due_days: number;       // dni na zapłatę po odbiorze, np. 14
  };

  // --- Tryb renderowania PDF ---
  render_mode: 'summary' | 'detailed';
  // summary: tylko sumy (netto, VAT, brutto) — bez listy pozycji
  // detailed: pełna tabela pozycji + sumy

  // --- Pola wyliczane (generowane przez system, nie podawane przez UI) ---
  totals: {
    net_pln: number;                // suma netto (2 miejsca po przecinku)
    vat_amount_pln: number;         // kwota VAT
    gross_pln: number;              // suma brutto
  };
}

interface QuotationItem {
  label_pl: string;                 // "Pokrycie + więźba dachowa"
  category: QuotationCategory;
  amount_net_pln: number;           // kwota netto w PLN
  notes?: string;                   // opcjonalne uwagi do pozycji
}

type QuotationCategory =
  | 'roofing'     // pokrycie + więźba
  | 'gutters'     // orynnowanie
  | 'windows'     // montaż okien dachowych
  | 'flashings'   // obróbki dekarskie
  | 'chimney'     // okucia kominowe
  | 'custom'      // pozycja "z ręki"
  // Rozszerzalne w v2:
  | 'plumbing'    // hydraulika
  | 'electrical'  // elektryka
  | 'masonry'     // murarstwo
  | 'other';      // inna domena
```

### Walidacje po stronie generatora

Przed przekazaniem do `pdf-document-templates` sprawdź:
- `items.length >= 1` — oferta musi mieć co najmniej jedną pozycję
- `totals.net_pln > 0` — suma netto musi być dodatnia
- `valid_until` jest datą późniejszą niż `issue_date`
- `payment_terms.advance_percent + payment_terms.remaining_percent === 100`
- `vat_rate` jest jedną z dozwolonych wartości (0.08 lub 0.23)
- `vat_justification` nie jest pustym stringiem
