# C4 Model — Wprowadzenie (1 strona)

C4 to sposób na hierarchiczne dokumentowanie architektury oprogramowania. Cztery poziomy, każdy dla innej audiencji.

## Cztery poziomy

| Poziom | Nazwa | Pytanie | Audiencja |
|--------|-------|---------|-----------|
| **L1** | System Context | Gdzie jest nasz system w szerszym ekosystemie? | Management, product, nowi deweloperzy |
| **L2** | Container | Z czego składa się system (procesy, bazy, kolejki)? | Wszyscy deweloperzy |
| **L3** | Component | Z czego składa się konkretny kontener? | Deweloperzy tego kontenera |
| **L4** | Code | Jak wygląda implementacja? | Code review — zazwyczaj UML klas |

**W praktyce:** L4 prawie nigdy nie robimy (generuje się z kodu). Koncentruj się na L1-L3.

---

## Przykład myślowy

Wyobraź sobie CRM z Next.js frontendem, Hono backendem, PostgreSQL i Redis:

**L1 — kto używa i z czym integrujemy:**
```
[Użytkownik] → [CRM System] → [Resend SMTP]
[Admin]       ↗              → [S3 Storage]
```

**L2 — co jest w środku:**
```
[CRM System]
├── [Frontend: Next.js :3000]
├── [Backend API: Hono :4000]
├── [Database: PostgreSQL :5432]
└── [Cache: Redis :6379]
```

**L3 — co jest w Backend API:**
```
[Backend API]
├── [Auth Middleware]
├── [Users Router]
├── [Posts Router]
├── [DB Client (postgres.js)]
└── [Cache Client (ioredis)]
```

---

## Kluczowe zasady C4

1. **Każdy blok ma tytuł, typ i krótki opis** — nie tylko nazwa.
2. **Każda strzałka ma etykietę** — protokół, technologia, kierunek przepływu.
3. **Granica systemu jest jawna** — co jest w granicach, co poza.
4. **Jeden diagram = jeden poziom** — nie mieszaj L1 i L2 na jednym diagramie.
5. **Mermaid C4 na GitHub renderuje się natywnie** — preferuj, fallback do PlantUML tylko gdy złożoność wymaga.

---

## Kiedy który poziom w projekcie

| Poziom dojrzałości | Obowiązkowy | Opcjonalny |
|-------------------|-------------|------------|
| L1 (MVP) | System Context (C4 L1) | — |
| L2 (production) | + Container (C4 L2), Sequence (auth), ERD | — |
| L3 (scale) | + Deployment topology | Component (C4 L3) dla złożonych modułów |

---

## Typowe błędy

- **Pominięcie zewnętrznych systemów na L1** — diagram wygląda jak system w próżni. Zawsze pokaż SMTP, storage, OAuth, zewnętrzne API.
- **Zbyt dużo detali na L2** — kontener to proces lub store (baza, cache). Nie metody, nie klasy.
- **Niespójne nazewnictwo** — ten sam komponent nazwany inaczej na L1 i L2. Używaj tych samych nazw między poziomami.
- **Brak etykiet na strzałkach** — "co idzie od A do B?" bez etykiety = niejasność po 3 miesiącach.

---

## Zasoby

- Oficjalna strona: https://c4model.com (Simon Brown)
- Mermaid C4: https://mermaid.js.org/syntax/c4.html
- PlantUML C4 stdlib: https://github.com/plantuml-stdlib/C4-PlantUML

Snippety gotowe do użycia: [`mermaid-examples.md`](./mermaid-examples.md)
