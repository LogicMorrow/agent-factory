# hosting-strategies.md — gdzie hostować wideo portfolio

Trade-offs między 5 strategiami hostingu wideo dla portfolio (lub każdej strony web). Decyzja per use case.

## Strategia 1: Self-hosted (preferowana MVP)

**Co:** wideo lokalnie w `public/media/`, deploy na Vercel/Cloudflare Pages razem z site.

| Plus | Minus |
|---|---|
| ✅ Pełna kontrola | ❌ Bandwidth z planu hostingu |
| ✅ Brak third-party cookies (GDPR) | ❌ Brak adaptive streaming (HLS/DASH) |
| ✅ Brak tracker'ów (Vimeo/YouTube wkleja JS) | ❌ Vercel free tier: 100GB/mies bandwidth |
| ✅ Natywne HTML5 video (`<video>`) | ❌ Bez "Watch later" / "subscribe" social |
| ✅ Captions VTT served z tego samego origin | |

**Kiedy używać:**
- MVP portfolio (≤ 3 wideo, łącznie < 50 MB)
- GDPR/privacy first projekty
- Sites z low traffic (< 1000 visits/mies)

**Limity Vercel free tier:**
- 100 GB bandwidth/mies
- 5 MB / asset limit (większe wideo ok, ale 1 wideo 50MB × 2000 views = 100GB exhaust)

**Risk:** viral traffic exhaustuje bandwidth → site 503 lub overage charges.

**Mitigation v1.1:** przenieś wideo na CDN (Strategia 2/3) gdy bandwidth > 50% limit.

## Strategia 2: CDN third-party (Bunny.net, Cloudflare R2)

**Co:** wideo na CDN, HTML5 `<video>` `src` wskazuje na CDN URL.

| Plus | Minus |
|---|---|
| ✅ Bandwidth tanio (Bunny.net: $0.005/GB EU) | ❌ Setup overhead |
| ✅ Global edge cache (low latency) | ❌ Trzeba konto + billing |
| ✅ Natywne HTML5 (zero JS) | ❌ Brak adaptive streaming (chyba że paid tier Bunny Stream) |
| ✅ Custom CORS dla VTT cross-origin | |

**Providers comparison (2026):**

| Provider | Pricing | Plus | Minus |
|---|---|---|---|
| **Bunny.net Storage + CDN** | $0.01/GB stored + $0.005/GB egress EU | Tania, simple API | Brak built-in player |
| **Cloudflare R2 + Workers** | $0.015/GB stored, **0 egress** | Free egress = winner long-term | Wymaga Workers dla custom paths |
| **AWS S3 + CloudFront** | $0.023/GB stored + $0.085/GB egress | Enterprise-grade | Drogo |
| **Vercel Pro** | $20/mies + 1 TB bandwidth | Integration | Drogo dla single hobby |

**Rekomendacja operator v1.1:** **Cloudflare R2** — 10 GB storage free + 0 egress fee.

**Setup:**
1. Upload `hero.mp4` + `hero.webm` + `hero-poster.webp` do R2 bucket
2. Cloudflare Workers route `/media/*` → R2 (zero egress fee)
3. `<source src="https://cdn.operator.dev/media/hero.mp4">`

**CORS:** ustaw `Access-Control-Allow-Origin: https://operator.dev` w R2 bucket policy.

## Strategia 3: Vimeo (paid)

**Co:** wideo na Vimeo, embed `<iframe>` lub custom player.

| Plus | Minus |
|---|---|
| ✅ Adaptive streaming (1080p/720p/480p auto) | ❌ Paid plan ($12/mies+) |
| ✅ Captions, chapters, analytics built-in | ❌ Vimeo branding (chyba że Plus+) |
| ✅ Domain restrictions (anti-hotlinking) | ❌ Cookies third-party (chyba że "do-not-track" mode) |
| ✅ Quality control | ❌ Vimeo Player JS ~150KB |
| ✅ Backup/CDN automatic | ❌ Lock-in |

**Kiedy używać:**
- Wideo > 50MB (Vercel bandwidth limit)
- Multi-quality streaming wymagane (long-form content)
- Brand control acceptable z Vimeo logo

**operator portfolio:** NIE rekomendowane (overkill dla 30s hero clip).

## Strategia 4: YouTube embed (free)

**Co:** wideo na YouTube, embed `<iframe>`.

| Plus | Minus |
|---|---|
| ✅ Free | ❌ Cookies third-party (Google Analytics, ad-tracking) |
| ✅ Best-in-class player | ❌ GDPR consent banner WYMAGANY w EU |
| ✅ SEO bonus (YouTube indexed) | ❌ "Suggested videos" panel po pauzie (rozprasza) |
| ✅ Free adaptive streaming | ❌ YouTube branding/logo |
| ✅ Captions auto | ❌ Recommendations algorithm (politically charged content może się pojawić) |

**Privacy-friendly variant:** `youtube-nocookie.com` zamiast `youtube.com` — mniej tracking, ale wciąż third-party.

**Kiedy używać:**
- Wideo które chcesz promować na YouTube niezależnie
- Long-form content (>5 min)
- Akceptujesz cookie banner + Google ecosystem

**operator portfolio:** NIE rekomendowane (zero third-party tracking = preferencja).

## Strategia 5: Hybrid (self-host hero + Vimeo case studies)

**Co:** hero video self-hosted (kluczowy LCP), długie case studies na Vimeo.

| Plus | Minus |
|---|---|
| ✅ LCP fast (hero self-hosted) | ❌ Mixed CSP rules |
| ✅ Bandwidth oszczędność (długie wideo na Vimeo) | ❌ 2 systemy = 2x maintenance |
| ✅ A11y simple dla hero | ❌ Vimeo player accessibility wymaga audit |

**Kiedy używać:**
- Portfolio z hero clip 30s + 3-5 case study walkthroughs po 2-3 min każdy
- Total bandwidth > 50 GB/mies expected

## Decision matrix dla operatora

| Use case | Strategia | Powód |
|---|---|---|
| MVP v1.0 (30s hero, brak case-study videos) | **Self-host** (Strategia 1) | Najprościej, < 5MB total |
| v1.1 (3 case study walkthroughs po 2 min) | **Hybrid** (Strategia 5) lub **Cloudflare R2** (Strategia 2) | Bandwidth saving |
| v1.2 (viral traffic, > 50 GB/mies bandwidth) | **Cloudflare R2** (Strategia 2) | 0 egress fee |
| v1.x (operator chce YouTube channel) | **Strategia 4 z `youtube-nocookie`** | Cross-promotion |

**MVP v1.0 rekomendacja:** Self-host. Setup: `optimize-media.sh` → `public/media/` → deploy.

## Anti-patterns hostingu

### Anti-pattern 1: wideo bezpośrednio z Google Drive / Dropbox public link

**Co:** `<video src="https://drive.google.com/file/...">`

**Dlaczego ŹLE:**
- Brak CDN → wolne
- Brak HTML5 video player (Google Drive wymusza iframe)
- TOS violation (Google Drive nie jest CDN)
- Random rate limits

### Anti-pattern 2: wideo GIF zamiast `<video>`

**Co:** animated GIF jako "wideo" tła hero.

**Dlaczego ŹLE:**
- GIF jest ~10x większy bitrate niż MP4 dla tej samej jakości
- Brak controls, brak pauzy, brak a11y
- LCP killer

**DOBRZE:** zawsze `<video>` z multiple sources.

### Anti-pattern 3: brak fallback dla wideo

**Co:** `<video src="hero.mp4">` bez `<source>` ani fallback `<p>`.

**Dlaczego ŹLE:**
- 1% userów na bardzo starych browserach → black screen.
- Brak format negotiation (WebM vs MP4).

**DOBRZE:** multiple `<source>` + fallback `<p>` z download link.

### Anti-pattern 4: autoplay z sound + brak `playsinline`

**Co:** `<video autoplay src="hero.mp4">` na iOS.

**Dlaczego ŹLE:**
- iOS Safari odpala fullscreen player → user musi zamknąć
- Brak `muted` → autoplay blocked

**DOBRZE:** `muted autoplay playsInline` zawsze razem.

## Status

v1.0.0 (2026-05-13) — 5 strategii + decision matrix dla portfolio. Update q+1 wraz z trends (HLS/DASH adoption, new CDN providers).
