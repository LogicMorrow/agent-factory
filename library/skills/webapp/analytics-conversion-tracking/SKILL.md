---
name: analytics-conversion-tracking
description: Analytics tracking webapp — GA4 setup (gtag.js inline + next/script async + env vars + IP anonimization PL + cookie consent), GTM tagged ≥3 third-party scripts, GSC sitemap/URL inspection, Plausible/PostHog privacy-first GDPR-friendly, server-side tracking Next.js route handlers Measurement Protocol omija Adblockers, event taxonomy 7 events (pageview, scroll_50/100, cta_click, calc_step_completed, calc_result_shown, lead_form_submitted). **DEAL-BREAKER: NEVER sync with external-crm** (anti-crm-integration.md required).
version: 1.0.0
compatible_with: [webapp]
tags: [analytics, ga4, gtm, gsc, plausible, posthog, tracking, webapp]
requires: [responsive-web-standards-2026]
token_cost: medium
distribution: library/skills/webapp/
last_updated: 2026-05-11
---

# analytics-conversion-tracking

Skill analytics dla webapp Next.js 14+ — spójny standard trackingu konwersji zamiast ad-hoc decyzji per projekt.
Eliminuje 4-8h research per projekt. Pokrywa 6 obszarów: GA4, GTM, GSC, Plausible/PostHog, server-side tracking, event taxonomy.

**DEAL-BREAKER:** Analytics = read-only observer. Zdarzenia NIE są forwardowane do żadnego CRM.
Plik `anti-crm-integration.md` jest wymagany. Quality-checker odrzuca skill jeśli nie zawiera frazy
"NEVER sync with external-crm" w pierwszych 20 liniach.

Pliki towarzyszące:
- `event-taxonomy.yaml` — 7 standardowych eventów z metadanymi
- `ga4-setup-nextjs.md` — gtag.js + next/script + env vars + cookie consent
- `anti-crm-integration.md` — DEAL-BREAKER zakaz syncu z external-crm (4 scenariusze)
- `server-side-tracking.md` — Next.js route handler proxy → GA4 Measurement Protocol (omija Adblockers)

---

## 1. Kiedy uruchomić

Uruchom gdy projektujesz analytics dla webapp. Sygnały:

- "Jak dodać GA4 do Next.js?"
- "GA4 vs Plausible — co wybrać?"
- "Jak trackować konwersje kalkulatora?"
- "Jak omijać Adblockers w analytics?"
- Task w planie: "dodaj analytics", "setup tracking konwersji"

NIE uruchamiaj gdy:
- Lead scoring, attribution multi-touch, marketing automation → osobny skill (5D E2+)
- Reverse proxy Nginx/Cloudflare do omijania Adblockers → infra-level, poza zakresem
- Integracja analytics z CRM → ZAKAZ (patrz `anti-crm-integration.md`)
- Konfiguracja GSC Search Console domain verification → ręcznie w panelu GSC

---

## 2. Decision Tree — Wybór Stacku Analytics

```
START: Jaki jest cel projektu?
│
├─► PRYWATNOŚĆ priorytet / Klient RODO-sensitive / brak cookie banner
│   └─► Plausible (privacy-first, GDPR-compliant bez cookie)
│       Kiedy: landing page prosty, portfolio, site klienta (EU public sector)
│
├─► ZŁOŻONE wymagania: e-commerce / SaaS / funnel wielostopniowy
│   └─► GA4 + GTM
│       Kiedy: commerce events, A/B testing, advertising pixels (≥3 third-party scripts)
│       → gdy ≥3 third-party scripts: użyj GTM jako container
│       → gdy <3 scripts: gtag.js inline (GA4 only, bez GTM)
│
└─► HYBRID (rekomendowany default dla projektów operatora):
    Plausible GŁÓWNY (privacy-first, zero cookie) +
    GA4 server-side UZUPEŁNIAJĄCY (Measurement Protocol, omija Adblockers)
    Kiedy: kalkulatory, lendingi, SaaS klienckie gdzie balansujemy privacy vs depth
```

---

## 3. Kluczowe zasady

### 3.1 GA4 Setup (gtag.js)

Pełny snippet → `ga4-setup-nextjs.md`.

Zasady obowiązkowe:
- `strategy="afterInteractive"` — NIE blokuje renderowania (NIGDY synchroniczny `<script>`)
- Property ID z `process.env.NEXT_PUBLIC_GA4_PROPERTY_ID` (NIE hardcoded)
- `anonymize_ip: true` — OBOWIĄZKOWE dla PL/GDPR (art. 5 RODO minimalizacja danych)
- Cookie consent: NIE ładuj gtag.js dopóki user nie zaakceptuje

### 3.2 GTM — kiedy i jak

GTM zamiast gtag.js gdy projekt ma ≥3 third-party scripts (GA4 + Facebook Pixel + HotJar = przykład).

Zasady:
- Jeden GTM container = jeden projekt (`GTM-XXXXXXX` jako env var)
- GTM ładuje się przez `next/script strategy="afterInteractive"`
- Wszystkie eventy przez `window.dataLayer.push({...})` → GTM je odbiera
- Partytown ALTERNATYWA: `strategy="worker"` (z `responsive-web-standards-2026 §10`)

### 3.3 Google Search Console

1. Weryfikacja domeny: HTML tag lub DNS TXT (ręcznie w panelu)
2. Sitemap: submit `https://<domena>/sitemap.xml` w GSC → Settings → Sitemaps
3. URL inspection: po deploymencie sprawdź kluczowe strony (`/`, `/kalkulator`, `/kontakt`)

Sitemap Next.js 14+ App Router:
```ts
// app/sitemap.ts
import { MetadataRoute } from 'next';
export default function sitemap: MetadataRoute.Sitemap {
  return [
    { url: 'https://example.com', lastModified: new Date, changeFrequency: 'monthly', priority: 1 },
    { url: 'https://example.com/kalkulator', lastModified: new Date, changeFrequency: 'weekly', priority: 0.9 },
  ];
}
```

### 3.4 Plausible — privacy-first

```tsx
// app/layout.tsx — Plausible (BRAK cookie, BRAK banner GDPR)
import Script from 'next/script';
<Script
  defer
  data-domain={process.env.NEXT_PUBLIC_PLAUSIBLE_DOMAIN}
  src="https://plausible.io/js/script.js"
  strategy="afterInteractive"
/>
```

Custom events Plausible:
```ts
// lib/analytics/plausible.ts
declare global { interface Window { plausible?: (event: string, opts?: { props: Record<string, string> }) => void } }

export function trackEvent(name: string, props?: Record<string, string>) {
  window.plausible?.(name, props ? { props } : undefined);
}
```

GDPR: Plausible nie używa cookies → BRAK wymagania cookie banner wg PECR/dyrektywa ePrivacy.

### 3.5 PostHog — product analytics

PostHog różni się od Plausible: dodaje session replay, feature flags, A/B tests.

```tsx
// lib/analytics/posthog.ts
import posthog from 'posthog-js';
export function initPostHog {
  if (typeof window === 'undefined') return;
  posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY!, {
    api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST ?? 'https://eu.posthog.com', // EU region GDPR
    person_profiles: 'identified_only',
    capture_pageview: false,
  });
}
```

PostHog cloud EU region (`eu.posthog.com`) → dane w Europie → GDPR-compliant.
Session replay: maskuj pola formularzy (`data-ph-capture-attribute-*="false"`).

### 3.6 Event Taxonomy

Pełna definicja 7 eventów → `event-taxonomy.yaml`.

Zasady nazewnictwa (GA4 convention):
- snake_case ZAWSZE (NIE camelCase: `ctaClick` ZAKAZ)
- Maksymalnie 40 znaków per event name

```ts
// lib/analytics/events.ts — unified tracker
import { trackEvent as plausibleTrack } from './plausible';
export const analytics = {
  pageview:  => { /* automatyczny w Plausible */ },
  cta_click: (label: string) => plausibleTrack('cta_click', { label }),
  calc_step_completed: (step: string) => plausibleTrack('calc_step_completed', { step }),
  calc_result_shown: (range: string) => plausibleTrack('calc_result_shown', { range }),
  lead_form_submitted: (calc_slug: string) => plausibleTrack('lead_form_submitted', { calc_slug }),
  scroll_50:  => plausibleTrack('scroll_50'),
  scroll_100:  => plausibleTrack('scroll_100'),
};
```

### 3.7 Server-Side Tracking

Pełny pattern → `server-side-tracking.md`.

Dlaczego: ~30-40% ruchu blokuje GA4 przez Adblockers (uBlock Origin, Brave).
Rozwiązanie: browser wysyła event do `/api/track` (własna domena) → handler forwarduje do GA4 Measurement Protocol.

---

## 4. Przykłady — dobrze vs źle

### Przykład 1: Ładowanie GA4

**DOBRZE:**
```tsx
// app/layout.tsx
const GA_ID = process.env.NEXT_PUBLIC_GA4_PROPERTY_ID;
{GA_ID && cookieConsent && (
  <Script src={`https://www.googletagmanager.com/gtag/js?id=${GA_ID}`} strategy="afterInteractive" />
)}
{GA_ID && cookieConsent && (
  <Script id="ga4-init" strategy="afterInteractive">
    {`window.dataLayer=window.dataLayer||[];function gtag{dataLayer.push(arguments);}
      gtag('js',new Date);gtag('config','${GA_ID}',{anonymize_ip:true});`}
  </Script>
)}
```

**ŹLE:**
```tsx
// ZAKAZ: synchroniczny script (blokuje render → LCP/INP degradacja)
<script src="https://www.googletagmanager.com/gtag/js?id=G-XXXX"></script>
// ZAKAZ: hardcoded Property ID
gtag('config', 'G-ABCDEFGHIJ');
// ZAKAZ: brak anonymize_ip w PL (GDPR violation)
gtag('config', process.env.NEXT_PUBLIC_GA4_PROPERTY_ID); // ^ brakuje {anonymize_ip:true}
```

### Przykład 2: Event tracking — krok kalkulatora

**DOBRZE:**
```tsx
analytics.calc_step_completed('krok_2_typ_dachu');
// snake_case, descriptive, brak PII
```

**ŹLE:**
```tsx
// ZAKAZ: camelCase (GA4 convention violation)
gtag('event', 'calcStepCompleted', { stepNumber: 2 });
// ZAKAZ: PII w parametrach (GDPR naruszenie)
gtag('event', 'lead_form_submitted', { email: userEmail, phone: userPhone });
// ZAKAZ: forwarding do CRM (deal-breaker)
await fetch('https://crm.example.com/api/events', { method: 'POST', body: JSON.stringify({event:'lead'}) });
```

### Przykład 3: Scroll tracking (responsive-aware)

**DOBRZE:**
```tsx
// hooks/useScrollTracking.ts
export function useScrollTracking {
  useEffect( => {
    const fired = { s50: false, s100: false };
    const handler =  => {
      const pct = (window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100;
      if (pct >= 50 && !fired.s50) { fired.s50 = true; analytics.scroll_50; }
      if (pct >= 95 && !fired.s100) { fired.s100 = true; analytics.scroll_100; }
    };
    window.addEventListener('scroll', handler, { passive: true });
    return  => window.removeEventListener('scroll', handler);
  }, []);
}
```

**ŹLE:**
```tsx
// ZAKAZ: brak passive:true (INP degradacja) + brak fired guard (inflate metrics)
window.addEventListener('scroll',  => {
  if (scrollY > 500) gtag('event', 'scroll_50'); // wysyła wielokrotnie!
});
```

---

## 5. Antywzorce

1. **gtag.js synchroniczny bez `strategy="afterInteractive"`** — blokuje parser HTML, niszczy LCP.
2. **Hardcoded Property ID** — bezpieczeństwo (ekspozycja w git), brak możliwości env-switch.
3. **Brak `anonymize_ip: true` w PL** — naruszenie RODO art. 5 (minimalizacja danych).
4. **camelCase event names** — GA4 wymaga snake_case, raporty się nie agregują.
5. **PII w parametrach eventów** — email, telefon, imię w event params = GDPR violation.
6. **Brak cookie consent gating** — gtag.js ładowany bez zgody = naruszenie ePrivacy.
7. **Forward analytics → external-crm** — DEAL-BREAKER (patrz `anti-crm-integration.md`).
8. **Duplikaty eventów bez fired guard** — inflate metrics, false conversion rates.
9. **Event names > 40 znaków** — GA4 odrzuca event bez warning w UI.
10. **GTM dla 1-2 skryptów** — overkill; gtag.js inline wystarczy poniżej progu 3.

---

## 6. Powiązania

**Wymaga (requires):**
- `responsive-web-standards-2026` — scroll tracking kalibrowany do viewportów (§3); Partytown (§10) jako alternatywa GTM

**Peer (wzorzec zakazu):**
- `webapp-calculator-patterns/lead-gate-anti-crm.md` (5C E2) — pierwotny ZAKAZ external-crm, ten skill rozszerza na eventy analytics

**Downstream (konsumuje ten skill):**
- `web-builder` (5C E4) — analytics placeholder component w layout.tsx
- `calculator-builder` (5C E5) — `calc_step_completed`, `calc_result_shown`, `lead_form_submitted`
- Agenty -5H wymagające conversion tracking

---

## References

1. developers.google.com/analytics/devguides/collection/ga4 — GA4 Measurement Protocol
2. plausible.io/docs — Plausible self-hosted
3. posthog.com/docs/libraries/next-js — PostHog Next.js SDK
4. nextjs.org/docs/app/api-reference/file-conventions/route — Next.js Route Handlers
5. uodo.gov.pl — UODO PL RODO art. 5 minimalizacja danych
