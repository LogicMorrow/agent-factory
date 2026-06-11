# Kontrakt A — Consumer PDF generator

Kontrakt danych między modułem ofertowania a generatorem PDF. Definiuje TypeScript interfaces, funkcje wywoławcze, audit trail i loader konfiguracji firmy z `process.env`.

## Architektura przepływu danych

```
[offer-builder agent]
    │
    │ QuotationPdfInput (z quotation-pl-rules/struktura-oferty.md)
    │ WoodListInput (z wood-list-document.md)
    ▼
[renderOfferPdf / renderWoodListPdf]
    │
    │ CompanyConfig (z process.env.COMPANY_*)
    ├─ OfferDocument TSX ──────────────────────────► PDF buffer
    │ WoodListDocument TSX ────────────────────────► PDF buffer
    │
    │ sha256(buffer) → hash
    │
    ▼
artifacts/audit-trail/<offer_id>/<timestamp>-<hash8>.pdf
```

## CompanyConfig — konfiguracja firmy z env

```typescript
// lib/types/pdf-config.ts

/**
 * Konfiguracja firmy ładowana z process.env.
 * NIE zawiera hardcode danych konkretnej firmy.
 * Wszystkie wartości z .env (lub secrets manager).
 */
export interface CompanyConfig {
  name: string;         // process.env.COMPANY_NAME — pełna nazwa prawna
  nip: string;          // process.env.COMPANY_NIP — 10 cyfr
  ownerName: string;    // process.env.COMPANY_OWNER — właściciel / osoba kontaktowa
  phone: string;        // process.env.COMPANY_PHONE — telefon kontaktowy
  address?: string;     // process.env.COMPANY_ADDRESS — opcjonalny adres firmy
  iban?: string;        // process.env.COMPANY_IBAN — opcjonalny IBAN do przelewów
}

/**
 * Ładuje konfigurację firmy z process.env.
 * Rzuca błąd jeśli wymagane zmienne są niezdefiniowane.
 * Wywołuj po stronie serwera (API route / server action).
 */
export function loadCompanyConfig: CompanyConfig {
  const required = {
    name: process.env.COMPANY_NAME,
    nip: process.env.COMPANY_NIP,
    ownerName: process.env.COMPANY_OWNER,
    phone: process.env.COMPANY_PHONE,
  };

  for (const [key, value] of Object.entries(required)) {
    if (!value) {
      throw new Error(
        `[pdf-config] Brak wymaganej zmiennej środowiskowej: COMPANY_${key.toUpperCase}. ` +
        `Dodaj do .env.local lub secrets.`
      );
    }
  }

  return {
    name: required.name!,
    nip: required.nip!,
    ownerName: required.ownerName!,
    phone: required.phone!,
    address: process.env.COMPANY_ADDRESS,
    iban: process.env.COMPANY_IBAN,
  };
}
```

## Wymagane zmienne środowiskowe

| Zmienna | Wymagana | Opis | Format |
|---|---|---|---|
| `COMPANY_NAME` | TAK | Pełna nazwa prawna firmy | `<NAZWA_FIRMY> sp. z o.o.` |
| `COMPANY_NIP` | TAK | NIP firmy | 10 cyfr bez myślników |
| `COMPANY_OWNER` | TAK | Imię i nazwisko właściciela / kontaktu | `<IMIE> <NAZWISKO>` |
| `COMPANY_PHONE` | TAK | Telefon kontaktowy | `000 000 000` |
| `COMPANY_ADDRESS` | NIE | Adres firmy (opcjonalny) | `ul. Przykładowa 1, 00-001 Miasto` |
| `COMPANY_IBAN` | NIE | IBAN do przelewów | `PL00 0000 0000 0000 0000 0000 0000` |
| `COMPANY_LOGO_PATH` | NIE | Ścieżka do logo (filesystem) | `/app/public/logo.png` |
| `PDF_ACCENT_COLOR` | NIE | Kolor akcentu hex | `#555555` |

Przykład `.env.local` (NIGDY nie commitować z prawdziwymi danymi):
```env
# .env.local — wypełnij danymi projektu
COMPANY_NAME=<NAZWA_FIRMY> sp. z o.o.
COMPANY_NIP=<NIP>
COMPANY_OWNER=<WLASCICIEL>
COMPANY_PHONE=<TELEFON>
# COMPANY_ADDRESS=
# COMPANY_IBAN=
# COMPANY_LOGO_PATH=
# PDF_ACCENT_COLOR=#555555
```

## renderOfferPdf — funkcja wywoławcza

```typescript
// lib/pdf/render-offer-pdf.ts

import crypto from 'crypto';
import fs from 'fs/promises';
import path from 'path';
import { renderToBuffer } from '@react-pdf/renderer';
import React from 'react';
import { OfferDocument } from '../../components/pdf/OfferDocument';
import { loadCompanyConfig } from '../types/pdf-config';
import type { QuotationPdfInput } from '../types/quotation';

// Inicjalizacja fontów — obowiązkowe przed pierwszym renderem
import './pdf-utils';

export interface PdfRenderResult {
  path: string;        // absolutna lub relative ścieżka do pliku PDF
  sha256: string;      // hex hash SHA-256 treści pliku
  sizeBytes: number;   // rozmiar pliku w bajtach
}

/**
 * Renderuje ofertę robocizny do pliku PDF.
 * Oblicza SHA-256 treści i zapisuje do audit-trail.
 * Obsługuje hash łańcuchowy (patrz sekcja Audit trail).
 *
 * @param input - dane oferty (kontrakt z quotation-pl-rules/struktura-oferty.md)
 * @param prevHash - hash poprzedniej wersji oferty (do hash łańcuchowego); null dla v1
 * @returns ścieżka pliku + sha256 + rozmiar
 */
export async function renderOfferPdf(
  input: QuotationPdfInput,
  prevHash: string | null = null,
): Promise<PdfRenderResult> {
  const company = loadCompanyConfig;
  const logoPath = process.env.COMPANY_LOGO_PATH;
  const accentColor = process.env.PDF_ACCENT_COLOR ?? '#555555';

  // Renderuj do bufora
  const element = React.createElement(OfferDocument, {
    data: input,
    company,
    logoPath,
    accentColor,
  });
  const buffer = await renderToBuffer(element);

  // Oblicz SHA-256 (hash łańcuchowy gdy prevHash podany)
  const hashInput = prevHash
    ? Buffer.concat([buffer, Buffer.from(prevHash, 'hex')])
    : buffer;
  const sha256 = crypto.createHash('sha256').update(hashInput).digest('hex');

  // Zapisz do audit-trail
  const offerId = input.document_number.replace(/\//g, '-');
  const timestamp = new Date.toISOString.replace(/[:.]/g, '-');
  const shortHash = sha256.substring(0, 8);
  const dir = path.join('artifacts', 'audit-trail', offerId);
  await fs.mkdir(dir, { recursive: true });
  const filePath = path.join(dir, `${timestamp}-${shortHash}.pdf`);
  await fs.writeFile(filePath, buffer);

  return {
    path: filePath,
    sha256,
    sizeBytes: buffer.length,
  };
}
```

## renderWoodListPdf — funkcja wywoławcza

```typescript
// lib/pdf/render-wood-list-pdf.ts

import crypto from 'crypto';
import fs from 'fs/promises';
import path from 'path';
import { renderToBuffer } from '@react-pdf/renderer';
import React from 'react';
import { WoodListDocument } from '../../components/pdf/WoodListDocument';
import { loadCompanyConfig } from '../types/pdf-config';
import type { WoodListInput } from '../types/wood-list';

import './pdf-utils'; // inicjalizacja fontów

export async function renderWoodListPdf(
  input: WoodListInput,
  prevHash: string | null = null,
): Promise<PdfRenderResult> {
  const company = loadCompanyConfig;

  const element = React.createElement(WoodListDocument, { data: input, company });
  const buffer = await renderToBuffer(element);

  const hashInput = prevHash
    ? Buffer.concat([buffer, Buffer.from(prevHash, 'hex')])
    : buffer;
  const sha256 = crypto.createHash('sha256').update(hashInput).digest('hex');

  const offerId = input.offer_reference.replace(/\//g, '-');
  const timestamp = new Date.toISOString.replace(/[:.]/g, '-');
  const shortHash = sha256.substring(0, 8);
  const dir = path.join('artifacts', 'audit-trail', offerId);
  await fs.mkdir(dir, { recursive: true });
  const filePath = path.join(dir, `wood-list-${timestamp}-${shortHash}.pdf`);
  await fs.writeFile(filePath, buffer);

  return {
    path: filePath,
    sha256,
    sizeBytes: buffer.length,
  };
}
```

## Audit trail — specyfikacja

### Ścieżka archiwum

```
artifacts/
└── audit-trail/
    └── <offer_id>/          # np. OF-2026-001
        ├── <ts1>-<hash8>.pdf          # v1 oferty (pierwsze pobranie)
        ├── <ts2>-<hash8>.pdf          # v2 (po edycji i ponownym pobraniu)
        └── wood-list-<ts3>-<hash8>.pdf  # wykaz drewna tej samej oferty
```

- Pliki są **append-only** — nigdy nie nadpisuj istniejącego pliku.
- Każde pobranie PDF przez operatora tworzy nowy plik.
- `<ts>` = `new Date.toISOString` z `:` i `.` zamienionymi na `-` (np. `2026-05-27T10-30-00-000Z`).
- `<hash8>` = pierwsze 8 znaków SHA-256 (unikalność w ramach oferty).

### Hash łańcuchowy

Sekwencja wersji dokumentu (oferta edytowana i pobierana wielokrotnie):

```
v1: sha256(pdf_content_v1) = H1
v2: sha256(pdf_content_v2 + H1) = H2
v3: sha256(pdf_content_v3 + H2) = H3
```

Przechowuj `H_prev` w bazie obok rekordu oferty:

```typescript
// Prisma schema fragment
model Offer {
  id              String   @id @default(cuid)
  documentNumber  String   @unique
  lastPdfHash     String?  // SHA-256 ostatnio wygenerowanego PDF
  // ...
}

// Użycie:
const offer = await prisma.offer.findUnique({ where: { documentNumber } });
const result = await renderOfferPdf(input, offer?.lastPdfHash ?? null);
await prisma.offer.update({
  where: { documentNumber },
  data: { lastPdfHash: result.sha256 },
});
```

Hash łańcuchowy pozwala udowodnić chronologię — każda wersja dokumentu "zawiera" poprzednią w swoim hashu.

### Integracja z hook audit-trail-on-offer-write.sh

Hook `audit-trail-on-offer-write.sh` (trigger: PostToolUse) automatycznie tworzy snapshot po każdej operacji zapisu oferty przez agenta. Funkcje `renderOfferPdf` / `renderWoodListPdf` są komplementarne — generują PDF i hash, hook potwierdza operację w logu.

## Przykład użycia w API route (Next.js)

```typescript
// app/api/offers/[id]/pdf/route.ts
// Server-side only — dostęp do process.env i fs

import { NextRequest, NextResponse } from 'next/server';
import { renderOfferPdf } from '@/lib/pdf/render-offer-pdf';
import { renderWoodListPdf } from '@/lib/pdf/render-wood-list-pdf';
import { prisma } from '@/lib/prisma';
import { buildQuotationPdfInput, buildWoodListInput } from '@/lib/offer-builder';

export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const offer = await prisma.offer.findUnique({
    where: { id: params.id },
    include: { items: true, client: true, woodListItems: true },
  });

  if (!offer) {
    return NextResponse.json({ error: 'Oferta nie znaleziona' }, { status: 404 });
  }

  // Buduj input ze struktury DB → kontrakt PDF
  const quotationInput = buildQuotationPdfInput(offer);
  const woodListInput = offer.woodListItems.length > 0
    ? buildWoodListInput(offer)
    : null;

  // Generuj PDFy (z hash łańcuchowym)
  const [offerResult, woodResult] = await Promise.all([
    renderOfferPdf(quotationInput, offer.lastPdfHash ?? null),
    woodListInput ? renderWoodListPdf(woodListInput, offer.lastWoodListHash ?? null) : null,
  ]);

  // Aktualizuj hashe w DB
  await prisma.offer.update({
    where: { id: params.id },
    data: {
      lastPdfHash: offerResult.sha256,
      ...(woodResult && { lastWoodListHash: woodResult.sha256 }),
    },
  });

  // Zwróć ścieżki do pobrania (lub stream PDF)
  return NextResponse.json({
    offer: { path: offerResult.path, sha256: offerResult.sha256 },
    woodList: woodResult ? { path: woodResult.path, sha256: woodResult.sha256 } : null,
  });
}
```
