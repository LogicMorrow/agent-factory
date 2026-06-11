---
name: static-site-premium-patterns
description: Wzorce budowy premium-minimal strony-wizytówki/portfolio w CZYSTYM vanilla HTML/CSS/JS (jeden index.html, zero frameworka, zero build-stepu) — design-tokens (CSS variables), sekcja-jako-krok-procesu, sticky-nav z backdrop-blur, scroll-reveal przez IntersectionObserver + prefers-reduced-motion, modal wideo bez autoplay, formularz serverless (Formspree/Web3Forms), pobranie CV PDF jednym kliknięciem, mobile-first. Filozofia Apple/tenity: dużo whitespace, jeden przekaz na ekran. Konsumowany przez static-site-builder. NIE Next.js/React — to świadomie lekka ścieżka.
version: 1.0.0
compatible_with: [webapp]
tags: [static-site, vanilla, html, css, javascript, portfolio, premium-minimal, github-pages, no-framework, 2026]
requires: [responsive-web-standards-2026]
token_cost: medium
distribution: library/skills/webapp/
last_updated: 2026-06-06
---

# static-site-premium-patterns

Referencja wzorców dla **prostej, szybkiej, eleganckiej strony statycznej** budowanej bez frameworka.
Antyteza over-engineeringu: jeśli stronę da się zrobić jednym `index.html` + `<style>` + `<script>` — robimy tak.

**Scope:** vanilla single-page (HTML5 + CSS3 + ES2020 JS), design-tokens, layout sekcji, mikrointerakcje
czystym JS, dostępność (WCAG 2.2 AA przez `responsive-web-standards-2026`), wideo w modalu, formularz serverless,
CV PDF. Framework-agnostic w sensie: ZERO zależności runtime.

**NIE pokrywa:** React/Next.js/Tailwind (→ `portfolio-design-patterns`), deployment na GH Pages (→ `github-pages-deploy`),
treść/narracja (→ `personal-branding-portfolio-pl`), typografia PL (→ `polish-typography`), wideo encoding/hosting
(→ `video-web-integration`).

Pliki towarzyszące:
- `design-tokens-example.css` — kompletny zestaw CSS variables (paleta, typografia, easing, spacing) jako start
- `vanilla-scroll-reveal.js` — gotowy IntersectionObserver scroll-reveal + sticky-nav blur + video-modal + smooth-scroll
- `anti-patterns.md` — czego NIE robić (over-engineering, autoplay, parallax, framework-bloat)

---

## 1. Kiedy uruchomić

Uruchom gdy: budujesz prostą stronę-wizytówkę/portfolio/landing bez backendu (§2 struktura, §3 tokens),
implementujesz scroll-reveal lub sticky-nav (§4 mikrointerakcje), wstawiasz wideo w modalu (§5), dodajesz
formularz bez serwera (§6) lub przycisk pobrania CV (§7), pilnujesz wydajności/a11y prostej strony (§8).

NIE uruchamiaj: gdy projekt wymaga SSR/routingu/stanu/auth → to webapp, użyj `webapp-standards` + Next.js.

---

## 2. Filozofia: jeden przekaz na ekran, sekcja = krok

Premium-minimal (benchmark filozofii: Apple, tenity.com — NIE kopia estetyki):
- **Dużo whitespace.** Padding sekcji hojny (np. `7rem 3rem` desktop / `4rem 1.5rem` mobile).
- **Jeden cel na sekcję.** Każda sekcja odpowiada na jedno pytanie użytkownika. Zero ozdobników bez funkcji.
- **Struktura jako proces.** Kolejność sekcji = ścieżka prowadzenia odbiorcy (kto→skąd→co→dowody→jak→kontakt).
- **Treść > forma.** Jeśli element nie niesie informacji ani nie wspiera czytania — wyrzuć.
- **Jeden wyróżnik wizualny.** Co najwyżej jedna sekcja łamie rytm (np. ciemne tło dla „serca" strony).

Struktura HTML: semantyczny `<header>` (nav) + `<main>` z `<section id="...">` per krok + `<footer>`.
Każda `<section>` ma `aria-labelledby` wskazujące na jej nagłówek.

---

## 3. Design tokens (CSS variables w `:root`)

Cały system wizualny w zmiennych — zmiana motywu = zmiana kilku linii. Wzorzec (pełny w `design-tokens-example.css`):

```css
:root {
  /* kolor: tło / powierzchnie / 3 poziomy tekstu / akcent / obramowania */
  --bg: #F9F8F6; --surface: #FFFFFF;
  --ink: #111110; --ink-secondary: #5A5A57; --ink-tertiary: #9A9A96;
  --accent: #1A3A2A; --accent-light: #2D5A40; --accent-muted: #E8EDE9;
  --border: #E4E3DF; --border-strong: #C8C7C2;
  /* typografia: display (nagłówki) + body (treść) */
  --font-display: 'Syne', sans-serif; --font-body: 'DM Sans', system-ui, sans-serif;
  /* ruch */
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-in-out: cubic-bezier(0.65, 0, 0.35, 1);
  /* rytm */
  --section-pad: 7rem 3rem; --radius-card: 1.125rem; --radius-pill: 100px;
}
```

**Skala typografii — fluid przez `clamp`** (nie media-query per nagłówek):
- `h1`: `clamp(2.75rem, 6vw, 5rem)`, weight 800, `letter-spacing: -0.03em`
- `h2`: `clamp(2rem, 4vw, 3rem)`, weight 700
- `h3`: `1.375rem`, weight 600 · body `1rem`/`1.6` · label `0.75rem` uppercase `letter-spacing .1em` kolor `--accent`

**Fonty (Google Fonts):** `<link>` z `display=swap`. Preconnect do `fonts.gstatic.com`. Tylko potrzebne wagi.

**Dark accent section:** jedna sekcja może mieć `background: var(--ink); color: var(--surface)` — wyróżnienie „serca".

---

## 4. Mikrointerakcje czystym JS (`vanilla-scroll-reveal.js`)

Wszystko bez bibliotek. Trzy wzorce + reguła ruchu:

1. **Scroll-reveal** — elementy z klasą `.reveal` wpływają (fade-in + `translateY(20px)→0`) gdy wchodzą w viewport:
   ```js
   const io = new IntersectionObserver((entries) => {
     entries.forEach(e => { if (e.isIntersecting) { e.target.classList.add('is-visible'); io.unobserve(e.target); } });
   }, { threshold: 0.15, rootMargin: '0px 0px -10% 0px' });
   document.querySelectorAll('.reveal').forEach(el => io.observe(el));
   ```
   CSS: `.reveal{opacity:0;transform:translateY(20px);transition:opacity .7s var(--ease-out),transform .7s var(--ease-out)} .reveal.is-visible{opacity:1;transform:none}`
2. **Sticky-nav + backdrop-blur po scrollu** — toggle klasy `.scrolled` na `<header>` przy `window.scrollY > 8`
   (przez `requestAnimationFrame` lub `IntersectionObserver` na sentinelu). CSS: `header.scrolled{backdrop-filter:blur(12px);background:color-mix(in srgb,var(--bg) 80%,transparent)}`.
3. **Smooth-scroll menu** — `scroll-behavior:smooth` w CSS + `scroll-margin-top` na sekcjach pod sticky-nav.
4. **REGUŁA RUCHU (twarda):** każdy ruch w `@media (prefers-reduced-motion: reduce){ *,*::before,*::after{animation:none!important;transition:none!important} .reveal{opacity:1;transform:none} }`.

Hover: subtelny (translateY -2px, zmiana `border-color`/`box-shadow`), NIE krzykliwy. Tylko na `@media (hover:hover)`.

---

## 5. Modal wideo bez autoplay (`vanilla-scroll-reveal.js` zawiera handler)

- **Placeholder:** `<button class="video-trigger" data-yt="VIDEO_ID" aria-label="Odtwórz wideo">` z posterem + ikoną play.
- **Otwarcie:** klik → wstaw `<iframe src="https://www.youtube-nocookie.com/embed/VIDEO_ID?autoplay=1" allow="autoplay; fullscreen">` do `<dialog>` lub overlay div. Ciemne tło, centrowany player 16:9 (`aspect-ratio:16/9`).
- **Zamknięcie:** Esc, klik tła, przycisk ×. Po zamknięciu USUŃ iframe (stop odtwarzania). Focus-trap + przywróć focus na trigger.
- **A11y:** `<dialog>` natywny (`showModal`) daje focus-trap i Esc za darmo. `aria-modal`, `role="dialog"`.
- **Zakaz:** autoplay na wejściu strony, dźwięk bez interakcji. Lazy — iframe powstaje DOPIERO przy kliknięciu (perf).

---

## 6. Formularz serverless (bez backendu)

Statyczna strona nie ma serwera → użyj serwisu (Formspree / Web3Forms / formsubmit.co):
```html
<form action="https://formspree.io/f/FORM_ID" method="POST">
  <input type="text" name="name" required>
  <input type="email" name="email" required>
  <textarea name="message" required></textarea>
  <button type="submit">Wyślij</button>
</form>
```
- **Walidacja:** natywna HTML5 (`required`, `type=email`) + opcjonalny JS dla komunikatów PL.
- **Honeypot anti-spam:** ukryte pole `_gotcha` (Formspree) / `botcheck` (Web3Forms).
- **Stan po wysłaniu:** `fetch` + `e.preventDefault` dla inline „Dziękuję, odpiszę w 1 dzień roboczy" (bez przeładowania) — opcjonalne, progresywne ulepszenie.
- **Endpoint ID = identyfikator publiczny**, nie sekret — ale trzymaj w jednym, oznaczonym miejscu (komentarz/config). Patrz `secrets-handling`.
- **Zawsze dawaj alternatywę:** `mailto:` + LinkedIn obok formularza (formularz może paść / spam-filter).

---

## 7. Pobranie CV PDF jednym kliknięciem

- Plik w repo (np. `cv-imie-nazwisko.pdf`), link `<a href="cv-...pdf" download>Pobierz CV ↓</a>`.
- Atrybut `download` wymusza pobranie zamiast otwarcia w karcie.
- Przycisk widoczny w DWÓCH miejscach: nav (sticky, zawsze pod ręką) + sekcja Kontakt.
- Na mobile nav: zostaw logo + przycisk CV (reszta linków w hamburgerze lub schowana).

---

## 8. Wydajność i a11y prostej strony

Vanilla daje przewagę — pilnuj jej (szczegóły norm: `responsive-web-standards-2026`):
- **Zero zależności runtime.** Jeden plik CSS inline lub jeden `<link>`, jeden `<script defer>`.
- **Obrazy:** AVIF/WebP + `loading="lazy"` + wymiary `width`/`height` (zero CLS). Poster wideo zoptymalizowany.
- **Fonty:** `display=swap`, preconnect, tylko potrzebne wagi (Syne 4 wagi + DM Sans 2-3 to już sporo KB — minimalizuj).
- **CWV target:** LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1. Lighthouse ≥ 95 osiągalny trywialnie bez frameworka.
- **A11y baseline:** semantyczny HTML, kontrast AA (sprawdź `--ink` na `--bg`), focus-visible, alt-y, `<dialog>` dla modala, skip-link, `lang="pl"`.
- **Bez third-party trackerów** w MVP (GDPR-friendly). Jeśli analytics — dopiero świadomie, z banerem.

---

## 9. Antywzorce (skrót — pełna lista w `anti-patterns.md`)

- ❌ **Framework dla strony statycznej** (Next.js/React/Tailwind dla 6-sekcyjnej wizytówki) — build-step, `node_modules`, większy bundle, wolniejszy start. Jeśli nie ma routingu/stanu/auth → vanilla.
- ❌ **Autoplay wideo / parallax / animacje tła** — rozprasza, szkodzi perf, łamie „jeden przekaz na ekran".
- ❌ **Ruch bez `prefers-reduced-motion`** oraz **obrazy bez `width`/`height`** (CLS) — to bugi a11y/perf, nie opcje.
- ❌ **Placeholdery w publikowanej wersji** (`VIDEO_ID`, `FORM_ID`, lorem ipsum) i **sekcje-wypełniacze** bez funkcji.

## 10. Dobrze vs źle (wzorce)

**A. Wartości wizualne**
- ✅ Dobrze: `padding: var(--section-pad-y) var(--section-pad-x)` — wszystko w `:root`, zmiana motywu = kilka linii.
- ❌ Źle: `padding: 112px 48px` rozsiane po 20 regułach CSS — magic-numbers, nie do utrzymania.
- *Dlaczego:* tokeny dają spójność i jeden punkt zmiany; magic-numbers rozjeżdżają design przy pierwszej edycji.

**B. Wideo w modalu**
- ✅ Dobrze: `<iframe>` tworzony JS-em DOPIERO przy kliknięciu triggera i usuwany przy zamknięciu.
- ❌ Źle: `<iframe src="...youtube...">` w HTML na starcie strony.
- *Dlaczego:* iframe na starcie ładuje skrypty YouTube (waga + tracking) przed interakcją — psuje LCP/INP i prywatność; lazy iframe = szybki start i stop odtwarzania po zamknięciu.

## 11. Powiązania

- `static-site-builder` (agent) — **konsument** tego skilla: składa `index.html` wg tych wzorców.
- `responsive-web-standards-2026` — WCAG 2.2 AA + CWV + image/font opt (ten skill `requires` tamten).
- `github-pages-deploy` — publikacja gotowej strony (CNAME, DNS, HTTPS).
- `personal-branding-portfolio-pl` — narracja i struktura treści (co wpada w sekcje).
- `polish-typography` — poprawna polska typografia copy (lint przez `polish-proofreader`).
- `video-web-integration` — encoding/hosting/VTT dla wideo wstawianego w modal.

## 12. Checklist przed oddaniem strony

- [ ] Jeden `index.html`, zero build-stepu, zero `node_modules` w repo.
- [ ] Wszystkie design-tokens w `:root`, zero magic-numbers rozsianych po CSS.
- [ ] Każda sekcja `<section id>` + `aria-labelledby`, smooth-scroll + `scroll-margin-top` działa.
- [ ] Scroll-reveal działa + `prefers-reduced-motion` wyłącza ruch (przetestuj w DevTools).
- [ ] Modal wideo: otwiera, Esc/tło/× zamyka, iframe usuwany po zamknięciu, brak autoplay na wejściu.
- [ ] Formularz: walidacja HTML5, honeypot, alternatywa mailto/LinkedIn obok.
- [ ] CV: link `download` w nav + Kontakt, plik obecny.
- [ ] Mobile-first: 320/768/1024 OK, nav zwija się sensownie.
- [ ] Lighthouse ≥ 95 (Perf/A11y/Best/SEO), zero błędów konsoli.
- [ ] Zero placeholderów (`VIDEO_ID`, `FORM_ID`, lorem ipsum) w wersji publikowanej.
