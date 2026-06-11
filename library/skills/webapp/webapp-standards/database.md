# Baza danych — Prisma i PostgreSQL 16

## Schemat Prisma — standard
```prisma
model User {
  id        String   @id @default(dbgenerated("gen_random_uuid")) @db.Uuid
  createdAt DateTime @default(now) @db.Timestamptz
  updatedAt DateTime @updatedAt @db.Timestamptz
  // ...
}
```
Każda tabela ma: UUID PK, `created_at`, `updated_at` jako TIMESTAMPTZ NOT NULL DEFAULT NOW.

## Migracje — zasady bezwzględne
```bash
# Tworzenie migracji:
npx prisma migrate dev --name add_user_roles   # opisowa nazwa!

# Nigdy:
# - ręczna edycja plików w prisma/migrations/
# - ALTER TABLE bezpośrednio na bazie prod
# - prisma db push na prod (tylko dla dev)
```

## Baza danych — bezpieczeństwo
- User bazy: minimalne uprawnienia (SELECT, INSERT, UPDATE, DELETE na własnych tabelach — nie superuser)
- Baza niedostępna publicznie — tylko localhost lub Docker network
- Hasło TYLKO w `.env`, nigdy w kodzie lub docker-compose bez zmiennej

## Indeksy — obowiązkowe
Każda kolumna używana w `WHERE` lub `JOIN` powinna mieć indeks. Dokumentuj indeksy w schemacie Prisma.

## Backup produkcyjny
```bash
# Cron codziennie:
pg_dump -U $USER $DB_NAME | gzip > /backups/db_$(date +%Y%m%d).sql.gz

# Retencja: minimum 7 dni
# Opcjonalnie: sync do S3-compatible przez rclone
```

## Monitoring bazy
- Healthcheck w docker-compose: `pg_isready`
- Połączenie przez `depends_on: condition: service_healthy`
- Sentry error tracking dla błędów Prisma

## Antywzorce
- ❌ `String` PK zamiast UUID
- ❌ Brak `updated_at` w tabeli
- ❌ `DATETIME` zamiast `TIMESTAMPTZ`
- ❌ Migracja tworzona ręcznie bez `prisma migrate dev`
- ❌ Superuser jako user aplikacji
- ❌ Brak backupu na prod
