---
name: webapp-calculator-patterns
description: Calculator UX patterns webapp — multistep wizard (3-5 krokow, save progress localStorage), zod walidacje (inline errors), PDF export (react-pdf client/server), share-link (URLSearchParams+LZString), lead-gate OPCJONALNY (DEAL-BREAKER: ZAKAZ external-crm, default email forward Resend/SendGrid/SMTP), mobile UX 44px targets WCAG 2.2 NEW, ARIA live regions a11y.
version: 1.0.0
compatible_with: [webapp]
tags: [calculator, webapp, ux, forms, multistep, pdf, leadgen]
requires: [responsive-web-standards-2026]
token_cost: medium
distribution: library/skills/webapp/
last_updated: 2026-05-11
---

# webapp-calculator-patterns

Skill normatywny dla kalkulatorów lead-gen w webapp-ach (kalkulator stoiska, ROI, wyceny, konfiguratory).
Agenty cytują konkretne sekcje: np. "patrz §1 multistep wizard", "§3 PDF client-side", "§5 lead-gate".

**Pliki towarzyszące:**
- `multistep-wizard-pattern.md` — Zod schema per-step, useReducer dla 4+ kroków, localStorage save
- `pdf-export-template.md` — react-pdf client-side + Next.js route handler server-side + CSS print fallback
- `share-link-strategy.md` — LZString compress + Clipboard API + URL length guard
- `lead-gate-anti-crm.md` — DEAL-BREAKER: ZAKAZ external-crm, Resend default, sample `/api/lead`

**NIE pokrywa:** SSR/SSG/ISR strategies, state management (Zustand/Jotai), A/B testing,
analytics per-step → osobne skille. Przykłady w Next.js 14+/15 App Router + React 18+.

---

## 1. Kiedy uruchomić

Uruchom gdy projektujesz kalkulator w webapp — lead-gen, wycena, ROI, konfigurator.

Cite sekcję per potrzeba:
- §1 Multistep wizard — 3-5 kroków z progress save i walidacją per step
- §2 Walidacje Zod — inline errors, cross-field rules, prevent-next
- §3 PDF export — react-pdf branding + fallback server-side lub CSS print
- §4 Share-link — URLSearchParams + LZString + Clipboard API
- §5 Lead-gate — email capture TYLKO przez email forward (NIE external-crm)
- §6 Mobile UX — touch targets 44px, numeric keyboard, sticky CTA
- §7 Accessibility — ARIA live regions, focus management, screen reader

NIE uruchamiaj dla: dashboardy bez UX capture (→ `webapp-standards`),
CWV-specific fixes (→ `responsive-web-standards-2026 §5`), WCAG global checklist
(→ `responsive-web-standards-2026 §4 wcag-2-2-aa-checklist.md`).

---

## 2. §1 Multistep Wizard

Szczegółowy pattern + kod → `multistep-wizard-pattern.md`.

**Reguły:**
- 3-5 kroków; powyżej 5 → podziel na osobne kalkulatory
- Step indicator widoczny zawsze: "Krok 2 z 4" + opcjonalny progress bar
- LocalStorage save key: `calc-{slug}-state` (serialize cały state po każdym next)
- Restore on mount: `useEffect( => { const saved = localStorage.getItem(key); if (saved) dispatch({ type: 'RESTORE', payload: JSON.parse(saved) }) }, [])`
- `beforeunload` warning gdy state dirty i nie submitted
- Keyboard: Tab/Enter → next (gdy valid), Esc → back/close confirm

**State management:**
- 1-3 kroki → `useState` per field (prostota)
- 4+ kroków lub cross-step validation → `useReducer` (przewidywalność)

**Dobrze vs Źle:**

```tsx
// Dobrze — step indicator + localStorage save
function WizardStep({ step, total, children }) {
  return (
    <div>
      <p aria-live="polite">Krok {step} z {total}</p>
      {children}
    </div>
  );
}
// Po każdym next:
localStorage.setItem(`calc-${slug}-state`, JSON.stringify(state));
```

```tsx
// Zle — brak progress indicator + brak save
function Wizard({ children }) {
  return <div>{children}</div>; // user nie wie ile kroków, straci dane na reload
}
```

---

## 3. §2 Walidacje Zod

Szczegółowy pattern → `multistep-wizard-pattern.md §2`.

**Reguły:**
- Schema per step (NIE jedna globalna — cross-step errors zbyt wcześnie)
- Cross-field rules: `.refine` np. `end > start`
- Inline errors: czerwony tekst pod input + `aria-invalid="true"` + `aria-describedby="field-error"`
- Prevent next na invalid: disable Next button OR scroll do pierwszego błędu + focus
- Submit final: `fullSchema.parse(mergedState)` — ochrona przed manipulacją URL

```tsx
// Dobrze — schema step 2 z cross-field rule
const step2Schema = z.object({
  powierzchnia: z.number.min(4, "Min 4m²").max(400, "Max 400m²"),
  rodzajStoiska: z.enum(["liniowe", "wyspowe", "narozne"]),
}).refine(data => !(data.rodzajStoiska === "wyspowe" && data.powierzchnia < 9), {
  message: "Stoisko wyspowe wymaga min. 9m²",
  path: ["powierzchnia"],
});

// Input z ARIA
<input
  aria-invalid={!!errors.powierzchnia}
  aria-describedby={errors.powierzchnia ? "pow-error" : undefined}
/>
{errors.powierzchnia && (
  <p id="pow-error" role="alert" className="text-red-600 text-sm mt-1">
    {errors.powierzchnia.message}
  </p>
)}
```

```tsx
// Zle — global schema, errors wszystkich kroków naraz
const fullSchema = z.object({ ...step1, ...step2, ...step3 });
// Użytkownik widzi błędy step 3 na step 1
```

---

## 4. §3 PDF Export

Szczegółowy pattern + template → `pdf-export-template.md`.

**Reguły:**
- **Client-side preferred** (react-pdf): szybciej, bez server cost, brak cold-start
- **Server-side fallback** (Next.js route handler `/api/pdf`): gdy layout zbyt złożony dla client render
- Download trigger: `Blob + URL.createObjectURL + <a>.click` → `URL.revokeObjectURL`
- CSS print fallback (`@media print`): gdy react-pdf nie obsługuje przeglądarki (Safari starsze)

**Client-side minimum viable:**
```tsx
import { PDFDownloadLink, Document, Page, Text, View } from '@react-pdf/renderer';

<PDFDownloadLink
  document={<CalcReport data={calcState} />}
  fileName="kalkulator-wynik.pdf"
>
  {({ loading }) => loading ? "Generuję PDF..." : "Pobierz PDF"}
</PDFDownloadLink>
```

**Anti-pattern — SSR import react-pdf:**
```tsx
// Zle — react-pdf nie działa w SSR (Node.js canvas issues)
import { PDFDownloadLink } from '@react-pdf/renderer'; // w Server Component → crash
// Naprawa: dynamic import z ssr: false
const PDFDownloadLink = dynamic( => import('@react-pdf/renderer').then(m => m.PDFDownloadLink), { ssr: false });
```

---

## 5. §4 Share-link

Szczegółowy pattern → `share-link-strategy.md`.

**Reguły:**
- Encode: `LZString.compressToEncodedURIComponent(JSON.stringify(state))`
- Decode on mount: `LZString.decompressFromEncodedURIComponent(params.get("state"))`
- URL pattern: `/{calc-slug}?state={compressed}`
- Max URL ~2000 znaków (safe cross-browser) → guard: jeśli >2000 → fallback do skróconego lub ostrzeżenie
- Copy: Clipboard API + visual feedback (toast/checkmark) przez 2s

```tsx
// Encode
const compressed = LZString.compressToEncodedURIComponent(JSON.stringify(calcState));
const shareUrl = `${window.location.origin}/kalkulator?state=${compressed}`;
await navigator.clipboard.writeText(shareUrl);
```

---

## 6. §5 Lead-gate (OPCJONALNY)

**DEAL-BREAKER — przeczytaj `lead-gate-anti-crm.md` PRZED implementacją.**

**Zasada:** pokaż pełny wynik DOPIERO po email capture.

Default flow:
1. Użytkownik przechodzi 3-5 kroków wizarda
2. Step finalny → formularz email (imie + email, opcjonalnie telefon)
3. Submit → POST `/api/lead` → Resend (preferred 2026) / SendGrid / SMTP
4. Po success → unlock pełny wynik + opcja PDF download

**Providers (hierarchia):**
- Resend — preferred 2026 (prosta API, webhooks, dobra deliverability)
- SendGrid — legacy (więcej konfiguracji, te same możliwości)
- Nodemailer + SMTP — self-hosted, zero third-party cost

**ZAKAZ bezwzględny:** integracja z external-crm lub jakimkolwiek CRM operatora.
Leads klientów NIE trafiają do narzędzi operatora. Szczegóły uzasadnienia → `lead-gate-anti-crm.md`.

---

## 7. §6 Mobile UX

Bazuje na: `responsive-web-standards-2026 §3` (breakpoints) i `§4` (WCAG 2.2 target size).

**Reguły:**
- Touch targets: `min-height: 44px; min-width: 44px` (WCAG 2.2 SC 2.5.5 NEW — obowiązkowe)
- Numeric keyboard: `inputmode="numeric"` dla liczb, `inputmode="decimal"` dla kwot
- Pattern attribute: `pattern="[0-9]*"` — wymusza numeric keyboard na iOS Safari
- Single-column layout poniżej 768px (`grid-cols-1` na mobile → `md:grid-cols-2`)
- Sticky Next button mobile: `fixed bottom-4 left-4 right-4` (above-fold, zawsze widoczny)
- Auto-scroll to next step: `window.scrollTo({ top: 0, behavior: 'smooth' })` po next
- ZAKAZ: hover-only UX (touch nie ma hover)

```tsx
// Dobrze — input mobile-friendly
<input
  type="text"
  inputMode="numeric"
  pattern="[0-9]*"
  className="w-full min-h-[44px] px-4 py-3 text-base rounded-lg border"
/>

// Sticky CTA mobile
<div className="fixed bottom-4 left-4 right-4 md:static md:mt-6">
  <button className="w-full py-4 bg-blue-600 text-white rounded-xl min-h-[44px]">
    Dalej →
  </button>
</div>
```

---

## 8. §7 Accessibility

Bazuje na: `responsive-web-standards-2026 §4` (WCAG 2.2 AA checklist).

**Reguły:**
- `<label for="id">` lub `aria-label` przy każdym input (bez wyjątku)
- ARIA live region dla wyników: `<div role="status" aria-live="polite">` — screen reader czyta po obliczeniu
- Error announcements: `role="alert"` na error message (assertive — czyta natychmiast)
- Focus management between steps: `firstFieldRef.current?.focus` po przejściu do nowego kroku
- Keyboard-only: każda akcja osiągalna przez Tab+Enter, brak mouse-required UX
- Reduced motion: `prefers-reduced-motion` → wyłącz transitions step-to-step

```tsx
// Dobrze — ARIA live region wyników
<div role="status" aria-live="polite" aria-atomic="true" className="sr-only">
  {result && `Wynik kalkulacji: ${result.total} PLN`}
</div>

// Widoczny wynik (wizualny) — osobny element
<div className="text-3xl font-bold">{result?.total} PLN</div>
```

```tsx
// Zle — result bez live region
<div className="text-3xl font-bold">{result?.total} PLN</div>
// Screen reader nie ogłosi zmiany gdy kalkulator przelicza
```

---

## Antywzorce

1. **Brak localStorage save** — użytkownik traci dane po przypadkowym odświeżeniu; drop-off wzrasta.
2. **Yup/Joi zamiast Zod** — niespójność z resztą webapp-ów (Zod standard w factory).
3. **react-pdf w Server Component** — crash Node.js canvas; zawsze `dynamic(..., { ssr: false })`.
4. **Share-link bez kompresji** — URL >4000 znaków, niektóre serwery/przeglądarki obcinają.
5. **Lead-gate do external-crm** — leads klientów w CRM operatora = naruszenie separation of concerns + ryzyko prawne RODO.
6. **Brak focus management między krokami** — screen reader pozostaje na poprzednim kroku; WCAG FAIL 2.4.3.
7. **Touch target <44px** — WCAG 2.2 SC 2.5.5 FAIL, szczególnie bolesne na mobile B2B.
8. **Jedna globalna Zod schema** — błędy wszystkich kroków na step 1, UX złamany.

---

## Powiązania

**Requires (foundation):**
- `responsive-web-standards-2026` — breakpoints §3, WCAG 2.2 §4, touch targets §4 NOWE 2.2

**Upstream (budują kontekst):**
- `webapp-standards` — TypeScript/struktura projektu, Tailwind, Next.js baseline
- `webapp-security-hardening` — gdy lead-gate używa POST `/api/lead` (rate-limiting, secrets)

**Downstream (konsumują ten skill):**
- `calculator-builder` agent (5C E5 — future) — cite §1-§7 durante implementacji
- `web-builder` agent — cite §6 mobile + §7 a11y podczas budowania stron z formularzami
- `lead-gen-form-patterns` (future) — rozszerzenie §5 lead-gate

**Companion files (ten skill):**
- `multistep-wizard-pattern.md` — §1 + §2 szczegóły + kod
- `pdf-export-template.md` — §3 template react-pdf + server fallback
- `share-link-strategy.md` — §4 LZString + Clipboard + guard
- `lead-gate-anti-crm.md` — §5 ZAKAZ CRM + Resend sample

---

## References

1. react-pdf.org — official react-pdf docs (Document/Page/Text/View components)
2. github.com/pieroxy/lz-string — LZString compress/decompress API
3. w3.org/TR/WCAG22/#target-size-minimum — SC 2.5.5 Target Size 44×44px (NOWE WCAG 2.2)
4. w3.org/TR/WCAG22/#focus-order — SC 2.4.3 Focus Order (focus management between steps)
5. resend.com/docs — Resend API (preferred email provider 2026)
6. zod.dev — Zod schema validation API
