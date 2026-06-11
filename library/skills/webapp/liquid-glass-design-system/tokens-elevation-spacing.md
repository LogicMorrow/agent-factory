# Tokeny: Elewacja, Blur, Spacing — v2.0.0 DESKTOP-FIRST

## KRYTYCZNE — Tokens Dual-Mode Reversal (v1.0.0 → v2.0.0)

** BŁĄD:** blur mobilny (8/16/24px) był primary DEFAULT w `:root`. Desktop miał override.
** NAPRAWA:** blur desktopowy (6/12/20px) jest PRIMARY DEFAULT. Mobile ma `@media max-width` override.

| Token | v1.0.0 `:root` (BŁĄD) | v2.0.0 `:root` (POPRAWNE) | v2.0.0 mobile override |
|---|---|---|---|
| `--lg-blur-1` | `8px` (mobile default) | `6px` (desktop default) | `@media (max-width: 767px): 8px` |
| `--lg-blur-2` | `16px` (mobile default) | `12px` (desktop default) | `@media (max-width: 767px): 16px` |
| `--lg-blur-3` | `24px` (mobile default) | `20px` (desktop default) | `@media (max-width: 767px): 24px` |
| Surface opacity | `0.70` (glass pełny) | `0.60` desktop (mocniejszy kontrast) | `@media (max-width: 767px): 0.40-0.70` |

---

## 1. Hierarchia głębokości — 4 poziomy

| Level | Nazwa | Użycie | Blur desktop | Blur mobile | Klasa Tailwind |
|---|---|---|---|---|---|
| **0** | background | Tło ekranu — solid gradient | 0px | 0px | `lg-bg` |
| **1** | cards | Karty, listy, sekcje formularza | **6px** | 8px `max-md:` | `lg-card` |
| **2** | modals / popovers | Dialog, Popover, Sheet | **12px** | 16px `max-md:` | `lg-modal` |
| **3** | overlays | Context menu, Tooltip, Toast | **20px** | 24px `max-md:` | `lg-overlay` |

### CSS Variables — pełny zestaw

```css
:root {
  /* === BLUR PER LEVEL — DESKTOP PRIMARY (6/12/20) === */
  --lg-blur-0:  0px;
  --lg-blur-1:  6px;    /* desktop primary — statyczne tło, mniejszy vibrancy */
  --lg-blur-2:  12px;
  --lg-blur-3:  20px;

  /* === SATURATE (vibrancy) === */
  --lg-saturate-0:  1;
  --lg-saturate-1:  1.3;
  --lg-saturate-2:  1.5;
  --lg-saturate-3:  1.7;

  /* === SHADOWS PER LEVEL (desktop — mocniejsze cienie dla hierarchy) === */
  --lg-shadow-0:            none;
  --lg-shadow-1:            0 2px 12px rgba(0, 0, 0, 0.06);   /* desktop primary */
  --lg-shadow-2:            0 8px 32px rgba(0, 0, 0, 0.10);
  --lg-shadow-3:            0 16px 56px rgba(0, 0, 0, 0.18);
  --lg-shadow-1-ambient:    0 1px 3px  rgba(0, 0, 0, 0.04);
  --lg-shadow-2-ambient:    0 2px 6px  rgba(0, 0, 0, 0.06);

  /* === BORDER RADIUS PER COMPONENT === */
  --lg-radius-xs:     8px;    /* chips, badges, tagi */
  --lg-radius-sm:    12px;    /* małe przyciski */
  --lg-radius-md:    16px;    /* przyciski drugorzędne, karty małe */
  --lg-radius-lg:    20px;    /* karty standardowe */
  --lg-radius-xl:    24px;    /* karty iOS-like — główny typ kart */
  --lg-radius-modal: 28px;    /* Sheet (bottom) i Dialog zaokrąglony */
  --lg-radius-full:  9999px;  /* pill buttons */

  /* === GLASS OPACITY — DESKTOP PRIMARY (mocniejszy kontrast) === */
  --lg-glass-opacity-0:  1;      /* solid */
  --lg-glass-opacity-1:  0.60;   /* desktop cards — mocniejszy kontrast */
  --lg-glass-opacity-2:  0.72;   /* desktop modals */
  --lg-glass-opacity-3:  0.88;   /* desktop overlays */

  /* === HIGHLIGHT TOP EDGE (refleksja iOS) === */
  /* Użycie: border-top: 1px solid var(--lg-highlight-top) */
}
```

### Mobile responsive override (blur + opacity)

```css
/* Mobile responsive — pełny glass effect (8/16/24px blur, niższy opacity) */
@media (max-width: 767px) {
  :root {
    /* Mocniejszy blur — ruch tła za glass = lepsza vibrancy na mobile */
    --lg-blur-1:  8px;
    --lg-blur-2:  16px;
    --lg-blur-3:  24px;

    /* Niższy opacity — "pełny glass" mobile iOS style */
    --lg-glass-opacity-1:  0.40;
    --lg-glass-opacity-2:  0.60;
    --lg-glass-opacity-3:  0.80;

    /* Lżejsze cienie na mobile — ekran mniejszy, mniejszy kontrast shadows */
    --lg-shadow-1: 0 2px 8px  rgba(0, 0, 0, 0.04);
    --lg-shadow-2: 0 8px 24px rgba(0, 0, 0, 0.08);
    --lg-shadow-3: 0 16px 48px rgba(0, 0, 0, 0.16);
  }
}
```

---

## 2. Klasy CSS komponentów glass

### Glass Card (Level 1) — desktop-first

```css
.lg-card {
  /* Solid fallback — zawsze */
  background: var(--lg-surface-1-solid);
  border-radius: var(--lg-radius-xl);
  box-shadow: var(--lg-shadow-1), var(--lg-shadow-1-ambient);
  border: 1px solid var(--lg-separator-nonopaque);
  border-top: 1px solid var(--lg-highlight-top);
  transition: box-shadow 200ms cubic-bezier(0.32, 0.72, 0, 1);
}

@supports (backdrop-filter: blur(0)) {
  .lg-card {
    background: rgba(var(--lg-surface-1-rgb, 240, 244, 250), var(--lg-glass-opacity-1));
    backdrop-filter: blur(var(--lg-blur-1)) saturate(var(--lg-saturate-1));
  }
}

/* Hover state (desktop primary — mouse) */
.lg-card:hover {
  box-shadow: var(--lg-shadow-2), var(--lg-shadow-1-ambient);
}
```

### Glass Popover / Modal (Level 2) — desktop primary

```css
.lg-modal {
  background: var(--lg-surface-2-solid);
  border-radius: var(--lg-radius-xl);   /* desktop: symetryczny */
  box-shadow: var(--lg-shadow-2);
  border: 1px solid var(--lg-separator-nonopaque);
  border-top: 1px solid var(--lg-highlight-top);
}

@supports (backdrop-filter: blur(0)) {
  .lg-modal {
    background: rgba(var(--lg-surface-2-rgb, 240, 244, 250), var(--lg-glass-opacity-2));
    backdrop-filter: blur(var(--lg-blur-2)) saturate(var(--lg-saturate-2));
  }
}

/* Mobile: Sheet side=bottom — asymetryczny radius */
@media (max-width: 767px) {
  .lg-modal.lg-sheet-bottom {
    border-radius: var(--lg-radius-modal) var(--lg-radius-modal) 0 0;
  }
}
```

### Glass Overlay (Level 3)

```css
.lg-overlay {
  background: var(--lg-surface-3-solid);
  border-radius: var(--lg-radius-md);
  box-shadow: var(--lg-shadow-3);
  border: 1px solid var(--lg-separator-nonopaque);
}

@supports (backdrop-filter: blur(0)) {
  .lg-overlay {
    background: rgba(var(--lg-surface-3-rgb, 240, 244, 250), var(--lg-glass-opacity-3));
    backdrop-filter: blur(var(--lg-blur-3)) saturate(var(--lg-saturate-3));
  }
}
```

---

## 3. Spacing Scale (8pt grid, Tailwind compatible)

```css
:root {
  --lg-space-0:   0px;
  --lg-space-1:   4px;    /* mikro — separacja labelek */
  --lg-space-2:   8px;    /* baza gridu */
  --lg-space-3:  12px;    /* padding wewn. małych elementów */
  --lg-space-4:  16px;    /* padding kart, grup */
  --lg-space-5:  20px;    /* spacing między sekcjami */
  --lg-space-6:  24px;    /* padding wewn. dużych kart — desktop screen padding */
  --lg-space-8:  32px;    /* odstęp między sekcjami ekranu */
  --lg-space-10: 40px;    /* padding poziomy ekranu (mobile) */
  --lg-space-12: 48px;    /* touch target / heading spacing */
  --lg-space-16: 64px;    /* spacing duże sekcje */
}
```

**Padding poziomy:**
- Desktop primary: `--lg-space-6` (24px) — szerszy ekran = więcej oddechu
- Mobile responsive: `--lg-space-4` (16px) minimum, `--lg-space-5` (20px) preferowane

---

## 4. Safe Area Insets (mobile responsive ONLY)

Laptopy nie mają notch. Safe area obowiązuje TYLKO na mobile (iPhone, iPad).

```css
:root {
  --lg-safe-top:    env(safe-area-inset-top,    0px);
  --lg-safe-right:  env(safe-area-inset-right,  0px);
  --lg-safe-bottom: env(safe-area-inset-bottom, 0px);
  --lg-safe-left:   env(safe-area-inset-left,   0px);
}
```

```tsx
// Sticky nav — safe area tylko na mobile (max-md:)
<nav className="fixed bottom-0 left-0 right-0 px-6
                max-md:px-4 max-md:pb-safe
                bg-[--lg-surface-1] backdrop-blur-lg-1">
  {/* items */}
</nav>

// Bottom Sheet — pb-safe zawsze (pojawia się na mobile)
<SheetContent side="bottom" className="lg-modal lg-sheet-bottom pb-safe px-4">
  <div className="flex justify-center py-3">
    <div className="w-10 h-1 rounded-full bg-[--lg-separator-opaque]" />
  </div>
  {children}
</SheetContent>
```

### Tailwind — safe area plugin

```ts
// tailwind.config.ts — plugins
({ addUtilities }: any) => {
  addUtilities({
    '.pt-safe': { paddingTop:    'env(safe-area-inset-top, 0px)' },
    '.pb-safe': { paddingBottom: 'env(safe-area-inset-bottom, 0px)' },
    '.pl-safe': { paddingLeft:   'env(safe-area-inset-left, 0px)' },
    '.pr-safe': { paddingRight:  'env(safe-area-inset-right, 0px)' },
  });
},
```

---

## 5. Spring Animation Tokens

```css
:root {
  /* === SPRING EASING (iOS standard) === */
  --lg-spring: cubic-bezier(0.32, 0.72, 0, 1);

  /* === DURATIONS === */
  --lg-duration-fast:    150ms;   /* feedback: tap, toggle, icon swap */
  --lg-duration-normal:  200ms;   /* standard transitions */
  --lg-duration-slow:    300ms;   /* modal enter/exit, popover, sheet slide */
  --lg-duration-slower:  400ms;   /* page transitions */

  /* === GOTOWE WARTOŚCI === */
  --lg-transition-fast:   all 150ms cubic-bezier(0.32, 0.72, 0, 1);
  --lg-transition-normal: all 200ms cubic-bezier(0.32, 0.72, 0, 1);
  --lg-transition-slow:   all 300ms cubic-bezier(0.32, 0.72, 0, 1);
}
```

```ts
// tailwind.config.ts — extend.transitionTimingFunction
transitionTimingFunction: {
  'spring': 'cubic-bezier(0.32, 0.72, 0, 1)',
  // Alias dla ios-ux-checker check I (spring animations)
  'ios-spring': 'cubic-bezier(0.32, 0.72, 0, 1)',
},
transitionDuration: {
  '150': '150ms',
  '200': '200ms',
  '300': '300ms',
  '400': '400ms',
},
```

```tsx
// Użycie — button z spring feedback
<button className="transition-all duration-200 ease-spring
                   hover:shadow-lg-2 active:scale-[0.97]">
  Pobierz PDF
</button>
```
