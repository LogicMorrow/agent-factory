# Anti-patterns RODO — małe firmy PL

## AP-1: Hardkodowany checkbox zgody zamiast prawdziwego wyboru

Błąd: formularz wyświetla checkbox „Wyrażam zgodę na przetwarzanie danych" z wartością domyślną `checked=true`, lub checkbox jest wymagany do wysłania formularza, ale brak wyraźnego celu.

Dlaczego złe: zgoda art. 6.1.a musi być dobrowolna, konkretna, świadoma i jednoznaczna. Wstępnie zaznaczony checkbox lub checkbox bez którego nie można skorzystać z usługi = nieważna zgoda (TSUE C-673/17 Planet49).

Właściwe podejście dla <firma>: nie zbierasz zgód w v1 — ofertowanie opiera się na 6.1.b (wykonanie umowy). Nie dodawaj checkbox zgody tam gdzie działa podstawa ustawowa.

```tsx
// Zle
<input type="checkbox" checked={true} required />
<label>Wyrażam zgodę na przetwarzanie danych</label>

// Dobrze (<projekt> v1 — brak checkboxa zgody, klauzula informacyjna na PDF)
// Przetwarzanie oparte na 6.1.b — brak potrzeby zbierania zgody
<InformationClause {...PDF_CONFIG} />
```

## AP-2: Brak retencji — dane trzymane bezterminowo

Błąd: brak jakiejkolwiek logiki czyszczenia lub anonimizacji danych. Oferty klientów sprzed 10 lat nadal w bazie z pełnymi danymi osobowymi.

Dlaczego złe: naruszenie art. 5.1.e RODO (zasada ograniczenia przechowywania). Dane mogą być przetwarzane tylko tak długo jak jest to niezbędne do celu. Brak retencji może skutkować nakazem PUODO i karą administracyjną.

Właściwe podejście: skrypt `data-retention-cleanup.ts` uruchamiany co miesiąc (harmonogram w `retencja-i-audit-trail.md`). Anonimizacja po 2/5 latach w zależności od statusu oferty.

```typescript
// Zle
// brak jakiegokolwiek mechanizmu retencji

// Dobrze
// cron: 0 2 1 * * — uruchamia data-retention-cleanup.ts
// anonimizuje klientów ofert odrzuconych starszych niż 2 lata
// anonimizuje klientów ofert zaakceptowanych starszych niż 5 lat
```

## AP-3: Audit-trail w tej samej tabeli co dane operacyjne

Błąd: historia zmian oferty przechowywana jako pole JSON w tabeli `offers` lub jako wiersze w `offer_history` z możliwością UPDATE/DELETE.

Dlaczego złe: jeśli użytkownik (lub atak) może zmodyfikować lub usunąć rekord z `offer_history`, nie masz wiarygodnej historii. Audytor zewnętrzny nie zaakceptuje audit-trail który można zmienić. Przy usunięciu klienta można przypadkowo skasować historię.

Właściwe podejście: snapshoty w systemie plików `artifacts/audit-trail/<offer_id>/` z hash łańcuchowym. Warstwa aplikacji nie ma operacji DELETE na snapshotach (opisano w `retencja-i-audit-trail.md`).

```sql
-- Zle
ALTER TABLE offer_history ADD COLUMN deleted_at TIMESTAMP;
DELETE FROM offer_history WHERE offer_id = :id; -- kasuje audyt!

-- Dobrze
-- brak tabeli offer_history w DB
-- snapshoty w filesystem: artifacts/audit-trail/<offer_id>/<ts>-<hash>.json
-- brak API DELETE na snapshotach
```

## AP-4: Brak klauzuli informacyjnej na dokumencie przekazywanym klientowi

Błąd: oferta PDF zawiera dane klienta (imię, adres budowy) ale brak informacji o administratorze i celu przetwarzania.

Dlaczego złe: naruszenie art. 13 RODO — administrator MA obowiązek poinformować podmiot danych w momencie zbierania danych. Klient nie wie kim jest administrator, jak długo będą trzymane dane, jakie ma prawa.

Konsekwencja: klient może złożyć skargę do PUODO. Ryzyko ostrzeżenia lub kary.

Właściwe podejście: komponent `InformationClause` w każdym szablonie PDF (opisano w `klauzula-informacyjna-szablon.md`). Klauzula generuje się automatycznie przy renderowaniu dokumentu.

## AP-5: Hard DELETE zamiast anonimizacji przy żądaniu art. 17

Błąd: implementacja „prawa do bycia zapomnianym" jako `DELETE FROM clients WHERE id = ?` bez sprawdzenia referencji.

Dlaczego złe:
- Kasuje referencje FK w tabelach `offers` — utrata integralności bazy.
- Oferty w archiwum tracą informacje o kliencie — niemożność rozpatrzenia roszczeń.
- Brak możliwości udowodnienia że żądanie zostało obsłużone (brak wpisu w audit_log dla usuniętego rekordu).
- Prawo do usunięcia ma wyjątki (art. 17.3.e — ustalenie, dochodzenie, obrona roszczeń) — hard DELETE nie pozwala na selektywność.

Właściwe podejście: anonimizacja (name=`[ZANONIMIZOWANO]`, phone=null, address=null) + log w `audit_log`. Rekord pozostaje jako pseudonim do integralności FK. Opisano w `prawa-podmiotow.md`.

## AP-6: Brak logowania żądań RODO w audit_log

Błąd: endpoint `/api/rodo/data-delete` wykonuje anonimizację, ale nie zapisuje zdarzenia. Operator nie może udowodnić że obsłużył żądanie klienta.

Dlaczego złe: w przypadku sporu klient twierdzi że dane nie zostały usunięte. Administrator nie ma dowodu że żądanie zostało obsłużone w terminie 30 dni.

Właściwe podejście: każde żądanie RODO (ACCESS, DELETE, RECTIFICATION, PORTABILITY) natychmiast logowane z timestampem i `actor_user_id` do `audit_log` z retencją 6 lat. Opisano w `prawa-podmiotow.md` (lista `RodoActionType`).

## AP-7: Zewnętrzny procesor bez umowy powierzenia (DPA)

Błąd: integracja z zewnętrznym SaaS (np. Mailchimp, Twilio SMS, zewnętrzny SMTP) przetwarzającym dane klientów bez zawarcia umowy powierzenia przetwarzania danych (art. 28 RODO).

Dlaczego złe: każdy podmiot zewnętrzny przetwarzający dane osobowych klientów w Twoim imieniu jest procesorem i wymaga pisemnej umowy DPA. Brak umowy = naruszenie RODO po stronie administratora (<firma>).

Właściwe podejście dla <projekt> v1: brak zewnętrznych procesorów przetwarzających dane klientów — <operator> sam wysyła PDF z telefonu. Jeśli w v2 pojawi się SMTP lub SMS gateway → obowiązkowa umowa DPA z dostawcą (większość ma gotowy DPA w panelu klienta).

Sygnał ostrzegawczy: gdy dodajesz do `.env` klucz API zewnętrznego serwisu który będzie widział dane klientów (imię, telefon, adres) — sprawdź czy serwis oferuje DPA i zawrzyj umowę przed wdrożeniem.
