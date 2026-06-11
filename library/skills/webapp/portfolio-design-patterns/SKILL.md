---
name: portfolio-design-patterns
description: "Wzorce nowoczesnego portfolio 2026 — 8 patterns: Hero+Video, Sticky-Nav, Scroll-Reveal, Mikrointerakcje, Case-Study layout, CTA-dual (freelance+job), Dark-mode, Fluid-typography. Stack: Next.js 15 + Tailwind + opt-in Framer Motion. Konsumowany przez web-builder (E8 mode=portfolio), interactivity-designer (E7), portfolio-content-writer (E6). NIE używać do: korporacyjne strony usługowe (→ web-builder default), blog-heavy sites (→ seo-content-writer), ecommerce."
version: 1.0.0
compatible_with: [webapp]
tags: [portfolio, design, web-patterns, nextjs, tailwind, framer-motion, 2026]
requires: [responsive-web-standards-2026]
token_cost: medium
distribution: library/skills/webapp/
last_updated: 2026-05-13
---

# portfolio-design-patterns

Wzorce projektowe nowoczesnego portfolio (one-page lub multi-section) 2026 dla dewelopera / AI engineera / hybrydy zawodowej. Stack: **Next.js 15 + Tailwind 4 + opt-in Framer Motion**. Filozofia: **evergreen > trendy**, **a11y first**, **performance-aware**.

**Bundle pliki:**
- `SKILL.md` — 8 wzorców + decyzje per wzorzec (ten plik)
- `anti-patterns.md` — czego NIE robić (scroll-jacking, autoplay-sound, motion-bez-reduced-motion)
- `examples.md` — referencyjne portfolio + co od kogo wziąć

## When to use this skill

Uruchamiaj gdy:
- `web-builder` ma `--mode=portfolio` (E8 paczki) → bootstrap 5 sekcji wg wzorców
- `interactivity-designer` (E7) projektuje motion → consume anti-patterns + Pattern 4 (Mikrointerakcje)
- `portfolio-content-writer` (E6) planuje layout sekcji → consume Pattern 5 (Case-Study) + Pattern 6 (CTA-dual)
- Code-implementer pisze TSX komponenty → consume Pattern 2 (Sticky-Nav), 7 (Dark), 8 (Fluid)

## Pre-execution context loading

Agent konsumujący ten skill MA czytać:
- `responsive-web-standards-2026/wcag-2-2-aa-checklist.md` (a11y baseline)
- `responsive-web-standards-2026/cwv-targets.yaml` (perf budget)
- `anti-patterns.md` (w tym bundle)

## Wzorzec 1: Hero + Video

**Cel:** pierwsze 2 sekundy decydują o "stay or bounce". Wideo = silne pierwsze wrażenie, ale BLOKUJE LCP jeśli źle zaimplementowane.

### Decyzje techniczne

| Aspekt | Decyzja |
|---|---|
| Hosting | Self-hosted (kontrola, GDPR, brak cookies) |
| Format | MP4 (H.264 baseline) + WebM (VP9) — multiple `<source>` |
| Długość | **Max 30s** dla hero clip. Dłuższe wideo (1-3 min "o mnie") opt-in w sekcji case study lub modal. |
| Poster | **Zawsze**. JPEG/WebP, ~80KB. Bez postera = czarny ekran przez 1-2s. |
| Preload | `preload="metadata"` (NIE `auto`, NIE `none`). Ładuje pierwszy frame + meta. |
| Autoplay | `muted autoplay playsinline` — przeglądarki BLOKUJĄ autoplay z dźwiękiem. Mute jest mandatory. |
| Loop | OK dla hero (krótki clip). Wyłącz dla dłuższych wideo. |
| Captions | VTT, język PL. **Mandatory** dla wideo z mową (a11y). |
| Controls | `controls` jeśli wideo > 10s. Bez `controls` jeśli ambient loop. |
| Mobile | Test na 3G slow. Fallback: poster only + button "Odtwórz wideo" + lazy load po click. |

### Markup wzorcowy (TSX)

```tsx
<section className="hero">
  <video
    poster="/media/hero-poster.webp"
    preload="metadata"
    muted
    autoPlay
    playsInline
    loop
    className="hero__video"
    aria-label="operator przy pracy — analityka, AI engineering, sprzedaż B2B"
  >
    <source src="/media/hero.webm" type="video/webm" />
    <source src="/media/hero.mp4" type="video/mp4" />
    <track kind="captions" src="/media/hero-pl.vtt" srcLang="pl" label="Polski" default />
  </video>
  <div className="hero__overlay">
    <h1>operator Nowak — AI engineer · analityk · B2B sales</h1>
    <p>Buduję agenty AI, piszę cold maile, analizuję dane.</p>
    <div className="hero__cta">
      <a href="mailto:you@example.com?subject=Projekt%20freelance">Wynajmij na projekt</a>
      <a href="mailto:you@example.com?subject=Aplikacja%20full-time">Zatrudnij full-time</a>
    </div>
  </div>
</section>
```

### LCP optimization

- Poster JPEG ma być **LCP element**, nie wideo.
- `<link rel="preload" as="image" href="/media/hero-poster.webp">` w `<head>`.
- Wideo lazy load: ładuj `<source>` dopiero gdy user scrolluje > 50vh (IntersectionObserver).

## Wzorzec 2: Sticky Nav

**Cel:** szybka nawigacja między sekcjami bez scroll-frustration. Opt-in (mobile może mieć burger menu).

### Decyzje

- **Desktop:** sticky top nav lub sticky left side nav (sidebar style — Brittany Chiang).
- **Mobile:** burger menu lub bottom-fixed mini-nav (3-4 ikony max).
- **Anchor links:** smooth scroll do sekcji (CSS `scroll-behavior: smooth` + `scroll-margin-top` na sekcjach, żeby fixed nav nie zasłaniał headera).
- **Active state:** podświetlanie current section via IntersectionObserver.
- **Hide on scroll-down, show on scroll-up** (opcjonalnie, jeśli nav zabiera dużo miejsca).

### Markup wzorcowy

```tsx
<nav className="sticky top-0 z-50 backdrop-blur bg-bg-primary/80 border-b border-border">
  <ul className="flex gap-6 px-4 py-3">
    <li><a href="#hero" className="active:underline">Start</a></li>
    <li><a href="#o-mnie">O mnie</a></li>
    <li><a href="#co-robie">Co robię</a></li>
    <li><a href="#case-studies">Case studies</a></li>
    <li><a href="#kontakt">Kontakt</a></li>
  </ul>
</nav>
```

### Scroll-margin (CSS):

```css
section[id] {
  scroll-margin-top: 80px; /* height of sticky nav */
}
```

## Wzorzec 3: Scroll-Reveal (subtelne!)

**Cel:** sekcje pojawiają się w viewport z micro-animacją (fade + translateY). Sprawia że "stoi do czytania".

### Decyzje

- **Tylko translateY(20px) + opacity 0→1**. NIE rotacje, NIE scale > 1.05, NIE blur.
- **Duration: 0.4-0.6s**. Krótko, żeby nie irytować.
- **Easing:** `ease-out` lub `cubic-bezier(0.16, 1, 0.3, 1)` (snappy).
- **Trigger:** IntersectionObserver z `threshold: 0.15` (gdy 15% sekcji w viewport).
- **prefers-reduced-motion:** ZAWSZE pomiń animację, pokaż statycznie.

### Markup (Framer Motion lub CSS-only)

**CSS-only fallback** (preferowany — zero JS overhead):

```css
@media (prefers-reduced-motion: no-preference) {
  .reveal {
    opacity: 0;
    transform: translateY(20px);
    transition: opacity 0.5s ease-out, transform 0.5s ease-out;
  }
  .reveal.in-view {
    opacity: 1;
    transform: translateY(0);
  }
}
```

**Framer Motion variant** (opt-in dla bardziej złożonych):

```tsx
import { motion } from 'framer-motion'

<motion.section
  initial={{ opacity: 0, y: 20 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, amount: 0.15 }}
  transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
>
  ...
</motion.section>
```

## Wzorzec 4: Mikrointerakcje

**Cel:** delight bez przesady. Hover/focus/click feedback.

### Inwentarz mikrointerakcji w portfolio

| Element | Mikrointerakcja | Implementation |
|---|---|---|
| Link | Underline slide-in (left→right) | `transition: text-decoration-thickness 0.2s` lub `::after` pseudo |
| Button primary | Subtle scale (1.0 → 1.02) + shadow lift | `hover:scale-[1.02] transition-transform` |
| Card | Border highlight + slight lift | `hover:border-accent hover:-translate-y-1` |
| Image | Zoom (1.0 → 1.05) inside fixed frame | `overflow-hidden` parent + `hover:scale-105` child |
| Icon | Rotate 0 → 5deg lub fill change | `hover:rotate-3 transition-transform` |
| Code block | Click-to-copy + toast | JS + clipboard API |
| Section heading | Anchor link `#` appears on hover | `:hover ::before { content: '#'; opacity: 1 }` |

### Constraints

- **Duration:** 100-300ms (przekroczenie = "laggy")
- **Easing:** `ease-out` dla "snappy" feel
- **Touch devices:** hover NIE działa, więc primary action ma być widoczna bez hover (tylko bonus delight on hover)
- **Reduced motion:** disabled (lub minimalne — opacity only)

## Wzorzec 5: Case Study layout

**Cel:** pokazać głębię, nie szerokość. 2-4 case studies > 10 superficial projects.

### Struktura 5-elementowa

| Element | Co zawiera | Długość |
|---|---|---|
| **Problem** | Jaki realny problem klienta/projektu | 1-2 zdania |
| **Approach** | Jak podchodzimy + co odrzucone | 2-4 zdania |
| **Tools** | Konkretne tech (Claude API, Python, pandas, n8n…) | Lista 3-6 itemów |
| **Outcome** | Metryka + przykład (NIE buzzwords) | 1-2 zdania + screenshot/wideo |
| **Lessons** | Co bym zmienił, gdybym powtarzał | 1 zdanie (pokora = trust) |

### Markup wzorcowy (MDX)

```mdx
## Case study #1 — Automatyzacja cold mailingu B2B dla [klient]

**Problem.** Manualny outreach do 500 prospektów/mies zajmował 20h/tydz.

**Approach.** Zbudowałem pipeline: scraper (LinkedIn Sales Navigator) → enrichment (Apollo API) → personalization (Claude API) → send (Lemlist) → tracking (PostgreSQL + Metabase). Odrzuciłem ChatGPT API ze względu na slot limits.

**Tools.** Python, Claude API (claude-sonnet-4-6), Apollo, Lemlist, PostgreSQL, Metabase.

**Outcome.** Czas spadł z 20h → 3h/tydz. CTR maili wzrósł z 8% do 19% (per A/B test 200/200).

**Lessons.** Personalizacja Claude API musi mieć HITL gate — w 5% case'ów ton był zbyt formalny. Następnym razem dodałbym strict tone guidelines w prompt.
```

### Visual layout

- 2-column desktop: text left, screenshot/video right (alternate per case)
- Mobile: stack vertically, screenshot pod tekstem

## Wzorzec 6: CTA-dual (freelance + job)

**Cel:** jeden portfolio, dwie persony użytkownika. Bez konfliktu, bez "wybierz wersję" toggle (dodatkowa friction).

### Decyzje

| Wariant | Plus | Minus | Rekomendacja |
|---|---|---|---|
| **Dual CTA side-by-side** | Najprościej, user wybiera | operator musi rozróżniać 2 typy maili | **REKOMENDACJA** v1.0 |
| Toggle freelance/job (UI switch) | Customized copy per mode | Friction, JS state | v1.1 opt-in |
| Dwa osobne site (`/freelance`, `/job`) | Pełna kontrola | Duplikacja content, SEO split | NIE |

### Markup wzorcowy

```tsx
<section id="kontakt" className="contact">
  <h2>Pracujmy razem</h2>
  <p>Jeśli szukasz...</p>
  <div className="cta-dual">
    <a
      href="mailto:you@example.com?subject=Projekt%20freelance%20—%20[temat]&body=Cześć%20operator..."
      className="cta cta--primary"
    >
      <strong>Wynajmij na projekt</strong>
      <span>Cold mailing setup · agent AI · analytics dashboard</span>
    </a>
    <a
      href="mailto:you@example.com?subject=Aplikacja%20full-time%20—%20[stanowisko]&body=Cześć%20operator..."
      className="cta cta--secondary"
    >
      <strong>Zatrudnij full-time</strong>
      <span>AI engineer · data analyst · B2B sales hybrid</span>
    </a>
  </div>
  <p className="contact__alt">
    Lub: <a href="mailto:you@example.com">you@example.com</a> ·
    <a href="https://linkedin.com/in/...">LinkedIn</a> ·
    <a href="https://github.com/LogicMorrow">GitHub</a>
  </p>
</section>
```

### Pre-fill body w mailto:

- `?subject=Projekt%20freelance%20—%20[temat]&body=Cześć%20operator...`
- URL-encode (`%20` zamiast spacja, `%5B` zamiast `[`)
- Body max 200 znaków (limit niektórych klientów email)

## Wzorzec 7: Dark mode

**Cel:** AI/dev portfolio domyślnie dark. Light mode opt-in v1.1 (nie MVP — overhead testów).

### Decyzje

- **v1.0:** dark only. Brak toggle. Mniej code, mniej bug surface.
- **v1.1:** toggle ze `localStorage` persist + `prefers-color-scheme` media query. Tailwind `darkMode: 'class'`.
- **Paleta dark:** patrz karta projektu sekcja 6 (`#0A0A0B` bg, `#F5F5F4` text, `#10B981` accent).
- **Contrast ratio:** ≥ 4.5:1 (WCAG AA) dla body text, ≥ 7:1 dla powerful claims.

### Tailwind config (v1.1 ready)

```ts
// tailwind.config.ts
export default {
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        bg: { primary: '#0A0A0B', secondary: '#141416' },
        text: { primary: '#F5F5F4', muted: '#A3A3A3' },
        accent: '#10B981',
        border: '#27272A',
      },
    },
  },
}
```

## Wzorzec 8: Fluid typography (clamp)

**Cel:** typografia skaluje się płynnie 320px → 1920px bez breakpoints stepwise. Lepszy reading experience.

### CSS pattern

```css
:root {
  --fs-body: clamp(1rem, 0.9rem + 0.5vw, 1.125rem);     /* 16px → 18px */
  --fs-h1: clamp(2rem, 1.5rem + 2.5vw, 4rem);            /* 32px → 64px */
  --fs-h2: clamp(1.5rem, 1.2rem + 1.5vw, 2.5rem);        /* 24px → 40px */
  --fs-h3: clamp(1.25rem, 1.1rem + 0.75vw, 1.75rem);     /* 20px → 28px */
  --fs-small: clamp(0.875rem, 0.8rem + 0.3vw, 1rem);     /* 14px → 16px */
}

body { font-size: var(--fs-body); line-height: 1.6; }
h1 { font-size: var(--fs-h1); line-height: 1.1; }
h2 { font-size: var(--fs-h2); line-height: 1.2; }
h3 { font-size: var(--fs-h3); line-height: 1.3; }
```

### Formuła clamp:

`clamp(MIN, PREFERRED, MAX)`
- MIN: rozmiar mobile (320px)
- MAX: rozmiar desktop (1920px)
- PREFERRED: linear interpolation, np. `1rem + 0.5vw`

### Line height — inverse scale

- Headings: tight (1.1-1.3)
- Body: relaxed (1.5-1.7)
- Small (captions, code): 1.4

## Procedury (use case)

### Procedura A: bootstrap portfolio (E8 web-builder mode=portfolio)

1. Bootstrap Next.js 15 stack (deleguje do `webapp-bootstrapper`)
2. Apply Tailwind config z Wzorca 7 (dark palette)
3. Generuj 5 sekcji wg Wzorca 5 (Case-Study) + 6 (CTA-dual) + 1 (Hero+Video)
4. Add Sticky Nav (Wzorzec 2)
5. Add Scroll-Reveal (Wzorzec 3) z `prefers-reduced-motion` respect
6. Add Fluid typography (Wzorzec 8) w global CSS
7. Run Lighthouse — target CWV PASS

### Procedura B: review existing portfolio component (interactivity-designer E7)

1. Czytaj plik `app/components/<Name>.tsx`
2. Check 8 wzorców — jakie zastosowane, jakie missing
3. Check `anti-patterns.md` — czy któryś naruszony
4. Output: ADR z trade-off + propozycja patche

## Trade-offs

| Wybór A | Wybór B | Kiedy A | Kiedy B |
|---|---|---|---|
| Framer Motion | CSS-only animations | Złożone choreografie, scroll-triggers | Prosty fade + translate, mniej JS bundle |
| Self-hosted video | YouTube embed | GDPR, kontrola | Bandwidth saving Vercel |
| Sticky nav | Static nav | Long page, multiple sections | Short single-screen portfolio |
| Dual CTA side-by-side | Toggle UI switch | MVP v1.0 | v1.1 customized copy |
| Dark only | Light + Dark toggle | MVP, AI/dev aesthetic | v1.1, accessibility request |

## Status

v1.0.0 (2026-05-13) — initial release dla paczki `af-pack-<nazwa>` (E2 plan paczki). Update kwartalnie z lessons #110+ paczki portfolio.

## Referencje

- patrz `examples.md` — inspiracje konkretnych portfolio
- patrz `anti-patterns.md` — czego unikać
- `responsive-web-standards-2026/cwv-targets.yaml` — perf budget
- `responsive-web-standards-2026/wcag-2-2-aa-checklist.md` — a11y baseline
