# Share-Link Strategy

Companion file dla `webapp-calculator-patterns §4`.

Stack: URLSearchParams + LZString (compressed base64) + Clipboard API.

---

## Instalacja

```bash
pnpm add lz-string
pnpm add -D @types/lz-string
```

---

## Encode / Decode

```tsx
import LZString from 'lz-string';

// Encode state → compressed base64 URL-safe
function encodeState(state: CalcState): string {
  return LZString.compressToEncodedURIComponent(JSON.stringify(state));
}

// Decode compressed base64 → state (z walidacją)
function decodeState(compressed: string): CalcState | null {
  try {
    const decompressed = LZString.decompressFromEncodedURIComponent(compressed);
    if (!decompressed) return null;
    const parsed = JSON.parse(decompressed);
    // Opcjonalnie: walidacja Zod schema przed restore
    const result = calcStateSchema.safeParse(parsed);
    return result.success ? result.data : null;
  } catch {
    return null;
  }
}
```

---

## URL Pattern + Guard

```tsx
// Pattern: /{calc-slug}?state={compressed}
// Przykład: /kalkulator-stoiska?state=N4Ig...

const URL_MAX_SAFE = 2000; // safe cross-browser

function buildShareUrl(state: CalcState): { url: string; truncated: boolean } {
  const compressed = encodeState(state);
  const base = `${window.location.origin}${window.location.pathname}`;
  const full = `${base}?state=${compressed}`;

  if (full.length > URL_MAX_SAFE) {
    // Fallback: URL bez state (link do kalkulatora bez pre-fill)
    // lub: skróć state do minimal snapshot
    return { url: base, truncated: true };
  }

  return { url: full, truncated: false };
}
```

---

## Copy-to-Clipboard z Feedback

```tsx
import { useState } from 'react';

function ShareButton({ calcState }: { calcState: CalcState }) {
  const [copied, setCopied] = useState(false);
  const [error, setError] = useState(false);

  async function handleShare {
    const { url, truncated } = buildShareUrl(calcState);

    if (truncated) {
      // Informuj użytkownika
      toast.warning('Link prowadzi do kalkulatora bez pre-fill (wynik zbyt duży do URL)');
    }

    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout( => setCopied(false), 2000);
    } catch {
      // Clipboard API niedostępne (HTTP lub brak uprawnień)
      setError(true);
      // Fallback: prompt lub input[readonly] z select
      window.prompt('Skopiuj link ręcznie:', url);
    }
  }

  return (
    <button
      onClick={handleShare}
      aria-label={copied ? 'Link skopiowany!' : 'Skopiuj link do wyników'}
      className="btn-secondary flex items-center gap-2"
    >
      {copied ? (
        <><CheckIcon className="w-4 h-4 text-green-600" /> Skopiowano!</>
      ) : error ? (
        <><AlertIcon className="w-4 h-4 text-red-600" /> Błąd kopiowania</>
      ) : (
        <><ShareIcon className="w-4 h-4" /> Udostępnij wynik</>
      )}
    </button>
  );
}
```

---

## Restore On Mount

```tsx
// app/kalkulator-[slug]/page.tsx lub w Client Component
'use client';
import { useSearchParams } from 'next/navigation';
import { useEffect } from 'react';

function CalcPage {
  const searchParams = useSearchParams;

  useEffect( => {
    const stateParam = searchParams.get('state');
    if (stateParam) {
      const restored = decodeState(stateParam);
      if (restored) {
        dispatch({ type: 'RESTORE', payload: restored });
        // Opcjonalnie: scroll to result jeśli state zawiera completed wizard
        if (restored.completed) {
          document.getElementById('calc-result')?.scrollIntoView({ behavior: 'smooth' });
        }
      } else {
        // Corrupt/invalid state — zignoruj, startuj od nowa
        toast.info('Nie udało się przywrócić wyników. Wypełnij kalkulator od nowa.');
      }
    }
  }, []); // eslint-disable-line react-hooks/exhaustive-deps — run once on mount
}
```

---

## URL Length Benchmark

| State size | Compressed | URL length | Safe? |
|---|---|---|---|
| 5 pól (step 1-2) | ~120 znaków | ~200 znaków | Tak |
| 15 pól (3-4 kroki) | ~300 znaków | ~400 znaków | Tak |
| 30 pól (4-5 kroków) | ~600 znaków | ~800 znaków | Tak |
| 60 pól + nested arrays | ~1500 znaków | ~1700 znaków | Tak (blisko limitu) |
| >80 pól lub duże tablice | >2000 znaków | >2100 znaków | NIE — truncate |

Kompresja LZString dla JSON-a kalkulatorowego: ~60-75% redukcja rozmiaru vs raw JSON.

---

## Anti-wzorce

1. `encodeURIComponent(JSON.stringify(state))` bez kompresji → 3-4× dłuższy URL, łatwo >2000 znaków.
2. Brak walidacji Zod po decompresji → crash gdy użytkownik zmanipuluje URL ręcznie.
3. Brak Clipboard API fallback → silent fail na HTTP (localhost lub niebezpieczny kontekst).
4. Brak feedback po copy → użytkownik nie wie czy kliknięcie zadziałało.
5. `localStorage` jako alternatywa do share → działa tylko na tym samym urządzeniu, nie "share".
