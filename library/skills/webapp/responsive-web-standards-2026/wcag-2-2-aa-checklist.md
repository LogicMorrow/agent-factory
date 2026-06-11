# WCAG 2.2 AA Checklist — 20+ items

Literal compliance checklist. Format: ID | Criterion | Level | How to check | Common fix.

**Legenda Level:** A = must, AA = should (AA wymagany przez EU Accessibility Act od 2025-06-28).

**Narzędzia do testowania:** axe DevTools (browser extension), WAVE, NVDA/VoiceOver (screen reader), keyboard-only navigation.

---

## Principle 1: Perceivable

| # | Criterion | Level | How to check | Common fix | PASS example | FAIL example |
|---|---|---|---|---|---|---|
| 1.1.1 | **Non-text content — alt text** | A | Inspect every `<img>`: alt attribute present | Informative: `alt="wykres sprzedazy Q1 2026"`. Decorative: `alt=""` | `<img src="logo.png" alt="LogicMorrow logo">` | `<img src="logo.png">` (missing alt) |
| 1.3.1 | **Info and relationships (semantic HTML)** | A | HTML validator + axe | Użyj `<table>` dla danych tabelarycznych, `<ul>/<ol>` dla list, nagłówki `<h1>-<h6>` | `<table><caption>Cennik</caption><th>...</th>` | `<div class="table"><div class="row">` |
| 1.3.2 | **Meaningful sequence** | A | Tab/read-order test z screen reader | DOM order = visual order. Unikaj `order:` w CSS bez korekty tabindex | Sekcja z flex — DOM: text first, image second = visual | CSS `order: -1` przesuwa image przed text w CSS, ale DOM czyta text last |
| 1.4.1 | **Use of color — no color-only info** | A | Visual inspection: czy info dostępne bez koloru | Dodaj ikonę lub tekst obok koloru | Błąd: czerwony tekst + ikona "✗" + "Pole wymagane" | Błąd: tylko czerwony border (niewidoczny dla color blind) |
| 1.4.3 | **Color contrast — text 4.5:1** | AA | WebAIM Contrast Checker / axe | Dostosuj kolory. Duży tekst (≥18pt/14pt bold): min 3:1 | `#111827` na `#ffffff` = 19.3:1 PASS | `#9ca3af` na `#ffffff` = 2.85:1 FAIL |
| 1.4.4 | **Resize text 200%** | AA | Browser zoom 200% — czy treść nie jest ucięta | Użyj `rem`/`em`, nie `px` fixed dla font-size | `font-size: clamp(1rem, 2vw, 1.5rem)` — skaluje się | `font-size: 12px` — nie skaluje przy zoom |
| 1.4.10 | **Reflow — 320px bez horizontal scroll** | AA | Resize do 320px width (lub DevTools 320px) | Mobile-first CSS, brak `width: 600px` fixed | Grid → 1 kolumna na mobile | Tabela fixed-width wymaga horizontal scroll |
| 1.4.11 | **Non-text contrast 3:1 (UI components)** | AA | Visual inspection: button border, input border, icons | Dostosuj kolory ramek, ikon — min 3:1 vs tło | Szary button border `#6b7280` na `#fff` = 4.61:1 PASS | `#d1d5db` na `#fff` = 1.32:1 FAIL |
| 1.4.12 | **Text spacing** | AA | UserCSS: `letter-spacing: 0.12em; word-spacing: 0.16em; line-height: 1.5` — czy nic nie ucina | Nie hardcoduj `height: 40px` dla text containers — użyj `min-height` | `min-height: 40px; padding: 0.5rem` | `height: 40px` — ukrywa powiększony tekst |

---

## Principle 2: Operable

| # | Criterion | Level | How to check | Common fix | PASS example | FAIL example |
|---|---|---|---|---|---|---|
| 2.1.1 | **Keyboard accessible** | A | Tab przez całą stronę — czy wszystkie interactive elementy osiągalne | Zamień `<div onClick>` na `<button>` / dodaj `tabindex="0"` + keyboard handler | `<button onClick={...}>Wyślij</button>` | `<div class="btn" onClick={...}>` (nie focusable) |
| 2.1.2 | **No keyboard trap** | A | Tab do modala/popupera → Esc → czy można wyjść | Esc zamyka modal + focus wraca do trigger | Modal: Esc zamyka, focus na `<button>Otwórz modal</button>` | Modal: po Tab wewnątrz focus nie wychodzi, Esc nie działa |
| 2.4.1 | **Bypass blocks — skip link** | A | Tab po wczytaniu strony — czy skip link jest pierwszym elementem | `<a href="#main" class="sr-only focus:not-sr-only">Przejdź do treści</a>` | Skip link widoczny po pierwszym Tab | Brak skip link — screen reader musi przechodzić przez cały nav |
| 2.4.3 | **Focus order logical** | A | Tab przez stronę — kolejność focus = wizualna kolejność | DOM order musi być logiczny. Unikaj tabindex >0 | Tab: logo → nav → main content → footer | tabindex=99 na sidebar wysyła focus do końca strony |
| 2.4.4 | **Link purpose — descriptive anchors** | A | Screen reader list links mode | Link text = cel linku. Nie "kliknij tutaj", "więcej" | `<a href="/blog/post">Jak wybrać GW — poradnik</a>` | `<a href="/blog/post">Kliknij tutaj</a>` |
| 2.4.7 | **Focus visible** | AA | Tab przez stronę — czy focus ring jest widoczny | Nie `outline: none`. Custom: `outline: 2px solid #2563eb; outline-offset: 2px` | `:focus-visible { outline: 2px solid blue; }` | `* { outline: none; }` (developer convenience, a11y fail) |
| 2.4.11 | **Focus not obscured (NEW 2.2)** | AA | Sticky header + Tab — czy focused element nie jest całkowicie zasłonięty | `scroll-padding-top: 80px` (wysokość sticky header) | Sticky nav 60px + `scroll-padding-top: 70px` | Focused link pod sticky nav — focus widoczny ale element zasłonięty |
| 2.5.5 | **Target size ≥44×44px (NEW 2.2)** | AA | DevTools → inspect button/link: computed width/height | `min-width: 44px; min-height: 44px` lub `padding: 12px` | Button: `padding: 12px 24px` → min 44px height | Icon button 16×16px bez padding |
| 2.5.7 | **Dragging movements — alternative (NEW 2.2)** | AA | Sprawdź czy drag-n-drop ma single-pointer alternative | Każda drag funkcja musi mieć click/tap equivalent | Sortable list: drag OR arrow buttons up/down | Tylko drag sortowanie — niedostępne dla motor impaired |

---

## Principle 3: Understandable

| # | Criterion | Level | How to check | Common fix | PASS example | FAIL example |
|---|---|---|---|---|---|---|
| 3.1.1 | **Page language** | A | View Source: `<html lang="...">` | `<html lang="pl">` dla PL strony | `<html lang="pl">` | `<html>` bez lang |
| 3.2.2 | **On input — no unexpected change** | A | Zmień wartość select/checkbox — czy strona nie submittuje lub nie nawiguje | Nie submittuj formularza `onChange` — użyj submit button | Select sortowania: zmiana → czeka na "Zastosuj" button | Select lokalizacji `onChange={router.push(...)}` |
| 3.3.1 | **Error identification** | A | Wyślij pusty formularz — czy każde błędne pole ma opis | `aria-invalid="true"` + `aria-describedby="error-msg-id"` + visible error text | Input Email z `aria-invalid` + "Podaj prawidłowy adres email" | Red border tylko — screen reader nie wie co jest błędem |
| 3.3.2 | **Labels or instructions** | A | Inspect każdy `<input>`: czy ma `<label for>` lub `aria-label` | `<label for="email">Email</label><input id="email">` lub `aria-label="Email"` | `<label for="phone">Telefon</label><input id="phone">` | Placeholder jako jedyna etykieta (znika po wpisaniu) |
| 3.3.3 | **Error suggestion** | AA | Invalid form — czy komunikat błędu sugeruje poprawkę | Error message: "Podaj email w formacie: adres@domena.pl" | "Hasło musi zawierać min. 8 znaków, dużą literę i cyfrę" | "Nieprawidłowe hasło" (bez wskazówki) |
| 3.3.7 | **Redundant entry (NEW 2.2)** | A | Multi-step form — czy dane wpisane w kroku 1 są prefillowane w kolejnych | `localStorage`/state/URL params między krokami | Step 2 pre-fills email z Step 1 | Step 3 prosi o ponowne wpisanie adresu z Step 1 |

---

## Principle 4: Robust

| # | Criterion | Level | How to check | Common fix | PASS example | FAIL example |
|---|---|---|---|---|---|---|
| 4.1.1 | **Parsing — no duplicate IDs** | A | HTML validator (validator.w3.org) + axe | Każde `id` musi być unikalne w DOM | `id="email-field"` raz | `id="submit"` na 3 elementach |
| 4.1.2 | **Name, role, value (ARIA)** | A | Screen reader + axe | Interaktywne elementy mają `name` (label/aria-label), `role`, stan (`aria-expanded`, `aria-checked`) | `<button aria-expanded="false" aria-controls="menu">Menu</button>` | `<div class="menu-btn" data-open="false">` (brak ARIA) |
| 4.1.3 | **Status messages (ARIA live regions)** | AA | Screen reader po akcji async (submit, dodaj do koszyka) | `aria-live="polite"` dla non-urgent, `aria-live="assertive"` dla critical errors | `<div aria-live="polite">Formularz wysłany pomyślnie</div>` | Popup "sukces" pojawia się wizualnie ale screen reader nie odczytuje |

---

## Quick wins — Top 5 dla polskich webapp-ów

| Priority | Issue | Fix | Impact |
|---|---|---|---|
| P1 | Brak alt text na obrazkach | `alt="opis"` lub `alt=""` dla dekoracyjnych | screen reader, SEO |
| P2 | Brak `focus-visible` (developer `outline: none`) | `:focus-visible { outline: 2px solid #2563eb }` | keyboard nav |
| P3 | Niewystarczający kontrast (szary tekst na białym tle) | WebAIM Checker + dostosowanie palette | wszyski użytkownicy, nie tylko a11y |
| P4 | Target size <44px (icon buttons, mini linki) | `min-width: 44px; min-height: 44px` lub `padding: 12px` | mobile + motor impaired |
| P5 | Brak `<html lang="pl">` | Jeden atrybut na layout.tsx | screen reader, SEO |

---

## Narzędzia testowania

| Narzędzie | Typ | Co wykrywa |
|---|---|---|
| **axe DevTools** (browser ext.) | Auto | ~57% WCAG issues automatycznie |
| **WAVE** (browser ext.) | Auto+Visual | Kontrast, labels, landmarks |
| **WebAIM Contrast Checker** | Manual | Color contrast ratio |
| **NVDA** (Windows) / **VoiceOver** (Mac/iOS) | Manual | Real screen reader experience |
| **Keyboard only** | Manual | Focus management, keyboard traps |
| **validator.w3.org** | Auto | HTML parsing, duplicate IDs |
| **Lighthouse Accessibility** | Auto | Subset WCAG issues |

**UWAGA:** Narzędzia automatyczne wykrywają ~30-57% problemów WCAG. Testy manualne (keyboard, screen reader) są obowiązkowe.
