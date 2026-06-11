# seo-fundamentals — Przykłady kodu Next.js 15 App Router

Gotowe do wklejenia snippety. Stack: Next.js 15, App Router, TypeScript.

---

## 1. `app/layout.tsx` — metadata root z pełnym SEO setup

```typescript
import type { Metadata } from 'next'

export const metadata: Metadata = {
  // Title template — %s jest zastępowane przez child pages
  title: {
    template: '%s | {{COMPANY_NAME}}',
    default: '{{COMPANY_NAME}} — {{PRIMARY_SERVICE}} {{CITY}}',
  },

  // Description — 150-160 znaków
  description: '{{COMPANY_DESCRIPTION_150_CHARS}}',

  // Open Graph
  openGraph: {
    type: 'website',
    locale: 'pl_PL',
    siteName: '{{COMPANY_NAME}}',
    images: [
      {
        url: '{{COMPANY_OG_IMAGE_URL}}', // 1200x630px, max 300KB
        width: 1200,
        height: 630,
        alt: '{{COMPANY_NAME}} — {{PRIMARY_SERVICE}}',
      },
    ],
  },

  // Twitter Cards
  twitter: {
    card: 'summary_large_image',
    title: '{{COMPANY_NAME}} — {{PRIMARY_SERVICE}} {{CITY}}',
    description: '{{COMPANY_DESCRIPTION_SHORT}}',
    images: ['{{COMPANY_OG_IMAGE_URL}}'],
  },

  // Canonical — self-canonical na root
  alternates: {
    canonical: 'https://{{DOMAIN}}',
    // Dodaj languages gdy multi-language (sekcja 6 SKILL.md)
    // languages: { 'pl': 'https://{{DOMAIN}}', 'x-default': 'https://{{DOMAIN}}' },
  },

  // Robots — domyślnie index + follow
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
    },
  },

  // Verification — dodaj po weryfikacji GSC
  // verification: { google: '{{GSC_VERIFICATION_CODE}}' },
}
```

---

## 2. `app/[locale]/blog/[slug]/page.tsx` — dynamic generateMetadata

```typescript
import type { Metadata } from 'next'

type Props = {
  params: { slug: string }
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  // Pobierz dane artykułu (CMS, DB, MDX frontmatter — zależnie od projektu)
  const post = await fetchPost(params.slug)

  if (!post) {
    return {
      title: 'Artykuł nie znaleziony',
      robots: { index: false, follow: false },
    }
  }

  return {
    title: post.title, // template z layout.tsx dokłada " | {{COMPANY_NAME}}"
    description: post.excerpt, // max 160 znaków

    openGraph: {
      type: 'article',
      title: post.title,
      description: post.excerpt,
      publishedTime: post.publishedAt.toISOString,
      modifiedTime: post.updatedAt.toISOString,
      authors: [`https://{{DOMAIN}}/autor/${post.authorSlug}`],
      images: [
        {
          url: post.coverImage || '{{COMPANY_OG_IMAGE_URL}}',
          width: 1200,
          height: 630,
          alt: post.title,
        },
      ],
    },

    // Canonical — bez parametrów UTM
    alternates: {
      canonical: `https://{{DOMAIN}}/blog/${params.slug}`,
    },
  }
}

export default function BlogPost({ params }: Props) {
  // ... komponent
}
```

---

## 3. `next-sitemap.config.js` z funkcją transform

```javascript
/** @type {import('next-sitemap').IConfig} */
module.exports = {
  siteUrl: 'https://{{DOMAIN}}',
  generateRobotsTxt: false, // robots.txt zarządzamy ręcznie (public/robots.txt)
  sitemapSize: 5000,         // Sitemap index gdy >5000 URLi per plik

  // Strony WYKLUCZONE z sitemap (mają noindex lub są prywatne)
  exclude: [
    '/admin/*',
    '/api/*',
    '/_next/*',
    '/draft/*',
    '/koszyk',
    '/checkout/*',
    '/login',
  ],

  // Funkcja transform — priority i changefreq per route pattern
  transform: async (config, path) => {
    // Home page
    if (path === '/') {
      return {
        loc: path,
        changefreq: 'weekly',
        priority: 1.0,
        lastmod: new Date.toISOString, // wyjątek — home się często zmienia
      }
    }

    // Strony usług — wysoki priority
    if (path.startsWith('/uslugi')) {
      return {
        loc: path,
        changefreq: 'monthly',
        priority: 0.9,
        // lastmod powinien być z DB/CMS — tu placeholder
        lastmod: config.autoLastmod ? new Date.toISOString : undefined,
      }
    }

    // Artykuły blogowe — najniższy priority, treść nie zmienia się
    if (path.startsWith('/blog')) {
      return {
        loc: path,
        changefreq: 'never', // artykuł po publikacji nie zmienia URL
        priority: 0.7,
        // WAŻNE: lastmod z faktycznej daty edycji, NIE new Date
        // Ustaw lastmod z fronmattera MDX lub z pola updatedAt w DB
        lastmod: undefined, // next-sitemap pomija gdy undefined
      }
    }

    // Strony statyczne (o nas, kontakt, etc.)
    return {
      loc: path,
      changefreq: 'yearly',
      priority: 0.5,
      lastmod: undefined,
    }
  },

  // Dodatkowe ścieżki dynamiczne (np. z DB) — opcjonalne
  // additionalPaths: async (config) => {
  //   const posts = await fetchAllPostSlugs
  //   return posts.map(slug => ({ loc: `/blog/${slug}` }))
  // },
}
```

---

## 4. Komponent `<JsonLd>` — SSR-safe JSON-LD

```typescript
// components/JsonLd.tsx
import { FC } from 'react'

interface JsonLdProps {
  data: Record<string, unknown>
}

/**
 * SSR-safe JSON-LD komponent.
 * Użyj w layout.tsx (Organization) lub page.tsx (Article, FAQPage, etc.)
 *
 * Przykład:
 * import schemaTemplates from '@/data/schema-templates.json'
 * <JsonLd data={schemaTemplates.Organization} />
 */
export const JsonLd: FC<JsonLdProps> = ({ data }) => {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data) }}
    />
  )
}
```

```typescript
// app/layout.tsx — użycie z schema-templates.json
import { JsonLd } from '@/components/JsonLd'
import schemaTemplates from '@/data/schema-templates.json'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pl">
      <body>
        {/* Organization schema — footerowy, zawsze w root layout */}
        <JsonLd data={schemaTemplates.Organization} />
        {children}
      </body>
    </html>
  )
}
```

```typescript
// app/blog/[slug]/page.tsx — Article schema dynamicznie
import { JsonLd } from '@/components/JsonLd'

export default async function BlogPage({ params }) {
  const post = await fetchPost(params.slug)

  const articleSchema = {
    ...schemaTemplates.Article,
    headline: post.title,
    author: { '@type': 'Person', name: post.authorName, url: post.authorUrl },
    datePublished: post.publishedAt.toISOString,
    dateModified: post.updatedAt.toISOString,
    image: post.coverImage,
  }

  return (
    <>
      <JsonLd data={articleSchema} />
      {/* reszta treści strony */}
    </>
  )
}
```

---

## 5. `middleware.ts` — Security headers

```typescript
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const response = NextResponse.next

  // Content Security Policy
  // WAŻNE: dostosuj do używanych third-party (GA4, GTM, fonts, etc.)
  const csp = [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' https://www.googletagmanager.com https://www.google-analytics.com",
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
    "font-src 'self' https://fonts.gstatic.com",
    "img-src 'self' data: https://www.google-analytics.com",
    "connect-src 'self' https://www.google-analytics.com https://analytics.google.com",
    "frame-ancestors 'none'",
  ].join('; ')

  response.headers.set('Content-Security-Policy', csp)
  response.headers.set('X-Frame-Options', 'SAMEORIGIN')
  response.headers.set('X-Content-Type-Options', 'nosniff')
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin')
  response.headers.set(
    'Permissions-Policy',
    'geolocation=, microphone=, camera=, payment='
  )
  response.headers.set(
    'Strict-Transport-Security',
    'max-age=31536000; includeSubDomains'
  )

  return response
}

// Stosuj do wszystkich ścieżek OPRÓCZ API routes i _next
export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
}
```

---

## 6. `public/robots.txt` — template gotowy do użycia

```text
# Robots.txt — {{DOMAIN}}
# Wygenerowano: {{DATE}}
# Zarządzaj ręcznie (next-sitemap generateRobotsTxt: false)

# Search engine crawlers — Allow
User-agent: Googlebot
Allow: /

User-agent: Bingbot
Allow: /

User-agent: DuckDuckBot
Allow: /

# AI crawlers — Disallow (content protection, decyzja Q3 seo-fundamentals brief)
# Aby włączyć AI visibility (np. Google AI Overview): zmień Disallow na Allow
# dla konkretnych botów lub usuń sekcję AI crawlers
User-agent: GPTBot
Disallow: /

User-agent: ChatGPT-User
Disallow: /

User-agent: anthropic-ai
Disallow: /

User-agent: ClaudeBot
Disallow: /

User-agent: CCBot
Disallow: /

User-agent: PerplexityBot
Disallow: /

# Pozostałe — standardowy dostęp, blokady techniczne
User-agent: *
Disallow: /api/
Disallow: /admin/
Disallow: /_next/
Disallow: /draft/
Disallow: /login
Disallow: /koszyk

# Sitemap declaration
Sitemap: https://{{DOMAIN}}/sitemap.xml
Sitemap: https://{{DOMAIN}}/sitemap-0.xml
```

---

## 7. Loading schema-templates.json — przykład substitution

```typescript
// scripts/fill-schema.ts — skrypt do wypełniania placeholderów
// Uruchom: ts-node scripts/fill-schema.ts > src/data/schema-filled.json

import templates from '../src/data/schema-templates.json'

const companyData = {
  COMPANY_NAME: 'Firma Budowlana XYZ Sp. z o.o.',
  COMPANY_URL: 'https://firma-xyz.pl',
  COMPANY_LOGO_URL: 'https://firma-xyz.pl/logo.png',
  COMPANY_PHONE: '+48 81 123 45 67',
  COMPANY_ADDRESS: 'ul. Przykładowa 1',
  COMPANY_CITY: 'Warszawa',
  COMPANY_POSTAL_CODE: '20-001',
  COMPANY_GEO_LAT: '51.2465',
  COMPANY_GEO_LNG: '22.5684',
  OPENING_HOURS: 'Mo-Fr 08:00-17:00',
  SOCIAL_PROFILES: JSON.stringify([
    'https://facebook.com/firma-xyz',
    'https://linkedin.com/company/firma-xyz',
  ]),
  PRICE_RANGE_OPTIONAL: '', // zostaw puste jeśli nie chcesz pokazywać
}

function fillTemplate(obj: unknown, data: Record<string, string>): unknown {
  const str = JSON.stringify(obj)
  const filled = str.replace(/\{\{(\w+)\}\}/g, (match, key) => data[key] ?? match)
  return JSON.parse(filled)
}

const filledTemplates = fillTemplate(templates, companyData)
console.log(JSON.stringify(filledTemplates, null, 2))
```
