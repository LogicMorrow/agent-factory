# Prawa podmiotów danych — implementacja techniczna

## Przegląd praw i endpointów

| Prawo | Art. RODO | Endpoint API | Termin odpowiedzi | Logowane jako |
|---|---|---|---|---|
| Dostępu | 15 | `GET /api/rodo/data-export` | 30 dni | `RODO_ACCESS_REQUEST` |
| Usunięcia (zapomnienia) | 17 | `POST /api/rodo/data-delete` | 30 dni | `RODO_DELETE_REQUEST` |
| Sprostowania | 16 | (standardowa edycja w UI) | 30 dni | `RODO_RECTIFICATION` |
| Przenoszenia | 20 | `GET /api/rodo/data-export?format=csv` | 30 dni | `RODO_PORTABILITY_REQUEST` |
| Sprzeciwu | 21 | (v2 — marketing opt-out) | 30 dni | `RODO_OBJECTION` — v2 |

Każde żądanie: logowane w `audit_log` z `actor_user_id` (dostarczany przez `single-user-auth-pl`) i timestampem.

## Prawo dostępu — art. 15

Klient ma prawo wiedzieć jakie dane przetwarzamy i w jakim celu.

```typescript
// GET /api/rodo/data-export
// Zwraca wszystkie dane klienta w formacie JSON

export async function GET(req: Request) {
  const session = await getSession(req); // single-user-auth-pl
  const { clientId } = parseQuery(req);

  const client = await prisma.client.findUnique({
    where: { id: clientId },
    include: { offers: true }
  });

  if (!client) return Response.json({ error: 'Nie znaleziono' }, { status: 404 });

  // Log żądania dostępu
  await auditLog.insert({
    ts: new Date.toISOString,
    actor_user_id: session.userId,
    action_type: 'RODO_ACCESS_REQUEST',
    target_id: clientId,
    result: 'OK',
  });

  return Response.json({
    exportedAt: new Date.toISOString,
    administrator: '<firma> sp. z o.o., NIP <NIP>',
    subject: {
      name: client.name,
      phone: client.phone,
      address: client.address,
    },
    offers: client.offers.map(o => ({
      id: o.id,
      createdAt: o.createdAt,
      status: o.status,
      totalNet: o.totalNet,
    })),
    processingBasis: 'art. 6.1.b RODO (wykonanie umowy) + art. 6.1.f (uzasadniony interes — archiwum)',
    retentionPolicy: 'Oferty akceptowane: 5 lat. Odrzucone: 2 lata. Następnie anonimizacja.',
    contact: '<operator>, kontakt przez telefon <TELEFON>',
  });
}
```

## Prawo do usunięcia — art. 17

Klient ma prawo żądać usunięcia danych. Nie jest bezwzględne — jeśli dane są potrzebne do ustalenia/dochodzenia/obrony roszczeń (art. 17.3.e), możemy odmówić pełnego usunięcia i zastąpić anonimizacją.

Strategia dla <firma>: **soft-delete + anonimizacja** zamiast hard DELETE.

```typescript
// POST /api/rodo/data-delete
// Body: { clientId: string, reason?: string }

export async function POST(req: Request) {
  const session = await getSession(req);
  const { clientId } = await req.json;

  const client = await prisma.client.findUnique({ where: { id: clientId } });
  if (!client) return Response.json({ error: 'Nie znaleziono' }, { status: 404 });

  // Sprawdź czy są aktywne/akceptowane oferty (roszczenia)
  const activeOffers = await prisma.offer.count({
    where: { clientId, status: 'ACCEPTED', createdAt: { gte: subYears(new Date, 5) } }
  });

  if (activeOffers > 0) {
    // Odmowa pełnego usunięcia — dane potrzebne do roszczeń (art. 17.3.e)
    await auditLog.insert({
      ts: new Date.toISOString,
      actor_user_id: session.userId,
      action_type: 'RODO_DELETE_REFUSED',
      target_id: clientId,
      result: 'OK',
      note: 'Aktywna oferta w okresie rękojmi — dane niezbędne do obrony roszczeń',
    });
    return Response.json({
      status: 'partial',
      message: 'Dane nie mogą być usunięte — oferta w okresie rękojmi (5 lat). Zostanie anonimizowana po upływie okresu.',
    });
  }

  // Anonimizacja — nie usuwamy rekordu (zachowujemy integralność FK w audit-trail)
  await prisma.client.update({
    where: { id: clientId },
    data: {
      name: '[ZANONIMIZOWANO]',
      phone: null,
      address: null,
      anonymizedAt: new Date,
    }
  });

  await auditLog.insert({
    ts: new Date.toISOString,
    actor_user_id: session.userId,
    action_type: 'RODO_DELETE_REQUEST',
    target_id: clientId,
    result: 'OK',
  });

  return Response.json({ status: 'anonymized', message: 'Dane osobowe zostały zanonimizowane.' });
}
```

## Prawo sprostowania — art. 16

Implementacja: standardowy formularz edycji danych klienta w UI. Wymagania dodatkowe:

```typescript
// Przy każdej edycji danych klienta loguj zmianę:
await auditLog.insert({
  ts: new Date.toISOString,
  actor_user_id: session.userId,
  action_type: 'RODO_RECTIFICATION',
  target_id: clientId,
  result: 'OK',
  note: `Zmienione pola: ${changedFields.join(', ')}`,
});
```

Nie buduj osobnego endpointu — standardowy `PATCH /api/clients/:id` z audit logiem wystarczy.

## Prawo do przenoszenia — art. 20

Dotyczy danych przetwarzanych na podstawie zgody (6.1.a) lub umowy (6.1.b). Dane muszą być dostarczone w powszechnie używanym formacie (JSON lub CSV).

```typescript
// GET /api/rodo/data-export?format=csv
// Rozszerzenie endpointu data-export o format CSV

const format = searchParams.get('format') ?? 'json';

if (format === 'csv') {
  const csvContent = [
    'id,imie,telefon,adres,data_oferty,status,wartosc_netto',
    ...client.offers.map(o =>
      `${o.id},"${client.name}","${client.phone ?? ''}","${client.address ?? ''}",${o.createdAt.toISOString},${o.status},${o.totalNet}`
    )
  ].join('\n');

  await auditLog.insert({ ..., action_type: 'RODO_PORTABILITY_REQUEST' });

  return new Response(csvContent, {
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="dane-${clientId}.csv"`,
    }
  });
}
```

## Lista action_type dla audit_log

Kompletna lista wartości `action_type` wymaganych przez ten skill (kontrakt z `single-user-auth-pl`):

```typescript
type RodoActionType =
  | 'RODO_ACCESS_REQUEST'        // art. 15 — eksport danych
  | 'RODO_DELETE_REQUEST'        // art. 17 — anonimizacja wykonana
  | 'RODO_DELETE_REFUSED'        // art. 17 — odmowa z powodu roszczeń
  | 'RODO_RECTIFICATION'         // art. 16 — sprostowanie danych
  | 'RODO_PORTABILITY_REQUEST'   // art. 20 — eksport CSV
  | 'RETENTION_CLEANUP'          // automatyczne czyszczenie retencji
  | 'OFFER_CREATED'              // tworzenie oferty
  | 'OFFER_UPDATED'              // edycja oferty
  | 'OFFER_STATUS_CHANGED';      // zmiana statusu oferty
```

`single-user-auth-pl` loguje akcje sesji (LOGIN, LOGOUT, SESSION_EXPIRED). Ten skill odpowiada za akcje domenowe (RODO_*, RETENTION_*, OFFER_*).

## Obsługa żądania w praktyce (mała firma, brak DPO)

Kiedy klient zadzwoni lub napisze z żądaniem RODO:

1. Właściciel firmy (<operator>) loguje się do systemu.
2. Wyszukuje klienta po nazwisku lub telefonie.
3. Klika „Eksport danych RODO" lub „Usuń dane RODO" w panelu klienta.
4. System wykonuje akcję i loguje w audit_log.
5. Właściciel wysyła eksport klientowi lub potwierdza usunięcie.
6. Cały proces: max 30 dni, w praktyce kilka minut.

UI dla tych akcji powinien być dostępny w widoku szczegółów klienta, widoczny tylko dla zalogowanego właściciela.
