# WoodListDocument — Wykaz drewna PDF

Specyfikacja komponentu TSX `WoodListDocument` dla `@react-pdf/renderer`. Renderuje wykaz drewna konstrukcyjnego w formacie A4 PL — dokument techniczny, osobny od oferty robocizny.

> Typy drewna, formaty wymiarów i nazewnictwo PL — patrz `roofing-domain-rules/typy-drewna.md` + `roofing-domain-rules/formaty-i-jednostki.md`.

## Struktura dokumentu

```
[1] Nagłówek (dane firmy + "Wykaz drewna do oferty nr X")
[2] Skrócone dane klienta + adres budowy
[3] Tabela pozycji drewna (typ | wymiary | ilość | jednostka | [cena])
[4] Podsumowanie (suma ilości + opcjonalna suma wartości)
[5] Uwagi / pozycje "z ręki"
[6] Stopka z numeracją stron
```

**Brak klauzuli RODO** — wykaz drewna to dokument techniczny. Zawiera minimum danych osobowych klienta (tylko kontekst budowy). Klauzula RODO jest wyłącznie w `OfferDocument`.

## TypeScript interface — WoodListInput

```typescript
// lib/types/wood-list.ts

interface WoodListInput {
  // --- Metadane dokumentu ---
  offer_reference: string;    // powiązanie z ofertą: "OF/2026/001"
  issue_date: string;         // ISO 8601: "2026-05-27"

  // --- Dane firmy (z konfiguracji — NIE hardcode) ---
  // przekazywane przez CompanyConfig (patrz kontrakt-A-consumer.md)

  // --- Skrócone dane klienta (min. do identyfikacji budowy) ---
  client_name: string;        // "Jan Kowalski" (lub inicjały)
  build_address: string;      // "ul. Kwiatowa 5, 35-001 Kraków"

  // --- Pozycje wykazu ---
  items: WoodListItem[];

  // --- Tryb cen ---
  show_prices: boolean;
  // false = tylko wykaz (klient dostarcza drewno)
  // true = z cenami (firma dostarcza drewno)

  // --- Opcjonalne podsumowanie ilości ---
  show_volume_summary?: boolean;
  // true = oblicza i pokazuje sumę m³ dla pozycji w szt. z wymiarami
}

interface WoodListItem {
  // --- Typ drewna ---
  wood_type: WoodType | string;
  // WoodType = enum 8 typów z roofing-domain-rules
  // string = pozycja "z ręki" (wolny opis)

  // --- Wymiary ---
  dimensions: string;
  // Format: "7×16×800" (przekrój_szer×przekrój_wys×długość [cm])
  // lub "4×5" (tylko przekrój, dla łat/kontrłat w mb)
  // lub wolny tekst dla pozycji "z ręki"

  // --- Ilość + jednostka ---
  quantity: number;
  unit: 'szt.' | 'mb' | 'm³';

  // --- Cena (opcjonalna — tylko gdy show_prices = true) ---
  unit_price_pln?: number;    // cena za sztukę / mb / m³

  // --- Uwagi ---
  notes?: string;             // opcjonalne: "impregnowane", "KVH", "C24"
}

type WoodType =
  | 'krokiew'
  | 'murłata'
  | 'płatew'
  | 'płatew stolcowa'
  | 'łata'
  | 'kontrłata'
  | 'jętka'
  | 'deska'
  | 'słup';
// Rozszerzalne o "inne" dla pozycji z ręki
```

## Wyliczenia (show_prices = true)

```typescript
// Kalkulacja wartości pozycji i sum
function calculateItemValue(item: WoodListItem): number | null {
  if (!item.unit_price_pln) return null;
  return item.quantity * item.unit_price_pln;
}

function calculateTotals(items: WoodListItem[]): {
  total_value_pln: number | null;
  volume_m3: number | null;
} {
  // Suma wartości (gdy show_prices = true)
  const prices = items.map(i => calculateItemValue(i));
  const total_value_pln = prices.every(v => v !== null)
    ? prices.reduce((sum, v) => sum! + v!, 0)
    : null;

  // Suma objętości (dla pozycji z wymiarami w szt.)
  // Wzór: (szer_cm × wys_cm × dł_cm) / 1_000_000 × quantity
  const volume_m3 = items.reduce((sum, item) => {
    if (item.unit !== 'szt.') return sum;
    const dims = parseDimensions(item.dimensions); // [szer, wys, dł] w cm
    if (!dims || dims.length < 3) return sum;
    const vol = (dims[0] * dims[1] * dims[2]) / 1_000_000;
    return sum + vol * item.quantity;
  }, 0);

  return { total_value_pln, volume_m3 };
}
```

## Przykład TSX — WoodListDocument

```tsx
// components/pdf/WoodListDocument.tsx
// NIE zawiera danych konkretnej firmy ani klienta.
// Wszystkie dane przez props.

import React from 'react';
import { Document, Page, Text, View, StyleSheet } from '@react-pdf/renderer';
import type { WoodListInput } from '../../lib/types/wood-list';
import type { CompanyConfig } from '../../lib/types/pdf-config';
import { formatAmountPl, formatDatePl, PAGE_STYLES } from './pdf-utils';
import { calculateItemValue, calculateTotals } from '../../lib/wood-list-utils';

const styles = StyleSheet.create({
  page: {
    ...PAGE_STYLES.a4Portrait,
    fontSize: 10,
    fontFamily: 'Roboto',
    color: '#1a1a1a',
  },
  // Nagłówek
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 14,
    paddingBottom: 10,
    borderBottomWidth: 1.5,
    borderBottomColor: '#cccccc',
  },
  companyName: { fontSize: 12, fontWeight: 'bold', marginBottom: 2 },
  companyDetail: { fontSize: 8.5, color: '#555555', lineHeight: 1.4 },
  docTitle: { fontSize: 11, fontWeight: 'bold', textAlign: 'right' },
  docMeta: { fontSize: 8.5, color: '#555555', textAlign: 'right' },
  // Klient
  clientBlock: {
    marginBottom: 12,
    padding: 8,
    backgroundColor: '#f8f8f8',
    borderLeftWidth: 2,
    borderLeftColor: '#888888',
  },
  clientRow: { flexDirection: 'row', marginBottom: 2 },
  clientLabel: { fontSize: 9, color: '#666666', width: 100 },
  clientValue: { fontSize: 9, flex: 1 },
  // Tabela
  sectionTitle: {
    fontSize: 10,
    fontWeight: 'bold',
    marginBottom: 6,
    marginTop: 8,
    paddingBottom: 2,
    borderBottomWidth: 0.5,
    borderBottomColor: '#cccccc',
  },
  tableHeader: {
    flexDirection: 'row',
    backgroundColor: '#e8e8e8',
    paddingVertical: 4,
    paddingHorizontal: 5,
    fontSize: 8.5,
    fontWeight: 'bold',
    borderWidth: 0.5,
    borderColor: '#cccccc',
  },
  tableRow: {
    flexDirection: 'row',
    paddingVertical: 4,
    paddingHorizontal: 5,
    borderBottomWidth: 0.5,
    borderBottomColor: '#e0e0e0',
    fontSize: 9,
  },
  tableRowAlt: { backgroundColor: '#f7f7f7' },
  colLp: { width: 22, fontSize: 8.5 },
  colType: { width: 110 },
  colDims: { width: 90 },
  colQty: { width: 45, textAlign: 'right' },
  colUnit: { width: 35, textAlign: 'center', color: '#555555' },
  colPrice: { width: 75, textAlign: 'right' },
  colValue: { width: 75, textAlign: 'right' },
  colNotes: { flex: 1, fontSize: 8, color: '#666666' },
  // Sumy
  summaryBlock: {
    marginTop: 10,
    alignItems: 'flex-end',
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    marginBottom: 2,
  },
  summaryLabel: { fontSize: 9, color: '#555555', width: 160, textAlign: 'right', paddingRight: 10 },
  summaryValue: { fontSize: 9, width: 90, textAlign: 'right' },
  summaryBold: { fontSize: 10, fontWeight: 'bold' },
  // Uwagi
  notesBlock: { marginTop: 10, fontSize: 8.5, color: '#555555', lineHeight: 1.4 },
  // Stopka
  footer: {
    position: 'absolute',
    bottom: 20,
    left: 20,
    right: 20,
    flexDirection: 'row',
    justifyContent: 'space-between',
    fontSize: 7.5,
    color: '#999999',
    borderTopWidth: 0.5,
    borderTopColor: '#dddddd',
    paddingTop: 4,
  },
});

export function WoodListDocument({
  data,
  company,
}: {
  data: WoodListInput;
  company: CompanyConfig;
}) {
  const { total_value_pln, volume_m3 } = calculateTotals(data.items);
  const hasCustomItems = data.items.some(i => !isKnownWoodType(i.wood_type));

  return (
    <Document
      title={`Wykaz drewna — oferta ${data.offer_reference}`}
      author={company.name}
      subject="Wykaz drewna konstrukcyjnego"
    >
      <Page size="A4" style={styles.page}>

        {/* [1] Nagłówek */}
        <View style={styles.header}>
          <View>
            <Text style={styles.companyName}>{company.name}</Text>
            <Text style={styles.companyDetail}>NIP: {company.nip}</Text>
            <Text style={styles.companyDetail}>tel. {company.phone}</Text>
          </View>
          <View>
            <Text style={styles.docTitle}>WYKAZ DREWNA</Text>
            <Text style={styles.docMeta}>do oferty nr {data.offer_reference}</Text>
            <Text style={styles.docMeta}>Data: {formatDatePl(data.issue_date)}</Text>
          </View>
        </View>

        {/* [2] Dane klienta */}
        <View style={styles.clientBlock}>
          <View style={styles.clientRow}>
            <Text style={styles.clientLabel}>Klient:</Text>
            <Text style={styles.clientValue}>{data.client_name}</Text>
          </View>
          <View style={styles.clientRow}>
            <Text style={styles.clientLabel}>Adres budowy:</Text>
            <Text style={styles.clientValue}>{data.build_address}</Text>
          </View>
        </View>

        {/* [3] Tabela pozycji */}
        <Text style={styles.sectionTitle}>
          Zestawienie drewna {data.show_prices ? '— z cenami (dostawa w cenie)' : '— bez cen (drewno klienta)'}
        </Text>

        {/* Nagłówek tabeli */}
        <View style={styles.tableHeader}>
          <Text style={styles.colLp}>Lp.</Text>
          <Text style={styles.colType}>Element</Text>
          <Text style={styles.colDims}>Wymiary (cm)</Text>
          <Text style={styles.colQty}>Ilość</Text>
          <Text style={styles.colUnit}>Jedn.</Text>
          {data.show_prices && (
            <>
              <Text style={styles.colPrice}>Cena jedn.</Text>
              <Text style={styles.colValue}>Wartość</Text>
            </>
          )}
          <Text style={styles.colNotes}>Uwagi</Text>
        </View>

        {/* Wiersze */}
        {data.items.map((item, idx) => {
          const itemValue = data.show_prices ? calculateItemValue(item) : null;
          return (
            <View
              key={idx}
              style={[styles.tableRow, idx % 2 === 1 ? styles.tableRowAlt : {}]}
            >
              <Text style={styles.colLp}>{idx + 1}.</Text>
              <Text style={styles.colType}>{item.wood_type}</Text>
              <Text style={styles.colDims}>{item.dimensions}</Text>
              <Text style={styles.colQty}>{item.quantity}</Text>
              <Text style={styles.colUnit}>{item.unit}</Text>
              {data.show_prices && (
                <>
                  <Text style={styles.colPrice}>
                    {item.unit_price_pln != null ? formatAmountPl(item.unit_price_pln) : '—'}
                  </Text>
                  <Text style={styles.colValue}>
                    {itemValue != null ? formatAmountPl(itemValue) : '—'}
                  </Text>
                </>
              )}
              <Text style={styles.colNotes}>{item.notes ?? ''}</Text>
            </View>
          );
        })}

        {/* [4] Podsumowanie */}
        <View style={styles.summaryBlock}>
          {data.show_volume_summary && volume_m3 !== null && volume_m3 > 0 && (
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Łączna objętość (przybliżona):</Text>
              <Text style={styles.summaryValue}>
                {volume_m3.toLocaleString('pl-PL', { minimumFractionDigits: 3, maximumFractionDigits: 3 })} m³
              </Text>
            </View>
          )}
          {data.show_prices && total_value_pln !== null && (
            <View style={styles.summaryRow}>
              <Text style={[styles.summaryLabel, styles.summaryBold]}>ŁĄCZNA WARTOŚĆ (netto):</Text>
              <Text style={[styles.summaryValue, styles.summaryBold]}>
                {formatAmountPl(total_value_pln)}
              </Text>
            </View>
          )}
        </View>

        {/* [5] Uwaga o pozycjach z ręki */}
        {hasCustomItems && (
          <View style={styles.notesBlock}>
            <Text>
              * Pozycje oznaczone jako niestandardowe — wymiary i specyfikacja według uzgodnień z klientem.
            </Text>
          </View>
        )}

        {/* [6] Stopka */}
        <Text
          style={styles.footer}
          render={({ pageNumber, totalPages }) =>
            `${company.name}  |  Wykaz drewna — oferta ${data.offer_reference}  |  Strona ${pageNumber} z ${totalPages}`
          }
          fixed
        />
      </Page>
    </Document>
  );
}

// Pomocnicza funkcja walidacji typów drewna
function isKnownWoodType(type: string): boolean {
  const known: string[] = [
    'krokiew', 'murłata', 'płatew', 'płatew stolcowa',
    'łata', 'kontrłata', 'jętka', 'deska', 'słup',
  ];
  return known.includes(type.toLowerCase);
}
```

## Przykładowe dane — 8 typów drewna (test/demo)

Przykład `WoodListInput.items` z kompletnym wykazem dla typowego dachu dwuspadowego. Dane są **generyczne** — wymiary i ilości są przykładowe, nie projektowe.

```typescript
const exampleItems: WoodListItem[] = [
  // 1. Krokiew — element nośny połaci (patrz roofing-domain-rules)
  {
    wood_type: 'krokiew',
    dimensions: '7×16×800',    // przekrój 7×16 cm, długość 800 cm
    quantity: 24,
    unit: 'szt.',
    notes: 'impregnowane',
  },
  // 2. Murłata — belka na wierzchu muru (patrz roofing-domain-rules)
  {
    wood_type: 'murłata',
    dimensions: '14×14×1260',  // przekrój 14×14 cm, długość 1260 cm
    quantity: 4,
    unit: 'szt.',
    notes: 'impregnowane, kotwy co 150 cm',
  },
  // 3. Płatew stolcowa — pozioma belka podpierająca krokwie
  {
    wood_type: 'płatew stolcowa',
    dimensions: '14×14×700',
    quantity: 8,
    unit: 'szt.',
  },
  // 4. Łata — podpory pod pokrycie dachowe (ilość w mb)
  {
    wood_type: 'łata',
    dimensions: '4×5',          // tylko przekrój; ilość w mb
    quantity: 640,
    unit: 'mb',
    notes: 'rozstaw 32 cm (wg karty dachówki)',
  },
  // 5. Kontrłata — wentylacja pod pokryciem
  {
    wood_type: 'kontrłata',
    dimensions: '3×5',
    quantity: 420,
    unit: 'mb',
  },
  // 6. Jętka — poprzeczka ściągająca krokwie
  {
    wood_type: 'jętka',
    dimensions: '7×16×320',
    quantity: 24,
    unit: 'szt.',
  },
  // 7. Deska — deskowanie okapu / szczytu
  {
    wood_type: 'deska',
    dimensions: '2,5×14',
    quantity: 85,
    unit: 'mb',
    notes: 'podbicie okapu',
  },
  // 8. Słup — podpora pionowa płatwi stolcowej
  {
    wood_type: 'słup',
    dimensions: '14×14×220',
    quantity: 8,
    unit: 'szt.',
  },
  // Pozycja "z ręki" — niestandardowy element
  {
    wood_type: 'listwa wiatrownicowa',   // wolny tekst
    dimensions: '2,5×12',
    quantity: 60,
    unit: 'mb',
    notes: 'zabezpieczenie krawędzi połaci',
  },
];
```

## Warianty dokumentu

| Wariant | `show_prices` | Zawiera kolumny cen | Użycie |
|---|---|---|---|
| Tylko wykaz | `false` | Nie | Klient dostarcza własne drewno; wykaz jest listą do zakupu |
| Z cenami | `true` | Tak (cena jedn. + wartość) | Firma dostarcza drewno; ceny wchodzą w ofertę |

## Format pliku wynikowego

```
artifacts/audit-trail/<offer_reference>/wood-list-<ISO-timestamp>-<sha256-8chars>.pdf
```

Przykład (generyczny):
```
artifacts/audit-trail/OF-2026-001/wood-list-2026-05-27T10-30-00-000Z-b7c2d441.pdf
```

Brak klauzuli RODO w tym dokumencie — wykaz drewna zawiera tylko adres budowy (nie imię + telefon klienta razem = nie spełnia progu „dane osobowe" zgodnie z zasadą minimalizacji RODO). Jeśli dane klienta są rozszerzone — skonsultuj `data-protection-rodo-pl`.
