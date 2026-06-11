# case-study-template.md — szablon Problem→Approach→Tools→Outcome→Lessons

Pełen template case study dla portfolio operatora + 3 placeholder case'y do wypełnienia. Konsumowany przez `portfolio-content-writer` (E6) — agent generuje copy zgodnie z tym szablonem.

## Szablon ogólny (markdown / MDX)

```mdx
## [Case study #N] — [Tytuł case study, np. "Automatyzacja cold mailingu B2B dla SaaS Series A"]

**Klient/projekt:** [Nazwa LUB anonimizowane "SaaS Series A z branży fintech"]
**Rola:** [Freelance / Full-time / Pro-bono / Personal project]
**Czas trwania:** [np. 3 tygodnie / 6 miesięcy / ongoing]
**Status:** [W produkcji / Zakończone / Archived]

### Problem

[1-2 zdania o realnym problemie biznesowym, NIE technicznym]

Przykład:
> Manualny outreach do 500 prospektów/miesiąc zajmował 20h/tydz. Zespołowi sprzedażowemu kończył się czas na qualifying calls.

### Approach

[2-4 zdania o podejściu — co zrobiono, co odrzucono, dlaczego]

Przykład:
> Zbudowałem pipeline: scraper (LinkedIn Sales Navigator) → enrichment (Apollo API) → personalization (Claude API) → send (Smartlead) → tracking (PostgreSQL + Metabase).
>
> Odrzuciłem ChatGPT API ze względu na strict rate limits dla bulk personalization. Claude Sonnet 4.6 lepszy w PL business writing.

### Tools

[Lista 3-7 konkretnych narzędzi/technologii. Konkret > generic.]

- **Backend:** Python 3.12, FastAPI, PostgreSQL 16
- **AI:** Claude API (Sonnet 4.6), Anthropic SDK Python
- **Data:** Apollo API (enrichment), LinkedIn Sales Navigator (scrape)
- **Email:** Smartlead (send + tracking)
- **Analytics:** Metabase + Plausible

### Outcome

[Metryka + przykład. NIE buzzwords, KONKRETNE liczby. Screenshot/wideo demo opcjonalnie.]

Przykład:
> - Czas spadł z 20h → 3h/tydz (87% redukcja)
> - CTR maili: 8% → 19% (A/B test 200/200, p < 0.01)
> - Pipeline value: +€45k MRR w 3 miesiące
> - Zespół sprzedażowy: 80% czasu na qualifying calls (vs 20% pre-projekt)

[Opcjonalnie: screenshot dashboard lub demo wideo case-study-N.mp4]

### Lessons

[1-2 zdania — co byś zmienił, gdybyś robił to ponownie. Pokora = trust.]

Przykład:
> Pierwsza wersja agenta wysyłała 10x maile/min, co triggerowało rate-limit Smartlead. Następnym razem zacznę od limitera (5/min) zamiast optymalizować po incidente.
>
> Druga lekcja: HITL gate dla personalizacji był overkill dla 95% przypadków, ale 5% case'ów wymagało interwencji (zbyt formalny ton). Tradeoff trzeba balansować per industry.

### [Opcjonalnie] Link / demo

- 🔗 Live demo: [link jeśli dostępny]
- 📂 Source: [GitHub repo jeśli public]
- 📝 Blog post: [link do długiego opisu, jeśli istnieje]
```

## Placeholder case'y dla portfolio operatora (do wypełnienia)

### Case study #1 (placeholder) — Cold mailing B2B z AI personalization

**Klient/projekt:** [operator uzupełnia: konkretny SaaS lub anonimizowany]
**Rola:** Freelance
**Czas trwania:** [TBD]
**Status:** [TBD]

**Problem.** [operator: opisz realny problem outreach, np. ROI, czas, conversion]

**Approach.** [operator: pipeline + decyzje techniczne + co odrzucono]

**Tools.**
- Python (FastAPI / scripts)
- Claude API (Sonnet 4.6 dla PL writing)
- Apollo / LinkedIn Sales Nav
- Smartlead / Lemlist
- PostgreSQL / SQLite local
- Metabase / Plausible

**Outcome.** [operator: konkretne metryki, A/B test results]

**Lessons.** [operator: co byś zmienił]

---

### Case study #2 (placeholder) — Analytics dashboard dla B2B SaaS

**Klient/projekt:** [operator uzupełnia]
**Rola:** [Freelance / Full-time]
**Czas trwania:** [TBD]

**Problem.** [operator: jaki problem analytics? Np. brak insight do churn, ROI niskich marży, etc.]

**Approach.** [operator: ETL? Real-time? Dashboards co dla kogo?]

**Tools.**
- Python + pandas
- SQL (PostgreSQL / BigQuery / Snowflake)
- Metabase / Looker / Power BI
- Airflow / Dagster (jeśli ETL)

**Outcome.** [operator: time-to-insight, decisions enabled, ROI]

**Lessons.** [operator]

---

### Case study #3 (placeholder) — AI agent autonomous workflow

**Klient/projekt:** [operator uzupełnia, może być personal/portfolio project]
**Rola:** [TBD]
**Czas trwania:** [TBD]

**Problem.** [operator: co automatyzuje agent? Jakie human-in-loop overhead było wcześniej?]

**Approach.** [operator: architektura agentowa — Claude Code? Anthropic SDK? n8n? MCP? Tool calling?]

**Tools.**
- Claude API (Sonnet 4.6 / Opus 4.7)
- Anthropic SDK Python/TypeScript
- MCP (Model Context Protocol) jeśli używasz
- n8n / Zapier (orchestration)
- Claude Code (jeśli developer-facing)

**Outcome.** [operator: czas zaoszczędzony, tasks automated, error rate]

**Lessons.** [operator]

## Wytyczne wypełnienia (operator)

### Dobre vs złe Outcome

| ŹLE (vague) | DOBRZE (concrete) |
|---|---|
| "Wzrost konwersji" | "CTR 8% → 19% (A/B test, n=400, p<0.01)" |
| "Oszczędność czasu" | "20h/tydz → 3h/tydz (87% redukcja)" |
| "Poprawa procesów" | "Time-to-decision dla CEO: 5 dni → 1h" |
| "Klient zadowolony" | "Klient kontynuuje współpracę 18 mies, +2 referrale" |

### Dobre vs złe Lessons

| ŹLE (perfect) | DOBRZE (uczciwie) |
|---|---|
| "Wszystko poszło idealnie" | "Rate-limit Smartlead nie był uwzględniony w MVP" |
| "Klient był zachwycony od day 1" | "Pierwszy demo był za techniczny, drugi pokazałem outcome-first" |
| "Nic bym nie zmienił" | "Dodałbym HITL gate dla 5% edge case'ów ton komunikacji" |

### Anonimizacja klientów

Jeśli nie masz pisemnej zgody na publikację nazwy:
- "SaaS Series A z branży fintech (40 osób)"
- "Marketplace e-commerce skalujący do EU"
- "Agencja marketingowa z 12 klientami B2B"

NIE używaj real names bez zgody (GDPR + business respect).

### Screenshoty/demo wideo

- 1 visual per case'a max (więcej = scroll fatigue)
- WebP > JPEG > PNG (rozmiar)
- Anonimizuj PII na screenshotach (blur emails, names)
- Jeśli demo wideo: max 2 min, captions VTT (per video-web-integration skill)

## Status

v1.0.0 (2026-05-13) — initial template + 3 placeholder case'y. operator wypełnia w E12 bootstrap lub później.
