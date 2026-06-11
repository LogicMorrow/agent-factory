# examples.md — inspiracje portfolio 2026

5 referencyjnych portfolio + co od kogo wziąć dla portfolio operatora (analityk + sprzedaż B2B + AI engineer + AI art hobby).

## 1. Brittany Chiang — brittanychiang.com

**Stack:** Next.js, Tailwind, dark mode default.
**Aesthetic:** dark + emerald accent (`#64FFDA`), monospace headings, terminal-style.
**Layout:** sticky left side nav, smooth scroll, sections (About / Experience / Projects / Contact).

**Co wziąć dla operatora:**
- ✅ Sticky **left side nav** zamiast top nav (Wzorzec 2) — działa świetnie dla 5 sekcji
- ✅ Monospace headings (JetBrains Mono) — wzmacnia "AI/dev" aesthetic
- ✅ Sekcja Experience z chronologią — przerobić na "Case studies"
- ✅ Linki zewnętrzne z `↗` icon — czytelne że external
- ❌ Numbered section headers (`01.`, `02.`) — zbyt copy-paste'owe, użyć innego marker

## 2. Lee Robinson — leerob.io

**Stack:** Next.js 14+, Tailwind, MDX blog.
**Aesthetic:** minimalist, white bg (light mode default), Inter font, lots of whitespace.
**Layout:** simple stack — header / about / blog list / footer.

**Co wziąć dla operatora:**
- ✅ **Inter font** dla body — clean, neutral, czytelny PL fleksja
- ✅ Minimalist sekcje — jedna idea per sekcja, dużo whitespace
- ✅ Footer prosty (linki + last-update date)
- ❌ Light mode default — operator preferuje dark (AI/dev aesthetic)
- ❌ Heavy blog focus — operator v1.0 bez bloga (opt-in v1.1)

## 3. Bartosz Ciechanowski — bartoszciechanowski.com

**Stack:** custom vanilla JS, hand-rolled animations.
**Aesthetic:** light bg, blue accent, hand-drawn diagrams, deep technical case studies.
**Layout:** essay-style (long-form), interactive demos embedded.

**Co wziąć dla operatora:**
- ✅ **Deep case studies** — 3 case'y w stylu "explainer", nie buzzword summary
- ✅ Inline mini-demos (np. cold mailing pipeline visualization) — pokazuje umiejętność
- ✅ Tabela tools z kontekstem (NIE generic "Python, SQL")
- ❌ Hand-rolled JS — overkill, Framer Motion wystarczy
- ❌ Essay-length — operator portfolio nie jest blog, case studies max 300-500 słów

## 4. Rauno Freiberg — rauno.me

**Stack:** Next.js, motion-heavy.
**Aesthetic:** white bg, motion design playground, mikrointerakcje wszędzie.
**Layout:** experiments / writing / projects.

**Co wziąć dla operatora:**
- ✅ **Mikrointerakcje** (Wzorzec 4) — hover scale, link underline animation
- ✅ "Things I made" sekcja dla hobby AI art (gallery + lightbox)
- ❌ Motion overdose — Rauno robi to professionally, operator nie jest motion designer. Use sparingly.
- ❌ Hand-rolled cursor effects — gimmick, nie pasuje do profesjonalnego portfolio AI engineer

## 5. Josh Comeau — joshwcomeau.com

**Stack:** Gatsby + custom MDX components.
**Aesthetic:** colorful, sketchy, gradient accents, lots of personality.
**Layout:** home with intro + blog + courses.

**Co wziąć dla operatora:**
- ✅ **Osobowość w copy** — pisze konkretnie, nie corporate. operator portfolio MA mieć głos.
- ✅ Color accents w nagłówkach (1-2 słowa highlighted)
- ❌ Sketchy aesthetic — operator target: AI engineer + analityk → cleaner, professional
- ❌ Course-selling focus — operator nie sprzedaje kursów

## Synteza — paleta inspiracji dla operatora

| Element | Inspiracja | Implementacja |
|---|---|---|
| Layout | Brittany Chiang (left sticky nav) | Sticky left side nav, 5 sekcji |
| Typography | Lee Robinson (Inter) | Inter body + JetBrains Mono akcent |
| Aesthetic | Brittany Chiang (dark + accent) | `#0A0A0B` bg + `#10B981` accent |
| Case studies | Bartosz Ciechanowski (depth) | 3 case'y z "Problem→Approach→Tools→Outcome→Lessons" |
| Mikrointerakcje | Rauno (subtle) | Hover scale 1.02, link underline slide-in |
| Voice/copy | Josh Comeau (osobowość) | Konkret zamiast buzzword, "ja zbudowałem" zamiast "stworzono" |

## Anti-references (czego unikać)

- ❌ Portfolio typu "stunning hero image + lorem ipsum" — pusty content, AI-generated vibe
- ❌ Awwwards-winning sites z scroll-jacking — wow factor, ale UX broken (Wzorzec anti-1)
- ❌ Portfolio bez wideo/demo — w 2026 sama bio + linki nie wystarczy dla AI engineera (oczekiwanie show-not-tell)
- ❌ Portfolio dual-purpose (freelance + job) gdzie obie persony konfliktują w jednym CTA — operator rozwiązuje przez Wzorzec 6 (CTA-dual)

## Konkretne reuse dla portfolio operatora

1. **Hero:** Brittany Chiang style — duże imię + tagline 1 linia + 2 CTA side-by-side
2. **Wideo:** self-hosted, max 30s, lazy load (NIE jak Awwwards-winning sites z autoplay full-screen)
3. **Sticky nav:** Brittany Chiang left side (desktop), burger mobile
4. **Sekcje:** stack pionowo (Lee Robinson minimalism), 5 sekcji w MVP
5. **Case studies:** Bartosz Ciechanowski depth, 3 case'y max
6. **Mikrointerakcje:** Rauno subtelność, nie overdose
7. **Footer:** Lee Robinson prostota — linki + last-update + GitHub link do source
8. **Voice:** Josh Comeau osobowość, ale profesjonalny ton (nie sketchy)

## Status

v1.0.0 (2026-05-13) — 5 inspiracji + synteza dla operatora. Updates po realnym deploy + operator feedback.
