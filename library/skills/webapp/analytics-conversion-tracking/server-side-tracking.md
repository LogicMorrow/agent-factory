# Server-Side Tracking — Next.js Route Handler Proxy
# analytics-conversion-tracking skill v1.0.0
# Omija Adblockers: browser → /api/track → GA4 Measurement Protocol

## Dlaczego server-side tracking

~30-40% użytkowników w PL blokuje analytics przez Adblockers (uBlock Origin, Brave default).
Klasyczny gtag.js jest blokowany po stronie klienta — żądania do `googletagmanager.com` filtrowane.

Rozwiązanie: proxy przez własną domenę.
```
Browser → POST /api/track (twoja-domena.pl) → GA4 Measurement Protocol (server-to-server)
```
Własna domena NIE jest na blocklist Adblockerów → dane trafiają do GA4.

---

## Implementacja: /api/track Route Handler

```ts
// app/api/track/route.ts
import { NextRequest, NextResponse } from 'next/server';

// Typy eventów (z event-taxonomy.yaml)
type AnalyticsEvent = {
  name: 'pageview' | 'scroll_50' | 'scroll_100' | 'cta_click' |
        'calc_step_completed' | 'calc_result_shown' | 'lead_form_submitted';
  params?: Record<string, string | number | boolean>;
};

const GA4_MEASUREMENT_ID = process.env.NEXT_PUBLIC_GA4_PROPERTY_ID;
const GA4_API_SECRET = process.env.GA4_MEASUREMENT_PROTOCOL_SECRET; // Server-only, NIE NEXT_PUBLIC_

export async function POST(req: NextRequest) {
  try {
    const body = await req.json as { client_id: string; event: AnalyticsEvent };

    if (!GA4_MEASUREMENT_ID || !GA4_API_SECRET) {
      // Degraded mode — brak konfiguracji GA4 (np. Plausible-only setup)
      return NextResponse.json({ ok: true, mode: 'degraded' });
    }

    if (!body.client_id || !body.event?.name) {
      return NextResponse.json({ error: 'Missing client_id or event.name' }, { status: 400 });
    }

    // Forward do GA4 Measurement Protocol
    const gaResponse = await fetch(
      `https://www.google-analytics.com/mp/collect?measurement_id=${GA4_MEASUREMENT_ID}&api_secret=${GA4_API_SECRET}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          client_id: body.client_id,
          events: [
            {
              name: body.event.name,
              params: {
                ...body.event.params,
                // Server-side: IP anonimization automatyczna (Measurement Protocol)
                // NIE wysyłaj IP użytkownika — Next.js handler NIE przekazuje IP do GA4
              },
            },
          ],
        }),
      }
    );

    if (!gaResponse.ok) {
      // Nie blokuj użytkownika gdy GA4 nie odpowiada — log i 200
      console.error('[/api/track] GA4 Measurement Protocol error:', gaResponse.status);
    }

    return NextResponse.json({ ok: true });
  } catch (err) {
    console.error('[/api/track] Error:', err);
    return NextResponse.json({ ok: true }); // Fail silently — analytics errors NIE blokują UX
  }
}
```

**Ważne:** `GA4_MEASUREMENT_PROTOCOL_SECRET` — server-only secret (bez `NEXT_PUBLIC_` prefiksu).
Nie eksponuj w bundle klienta. Szczegóły → `library/skills/universal/secrets-handling/`.

---

## Env vars wymagane

```env
# .env.local — server-side only (NIE commituj, NIE NEXT_PUBLIC_)
GA4_MEASUREMENT_PROTOCOL_SECRET=your_api_secret_from_ga4_admin

# Już zadeklarowany (client-side, bezpieczny do eksponowania)
NEXT_PUBLIC_GA4_PROPERTY_ID=G-XXXXXXXXXX
```

Gdzie znaleźć `GA4_MEASUREMENT_PROTOCOL_SECRET`:
GA4 Admin → Data Streams → Twój stream → Measurement Protocol → Create a secret.

---

## Client-side sender (browser → /api/track)

```ts
// lib/analytics/server-track.ts
'use client';

// Pobierz lub utwórz GA4 client_id (persisted w localStorage)
function getClientId: string {
  const stored = localStorage.getItem('_ga_client_id');
  if (stored) return stored;
  const newId = `${Date.now}.${Math.random.toString(36).slice(2)}`;
  localStorage.setItem('_ga_client_id', newId);
  return newId;
}

type EventName = 'pageview' | 'scroll_50' | 'scroll_100' | 'cta_click' |
                 'calc_step_completed' | 'calc_result_shown' | 'lead_form_submitted';

export async function trackServerSide(
  eventName: EventName,
  params?: Record<string, string | number | boolean>
): Promise<void> {
  try {
    await fetch('/api/track', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        client_id: getClientId,
        event: { name: eventName, params },
      }),
      // keepalive: true — ważne dla eventów przy nawigacji away
      keepalive: true,
    });
  } catch {
    // Analytics failures NIE przerywają flow aplikacji (silent fail)
  }
}
```

Użycie zamiast bezpośredniego gtag:
```ts
// Zamiast: gtag('event', 'cta_click', { label: 'Oblicz' })
await trackServerSide('cta_click', { label: 'Oblicz' });
// ^ Przechodzi przez /api/track → GA4, omija Adblockers
```

---

## Hybrid setup: Plausible (client) + GA4 (server-side)

Rekomendowany default dla projektów operatora (decision tree z SKILL.md):

```ts
// lib/analytics/events.ts — unified tracker
import { trackEvent as plausibleTrack } from './plausible';
import { trackServerSide } from './server-track';

type EventName = 'pageview' | 'scroll_50' | 'scroll_100' | 'cta_click' |
                 'calc_step_completed' | 'calc_result_shown' | 'lead_form_submitted';

export const analytics = {
  track: async (name: EventName, props?: Record<string, string>) => {
    // Plausible (nie wymaga cookie consent, privacy-first)
    plausibleTrack(name, props);

    // GA4 server-side (omija Adblockers, wymaga cookie consent)
    // Sprawdź consent przed wysłaniem do GA4
    const consent = localStorage.getItem('cookie-consent');
    if (consent === 'accepted') {
      await trackServerSide(name, props);
    }
  },

  // Convenience wrappers (z event-taxonomy.yaml)
  pageview: (path: string) => analytics.track('pageview', { page_path: path }),
  cta_click: (label: string, location?: string) =>
    analytics.track('cta_click', { label, ...(location ? { location } : {}) }),
  calc_step_completed: (step: string, calc_slug?: string) =>
    analytics.track('calc_step_completed', { step, ...(calc_slug ? { calc_slug } : {}) }),
  calc_result_shown: (calc_slug: string, result_range?: string) =>
    analytics.track('calc_result_shown', { calc_slug, ...(result_range ? { result_range } : {}) }),
  lead_form_submitted: (calc_slug: string, lead_source?: string) =>
    analytics.track('lead_form_submitted', { calc_slug, ...(lead_source ? { lead_source } : {}) }),
  scroll_50:  => analytics.track('scroll_50'),
  scroll_100:  => analytics.track('scroll_100'),
};
```

---

## Plausible i PostHog — server-side endpoints

Plausible i PostHog mają własne server-side API (nie Measurement Protocol):

**Plausible Event API (server-side):**
```ts
await fetch('https://plausible.io/api/event', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'User-Agent': req.headers.get('user-agent') ?? 'server',
    'X-Forwarded-For': '0.0.0.0', // NIE przekazuj prawdziwego IP — GDPR
  },
  body: JSON.stringify({
    domain: process.env.NEXT_PUBLIC_PLAUSIBLE_DOMAIN,
    name: eventName,
    url: pageUrl,
  }),
});
```

**PostHog Capture API (server-side):**
```ts
import { PostHog } from 'posthog-node';
const posthog = new PostHog(process.env.POSTHOG_API_KEY!, {
  host: 'https://eu.posthog.com',
});
posthog.capture({ distinctId: clientId, event: eventName, properties: params });
```

Cross-reference pełna konfiguracja Plausible/PostHog → SKILL.md §3.4 i §3.5.

---

## Antywzorce

- **ZAKAZ:** Przekazywanie prawdziwego IP użytkownika w Measurement Protocol (GDPR — minimalizacja)
- **ZAKAZ:** Eksponowanie `GA4_MEASUREMENT_PROTOCOL_SECRET` jako `NEXT_PUBLIC_*` (security)
- **ZAKAZ:** Forward eventów do external-crm przez `/api/track` (deal-breaker)
- **ZAKAZ:** Brak `keepalive: true` przy nawigacji — event ginie przy page unload
- **ZAKAZ:** Blokowanie UX przez rzucanie wyjątku gdy GA4 niedostępny — zawsze silent fail
