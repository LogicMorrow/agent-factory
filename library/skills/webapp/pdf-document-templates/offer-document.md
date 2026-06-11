# OfferDocument — Oferta robocizny PDF

Specyfikacja komponentu TSX `OfferDocument` dla `@react-pdf/renderer`. Renderuje profesjonalną ofertę ryczałtową robocizny dekarskiej (lub innej branży budowlanej) w formacie A4 PL.

## Struktura dokumentu (sekcje w kolejności)

```
[1] Nagłówek (dane firmy + opcjonalne logo)
[2] Tytuł dokumentu + numer + data wystawienia
[3] Dane klienta
[4] Przedmiot oferty (opis zlecenia)
[5a] Tryb SUMMARY: tylko sumy (netto + VAT + brutto)
[5b] Tryb DETAILED: tabela pozycji kosztorysowych + sumy
[6] Warunki (ważność, płatności, termin wykonania)
[7] Podpis / pieczątka (placeholder na podpis ręczny)
[8] Klauzula RODO (art. 13 — Wariant B skrócony)
[9] Stopka (numeracja stron + data wydruku)
```

## Props interface

```typescript
import type { QuotationPdfInput } from '../quotation-pl-rules/struktura-oferty';
import type { CompanyConfig } from './kontrakt-A-consumer';

interface OfferDocumentProps {
  data: QuotationPdfInput;       // kontrakt z quotation-pl-rules
  company: CompanyConfig;        // z process.env.COMPANY_*
  logoPath?: string;             // opcjonalne: ścieżka do pliku logo (PNG/JPG)
  accentColor?: string;          // opcjonalne: hex koloru akcentu (default '#555555')
}
```

## Przykład TSX — OfferDocument

```tsx
// components/pdf/OfferDocument.tsx
// WAŻNE: Ten plik NIE zawiera danych konkretnej firmy.
// Dane firmy (name, nip, ownerName, phone) przekazywane przez props.

import React from 'react';
import {
  Document,
  Page,
  Text,
  View,
  Image,
  StyleSheet,
  Font,
} from '@react-pdf/renderer';
import type { QuotationPdfInput } from '../../lib/types/quotation';
import type { CompanyConfig } from '../../lib/types/pdf-config';
import { InformationClause } from './InformationClause';
import { formatAmountPl, formatDatePl, PAGE_STYLES } from './pdf-utils';

// Font rejestracja — patrz font-and-typography-pl.md
// Font.register(...) wywołane globalnie w pdf-utils.ts

const styles = StyleSheet.create({
  page: {
    ...PAGE_STYLES.a4Portrait,    // A4, marginesy 20mm
    fontSize: 10,
    fontFamily: 'Roboto',
    color: '#1a1a1a',
  },
  // --- Nagłówek ---
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 16,
    paddingBottom: 12,
    borderBottomWidth: 1.5,
    borderBottomColor: '#cccccc',
  },
  companyBlock: {
    flex: 1,
  },
  companyName: {
    fontSize: 13,
    fontWeight: 'bold',
    marginBottom: 2,
  },
  companyDetail: {
    fontSize: 8.5,
    color: '#555555',
    lineHeight: 1.4,
  },
  logo: {
    width: 80,
    height: 40,
    objectFit: 'contain',
    marginLeft: 10,
  },
  // --- Tytuł ---
  titleBlock: {
    marginBottom: 14,
  },
  titleText: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 3,
  },
  titleMeta: {
    fontSize: 9,
    color: '#555555',
  },
  // --- Klient ---
  sectionTitle: {
    fontSize: 10,
    fontWeight: 'bold',
    marginBottom: 5,
    marginTop: 10,
    paddingBottom: 2,
    borderBottomWidth: 0.5,
    borderBottomColor: '#cccccc',
  },
  row: {
    flexDirection: 'row',
    marginBottom: 2,
  },
  label: {
    fontSize: 9,
    color: '#666666',
    width: 120,
  },
  value: {
    fontSize: 9,
    flex: 1,
  },
  // --- Tabela pozycji (tryb detailed) ---
  table: {
    marginTop: 8,
    marginBottom: 8,
  },
  tableHeader: {
    flexDirection: 'row',
    backgroundColor: '#f0f0f0',
    borderWidth: 0.5,
    borderColor: '#cccccc',
    paddingVertical: 4,
    paddingHorizontal: 6,
    fontSize: 8.5,
    fontWeight: 'bold',
  },
  tableRow: {
    flexDirection: 'row',
    borderBottomWidth: 0.5,
    borderBottomColor: '#e0e0e0',
    paddingVertical: 4,
    paddingHorizontal: 6,
    fontSize: 9,
  },
  tableRowAlt: {
    backgroundColor: '#f9f9f9',
  },
  colNo: { width: 22 },
  colLabel: { flex: 1 },
  colAmount: { width: 90, textAlign: 'right' },
  colNotes: { width: 100, fontSize: 8, color: '#666666' },
  // --- Sumy ---
  totalsBlock: {
    marginTop: 8,
    alignItems: 'flex-end',
  },
  totalRow: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    marginBottom: 2,
  },
  totalLabel: {
    fontSize: 9,
    width: 140,
    textAlign: 'right',
    paddingRight: 10,
    color: '#555555',
  },
  totalValue: {
    fontSize: 9,
    width: 100,
    textAlign: 'right',
  },
  totalBrutto: {
    fontSize: 11,
    fontWeight: 'bold',
  },
  totalBruttoValue: {
    fontSize: 11,
    fontWeight: 'bold',
    width: 100,
    textAlign: 'right',
  },
  // --- Warunki ---
  conditionsBlock: {
    marginTop: 12,
    fontSize: 8.5,
    color: '#444444',
    lineHeight: 1.5,
  },
  conditionItem: {
    marginBottom: 2,
  },
  // --- Podpis ---
  signatureBlock: {
    marginTop: 24,
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  signatureLine: {
    width: 200,
    borderBottomWidth: 0.5,
    borderBottomColor: '#888888',
    paddingBottom: 2,
    marginBottom: 4,
  },
  signatureCaption: {
    fontSize: 8,
    color: '#888888',
  },
  // --- Stopka ---
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

export function OfferDocument({ data, company, logoPath, accentColor = '#555555' }: OfferDocumentProps) {
  const isDetailed = data.render_mode === 'detailed';

  return (
    <Document
      title={`Oferta ${data.document_number}`}
      author={company.name}
      subject="Oferta robocizny"
    >
      <Page size="A4" style={styles.page}>

        {/* [1] Nagłówek */}
        <View style={styles.header}>
          <View style={styles.companyBlock}>
            <Text style={styles.companyName}>{company.name}</Text>
            <Text style={styles.companyDetail}>NIP: {company.nip}</Text>
            <Text style={styles.companyDetail}>{company.ownerName}</Text>
            <Text style={styles.companyDetail}>tel. {company.phone}</Text>
            {company.address && (
              <Text style={styles.companyDetail}>{company.address}</Text>
            )}
          </View>
          {logoPath ? (
            <Image src={logoPath} style={styles.logo} />
          ) : null}
        </View>

        {/* [2] Tytuł */}
        <View style={styles.titleBlock}>
          <Text style={styles.titleText}>OFERTA ROBOCIZNY</Text>
          <Text style={styles.titleMeta}>
            Nr: {data.document_number}  |  Data wystawienia: {formatDatePl(data.issue_date)}  |  Ważna do: {formatDatePl(data.valid_until)}
          </Text>
        </View>

        {/* [3] Dane klienta */}
        <Text style={styles.sectionTitle}>Zamawiający</Text>
        <View style={styles.row}>
          <Text style={styles.label}>Imię i nazwisko:</Text>
          <Text style={styles.value}>{data.client.name}</Text>
        </View>
        <View style={styles.row}>
          <Text style={styles.label}>Adres budowy:</Text>
          <Text style={styles.value}>{data.client.address}</Text>
        </View>
        {data.client.phone && (
          <View style={styles.row}>
            <Text style={styles.label}>Telefon:</Text>
            <Text style={styles.value}>{data.client.phone}</Text>
          </View>
        )}
        {data.client.nip && (
          <View style={styles.row}>
            <Text style={styles.label}>NIP:</Text>
            <Text style={styles.value}>{data.client.nip}</Text>
          </View>
        )}

        {/* [4] Przedmiot oferty */}
        <Text style={styles.sectionTitle}>Przedmiot oferty</Text>
        <View style={styles.row}>
          <Text style={styles.label}>Opis zlecenia:</Text>
          <Text style={styles.value}>{data.job.description}</Text>
        </View>
        {data.job.building_area_m2 && (
          <View style={styles.row}>
            <Text style={styles.label}>Pow. użytkowa:</Text>
            <Text style={styles.value}>{data.job.building_area_m2} m²</Text>
          </View>
        )}
        {data.job.estimated_duration && (
          <View style={styles.row}>
            <Text style={styles.label}>Czas realizacji:</Text>
            <Text style={styles.value}>{data.job.estimated_duration}</Text>
          </View>
        )}

        {/* [5] Pozycje lub tryb summary */}
        {isDetailed ? (
          <>
            <Text style={styles.sectionTitle}>Pozycje kosztorysowe</Text>
            <View style={styles.table}>
              {/* Nagłówek tabeli */}
              <View style={styles.tableHeader}>
                <Text style={styles.colNo}>Lp.</Text>
                <Text style={styles.colLabel}>Zakres robót</Text>
                <Text style={styles.colAmount}>Cena netto</Text>
                <Text style={styles.colNotes}>Uwagi</Text>
              </View>
              {/* Wiersze */}
              {data.items.map((item, idx) => (
                <View
                  key={idx}
                  style={[styles.tableRow, idx % 2 === 1 ? styles.tableRowAlt : {}]}
                >
                  <Text style={styles.colNo}>{idx + 1}.</Text>
                  <Text style={styles.colLabel}>{item.label_pl}</Text>
                  <Text style={styles.colAmount}>{formatAmountPl(item.amount_net_pln)}</Text>
                  <Text style={styles.colNotes}>{item.notes ?? ''}</Text>
                </View>
              ))}
            </View>
          </>
        ) : (
          <Text style={[styles.sectionTitle, { marginBottom: 8 }]}>Wartość oferty</Text>
        )}

        {/* Sumy */}
        <View style={styles.totalsBlock}>
          <View style={styles.totalRow}>
            <Text style={styles.totalLabel}>Razem netto:</Text>
            <Text style={styles.totalValue}>{formatAmountPl(data.totals.net_pln)}</Text>
          </View>
          <View style={styles.totalRow}>
            <Text style={styles.totalLabel}>
              VAT ({Math.round(data.vat_rate * 100)}% — {data.vat_justification}):
            </Text>
            <Text style={styles.totalValue}>{formatAmountPl(data.totals.vat_amount_pln)}</Text>
          </View>
          <View style={styles.totalRow}>
            <Text style={styles.totalBrutto}>RAZEM BRUTTO:</Text>
            <Text style={styles.totalBruttoValue}>{formatAmountPl(data.totals.gross_pln)}</Text>
          </View>
        </View>

        {/* [6] Warunki */}
        <Text style={styles.sectionTitle}>Warunki oferty</Text>
        <View style={styles.conditionsBlock}>
          <Text style={styles.conditionItem}>
            • Oferta ważna do: {formatDatePl(data.valid_until)} (14 dni od daty wystawienia).
          </Text>
          <Text style={styles.conditionItem}>
            • Warunki płatności: {data.payment_terms.advance_percent}% zaliczki przy podpisaniu umowy,
            {' '}{data.payment_terms.remaining_percent}% po odbiorze robót.
            Płatność w ciągu {data.payment_terms.payment_due_days} dni.
          </Text>
          {data.job.estimated_duration && (
            <Text style={styles.conditionItem}>
              • Szacowany czas realizacji: {data.job.estimated_duration}.
            </Text>
          )}
          <Text style={styles.conditionItem}>
            • Oferta dotyczy wyłącznie robocizny. Materiały wyceniane osobno, chyba że zaznaczono inaczej w pozycjach.
          </Text>
          <Text style={styles.conditionItem}>
            • Ceny obejmują wszystkie niezbędne prace w podanym zakresie.
          </Text>
        </View>

        {/* [7] Podpis */}
        <View style={styles.signatureBlock}>
          <View>
            <View style={styles.signatureLine} />
            <Text style={styles.signatureCaption}>Data i podpis zamawiającego</Text>
          </View>
          <View>
            <View style={styles.signatureLine} />
            <Text style={styles.signatureCaption}>
              Podpis oferenta — {company.ownerName}
            </Text>
          </View>
        </View>

        {/* [8] Klauzula RODO */}
        <InformationClause
          companyName={company.name}
          nip={company.nip}
          ownerName={company.ownerName}
          ownerPhone={company.phone}
        />

        {/* [9] Stopka z numeracją stron */}
        <Text
          style={styles.footer}
          render={({ pageNumber, totalPages }) =>
            `${company.name}  |  Oferta nr ${data.document_number}  |  Strona ${pageNumber} z ${totalPages}  |  Wydrukowano: ${formatDatePl(new Date.toISOString)}`
          }
          fixed
        />
      </Page>
    </Document>
  );
}
```

## Tabela placeholderów (props company)

| Pole `company.*` | Env var | Opis | Przykład wartości (generyczny) |
|---|---|---|---|
| `company.name` | `COMPANY_NAME` | Pełna nazwa prawna | `<NAZWA_FIRMY>` |
| `company.nip` | `COMPANY_NIP` | NIP (10 cyfr) | `<NIP>` |
| `company.ownerName` | `COMPANY_OWNER` | Właściciel / osoba kontaktowa | `<WLASCICIEL>` |
| `company.phone` | `COMPANY_PHONE` | Telefon kontaktowy | `<TELEFON>` |
| `company.address` | `COMPANY_ADDRESS` | Adres firmy (opcjonalny) | `<ADRES_FIRMY>` |
| `company.iban` | `COMPANY_IBAN` | IBAN do przelewów (opcjonalny) | `<IBAN>` |
| `logoPath` | `COMPANY_LOGO_PATH` | Ścieżka do pliku logo (opcjonalna) | `<LOGO_PATH>` |
| `accentColor` | `PDF_ACCENT_COLOR` | Kolor akcentu hex (opcjonalny) | `#555555` |

## Tryb summary vs detailed

| Tryb | Co renderuje | Kiedy używać |
|---|---|---|
| `summary` | Tylko 3 wiersze: netto + VAT + brutto | Gdy klient prosi o cenę „bez szczegółów"; Oferta uproszczona |
| `detailed` | Tabela wszystkich pozycji + sumy | Oferta formalna; klient chce wiedzieć co za co |

Wybór trybu kontroluje pole `render_mode: 'summary' | 'detailed'` w `QuotationPdfInput` (kontrakt z `quotation-pl-rules/struktura-oferty.md`).

## Format pliku wynikowego

```
artifacts/audit-trail/<document_number>/<ISO-timestamp>-<sha256-8chars>.pdf
```

Przykład (generyczny):
```
artifacts/audit-trail/OF-2026-001/2026-05-27T10-30-00-000Z-a3f8e921.pdf
```

Szczegóły ścieżki i hash łańcuchowy — patrz `kontrakt-A-consumer.md` sekcja "Audit trail".
