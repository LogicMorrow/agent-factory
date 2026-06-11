# Font embedding i typografia PL — @react-pdf/renderer

Polska typografia w `@react-pdf/renderer` wymaga jawnej rejestracji fontów. Bez tego ogonki (ą, ć, ę, ł, ń, ó, ś, ź, ż) renderują jako znaki zastępcze lub są pomijane — domyślny Helvetica/Times New Roman nie zawiera polskich znaków.

## Dlaczego font embedding jest obowiązkowy

`@react-pdf/renderer` używa własnego silnika renderowania PDF (nie przeglądarki). Domyślne fonty wbudowane w PDF (`Helvetica`, `Times-Roman`, `Courier`) to fonty Type 1 — nie zawierają polskich znaków Unicode. Bez embed:

```
// Efekt bez font embedding — PL ogonki zamienione na □ lub pominięte:
"Oferta dla Jana Kowalskiego z Krakowa" → "Oferta dla Jana Kowalskiego z Krakowa" ✓
"Pokrycie dachówką ceramiczną — orynnowanie"
→ "Pokrycie dach wk  ceramiczn  — orynnowanie" ✗ (ogonki wycięte)
```

## Rejestracja fontu Roboto z ogonkami

Roboto (Google Fonts) zawiera pełen zakres Latin Extended — wszystkie polskie ogonki. Licencja Apache 2.0, bezpłatna w zastosowaniach komercyjnych.

### Krok 1 — Pobierz pliki TTF

```bash
# W katalogu projektu Next.js:
mkdir -p public/fonts/roboto

# Pobierz warianty z Google Fonts (lub użyj @fontsource/roboto)
# Wymagane warianty: Regular (400), Bold (700), Italic (400i)
# URL: https://fonts.google.com/specimen/Roboto (Download family)
# lub przez npm:
npm install @fontsource/roboto
# Pliki TTF znajdziesz w: node_modules/@fontsource/roboto/files/
```

### Krok 2 — Rejestracja globalna (pdf-utils.ts)

```typescript
// lib/pdf/pdf-utils.ts
// UWAGA: Font.register musi być wywołane PRZED pierwszym renderem PDF.
// Umieść w pliku inicjalizacyjnym — nie w komponencie.

import { Font, StyleSheet } from '@react-pdf/renderer';
import path from 'path';

// Ścieżki do plików TTF (relative do katalogu projektu lub absolute)
// Opcja A: pliki w public/fonts/ (serwowane przez Next.js)
const FONTS_DIR = path.join(process.cwd, 'public', 'fonts', 'roboto');

// Opcja B: pliki z @fontsource (npm package)
// const FONTS_DIR = path.join(process.cwd, 'node_modules', '@fontsource', 'roboto', 'files');

Font.register({
  family: 'Roboto',
  fonts: [
    {
      src: path.join(FONTS_DIR, 'Roboto-Regular.ttf'),
      fontWeight: 'normal',
      fontStyle: 'normal',
    },
    {
      src: path.join(FONTS_DIR, 'Roboto-Bold.ttf'),
      fontWeight: 'bold',
      fontStyle: 'normal',
    },
    {
      src: path.join(FONTS_DIR, 'Roboto-Italic.ttf'),
      fontWeight: 'normal',
      fontStyle: 'italic',
    },
    {
      src: path.join(FONTS_DIR, 'Roboto-BoldItalic.ttf'),
      fontWeight: 'bold',
      fontStyle: 'italic',
    },
  ],
});

// Wyłącz hyphenation (domyślnie włączone — niepożądane w PL dokumentach biznesowych)
Font.registerHyphenationCallback((word) => [word]);

// Globalne style strony A4
export const PAGE_STYLES = {
  a4Portrait: {
    size: 'A4' as const,
    orientation: 'portrait' as const,
    paddingTop: 56,      // 20mm w punktach (1mm ≈ 2.835pt → 20mm ≈ 56pt)
    paddingBottom: 56,
    paddingLeft: 56,
    paddingRight: 56,
  },
};
```

### Krok 3 — Weryfikacja ogonków (test snippet)

```typescript
// test/pdf-font-test.ts
// Uruchom przed wdrożeniem: npx ts-node test/pdf-font-test.ts

import { renderToBuffer } from '@react-pdf/renderer';
import React from 'react';
import { Document, Page, Text } from '@react-pdf/renderer';
import './lib/pdf/pdf-utils'; // inicjalizacja Font.register

async function testPolishChars {
  const testChars = 'ą ć ę ł ń ó ś ź ż — ĄĆĘŁŃÓŚŹŻ';
  const testWords = 'krokiew murłata płatew kontrłata jętka';
  const testSentence = 'Oferta dla klienta — pokrycie dachówką ceramiczną, orynnowanie z blachy ocynkowanej.';

  const doc = React.createElement(Document, null,
    React.createElement(Page, { size: 'A4' },
      React.createElement(Text, { style: { fontFamily: 'Roboto', fontSize: 12 } }, testChars),
      React.createElement(Text, { style: { fontFamily: 'Roboto', fontSize: 10 } }, testWords),
      React.createElement(Text, { style: { fontFamily: 'Roboto', fontSize: 9 } }, testSentence),
    )
  );

  const buffer = await renderToBuffer(doc);
  const fs = await import('fs/promises');
  await fs.writeFile('/tmp/pdf-font-test.pdf', buffer);
  console.log('Test PDF zapisany: /tmp/pdf-font-test.pdf');
  console.log('Otwórz i sprawdź czy ogonki renderują poprawnie.');
}

testPolishChars.catch(console.error);
```

**Jeśli ogonki nadal nie renderują** po wykonaniu powyższego — aktywuj fallback R4: przełącz na `pdfme` (patrz ADR w `SKILL.md`).

## Format liczb PL

```typescript
// lib/pdf/pdf-utils.ts (kontynuacja)

/**
 * Formatuje kwotę PLN zgodnie z konwencją PL:
 * - separator tysięcy: spacja nierozdzielająca (U+00A0)
 * - separator dziesiętny: przecinek
 * - sufiks: " PLN"
 * Przykład: 1500.5 → "1 500,50 PLN"
 */
export function formatAmountPl(amount: number): string {
  // Użyj locale 'pl-PL' — przeglądarka używa spacji jako separatora tysięcy
  const formatted = amount.toLocaleString('pl-PL', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  // toLocaleString w Node może dawać różne wyniki — fallback ręczny:
  // (jeśli Node nie zwraca spacji jako separatora — użyj implementacji poniżej)
  return `${formatted} PLN`;
}

/**
 * Fallback ręczny dla środowisk gdzie toLocaleString('pl-PL') nie działa poprawnie
 * (niektóre wersje Node.js bez pełnych danych ICU)
 */
export function formatAmountPlFallback(amount: number): string {
  const [intPart, decPart] = amount.toFixed(2).split('.');
  // Grupuj co 3 cyfry od prawej, separator = spacja
  const intFormatted = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  return `${intFormatted},${decPart} PLN`;
}

// Sprawdź aktywną implementację przy inicjalizacji (dev-time):
// console.assert(formatAmountPl(1500) === '1 500,00 PLN', 'Format PLN FAIL');
```

## Format dat PL

```typescript
/**
 * Formatuje datę ISO 8601 do formatu PL: DD.MM.YYYY
 * Przykłady:
 *   "2026-05-27" → "27.05.2026"
 *   "2026-05-27T10:30:00.000Z" → "27.05.2026"
 */
export function formatDatePl(isoDate: string): string {
  const date = new Date(isoDate);
  const day = String(date.getUTCDate).padStart(2, '0');
  const month = String(date.getUTCMonth + 1).padStart(2, '0');
  const year = date.getUTCFullYear;
  return `${day}.${month}.${year}`;
}

// Test:
// console.assert(formatDatePl('2026-05-27') === '27.05.2026');
// console.assert(formatDatePl('2026-01-01') === '01.01.2026');
```

## Format adresu PL (konwencja pocztowa)

W dokumentach PDF używaj formatu zgodnego z pocztą polską:

```
Dobra konwencja:
ul. Kwiatowa 5
35-001 Kraków

lub jednoliniowo:
ul. Kwiatowa 5, 35-001 Kraków
```

```
Zła konwencja (anglojęzyczna):
Kraków, 35-001, ul. Kwiatowa 5
```

Kod pocztowy w formacie `XX-XXX` zawsze **przed** miastem.

## Skala typograficzna (dokumenty biznesowe A4)

| Element | Rozmiar | Waga | Kolor |
|---|---|---|---|
| Nazwa firmy / tytuł dokumentu | 12–13 pt | bold | `#1a1a1a` |
| Tytuł sekcji (Zamawiający, Pozycje) | 10 pt | bold | `#1a1a1a` |
| Treść główna (tabela, warunki) | 9–10 pt | normal | `#1a1a1a` |
| Etykiety / labels | 9 pt | normal | `#666666` |
| Metadane (nr dokumentu, daty) | 8.5–9 pt | normal | `#555555` |
| Klauzula RODO (stopka) | 7–8 pt | normal | `#666666` |
| Numeracja stron | 7.5 pt | normal | `#999999` |

## Typowe problemy i rozwiązania

| Problem | Przyczyna | Rozwiązanie |
|---|---|---|
| Ogonki jako `□` lub puste miejsca | Brak font embedding lub zły plik TTF | Sprawdź czy TTF zawiera Latin Extended — użyj `fonttools` lub online FontDrop |
| `Font.register` nie działa w Next.js | Moduł inicjalizowany po stronie klienta (browser nie ma `path`) | Przenieś `Font.register` do pliku ładowanego tylko po stronie serwera (`use server` lub API route) |
| Spacja jako separator tysięcy nie wyświetla się | `toLocaleString` Node bez pełnych ICU | Użyj `formatAmountPlFallback` z ` ` |
| Tekst wychodzi poza obszar strony | Brak `wrap: true` lub za mała kolumna | Dodaj `flexWrap: 'wrap'` lub zmniejsz `fontSize` |
| Polskie cudzysłowy `„"` zamiast `""` | Nie ma znaczenia dla PDF — oba działają z Roboto | Preferuj `„"` w PL dokumentach (standard typograficzny PL) |
