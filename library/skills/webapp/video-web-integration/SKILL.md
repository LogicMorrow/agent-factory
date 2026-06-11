---
name: video-web-integration
description: "HTML5 video best practices dla web — multi-source (MP4 H.264 + WebM VP9), poster zawsze, lazy load przez IntersectionObserver, autoplay-mute restrictions, VTT captions (a11y), preload strategies, FFmpeg presets (optymalizacja MP4/WebM/poster), hosting trade-offs (self-host vs CDN vs Vimeo). Konsumowany przez web-builder portfolio mode (E8), code-implementer (hero video component), optimize-media.sh skrypt (E10). NIE używać do: YouTube embeds (trade-offs w hosting-strategies.md), live streaming (HLS/DASH), screen recording capture."
version: 1.0.0
compatible_with: [webapp]
tags: [video, html5, lazy-loading, ffmpeg, a11y, captions, webm, mp4]
requires: [responsive-web-standards-2026]
token_cost: medium
distribution: library/skills/webapp/
last_updated: 2026-05-13
---

# video-web-integration

Best practices dla osadzania wideo w aplikacjach web 2026. Skupienie: **self-hosted MP4 + WebM**, **lazy load**, **a11y compliance** (captions, transcripts), **CWV-aware** (lazy + poster + preload metadata).

**Bundle pliki:**
- `SKILL.md` — wiedza referencyjna (ten plik)
- `ffmpeg-presets.sh` — komendy FFmpeg dla MP4 H.264 / WebM VP9 / poster / audio extract
- `captions-template.vtt` — szablon napisów PL (WebVTT format)
- `hosting-strategies.md` — self-host vs CDN vs Vimeo vs YouTube z trade-offs

## When to use this skill

Uruchamiaj gdy:
- `web-builder --mode=portfolio` osadza hero video (E8)
- `code-implementer` pisze `<VideoPlayer>` component
- `optimize-media.sh` skrypt batch convert media w `public/`
- `page-speed-optimizer` debuguje CWV (LCP blokowany przez wideo)
- operator dodaje case-study video do sekcji portfolio

## Pre-execution context loading

Agent konsumujący ten skill MA czytać:
- `responsive-web-standards-2026/cwv-targets.yaml` (LCP/INP budgets)
- `responsive-web-standards-2026/wcag-2-2-aa-checklist.md` (sekcja Media)
- `portfolio-design-patterns/SKILL.md` (Wzorzec 1: Hero+Video)

## Markup wzorcowy — pełen `<video>` z a11y

```tsx
<video
  poster="/media/hero-poster.webp"
  preload="metadata"
  muted
  autoPlay
  playsInline
  loop
  aria-label="operator przy pracy — krótki klip showcase"
  className="w-full h-auto rounded-lg"
>
  {/* WebM PIERWSZY (preferowany przez nowoczesne przeglądarki, lepsza kompresja) */}
  <source src="/media/hero.webm" type="video/webm" />
  {/* MP4 fallback (Safari, starsze przeglądarki) */}
  <source src="/media/hero.mp4" type="video/mp4" />

  {/* Captions VTT — mandatory dla wideo z dźwiękiem */}
  <track
    kind="captions"
    src="/media/hero-pl.vtt"
    srcLang="pl"
    label="Polski"
    default
  />

  {/* Fallback dla przeglądarek bez HTML5 video (1% rynku, raczej nie potrzeba) */}
  <p>
    Twoja przeglądarka nie obsługuje HTML5 video.
    <a href="/media/hero.mp4">Pobierz wideo (MP4)</a>.
  </p>
</video>
```

### Decyzje per atrybut

| Atrybut | Wartość | Dlaczego |
|---|---|---|
| `poster` | path do JPEG/WebP | Pokazuje przed load; LCP element zamiast wideo |
| `preload` | `metadata` (default) lub `none` (jeśli below-the-fold) | `auto` blokuje LCP, `none` cache miss |
| `muted` | zawsze obowiązkowe dla autoplay | Browsers BLOKUJĄ autoplay z dźwiękiem (Chrome 2018+) |
| `autoplay` | tylko dla hero/ambient | NIE dla case study video (user wybiera) |
| `playsinline` | mandatory na iOS | Bez tego Safari mobile odpala fullscreen |
| `loop` | tylko dla < 15s clip | Dłuższe loopy irytują |
| `controls` | tylko gdy > 10s lub user-initiated | Ambient hero nie potrzebuje controls |
| `aria-label` | opis treści wideo | Screen reader (gdy track nie wystarczy) |
| `crossorigin` | `anonymous` jeśli CDN | Potrzebne dla VTT z innego origin |

## Multi-source — kolejność `<source>`

**Reguła:** WebM PIERWSZY, MP4 DRUGI.

**Powód:** browsers parsują `<source>` po kolei, używają pierwszego supported.
- WebM VP9: ~85% rynku 2026 (Chrome, Firefox, Edge, Android, Safari 16+).
- MP4 H.264: 100% fallback.

**Wynik:** nowoczesne przeglądarki ładują WebM (~30% mniejszy bitrate przy tej samej jakości), starsze MP4.

## Lazy load via IntersectionObserver

**Cel:** wideo NIE ładuje się dopóki user nie scrolluje blisko viewport. Oszczędza bandwidth + LCP.

### React hook (TypeScript)

```tsx
'use client'
import { useEffect, useRef, useState } from 'react'

export function useLazyVideo<T extends HTMLVideoElement>(rootMargin = '200px') {
  const ref = useRef<T>(null)
  const [shouldLoad, setShouldLoad] = useState(false)

  useEffect( => {
    if (!ref.current) return
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setShouldLoad(true)
          observer.disconnect
        }
      },
      { rootMargin }
    )
    observer.observe(ref.current)
    return  => observer.disconnect
  }, [rootMargin])

  return { ref, shouldLoad }
}
```

### Użycie

```tsx
function CaseStudyVideo({ src, poster }: { src: string; poster: string }) {
  const { ref, shouldLoad } = useLazyVideo<HTMLVideoElement>

  return (
    <video ref={ref} poster={poster} preload="none" controls muted playsInline>
      {shouldLoad && (
        <>
          <source src={src + '.webm'} type="video/webm" />
          <source src={src + '.mp4'} type="video/mp4" />
        </>
      )}
    </video>
  )
}
```

### Hero NIE lazy

Hero video ładuje się **natychmiast** (above-the-fold). Lazy DLA case studies, opt-in widgets.

## VTT captions — szablon i konwencja

WebVTT (`.vtt`) — format napisów wspierany natywnie przez `<track>`.

### Minimalny przykład

```vtt
WEBVTT
Kind: captions
Language: pl

00:00:00.000 --> 00:00:03.500
Cześć, jestem operator Nowak.

00:00:03.500 --> 00:00:07.000
Buduję agenty AI i automatyzuję sprzedaż B2B.

00:00:07.000 --> 00:00:12.000
W tym wideo pokażę 3 projekty: cold mailing, analytics dashboard, agent CC.
```

### Konwencje

- **Język:** PL primary. EN opt-in v1.1 (`<track ... srcLang="en" label="English" />`).
- **Limit znaków per linia:** 42 (czytalne 1 linia).
- **Max 2 linie per cue.**
- **Czas trwania cue:** 1-7 sekund (krótkie cue dla szybkiej mowy, dłuższe dla pauz).
- **Bez mówcy** (jeśli single speaker). Z mówcą `<v operator>...` jeśli interview.

### Generacja captions

| Metoda | Plus | Minus |
|---|---|---|
| **Manualne pisanie** | 100% accuracy, kontrola | 1h pracy/1 min wideo |
| **Whisper API** (OpenAI) | Auto-transcribe, ~95% PL accuracy | Cost, wymaga proofread |
| **YouTube Studio auto-captions** | Free, fast | 80% PL accuracy, wymaga proofread |
| **Anthropic Claude Sonnet + audio** | Multi-modal, PL accuracy ~90% | Wymaga handling audio file |

**Rekomendacja operator:** Whisper API → ręczny proofread (`/proofread-pl` z polish-proofreader) → publish.

## Preload strategies

| Strategy | Wartość `preload` | Kiedy używać |
|---|---|---|
| Eager (above-fold) | nie ustawiać (default = `auto`) lub `metadata` | Hero video |
| Lazy (below-fold) | `none` + IntersectionObserver dynamic load | Case study video |
| Background prefetch | manual `<link rel="prefetch">` | Wideo które user prawdopodobnie kliknie |

**Anti-pattern:** `preload="auto"` dla wszystkich wideo → ładujesz bajty których user może nigdy nie zobaczyć.

## Captions vs Transcripts vs Subtitles

| Term | Definicja | Kiedy |
|---|---|---|
| **Captions** | Tekst dla niesłyszących (mowa + dźwięki "[muzyka]") | A11y mandatory dla wideo z mową |
| **Subtitles** | Tekst tłumaczenia (mowa only) | Multi-language v1.1 |
| **Transcripts** | Pełen tekst wideo pod video element | Bonus a11y, SEO win |

### Transcripts pattern

```tsx
<details className="transcript">
  <summary>Transkrypt tekstowy wideo</summary>
  <div className="transcript__content">
    <p>Cześć, jestem operator Nowak. Buduję agenty AI i automatyzuję sprzedaż B2B...</p>
    {/* pełen tekst */}
  </div>
</details>
```

**Bonus:** transcript jest indexowany przez Google → SEO content.

## Performance budgets dla wideo

| Metryka | Target | Hard limit |
|---|---|---|
| Hero video file size | < 2 MB | < 5 MB |
| Hero video duration | < 30s | < 60s |
| Case study video | < 10 MB | < 30 MB |
| Poster (WebP) | < 80 KB | < 200 KB |
| Total media w `public/` | < 50 MB | Vercel free tier limit |

**Vercel free tier:** 100 GB bandwidth/mies. Wideo 5MB × 1000 views = 5 GB. **Risk:** viral traffic → bandwidth exhausted.

**Mitigation:** dla v1.1 przenieść wideo na Bunny.net CDN ($0.005/GB EU) lub Cloudflare R2 (free 10GB egress).

## CWV impact

| Pattern | LCP | INP | CLS |
|---|---|---|---|
| Hero video bez poster | ❌ BLOCK (czarny screen 1-2s) | OK | ❌ shift on load |
| Hero video z poster `webp` | ✅ Poster = LCP | OK | ✅ aspect-ratio set |
| Lazy case study video | ✅ Nie wpływa (below-fold) | OK | OK jeśli reserve space |
| Autoplay multiple | ❌ Multiple parallel downloads | ❌ Main thread busy | OK |

**Reguła:** **1 autoplay video max per page**. Reszta `controls` user-initiated.

## A11y compliance checklist

- [ ] `<track kind="captions">` z VTT dla każdego wideo z mową
- [ ] `aria-label` na `<video>` z opisem treści
- [ ] Transcript jako alternatywa (collapsed details)
- [ ] Controls keyboard-accessible (default HTML5 controls są — custom controls wymagają testów)
- [ ] Brak autoplay z dźwiękiem (mandatory `muted`)
- [ ] Pauza dostępna w < 5s od pojawienia się (WCAG 2.2.2)
- [ ] Brak flashing > 3x/s (WCAG 2.3.1)
- [ ] `prefers-reduced-motion` respect (opcja: pomiń autoplay loop)

## Procedury (use case)

### Procedura A: dodanie hero video do portfolio

1. operator nagrywa 30s clip (telefon lub kamera) → `raw/hero-source.mov`
2. Uruchom `optimize-media.sh raw/hero-source.mov` → generuje:
   - `public/media/hero.mp4` (H.264 baseline, ~1.5MB)
   - `public/media/hero.webm` (VP9, ~1MB)
   - `public/media/hero-poster.webp` (frame 0, ~50KB)
3. Wygeneruj VTT captions (Whisper API → `/proofread-pl` proofread) → `public/media/hero-pl.vtt`
4. Apply markup wzorcowy w `app/components/Hero.tsx`
5. Lighthouse audit — verify LCP ≤ 2.5s

### Procedura B: case study video (lazy)

1. operator nagrywa 2-3 min walkthrough → `raw/case-study-1.mov`
2. `optimize-media.sh` (z innym presetem — case study, większy bitrate OK)
3. Generuj poster (15s mark — interesting frame)
4. Generuj captions
5. Use `useLazyVideo` hook + `preload="none"`

## Status

v1.0.0 (2026-05-13) — initial release dla paczki `af-pack-<nazwa>` (E3 plan paczki).

## Cross-reference

- `ffmpeg-presets.sh` — concrete FFmpeg commands
- `captions-template.vtt` — VTT structure
- `hosting-strategies.md` — self-host vs CDN vs YouTube/Vimeo
- `portfolio-design-patterns/SKILL.md` Wzorzec 1 — Hero+Video integration
- `responsive-web-standards-2026/image-opt-strategy.md` — analogiczne wzorce dla obrazków
