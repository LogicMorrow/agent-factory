# Mermaid — Gotowe snippety

Użyj jako punkt startowy — kopiuj i dostosuj do projektu. Wszystkie renderują się natywnie na GitHub.

> **Fallback do PlantUML:** gdy diagram jest zbyt złożony (C4 L3 z >10 komponentami, deployment topology z wieloma sieciami) — patrz sekcja "PlantUML fallback" na końcu.

---

## C4 Context Diagram (L1)

```mermaid
C4Context
    title System Context Diagram — <PROJEKT>

    Person(user, "Użytkownik końcowy", "Korzysta z aplikacji przez przeglądarkę")
    Person(admin, "Administrator", "Zarządza konfiguracją i użytkownikami")

    System(app, "<PROJEKT>", "Główna aplikacja — <krótki opis>")

    System_Ext(smtp, "SMTP (np. Resend)", "Wysyłka emaili transakcyjnych")
    System_Ext(storage, "Object Storage (np. S3)", "Pliki i załączniki")
    System_Ext(oauth, "OAuth Provider (np. Google)", "SSO / social login")

    Rel(user, app, "HTTPS")
    Rel(admin, app, "HTTPS")
    Rel(app, smtp, "API / SMTP")
    Rel(app, storage, "S3 API")
    Rel(app, oauth, "OAuth 2.0 / OIDC")

    UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")
```

---

## C4 Container Diagram (L2)

```mermaid
C4Container
    title Container Diagram — <PROJEKT>

    Person(user, "Użytkownik")

    System_Boundary(app_boundary, "<PROJEKT>") {
        Container(frontend, "Frontend", "Next.js 14 / React", "UI aplikacji — SSR + CSR")
        Container(backend, "Backend API", "Hono / Node.js", "REST lub tRPC endpoints, business logic")
        ContainerDb(pg, "PostgreSQL", "PostgreSQL 16", "Dane aplikacji — users, sessions, ...")
        ContainerDb(redis, "Redis", "Redis 7", "Cache, sesje, pub/sub dla WebSocket")
    }

    System_Ext(smtp, "SMTP")

    Rel(user, frontend, "HTTPS", "browser")
    Rel(frontend, backend, "HTTP/tRPC", "internal network")
    Rel(backend, pg, "SQL", "TCP 5432")
    Rel(backend, redis, "Redis protocol", "TCP 6379")
    Rel(backend, smtp, "API")

    UpdateLayoutConfig($c4ShapeInRow="2", $c4BoundaryInRow="1")
```

---

## Sequence — Auth Flow

```mermaid
sequenceDiagram
    autonumber
    actor User as "Użytkownik"
    participant F as "Frontend (Next.js)"
    participant B as "Backend API (Hono)"
    participant DB as "PostgreSQL"
    participant Cache as "Redis"

    User->>F: Wypełnia formularz logowania
    F->>B: POST /api/auth/login {email, password}
    B->>DB: SELECT * FROM users WHERE email = $1
    DB-->>B: user row (password_hash, id, role)
    B->>B: bcrypt.compare(password, hash)

    alt Hasło poprawne
        B->>Cache: SET session:<uuid> {userId, role} EX 86400
        B-->>F: 200 {token: "<jwt>", user: {...}}
        F->>F: Zapisz token w HttpOnly cookie
        F-->>User: Redirect → dashboard
    else Hasło niepoprawne
        B-->>F: 401 {error: "INVALID_CREDENTIALS"}
        F-->>User: Wyświetl błąd
    end
```

---

## ERD — Prisma schema style

```mermaid
erDiagram
    User {
        String id PK "cuid"
        String email UK
        String passwordHash
        UserRole role "DEFAULT USER"
        DateTime createdAt
        DateTime updatedAt
    }

    Session {
        String id PK "cuid"
        String userId FK
        String token UK
        DateTime expiresAt
        String ipAddress
        String userAgent
    }

    Post {
        String id PK "cuid"
        String authorId FK
        String title
        String content
        Boolean published "DEFAULT false"
        DateTime createdAt
        DateTime updatedAt
    }

    User ||--o{ Session : "has sessions"
    User ||--o{ Post : "authors"
```

---

## ERD — SQL/DBML style (czysty PostgreSQL bez ORM)

```mermaid
erDiagram
    users {
        uuid id PK "DEFAULT gen_random_uuid"
        varchar_255 email UK "NOT NULL"
        varchar_255 password_hash "NOT NULL"
        varchar_50 role "NOT NULL DEFAULT 'user'"
        timestamp created_at "DEFAULT now"
        timestamp updated_at "DEFAULT now"
    }

    sessions {
        uuid id PK "DEFAULT gen_random_uuid"
        uuid user_id FK "NOT NULL REFERENCES users(id) ON DELETE CASCADE"
        text token UK "NOT NULL"
        timestamp expires_at "NOT NULL"
        inet ip_address
        text user_agent
    }

    posts {
        uuid id PK
        uuid author_id FK "NOT NULL REFERENCES users(id)"
        text title "NOT NULL"
        text content
        boolean published "DEFAULT false"
        timestamp created_at "DEFAULT now"
    }

    users ||--o{ sessions : "has"
    users ||--o{ posts : "authors"
```

---

## Deployment Topology

<!--
Użyj dla L3. Dla złożonych topologii z wieloma sieciami rozważ PlantUML fallback.
-->

```mermaid
graph TB
    subgraph Internet
        Browser["Przeglądarka użytkownika"]
        CI["GitHub Actions CI/CD"]
    end

    subgraph "VPS Production (Ubuntu 22.04)"
        direction TB
        Caddy["Caddy :80/:443\n(reverse proxy + SSL)"]

        subgraph "Docker Compose Network"
            Frontend["next-app :3000\n(Next.js 14)"]
            Backend["hono-api :4000\n(Hono / Node.js)"]
            PG["postgres :5432\n(PostgreSQL 16)"]
            Redis["redis :6379\n(Redis 7)"]
        end

        subgraph "Volumes"
            PGData[("pg_data")]
            RedisData[("redis_data")]
            CaddyCerts[("caddy_data\n(TLS certs)")]
        end
    end

    Browser -->|"HTTPS :443"| Caddy
    CI -->|"SSH deploy"| VPS
    Caddy -->|"proxy :3000"| Frontend
    Caddy -->|"proxy :4000"| Backend
    Backend -->|"TCP :5432"| PG
    Backend -->|"TCP :6379"| Redis
    PG --- PGData
    Redis --- RedisData
    Caddy --- CaddyCerts

    classDef external fill:#lightblue,stroke:#333
    classDef service fill:#lightgreen,stroke:#333
    classDef storage fill:#lightyellow,stroke:#333
    class Browser,CI external
    class Caddy,Frontend,Backend service
    class PG,Redis,PGData,RedisData,CaddyCerts storage
```

---

## PlantUML Fallback

Gdy Mermaid nie radzi sobie z diagramem (zbyt duże C4 L3, złożona deployment topology z wieloma sieciami):

1. Napisz diagram w `.puml` (np. `docs/architecture/deployment.puml`)
2. Wyrenderuj do `.svg`: `plantuml -tsvg deployment.puml`
3. Dodaj oba pliki do repo
4. Linkuj SVG w Markdown: `![Deployment](./deployment.svg)`

**Zasada:** `.puml` źródło MUSI być w repo obok `.svg`. Bez źródła — `*.svg` bez możliwości edycji = takie samo zło jak draw.io bez źródła.

Przykładowy plik `.puml` dla C4 Level 3 (Component):
```plantuml
@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Component.puml

Container_Boundary(api, "Backend API (Hono)") {
    Component(auth, "Auth Controller", "Hono middleware", "JWT verify, session management")
    Component(users, "Users Router", "Hono router", "CRUD users")
    Component(posts, "Posts Router", "Hono router", "CRUD posts")
    Component(db, "DB Client", "postgres.js", "Raw SQL queries")
    Component(cache, "Cache Client", "ioredis", "Session cache")
}

Rel(auth, cache, "session lookup")
Rel(users, db, "SQL")
Rel(posts, db, "SQL")
@enduml
```
