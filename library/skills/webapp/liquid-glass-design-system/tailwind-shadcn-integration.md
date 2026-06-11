# Tailwind 4 Config + shadcn Pattern Adapters — v2.0.0 DESKTOP-FIRST

**Wzorzec:** shadcn pattern — komponenty kopiowane do projektu, BEZ biblioteki.
Jak w external-crm: kontrola tokenów, brak version-lock zewnętrznej biblioteki.

## 1. Pełny snippet tailwind.config.ts

```ts
// tailwind.config.ts
import type { Config } from 'tailwindcss'

const config: Config = {
  darkMode: ['selector', '[data-theme="dark"]'],
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      // --- KOLORY (tokeny --lg-*) ---
      colors: {
        'lg': {
          // Label hierarchy
          'label':            'var(--lg-label-primary)',
          'label-secondary':  'var(--lg-label-secondary)',
          'label-tertiary':   'var(--lg-label-tertiary)',
          'label-disabled':   'var(--lg-label-quaternary)',
          // Surfaces
          'surface-0':        'var(--lg-surface-0)',
          'surface-1':        'var(--lg-surface-1)',
          'surface-2':        'var(--lg-surface-2)',
          'surface-3':        'var(--lg-surface-3)',
          // Background
          'bg':               'var(--lg-bg-primary)',
          'bg-secondary':     'var(--lg-bg-secondary)',
          // Brand accent
          'accent':           'var(--lg-accent-brand)',
          'accent-hover':     'var(--lg-accent-brand-hover)',
          'accent-muted':     'var(--lg-accent-brand-muted)',
          // Separators
          'separator':        'var(--lg-separator-opaque)',
          'separator-light':  'var(--lg-separator-nonopaque)',
          // Material tinted glass
          'material-blue':    'var(--lg-material-blue)',
          'material-green':   'var(--lg-material-green)',
          'material-orange':  'var(--lg-material-orange)',
          'material-red':     'var(--lg-material-red)',
          'material-purple':  'var(--lg-material-purple)',
          'material-gray':    'var(--lg-material-gray)',
        },
      },

      // --- BACKDROP BLUR (desktop primary 6/12/20) ---
      backdropBlur: {
        'lg-0': '0px',
        'lg-1': 'var(--lg-blur-1)',   /* 6px desktop default */
        'lg-2': 'var(--lg-blur-2)',   /* 12px desktop default */
        'lg-3': 'var(--lg-blur-3)',   /* 20px desktop default */
      },

      backdropSaturate: {
        'lg-1': 'var(--lg-saturate-1)',
        'lg-2': 'var(--lg-saturate-2)',
        'lg-3': 'var(--lg-saturate-3)',
      },

      // --- BOX SHADOW ---
      boxShadow: {
        'lg-0':   'none',
        'lg-1':   'var(--lg-shadow-1)',
        'lg-1-a': 'var(--lg-shadow-1), var(--lg-shadow-1-ambient)',
        'lg-2':   'var(--lg-shadow-2)',
        'lg-3':   'var(--lg-shadow-3)',
      },

      // --- BORDER RADIUS ---
      borderRadius: {
        'lg-xs':    'var(--lg-radius-xs)',
        'lg-sm':    'var(--lg-radius-sm)',
        'lg-md':    'var(--lg-radius-md)',
        'lg-lg':    'var(--lg-radius-lg)',
        'lg-xl':    'var(--lg-radius-xl)',
        'lg-modal': 'var(--lg-radius-modal)',
      },

      // --- FONT SIZES (iOS typography scale) ---
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

      // --- TRANSITION TIMING (spring iOS) ---
      transitionTimingFunction: {
        'spring':     'cubic-bezier(0.32, 0.72, 0, 1)',
        'ios-spring': 'cubic-bezier(0.32, 0.72, 0, 1)',
      },
      transitionDuration: {
        '150': '150ms',
        '200': '200ms',
        '300': '300ms',
        '400': '400ms',
      },

      // --- SPACING (8pt grid + safe area) ---
      spacing: {
        'safe-top':    'env(safe-area-inset-top, 0px)',
        'safe-bottom': 'env(safe-area-inset-bottom, 0px)',
        'safe-left':   'env(safe-area-inset-left, 0px)',
        'safe-right':  'env(safe-area-inset-right, 0px)',
      },
    },
  },
  plugins: [
    require('@tailwindcss/container-queries'),
    // Safe area utilities
    ({ addUtilities }: any) => {
      addUtilities({
        '.pt-safe': { paddingTop:    'env(safe-area-inset-top, 0px)' },
        '.pb-safe': { paddingBottom: 'env(safe-area-inset-bottom, 0px)' },
        '.pl-safe': { paddingLeft:   'env(safe-area-inset-left, 0px)' },
        '.pr-safe': { paddingRight:  'env(safe-area-inset-right, 0px)' },
      });
    },
    // Glass surface utility classes (desktop primary — 6/12/20px blur)
    ({ addComponents }: any) => {
      addComponents({
        '.lg-card': {
          background: 'var(--lg-surface-1-solid)',
          borderRadius: 'var(--lg-radius-xl)',
          boxShadow: 'var(--lg-shadow-1), var(--lg-shadow-1-ambient)',
          border: '1px solid var(--lg-separator-nonopaque)',
          borderTop: '1px solid var(--lg-highlight-top)',
          transition: 'box-shadow 200ms cubic-bezier(0.32, 0.72, 0, 1)',
          '@supports (backdrop-filter: blur(0))': {
            // opacity 0.60 desktop primary (tokens-elevation-spacing.md)
            background: 'rgba(var(--lg-surface-1-rgb, 240, 244, 250), var(--lg-glass-opacity-1))',
            backdropFilter: 'blur(var(--lg-blur-1)) saturate(var(--lg-saturate-1))',
          },
          '&:hover': {
            boxShadow: 'var(--lg-shadow-2), var(--lg-shadow-1-ambient)',
          },
        },
        '.lg-modal': {
          background: 'var(--lg-surface-2-solid)',
          borderRadius: 'var(--lg-radius-xl)',
          boxShadow: 'var(--lg-shadow-2)',
          border: '1px solid var(--lg-separator-nonopaque)',
          borderTop: '1px solid var(--lg-highlight-top)',
          '@supports (backdrop-filter: blur(0))': {
            background: 'rgba(var(--lg-surface-2-rgb, 240, 244, 250), var(--lg-glass-opacity-2))',
            backdropFilter: 'blur(var(--lg-blur-2)) saturate(var(--lg-saturate-2))',
          },
        },
        '.lg-overlay': {
          background: 'var(--lg-surface-3-solid)',
          borderRadius: 'var(--lg-radius-md)',
          boxShadow: 'var(--lg-shadow-3)',
          '@supports (backdrop-filter: blur(0))': {
            background: 'rgba(var(--lg-surface-3-rgb, 240, 244, 250), var(--lg-glass-opacity-3))',
            backdropFilter: 'blur(var(--lg-blur-3)) saturate(var(--lg-saturate-3))',
          },
        },
        // Sheet bottom — asymetryczny radius dla mobile
        '.lg-sheet-bottom': {
          borderRadius: 'var(--lg-radius-modal) var(--lg-radius-modal) 0 0',
        },
      });
    },
  ],
}

export default config
```

---

## 2. globals.css

```css
/* src/app/globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  /* Wklej bloki :root i [data-theme="dark"] z tokens-color-typography.md */
  /* Wklej --lg-blur-*, --lg-shadow-*, --lg-radius-* z tokens-elevation-spacing.md */
  /* Wklej @media (max-width: 767px) override blur z tokens-elevation-spacing.md */

  html {
    font-family: var(--lg-font-text);
    color: var(--lg-label-primary);
    /* Desktop-first background gradient */
    background: linear-gradient(135deg, var(--lg-bg-gradient-from) 0%, var(--lg-bg-gradient-to) 100%);
    background-attachment: fixed;
    transition: background-color 200ms cubic-bezier(0.32, 0.72, 0, 1);
  }
}
```

---

## 3. Adaptery shadcn pattern — DESKTOP-FIRST

### 3.1 Card — liquid glass adapter

```tsx
// components/ui/card.tsx — kopiowany do projektu, BEZ shadcn library
import * as React from "react"
import { cn } from "@/lib/utils"

const Card = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      "lg-card p-6",               // glass Level 1, desktop primary 6px blur
      "cursor-pointer",
      "transition-all duration-200 ease-spring",
      "active:scale-[0.98]",
      className
    )}
    {...props}
  />
))
Card.displayName = "Card"

export { Card }
```

### 3.2 Button — dual target sizes (44pt desktop / 48-56pt mobile)

```tsx
// components/ui/button.tsx
import { cva } from "class-variance-authority"
import { cn } from "@/lib/utils"

const buttonVariants = cva(
  cn(
    // Base — spring animation + dual targets
    "inline-flex items-center justify-center gap-2 whitespace-nowrap font-semibold",
    // Desktop primary 44pt — mouse ergonomia seniora
    "min-h-[44px] min-w-[44px]",
    // Mobile responsive 48pt override (touch seniora)
    "max-md:min-h-[48px] max-md:min-w-[48px]",
    // Stany: hover (desktop mouse) + focus-visible (klawiatura) + active (click + touch)
    "hover:opacity-90",
    "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[--lg-accent-brand]",
    "active:scale-[0.97]",
    // Spring transition
    "transition-all duration-200 ease-spring",
    "disabled:pointer-events-none disabled:opacity-40",
  ),
  {
    variants: {
      variant: {
        // Primary — solid accent
        default: cn(
          "bg-[--lg-accent-brand] hover:bg-[--lg-accent-brand-hover] text-white",
          "rounded-lg-xl shadow-lg-1 hover:shadow-lg-2",
        ),
        // Secondary — glass surface
        secondary: cn(
          "lg-card text-[--lg-label-primary]",
          "hover:shadow-lg-2",
        ),
        // Destructive — material red
        destructive: cn(
          "bg-[--lg-material-red] text-white rounded-lg-xl",
          "hover:opacity-80",
        ),
        // Ghost — tekst only
        ghost: "text-[--lg-accent-brand] hover:bg-[--lg-accent-brand-muted] rounded-lg-md",
        // Link
        link: "text-[--lg-accent-brand] underline-offset-4 hover:underline",
      },
      size: {
        default: "h-12 px-6 rounded-lg-xl",          /* 48px — desktop standard */
        sm:      "h-10 px-4 rounded-lg-md",           /* 40px — drugorzędny */
        lg:      "h-14 px-8 rounded-lg-xl text-lg-body",  /* 56px — CTA główny senior */
        icon:    "h-11 w-11 rounded-lg-xl max-md:h-12 max-md:w-12", /* 44px+mobile 48px */
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)
```

### 3.3 Dialog — desktop primary (wycentrowany), mobile bottom sheet

```tsx
// Overlay
<DialogOverlay
  className={cn(
    "fixed inset-0 z-50",
    "bg-black/30 backdrop-blur-sm",
    "data-[state=open]:animate-in data-[state=closed]:animate-out",
    "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0"
  )}
/>

// Content — desktop wycentrowany primary
<DialogContent
  className={cn(
    "lg-modal",
    "fixed z-50 grid gap-4 p-6",
    // Desktop — wycentrowany modal (primary use case)
    "left-[50%] top-[50%] translate-x-[-50%] translate-y-[-50%]",
    "w-full max-w-lg",
    // Mobile responsive — bottom sheet override
    "max-md:bottom-0 max-md:left-0 max-md:right-0 max-md:top-auto",
    "max-md:translate-x-0 max-md:translate-y-0",
    "max-md:rounded-t-[28px] max-md:rounded-b-none",
    // Spring animation
    "duration-300 ease-spring",
    "data-[state=open]:animate-in data-[state=closed]:animate-out",
    "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
    "data-[state=open]:zoom-in-95 max-md:data-[state=open]:zoom-in-100",
    "max-md:data-[state=open]:slide-in-from-bottom-full",
  )}
/>
```

### 3.4 Popover — desktop primary action sheet

```tsx
// components/ui/popover.tsx — NOWY w v2.0.0 (zastępuje Sheet dla desktop)
import * as PopoverPrimitive from "@radix-ui/react-popover"
import { cn } from "@/lib/utils"

const PopoverContent = React.forwardRef<
  React.ElementRef<typeof PopoverPrimitive.Content>,
  React.ComponentPropsWithoutRef<typeof PopoverPrimitive.Content>
>(({ className, align = "end", sideOffset = 4, ...props }, ref) => (
  <PopoverPrimitive.Portal>
    <PopoverPrimitive.Content
      ref={ref}
      align={align}
      sideOffset={sideOffset}
      className={cn(
        // Glass Level 2 — popover jako modal desktop
        "lg-modal",
        "z-50 min-w-[8rem] overflow-hidden p-1",
        // Spring animation
        "data-[state=open]:animate-in data-[state=closed]:animate-out",
        "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
        "data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95",
        "data-[side=bottom]:slide-in-from-top-2",
        "data-[side=top]:slide-in-from-bottom-2",
        "duration-200 ease-spring",
        className
      )}
      {...props}
    />
  </PopoverPrimitive.Portal>
))
```

### 3.5 Sheet — mobile responsive action sheet

```tsx
// Sheet — używany TYLKO dla mobile responsive (max-md: context)
<SheetContent
  side="bottom"
  className={cn(
    "lg-modal lg-sheet-bottom",
    "pb-safe max-h-[90vh] overflow-y-auto",
    "pt-0 px-4",
    // Spring slide
    "duration-300 ease-spring",
    "data-[state=open]:animate-in data-[state=closed]:animate-out",
    "data-[state=closed]:slide-out-to-bottom data-[state=open]:slide-in-from-bottom",
  )}
>
  {/* Handle — iOS-like */}
  <div className="flex justify-center py-3">
    <div className="w-10 h-1 rounded-full bg-[--lg-separator-opaque]" />
  </div>
  {children}
</SheetContent>
```

---

## 4. Dark mode hook

```tsx
// hooks/useTheme.ts
'use client'
import { useEffect, useState } from 'react'

type Theme = 'light' | 'dark' | 'system'

export function useTheme {
  const [theme, setTheme] = useState<Theme>('system')

  useEffect( => {
    const stored = localStorage.getItem('lg-theme') as Theme | null
    if (stored) setTheme(stored)
  }, [])

  useEffect( => {
    const root = document.documentElement
    const isDark =
      theme === 'dark' ||
      (theme === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches)
    root.setAttribute('data-theme', isDark ? 'dark' : 'light')
    localStorage.setItem('lg-theme', theme)
  }, [theme])

  return { theme, setTheme }
}
```

---

## 5. layout.tsx — viewport fit cover (mobile responsive)

```tsx
// app/layout.tsx — Next.js 14.2 LTS
import type { Viewport } from 'next'

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#FAF7F2' },   /* Wariant 1 bg */
    { media: '(prefers-color-scheme: dark)',  color: '#1A1612' },
  ],
  width: 'device-width',
  initialScale: 1,
  viewportFit: 'cover',   // WYMAGANE dla safe-area-inset-* na iPhone (mobile responsive)
}
```

---

## 6. useMediaQuery hook (dla Popover/Sheet responsive)

```tsx
// hooks/useMediaQuery.ts
'use client'
import { useEffect, useState } from 'react'

export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(false)

  useEffect( => {
    const mq = window.matchMedia(query)
    setMatches(mq.matches)
    const handler = (e: MediaQueryListEvent) => setMatches(e.matches)
    mq.addEventListener('change', handler)
    return  => mq.removeEventListener('change', handler)
  }, [query])

  return matches
}

// Convenience hook
export const useIsDesktop =  => useMediaQuery('(min-width: 768px)')
```
