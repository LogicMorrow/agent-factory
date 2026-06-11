---
name: personal-branding-portfolio-pl
description: "Wzorce narracji portfolio PL dla profesjonalistów hybrydowych (np. AI engineer + analityk + B2B sales). 5 sekcji standardowych + dual CTA (freelance + job) + case-study template + about-me patterns. Konsumowany przez portfolio-content-writer (E6 paczki portfolio), web-builder portfolio mode (E8). NIE używać do: czystego CV (→ cv-builder z paczki example-pack), korpo-bio (LinkedIn/Goldenline), kursów online (→ course-landing-patterns dla v2)."
version: 1.0.0
compatible_with: [universal, webapp]
tags: [portfolio, personal-branding, content, narrative, polish, dual-cta]
requires: [polish-typography]
token_cost: low
distribution: library/skills/universal/
last_updated: 2026-05-13
---

# personal-branding-portfolio-pl

Wzorce narracyjne portfolio PL — jak prezentować "kim jestem" i "co robię" tak, żeby w 60s zarówno pracodawca, jak i klient freelance widzieli wartość. Filozofia: **konkret > buzzword**, **show-don't-tell**, **osobowość > corporate-speak**.

**Bundle pliki:**
- `SKILL.md` — 5 sekcji + zasady narracji (ten plik)
- `case-study-template.md` — szablon "Problem→Approach→Tools→Outcome→Lessons" z 3 placeholder case'ami
- `about-me-patterns.md` — patterny "O mnie" 2026 (good/bad/ugly)
- `dual-cta-patterns.md` — jak ułożyć 2 CTA bez konfliktu freelance vs job

## When to use this skill

Uruchamiaj gdy:
- `portfolio-content-writer` (E6) generuje copy 5 sekcji
- `web-builder --mode=portfolio` (E8) projektuje structure (kolejność sekcji)
- operator pisze sekcję manualnie i chce reference do struktury
- `polish-proofreader` chce kontekstu domeny (whitelist AI/B2B terms)

## Pre-execution context loading

Agent konsumujący ma czytać:
- `polish-typography/common-errors.md` (lint przed publish)
- `polish-typography/SKILL.md` (whitelist AI terms)
- Karta projektu `knowledge-base/projects/portfolio-operator.md` (cel, deal-breakers, persony)
- `portfolio-design-patterns/SKILL.md` (Wzorzec 5 Case-Study + Wzorzec 6 CTA-dual)

## 5 sekcji standardowych portfolio PL 2026

### Sekcja 1: HERO

**Cel:** w 5 sekundach user wie "kim jesteś" + "co oferujesz".

**Struktura:**
- Imię + nazwisko (lub pseudonim profesjonalny)
- 1-zdaniowy tagline (3-7 słów)
- 2 CTA (Wynajmij na projekt + Zatrudnij full-time)
- Opcjonalnie: wideo 30s w tle/obok

**Tagline — wzór:**

**Format A:** `[Tytuł zawodowy hybrydowy]`
- "AI engineer · analityk · B2B sales"
- "Full-stack dev z domeną fintech"

**Format B:** `Pomagam [persona] zrobić [outcome]`
- "Pomagam founderom skalować B2B outreach z AI"
- "Automatyzuję powtarzalną pracę dla małych zespołów"

**Format C:** `[Verb] + [domena]`
- "Buduję agenty AI dla sprzedaży B2B"
- "Projektuję analytics dashboards dla SaaS"

**Anti-tagline (NIE rób):**
- "Passionate about innovation and synergy" (corporate-speak, AI-generated vibe)
- "Full-stack developer | React expert | Cloud enthusiast" (kupowanie ofert, brak focus)
- "I love coding ❤️" (zero info)

### Sekcja 2: O MNIE (about)

**Cel:** kontekst osobisty + dlaczego ta hybryda kompetencji ma sens.

**Długość:** 80-150 słów (max 200).

**Struktura (3 akapity):**

1. **Co robię (1 akapit, 30-50 słów):** dziedziny + kombinacja kompetencji.
2. **Dlaczego ta hybryda (1 akapit, 30-50 słów):** krótka historia jak doszło do połączenia obszarów.
3. **Wartość dla klienta/pracodawcy (1 akapit, 20-40 słów):** co user ma z tego, że jesteś hybrydą.

**Przykład dobry (operator):**

> Buduję agenty AI dla sprzedaży B2B, projektuję analytics dashboards i piszę cold maile, które konwertują. Pracuję na styku trzech światów: kodu, danych i komunikacji z klientem.
>
> Zacząłem od sprzedaży B2B w branży tech (3 lata), potem doszły dane (Python, SQL, pandas), a w 2024 wciągnęła mnie inżynieria AI — Claude API, Anthropic SDK, agenty autonomous workflows. Hybryda powstała organicznie, bo każdy mój kolejny projekt potrzebował wszystkich tych rzeczy naraz.
>
> Jeśli budujesz B2B SaaS lub potrzebujesz automatyzacji procesów sprzedaży i analytics, dostajesz jedną osobę zamiast trzech. Mniej koordynacji, więcej kontekstu między obszarami.

**Przykład zły (NIE rób):**

> Pasjonat technologii i komunikacji, dynamiczny specjalista łączący kompetencje analityczne, sprzedażowe i programistyczne. Z zaangażowaniem podejmuję wyzwania w obszarze sztucznej inteligencji oraz transformacji cyfrowej. Otwarty na nowe projekty.

(Powód: 100% buzzword, zero konkretu, mogłaby napisać AI.)

### Sekcja 3: CO ROBIĘ (kompetencje)

**Cel:** 4-6 obszarów kompetencji + konkret per obszar.

**Layout:** karty / lista z ikona + nazwa + 1-2 zdania + 3-5 tools.

**Wzorzec operator:**

| Obszar | Tools/Tech | Przykład use case |
|---|---|---|
| **Analityka danych** | Python, pandas, SQL, Metabase, Looker | Dashboard konwersji lejka sprzedażowego |
| **Sprzedaż B2B + cold mailing** | Apollo, Lemlist, LinkedIn SN, Smartlead | Pipeline outreach 500 prospektów/tyg |
| **Inżynieria AI (CC + LLM agents)** | Claude API, Anthropic SDK, MCP, n8n, Python | Autonomous workflows z Claude Sonnet 4.6 |
| **Grafika i wideo AI (hobby)** | Midjourney, Runway, Stable Diffusion, Suno | Personal projects, eksperymenty, testy własne |

**Reguły:**
- **Konkretne tools, nie generic** ("Python pandas" zamiast "data analysis")
- **Use case obok każdego obszaru** — pokazuje że robisz, nie tylko czytałeś
- **Hobby oddzielony od professional** (nie miesz "Power BI" z "Midjourney" jednej kategorii)
- **Max 4-6 kart** — więcej = "jack of all trades, master of none"

### Sekcja 4: CASE STUDIES

**Cel:** głębia > szerokość. 3 case'y, każdy z 5-elementowym layoutem.

**Patrz:** `case-study-template.md` w tym bundle dla pełnego szablonu.

**Constraints:**
- 3 case'y MAX w MVP (4-5 w v1.1, jeśli wystarczająco materiału)
- Każdy 200-400 słów (NIE essay-length, NIE one-liner)
- Per case: 1 screenshot / wideo demo / link do live demo (jeśli możliwe)
- Lessons sekcja MA być (pokazuje pokorę i naukę z error'ów)

**Anti-pattern:** "Pracowałem z firmami: Coca-Cola, Microsoft, IBM..." (logo wall bez kontekstu). Wybierz 3 i opowiedz konkretnie.

### Sekcja 5: KONTAKT (z dual CTA)

**Cel:** clear next step + brak friction.

**Layout:**
- Headline: "Pracujmy razem" (lub "Zacznijmy rozmowę")
- 2 CTA buttons side-by-side (patrz `dual-cta-patterns.md`)
- Alternatywa: bezpośredni email + LinkedIn + GitHub
- NIE form (form = lead generation = lead-gen friction)
- Update timestamp ("Ostatnia aktualizacja: maj 2026") — pokazuje active

**Footer:**
- "Made by operator · 2026" + GitHub link do source (transparency, dev cred)
- Opcjonalnie: licencja content (CC-BY-NC 4.0) jeśli copy reusable

## Zasady narracji PL portfolio

### Zasada 1: Konkret > buzzword

| ŹLE | DOBRZE |
|---|---|
| "Doświadczony w transformacji cyfrowej" | "Wdrożyłem dashboard analityczny w 3 firmach SaaS" |
| "Pasjonat AI" | "Buduję agenty Claude Code, mam 2 produkcyjne wdrożenia" |
| "Synergia między domenami" | "Łączę 3 lata sprzedaży B2B z Python/SQL — robię to, czego CRM nie potrafi" |

### Zasada 2: "Ja zbudowałem" > "stworzono", "powstał"

PL ma tendencję do strony biernej w korpo-bio. Portfolio = osobiste = aktywne.

| ŹLE (passive) | DOBRZE (active) |
|---|---|
| "Został zbudowany agent AI" | "Zbudowałem agenta AI" |
| "Powstał dashboard dla klienta" | "Zaprojektowałem dashboard dla klienta" |
| "Zostały zautomatyzowane procesy" | "Zautomatyzowałem procesy" |

### Zasada 3: Showcase, nie inwentarz

| ŹLE (inwentarz) | DOBRZE (showcase) |
|---|---|
| "Skills: Python, SQL, JavaScript, React, Vue, Angular..." | "Najczęściej używam: Python (analytics), TypeScript (web), Claude API (AI agents)" |
| "Lista technologii: 25+ frameworków" | "3 stacki, w których jestem szybki: Python+pandas, Next.js+Tailwind, Claude Code" |

**Reguła:** wybierz top 3-5, opowiedz konkretnie. NIE wymieniaj wszystkiego, czego się tknąłeś.

### Zasada 4: Pokora przez Lessons sekcję

Case studies MAJĄ sekcję "Lessons" — co byś zmienił, gdybyś powtarzał. To buduje trust ("ten gość się uczy") zamiast "perfect outcome każdy raz".

**Przykład:**

> Lessons: Pierwsza wersja agenta wysyłała 10x maile/min, co triggerowało rate-limit Smartlead. Następnym razem zacznę od limitera (5/min) zamiast optymalizować po incidente.

### Zasada 5: Voice consistency

**Voice operator (przykład):**
- Krótkie zdania (max 20 słów)
- Pierwsza osoba liczba pojedyncza
- Konkretne liczby (3 firmy, 500 prospektów, 8% → 19% CTR)
- Bez wykrzykników (poważny ton)
- Lekka pewność siebie (NIE "jestem najlepszy w PL", ale NIE "może mogę pomóc")
- Anglicyzmy zaakceptowane w domain (cold mailing, prompt, agent, freelance)
- Polskie znaki + interpunkcja na poziomie (operator świadomy — patrz polish-typography skill)

**Anti-voice:**
- Brak "kreatywny", "innowacyjny", "dynamiczny" (corporate buzzwords)
- Brak "z radością", "mam przyjemność" (zbyt formalne)
- Brak emoji w copy MVP (poważny ton; emoji ok w hobby section v1.1)

## Lokalne nuanse PL

### Adres do usera

- **"Ty"** (forma neutralna 2026, używaj domyślnie)
- **"Państwo"** tylko jeśli target enterprise (operator: NIE — target SaaS founders / hiring managers)
- **"Ja"** jest OK ("Zbudowałem", "Pracuję") — to portfolio osobiste

### Kontakt — preferred channel

- **Email primary** (mailto:) — najmniej friction, sprawdzony w PL B2B
- **LinkedIn secondary** — high signal dla rekruterów PL
- **GitHub** — kredencjały dev (commit history > CV)
- **X (Twitter)** — opcjonalne (PL X-Twitter jest niche, ale signal dla AI/dev community)
- **Telefon** — NIE w portfolio public (spam risk, friction)
- **WhatsApp** — NIE (zbyt informalne dla pierwszego kontaktu)

### Cena/wycena

- **NIE umieszczaj price list** w portfolio (lock-in vs negotiation)
- Sekcja "Współpraca" lub "FAQ" może zawierać: "Pracuję na MVP od 5k zł, full project od 20k zł — finalna wycena po briefing call" (opcjonalne v1.1)
- **VAT:** operator prowadzi działalność → ceny netto + "+ VAT 23%" w komunikacji finansowej (NIE w portfolio public)

## Hobby section — jak nie zaszkodzić professional

**Risk:** sekcja "AI generated grafika/wideo" może wyglądać jak rozproszenie ("jack of all trades").

**Mitigation:**
- Wyraźnie oddzielony nagłówek: "Hobby & eksperymenty" (NIE "Inne kompetencje")
- 1 akapit kontekstu: "Robię to dla zabawy, eksperymentów AI, nie świadczę usług produkcyjnie"
- 3-5 sample obrazów/wideo (lightbox gallery)
- Link do social profile jeśli operator publikuje na Twitter/Instagram

**Bonus:** hobby AI grafika = social proof "ten gość naprawdę gra z AI, nie tylko czyta o tym".

## Anti-narratives (czego NIE pisać)

### Anti 1: "Self-taught" jako wymówka

```
ŹLE: "Jestem self-taught, więc mam luki, ale uczę się szybko."
```
Brak potrzeby wybijania. Jeśli portfolio pokazuje wyniki, czy self-taught vs uniwer — irrelevant.

### Anti 2: "Otwarty na nowe wyzwania"

Tak wszyscy. Konkret: "Chcę pracować nad B2B SaaS z AI integration, najchętniej w stage Series A-C."

### Anti 3: Lista certyfikatów bez kontekstu

```
ŹLE: "Certyfikaty: AWS, GCP, Coursera Machine Learning, edX Python..."
```
Cert ≠ kompetencja. Pokaż projekt, nie cert.

### Anti 4: Wykorzystanie cudzych logos bez explicit zgody

NIE umieszczaj logo klientów dla których pracowałeś bez ich pisemnej zgody (PL GDPR + business relation respect). operator: NIE wymieniaj nazw klientów bez wcześniejszej zgody.

## Procedury (use case)

### Procedura A: portfolio-content-writer (E6) generuje sekcję

1. Read karta projektu + ten skill + polish-typography
2. Per sekcja: apply structure z tego skilla
3. Generate 2 warianty (freelance + job tone) lub jeden hybrydowy
4. **HITL gate:** wszystkie cytaty motywacyjne / claim'y MUSZĄ być verified (operator approve fakty)
5. Lint polish-proofreader → apply patches
6. Save do `portfolio/content/<section>.mdx`

### Procedura B: manual update portfolio (operator sam pisze)

1. Open `<section>.mdx`
2. Refer to `SKILL.md` (ten plik) + `about-me-patterns.md` per sekcja
3. Po edycie: `/proofread-pl portfolio/content/<section>.mdx`
4. Review propozycji, apply approved

## Status

v1.0.0 (2026-05-13) — initial release dla paczki `af-pack-<nazwa>` (E4). Update q+1 wraz z lessons od operatora po deploy.

## Cross-reference

- `case-study-template.md` — pełen template Problem→Approach→Tools→Outcome→Lessons
- `about-me-patterns.md` — good/bad/ugly examples
- `dual-cta-patterns.md` — jak ułożyć freelance + job CTA bez konfliktu
- `polish-typography/SKILL.md` — interpunkcja + AI whitelist terms
- `portfolio-design-patterns/SKILL.md` Wzorzec 5+6 — visual layout per sekcja
