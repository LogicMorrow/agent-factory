# dual-cta-patterns.md — jak ułożyć 2 CTA (freelance + job) bez konfliktu

5 wzorców rozwiązania dilemma "portfolio dla freelance vs dla job application". Każdy z trade-offs. Konsumowany przez `portfolio-content-writer` (E6) + `web-builder` portfolio mode (E8).

## Problem

Portfolio operatora ma 2 persony użytkownika:
1. **Pracodawca** — szuka full-time AI engineera, ocenia stability, cultural fit, team work
2. **Klient freelance** — szuka wykonawcy na projekt, ocenia track record, speed, expertise

Każda persona ma różne signals trust:
| Signal | Pracodawca | Klient freelance |
|---|---|---|
| Liczba klientów | Mniej istotne | Bardzo ważne |
| Stability (1 firma 3+ lat) | Bardzo ważne | Neutral |
| Track record portfolio | Ważne | Najważniejsze |
| "Open to opportunities" | Aktywny signal | Może odstraszyć ("samotnik") |
| Stack depth | Ważne | Ważne |
| Soft skills (team, comm) | Bardzo ważne | Mniej istotne |

## Pattern 1: Dual CTA side-by-side (REKOMENDACJA v1.0)

**Co:** 2 buttony obok siebie w sekcji Kontakt + reszta site neutralny.

**Markup:**

```tsx
<section id="kontakt" className="contact">
  <h2>Pracujmy razem</h2>
  <p className="muted">Wybierz, co Cię tu sprowadziło:</p>

  <div className="cta-dual">
    <a
      href="mailto:you@example.com?subject=Projekt%20freelance%20—%20[temat]&body=Cześć%20operator,%0A%0AInteresuje%20mnie%20współpraca%20przy%20projekcie:%0A%0A[opisz%20projekt]"
      className="cta cta--primary"
    >
      <strong>Wynajmij na projekt</strong>
      <span>Cold mailing setup · agent AI · analytics dashboard</span>
    </a>
    <a
      href="mailto:you@example.com?subject=Aplikacja%20full-time%20—%20[stanowisko]&body=Cześć%20operator,%0A%0AChciałbym%20porozmawiać%20o%20stanowisku:%0A%0A[stanowisko%20+%20firma]"
      className="cta cta--secondary"
    >
      <strong>Zatrudnij full-time</strong>
      <span>AI engineer · data analyst · B2B sales hybrid</span>
    </a>
  </div>
</section>
```

**Plus:**
- ✅ Najprościej (zero JS, zero state)
- ✅ User wybiera, czytelne separation
- ✅ Subject line w mailto: → operator wie który kanał

**Minus:**
- ❌ operator musi rozróżniać 2 typy maili (mała friction po stronie odbiorcy)
- ❌ Reszta site (hero, o-mnie) musi być neutral (nie skłaniać do jednego)

**Kiedy używać:** MVP v1.0 (operator).

## Pattern 2: Persona toggle UI (v1.1 opt-in)

**Co:** w hero/nav switch "Wynajmij vs Zatrudnij", site reaguje content per mode.

**Markup koncept:**

```tsx
const [persona, setPersona] = useState<'freelance' | 'job'>('freelance')

<header>
  <div className="persona-toggle">
    <button
      onClick={ => setPersona('freelance')}
      aria-pressed={persona === 'freelance'}
      className={persona === 'freelance' ? 'active' : ''}
    >
      Szukam wykonawcy projektu
    </button>
    <button
      onClick={ => setPersona('job')}
      aria-pressed={persona === 'job'}
      className={persona === 'job' ? 'active' : ''}
    >
      Szukam pracownika full-time
    </button>
  </div>
</header>

<section className="hero">
  {persona === 'freelance' ? (
    <h1>Buduję narzędzia AI dla B2B SaaS</h1>
  ) : (
    <h1>AI engineer · analityk · B2B sales hybryda</h1>
  )}
</section>
```

**Plus:**
- ✅ Każda persona widzi customized copy
- ✅ Pokazuje professional UX awareness

**Minus:**
- ❌ Friction — user musi kliknąć przed czytaniem
- ❌ JS state + duplikacja content
- ❌ SEO challenge (Googlebot widzi jeden default state)
- ❌ Persistence przez `localStorage` — extra code

**Kiedy używać:** v1.1+ jeśli analytics pokaże, że jeden CTA conversion znacznie wyższy.

## Pattern 3: Hero z "either / or" (jeden CTA primary + secondary)

**Co:** hero ma głównie 1 CTA (np. "Wynajmij na projekt"), a "lub: aplikuj full-time" jako drugorzędny link.

**Markup:**

```tsx
<section className="hero">
  <h1>Buduję agenty AI dla sprzedaży B2B</h1>
  <p>Hybryda kompetencji: AI engineering · analityka · sprzedaż.</p>

  <a href="mailto:..." className="cta cta--primary">
    Porozmawiajmy o Twoim projekcie
  </a>

  <p className="hero__alt">
    Szukasz pracownika full-time? <a href="#kontakt-fulltime">Aplikuj tutaj</a>
  </p>
</section>
```

**Plus:**
- ✅ Jasny primary path (freelance)
- ✅ Drugorzędny opt-in dla pracodawców (mniej friction)

**Minus:**
- ❌ Pracodawca może czuć się drugorzędny ("oh, on woli freelance")
- ❌ Jeden CTA dominuje site identity

**Kiedy używać:** jeśli operator prioritises freelance > full-time (analiza intent — KPI 70/30).

## Pattern 4: Two separate URLs (anti-pattern w MVP)

**Co:** `operator.dev/freelance` + `operator.dev/job` jako osobne strony.

**Plus:**
- ✅ Pełna customizacja per persona
- ✅ SEO separation

**Minus:**
- ❌ Duplikacja content (case studies same, ale o-mnie różne)
- ❌ Maintenance overhead (2 sites)
- ❌ User musi wybrać URL — friction

**Kiedy używać:** NIE w MVP. Może w v2 jeśli wymagane.

## Pattern 5: Single CTA + landing pages per intent (advanced)

**Co:** hero ma generic "Kontakt" CTA, ale różne content paths (`/uslugi`, `/o-mnie`, `/case-studies`) dla różnych intent.

**Plus:**
- ✅ Neutral hero
- ✅ User naturally trafia do właściwej sekcji

**Minus:**
- ❌ Wymaga multi-page site (MVP single-page)
- ❌ Conversion path dłuższy

**Kiedy używać:** v2 jeśli portfolio rozrośnie się w blog + courses + multiple service pages.

## Pre-fill mailto: body — wzór

Z Pattern 1 (REKOMENDACJA):

```
mailto:you@example.com?subject=[SUBJECT]&body=[BODY]
```

**Freelance subject:**
```
Projekt freelance — [temat]
```

**Freelance body (URL-encoded):**
```
Cześć operator,

Interesuje mnie współpraca przy projekcie:

[opisz projekt — branża, zakres, deadline]

Budżet: [opcjonalnie]
Start: [data]

Pozdrawiam,
[Twoje imię]
```

URL-encoded:
```
Cze%C5%9B%C4%87%20operator%2C%0A%0AInteresuje%20mnie%20wsp%C3%B3%C5%82praca%20przy%20projekcie%3A%0A%0A%5Bopisz%20projekt%5D
```

**Job subject:**
```
Aplikacja full-time — [stanowisko]
```

**Job body:**
```
Cześć operator,

Chciałbym porozmawiać o stanowisku [stanowisko] w [firma].

O firmie: [krótko]
Stack: [stack tech]
Lokalizacja: [remote / hybrid / on-site]
Budżet: [widełki]

Możemy umówić call?

Pozdrawiam,
[Twoje imię]
```

## Anti-patterns dual CTA

### Anti 1: 3+ CTA buttons w jednej sekcji

```
[Wynajmij na projekt]  [Zatrudnij full-time]  [Skontaktuj się]  [Pobierz CV]  [LinkedIn]
```

**Dlaczego ŹLE:** Hick's Law — więcej opcji = wolniejsza decyzja = brak action.

**DOBRZE:** Max 2 CTA primary + alternatywy w footer.

### Anti 2: CTA z brand voice mismatch

```
[💼 Hire me!] [📨 Let's chat about your dream project!]
```

**Dlaczego ŹLE:**
- Code-switching PL→EN
- Emoji corporate
- "Dream project" = empty buzzword

**DOBRZE:** Konkretny copy w PL (`Wynajmij na projekt` + descriptor 1 linii).

### Anti 3: "Open to opportunities" baner

Jeśli używasz LinkedIn-style baner "Open to work" w portfolio:
- Pracodawca: signal że jesteś desperate
- Klient freelance: signal że szukasz full-time (= unavailable długoterminowo)

**DOBRZE:** brak banner. CTA wystarcza.

### Anti 4: Kontradyktoryjne sygnały

```
Hero: "Buduję narzędzia dla B2B SaaS (freelance)"
O mnie: "Szukam stabilnego full-time job w startupie"
```

User confused. Wybierz jeden ton lub Pattern 2 (toggle).

## Decision tree dla operatora

```
Czy chcesz portfolio MVP w 1 tygodniu?
├── TAK → Pattern 1 (dual CTA side-by-side) ✅ REKOMENDACJA v1.0
└── NIE, mam czas na advanced UX
    ├── Pattern 2 (persona toggle) — jeśli budgetujesz JS state + a11y testing
    └── Pattern 3 (primary + secondary) — jeśli wiesz że 70/30 split freelance/job
```

## operator default decision (per karta projektu)

**Pattern 1** (dual CTA side-by-side) w MVP v1.0.
**Pattern 2** (persona toggle) opt-in w v1.1 jeśli analytics pokaże low conversion (< 5%).

## Status

v1.0.0 (2026-05-13) — 5 patterns + decision tree. Update wraz z analytics post-deploy.
