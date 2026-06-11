# ZAKAZ external-crm — Lead Gate Anti-CRM

**DEAL-BREAKER (kontrakt master ):**
Kalkulatory budowane dla klientów MUSZĄ używać email forward jako default.
Leads klientów NIE trafiają do external-crm ani żadnego CRM operatora.

---

## Dlaczego ZAKAZ jest bezwzględny

1. **Separation of concerns** — kalkulator to narzędzie klienta. Jego użytkownicy i leady należą do klienta, nie do operatora.
2. **Ryzyko prawne RODO** — przetwarzanie danych kontaktowych klientów operatora bez ich zgody i bez podstawy prawnej = naruszenie RODO art. 6.
3. **Reputacyjne** — jeśli klient odkryje, że dane jego klientów trafiają do zewnętrznego CRM, utrata zaufania i kontrakt.
4. **Architektoniczne** — skille w `library/` mają być uniwersalne. external-crm jest prywatnym narzędziem — twardy coupling niszczy reużywalność całej biblioteki.

---

## Dozwolone Providers (hierarchia)

| Provider | Status 2026 | Kiedy wybrać |
|---|---|---|
| **Resend** | PREFERRED | Nowe projekty 2026 — prosta API, webhooks, React Email templates, dobra deliverability |
| **SendGrid** | Legacy OK | Istniejące projekty z SendGrid setup — te same możliwości |
| **Nodemailer + SMTP** | Self-hosted | Klient wymaga zero third-party, ma własny SMTP (np. Mailgun, Postmark) |
| Klient's own CRM webhook | Dozwolony | Jeśli klient **jawnie** zleci integrację z WŁASNYM CRM (nie CRM operatora) |

---

## Anti-patterns — Explicit ZAKAZ

```tsx
// ZAKAZ #1 — hardcoded external-crm endpoint
await axios.post('https://crm.example.com/api/leads', { email, name });
// ^ ZABRONIONE — endpoint CRM operatora

// ZAKAZ #2 — webhook do external-crm
await fetch('https://crm.example.com/api/webhook/calc-leads', {
  method: 'POST', body: JSON.stringify({ email })
});
// ^ ZABRONIONE — nawet przez webhook

// ZAKAZ #3 — axios POST do jakiegokolwiek CRM operatora
import { CRM_API_KEY, CRM_BASE_URL } from '@/config/crm'; // CRM operatora
await axios.post(`${CRM_BASE_URL}/contacts`, { email }, { headers: { 'X-API-Key': CRM_API_KEY } });
// ^ ZABRONIONE

// ZAKAZ #4 — import utils z CRM projektu operatora
import { addLeadToCRM } from '@your-org/crm-utils';
// ^ ZABRONIONE — dependency na prywatny pakiet operatora
```

---

## Sample: Next.js Route Handler z Resend (Correct Pattern)

```tsx
// app/api/lead/route.ts
import { Resend } from 'resend';
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';

const resend = new Resend(process.env.RESEND_API_KEY);

const leadSchema = z.object({
  email: z.string.email("Niepoprawny adres email"),
  name: z.string.min(2, "Podaj imię").max(100),
  calcSlug: z.string,
  calcState: z.record(z.unknown), // compressed state lub parsed
});

export async function POST(req: NextRequest) {
  const body = await req.json;
  const parsed = leadSchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json(
      { error: 'Validation failed', details: parsed.error.flatten },
      { status: 400 }
    );
  }

  const { email, name, calcSlug, calcState } = parsed.data;

  // Wyślij email do klienta (właściciela kalkulatora) — NIE do CRM operatora
  await resend.emails.send({
    from: `Kalkulator <kalkulator@klient-domena.pl>`,     // domena klienta
    to: [process.env.CLIENT_NOTIFICATION_EMAIL as string], // email klienta (właściciela)
    subject: `Nowe zapytanie z kalkulatora: ${calcSlug}`,
    html: buildLeadEmail({ name, email, calcSlug, calcState }),
  });

  // Opcjonalnie: wyślij potwierdzenie do użytkownika (zainteresowanego)
  await resend.emails.send({
    from: `Kalkulator <kalkulator@klient-domena.pl>`,
    to: [email],
    subject: 'Twój wynik kalkulacji — potwierdzenie',
    html: buildConfirmationEmail({ name, calcSlug, calcState }),
  });

  return NextResponse.json({ success: true });
}

function buildLeadEmail({ name, email, calcSlug, calcState }: {
  name: string; email: string; calcSlug: string; calcState: Record<string, unknown>
}): string {
  return `
    <h2>Nowe zapytanie z kalkulatora: ${calcSlug}</h2>
    <p><strong>Imię:</strong> ${name}</p>
    <p><strong>Email:</strong> ${email}</p>
    <p><strong>Data:</strong> ${new Date.toLocaleString('pl-PL')}</p>
    <h3>Dane z kalkulatora:</h3>
    <pre>${JSON.stringify(calcState, null, 2)}</pre>
    <hr>
    <p><small>Email wygenerowany automatycznie przez kalkulator. ZERO danych wysłanych do zewnętrznych CRM.</small></p>
  `;
}
```

## .env.example (dla projektu klienta)

```env
# Resend API — NIE używać kluczy operatora, klient zakłada własne konto resend.com
RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxx

# Email klienta — tam trafiają leads z kalkulatora
CLIENT_NOTIFICATION_EMAIL=kontakt@firma-klienta.pl
```

---

## Checklist przed deployem lead-gate

- [ ] `RESEND_API_KEY` należy do konta klienta (nie operatora)
- [ ] `CLIENT_NOTIFICATION_EMAIL` wskazuje na email klienta
- [ ] Brak jakiegokolwiek endpointu `crm.example.com` w kodzie
- [ ] Brak importu `@your-org/*` pakietów w projekcie
- [ ] `from:` email używa domeny klienta (nie example.com)
- [ ] RODO disclaimer w formularzu: "Dane zostaną użyte wyłącznie w celu odpowiedzi na zapytanie"
- [ ] Rate-limiting na `/api/lead` (np. Upstash Ratelimit lub middleware Hono)

---

## Alternatywa: Klient's Own CRM (Dozwolone)

Jeśli klient jawnie zleca integrację z WŁASNYM CRM:

```tsx
// OK — klient's own CRM (np. HubSpot, Pipedrive klienta)
await fetch(`${process.env.CLIENT_CRM_WEBHOOK_URL}`, {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${process.env.CLIENT_CRM_API_KEY}` },
  body: JSON.stringify({ email, name, source: calcSlug }),
});
// ^ DOZWOLONE jeśli CLIENT_CRM_WEBHOOK_URL to CRM klienta
// ^ NIE może być to CRM operatora (crm.example.com)
```

Klucze API: zawsze w zmiennych środowiskowych klienta (`CLIENT_CRM_*`), nigdy hardcoded.
