# Retencja danych i audit-trail

## Polityka retencji dla <firma>

| Kategoria danych | Okres retencji | Podstawa | Akcja po upływie |
|---|---|---|---|
| Oferty zaakceptowane (dane klienta) | 5 lat od akceptacji | Rękojmia (art. 556 KC) + art. 6.1.f | Anonimizacja danych osobowych klienta |
| Oferty odrzucone / wygasłe (dane klienta) | 2 lata od ostatniej zmiany statusu | Uzasadniony interes — follow-up, roszczenia | Anonimizacja danych osobowych klienta |
| Audit-trail (snapshoty PDF + hash) | 6 lat | Ordynacja podatkowa + KSeF | Brak — append-only, archiwum trwałe |
| Dane klienta po wygaśnięciu wszystkich ofert | Anonimizacja natychmiast | — | Pseudonim w rekordzie, dane osobowe null |
| Logi techniczne (błędy, requesty) | 90 dni | art. 6.1.f — bezpieczeństwo | Automatyczne usunięcie przez cron |
| Wpisy audit_log | 6 lat | Ordynacja podatkowa | Brak usunięcia — archiwum |

### Zasada pseudonimizacji archiwum

Po anonimizacji klienta rekord w tabeli `clients` pozostaje (zachowanie integralności FK):

```sql
-- Rekord po anonimizacji
UPDATE clients SET
  name = '[ZANONIMIZOWANO]',
  phone = NULL,
  address_street = NULL,
  address_city = NULL,
  anonymized_at = NOW
WHERE id = :clientId;

-- Rekord NIE jest usuwany — oferty w archiwum wciąż mają client_id FK
-- Audit-trail zachowuje hash dokumentu z momentu tworzenia
```

## Harmonogram cron — data-retention-cleanup

Cron uruchamiany co miesiąc (1-ego dnia, godz. 02:00). Cel: automatyczna anonimizacja danych po upływie okresu retencji.

```typescript
// scripts/data-retention-cleanup.ts
// Uruchamiane przez cron: 0 2 1 * *

async function runRetentionCleanup {
  const log: string[] = [];
  const now = new Date;

  // 1. Oferty odrzucone/wygasłe starsze niż 2 lata
  const cutoff2y = subYears(now, 2);
  const expiredOffers = await prisma.offer.findMany({
    where: {
      status: { in: ['REJECTED', 'EXPIRED'] },
      updatedAt: { lt: cutoff2y },
      client: { anonymizedAt: null }, // pomijaj już zanonimizowanych
    },
    include: { client: true },
    distinct: ['clientId'],
  });

  for (const offer of expiredOffers) {
    // Sprawdź czy klient ma inne aktywne/akceptowane oferty
    const activeCount = await prisma.offer.count({
      where: {
        clientId: offer.clientId,
        status: 'ACCEPTED',
        createdAt: { gte: subYears(now, 5) },
      }
    });
    if (activeCount > 0) continue; // pomijaj — aktywne oferty w rękojmi

    await anonymizeClient(offer.clientId);
    log.push(`ANONYMIZED clientId=${offer.clientId} reason=retention_2y`);
  }

  // 2. Logi techniczne starsze niż 90 dni
  const cutoff90d = subDays(now, 90);
  const deleted = await prisma.technicalLog.deleteMany({
    where: { createdAt: { lt: cutoff90d } }
  });
  log.push(`DELETED_TECH_LOGS count=${deleted.count}`);

  // 3. Zapis do audit_log
  await auditLog.insert({
    ts: now.toISOString,
    actor_user_id: 'SYSTEM_CRON',
    action_type: 'RETENTION_CLEANUP',
    result: 'OK',
    note: log.join('; '),
  });

  console.log('[RETENTION]', log.join('\n'));
}
```

## Audit-trail — format i hash łańcuchowy

### Cel audit-trail

Wykrycie retroaktywnych modyfikacji ofert. Każda zmiana oferty tworzy snapshot — ciąg snapshotów z hash łańcuchowym uniemożliwia niewidoczną modyfikację historii.

### Struktura katalogu

```
artifacts/
└── audit-trail/
    └── <offer_id>/
        ├── 2026-05-27T10:15:00Z-a1b2c3d4.json   # snapshot N
        ├── 2026-05-27T10:15:00Z-a1b2c3d4.pdf    # PDF snapshot N
        ├── 2026-05-28T14:22:00Z-e5f6g7h8.json   # snapshot N+1
        └── chain.json                             # manifest łańcucha hashy
```

### Format snapshotu JSON

```json
{
  "snapshotVersion": 1,
  "offerId": "uuid",
  "createdAt": "2026-05-27T10:15:00.000Z",
  "actorUserId": "owner",
  "action": "OFFER_UPDATED",
  "offerData": {
    "clientName": "Jan Kowalski",
    "clientPhone": "600123456",
    "totalNet": 12500.00,
    "positions": [...]
  },
  "contentHash": "sha256(JSON.stringify(offerData))",
  "chainHash": "sha256(contentHash + previousChainHash)"
}
```

### Algorytm hash łańcuchowy

```typescript
import { createHash } from 'crypto';

function computeChainHash(
  contentHash: string,
  previousChainHash: string
): string {
  return createHash('sha256')
    .update(contentHash + previousChainHash)
    .digest('hex');
}

async function createAuditSnapshot(
  offer: Offer,
  actorUserId: string,
  action: string
): Promise<void> {
  const offerData = serializeOffer(offer);
  const contentHash = createHash('sha256')
    .update(JSON.stringify(offerData))
    .digest('hex');

  // Pobierz ostatni hash z chain.json (lub genesis '0000...0000' dla pierwszego)
  const chainManifest = await readChainManifest(offer.id);
  const previousChainHash = chainManifest.lastHash ?? '0'.repeat(64);
  const chainHash = computeChainHash(contentHash, previousChainHash);

  const ts = new Date.toISOString;
  const filename = `${ts.replace(/[:.]/g, '-')}-${chainHash.substring(0, 8)}`;

  const snapshot = {
    snapshotVersion: 1,
    offerId: offer.id,
    createdAt: ts,
    actorUserId,
    action,
    offerData,
    contentHash,
    chainHash,
  };

  // Zapisz snapshot (append-only — nigdy nie nadpisujemy)
  const dir = `artifacts/audit-trail/${offer.id}`;
  await fs.mkdir(dir, { recursive: true });
  await fs.writeFile(`${dir}/${filename}.json`, JSON.stringify(snapshot, null, 2));

  // Zaktualizuj chain.json
  await updateChainManifest(offer.id, { lastHash: chainHash, lastTs: ts });
}
```

### Weryfikacja integralności łańcucha

```typescript
async function verifyAuditChain(offerId: string): Promise<boolean> {
  const snapshots = await loadSnapshotsChronologically(offerId);
  let previousHash = '0'.repeat(64);

  for (const snapshot of snapshots) {
    const expectedChainHash = computeChainHash(snapshot.contentHash, previousHash);
    if (expectedChainHash !== snapshot.chainHash) {
      console.error(`[AUDIT] Naruszenie integralności! offerId=${offerId} snapshot=${snapshot.createdAt}`);
      return false;
    }
    previousHash = snapshot.chainHash;
  }
  return true;
}
```

### Kontrakt z hookiem `audit-trail-on-offer-write.sh`

Hook `audit-trail-on-offer-write.sh` (PostToolUse) wywołuje `createAuditSnapshot` przy każdym:
- `OFFER_CREATED`
- `OFFER_UPDATED`
- `OFFER_STATUS_CHANGED`

Hook NIE wywołuje się przy akcjach RODO (te logowane bezpośrednio przez endpointy RODO).

### Backup audit-trail

Snapshoty w `artifacts/audit-trail/` muszą być backupowane osobno od bazy danych:

```bash
# Zalecany harmonogram: daily, poza backup PostgreSQL
# v1: rsync do drugiego VPS lub cold storage
rsync -av artifacts/audit-trail/ backup-host:/<BACKUP_BUCKET>/

# v2 (przyszłość): S3-compatible (np. Backblaze B2, Wasabi)
# aws s3 sync artifacts/audit-trail/ s3://<BACKUP_BUCKET>/
```

Jeśli baza zostanie skasowana lub zhackowana — audit-trail na oddzielnym backupie umożliwia odtworzenie historii ofert.

## Zgłaszanie incydentów do PUODO

Przy wykryciu naruszenia ochrony danych osobowych (np. wyciek bazy, kradzież danych):

1. Czas na decyzję: 72 godziny od wykrycia.
2. Ocena: czy naruszenie stwarza ryzyko dla praw i wolności osób? Wyciek imion + adresów = ryzyko.
3. Zgłoszenie: formularz online na puodo.gov.pl → „Zgłoś naruszenie ochrony danych osobowych".
4. Treść zgłoszenia: opis zdarzenia, kategorie danych, przybliżona liczba osób, podjęte środki zaradcze.
5. Jeśli ryzyko wysokie: poinformowanie poszkodowanych klientów (art. 34 RODO).

Brak zgłoszenia w terminie = potencjalna kara do 10 mln EUR lub 2% obrotu.
