---
name: responsive-web-standards-2026
description: Foundation web standards 2026 — HTML5 semantic, mobile-first CSS (320/768/1024/1440 breakpoints), WCAG 2.2 AA (20+ items), Core Web Vitals 2026 (LCP <2.5s, INP <200ms NEW, CLS <0.1), Lighthouse 95+ checklist, dark mode, fluid type clamp, image opt (AVIF/WebP/JPEG), font loading (next/font swap), third-party isolation (Partytown). Konsumowany przez web-builder + calculator-builder + page-speed-optimizer.
version: 1.0.0
compatible_with: [webapp]
tags: [web, responsive, accessibility, wcag, cwv, performance, standards-2026]
requires: []
token_cost: medium
distribution: library/skills/webapp/
last_updated: 2026-05-11
---

# responsive-web-standards-2026

Foundation skill — referencja normatywna. Agenty citują konkretne sekcje (§1-§10) podczas projektowania UI/layoutów/komponentów.

**Scope:** HTML5, mobile-first CSS, WCAG 2.2 AA, CWV 2026, Lighthouse 95+, dark mode, fluid type, image opt, font loading, third-party isolation. Framework-agnostic; przykłady w Next.js 14+/15.

**NIE pokrywa:** SSR/SSG/ISR strategies, state management, testing, security headers → `web-security-headers-2026` (future).

Pliki towarzyszące:
- `cwv-targets.yaml` — CWV thresholds + measurement tools per device class
- `wcag-2-2-aa-checklist.md` — 20+ items literal, per principle, PASS/FAIL
- `image-opt-strategy.md` — AVIF/WebP/JPEG decision tree, next/image, srcset

---

## 1. Kiedy uruchomić

Uruchom gdy projektujesz layout/komponent (§2 HTML, §3 breakpoints), sprawdzasz WCAG compliance (§4 checklist), optymalizujesz CWV (§5 thresholds), implementujesz dark mode (§6), fluid type (§7), wybierasz format obrazka (§8), ładujesz fonty (§9), izolujesz third-party scripts (§10).

NIE uruchamiaj: content strategy GW → `content-strategy-construction`, technical SEO → `seo-fundamentals`, advanced CWV fixes → `seo-advanced`, security headers → `web-security-headers-2026`.

---

## 2. HTML5 Semantic

| Element | ARIA role | Kiedy |
|---|---|---|
| `<header>` | `banner` | Nagłówek strony lub sekcji — logo, nav, h1 |
| `<nav>` | `navigation` | Menu główne, breadcrumbs |
| `<main>` | `main` | Treść główna (1 per strona) |
| `<article>` | `article` | Samoistna treść: post blogowy, karta produktu |
| `<section>` | *(implicite)* | Tematyczna część — MUSI mieć nagłówek h2/h3 |
| `<aside>` | `complementary` | Sidebar, related content — poboczne do main |
| `<footer>` | `contentinfo` | Stopka — copyright, linki pomocnicze |

**ARIA roles fallback:** gdy element semantyczny niedostępny → `role="banner"`, `role="navigation"`, `role="main"`, `role="complementary"`, `role="contentinfo"`.

**Skip link** (WCAG 2.4.1): `<a href="#main-content" class="sr-only focus:not-sr-only">Przejdź do treści</a>` jako pierwszy element `<body>`.

**Heading hierarchy:** jedna h1 per strona, nigdy nie pomijaj poziomów (h1→h2→h3).

**Anti-pattern:** `<div class="header">` zamiast `<header>` — screen reader traci landmark.

---

## 3. Mobile-First CSS Strategy

| Breakpoint | px | Tailwind | Opis |
|---|---|---|---|
| Base | 0-319px | (brak) | Małe telefony — edge case |
| `sm` | 320px+ | `sm:` | Standardowy telefon |
| `md` | 768px+ | `md:` | Tablet portrait |
| `lg` | 1024px+ | `lg:` | Laptop / tablet landscape |
| `xl` | 1440px+ | `xl:` | Desktop wide |

Piszemy CSS na base (mobile), nadpisujemy dla większych ekranów (`min-width`).

```css
/* Mobile first */
.grid { display: grid; grid-template-columns: 1fr; }
@media (min-width: 768px) { .grid { grid-template-columns: repeat(2, 1fr); } }
@media (min-width: 1024px) { .grid { grid-template-columns: repeat(3, 1fr); } }
```

**Tailwind equivalent:** `<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">`

---

## 4. WCAG 2.2 AA — Top Issues Preview

Pełna checklist 20+ items → `wcag-2-2-aa-checklist.md`.

**Top 5 najczęstszych problemów:**

| Problem | SC | Quick fix |
|---|---|---|
| Brak alt text | 1.1.1 A | `alt="opis"` informacyjne; `alt=""` dekoracyjne |
| Kontrast <4.5:1 | 1.4.3 AA | WebAIM Checker + dostosowanie palette |
| Brak focus visible | 2.4.7 AA | Nigdy `outline: none` bez custom focus ring |
| Target size <44px | 2.5.5 AA (NEW) | `min-width: 44px; min-height: 44px` |
| Brak `lang` na html | 3.1.1 A | `<html lang="pl">` |

**NOWE w WCAG 2.2:** 2.5.5 Target Size 44×44px, 2.4.11 Focus Not Obscured (sticky header), 3.3.7 Redundant Entry (autofill multi-step), 2.5.7 Dragging Movements alternative.

---

## 5. Core Web Vitals 2026

Thresholds szczegółowe → `cwv-targets.yaml`.

| Metric | Good | Needs Improvement | Poor |
|---|---|---|---|
| **LCP** (Largest Contentful Paint) | ≤2.5s | 2.5-4.0s | >4.0s |
| **INP** (Interaction to Next Paint) | ≤200ms | 200-500ms | >500ms |
| **CLS** (Cumulative Layout Shift) | ≤0.1 | 0.1-0.25 | >0.25 |

**UWAGA:** INP zastąpił FID od marca 2024. FID jest deprecated — nie używaj.

**Narzędzia:** Lighthouse CI (lab), `web-vitals.js` v3+ (field), Chrome DevTools Performance tab, Google Search Console CWV report.

**Top fixes — LCP:** preload LCP image (`priority` prop + `fetchpriority="high"`), server response <600ms.
**Top fixes — INP:** dynamic imports (code splitting), Partytown dla third-party scripts, `useTransition` React 18+.
**Top fixes — CLS:** `width`+`height` na images, `aspect-ratio` CSS, reserve space dla dynamic content.

---

## 6. Lighthouse 95+ Checklist

| Category | Top 5 Issues |
|---|---|
| **Performance** | Oversized images bez srcset, render-blocking JS/CSS, no lazy loading below-fold, large JS bundles, no preconnect |
| **Accessibility** | Brak alt text, missing labels, insufficient contrast, missing ARIA landmarks, duplicate IDs |
| **Best Practices** | HTTPS invalid, console errors, images bez width/height (CLS), deprecated APIs, mixed content |
| **SEO** | Missing title/description, brak hreflang, robots.txt blokuje, brak JSON-LD, broken internal links |

**CI gate:** performance ≥95, accessibility ≥95, best-practices ≥90, SEO ≥95. Fail on error: true.

---

## 7. Dark Mode

```css
:root { --color-bg: #fff; --color-text: #111827; --color-accent: #2563eb; }
@media (prefers-color-scheme: dark) {
  :root { --color-bg: #0f172a; --color-text: #f1f5f9; --color-accent: #60a5fa; }
}
/* Manual toggle override */
html.dark { --color-bg: #0f172a; --color-text: #f1f5f9; --color-accent: #60a5fa; }
```

**Toggle pattern (localStorage):**
```ts
function toggleDark {
  const isDark = document.documentElement.classList.toggle('dark');
  localStorage.setItem('theme', isDark ? 'dark' : 'light');
}
// On load: apply saved preference over system preference
const saved = localStorage.getItem('theme');
const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
if (saved === 'dark' || (!saved && prefersDark)) document.documentElement.classList.add('dark');
```

**Tailwind:** `darkMode: 'class'` w `tailwind.config.ts`. Kontrast 4.5:1 obowiązuje w obu motywach.

---

## 8. Fluid Type i Space

```css
/* Font-size fluid — clamp(min, preferred, max) */
.heading-xl { font-size: clamp(1.5rem, 1rem + 2.5vw, 3rem); }
.heading-lg { font-size: clamp(1.25rem, 0.75rem + 2vw, 2rem); }
.body-text   { font-size: clamp(1rem, 0.875rem + 0.5vw, 1.125rem); }

/* Fluid spacing */
.section-gap { padding-block: clamp(2rem, 5vw, 6rem); }
```

**Generator:** utopia.fyi — fluid type + space scale. Modular scale ratio 1.25 (Major Third) lub 1.333.

---

## 9. Image Optimization

Pełna strategia + decision tree → `image-opt-strategy.md`.

| Format | Kiedy | Support 2026 |
|---|---|---|
| **AVIF** | Hero images, large photos (best compression ~50% vs JPEG) | ~95% |
| **WebP** | Fallback dla AVIF, ogólne zdjęcia (~30% vs JPEG) | ~97% |
| **JPEG** | Legacy fallback | 100% |
| **PNG** | Transparency required | 100% |
| **SVG** | Ikony, logo, diagramy | 100% |

```tsx
// LCP image — priority prop (fetchpriority="high" + preload)
<Image src="/hero.jpg" alt="Opis" width={1200} height={600} priority quality={85} />

// Below-fold — lazy + blur placeholder
<Image src="/card.jpg" alt="Opis" width={400} height={300} loading="lazy" placeholder="blur" blurDataURL="..." />

// Responsive — sizes critical dla bandwidth
<Image src="/photo.jpg" alt="Opis" fill
  sizes="(max-width: 768px) 100vw, (max-width: 1024px) 50vw, 33vw" />
```

**next/image** serwuje AVIF/WebP automatycznie — nie musisz ręcznie konwertować plików.

---

## 10. Font Loading i Third-Party Isolation

**next/font (font loading):**
```tsx
import { Inter } from 'next/font/google';
const inter = Inter({ subsets: ['latin', 'latin-ext'], display: 'swap', variable: '--font-inter' });
```
`font-display: swap` zapobiega FOIT. `latin-ext` wymagany dla PL znaków (ą, ę, ó, ś, ź, ż).

**Preload critical font (nie next/font):**
```html
<link rel="preload" href="/fonts/Inter.woff2" as="font" type="font/woff2" crossorigin="anonymous">
```

**Partytown (third-party isolation):**
```tsx
// GA4 przez Partytown — runs off main thread → INP improvement
<Script src="https://www.googletagmanager.com/gtag/js?id=G-XXXX" strategy="worker" />
```
Stosuj dla: GA4, GTM, Facebook Pixel, HotJar — wszystkie analytics/tracking blokujące INP.

**async/defer + Resource Hints:**
```html
<script defer src="/non-critical.js"></script>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="dns-prefetch" href="https://www.googletagmanager.com">
```

---

## Anti-wzorce

1. **Layout shift (CLS >0.1)** — brak `width`/`height` na `<img>`, dynamic content bez zarezerwowania przestrzeni.
2. **Render-blocking JS** — `<script>` synchroniczny bez `async`/`defer`, third-party analytics blokujące main thread.
3. **Oversized images** — JPEG raw bez optymalizacji, brak responsive `srcset`, `loading="eager"` below-fold.
4. **ARIA misuse** — `<div role="button">` bez `tabindex="0"` i keyboard handler; użyj `<button>` (natywna obsługa focus/Enter/Space).
5. **Keyboard trap** — modal bez Esc handler, focus nie wraca do trigger button po zamknięciu.
6. **Color-only information** — status error/success tylko kolorem bez ikony/tekstu (niewidoczne dla color blind).
7. **Hidden focus indicators** — `outline: none` bez custom focus ring; 2px solid, contrast ≥3:1 obowiązkowy.

---

## Powiązania

**Downstream (konsumują):**
- `web-builder` (5C E4) — §2 HTML semantic, §3 breakpoints, §9 font loading, §10 third-party
- `calculator-builder` (5C E5) — §4 WCAG touch targets, §5 CWV INP dla interactive forms
- `page-speed-optimizer` (5C E6) — §5 CWV thresholds, §8 image opt, §9 font loading

**Cross-ref:**
- `seo-fundamentals` (5A E1) — CWV baseline TU, advanced fixes w `seo-advanced`. Boundary: foundation thresholds vs deep optimization.
- `webapp-standards` (existing) — TypeScript/structure/security/CI TAM, HTML/CSS/WCAG/CWV TU.

---

## References

1. web.dev/articles/vitals — Google CWV 2026 oficjalne thresholds
2. developer.mozilla.org/en-US/docs/Web/Accessibility/Understanding_WCAG — MDN WCAG 2.2
3. w3.org/TR/WCAG22/ — W3C WCAG 2.2 specification
4. a11yproject.com/checklist — The A11y Project checklist
5. nextjs.org/docs/app/building-your-application/optimizing — Next.js performance docs
6. webaim.org/resources/contrastchecker — WebAIM Contrast Checker
