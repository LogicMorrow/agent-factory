---
name: quotation-pl-rules
description: Reguły ofertowania ryczałtowego PL — VAT 8/23%, struktura oferty, pozycje kosztorysowe (dekarstwo jako referencja), kontrakt z pdf-document-templates. Uruchamiaj gdy agent generuje ofertę PL lub kalkuluje VAT dla usług budowlano-montażowych.
version: 1.0.0
compatible_with: [universal]
tags: [domain, quotation, vat, poland, ryczalt]
requires: []
token_cost: medium
distribution: library/skills/universal/
last_updated: 2026-05-27
last_reviewed: 2026-05-29
valid_until: 2027-05-27
---

# quotation-pl-rules — Ofertowanie ryczałtowe PL

## Kiedy uruchomić

Uruchom ten skill gdy:
- Agent generuje ofertę ryczałtową dla klienta PL (wycena robocizny, usługa budowlana/dekarska).
- Agent kalkuluje VAT dla usług budowlano-montażowych lub sprzedaży materiałów.
- Agent produkuje dane wejściowe dla skilla `pdf-document-templates` (kontrakt JSON).
- Agent waliduje lub parsuje ofertę PL pod kątem kompletności prawnej.

Nie uruchamiaj gdy: generujesz fakturę VAT (inny dokument prawny), kosztorys inwestorski (normy PN), lub ofertę eksportową poza PL.

## Pliki tematyczne (index)

| Plik | Zawartość |
|---|---|
| `vat-pl-uslugi-budowlane.md` | Stawki VAT 8/23%, drzewo decyzyjne, wyjątki dla materiałów |
| `struktura-oferty.md` | Obowiązkowe elementy prawne oferty PL + JSON schema kontraktu |
| `pozycje-kosztorysowe.md` | Kategorie dekarskie + wzorzec rozszerzalny na inne domeny |
| `anti-patterns.md` | 7 typowych błędów ofertowych z konsekwencjami prawnymi |

## Kluczowe zasady (summary)

1. **Oferta ryczałtowa ≠ faktura VAT** — oferta to dokument handlowy (pre-kontraktowy), faktura to dokument księgowy wystawiany po realizacji lub na zaliczkę. Mylenie statusu powoduje problemy z US.
2. **VAT zależy od obiektu, nie usługi** — ta sama robota dekarska: 8% na budynku mieszk. ≤300 m², 23% na garażu wolnostojącym. Klasyfikuj obiekt przed wystawieniem oferty.
3. **Materiały sprzedawane osobno → zawsze 23%** — nawet jeśli usługa montażu jest w 8%. Drewno jako pozycja dostawy (nie wbudowane) = 23%.
4. **Ważność oferty MUSI być wpisana** — domyślnie 14 dni. Brak ważności = ryzyko sporu gdy klient wróci po 3 miesiącach z cenami sprzed inflacji.
5. **Suma brutto = suma netto + VAT** — zaokrąglenie do 2 miejsc po przecinku, reguła bankowa (round half to even, IEEE 754). Nigdy nie zaokrąglaj pośrednich wartości — zaokrąglaj tylko końcowy wynik.
6. **Format liczb PL** — separator tysięcy: spacja (np. `1 500,00 PLN`), separator dziesiętny: przecinek, waluta: sufiks `PLN`.
7. **Oferta ryczałtowa jest zasadna** dla usług <50 000 zł netto z jasno określonym zakresem i klientem indywidualnym (B2C lub micro-B2B). Powyżej i przy umowie B2B na roboty budowlane — kosztorys + umowa o roboty budowlane (KC art. 647+).

## Powiązania

- **`pdf-document-templates`** (library/skills/webapp) — konsument JSON schema z `struktura-oferty.md`. Kontrakty danych: sekcja "Kontrakt z pdf-document-templates" w pliku `struktura-oferty.md`.
- **`roofing-domain-rules`** (library/skills/universal) — słownik drewna dekarskiego, typy przekrojów, walidacja wymiarów. Komplementarny — `quotation-pl-rules` pokrywa finanse, `roofing-domain-rules` pokrywa materiałoznawstwo.
- **`webapp-calculator-patterns`** (library/skills/webapp) — wzorce UX kalkulatorów (input field design, walidacja formularzy). NIE zawiera merytoryki VAT — ten skill jest źródłem reguł biznesowych.
- **`data-protection-rodo-pl`** (library/skills/universal) — oferta zawiera dane osobowe klienta (imię, telefon, adres). Retencja ofert i prawa podmiotów — patrz ten skill.
- **`calculator-rules-engine`** (library/skills/webapp) — silnik obliczeń. Reguły zaokrągleń z `quotation-pl-rules` implementowane przez `calculator-rules-engine`.
