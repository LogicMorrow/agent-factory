# Image Optimization Strategy 2026

Strategia wyboru formatu + next/image best practices + responsive srcset patterns.

---

## 1. AVIF/WebP/JPEG Decision Tree

```
Czy obraz ma przezroczystość (transparency)?
├── TAK → PNG lub WebP
│         (PNG jeśli potrzebujesz 100% browser support, WebP dla nowszych)
└── NIE → Czy to ikona, logo, diagram?
          ├── TAK → SVG (skalowalne, małe, żadnej kompresji straty)
          └── NIE → Zdjęcie/fotografia?
                    ├── TAK → Użyj AVIF (best compression, 95%+ browsers 2026)
                    │         Fallback WebP (97%+ browsers)
                    │         Fallback JPEG (100% legacy)
                    └── NIE (grafika, ilustracja, screenshot z tekstem)
                              → WebP (lossless mode) lub PNG
```

### Porównanie formatów

| Format | Rozmiar vs JPEG | Browser support (2026) | Kiedy |
|---|---|---|---|
| **AVIF** | ~50% mniejszy | ~95% (Chrome 85+, Firefox 93+, Safari 16+) | Hero images, large photos — **preferowany** |
| **WebP** | ~30% mniejszy | ~97% (wszystkie modern browsers) | Fallback dla AVIF, zdjęcia ogólne |
| **JPEG** | baseline | 100% | Legacy fallback, prosta fotografia |
| **PNG** | duży (lossless) | 100% | Wymagana przezroczystość |
| **SVG** | vector (tiny) | 100% | Ikony, logo, diagramy, mapy |
| **GIF** | duży | 100% | UNIKAJ — zamień na `<video>` (autoplay, muted, loop) |

### Kiedy NIE używać AVIF

- Gdy encoding time jest krytyczny (AVIF encoding jest wolniejsze — nie dotyczy next/image który enkoduje raz + cache)
- Legacy browsers (sprawdź traffic analytics — jeśli >5% na Safari <16 lub IE → WebP fallback)

---

## 2. next/image Best Practices

### LCP Image (hero, above-fold)

```tsx
import Image from 'next/image';

// OBOWIĄZKOWE dla LCP image:
// - priority prop (dodaje fetchpriority="high" + preload link)
// - znane wymiary (width + height)
// - quality 85 (default 75 — dla hero można podnieść)
<Image
  src="/hero.jpg"
  alt="Opis zdjęcia bohatera — konkretny, nie 'hero image'"
  width={1200}
  height={600}
  priority        // fetchpriority="high" + preload
  quality={85}
/>
```

**UWAGA:** Tylko JEDNA image na stronie powinna mieć `priority`. Więcej = każda konkuruje o "high priority".

### Below-fold Images (cards, gallery)

```tsx
// Lazy loading + blur placeholder
<Image
  src="/product.jpg"
  alt="Opis produktu"
  width={400}
  height={300}
  loading="lazy"           // default — jawne dla czytelności
  placeholder="blur"       // wymaga blurDataURL lub statycznych imports
  blurDataURL="data:image/jpeg;base64,/9j/4AA..." // tiny base64 placeholder
/>
```

**Generowanie blurDataURL:** `next/image` auto-generuje dla `import photo from './photo.jpg'` (static import). Dla dynamic URLs użyj `plaiceholder` library.

### Responsive Fill (fluid width)

```tsx
// Gdy obraz ma zajmować cały kontener (fluid)
<div style={{ position: 'relative', width: '100%', height: '300px' }}>
  <Image
    src="/banner.jpg"
    alt="Banner"
    fill                    // position: absolute, inset: 0
    style={{ objectFit: 'cover' }}
    sizes="(max-width: 768px) 100vw, (max-width: 1024px) 50vw, 33vw"
  />
</div>
```

### `sizes` attribute — krytyczny dla responsywności

```tsx
// sizes mówi browserowi jak szeroki będzie obraz w różnych breakpointach
// Browser dobiera optymalny srcset wariant

// Pełna szerokość na mobile, 50% na tablet, 33% na desktop:
sizes="(max-width: 768px) 100vw, (max-width: 1024px) 50vw, 33vw"

// Sidebar — zawsze 300px:
sizes="300px"

// Hero — zawsze full width:
sizes="100vw"
```

**Brak `sizes`** = browser zakłada `100vw` → pobiera największy wariant dla każdego breakpointu. CLS + bandwidth waste.

### next/image automatyczny AVIF/WebP

next/image automatycznie serwuje:
- AVIF jeśli `Accept: image/avif` w request headers
- WebP jeśli `Accept: image/webp`
- JPEG/PNG oryginał jako fallback

Nie musisz ręcznie konwertować plików. Wystarczy dostarczyć JPEG/PNG, next/image konwertuje i cache'uje.

### Konfiguracja next.config.ts

```ts
// next.config.ts
const nextConfig = {
  images: {
    formats: ['image/avif', 'image/webp'],  // kolejność preferencji
    deviceSizes: [320, 640, 750, 828, 1080, 1200, 1920, 2048],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
    minimumCacheTTL: 60 * 60 * 24 * 30,  // 30 dni cache
  },
};
```

---

## 3. Responsive srcset Patterns (vanilla HTML)

Gdy nie używasz next/image (statyczny HTML, plain `<img>`):

```html
<!-- 4 warianty: 320w / 640w / 1024w / 1920w -->
<img
  src="/photo-640.jpg"
  srcset="
    /photo-320.jpg  320w,
    /photo-640.jpg  640w,
    /photo-1024.jpg 1024w,
    /photo-1920.jpg 1920w
  "
  sizes="(max-width: 768px) 100vw, (max-width: 1024px) 50vw, 33vw"
  alt="Opis zdjęcia"
  width="1024"
  height="683"
  loading="lazy"
/>
```

**AVIF + WebP + JPEG z `<picture>`:**

```html
<picture>
  <source
    srcset="/photo-320.avif 320w, /photo-640.avif 640w, /photo-1024.avif 1024w"
    type="image/avif"
    sizes="(max-width: 768px) 100vw, 50vw"
  />
  <source
    srcset="/photo-320.webp 320w, /photo-640.webp 640w, /photo-1024.webp 1024w"
    type="image/webp"
    sizes="(max-width: 768px) 100vw, 50vw"
  />
  <img
    src="/photo-640.jpg"
    srcset="/photo-320.jpg 320w, /photo-640.jpg 640w, /photo-1024.jpg 1024w"
    sizes="(max-width: 768px) 100vw, 50vw"
    alt="Opis zdjęcia"
    width="640"
    height="427"
    loading="lazy"
  />
</picture>
```

---

## Anti-patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| Single large image dla wszystkich urządzeń | Mobile pobiera 2MB hero — bandwidth, LCP | `sizes` + srcset warianty |
| JPEG raw bez optymalizacji | 3-5x większy niż potrzeba | next/image lub ręczna konwersja + squoosh.app |
| Brak `width` + `height` | CLS — przeglądarka nie wie ile miejsca zarezerwować | Zawsze podawaj wymiary |
| `loading="eager"` below-fold | Blokuje LCP image, bandwidth waste | `loading="lazy"` (default dla non-priority) |
| `alt=""` dla informacyjnych obrazków | Screen reader pomija, SEO traci | `alt="konkretny opis zawartości"` |
| GIF dla animacji | 10-50x większy niż video | `<video autoplay muted loop playsinline>` |
| `quality={100}` w next/image | Duże pliki bez zauważalnej różnicy | `quality={75-85}` optymalny balans |
