# Audit Log — schema, Prisma model, retencja

> v2.0.0 REBUILD: Schemat zaktualizowany pod iron-session 8 + pino-redact.
> Usunięto hash chain (zastąpiony przez DB-level RULE + pino structured log).
> Dodano: ip_hash + user_agent_hash pola, retencja 5 lat (DemoApp → ust. rachunkowości PL).

---

## Prisma model AuditLog

```prisma
// schema.prisma — dodaj do istniejącego schema

model AuditLog {
  id             String    @id @default(cuid)
  ts             DateTime  @default(now) @db.Timestamptz(3)

  /// ID użytkownika — null dla login.fail przed identyfikacją
  userId         String?

  /// Typ akcji — lista w templates/audit-log.ts.template
  action         String

  /// Typ zasobu — "offer" | "client" | "settings" | "pdf" | null
  resourceType   String?

  /// UUID zasobu — logiczna referencja, NIE FK z CASCADE DELETE
  resourceId     String?

  /// SHA-256(ip_address).slice(0,16) — pseudonimizacja RODO
  ipHash         String?

  /// SHA-256(user_agent).slice(0,16) — pseudonimizacja RODO
  userAgentHash  String?

  /**
   * Dodatkowy kontekst — TYLKO dane nieosobowe.
   * NIE WKŁADAJ: imion, nazwisk, telefonów, adresów, kwot, plaintextów PII.
   * Dozwolone: UUID, hashe (8-16 hex), flagi, changed_fields[], pdf_type.
   */
  metadata       Json      @default("{}")

  @@index([ts(sort: Desc)])
  @@index([userId, ts(sort: Desc)])
  @@index([action, ts(sort: Desc)])
  @@index([resourceId, ts(sort: Desc)])

  @@map("audit_log")
}
```

**Uwaga:** brak relacji `User @relation` celowo — audit_log ma cykl życia niezależny od użytkownika.
`resourceId` to logiczny UUID bez FK — usunięcie oferty NIE kasuje wpisów audit dla tej oferty.

---

## Migracja Prisma

```sql
-- Wygenerowana przez: pnpm prisma migrate dev --name add_audit_log
-- Dodatkowe: RULE append-only (nie w Prisma — raw SQL po migracji)

CREATE TABLE audit_log (
  id              TEXT        PRIMARY KEY,
  ts              TIMESTAMPTZ NOT NULL DEFAULT NOW,
  user_id         TEXT,
  action          TEXT        NOT NULL,
  resource_type   TEXT,
  resource_id     TEXT,
  ip_hash         TEXT,
  user_agent_hash TEXT,
  metadata        JSONB       NOT NULL DEFAULT '{}'
);

CREATE INDEX idx_audit_log_ts           ON audit_log(ts DESC);
CREATE INDEX idx_audit_log_user_ts      ON audit_log(user_id, ts DESC);
CREATE INDEX idx_audit_log_action_ts    ON audit_log(action, ts DESC);
CREATE INDEX idx_audit_log_resource_ts  ON audit_log(resource_id, ts DESC);

-- KLUCZOWE: Append-only enforcement na poziomie DB
-- Uruchom po `pnpm prisma migrate deploy` jako raw SQL (np. w seed.ts)
CREATE RULE no_delete_audit_log AS ON DELETE TO audit_log DO INSTEAD NOTHING;
CREATE RULE no_update_audit_log AS ON UPDATE TO audit_log DO INSTEAD NOTHING;
```

Alternatywa dla PostgreSQL z RLS (bardziej granularna):
```sql
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
-- Tylko rola app_user może INSERT
CREATE POLICY audit_insert ON audit_log FOR INSERT TO app_user WITH CHECK (true);
-- Nikt nie może DELETE
CREATE POLICY audit_no_delete ON audit_log FOR DELETE USING (false);
-- Brak UPDATE policy = UPDATE zablokowany domyślnie
```

---

## Retencja — 5 lat (ustawa o rachunkowości PL)

**Podstawa prawna:**
- Ustawa o rachunkowości art. 74 — dokumenty 5 lat po roku obrotowym
- RODO art. 5(1)(e) — ograniczenie przechowywania do niezbędnego minimum
- Wybrano 5 lat (nie 6 jak w v1.0.0) — dostosowane do wymagań Acme Sp. z o.o.

```sql
-- Auto-purge wierszy starszych niż 5 lat
-- UWAGA: execute tylko po archiwizacji do cold storage (B2 / archiwum)
-- Uruchom przez cron lub pg_cron extension

-- pg_cron (jeśli zainstalowane):
SELECT cron.schedule(
  'purge-audit-log-5y',
  '0 3 1 1 *',  -- co roku 1 stycznia o 3:00
  $$DELETE FROM audit_log WHERE ts < NOW - INTERVAL '5 years'$$
);

-- Alternatywnie — backup sidecar cron job (compose.prod.yml):
-- 0 3 1 1 * psql $DATABASE_URL -c "DELETE FROM audit_log WHERE ts < NOW - INTERVAL '5 years'"
```

**Przed purge — archiwizuj do B2:**
```bash
# scripts/archive-audit-log.sh
YEAR=$(date -d "5 years ago" +%Y)
psql $DATABASE_URL -c "\COPY (SELECT * FROM audit_log WHERE EXTRACT(YEAR FROM ts) = $YEAR) TO STDOUT CSV HEADER" \
  | gzip | rclone rcat b2:demoapp-backup/audit-log/audit_log_${YEAR}.csv.gz
echo "Archiwum audit_log rok $YEAR → B2 OK"
```

---

## Export danych podmiotu (RODO art. 15)

Endpoint `/api/rodo/export?clientId=UUID` — eksportuje wszystkie wpisy audit dla danego zasobu.

```ts
// app/api/rodo/export/route.ts
import { requireSession } from "@/lib/session";
import { db } from "@/lib/db";

export async function GET(request: Request) {
  await requireSession; // tylko zalogowany właściciel może eksportować

  const { searchParams } = new URL(request.url);
  const clientId = searchParams.get("clientId");

  if (!clientId) {
    return Response.json({ error: "Brak clientId" }, { status: 400 });
  }

  const logs = await db.auditLog.findMany({
    where: { resourceId: clientId },
    orderBy: { ts: "asc" },
    select: {
      ts: true,
      action: true,
      resourceType: true,
      // NIE eksportuj: ipHash, userAgentHash (dane techniczne, nie dane podmiotu)
      metadata: true,
    },
  });

  // Audit tego eksportu
  const { writeAuditLog } = await import("@/lib/audit-log");
  await writeAuditLog({
    action: "rodo.export",
    resourceType: "client",
    resourceId: clientId,
    metadata: { entriesExported: logs.length },
  });

  return Response.json({
    clientId,
    exportedAt: new Date.toISOString,
    recordCount: logs.length,
    records: logs,
  });
}
```

---

## Usunięcie danych podmiotu (RODO art. 17)

```ts
// Anonimizacja zamiast hard delete — audit log zostaje, dane klienta są maskowane
// Zob. data-protection-rodo-pl skill — procedura usunięcia danych

// W DB:
// UPDATE offers SET client_name = 'USUNIĘTO', client_phone = 'USUNIĘTO',
//   client_address = 'USUNIĘTO' WHERE client_id = $clientId;
// (NIE DELETE — zachowaj rekord historyczny dla rachunkowości)

// W audit_log:
await writeAuditLog({
  action: "rodo.delete",
  resourceType: "client",
  resourceId: clientId,
  metadata: {
    anonymizedFields: ["client_name", "client_phone", "client_address"],
  },
});
```

---

## Weryfikacja audit log (skrypt dla audytora)

```ts
// scripts/verify-audit-log.ts
// Sprawdza: czy są luki w sekwencji ts, czy metadata nie zawiera PII
// Uruchom: pnpm tsx scripts/verify-audit-log.ts

import { db } from "@/lib/db";

const PII_PATTERNS = [
  /\d{3}[-\s]?\d{3}[-\s]?\d{3}/,  // telefon PL
  /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/, // email
  /\b\d{2}-\d{3}\b/,               // kod pocztowy PL
];

const logs = await db.auditLog.findMany({ orderBy: { ts: "asc" } });
let piiWarnings = 0;

for (const log of logs) {
  const metadataStr = JSON.stringify(log.metadata);
  for (const pattern of PII_PATTERNS) {
    if (pattern.test(metadataStr)) {
      console.warn(`[WARN] Potencjalne PII w metadata, id=${log.id}, action=${log.action}`);
      piiWarnings++;
    }
  }
}

console.log(`Sprawdzono ${logs.length} wpisów.`);
if (piiWarnings === 0) {
  console.log("OK: Brak wykrytych PII w metadata.");
} else {
  console.error(`UWAGA: ${piiWarnings} potencjalnych PII — sprawdź ręcznie.`);
  process.exit(1);
}
```
