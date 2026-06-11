# Workflow konsumenta — 5 kroków (web-builder / code-implementer)

## Dla agentów korzystających z liquid-glass-design-system v2.0.0

---

## Krok 1 — Wczytaj design-tokens.json

```
Read library/skills/webapp/liquid-glass-design-system/assets/design-tokens.json
```

Sprawdź:
- `schema_version == 2` — jeśli 1, skill nie był REBUILD-owany, użyj v2
- `brand_palette_variant` — domyślnie `1` (ciepły drewno+dach dla DemoApp)
- `elevation.blur_per_level_px == [0, 6, 12, 20]` — desktop primary (desktop-first v2)

Jeśli `brand_palette_variant != 1` (np. klient wybrał wariant 2 lub 3 w ):
- Użyj `payload.palettes.palette_N` zamiast `palette_1`
- Podmień `--lg-accent-brand`, `--lg-bg-gradient-*`, `--lg-surface-1-rgb`

---

## Krok 2 — Ustaw CSS variables w globals.css

```css
/* src/app/globals.css — @layer base */

/* Wklej z tokens-color-typography.md Wariant 1 (lub wybrany) */
:root {
  --lg-accent-brand:          #B97A35;   /* Wariant 1 */
  --lg-bg-gradient-from:      #FAF7F2;
  --lg-bg-gradient-to:        #EEE4D3;
  --lg-surface-1-rgb:         240, 244, 250;
  /* ... reszta tokenów z tokens-color-typography.md ... */
}

[data-theme="dark"] {
  --lg-accent-brand:          #D4943F;
  /* ... reszta dark tokenów ... */
}

/* Wklej z tokens-elevation-spacing.md */
:root {
  /* DESKTOP PRIMARY (default :root) */
  --lg-blur-1: 6px;
  --lg-blur-2: 12px;
  --lg-blur-3: 20px;
  --lg-glass-opacity-1: 0.60;
  /* ... */
}

/* MOBILE RESPONSIVE OVERRIDE */
@media (max-width: 767px) {
  :root {
    --lg-blur-1: 8px;
    --lg-blur-2: 16px;
    --lg-blur-3: 24px;
    --lg-glass-opacity-1: 0.40;
    /* ... */
  }
}
```

---

## Krok 3 — Skopiuj tailwind.config.ts snippet

```
Read library/skills/webapp/liquid-glass-design-system/tailwind-shadcn-integration.md
```

Wklej sekcję 1 (pełny snippet) do `tailwind.config.ts` projektu.

Sprawdź Tailwind 4 compat:
- `darkMode: ['selector', '[data-theme="dark"]']` — OK dla Tailwind 4
- `plugins: [require('@tailwindcss/container-queries')]` — dodaj do `package.json` jeśli brak
- Klasy `.lg-card`, `.lg-modal`, `.lg-overlay`, `.lg-sheet-bottom` zdefiniowane w `addComponents`

---

## Krok 4 — Skopiuj komponenty (shadcn pattern)

Komponenty kopiowane do `src/components/ui/`, NIE instalowane z biblioteki.

| Komponent | Źródło | Cel |
|---|---|---|
| `card.tsx` | tailwind-shadcn-integration.md §3.1 | `src/components/ui/card.tsx` |
| `button.tsx` | tailwind-shadcn-integration.md §3.2 | `src/components/ui/button.tsx` |
| `dialog.tsx` | tailwind-shadcn-integration.md §3.3 | `src/components/ui/dialog.tsx` |
| `popover.tsx` | tailwind-shadcn-integration.md §3.4 | `src/components/ui/popover.tsx` |
| `sheet.tsx` | tailwind-shadcn-integration.md §3.5 | `src/components/ui/sheet.tsx` |
| `useMediaQuery.ts` | tailwind-shadcn-integration.md §6 | `src/hooks/useMediaQuery.ts` |
| `useTheme.ts` | tailwind-shadcn-integration.md §4 | `src/hooks/useTheme.ts` |

Paczki npm wymagane (jak external-crm):
- `clsx`, `tailwind-merge`, `class-variance-authority`, `lucide-react`
- `@radix-ui/react-popover`, `@radix-ui/react-dialog`, `@radix-ui/react-sheet` (lub shadcn CLI kopiowanie)

---

## Krok 5 — Uruchom ios-ux-checker po pierwszym ekranie

Po implementacji pierwszego ekranu (np. lista ofert lub formularz nowej oferty):

```
Dispatch ios-ux-checker na: app/(dashboard)/offers/page.tsx
```

Agent wykonuje 12 checków A-L. Oczekiwany wynik:
- **PASS** lub **PASS-WITH-NOTES** — merge OK
- **FAIL** — patch wymagany przed merge

Najczęstsze findings przy pierwszym ekranie:
- Check F (responsive) — upewnij się że używasz `max-md:` nie `md:` jako upgrade
- Check G (--lg-* variables) — sprawdź czy `--lg-blur-1 = 6px` desktop (nie 8px)
- Check H (Popover vs Sheet) — desktop musi mieć `<Popover>` nie `<Sheet side="bottom">`
- Check L (Polski UI) — zero angielskich CTA: nie "Submit", "Cancel", "Delete"

---

## Checklist przed merge (ios-ux-checker summary)

```
[ ] Check A: min-h-[44px] desktop, max-md:min-h-[48px] mobile na każdym elemencie interaktywnym
[ ] Check B: text-lg-body (17pt) dla treści, text-xs tylko dla captions/metadata
[ ] Check C: --lg-label-primary/#0F172A na surface-1 weryfikowane (17:1 Wariant 1)
[ ] Check D: max 3 CTA widoczne w viewport, reszta w Popover/Sheet
[ ] Check E: hover: + focus-visible: + active: na każdym przycisku
[ ] Check F: grid-cols-3 desktop default, max-lg: max-md: downgrade — NIE md: lg: upgrade
[ ] Check G: --lg-blur-1: 6px desktop, --lg-surface-* via var, @supports fallback
[ ] Check H: isDesktop ? <Popover> : <Sheet side="bottom">
[ ] Check I: ease-spring (cubic-bezier 0.32,0.72,0,1) dla glass elements
[ ] Check J: viewportFit=cover + max-md:pb-safe na fixed sticky elementach
[ ] Check K: [data-theme="dark"] bloki dla wszystkich tokenów kolorów
[ ] Check L: 100% PL — "Zapisz", "Anuluj", "Pobierz PDF" — zero "Submit", "Cancel", "Delete"
```
