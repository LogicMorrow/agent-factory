# Anti-patterns — pdf-document-templates

7 typowych błędów przy implementacji generatorów PDF w PL aplikacjach biznesowych. Każdy z konsekwencją i poprawką.

---

## AP-1: Puppeteer jako silnik PDF

**Opis:** Użycie `puppeteer` lub `playwright` do generowania PDF przez renderowanie HTML w headless browser.

**Dlaczego złe:**
- Wolny: 2–5 sekund per PDF (Chromium musi się uruchomić) vs ~100–300ms w `@react-pdf/renderer`.
- Non-deterministyczny: wynik zależy od rozdzielczości, skalowania, wersji Chromium, systemu operacyjnego.
- +100–200 MB dependency (binarny Chromium) — problem w serverless/edge environments.
- Audit trail niemożliwy — ten sam dokument wygenerowany dwa razy może dać różny hash.
- Błędy page break — Chromium nie gwarantuje podziału strony w przewidywalnych miejscach.

```typescript
// Źle:
const browser = await puppeteer.launch;
const page = await browser.newPage;
await page.setContent(htmlTemplate);
const pdf = await page.pdf({ format: 'A4' });  // non-deterministyczne
await browser.close;

// Dobrze:
import { renderToBuffer } from '@react-pdf/renderer';
const buffer = await renderToBuffer(<OfferDocument data={input} company={config} />);
// ~100-300ms, deterministyczne, SHA-256 stabilny
```

---

## AP-2: Hardcode danych firmy w komponencie PDF

**Opis:** Wpisanie nazwy firmy, NIP, telefonu lub imienia właściciela jako literale string bezpośrednio w kodzie komponentu TSX.

**Dlaczego złe:**
- FAIL quality-checker — skill jest w `library/` (distribution: webapp). Każdy projekt korzystający z paczki `af-pack-<nazwa>` musi wstrzyknąć własne dane.
- FAIL audyt bezpieczeństwa — dane firmowe w kodzie mogą trafić do publicznych repo, logów CI/CD, screenshot'ów.
- Zerwanie zasady przenośności (CLAUDE.md zasada #14).
- Niemożliwa zmiana danych bez edycji kodu + deploy.

```typescript
// Źle (hardcode — FAIL QC, FAIL distribution):
function OfferHeader {
  return (
    <View>
      <Text>Moja Firma sp. z o.o.</Text>    {/* ← hardcode */}
      <Text>NIP: 1234567890</Text>          {/* ← hardcode */}
      <Text>Jan Kowalski, tel. 555-000-000</Text>  {/* ← hardcode */}
    </View>
  );
}

// Dobrze:
function OfferHeader({ company }: { company: CompanyConfig }) {
  return (
    <View>
      <Text>{company.name}</Text>
      <Text>NIP: {company.nip}</Text>
      <Text>{company.ownerName}, tel. {company.phone}</Text>
    </View>
  );
}
// company = loadCompanyConfig z process.env.COMPANY_*
```

**Tabela placeholderów** — patrz `offer-document.md` sekcja "Tabela placeholderów".

---

## AP-3: Polskie ogonki bez font embedding

**Opis:** Generowanie PDF bez rejestracji fontu obsługującego Latin Extended. Domyślne fonty w `@react-pdf/renderer` (`Helvetica`, `Times-Roman`) nie zawierają polskich znaków.

**Konsekwencja:**
- Ogonki renderują jako `□` (tofu), puste miejsca lub są pomijane.
- `„Wykaz drewna — płatew stolcowa"` → `„Wykaz drewna — p atew sto cowa"` (litery z ogonkami wycięte).
- Dokument nieczytelny dla odbiorcy.
- Brak fontów = brak RODO compliance (klauzula jest nieczytelna).

```typescript
// Źle — brak Font.register:
const styles = StyleSheet.create({
  text: { fontFamily: 'Helvetica' }  // brak ogonków
});

// Dobrze — Font.register przed pierwszym renderem:
Font.register({
  family: 'Roboto',
  fonts: [
    { src: '/fonts/roboto/Roboto-Regular.ttf', fontWeight: 'normal' },
    { src: '/fonts/roboto/Roboto-Bold.ttf', fontWeight: 'bold' },
  ],
});
// Szczegóły inicjalizacji → font-and-typography-pl.md
```

**Fallback R4:** jeśli po poprawnym font embedding ogonki nadal nie renderują — przełącz na `pdfme` (patrz ADR w `SKILL.md`).

---

## AP-4: Brak hash sha256 dla audytu

**Opis:** Generowanie PDF bez obliczania i przechowywania SHA-256 treści dokumentu.

**Konsekwencja:**
- Brak możliwości weryfikacji integralności dokumentu (czy PDF nie był modyfikowany po generacji).
- Audit trail staje się bezużyteczny — nie można powiązać pliku z sesją generacji.
- Niezgodność z OWASP ASVS L2 wymaganiami integralności danych.
- Hook `audit-trail-on-offer-write.sh` nie może zapisać pełnego wpisu audit log.

```typescript
// Źle — brak hasha:
async function generatePdf(input: QuotationPdfInput): Promise<string> {
  const buffer = await renderToBuffer(<OfferDocument data={input} company={config} />);
  const filePath = `artifacts/${input.document_number}.pdf`;
  await fs.writeFile(filePath, buffer);
  return filePath;  // tylko ścieżka — brak weryfikacji integralności
}

// Dobrze — hash sha256 zawsze:
async function generatePdf(input: QuotationPdfInput): Promise<{ path: string; sha256: string }> {
  const buffer = await renderToBuffer(<OfferDocument data={input} company={config} />);
  const sha256 = crypto.createHash('sha256').update(buffer).digest('hex');
  const shortHash = sha256.substring(0, 8);
  const filePath = `artifacts/audit-trail/${input.document_number}/${Date.now}-${shortHash}.pdf`;
  await fs.writeFile(filePath, buffer);
  return { path: filePath, sha256 };
}
```

---

## AP-5: Jeden dokument PDF dla oferty i wykazu drewna

**Opis:** Łączenie oferty robocizny i wykazu drewna w jeden plik PDF.

**Dlaczego złe:**
- Klient może potrzebować tylko ofertę (bez drewna, jeśli sam kupuje materiały).
- Klauzula RODO musi być w ofercie — ale NIE w wykazie drewna (który to dokument techniczny). Łączenie = klauzula RODO w dokumencie technicznym = mylące dla klienta.
- Trudniejsze do archiwizowania — nie można wysłać tylko jednego z dokumentów.
- Audit trail — dwa dokumenty mają osobne sha256 (ich integralność jest niezależna).
- Wykaz drewna jest opcjonalny (gdy klient dostarcza drewno — PDF wykazowy nie jest generowany).

```typescript
// Źle — jeden PDF:
function OfferAndWoodListDocument({ offer, woodList }) {
  return (
    <Document>
      <Page>{/* ... oferta ... */}</Page>
      <Page>{/* ... wykaz drewna ... */}</Page>  {/* ← na tej samej stronie klauzula RODO */}
    </Document>
  );
}

// Dobrze — dwa osobne pliki:
const [offerResult, woodResult] = await Promise.all([
  renderOfferPdf(quotationInput),     // zawiera klauzulę RODO
  woodListInput
    ? renderWoodListPdf(woodListInput)  // BEZ klauzuli RODO
    : Promise.resolve(null),
]);
// operator pobiera 1 lub 2 pliki niezależnie
```

---

## AP-6: Zaokrąglenia VAT na pośrednich wartościach

**Opis:** Zaokrąglanie kwot netto per pozycję przed zsumowaniem.

**Konsekwencja:** Grosz lub dwa różnicy w sumie końcowej — rozbieżność między wartością w systemie a kwotą na dokumencie. Może powodować spory przy weryfikacji podatkowej.

```typescript
// Źle — zaokrąglenie pośrednie:
const items = [{ amount: 1333.33 }, { amount: 2666.67 }];
const netRounded = items.map(i => Math.round(i.amount * 100) / 100);  // [1333.33, 2666.67]
const total = netRounded.reduce((s, v) => s + v, 0);  // 4000.00 ✓ — ale w złożonych przypadkach błąd
const vat = Math.round(total * 0.08 * 100) / 100;    // zwykłe zaokrąglenie — nie bankowe

// Dobrze — zaokrąglenie tylko wyniku końcowego, reguła bankowa:
const total = items.reduce((s, i) => s + i.amount, 0);   // nie zaokrąglaj pozycji
const vat = roundBankers(total * 0.08, 2);                // bankowe zaokrąglenie
const gross = roundBankers(total + vat, 2);
// roundBankers — implementacja w quotation-pl-rules/struktura-oferty.md
```

---

## AP-7: Brak strony 2 (overflow bez paginacji)

**Opis:** Oferta z wieloma pozycjami lub długą klauzulą RODO przekracza rozmiar strony A4 — zawartość jest przycinana lub zachodzi na stopkę.

**Konsekwencja:** Nieczytelny dokument, obcięta klauzula RODO (naruszenie art. 13 RODO — klient nie otrzymuje pełnej informacji).

```tsx
// Źle — brak wrap + brak fixed footer:
<Page size="A4">
  <Text>... (100 pozycji) ...</Text>  // przekracza A4, reszta obcięta
  <InformationClause />               // może być na następnej stronie lub obcięta
</Page>

// Dobrze — @react-pdf/renderer automatycznie paginuje przy poprawnym użyciu:
// 1. Nie używaj position: absolute dla treści (tylko dla footera)
// 2. Użyj `fixed` prop dla stopki (wyświetla się na każdej stronie)
// 3. Sprawdź czy klauzula RODO ma `break: 'avoid'` (nie dziel w połowie)

<Page size="A4" style={pageStyle}>
  {/* treść scrolluje automatycznie na następne strony */}
  <View style={{ flexGrow: 1 }}>
    {items.map(...)}
    <InformationClause style={{ breakInside: 'avoid' }} />
  </View>

  {/* stopka z numeracją — fixed = pojawia się na każdej stronie */}
  <Text
    style={footerStyle}
    render={({ pageNumber, totalPages }) => `Strona ${pageNumber} z ${totalPages}`}
    fixed
  />
</Page>
```
