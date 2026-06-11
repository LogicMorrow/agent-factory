# Anti-patterns ofertowania ryczałtowego PL

## AP-1: Brak ważności oferty

**Wzorzec:** Oferta wystawiona bez pola `valid_until` lub z tekstem "oferta ważna do odwołania".

**Dlaczego to problem:**
- Klient wraca po 3 miesiącach z cenami materiałów z okresu wystawienia — wykonawca związany ofertą (KC art. 66 § 1: oferent jest związany ofertą przez czas w niej oznaczony lub "odpowiedni" czas).
- Wzrost cen stali/drewna w 2022–2024: +30–60% r/r — brak ważności = potencjalna strata finansowa.
- Spory sądowe o "odpowiedni czas" — sądy różnie interpretują.

**Rozwiązanie:**
```json
"valid_until": "2026-06-10"  // zawsze wymagane, domyślnie issue_date + 14 dni
```

Walidacja: `valid_until` musi być datą co najmniej 1 dzień po `issue_date`. Brak lub pusta wartość = BLOKUJĄCY błąd walidacji.

---

## AP-2: VAT 8% na budynku niemieszklanym

**Wzorzec:** Wykonawca stosuje 8% na wszystkich pracach "bo dekarstwo to 8%", nie sprawdzając obiektu.

**Przykład błędu:**
- Klient: "Proszę o wycenę dachu na budynku gospodarczym"
- Oferta: VAT 8% (błąd) zamiast 23%

**Konsekwencje:**
- Kontrola US: obowiązek dopłaty VAT (różnica 15 pp.) + odsetki (aktualnie 8% rocznie)
- Ewentualna kara za zaniżenie podatku
- Korekta faktury i oferty — profesjonalne ryzyko reputacyjne

**Rozwiązanie:**
- Pole `building_type` w formularzu oferty — wymagane (brak = blokada generowania PDF)
- Drzewo decyzyjne VAT automatycznie dobiera stawkę (patrz `vat-pl-uslugi-budowlane.md`)
- Ostrzeżenie w UI gdy `building_type = non-residential` i użytkownik próbuje ustawić 8%

---

## AP-3: Mieszanie oferty z fakturą — "zrobię fakturę zamiast oferty"

**Wzorzec:** Wykonawca wystawia od razu fakturę pro forma lub fakturę VAT jako "ofertę" i wysyła klientowi zamiast oferty handlowej.

**Dlaczego to problem:**
- Faktura VAT wystawiona przed realizacją bez podstawy prawnej (zamówienia, umowy) → błąd podatkowy
- Klient może traktować fakturę pro forma jako zobowiązanie do zapłaty (różna interpretacja)
- Brak możliwości odmowy przez klienta bez konsekwencji — oferta handlowa daje klientowi możliwość odrzucenia

**Rozwiązanie:**
- W dokumentach: wyraźne oznaczenie "OFERTA" (nie "FAKTURA") w nagłówku PDF
- Informacja w stopce: "Dokument nie stanowi faktury VAT"
- Faktura VAT generowana osobno po realizacji i akceptacji — osobny workflow, poza v1

---

## AP-4: Brak uzasadnienia stawki VAT

**Wzorzec:** Oferta z VAT 8% ale bez wyjaśnienia dlaczego 8%, nie 23%.

**Dlaczego to problem:**
- Przy kontroli US wykonawca musi udowodnić zasadność 8% — brak dokumentacji = domniemanie błędu
- Klient może zakwestionować stawkę jeśli nie wie czemu 8%, a nie 23%
- US może wymóc korektę i dopłatę z odsetkami

**Rozwiązanie:**
- Pole `vat_justification` obowiązkowe (walidacja: niepusty string, min 20 znaków)
- Widoczne w PDF oferty w stopce lub adnotacji (nie można usunąć z szablonu)

---

## AP-5: Zaokrąglanie pośrednich kwot

**Wzorzec:**
```javascript
// Błąd: zaokrąglanie każdej pozycji z osobna
const items = [
  { net: 1000.005 },  // zaokrąglone do 1000.01
  { net: 2000.005 },  // zaokrąglone do 2000.01
];
const totalNet = items.reduce((s, i) => s + i.net, 0);  // 3000.02 — błąd groszy
```

```javascript
// Poprawnie: zaokrąglaj tylko wynik końcowy
const items = [
  { net: 1000.005 },  // surowa wartość
  { net: 2000.005 },  // surowa wartość
];
const totalNet = roundBankers(items.reduce((s, i) => s + i.net, 0), 2);  // 3000.01
```

**Konsekwencja:** różnice groszowe między pozycjami a sumą → PDF wygląda nieprofesjonalnie, księgowy klienta może kwestionować dokument.

---

## AP-6: Jeden VAT dla mixed oferty (usługa + materiał)

**Wzorzec:** Oferta zawiera jednocześnie robociznę dekarską (8%) i sprzedaż drewna luzem (23%), ale wystawiana z jedną stawką VAT 8%.

**Przykład błędu:**
```json
{
  "items": [
    { "label_pl": "Montaż więźby", "category": "roofing", "amount_net_pln": 5000 },
    { "label_pl": "Drewno sosnowe KVH — wykaz", "category": "custom", "amount_net_pln": 3000 }
  ],
  "vat_rate": 0.08  // błąd — drewno luzem to dostawa 23%
}
```

**Rozwiązanie:** rozdziel ofertę na dwa dokumenty (lub dwa bloki z osobnymi VAT) gdy zakres mieszany. Jeśli drewno jest wbudowane w usługę montażu (nie sprzedawane osobno) — jedna stawka 8% jest OK.

---

## AP-7: Oferta bez numeru / bez archiwizacji

**Wzorzec:** Oferty generowane bez numeracji, bez zapisywania w systemie — tylko do pobrania.

**Dlaczego to problem:**
- Klient ma "ofertę z maja" ale nie wiadomo którą z trzech wysłanych
- Brak możliwości odtworzenia co było oferowane przy sporze
- US może wymagać historii dokumentów przy kontroli

**Rozwiązanie:**
- Każda oferta ma `document_number` w formacie `OF/<rok>/<seq>` (np. `OF/2026/001`)
- Snapshot JSON oferty zapisywany do `artifacts/audit-trail/` (patrz hook `audit-trail-on-offer-write.sh`)
- Archiwum ofert przeszukiwalne po nazwisku / adresie / roku

---

## Checklist przed generowaniem PDF

Automatyczna walidacja przed wywołaniem `pdf-document-templates`:

```
[ ] document_number — niepuste
[ ] issue_date — format ISO 8601, nie w przyszłości
[ ] valid_until — późniejsze niż issue_date o min. 1 dzień
[ ] client.name — niepuste, min. 3 znaki
[ ] client.address — niepuste
[ ] items.length >= 1
[ ] items każdy: label_pl niepuste, amount_net_pln > 0
[ ] vat_rate — 0.08 lub 0.23 (tylko te wartości)
[ ] vat_justification — niepuste, min. 20 znaków
[ ] totals.net_pln === sum(items[].amount_net_pln) zaokrąglone do 2dp
[ ] totals.vat_amount_pln === roundBankers(net_pln × vat_rate, 2)
[ ] totals.gross_pln === net_pln + vat_amount_pln
[ ] payment_terms.advance_percent + remaining_percent === 100
```

Wszystkie elementy z `[ ]` = blokujący błąd walidacji. Nie generuj PDF z błędami.
