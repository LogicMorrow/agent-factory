# Tokeny: Kolor i Typografia — v2.0.0 DESKTOP-FIRST

## CSS Variables — konwencja nazewnicza

Prefix **`--lg-`** dla wszystkich zmiennych. Zero kolizji z `--portfolio-*` ani `--tw-*`.

```css
/* Struktura: --lg-{kategoria}-{wariant}-{modyfikator} */
--lg-surface-0          /* background level 0 */
--lg-surface-1          /* cards level 1 */
--lg-label-primary      /* tekst główny */
--lg-blur-1             /* blur dla poziomu 1 (6px desktop primary) */
```

---

## 1. Trzy warianty palety — HITL Gate B.E1

**Decyzja operatora finalna w  przy bootstrappie apki.**
Wariant 1 = DEFAULT w DemoApp. Zmiana: `brand_palette_variant` w design-tokens.json.

---

### Wariant 1 (DEFAULT) — "Ciepły gradient drewno+dach"

**Personality:** drewno, dom, ciepło, naturalność. Właściwe dla firmy dekarskiej.
**Kontrast slate-900 / surface-1:** ~17:1 (WCAG AAA).

```css
/* WARIANT 1 — :root (light mode) */
:root {
  /* === BRAND PALETTE: ciepły drewno+dach === */
  --lg-accent-brand:          #B97A35;   /* miedziany — drewno, ciepło */
  --lg-accent-brand-hover:    #9E6828;   /* ciemniejszy hover */
  --lg-accent-brand-muted:    #F5EBD8;   /* tło dla akcentu */
  --lg-accent-brand-dark:     #D4943F;   /* dark mode — jaśniejszy */
  --lg-accent-brand-muted-dk: #3A2A15;   /* dark mode muted */

  /* === BACKGROUND GRADIENT (Level 0 — solid, bez glass) === */
  --lg-bg-gradient-from:      #FAF7F2;   /* kremowo-ciepły */
  --lg-bg-gradient-to:        #EEE4D3;   /* ciepły piaskowiec */
  --lg-bg-primary:            #FAF7F2;
  --lg-bg-secondary:          #EEE4D3;
  --lg-bg-tertiary:           #E4D8C8;

  /* === GLASS SURFACES (subtle blue cast) === */
  --lg-surface-0:             var(--lg-bg-primary);
  --lg-surface-1:             rgba(240, 244, 250, 0.60);  /* desktop opacity 0.60 — mocniejszy kontrast */
  --lg-surface-2:             rgba(240, 244, 250, 0.72);
  --lg-surface-3:             rgba(240, 244, 250, 0.88);
  --lg-surface-1-solid:       #EEF2F8;
  --lg-surface-2-solid:       #F3F6FB;
  --lg-surface-3-solid:       #F8FAFD;

  /* === LABEL HIERARCHY === */
  --lg-label-primary:         #0F172A;   /* slate-900 — 17:1 na surface-1 */
  --lg-label-secondary:       #334155;   /* slate-700 — 10:1 */
  --lg-label-tertiary:        #64748B;   /* slate-500 — 4.9:1 PASS body */
  --lg-label-quaternary:      #94A3B8;   /* slate-400 — disabled */

  /* === SEPARATORS === */
  --lg-separator-opaque:      #CBD5E1;   /* slate-300 */
  --lg-separator-nonopaque:   rgba(51, 65, 85, 0.20);

  /* === GLASS HIGHLIGHTS === */
  --lg-highlight-top:         rgba(255, 255, 255, 0.30);

  /* === INTERACTIVE STATES === */
  --lg-interactive-pressed:   rgba(185, 122, 53, 0.10);  /* accent tinted press */
  --lg-interactive-focus:     var(--lg-accent-brand);

  /* === MATERIAL TINTED GLASS === */
  --lg-material-blue:         rgba(46, 92, 138, 0.16);   /* stalowo-niebieski */
  --lg-material-green:        rgba(22, 101, 52, 0.16);
  --lg-material-orange:       rgba(185, 122, 53, 0.20);  /* drewno accent */
  --lg-material-red:          rgba(185, 28, 28, 0.16);
  --lg-material-purple:       rgba(109, 40, 217, 0.14);
  --lg-material-gray:         rgba(100, 116, 139, 0.18);
}

/* WARIANT 1 — [data-theme="dark"] */
[data-theme="dark"] {
  --lg-accent-brand:          #D4943F;   /* jaśniejszy dla dark mode */
  --lg-accent-brand-hover:    #E8A85A;
  --lg-accent-brand-muted:    #3A2A15;
  --lg-accent-brand-dark:     #D4943F;
  --lg-accent-brand-muted-dk: #4A3520;

  --lg-bg-gradient-from:      #1A1612;
  --lg-bg-gradient-to:        #120F0A;
  --lg-bg-primary:            #1A1612;
  --lg-bg-secondary:          #231D16;
  --lg-bg-tertiary:           #2C241B;

  --lg-surface-0:             var(--lg-bg-primary);
  --lg-surface-1:             rgba(44, 36, 27, 0.60);
  --lg-surface-2:             rgba(44, 36, 27, 0.75);
  --lg-surface-3:             rgba(44, 36, 27, 0.92);
  --lg-surface-1-solid:       #2C241B;
  --lg-surface-2-solid:       #332B21;
  --lg-surface-3-solid:       #3A3128;

  --lg-label-primary:         #F8FAFC;
  --lg-label-secondary:       #CBD5E1;
  --lg-label-tertiary:        #94A3B8;
  --lg-label-quaternary:      #475569;

  --lg-separator-opaque:      #374151;
  --lg-separator-nonopaque:   rgba(148, 163, 184, 0.20);
  --lg-highlight-top:         rgba(255, 255, 255, 0.08);
  --lg-interactive-pressed:   rgba(212, 148, 63, 0.15);
  --lg-interactive-focus:     var(--lg-accent-brand);
}
```

---

### Wariant 2 — "Chłodny przemysłowy stal"

**Personality:** profesjonalizm, precyzja techniczna, zaufanie.
**Kontrast:** 14:1 (WCAG AAA).
**Zastosowanie alternatywne:** gdy klient preferuje "korporacyjny" klimat.

```css
/* WARIANT 2 — :root (light mode) */
/* Użyj gdy brand_palette_variant=2 */
[data-palette="2"] {
  --lg-accent-brand:          #2E5C8A;
  --lg-accent-brand-hover:    #234970;
  --lg-accent-brand-muted:    #DBEAFE;
  --lg-accent-brand-dark:     #4B8BC2;
  --lg-accent-brand-muted-dk: #1E3A5F;

  --lg-bg-gradient-from:      #F5F7FA;
  --lg-bg-gradient-to:        #E8EDF5;
  --lg-bg-primary:            #F5F7FA;
  --lg-bg-secondary:          #E8EDF5;
  --lg-bg-tertiary:           #DCE4F0;

  --lg-surface-1:             rgba(235, 240, 248, 0.60);
  --lg-surface-2:             rgba(235, 240, 248, 0.72);
  --lg-surface-3:             rgba(235, 240, 248, 0.88);
  --lg-surface-1-solid:       #EBF0F8;
  --lg-surface-2-solid:       #F0F4FA;
  --lg-surface-3-solid:       #F5F8FC;

  --lg-label-primary:         #0F172A;
  --lg-label-secondary:       #1E3A5F;
  --lg-label-tertiary:        #4B7098;
  --lg-label-quaternary:      #7099B8;
  --lg-accent-contrast_note:  "14:1 WCAG AAA";
}
```

---

### Wariant 3 — "Akcentowy lakier samochodowy"

**Personality:** energia, alert, natychmiastowe działanie. Jak czerwona dachówka ceramiczna.
**Kontrast:** 15:1 (WCAG AAA). Mocny brand statement.
**Uwaga:** czerwony akcent → nie nadużywać. Główny CTA OK. Nie używać dla destrukcyjnych akcji (za dużo czerwonego = brak hierarchii alert).

```css
/* WARIANT 3 — :root (light mode) */
[data-palette="3"] {
  --lg-accent-brand:          #C53030;
  --lg-accent-brand-hover:    #9B1C1C;
  --lg-accent-brand-muted:    #FEE2E2;
  --lg-accent-brand-dark:     #FC8181;
  --lg-accent-brand-muted-dk: #7F1D1D;

  --lg-bg-gradient-from:      #FCFCFD;
  --lg-bg-gradient-to:        #F0F1F3;
  --lg-bg-primary:            #FCFCFD;
  --lg-bg-secondary:          #F0F1F3;
  --lg-bg-tertiary:           #E5E7EB;

  --lg-surface-1:             rgba(248, 248, 250, 0.60);
  --lg-surface-2:             rgba(248, 248, 250, 0.72);
  --lg-surface-3:             rgba(248, 248, 250, 0.88);
  --lg-surface-1-solid:       #F4F4F6;
  --lg-surface-2-solid:       #F8F8FA;
  --lg-surface-3-solid:       #FAFAFA;

  --lg-label-primary:         #18181B;   /* zinc-950 */
  --lg-label-secondary:       #3F3F46;
  --lg-label-tertiary:        #71717A;
  --lg-label-quaternary:      #A1A1AA;
  --lg-accent-contrast_note:  "15:1 WCAG AAA";
}
```

---

## 2. Shared tokens (wszystkie warianty)

Tokeny wspólne bez względu na wybrany wariant palety:

```css
:root {
  /* === MATERIAL GLASS (wspólne dla wariantu 1 — inne warianty override w [data-palette]) === */
  --lg-material-black:        rgba(15, 23, 42, 0.72);   /* slate-900 tinted */

  /* === GLASS OPACITY — DUAL-MODE DESKTOP-FIRST === */
  /* Wartości CSS overridy w media query — patrz tokens-elevation-spacing.md */
  --lg-glass-opacity-1:       0.60;    /* desktop primary — mocniejszy kontrast */
  --lg-glass-opacity-2:       0.72;
  --lg-glass-opacity-3:       0.88;
  /* Mobile responsive override (max-md): 0.40 / 0.60 / 0.80 — pełny glass */
}
```

---

## 3. Typography Scale (iOS-inspired)

**Font stack:** `'SF Pro Display', 'SF Pro Text', Inter, system-ui, -apple-system, sans-serif`

**Uwaga licencyjna:** SF Pro dostępny przez `system-ui` / `-apple-system` na macOS/iOS. Na innych
platformach — Inter (open-source) jako fallback. **NIE bundluj SF Pro w assets** (naruszenie Apple license).
Polskie ogonki ąćęłńóśźż: Inter v4+ pełna obsługa PL, SF Pro na Apple = native.

```css
:root {
  /* === FONT FAMILY === */
  --lg-font-display:  'SF Pro Display', Inter, system-ui, -apple-system, sans-serif;
  --lg-font-text:     'SF Pro Text',    Inter, system-ui, -apple-system, sans-serif;

  /* === FONT SIZES (rem, root = 16px) === */
  /* text-lg-large-title */ --lg-text-large-title:  2.125rem;   /* 34pt */
  /* text-lg-title-1 */     --lg-text-title-1:      1.75rem;    /* 28pt */
  /* text-lg-title-2 */     --lg-text-title-2:      1.375rem;   /* 22pt */
  /* text-lg-title-3 */     --lg-text-title-3:      1.25rem;    /* 20pt */
  /* text-lg-headline */    --lg-text-headline:     1.0625rem;  /* 17pt semibold */
  /* text-lg-body */        --lg-text-body:         1.0625rem;  /* 17pt — MINIMUM senior */
  /* text-lg-callout */     --lg-text-callout:      1.0rem;     /* 16pt */
  /* text-lg-subheadline */ --lg-text-subheadline:  0.9375rem;  /* 15pt */
  /* text-lg-footnote */    --lg-text-footnote:     0.8125rem;  /* 13pt */
  /* text-lg-caption-1 */   --lg-text-caption-1:    0.75rem;    /* 12pt */
  /* text-lg-caption-2 */   --lg-text-caption-2:    0.6875rem;  /* 11pt */

  /* === LINE HEIGHTS === */
  --lg-lh-large-title:  2.5625rem;   /* 41pt */
  --lg-lh-title-1:      2.125rem;    /* 34pt */
  --lg-lh-title-2:      1.75rem;     /* 28pt */
  --lg-lh-title-3:      1.5625rem;   /* 25pt */
  --lg-lh-headline:     1.375rem;    /* 22pt */
  --lg-lh-body:         1.375rem;    /* 22pt */
  --lg-lh-callout:      1.3125rem;   /* 21pt */
  --lg-lh-subheadline:  1.25rem;     /* 20pt */
  --lg-lh-footnote:     1.125rem;    /* 18pt */
  --lg-lh-caption-1:    1.0rem;      /* 16pt */
  --lg-lh-caption-2:    0.8125rem;   /* 13pt */

  /* === FONT WEIGHTS === */
  --lg-weight-regular:   400;
  --lg-weight-medium:    500;
  --lg-weight-semibold:  600;
  --lg-weight-bold:      700;
}
```

### Tailwind fontSize extension

```ts
// tailwind.config.ts — theme.extend.fontSize
fontSize: {
  'lg-large-title':  ['2.125rem',  { lineHeight: '2.5625rem', fontWeight: '700' }],
  'lg-title-1':      ['1.75rem',   { lineHeight: '2.125rem',  fontWeight: '400' }],
  'lg-title-2':      ['1.375rem',  { lineHeight: '1.75rem',   fontWeight: '400' }],
  'lg-title-3':      ['1.25rem',   { lineHeight: '1.5625rem', fontWeight: '400' }],
  'lg-headline':     ['1.0625rem', { lineHeight: '1.375rem',  fontWeight: '600' }],
  'lg-body':         ['1.0625rem', { lineHeight: '1.375rem',  fontWeight: '400' }],
  'lg-callout':      ['1.0rem',    { lineHeight: '1.3125rem', fontWeight: '400' }],
  'lg-subheadline':  ['0.9375rem', { lineHeight: '1.25rem',   fontWeight: '400' }],
  'lg-footnote':     ['0.8125rem', { lineHeight: '1.125rem',  fontWeight: '400' }],
  'lg-caption-1':    ['0.75rem',   { lineHeight: '1.0rem',    fontWeight: '400' }],
  'lg-caption-2':    ['0.6875rem', { lineHeight: '0.8125rem', fontWeight: '400' }],
},
```

### Użycie w komponentach

```tsx
// Tytuł ekranu — jeden per strona
<h1 className="text-lg-large-title font-bold text-[--lg-label-primary]">
  Nowa oferta
</h1>

// Nagłówek sekcji
<h2 className="text-lg-headline font-semibold text-[--lg-label-primary]">
  Pozycje kosztorysowe
</h2>

// Tekst w formularzu (body — min 17pt, senior)
<label className="text-lg-body font-medium text-[--lg-label-secondary]">
  Metraż dachu (m²)
</label>

// Pomocnicza notatka
<p className="text-lg-footnote text-[--lg-label-tertiary]">
  Podaj przybliżony metraż z miarówki
</p>
```

---

## 4. Kontrast — checklist WCAG AA

| Tekst | Minimalne ratio | Narzędzie |
|---|---|---|
| Body (17pt regular) | 4.5:1 | [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/) |
| Large text (22pt+ lub 17pt+ bold) | 3:1 | j.w. |
| Ikony aktywne | 3:1 | j.w. |

**Wariant 1 — pre-weryfikacja (light mode, tło `#FAF7F2`):**
- `--lg-label-primary` (#0F172A) na surface-1 → ~17:1 PASS AAA
- `--lg-label-secondary` (#334155) na surface-1 → ~10:1 PASS
- `--lg-label-tertiary` (#64748B) na surface-1 → ~4.9:1 PASS body

**Zasada:** `--lg-label-tertiary` dozwolone dla body. W Wariancie 1 to slate-500 = 4.9:1.
(Odwrotnie niż v1.0.0 gdzie tertiary dawało ~3.1:1 = FAIL dla body — Wariant 1 to naprawia.)
