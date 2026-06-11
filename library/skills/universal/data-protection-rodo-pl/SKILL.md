---
name: data-protection-rodo-pl
description: RODO compliance dla małej firmy PL (B2C usługi) — podstawy prawne, prawa podmiotów (implementacja techniczna), retencja, audit-trail, klauzula informacyjna (wzór PDF). Uruchamiaj gdy agent projektuje przepływ danych osobowych klientów PL lub przygotowuje gotowość audytową.
version: 1.0.0
compatible_with: [universal]
tags: [compliance, rodo, gdpr, poland, audit-trail]
requires: []
token_cost: medium
distribution: library/skills/universal/
last_updated: 2026-05-27
last_reviewed: 2026-05-29
valid_until: 2027-05-27
---

# data-protection-rodo-pl

## Kiedy uruchomić

Wczytaj ten skill gdy:
- projektujesz przepływ danych klientów PL (imię, telefon, adres budowy, adres zamieszkania),
- budujesz endpointy obsługujące żądania praw podmiotów danych (dostęp, usunięcie, eksport),
- implementujesz politykę retencji i harmonogram czyszczenia danych,
- projektujesz audit-trail do przetwarzania ofert / dokumentów,
- przygotowujesz klauzulę informacyjną art. 13 RODO do umieszczenia na PDF oferty.

Nie uruchamiaj dla systemów SaaS z wieloma klientami-administratorami — tam RODO dotyczy relacji B2B procesor/administrator, nie B2C.

## Pliki tematyczne (indeks)

| Plik | Zawartość |
|---|---|
| [`podstawy-rodo.md`](podstawy-rodo.md) | Administrator vs procesor, kategorie danych, podstawy prawne art. 6 RODO |
| [`prawa-podmiotow.md`](prawa-podmiotow.md) | 5 praw klientów + implementacja techniczna endpointów API |
| [`retencja-i-audit-trail.md`](retencja-i-audit-trail.md) | Polityka retencji dla <firma>, hash łańcuchowy, harmonogram cron |
| [`klauzula-informacyjna-szablon.md`](klauzula-informacyjna-szablon.md) | Gotowy wzór art. 13 RODO PL do PDF oferty (dane <firma> + placeholders) |
| [`anti-patterns.md`](anti-patterns.md) | 7 najczęstszych błędów compliance w małej firmie PL |

## Kluczowe zasady

1. **Administrator = <firma> sp. z o.o.** — firma przetwarzająca dane klientów jest administratorem, nie procesorem. VPS hostowany przez operatora (właściciela technicznego aplikacji) nie tworzy relacji powierzenia o ile operator nie jest odrębnym podmiotem świadczącym usługi hostingowe — wyjaśnienie w `podstawy-rodo.md`.
2. **Domyślna podstawa prawna = art. 6.1.b** — wykonanie umowy. Dla archiwum ofert = art. 6.1.f (uzasadniony interes). Zgoda (6.1.a) tylko dla marketingu — <projekt> v1 nie używa.
3. **Retencja jest obowiązkiem, nie opcją** — brak harmonogramu retencji = trzymanie danych „na zawsze" = naruszenie RODO. Polityka retencji musi być zdefiniowana przed wdrożeniem.
4. **Audit-trail osobno od danych operacyjnych** — snapshoty ofert append-only w `artifacts/audit-trail/`, nigdy w tej samej tabeli co dane edytowalne. DELETE na rekordzie klienta nie może kasować audit-trail.
5. **Klauzula art. 13 na każdej ofercie PDF** — klient musi wiedzieć kto przetwarza jego dane, zanim dane trafią do systemu. Klauzula w stopce PDF lub jako link do polityki prywatności.
6. **Każde żądanie RODO: 30 dni odpowiedzi, log w audit_log** — działanie potwierdzane przez `single-user-auth-pl` z `actor_user_id` i `action_type`.
7. **Incydent = 72h do PUODO** — naruszenie ochrony danych (np. wyciek bazy) zgłaszane do Urzędu Ochrony Danych Osobowych w ciągu 72 godzin od wykrycia.
8. **DPIA nieobowiązkowe dla <projekt> v1** — dane zwykłe (imię, telefon, adres), mała skala, brak profilowania. DPIA wymagane przy danych wrażliwych lub masowym profilowaniu.
9. **DPO nieobowiązkowy** — <firma> nie przetwarza danych wrażliwych w dużej skali.

## Przykłady: dobrze vs źle

### Soft-delete zamiast hard-delete przy żądaniu "prawa do bycia zapomnianym"

Dobrze:
```typescript
// Żądanie art. 17 RODO — anonimizacja, nie DELETE
await prisma.client.update({
  where: { id: clientId },
  data: {
    name: '[ZANONIMIZOWANO]',
    phone: null,
    address: null,
    deletedAt: new Date,
    anonymizedAt: new Date,
  }
});
// audit_log.insert({ actor: userId, action: 'RODO_DELETE_REQUEST', targetId: clientId, ts: now })
// Oferty z tym clientId pozostają w archiwum (audit-trail) z pseudonimem
```

Źle:
```typescript
// Hard DELETE bez anonimizacji
await prisma.client.delete({ where: { id: clientId } });
// — kasuje referencje w archiwum ofert → utrata integralności historycznej
// — brak wpisu w audit_log → nie można udowodnić wykonania żądania
```

### Retencja z harmonogramem vs "trzymamy na zawsze"

Dobrze:
```typescript
// Cron: data-retention-cleanup (np. co miesiąc)
// Oferty odrzucone/wygasłe starsze niż 2 lata → anonimizacja danych klienta
const cutoff = subYears(new Date, 2);
const expired = await prisma.offer.findMany({
  where: { status: { in: ['REJECTED', 'EXPIRED'] }, updatedAt: { lt: cutoff } }
});
for (const offer of expired) {
  await anonymizeClientData(offer.clientId);
  await offerLog.append({ action: 'RETENTION_CLEANUP', offerId: offer.id });
}
```

Źle:
```typescript
// Brak jakiejkolwiek logiki retencji
// Dane klientów z odrzuconych ofert sprzed 10 lat nadal w bazie
// — naruszenie zasady minimalizacji danych (art. 5.1.e RODO)
```

## Antywzorce

Szczegółowa lista z wyjaśnieniami w [`anti-patterns.md`](anti-patterns.md).

Najważniejsze skróty:
- Hardkodowanie checkboxa "wyrażam zgodę" bez prawdziwego wyboru — wada prawna.
- Audit-trail w tabeli `offers` — jedna transakcja może skasować historię.
- Brak klauzuli na PDF — klient nie wie kim jesteś jako administrator.
- DELETE zamiast anonimizacji — utrata integralności archiwum.
- Brak retencji — wieczne trzymanie danych = naruszenie art. 5.1.e.

## Kontrakt z `single-user-auth-pl`

Ten skill i `single-user-auth-pl` mają wspólny kontrakt interfejsu:

```typescript
// Każde logowanie/akcja w systemie musi generować wpis:
interface AuditLogEntry {
  ts: string;          // ISO-8601
  actor_user_id: string; // z sesji auth (single-user-auth-pl dostarcza)
  action_type: string; // np. OFFER_CREATED, RODO_EXPORT_REQUEST, RODO_DELETE_REQUEST
  target_id?: string;  // np. offer_id lub client_id
  ip_addr?: string;
  result: 'OK' | 'FAIL';
}
// Retencja audit_log: 6 lat (Ordynacja podatkowa + KSeF)
```

`single-user-auth-pl` odpowiada za dostarczenie `actor_user_id` do każdego wywołania.
Ten skill odpowiada za definicję jakie `action_type` muszą być logowane (lista w `prawa-podmiotow.md`).

## Powiązania

- **`single-user-auth-pl`** (library/skills/webapp/) — dostarcza `actor_user_id` do audit_log; kontrakt opisany powyżej.
- **`audit-trail-on-offer-write.sh`** (library/hooks/) — hook PostToolUse tworzący snapshoty ofert; `retencja-i-audit-trail.md` definiuje format i hash łańcuchowy.
- **`webapp-security-hardening`** (library/skills/webapp/) — OWASP ASVS L1-L2, uzupełniający aspekt bezpieczeństwa technicznego.
- **`secrets-handling`** (library/skills/universal/) — obsługa kluczy szyfrowania (jeśli dane wrażliwe będą szyfrowane at-rest).
- **`quality-checker`** (`.claude/agents/`) — weryfikuje czy endpointy RODO są zaimplementowane zgodnie z tym skillem.
