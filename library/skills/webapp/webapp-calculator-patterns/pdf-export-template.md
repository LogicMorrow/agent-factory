# PDF Export Template

Companion file dla `webapp-calculator-patterns §3`.

Trzy warianty w hierarchii preference:
1. **Client-side react-pdf** (preferred) — brak server cost, szybki cold-start
2. **Server-side Next.js route handler** — fallback dla złożonych layoutów
3. **CSS @media print** — ostateczny fallback gdy react-pdf nie zadziała

---

## Wariant 1: Client-Side react-pdf (Preferred)

### Instalacja

```bash
pnpm add @react-pdf/renderer
```

### Document Template

```tsx
// components/calc-pdf-report.tsx
import { Document, Page, Text, View, Image, StyleSheet, Font } from '@react-pdf/renderer';

// Opcjonalnie — custom font
Font.register({ family: 'Inter', src: '/fonts/Inter-Regular.ttf' });

const styles = StyleSheet.create({
  page: { fontFamily: 'Inter', padding: 40, backgroundColor: '#fff' },
  header: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 24, borderBottomWidth: 2, borderBottomColor: '#2563eb', paddingBottom: 12 },
  logo: { width: 80, height: 32 },
  title: { fontSize: 20, fontWeight: 'bold', color: '#1e293b' },
  subtitle: { fontSize: 11, color: '#64748b', marginTop: 4 },
  section: { marginBottom: 20 },
  sectionTitle: { fontSize: 13, fontWeight: 'bold', color: '#2563eb', marginBottom: 8 },
  row: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 4, borderBottomWidth: 1, borderBottomColor: '#e2e8f0' },
  label: { fontSize: 10, color: '#64748b', flex: 1 },
  value: { fontSize: 10, fontWeight: 'bold', color: '#1e293b', flex: 1, textAlign: 'right' },
  total: { fontSize: 16, fontWeight: 'bold', color: '#2563eb', textAlign: 'right', marginTop: 12 },
  footer: { position: 'absolute', bottom: 24, left: 40, right: 40, fontSize: 8, color: '#94a3b8', textAlign: 'center' },
});

type CalcReportProps = {
  companyName: string;
  calcDate: string;
  items: { label: string; value: string }[];
  total: string;
  currency?: string;
};

export function CalcPDFReport({ companyName, calcDate, items, total, currency = 'PLN' }: CalcReportProps) {
  return (
    <Document title={`Wynik kalkulacji — ${companyName}`} author="Kalkulator">
      <Page size="A4" style={styles.page}>
        {/* Header z logo */}
        <View style={styles.header}>
          <Image style={styles.logo} src="/images/logo.png" />
          <View>
            <Text style={styles.title}>Wynik kalkulacji</Text>
            <Text style={styles.subtitle}>{companyName} · {calcDate}</Text>
          </View>
        </View>

        {/* Pozycje */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Szczegóły</Text>
          {items.map((item, i) => (
            <View key={i} style={styles.row}>
              <Text style={styles.label}>{item.label}</Text>
              <Text style={styles.value}>{item.value}</Text>
            </View>
          ))}
        </View>

        {/* Suma */}
        <Text style={styles.total}>Łącznie: {total} {currency}</Text>

        {/* Footer */}
        <Text style={styles.footer}>
          Dokument wygenerowany automatycznie · {calcDate} · Wynik ma charakter szacunkowy
        </Text>
      </Page>
    </Document>
  );
}
```

### Download Button (dynamic import — OBOWIĄZKOWE)

```tsx
// Konieczne: react-pdf nie działa w SSR (Canvas API)
import dynamic from 'next/dynamic';

const PDFDownloadLink = dynamic(
   => import('@react-pdf/renderer').then((m) => m.PDFDownloadLink),
  { ssr: false, loading:  => <button disabled>Ładowanie...</button> }
);

// W komponencie
<PDFDownloadLink
  document={
    <CalcPDFReport
      companyName={state.step1.nazwaFirmy}
      calcDate={new Date.toLocaleDateString('pl-PL')}
      items={buildItems(state)}
      total={formatCurrency(state.result.total)}
    />
  }
  fileName={`kalkulator-${slug}-${Date.now}.pdf`}
>
  {({ loading, error }) => (
    <button
      disabled={loading}
      className="btn-primary"
      aria-label="Pobierz wynik jako PDF"
    >
      {loading ? 'Generuję...' : error ? 'Błąd PDF' : 'Pobierz PDF'}
    </button>
  )}
</PDFDownloadLink>
```

---

## Wariant 2: Server-Side Route Handler (Next.js App Router)

Kiedy używać: złożone layouty, tabele wielostronicowe, zewnętrzny font bez CDN.

```tsx
// app/api/pdf/route.ts
import { renderToBuffer } from '@react-pdf/renderer';
import { NextRequest, NextResponse } from 'next/server';
import { CalcPDFReport } from '@/components/calc-pdf-report';
import { createElement } from 'react';

export async function POST(req: NextRequest) {
  const body = await req.json;

  // Walidacja inputu (Zod)
  const parsed = pdfRequestSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'Invalid input' }, { status: 400 });
  }

  const buffer = await renderToBuffer(
    createElement(CalcPDFReport, {
      companyName: parsed.data.companyName,
      calcDate: new Date.toLocaleDateString('pl-PL'),
      items: parsed.data.items,
      total: parsed.data.total,
    })
  );

  return new NextResponse(buffer, {
    headers: {
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="kalkulator-${parsed.data.slug}.pdf"`,
    },
  });
}
```

```tsx
// Trigger z klienta
async function downloadPDF {
  const res = await fetch('/api/pdf', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(buildPDFPayload(calcState)),
  });
  if (!res.ok) { toast.error('Błąd generowania PDF'); return; }
  const blob = await res.blob;
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `kalkulator-${slug}.pdf`;
  a.click;
  URL.revokeObjectURL(url);
}
```

---

## Wariant 3: CSS @media print (Ostateczny fallback)

Gdy react-pdf nie zadziała (starsze Safari, przeglądarki mobile bez Canvas API).

```css
/* styles/print.css */
@media print {
  .no-print { display: none !important; }
  .print-only { display: block !important; }

  body { font-family: Arial, sans-serif; font-size: 12pt; color: #000; }
  .calc-result { page-break-inside: avoid; }
  .calc-result-row { border-bottom: 1px solid #ccc; padding: 4pt 0; }
  .calc-total { font-size: 16pt; font-weight: bold; color: #000; }
}
@media screen { .print-only { display: none; } }
```

```tsx
<button
  onClick={ => window.print}
  className="btn-secondary no-print"
  aria-label="Drukuj wynik kalkulacji"
>
  Drukuj / Zapisz PDF
</button>
```

---

## Anti-wzorce

1. `import { PDFDownloadLink } from '@react-pdf/renderer'` w Server Component → crash (Canvas Node.js).
2. `ssr: true` w dynamic import react-pdf → ten sam crash.
3. Brak `URL.revokeObjectURL` po download → memory leak.
4. Logo jako `<img>` w react-pdf → `<Image>` (własna implementacja react-pdf).
5. Polskie znaki (ą ę ó) bez custom font → losowe kwadraciki (domyślne fonty PDF są ASCII).
