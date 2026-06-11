---
# front-matter opcjonalny dla overview.md
last_updated: YYYY-MM-DD
docs_maturity_level: L2
related: []
---

# Architecture Overview — <PROJEKT>

> Dokument utrzymywany ręcznie. Aktualizuj przy każdej zmianie architektury lub nowym ADR `kind: infrastructure`.
> Ostatnia aktualizacja: YYYY-MM-DD

---

## 1. System Context (C4 Level 1)

<!--
C4 Context: pokazuje system i jego użytkowników/zewnętrzne systemy.
Szablon Mermaid poniżej — patrz też references/mermaid-examples.md dla pełnych snippetów.
-->

```mermaid
C4Context
    title System Context — <PROJEKT>
    Person(user, "Użytkownik", "Opis użytkownika")
    System(system, "<PROJEKT>", "Opis systemu — co robi w jednym zdaniu")
    System_Ext(ext1, "<Zewnętrzny system>", "Opis")
    Rel(user, system, "Używa")
    Rel(system, ext1, "Wywołuje API")
```

**Granice systemu:** ...
**Zewnętrzne integracje:** ...

---

## 2. Container View (C4 Level 2) *(L2+)*

<!--
C4 Container: rozbija system na kontenery (procesy, usługi, bazy danych).
Obowiązkowy od L2.
-->

```mermaid
C4Container
    title Container Diagram — <PROJEKT>
    Person(user, "Użytkownik")
    Container(frontend, "<Frontend>", "<tech stack>", "Opis")
    Container(backend, "<Backend API>", "<tech stack>", "Opis")
    ContainerDb(db, "<Database>", "<engine>", "Opis")
    Container(cache, "<Cache>", "<engine>", "Opis")
    Rel(user, frontend, "HTTP/HTTPS")
    Rel(frontend, backend, "REST/tRPC")
    Rel(backend, db, "SQL/ORM")
    Rel(backend, cache, "Redis protocol")
```

---

## 3. Tech Stack

| Warstwa | Technologia | Wersja | Uzasadnienie / ADR |
|---------|-------------|--------|--------------------|
| Frontend | <np. Next.js> | <wersja> | [ADR-NNNN](<ścieżka>) |
| Backend API | <np. Hono> | <wersja> | [ADR-NNNN](<ścieżka>) |
| Database | <np. PostgreSQL> | <wersja> | [ADR-NNNN](<ścieżka>) |
| Cache | <np. Redis> | <wersja> | [ADR-NNNN](<ścieżka>) |
| Hosting | <np. VPS + Docker> | — | [ADR-NNNN](<ścieżka>) |
| Auth | <np. JWT / NextAuth> | <wersja> | [ADR-NNNN](<ścieżka>) |

---

## 4. Key Flows *(L2+)*

<!--
Min. 1 sequence diagram krytycznego flow.
Obowiązkowy od L2. Typowe: auth flow, główny use case, webhook/event flow.
Snippety: references/mermaid-examples.md → sekcja "Sequence — Auth Flow"
-->

### Flow 1: Autentykacja

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Frontend
    participant Backend
    participant DB
    participant Cache

    User->>Frontend: POST /login {email, password}
    Frontend->>Backend: POST /api/auth/login
    Backend->>DB: SELECT user WHERE email=?
    DB-->>Backend: user record
    Backend->>Backend: verify password (bcrypt)
    Backend->>Cache: SET session:<token> ttl=24h
    Backend-->>Frontend: {token, user}
    Frontend-->>User: redirect to dashboard
```

### Flow 2: <Nazwa flow> *(opcjonalny)*

```mermaid
sequenceDiagram
    %% TODO
```

---

## 5. Data Model (ERD) *(L2+)*

<!--
ERD dla projektu. Mermaid erDiagram lub DBML.
Dla projektów z Prisma — patrz mermaid-examples.md → sekcja "ERD Prisma".
Dla projektów z czystym SQL/DBML — patrz mermaid-examples.md → sekcja "ERD SQL/DBML".
Obowiązkowy od L2.
-->

```mermaid
erDiagram
    USERS {
        uuid id PK
        varchar email UK
        varchar password_hash
        timestamp created_at
        timestamp updated_at
    }

    SESSIONS {
        uuid id PK
        uuid user_id FK
        varchar token UK
        timestamp expires_at
    }

    USERS ||--o{ SESSIONS : "has"
```

**Uwagi do modelu:**
- ...

---

## 6. Deployment Topology *(L3 only)*

<!--
Obowiązkowy tylko na L3 (>3 devs, multiple environments).
PlantUML dopuszczalny dla złożonych topologii — patrz references/mermaid-examples.md → "Deployment".
-->

```mermaid
graph TB
    subgraph "Production VPS"
        direction TB
        Caddy["Caddy (reverse proxy, SSL)"]
        Frontend["Frontend :3000"]
        Backend["Backend API :4000"]
        PG["PostgreSQL :5432"]
        Redis["Redis :6379"]
    end
    Internet["Internet"] --> Caddy
    Caddy --> Frontend
    Caddy --> Backend
    Backend --> PG
    Backend --> Redis
```

**Środowiska:**
| Środowisko | URL | Branch | Deploy |
|-----------|-----|--------|--------|
| Production | `https://...` | `main` | manual approval |
| Staging | `https://staging...` | `develop` | automatyczny |

---

## 7. ADR Index

Accepted ADR-y wpływające na obecną architekturę:

| ID | Tytuł | Kind | Data |
|----|-------|------|------|
| [0001](<ścieżka>) | <tytuł> | infrastructure | YYYY-MM-DD |
| [0002](<ścieżka>) | <tytuł> | code | YYYY-MM-DD |

Propozycje: `docs/adr/` (status: proposed)

---

## 8. Trade-offs & Known Limitations

<!--
Świadome kompromisy — czego NIE zrobiliśmy i dlaczego.
To jest najważniejsza sekcja dla przyszłych deweloperów.
-->

| Kompromis | Uzasadnienie | Kiedy revisit |
|-----------|-------------|---------------|
| Brak message queue (tylko Redis pub/sub) | MVP — Redis wystarczy dla <N> msg/s | Gdy >X msg/s lub potrzeba persistence |
| Brak full-text search (tylko ILIKE) | Corpus <Y rekordów, wystarczy | Gdy >Y rekordów lub wymagania PLN |
| ... | ... | ... |

**Known technical debt:**
- patrz [`TECH_DEBT.md`](../TECH_DEBT.md)
