# Anti-patterns — czego NIE robić w prostej stronie statycznej

Filozofia: „bez przerostu formy nad treścią". Każdy z poniższych = sygnał, że odchodzisz od celu.

## Architektura
- ❌ **Framework dla strony statycznej.** Next.js/React/Vue dla 6-sekcyjnej wizytówki to over-engineering: build-step, `node_modules`, hydration, większy bundle, wolniejszy start. Jeśli nie ma routingu/stanu/auth — vanilla.
- ❌ **Build-step bez powodu** (Webpack/Vite/SASS) gdy wystarczy jeden `index.html` + CSS variables.
- ❌ **CSS framework** (Tailwind/Bootstrap) dla kilkunastu komponentów — własne klasy + tokens są lżejsze i czytelniejsze.
- ❌ **Biblioteka animacji** (GSAP/Framer) gdy IntersectionObserver + CSS transitions załatwiają sprawę.
- ❌ **jQuery / lodash** — natywne API wystarcza w 2026.

## Ruch i animacje
- ❌ **Autoplay wideo** (zwłaszcza z dźwiękiem) — zawsze na kliknięcie.
- ❌ **Parallax** i animacje tła — rozprasza, szkodzi perf, łamie „jeden przekaz na ekran".
- ❌ **Scroll-jacking** (przejmowanie scrolla) — łamie oczekiwania użytkownika i a11y.
- ❌ **Ruch bez `prefers-reduced-motion`** — to bug dostępności, nie opcja.
- ❌ **Hover-only interakcje na mobile** — touch nie ma hovera; krytyczne akcje muszą działać klikiem.

## Treść i struktura
- ❌ **Sekcje-wypełniacze** bez funkcji (np. „Skills" z logotypami narzędzi — narzędzia należą do opisów projektów).
- ❌ **Lorem ipsum / placeholdery** w wersji publikowanej (`VIDEO_ID`, `FORM_ID`, „Twój tekst tutaj").
- ❌ **Mieszanie person bez hierarchii** — jeden główny odbiorca prowadzi treść i CTA.
- ❌ **Deklaracje zamiast dowodów** („pasjonuję się X") — pokaż projektami i liczbami.
- ❌ **Żargon** tam, gdzie odbiorca nie jest techniczny.

## Wydajność i a11y
- ❌ **Obrazy bez `width`/`height`** → CLS. Zawsze wymiary + `loading="lazy"` + AVIF/WebP.
- ❌ **Wszystkie wagi fontu** — ładuj tylko używane (każda waga to KB).
- ❌ **Iframe wideo ładowany na starcie** — twórz dopiero przy kliknięciu (lazy).
- ❌ **Brak `lang`, alt-ów, focus-visible, kontrastu AA** — baseline a11y nie jest opcjonalny.
- ❌ **Third-party trackery w MVP** — GDPR + perf. Jeśli analytics, to świadomie i z banerem.

## Sekrety i deployment
- ❌ **Sekrety w repo publicznym** — strona statyczna nie ma backendu, więc nie ma czego ukrywać; ale NIE wkładaj kluczy API (Formspree ID to identyfikator publiczny, nie sekret — patrz `secrets-handling`).
- ❌ **Podpinanie domeny na początku** — najpierw zweryfikuj stronę na `*.github.io`, domenę dodaj na końcu (`github-pages-deploy`).
