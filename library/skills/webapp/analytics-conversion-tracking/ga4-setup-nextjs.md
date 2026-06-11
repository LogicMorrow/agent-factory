# GA4 Setup — Next.js 14+ App Router
# analytics-conversion-tracking skill v1.0.0
# Zakres: gtag.js inline, next/script, env vars, IP anonimization PL, cookie consent

## Wymagania środowiskowe

```env
# .env.local (NIE commitować do git)
NEXT_PUBLIC_GA4_PROPERTY_ID=G-XXXXXXXXXX

# Opcjonalnie jeśli GTM zamiast gtag.js inline
NEXT_PUBLIC_GTM_CONTAINER_ID=GTM-XXXXXXX

# Opcjonalnie dla Plausible
NEXT_PUBLIC_PLAUSIBLE_DOMAIN=twoja-domena.pl
```

`.env.example` (commitowany, bez wartości):
```env
NEXT_PUBLIC_GA4_PROPERTY_ID=
NEXT_PUBLIC_GTM_CONTAINER_ID=
NEXT_PUBLIC_PLAUSIBLE_DOMAIN=
```

---

## Implementacja: gtag.js w app/layout.tsx

### Krok 1: Cookie Consent Hook

```tsx
// hooks/useCookieConsent.ts
'use client';
import { useState, useEffect } from 'react';

export type ConsentStatus = 'unknown' | 'accepted' | 'rejected';

export function useCookieConsent {
  const [consent, setConsent] = useState<ConsentStatus>('unknown');

  useEffect( => {
    const stored = localStorage.getItem('cookie-consent') as ConsentStatus | null;
    if (stored) setConsent(stored);
  }, []);

  const accept =  => {
    setConsent('accepted');
    localStorage.setItem('cookie-consent', 'accepted');
  };

  const reject =  => {
    setConsent('rejected');
    localStorage.setItem('cookie-consent', 'rejected');
  };

  return { consent, accept, reject };
}
```

### Krok 2: GA4 Script Component (tylko po consent)

```tsx
// components/analytics/GA4Script.tsx
'use client';
import Script from 'next/script';
import { useCookieConsent } from '@/hooks/useCookieConsent';

export function GA4Script {
  const { consent } = useCookieConsent;
  const GA_ID = process.env.NEXT_PUBLIC_GA4_PROPERTY_ID;

  // NIE ładuj bez GA_ID lub bez zgody użytkownika
  if (!GA_ID || consent !== 'accepted') return null;

  return (
    <>
      {/* strategy="afterInteractive" — NIE blokuje renderowania */}
      <Script
        src={`https://www.googletagmanager.com/gtag/js?id=${GA_ID}`}
        strategy="afterInteractive"
      />
      <Script id="ga4-init" strategy="afterInteractive">
        {`
          window.dataLayer = window.dataLayer || [];
          function gtag{dataLayer.push(arguments);}
          gtag('js', new Date);
          gtag('config', '${GA_ID}', {
            anonymize_ip: true,
            cookie_flags: 'SameSite=None;Secure',
            send_page_view: false
          });
        `}
      </Script>
    </>
  );
}
```

**Parametr `anonymize_ip: true`** — OBOWIĄZKOWY dla projektów PL. Anonimizuje ostatni oktet IPv4
(np. 192.168.1.123 → 192.168.1.0). Wymóg RODO art. 5 ust. 1 lit. e (minimalizacja danych).

**`send_page_view: false`** — wyłącza automatyczny pageview GA4 (zarządzamy ręcznie przez event taxonomy).

### Krok 3: Cookie Consent Banner

```tsx
// components/analytics/CookieBanner.tsx
'use client';
import { useCookieConsent } from '@/hooks/useCookieConsent';

export function CookieBanner {
  const { consent, accept, reject } = useCookieConsent;

  if (consent !== 'unknown') return null; // Banner znika po decyzji

  return (
    <div
      role="dialog"
      aria-label="Zgoda na pliki cookie"
      aria-live="polite"
      className="fixed bottom-0 left-0 right-0 z-50 p-4 bg-white dark:bg-slate-800 shadow-lg border-t"
    >
      <div className="max-w-4xl mx-auto flex flex-col sm:flex-row items-start sm:items-center gap-4">
        <p className="text-sm text-slate-700 dark:text-slate-200 flex-1">
          Używamy plików cookie do analizy ruchu (Google Analytics).
          Twoje dane są anonimizowane (IP anonymization).{' '}
          <a href="/polityka-prywatnosci" className="underline">Polityka prywatności</a>
        </p>
        <div className="flex gap-2 shrink-0">
          <button
            onClick={reject}
            className="px-4 py-2 text-sm border rounded hover:bg-slate-100 dark:hover:bg-slate-700"
          >
            Odrzuć
          </button>
          <button
            onClick={accept}
            className="px-4 py-2 text-sm bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            Akceptuję
          </button>
        </div>
      </div>
    </div>
  );
}
```

### Krok 4: Integracja w app/layout.tsx

```tsx
// app/layout.tsx
import { GA4Script } from '@/components/analytics/GA4Script';
import { CookieBanner } from '@/components/analytics/CookieBanner';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pl">
      <body>
        {children}
        <GA4Script />
        <CookieBanner />
      </body>
    </html>
  );
}
```

---

## GTM zamiast gtag.js (gdy ≥3 third-party scripts)

```tsx
// components/analytics/GTMScript.tsx
'use client';
import Script from 'next/script';
import { useCookieConsent } from '@/hooks/useCookieConsent';

export function GTMScript {
  const { consent } = useCookieConsent;
  const GTM_ID = process.env.NEXT_PUBLIC_GTM_CONTAINER_ID;

  if (!GTM_ID || consent !== 'accepted') return null;

  return (
    <>
      <Script id="gtm-init" strategy="afterInteractive">
        {`(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
          new Date.getTime,event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
          j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
          'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
          })(window,document,'script','dataLayer','${GTM_ID}');`}
      </Script>
    </>
  );
}
```

Wyślij event do dataLayer (GTM):
```ts
// lib/analytics/gtm.ts
export function pushDataLayer(event: Record<string, unknown>) {
  if (typeof window !== 'undefined') {
    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push(event);
  }
}

// Użycie:
pushDataLayer({ event: 'cta_click', cta_label: 'Oblicz wycenę' });
```

---

## Weryfikacja instalacji

1. Chrome DevTools → Network → filter `collect` lub `g/collect` → sprawdź payload
2. GA4 DebugView (Admin → DebugView): dodaj `?_ga_debug=1` do URL
3. GTM Preview Mode: `gtm.google.com/source?id=GTM-XXXXX`
4. `anonymize_ip` w payload: szukaj `aip=1` w query params (starszy API) lub brak pełnego IP w GA4 DebugView

---

## Antywzorce

- **ZAKAZ:** `<script>` synchroniczny (bez `strategy="afterInteractive"`) → blokuje parser
- **ZAKAZ:** Hardcoded `G-XXXXXXXX` w kodzie → ekspozycja w git, brak env-switch
- **ZAKAZ:** Ładowanie GA4 bez cookie consent → naruszenie ePrivacy Directive / PECR
- **ZAKAZ:** Brak `anonymize_ip: true` → RODO violation w PL
- **ZAKAZ:** GTM do 1-2 skryptów → overkill (próg ≥3 third-party scripts)
