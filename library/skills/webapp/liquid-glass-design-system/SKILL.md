---
name: liquid-glass-design-system
description: Design system iOS Springboard estetyka NA DESKTOPIE (1280-1920px laptop biurowy primary, mobile responsive fallback) — glassmorphism + blur + dual-mode tokens (desktop blur 6/12/20 / mobile blur 8/16/24 reversal vs ), Apple HIG senior 50+, 3 warianty palety z default ciepły gradient drewno+dach, popover-first dla action sheets desktop, Tailwind+shadcn pattern adapters (komponenty kopiowane BEZ biblioteki). Konsument source of truth dla agent ios-ux-checker 12 checków A-L. v2.0.0 REBUILD  fundamental error.
tools: Read, Write
model: opus
version: "2.0.0"
compatible_with: [webapp]
requires: []
tags: [design-system, ios, springboard, liquid-glass, desktop-first, glassmorphism, apple-hig, tailwind, shadcn-pattern, kontrakt-C, , rebuild]
token_cost: high
distribution: library/skills/webapp/
last_updated: 2026-05-29
last_reviewed: 2026-05-29
valid_until: 2027-05-29
breaking_changes_from: "1.0.0"
breaking_changes_note: "v2.0.0 reversal mobile-first → desktop-first (lesson  POST-MORTEM). Tokens blur swap: desktop primary 6/12/20px (vs mobile 8/16/24px). Default touch targets 44pt desktop primary (Apple HIG mouse), 48-56pt mobile responsive (touch senior). Surface opacity 0.6 desktop (mocniejszy contrast) vs 0.4 mobile (pełny glass). Bottom-sheet patterns → popover-first dla desktop, sheet jako mobile responsive variant. Agent mobile-ios-ux-checker → rename ios-ux-checker desktop-first 12 checków A-L."
---

# Liquid Glass Design System v2.0.0 — DESKTOP-FIRST

## ADR — Scope i desktop-first reversal ( v2.0.0)

**Status:** ACCEPTED 2026-05-29
**Breaking change:** v1.0.0 → v2.0.0 reversal mobile-first → desktop-first (karta projektu DemoApp sekcja 6)

### Lesson  (POST-MORTEM)

 zawierała fundamental error: autor skilla założył "mobile-first absolutny" bez konsultacji z operatorem.
Kontekst projektu: **70-80% użycia = laptop biurowy 1280-1920px**. Mobile (Safari iPhone) = read-only
przegląd na budowie. Reversal v2.0.0 naprawia każdy token, wzorzec i przykład.

| Wymiar | v1.0.0 (BŁĄD ) | v2.0.0 (POPRAWNE ) |
|---|---|---|
| Primary viewport | Mobile 375px | Desktop 1280-1920px |
| Blur desktop | `--lg-blur-1: 6px` jako KOREKTA | `--lg-blur-1: 6px` jako DEFAULT |
| Blur mobile | 8/16/24px jako secondary | 8/16/24px jako `max-md:` override |
| Touch targets | 48pt minimum (touch-first) | 44pt desktop (mouse), 48-56pt `max-md:` |
| Surface opacity | 0.70 cards (glass pełny) | 0.60 desktop primary (mocniejszy kontrast) |
| Action sheets | Bottom Sheet primary | Popover desktop primary + Sheet `max-md:` |
| Tailwind prefiksy | `md:` `lg:` upgrade (mobile-first) | `max-md:` `max-sm:` downgrade (desktop-first) |

**Scope:** webapp business single-tenant, desktop-first.
**NIE dotyczy:** personal portfolio → `portfolio-design-patterns`.

---

## 1. Kiedy uruchomić

Uruchom gdy:
- Projektujesz UI biznesowej webapp z estetycznym benchmark Apple iOS Springboard **na desktopie**
- Stack: Next.js 14.2+ + Tailwind 4 + shadcn pattern (komponenty kopiowane, BEZ biblioteki)
- Użytkownik docelowy = senior 50+ nie-IT, laptop biurowy primary, iPhone read-only
- Potrzebujesz gotowych tokenów `--lg-*` i klas Tailwind zamiast pisać od zera
- Implementujesz komponenty glass (Card, Popover, Sheet mobile, Button) z WCAG AA

**Nie uruchamiaj dla:**
- Portfolio personalnego → `portfolio-design-patterns`
- Apki multi-user bez wymogu iOS estetyki → `responsive-web-standards-2026`
- Prostej strony marketingowej → `webapp-standards`

---

## 2. Kluczowe zasady (DESKTOP-FIRST v2.0.0)

1. **Desktop-first absolutny** — token bez prefiksu = desktop (1280-1920px). `max-md:` / `max-sm:` = adaptacja mobilna.
2. **Dual-mode tokens z reversal** — desktop primary (blur 6/12/20px, opacity 0.60), mobile responsive (blur 8/16/24px, opacity 0.40-0.70).
3. **4 poziomy głębokości** — Level 0 (background solid) / 1 (cards) / 2 (modals/popovers) / 3 (overlays). Nigdy >2 levele w jednym widoku.
4. **Vibrancy** — tło "przebija się" przez glass. Transparencja 60-70% desktop, 40-70% mobile.
5. **Kontrast WCAG AA obowiązkowy** — 4.5:1 body, 3:1 large text. Glass surface nie zwalnia.
6. **Touch targets dual** — 44pt desktop primary (mouse, Apple HIG), 48-56pt mobile responsive (touch senior `max-md:`).
7. **Max 3 CTA per viewport** — clutter reduction dla nie-IT seniora.
8. **Prefix `--lg-`** — WSZYSTKIE CSS variables mają prefix `--lg-`. Zero wyjątków. Nie koliduje z `--portfolio-*`.
9. **Spring animations** — `cubic-bezier(0.32, 0.72, 0, 1)` 200-300ms. Nie `ease-in-out` dla glass.
10. **Fallback backdrop-filter** — zawsze `@supports (backdrop-filter: blur(0))` z solid-color fallback.
11. **Popover-first desktop** — action sheets = `<Popover>` / `<DropdownMenu>` desktop, `<Sheet side="bottom">` mobile responsive `max-md:`.
12. **3 warianty palety, default Wariant 1** — finalizacja w  przy bootstrappie apki. Patrz `tokens-color-typography.md`.

---

## 3. Pliki tematyczne (indeks)

| Plik | Zawartość |
|---|---|
| [`tokens-color-typography.md`](tokens-color-typography.md) | 3 warianty palety (default: ciepły drewno+dach), CSS variables `--lg-*`, typography scale iOS-inspired, dark mode |
| [`tokens-elevation-spacing.md`](tokens-elevation-spacing.md) | **Blur dual-mode (desktop 6/12/20 / mobile 8/16/24)**, shadow stack, radius, spacing 8pt grid |
| [`tailwind-shadcn-integration.md`](tailwind-shadcn-integration.md) | Tailwind 4 config snippet, shadcn pattern adapters (Card, Dialog, Popover, Sheet, Button) — **desktop-first** |
| [`apple-hig-senior.md`](apple-hig-senior.md) | **44pt desktop primary** + 48-56pt mobile responsive, typography, kontrast WCAG AA, CTA 3-max, popover patterns |
| [`contract-C-tokens.md`](contract-C-tokens.md) | JSON schema v2 — design-tokens (producer→web-builder/code-implementer), weryfikacja przez ios-ux-checker |
| [`examples-and-anti-patterns.md`](examples-and-anti-patterns.md) | 4 pary dobrze/źle **desktop-first**, 7 anti-patterns (AP1: mobile-first prefixes, AP2: brak fallback, AP5: single-mode) |

---

## 4. HITL Gate B.E1 — 3 warianty palety (wybór Wariant 1 jako default)

Pełne CSS variables wszystkich wariantów w `tokens-color-typography.md`. Tu streszczenie.

**Wariant 1 (DEFAULT) — "Ciepły gradient drewno+dach"**
- Accent: `#B97A35` (ciepły miedziany)
- Background: gradient `#FAF7F2 → #EEE4D3`
- Surfaces: subtle blue cast `#F0F4FA`
- Tekst: slate-900 (`#0F172A`)
- Kontrast text/glass: 13:1 WCAG AAA
- Personality: drewno, dom, ciepło — właściwe dla dekarza
- **Status: DEFAULT — użyj w DemoApp. Finalizacja logo+brand .**

**Wariant 2 — "Chłodny przemysłowy stal"**
- Accent: `#2E5C8A` (chłodny stalowy niebieski)
- Background: `#F5F7FA → #E8EDF5`
- Kontrast: 14:1 WCAG AAA
- Personality: profesjonalizm, precyzja techniczna

**Wariant 3 — "Akcentowy lakier samochodowy"**
- Accent: `#C53030` (czerwony jak dachówka ceramiczna)
- Background: `#FCFCFD → #F0F1F3` neutral
- Kontrast: 15:1 WCAG AAA
- Personality: energia, alert, natychmiastowa akcja

**Decyzja finalna:** Wariant 1 DEFAULT. operator podejmuje ostateczną decyzję w  przy bootstrappie.
Flag: `brand_palette_variant: 1` w design-tokens.json (łatwa zamiana na 2 lub 3).

---

## 5. Przykłady: dobrze vs źle (desktop-first)

### Para 1 — Glass card desktop-first

**Źle (v1.0.0 mobile-first error):**
```tsx
// WRONG — mobile-first w desktop-first projekcie
<div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
  <div style={{ background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(8px)' }}>
    <button className="min-h-[48px]">Akcja</button>
  </div>
</div>
```
Problemy: mobile-first prefiksy `md:`/`lg:`, inline style bez tokenów, brak `@supports` fallback.

**Dobrze (v2.0.0 desktop-first):**
```tsx
// CORRECT — desktop default, mobile max-md: adaptation
<div className="grid grid-cols-3 gap-6 max-lg:grid-cols-2 max-md:grid-cols-1">
  <article className="lg-card p-5 cursor-pointer transition-all duration-200 ease-spring active:scale-[0.98]">
    <h3 className="text-lg-title-3 font-medium text-[--lg-label-primary]">Kowalski Jan</h3>
    <p className="text-lg-body text-[--lg-label-secondary]">Dach 120 m² — wycena</p>
    <button className="min-h-[44px] max-md:min-h-[48px] px-4 rounded-lg-md
                       bg-[--lg-accent-brand] text-white mt-3">
      Pobierz PDF
    </button>
  </article>
</div>
```

### Para 2 — Popover desktop + Sheet mobile (NOWY wzorzec v2.0.0)

**Źle (v1.0.0 — Bottom Sheet everywhere):**
```tsx
// WRONG — bottom sheet na desktop jak mobile
<Sheet open={open}>
  <SheetContent side="bottom">
    <Button>Opcja 1</Button>
    <Button>Opcja 2</Button>
  </SheetContent>
</Sheet>
```

**Dobrze (v2.0.0 — popover desktop primary):**
```tsx
// CORRECT — Popover desktop, Sheet mobile responsive
const isDesktop = useMediaQuery('(min-width: 768px)')

return isDesktop ? (
  <Popover>
    <PopoverTrigger asChild>
      <Button variant="secondary" className="min-h-[44px]">Akcje oferty</Button>
    </PopoverTrigger>
    <PopoverContent className="lg-modal w-48 p-2">
      <Button variant="ghost" className="w-full justify-start" onClick={onPdf}>Pobierz PDF</Button>
      <Button variant="ghost" className="w-full justify-start" onClick={onEdit}>Edytuj</Button>
      <Button variant="ghost" className="w-full justify-start text-[--lg-material-red]" onClick={onDelete}>
        Usuń
      </Button>
    </PopoverContent>
  </Popover>
) : (
  <Sheet open={sheetOpen} onOpenChange={setSheetOpen}>
    <SheetContent side="bottom" className="lg-modal pb-safe px-4">
      <div className="flex justify-center py-3"><div className="w-10 h-1 rounded-full bg-[--lg-separator-opaque]" /></div>
      <Button size="lg" className="w-full mt-2" onClick={onPdf}>Pobierz PDF</Button>
      <Button size="default" variant="secondary" className="w-full mt-2" onClick={onEdit}>Edytuj</Button>
    </SheetContent>
  </Sheet>
)
```

---

## 6. Antywzorce (skrót — pełna lista w `examples-and-anti-patterns.md`)

1. **AP1 mobile-first prefiksy** — `md:` `lg:` jako primary pattern zamiast default=desktop + `max-md:` adaptacja. Lesson .
2. **AP2 brak fallback backdrop-filter** — Firefox <100 renderuje niewidoczną kartę. Zawsze `@supports`.
3. **AP3 prefix `--portfolio-*`** — tylko `--lg-*` w tym systemie (ADR zasada #8).
4. **AP4 hardcoded rgba zamiast tokenów** — `rgba(255,255,255,0.15)` nie reaguje na dark mode ani wariant palety.
5. **AP5 single-mode tokens (brak dark)** — każdy token ma wersję `:root` i `[data-theme="dark"]`.
6. **AP6 bottom sheet wszędzie** — desktop = Popover. Sheet tylko `max-md:` (mobile responsive).
7. **AP7 5+ CTA per viewport** — max 3, reszta w Popover/Sheet. Niezbędne dla seniora 50+.

---

## 7. Spójność z ios-ux-checker (12 checków A-L)

Agent `ios-ux-checker` waliduje implementację względem tego skilla. Mapowanie:

| Check | Zasada z tego skilla |
|---|---|
| A — Touch targets | zasada #6: 44pt desktop, 48-56pt `max-md:` |
| B — Typografia ≥17px | typography scale (body = 17pt minimum) |
| C — Kontrast WCAG AA | zasada #5: 4.5:1 body, 3:1 large text |
| D — Max 3 CTA | zasada #7 |
| E — hover+focus-visible+active | tailwind-shadcn-integration.md Button adapters |
| F — Desktop-first responsive | zasada #1: default=desktop, `max-md:` mobile |
| G — CSS variables `--lg-*` | zasada #8, blur desktop 6/12/20 |
| H — Popover desktop + Sheet mobile | zasada #11 |
| I — Spring animations | zasada #9: cubic-bezier(0.32, 0.72, 0, 1) |
| J — Safe-area mobile | tokens-elevation-spacing.md safe-area insets |
| K — Dark mode | tokens-color-typography.md dual-mode |
| L — Polski UI | apple-hig-senior.md słownik PL |

---

## 8. Powiązania

- **`webapp-standards`** — baza standardów webapp. Ten skill nabudowany na `webapp-standards`.
- **`ios-ux-checker`** (agent, opus) — waliduje każdy ekran po implementacji (desktop-first 12 checków A-L). Source of truth = ten skill.
- **`web-builder`** (agent) — konsument kontraktu C (design-tokens.json). Używa tokenów przy budowaniu komponentów.
- **`code-implementer`** (agent) — implementuje komponenty shadcn pattern z adapterami z `tailwind-shadcn-integration.md`.
- **`portfolio-design-patterns`** (skill) — odmienna estetyka (portfolio osobiste). Cross-reference w ADR.
- **`responsive-web-standards-2026`** (skill) — responsive patterns komplementarne.

---

## 9. Workflow konsumenta (5 kroków)

1. **Wczytaj `design-tokens.json`** z `assets/`. Wybierz wariant palety (default: 1).
2. **Zastąp `<accent-color>`** kolorem z karty projektu. Nie hardcoduj w pliku.
3. **Skopiuj `tailwind.config.ts` snippet** z `tailwind-shadcn-integration.md`. Sprawdź Tailwind 4 compat.
4. **Skopiuj komponenty** (Card, Button, Popover, Sheet) z `tailwind-shadcn-integration.md` do projektu.
5. **Uruchom `ios-ux-checker`** po implementacji pierwszego ekranu — walidacja 12 checków A-L.

---

## 10. Before starting work (cross-agent-learning)

Apply silently.

1. Read `.claude/memory/errors-liquid-glass-design-system.md` — jeśli istnieje.
2. Glob `knowledge-base/reflections/*liquid-glass*.md` → head 3 → Read.
3. Read `knowledge-base/lessons.jsonl` tail 20.
4. Budget ≤5k tokenów.

---

## 11. Czego NIE robi i do kogo odesłać

- **Nie waliduje własnego outputu** → `quality-checker` po każdym nowym ekranie.
- **Nie projektuje komponentów** → `web-builder` (layout) / `code-implementer` (TSX).
- **Nie zastępuje `ios-ux-checker`** — skill jest wiedzą, agent jest runtime-walidatorem.
- **Nie dyktuje finalnej palety** — decyzja operatora w . Wariant 1 to solidny default.
- **Nie dotyczy portfolio** → `portfolio-design-patterns`.

---

## 12. ACTIVITY-LOG

Sekcja do logowania zdarzeń (zasada #10 CLAUDE.md). Pola: `ts, actor, action, artifact, skill, skill_version, notes`.

```json
{
  "ts": "2026-05-29T00:00:00Z",
  "actor": "skill-builder",
  "action": "skill_rebuilt",
  "artifact": "library/skills/webapp/liquid-glass-design-system/",
  "skill": "liquid-glass-design-system",
  "skill_version": "2.0.0",
  "notes": "REBUILD v1.0.0→v2.0.0 desktop-first reversal  POST-MORTEM"
}
```
