# <PROJEKT>

> **Root README** — rekomendowany, nie wymuszany przez CI. Przeznaczony dla GitHub repo landing page.
> Dla mapy dokumentacji technicznej → patrz [`docs/README.md`](./docs/README.md).

<!-- Odznaki opcjonalne: CI status, version, license -->
<!-- ![CI](https://github.com/<org>/<repo>/actions/workflows/ci.yml/badge.svg) -->

Krótki opis projektu w jednym akapicie. Co robi, dla kogo, jaki problem rozwiązuje.

---

## Szybki start

```bash
# Klonuj
git clone git@github.com:<org>/<repo>.git && cd <repo>

# Setup
cp .env.example .env
pnpm install
docker compose up -d
pnpm db:migrate
pnpm dev
```

Więcej: [`docs/onboarding.md`](./docs/onboarding.md)

---

## Stack

| Warstwa | Technologia |
|---------|-------------|
| Frontend | <np. Next.js 14> |
| Backend | <np. Hono> |
| Database | <np. PostgreSQL> |
| Cache | <np. Redis> |
| Deploy | <np. VPS + Docker + Caddy> |

Architektura: [`docs/architecture/overview.md`](./docs/architecture/overview.md)

---

## Dokumentacja

| Dokument | Zawartość |
|----------|-----------|
| [`docs/README.md`](./docs/README.md) | Mapa dokumentacji |
| [`docs/onboarding.md`](./docs/onboarding.md) | Jak zacząć pracę |
| [`docs/architecture/overview.md`](./docs/architecture/overview.md) | Architektura systemu |
| [`docs/adr/`](./docs/adr/) | Decyzje architektoniczne |
| [`docs/runbooks/`](./docs/runbooks/) | Procedury operacyjne |

---

## Contributing

1. Utwórz branch: `git checkout -b feature/<nazwa>`
2. Commit zgodnie z commitlint: `feat(<scope>): <opis>`
3. Otwórz PR do `develop` — CI musi przejść
4. Merge wymaga review od ≥1 osoby

---

## License

<np. MIT | Proprietary | patrz LICENSE>
