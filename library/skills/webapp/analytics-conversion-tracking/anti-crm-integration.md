# DEAL-BREAKER: NEVER sync with external-crm
# analytics-conversion-tracking skill v1.0.0
# Quality-checker: odrzuca skill jeśli ta fraza nie istnieje w pierwszych 20 liniach

**NEVER sync with external-crm.**
Analytics jest read-only observer. Zdarzenia GA4/Plausible/PostHog NIE są forwardowane
do external-crm.com/api/* ani żadnego endpointu CRM operatora.

Wzorzec zakazu pochodzi z `webapp-calculator-patterns/lead-gate-anti-crm.md` (5C E2).
Ten plik rozszerza zakaz na warstwę analytics (eventy, webhooks, Measurement Protocol forwarding).

---

## Dlaczego zakaz jest bezwzględny

1. **Separation of concerns** — analytics to narzędzie obserwacji zachowań. CRM to narzędzie
   zarządzania relacjami. Twardy coupling niszczy reużywalność całej biblioteki skilli.
2. **Ryzyko prawne RODO** — forwarding danych analytics (w tym quasi-PII jak IP, fingerprint)
   do CRM bez wyraźnej podstawy prawnej = naruszenie art. 6 RODO (brak zgody / brak FPL).
3. **Leady należą do klienta** — projekty budowane dla klientów nie mogą wysyłać danych
   ich użytkowników do CRM operatora. Naruszenie trust i kontrakt.
4. **Architektura biblioteki** — skille w `library/` muszą być universalne. external-crm
   jest prywatnym systemem. Dependency na niego = nieprzenośny kod.
5. **Adblocker bypass risk** — server-side tracking (`/api/track`) omija Adblockers; gdyby
   te same eventy szły do CRM, RODO consent-gate byłby nieefektywny.

---

## Zakazane scenariusze (3+ concrete patterns)

### Scenariusz 1: Webhook GA4 → external-crm

```ts
// ZAKAZ — NIE RÓB TEGO
// app/api/ga4-webhook/route.ts
export async function POST(req: Request) {
  const body = await req.json;
  // ZAKAZ: forwarding eventów GA4 do CRM
  await fetch('https://crm.example.com/api/events', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${process.env.CRM_API_KEY}` },
    body: JSON.stringify({ event: body.event_name, user: body.client_id }),
  });
}
// ^ ZABRONIONE — webhook do CRM operatora, naruszenie RODO + deal-breaker
```

### Scenariusz 2: Server-to-server sync GA4 → CRM (Measurement Protocol)

```ts
// ZAKAZ — NIE RÓB TEGO
// lib/analytics/track.ts
export async function trackEvent(event: string, clientId: string) {
  // Measurement Protocol → GA4 (OK)
  await fetch('https://www.google-analytics.com/g/collect?...', { method: 'POST', ... });

  // ZAKAZ: ten sam event → external-crm
  await fetch('https://crm.example.com/api/track', {
    method: 'POST',
    body: JSON.stringify({ event, client_id: clientId, timestamp: Date.now }),
  });
  // ^ ZABRONIONE — dual-forwarding do CRM operatora
}
```

### Scenariusz 3: Shared cookie / fingerprint cross-domain

```ts
// ZAKAZ — NIE RÓB TEGO
// lib/analytics/identify.ts
export function syncUserIdentity(gaClientId: string) {
  // ZAKAZ: zapisywanie GA4 client_id do CRM (cross-domain fingerprint coupling)
  await fetch('https://crm.example.com/api/contacts/identify', {
    method: 'POST',
    body: JSON.stringify({ ga_client_id: gaClientId }),
  });
  // ^ ZABRONIONE — łączenie analytics identity z CRM contacts
}
```

### Scenariusz 4: Customer ID coupling (GTM trigger → CRM API)

```ts
// ZAKAZ — NIE RÓB TEGO
// W GTM Custom Tag lub dataLayer handler:
window.dataLayer.push({
  event: 'lead_form_submitted',
  customer_id: '12345',   // ZAKAZ — ID z CRM operatora w analytics events
  crm_contact_url: 'https://crm.example.com/contacts/12345',
});
// ^ ZABRONIONE — coupling CRM identifiers z analytics events

// Następnie GTM Custom Tag który wywołuje CRM API:
// fetch('https://crm.example.com/api/customers/' + {{DL - customer_id}})
// ^ ZABRONIONE — GTM jako pośrednik do CRM operatora
```

---

## Dozwolone alternatywy (GDPR-friendly)

### Prawidłowy wzorzec: Resend email forward (brak CRM)

```ts
// app/api/lead/route.ts — PRAWIDŁOWY WZORZEC
import { Resend } from 'resend';
import { NextRequest, NextResponse } from 'next/server';

const resend = new Resend(process.env.RESEND_API_KEY);

export async function POST(req: NextRequest) {
  const { email, name, calcSlug, calcResult } = await req.json;

  // Wyślij do klienta (właściciela projektu) — NIE do CRM operatora
  await resend.emails.send({
    from: `Kalkulator <noreply@${process.env.PROJECT_DOMAIN}>`,
    to: [process.env.CLIENT_NOTIFICATION_EMAIL as string], // email klienta, NIE operatora
    subject: `Nowe zapytanie: ${calcSlug}`,
    html: `<p>Od: ${name} &lt;${email}&gt;</p><p>Wynik: ${calcResult}</p>`,
  });

  // Analytics event — BRAK FORWARDINGU DO CRM
  // Tylko po stronie klienta lub przez /api/track → GA4 Measurement Protocol
  return NextResponse.json({ success: true });
}
```

### Dozwolone: Lokalny Postgres lead capture (zero external CRM)

```ts
// app/api/lead/route.ts — lokalny storage GDPR-friendly
import { prisma } from '@/lib/prisma';

export async function POST(req: NextRequest) {
  const { email, name, calcSlug } = await req.json;

  // Zapis do lokalnej bazy projektu — nie do external-crm
  await prisma.lead.create({
    data: {
      email,           // szyfrowanie BCRYPT lub at-rest encryption opcjonalne
      name,
      source: calcSlug,
      createdAt: new Date,
    },
  });

  return NextResponse.json({ success: true });
}
// Lead jest lokalny dla projektu. BRAK wysyłki do external-crm.com.
```

---

## Checklist — weryfikacja przed deployem

- [ ] Brak jakiegokolwiek `crm.example.com` w kodzie projektu
- [ ] Brak zmiennych środowiskowych `CRM_*` wskazujących na CRM operatora
- [ ] Brak importu `@your-org/*` pakietów (prywatne paczki operatora)
- [ ] `RESEND_API_KEY` lub `CLIENT_NOTIFICATION_EMAIL` należą do klienta (nie operatora)
- [ ] Event params w `event-taxonomy.yaml` nie zawierają `crm_lead_id`, `customer_id` (CRM)
- [ ] `/api/track` proxy (server-side tracking) nie ma dodatkowego `fetch` do external-crm
- [ ] GTM Custom Tags nie zawierają fetchów do `crm.example.com`

---

## Wzorzec zakazu — reużycie w 

Ten plik może być linkowany (lub wzorzec kopiowany) do przyszłych skilli -5H
które dotykają danych użytkowników:

- `lead-tracking` (5D E2) — powinien importować ten wzorzec zakazu
- `conversion-funnel` (5D E3) — jeśli powstanie, MUSI mieć analogiczny anti-crm-integration.md
- `email-marketing-integration` (future) — zakaz dot. CRM operatora jako destination

Quality-checker weryfikuje frazę "NEVER sync with external-crm" w pierwszych 20 liniach.
Jeśli fraza nieobecna → skill odrzucony (HARD FAIL).
