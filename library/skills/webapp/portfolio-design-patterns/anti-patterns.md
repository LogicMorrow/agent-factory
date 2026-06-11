# anti-patterns.md — czego NIE robić w portfolio 2026

11 wzorców których należy **eksplicytnie unikać** podczas budowy portfolio. Hard rules — agent `interactivity-designer` BLOKUJE propozycje naruszające. Lint w `webapp-code-reviewer`.

## 1. Scroll-jacking (override scrollwheel)

**Co to:** custom scroll handler, który zmienia natywną prędkość scrolla, animuje "snap-to-section", lub blokuje scroll podczas animacji.

**Dlaczego ŹLE:**
- Frustruje powe userów (CTRL+End, klawisz End, scrollbar drag — wszystko BLOK).
- Trackpad gesture ignored — UX broken.
- Slow devices laggą animację, user nie widzi "gdzie jest".

**ŹLE:**
```js
window.addEventListener('wheel', (e) => {
  e.preventDefault
  customSmoothScrollTo(nextSection)
})
```

**DOBRZE:** natywny scroll + `scroll-snap-type: y mandatory` (CSS) jeśli koniecznie snap.

```css
html { scroll-snap-type: y proximity; }
section { scroll-snap-align: start; }
```

## 2. Autoplay z dźwiękiem

**Co to:** `<video autoplay>` bez `muted`, lub muzyka tła startująca przy załadowaniu.

**Dlaczego ŹLE:**
- Browsers BLOKUJĄ (Chrome od 2018, Safari od 2018).
- Otwierając portfolio w pracy → embarrassing dla usera.
- A11y disaster — screen reader users nie mogą wyłączyć.

**ŹLE:**
```html
<video autoplay loop src="hero.mp4"></video>
<audio autoplay src="background.mp3"></audio>
```

**DOBRZE:**
```html
<video autoplay muted playsinline loop src="hero.mp4" poster="hero.webp"></video>
<!-- audio: tylko jako click-to-play, NIGDY autoplay -->
```

## 3. Parallax overdose

**Co to:** każda sekcja ma parallax background, każdy element ma scroll-speed override.

**Dlaczego ŹLE:**
- Motion sickness (znaczna część populacji).
- Performance: każdy scroll event reflow.
- Mobile: parallax wygląda dziwnie (nie ma "głębi").

**Limit:** max 1 element z parallax na cały site (np. hero background image). Reszta = standard layout.

**`prefers-reduced-motion: reduce` → wyłącz całkowicie.**

## 4. Motion bez `prefers-reduced-motion` respect

**Co to:** animacje (scroll-reveal, hover scale, page transitions) bez fallback dla użytkowników z motion sensitivity.

**Dlaczego ŹLE:**
- WCAG 2.3.3 (Level AAA) wymaga.
- ~35% populacji ma jakąś formę motion sensitivity.
- Vestibular disorders → portfolio fizycznie szkodzi.

**ŹLE:**
```css
.card { animation: bounce 0.5s ease-out; }
```

**DOBRZE:**
```css
@media (prefers-reduced-motion: no-preference) {
  .card { animation: bounce 0.5s ease-out; }
}

/* lub: */
.card {
  animation: bounce 0.5s ease-out;
}
@media (prefers-reduced-motion: reduce) {
  .card { animation: none; }
}
```

**JS / Framer Motion:**
```tsx
import { useReducedMotion } from 'framer-motion'

const shouldReduceMotion = useReducedMotion
const variants = shouldReduceMotion
  ? { initial: { opacity: 1 }, animate: { opacity: 1 } }
  : { initial: { opacity: 0, y: 20 }, animate: { opacity: 1, y: 0 } }
```

## 5. Infinite scroll na homepage

**Co to:** content ładuje się przy scrollu w nieskończoność (jak feed Twittera).

**Dlaczego ŹLE:**
- Portfolio MA być finite — pokazujesz konkretne projekty, nie nieskończony feed.
- Footer nieosiągalny → user nie widzi "Kontakt".
- SEO broken — Googlebot nie scrolluje JS.

**DOBRZE:** finite sections + pagination dla blog (jeśli v1.1).

## 6. Cookie modal blokujący view (gdy go nie potrzeba)

**Co to:** cookie banner pojawia się na portfolio bez cookies/trackerów.

**Dlaczego ŹLE:**
- Jeśli nie zbierasz PII / nie używasz GA4 → cookie banner NIE jest wymagany GDPR.
- Bouncuje user (modal frustration).
- operator portfolio: zero third-party, NIE potrzebuje banneru.

**DOBRZE:** zero cookie banner w MVP (zero trackers). Jeśli v1.1 dodajesz GA4 → wtedy banner (preferencja: Plausible cookieless → nadal bez banneru).

## 7. Splash loader > 2s

**Co to:** "loading…" screen przed pokazaniem treści (often z animacją).

**Dlaczego ŹLE:**
- CWV LCP > 2.5s = FAIL.
- Pierwsze wrażenie: "wolny site, słaby developer".
- 53% userów bounce > 3s load.

**DOBRZE:**
- SSG (Next.js `generateStaticParams`) → instant HTML.
- Loader tylko dla async content (np. Stripe widget w v1.1) — placeholder skeleton zamiast spinner.

## 8. Hover-only mobile interactions

**Co to:** dropdown menu działa tylko na hover (desktop). Mobile = broken.

**Dlaczego ŹLE:**
- Mobile traffic > 50% (PL ~60% w 2026).
- Touch nie ma hover → menu się nie pokazuje.

**DOBRZE:** click/tap toggle dla dropdown (Disclosure pattern). Hover BONUS dla desktop.

```tsx
const [open, setOpen] = useState(false)
<button onClick={ => setOpen(!open)} aria-expanded={open}>Menu</button>
{open && <ul>...</ul>}
```

## 9. Tiny fonts < 14px body

**Co to:** body text 12px lub mniejszy.

**Dlaczego ŹLE:**
- WCAG 2.5.5 (target size) violated.
- 30% userów PL > 50 lat — wzrok limit.
- Mobile: 12px → nieczytelne bez zoom.

**DOBRZE:**
- Body: min 16px (`clamp(1rem, 0.9rem + 0.5vw, 1.125rem)` z Wzorca 8).
- Captions/footnotes: min 14px (`clamp(0.875rem, ...)`).

## 10. Low contrast text < 4.5:1

**Co to:** szary tekst na białym tle (#888 na #fff = ratio 3.4:1 — FAIL).

**Dlaczego ŹLE:**
- WCAG 2.1.1 (AA) wymaga 4.5:1 dla body, 3:1 dla large text.
- 8% mężczyzn ma deficyt kolorów (deuteranopia/protanopia).
- Outdoor mobile (jasne słońce) → invisible.

**DOBRZE:**
- Body: contrast ≥ 4.5:1 (`#F5F5F4` na `#0A0A0B` = ratio ~17:1 — PASS).
- Test tool: WebAIM Contrast Checker.

## 11. Hover/focus indicators removed

**Co to:** `outline: none` na `:focus` bez alternatywy.

**Dlaczego ŹLE:**
- Keyboard navigation BROKEN — user nie wie gdzie jest focus.
- WCAG 2.4.7 (Focus Visible) FAIL.
- Screen reader users → bonus frustration.

**ŹLE:**
```css
button:focus { outline: none; }
```

**DOBRZE:**
```css
button:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}
```

## Status

v1.0.0 (2026-05-13) — 11 anti-patterns. Audytowane przez `interactivity-designer` (E7), `webapp-code-reviewer`, `page-speed-optimizer` przed deploy.

## Cross-reference

- `SKILL.md` — 8 wzorców pozytywnych
- `responsive-web-standards-2026/wcag-2-2-aa-checklist.md` — a11y baseline (full WCAG 2.2 AA lista)
- `responsive-web-standards-2026/cwv-targets.yaml` — perf budget
