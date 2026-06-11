---
name: pdf-document-templates
description: Szablony PDF (oferta robocizny + wykaz drewna) dla aplikacji ofertującej PL używające @react-pdf/renderer. Polska typografia (ogonki + PLN + DD.MM.YYYY), placeholders dla danych firmy (z env), hash sha256 dla audytu, kontrakt A consumer (z quotation-pl-rules + roofing-domain-rules). Uruchamiaj gdy projektujesz generowanie PDF dla apki ofertującej.
version: "1.0.0"
compatible_with: [webapp]
tags: [pdf, react-pdf, poland, templates, audit-trail]
requires: [webapp-standards, quotation-pl-rules, roofing-domain-rules, data-protection-rodo-pl]
token_cost: medium
distribution: library/skills/webapp/
last_updated: 2026-05-27
last_reviewed: 2026-05-29
valid_until: 2027-05-27
---

# pdf-document-templates

Szablony PDF dwóch dokumentów biznesowych dla branży dekarskiej PL: oferty robocizny i wykazu drewna. Deterministyczny layout, polska typografia z obsługą ogonków, ZERO hardcode danych firmy, hash sha256 dla audit-trail.

## Kiedy uruchomić

Uruchom ten skill gdy:
- Implementujesz generowanie PDF oferty ryczałtowej lub wykazu drewna w Next.js.
- Potrzebujesz gotowych komponentów TSX dla `@react-pdf/renderer` z PL typografią.
- Projektujesz kontrakt danych między modułem ofertowania a generatorem PDF.
- Wdrażasz audit-trail dla generowanych dokumentów (hash sha256, ścieżki archiwum).

Nie uruchamiaj gdy:
- Generujesz fakturę VAT (inny dokument prawny, poza zakresem).
- Używasz innej biblioteki PDF niż `@react-pdf/renderer` (sprawdź ADR poniżej).
- Projekt nie ma PL typografii — ten skill zakłada Roboto z PL ogonkami.

---

## ADR — Wybór biblioteki PDF

**Status:** ACCEPTED 2026-05-27
**Decyzja:** `@react-pdf/renderer` jako domyślna biblioteka do generowania PDF.

| Biblioteka | Zalety | Wady | Decyzja |
|---|---|---|---|
| **`@react-pdf/renderer`** | React API (TSX), deterministyczny layout, dobry TypeScript, aktywny rozwój | Wymaga font embedding dla ogonków | **DEFAULT** |
| `pdfme` | Szablony JSON, prosty | Słabszy TypeScript, mniej elastyczne layouty | Fallback R4 (patrz poniżej) |
| `pdfkit` | Niskopoziomowy, precyzyjny | Brak React API, verbose kod, brak TSX | Odrzucony |
| `puppeteer` | HTML → PDF, pełny CSS | Non-deterministyczny, wolny, plik binarny Chromium (+100MB) | Odrzucony (anti-pattern #1) |

**R4 Fallback (risk-matrix master plan):** Jeśli polskie ogonki (ą, ć, ę, ł, ń, ó, ś, ź, ż) lub tabele wielokolumnowe nie renderują poprawnie w `@react-pdf/renderer` po dodaniu Roboto — przełącz na `pdfme`. Test ogonków obowiązkowy przed wdrożeniem (patrz `font-and-typography-pl.md`).

---

## Pliki tematyczne (indeks)

| Plik | Zawartość |
|---|---|
| [`offer-document.md`](offer-document.md) | Pełna specyfikacja `OfferDocument` + TSX przykład |
| [`wood-list-document.md`](wood-list-document.md) | Pełna specyfikacja `WoodListDocument` + TSX przykład z 8 typami drewna |
| [`font-and-typography-pl.md`](font-and-typography-pl.md) | Font embedding, ogonki, format liczb PL, format dat PL |
| [`kontrakt-A-consumer.md`](kontrakt-A-consumer.md) | TypeScript interfaces + funkcje wywoławcze `renderOfferPdf` / `renderWoodListPdf` |
| [`anti-patterns.md`](anti-patterns.md) | 7 anti-patterns z konsekwencjami |

---

## Kluczowe zasady

1. **ZERO hardcode danych firmy** — nazwa, NIP, właściciel, telefon ZAWSZE z `process.env.COMPANY_*` lub obiektu konfiguracji. Nigdy jako literal string w komponencie.
2. **Dwa osobne dokumenty** — `OfferDocument` (oferta robocizny) i `WoodListDocument` (wykaz drewna) to dwa oddzielne komponenty. Nie łącz w jeden plik PDF.
3. **Font embedding obowiązkowy** — `@react-pdf/renderer` wymaga rejestracji fontu z ogonkami przed renderem. Brak embedding = znaki zastępcze zamiast ą/ę/ó/ś (anti-pattern #3).
4. **Hash sha256 przy każdej generacji** — każdy wygenerowany PDF musi mieć obliczony hash sha256 treści. Hash trafia do nazwy pliku i audit-trail.
5. **Hash łańcuchowy** — kolejny PDF = sha256(content + prev_hash). Dokumentuje sekwencję wersji oferty.
6. **Ścieżka archiwum** — `artifacts/audit-trail/<offer_id>/<ISO-timestamp>-<sha256-8chars>.pdf`. Pliki append-only — nigdy nie nadpisuj, zawsze nowy plik przy każdej generacji.
7. **Format liczb PL** — `1 500,00 PLN` (spacja jako separator tysięcy, przecinek dziesiętny, sufiks PLN). Implementacja w `font-and-typography-pl.md`.
8. **Format dat PL** — `DD.MM.YYYY`. NIE ISO 8601 na dokumentach klientów.
9. **A4 portrait, marginesy 20mm** — standard PL. Numeracja stron (Strona X z Y) w stopce.
10. **Klauzula RODO w OfferDocument** — Wariant B z `data-protection-rodo-pl/klauzula-informacyjna-szablon.md`. WoodListDocument nie zawiera klauzuli (dokument techniczny bez danych osobowych).

---

## Przykłady: dobrze vs źle

### Para 1 — Dane firmy w nagłówku

Źle:
```tsx
// Hardcode danych firmy w kodzie — FAIL QC, FAIL distribution
// Skill jest w library/ — każdy projekt musi wstrzyknąć własne dane
function OfferHeader {
  return (
    <View>
      <Text><NAZWA_FIRMY> sp. z o.o.</Text>  {/* ← literal string */}
      <Text>NIP: <NIP></Text>                {/* ← literal string */}
      <Text><WLASCICIEL>, tel. <TELEFON></Text>  {/* ← literal string */}
    </View>
  );
}
```

Dobrze:
```tsx
// Dane z konfiguracji — zawsze przez props / env
interface CompanyConfig {
  name: string;       // process.env.COMPANY_NAME
  nip: string;        // process.env.COMPANY_NIP
  ownerName: string;  // process.env.COMPANY_OWNER
  phone: string;      // process.env.COMPANY_PHONE
}

function OfferHeader({ company }: { company: CompanyConfig }) {
  return (
    <View>
      <Text>{company.name}</Text>
      <Text>NIP: {company.nip}</Text>
      <Text>{company.ownerName}, tel. {company.phone}</Text>
    </View>
  );
}
```

### Para 2 — Generacja PDF z hashem sha256

Źle:
```typescript
// Brak hasha — żaden ślad wersji dokumentu, audit trail bezużyteczny
async function generatePdf(input: QuotationPdfInput): Promise<string> {
  const buffer = await renderToBuffer(<OfferDocument data={input} />);
  const filePath = `artifacts/${input.document_number}.pdf`;
  await fs.writeFile(filePath, buffer);
  return filePath;  // tylko ścieżka — brak sha256, nadpisuje poprzedni PDF
}
```

Dobrze:
```typescript
import crypto from 'crypto';

async function renderOfferPdf(
  input: QuotationPdfInput,
  prevHash: string | null = null,
): Promise<{ path: string; sha256: string }> {
  const config = loadCompanyConfig; // z process.env.COMPANY_*
  const buffer = await renderToBuffer(<OfferDocument data={input} company={config} />);

  // Hash łańcuchowy: sha256(content + prevHash) lub sha256(content) dla v1
  const hashInput = prevHash
    ? Buffer.concat([buffer, Buffer.from(prevHash, 'hex')])
    : buffer;
  const sha256 = crypto.createHash('sha256').update(hashInput).digest('hex');

  const timestamp = new Date.toISOString.replace(/[:.]/g, '-');
  const dir = `artifacts/audit-trail/${input.document_number.replace(/\//g, '-')}`;
  await fs.mkdir(dir, { recursive: true });
  const filePath = `${dir}/${timestamp}-${sha256.substring(0, 8)}.pdf`;
  await fs.writeFile(filePath, buffer);  // append-only — nowy plik per generacja

  return { path: filePath, sha256 };
}
```

---

## Antywzorce

Pełna lista w [`anti-patterns.md`](anti-patterns.md). Skrót:

1. **Puppeteer jako PDF engine** — wolny (+3s/PDF), non-deterministyczny, +100MB dependency (Chromium).
2. **Hardcode danych firmy** — skill jest w `library/` i musi być przenośny. Dane konkretnej firmy = `.env` / karta projektu.
3. **Polskie ogonki bez font embedding** — `@react-pdf/renderer` domyślnie używa Helvetica (bez ogonków). Brak rejestracji Roboto = znaki zastępcze.
4. **Brak hash sha256** — brak możliwości weryfikacji integralności dokumentu. Audit trail nieużyteczny bez identyfikatora treści.
5. **Jeden dokument PDF dla oferty + drewna** — oferta i wykaz to osobne dokumenty. Klient może potrzebować tylko jeden. Klauzula RODO należy tylko do oferty.

---

## Powiązania

- **`quotation-pl-rules`** (universal) — dostarcza `QuotationPdfInput` interface + reguły zaokrągleń VAT. Kontrakt danych w `kontrakt-A-consumer.md`.
- **`roofing-domain-rules`** (universal) — typy drewna, formaty wymiarów, nazewnictwo PL. Dane do `WoodListDocument`.
- **`data-protection-rodo-pl`** (universal) — klauzula RODO art. 13 z `klauzula-informacyjna-szablon.md`. Komponent `InformationClause` w `OfferDocument`.
- **`pdf-document-generator`** (agent, sonnet) — agent implementujący ten skill. Wywołuje `renderOfferPdf` / `renderWoodListPdf`.
- **`offer-builder`** (agent, sonnet) — orchestrator łączący dane klienta + pozycje wyceny + wykaz drewna przed wywołaniem generatora.
- **`audit-trail-on-offer-write.sh`** (hook) — hook PostToolUse tworzący snapshoty. Ścieżka `artifacts/audit-trail/` jest wspólna.
- **`font-and-typography-pl.md`** (plik tematyczny) — pełna instrukcja font embedding i formatowania PL.
