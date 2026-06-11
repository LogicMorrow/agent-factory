---
name: seo-fundamentals
description: Fundament SEO uniwersalny dla każdej strony — meta tagi, Schema.org JSON-LD, sitemap.xml, robots.txt, canonical, hreflang, Core Web Vitals 2026 baseline, internal linking, security headers. MUST-DO każda strona przed włączeniem zaawansowanego SEO. Uruchamiaj przy starcie każdego webapp PL, audycie istniejącej strony lub projektowaniu nowej.
version: 1.0.0
compatible_with: [universal]
tags: [seo, technical, foundation]
requires: []
token_cost: medium
distribution: library/skills/universal/
last_updated: 2026-05-11
---

# seo-fundamentals

Jedno źródło prawdy SEO MUST-DO dla każdej strony. Reszta skilli SEO (seo-advanced, polish-language-seo, regional-seo-poland) buduje NA TYM — wszystkie mają `requires: [seo-fundamentals]`. Przykłady kodu: Next.js 15 App Router w `examples.md`. Przykłady branżowe: budownictwo (firma GW), ale skill jest UNIWERSALNY.

## When to use this skill

Uruchamiaj gdy:
- Startujesz nowy webapp PL (PRZED pierwszym deployem — to fundament indeksowania)
- Audytujesz istniejącą stronę pod kątem technicznego SEO
- Agent `web-builder`, `seo-strategist` lub `seo-auditor` projektuje lub sprawdza stronę
- Pytanie dotyczy meta tagów, schema.org, sitemapy, robots.txt, canonical, hreflang

NIE uruchamiaj gdy:
- Potrzebujesz optymalizacji Core Web Vitals (jak osiągnąć LCP <2.5s) → `seo-advanced`
- Szukasz wzorców fleksji PL w keyword research → `polish-language-seo`
- Konfigurujesz Google Business Profile krok po kroku → `regional-seo-poland`

---

## 1. Meta tagi (title, description, Open Graph, Twitter Cards, canonical, robots)

### Title

- Długość: **50-60 znaków** (Google obcina po ~60)
- Format: `Keyword Główny | Brand` (brand na końcu)
- Primary keyword PIERWSZY — sygnał relewancji
- Unikalne per strona — identyczne title = duplicate content signal

```
Dobre: "Budowa domu jednorodzinnego Warszawa — Firma GW"  (51 znaków)
Złe:   "Firma GW — witamy na naszej stronie internetowej" (51 znaków, brak keyword)
```

### Description

- Długość: **150-160 znaków** (Google obcina)
- Format: CTA + keyword naturalnie + USP
- Nie wpływa na ranking — wpływa na CTR (click-through rate)
- Unikalne per strona

### Open Graph (Facebook, LinkedIn, Slack preview)

Wymagane pola: `og:title`, `og:description`, `og:image` (1200×630px JPG/PNG, max 300KB), `og:type` (website/article), `og:locale` (pl_PL), `og:site_name`, `og:url` (canonical bez parametrów UTM).

### Twitter Cards

Pola: `twitter:card=summary_large_image`, `twitter:title`, `twitter:description`, `twitter:image`. Bez karty tweet pokazuje tylko URL.

### Canonical URL (w meta tagach)

`<link rel="canonical" href="https://domain.pl/ścieżka">` — zawsze BEZ parametrów UTM. Szczegóły w sekcji 5.

### Robots meta

```
Standardowo:        <meta name="robots" content="index, follow">
Utility pages:      <meta name="robots" content="noindex, follow">
                    (search, login, koszyk, /admin/)
Stock photo pages:  <meta name="robots" content="index, follow, noimageindex">
```

Pełny przykład Next.js 15 `metadata` export → `examples.md` sekcja 1 (`app/layout.tsx`).

---

## 2. Schema.org JSON-LD

Implementacja: `<script type="application/ld+json">` w `<head>`. Next.js 15: komponent `<JsonLd>` (SSR-safe) → `examples.md` sekcja 4. Pełne templates z placeholderami → `schema-templates.json`.

| Typ | Kiedy używać |
|---|---|
| **Organization** | Każda strona firmowa — footerowy JSON-LD z logiem i sameAs |
| **LocalBusiness** | Firmy z fizyczną lokalizacją (budowlanka, usługi lokalne) |
| **Service** | Opis konkretnej usługi z provider ref do Organization |
| **Article** | Każdy wpis blogowy / poradnik |
| **FAQPage** | Sekcje Q&A na landing page — wysoka szansa Featured Snippet |
| **BreadcrumbList** | Nawigacja okruszkowa — zawsze razem z wizualnym breadcrumb |

### LocalBusiness — kluczowe pola

```json
{
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "name": "{{COMPANY_NAME}}",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "{{STREET}}",
    "addressLocality": "{{CITY}}",
    "postalCode": "{{POSTAL_CODE}}",
    "addressCountry": "PL"
  },
  "telephone": "{{PHONE}}",
  "areaServed": ["mazowieckie", "małopolskie"],
  "openingHours": ["Mo-Fr 08:00-17:00"]
}
```

`priceRange` jest OPCJONALNY — patrz sekcja "Anti-patterns" (fake range).
`addressCountry: "PL"` — ISO 3166-1 alpha-2, Google akceptuje.

Dodatkowe typy warte uwagi: **Review / AggregateRating** (tylko prawdziwe opinie), **JobPosting** (branża budowlana często rekrutuje — pomaga w Google for Jobs).

---

## 3. sitemap.xml (next-sitemap)

Instalacja: `npm i next-sitemap`, config `next-sitemap.config.js`. Pełny przykład z funkcją `transform` → `examples.md` sekcja 3.

### Priority i changefreq — konwencja

| Route | priority | changefreq |
|---|---|---|
| `/` (home) | 1.0 | weekly |
| `/uslugi/*` (category) | 0.9 | monthly |
| `/blog/*` (article) | 0.7 | never |
| `/o-nas`, `/kontakt` | 0.5 | yearly |

### Pułapki sitemap

- **`lastmod: new Date`** przy każdym buildzie → sygnał manipulacji. Używaj prawdziwej daty edycji z CMS/git log.
- **Sitemap index** — gdy >50 000 URLi (Google limit na plik). Ustaw `sitemapSize: 5000`.
- Strony z `noindex` NIE powinny być w sitemap — niespójność sygnałów.

---

## 4. robots.txt

Pełny template → `examples.md` sekcja 6. Kluczowe bloki:

```text
User-agent: Googlebot
Allow: /

User-agent: GPTBot
Disallow: /

User-agent: *
Disallow: /api/
Disallow: /admin/

Sitemap: https://domain.pl/sitemap.xml
```

### Dlaczego AI crawlers Disallow (decyzja domyślna)

Priorytet: ochrona know-how (budowlanka, wyceny, porady techniczne). Trade-off: **blokuje widoczność w AI Overview** (Google SGE) i Perplexity answers.

### Kiedy zmienić na Allow dla AI crawlerów

- Priorytet: brand awareness przez AI answers (content marketing, media, edukacja)
- Strona ma treści do cytowania przez AI asystentów
- Decyzja per projekt — zmień w `robots.txt` lub użyj `X-Robots-Tag` header na wybrane sekcje

---

## 5. Canonical URL — pułapki

**Self-canonical zalecane** — każda strona deklaruje canonical na siebie (nawet bez duplikatów).

| Pułapka | Problem | Naprawa |
|---|---|---|
| Canonical na 404 | Google ignoruje | Sprawdź GSC: Coverage → Submitted URL not found |
| Canonical chain (A→B→C) | Max 1 hop respektowany | Skróć do A→C direct |
| Canonical z parametrem UTM | `?utm_source=google` w canonical | Canonical zawsze BEZ parametrów |
| Brak self-canonical | Google wybiera inny URL | Dodaj explicite per page |

Next.js 15 implementacja (static + dynamic generateMetadata) → `examples.md` sekcja 2.

### URL slug PL — transliteration

`ą→a`, `ę→e`, `ó→o`, `ś→s`, `ł→l`, `ź→z`, `ż→z`, `ć→c`, `ń→n`. Kebab-case. Przykład: `/uslugi/budowa-domu-jednorodzinnego`. Głębsze zasady → `polish-language-seo`.

---

## 6. Hreflang (PL self + future-proof PL/EN/x-default)

Dwa warianty implementacji (Next.js 15 `metadata.alternates.languages`) → `examples.md` sekcja 2.

**Wariant domyślny:** `languages: { 'pl': 'https://domain.pl/path' }`

**Wariant future-proof:** `languages: { 'pl': '...', 'en': '...', 'x-default': '...' }`

### Reciprocal rule (KRYTYCZNE)

Każda wersja językowa MUSI deklarować WSZYSTKIE pozostałe. Brak reciprocal = Google ignoruje hreflang.

### Pułapki hreflang

- `x-default` wymagane przy multi-language (fallback dla nieznanych regionów)
- Canonical i hreflang muszą być spójne (canonical strony PL = URL PL)
- Zmiana URL wersji EN bez aktualizacji hreflang w PL = broken signal

---

## 7. Internal linking (hub+spoke preview, breadcrumbs, related, anchor text)

### Hub + spoke (topical clusters) — PREVIEW

Hub page (pillar) = główna strona tematu. Spoke pages = artykuły szczegółowe linkujące do huba. Przykład: hub `/uslugi/budowa-domu` ← spoki: `/blog/fundament-ławowy-vs-płytowy`, `/blog/koszt-budowy-domu-100m2`. Pełne wzorce topical clusters → `seo-advanced`.

### Breadcrumbs

Zawsze razem z `BreadcrumbList` schema (sekcja 2). Wizualny breadcrumb + schema muszą być spójne.

### Related articles

Sekcja "Podobne wpisy" pod artykułem — 3-5 linków do siostrzanych tematycznie. Zmniejsza bounce rate + distribute page authority.

### Anchor text rules

| Typ | Przykład | Zasada |
|---|---|---|
| Partial match | "koszt budowy domu w Warszawie" | Preferowany — naturalny |
| Exact match | "budowa domu Warszawa" | Max 20-30% — natural mix |
| Generic | "kliknij tutaj", "więcej" | **ZAKAZ** — zero sygnału SEO |
| Keyword stuffing | "budowa dom Warszawa tanio szybko" | **ZAKAZ** — penalty risk |

---

## 8. Google 2026 technical checklist

### HTTPS + HSTS

`Strict-Transport-Security: max-age=31536000; includeSubDomains`. Weryfikacja: `curl -I https://domain.pl | grep Strict`.

### Mobile-friendly

`<meta name="viewport" content="width=device-width, initial-scale=1">`. Test: Google Mobile-Friendly Test.

### Core Web Vitals 2026 — progi (thresholds)

| Metryka | Good | Needs Improvement | Poor |
|---|---|---|---|
| **LCP** (Largest Contentful Paint) | <2.5s | 2.5-4.0s | >4.0s |
| **INP** (Interaction to Next Paint) | <200ms | 200-500ms | >500ms |
| **CLS** (Cumulative Layout Shift) | <0.1 | 0.1-0.25 | >0.25 |

INP zastąpiło FID od marca 2024. PageSpeed Insights = CrUX (field data), Lighthouse = lab data — różnice normalne. Jak osiągnąć te progi → `seo-advanced`.

### Structured data validator

Przed deployem: `validator.schema.org` lub Google Rich Results Test. Błędy = brak rich results.

### HTTP/2

Caddy: domyślnie HTTP/2. Nginx: `listen 443 ssl http2`. Weryfikacja: `curl -I --http2 https://domain.pl`.

### Security headers (short overview)

Pełna implementacja (Next.js middleware.ts) → `examples.md` sekcja 5.

| Header | Wartość minimalna |
|---|---|
| `Content-Security-Policy` | `default-src 'self'` + allowlist |
| `X-Frame-Options` | `SAMEORIGIN` |
| `X-Content-Type-Options` | `nosniff` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | `geolocation=, microphone=, camera=` |

---

## 9. Anti-patterns (czerwone flagi SEO)

| Anti-pattern | Mechanizm kary | Naprawa |
|---|---|---|
| **Keyword stuffing** | >2-3% density → BERT NLP detection → obniżenie pozycji | Pisz naturalnie, 1 główny keyword per strona |
| **Hidden text** | `color:white` na białym tle, `display:none` z keywordami — Google renderuje JS | Usuń — deliberate deception |
| **Cloaking** | Inny HTML dla Googlebota vs użytkownika | Manual penalty → ban. Zakaz bezwyjątkowy |
| **Doorway pages** | Identyczne strony różniące się tylko nazwą miasta | Unikalne treści per lokalizacja → `regional-seo-poland` |
| **Paid links bez atrybutu** | `<a>` bez `rel="nofollow"` lub `rel="sponsored"` | Dodaj atrybut |
| **Scraped content** | Duplikat z innych stron → de-indexowanie | Oryginalne treści lub cytaty z attribution |
| **Fake reviews schema** | JSON-LD `Review` z wymyślonych opinii → manual penalty | Tylko prawdziwe opinie z imieniem + datą |
| **AI content bez edycji** | Helpful Content Update 2022+ filtruje autogen | AI jako draft → human edit → E-E-A-T markers (`seo-advanced`) |
| **Missing alt text** | Obrazy bez `alt` → niedostępne dla Googlebota image search | `alt` = opis obrazu + optional keyword naturalnie |

---

## Boundary with seo-advanced

**Fundamentals (TU):** MUST-DO — meta, schema, sitemap, robots, canonical, hreflang, CWV progi (tylko liczby), security headers lista.

**seo-advanced:** NICE-TO-HAVE — jak OSIĄGNĄĆ LCP <2.5s, E-E-A-T markers, topical clusters DEEP, intent mapping, content gap, SERP features, AI Overview/SGE optimization.

**Reguła:** "Jakie progi CWV?" → fundamentals. "Jak zoptymalizować INP kalkulatora?" → seo-advanced.

---

## Boundary with polish-language-seo

**Fundamentals (TU):** URL slug transliteration (1 paragraf sekcja 5), `og:locale: pl_PL`, `hreflang: pl`.

**polish-language-seo:** fleksja PL w keyword research (7 przypadków), polskie SERP behavior, katalogi PL (OLX, Allegro, Otodom, Aleo, Panorama Firm, Oferia), transliteration DEEP.

**Reguła:** "Jak ustawić locale?" → fundamentals. "Warianty keyword 'budowa domu' we wszystkich przypadkach?" → polish-language-seo.

---

## Boundary with regional-seo-poland

**Fundamentals (TU):** `LocalBusiness` schema struktura JSON-LD, `areaServed` pole, `PostalAddress` format PL.

**regional-seo-poland:** Google Business Profile DEEP, NAP consistency, citation building (top 20 katalogów PL), reviews playbook, województwa+powiaty dict YAML.

**Reguła:** "Jak zbudować LocalBusiness JSON-LD?" → fundamentals. "Jak skonfigurować GBP dla firmy budowlanej w Warszawie?" → regional-seo-poland.

---

## How to extend / customize

Placeholders w `schema-templates.json` do zastąpienia danymi firmy. Workflow:

1. Skopiuj `schema-templates.json` do `src/data/schema-templates.json` w projekcie
2. Zastąp: `{{COMPANY_NAME}}`, `{{COMPANY_URL}}`, `{{COMPANY_LOGO_URL}}`, `{{COMPANY_PHONE}}`, `{{COMPANY_ADDRESS}}`, `{{COMPANY_GEO_LAT}}`, `{{COMPANY_GEO_LNG}}`, `{{OPENING_HOURS}}`, `{{SOCIAL_PROFILES}}`
3. `{{PRICE_RANGE_OPTIONAL}}` — realny przedział (np. `"PLN 500-800/m²"`) lub usuń pole
4. `{{AUTHOR_NAME}}` / `{{AUTHOR_URL}}` — w Article schema wymagane dla E-E-A-T

Skrypt TypeScript do automatycznej substitucji → `examples.md` sekcja 7.

**Next.js version compatibility:** Next.js 15 + 14 + 13 App Router — API metadata identyczne. Next.js 12 i starsze (Pages Router): użyj `next-seo` package + `<NextSeo>`. Migracja Pages Router → App Router: nextjs.org/docs/app/building-your-application/upgrading.

---

## References

- **Google Search Central:** https://developers.google.com/search
- **Schema.org:** https://schema.org
- **web.dev — Core Web Vitals:** https://web.dev/articles/vitals
- **Next.js 15 Metadata API:** https://nextjs.org/docs/app/api-reference/functions/generate-metadata
- **next-sitemap:** https://github.com/iamvishnusankar/next-sitemap
- **Google Rich Results Test:** https://search.google.com/test/rich-results
- **Google Mobile-Friendly Test:** https://search.google.com/test/mobile-friendly
