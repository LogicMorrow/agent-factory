# Podstawy RODO dla małej firmy PL

## Administrator vs procesor — gdzie jest <firma>

| Rola | Definicja | Kto w kontekście <firma> |
|---|---|---|
| **Administrator** | Decyduje o celach i sposobach przetwarzania danych | <firma> sp. z o.o. — przetwarza dane klientów (imię, telefon, adres) |
| **Procesor (podmiot przetwarzający)** | Przetwarza dane w imieniu administratora, na jego zlecenie | Zewnętrzny dostawca SaaS (np. e-mail marketing, CRM) |
| **Współadministrator** | Dwie firmy wspólnie ustalają cele — wymaga umowy art. 26 | Nie dotyczy <projekt> v1 |

### VPS operatora — czy to powierzenie?

Jeśli właściciel VPS jest tą samą osobą co de facto właściciel firmy lub działa jako jej zaplecze IT bez odrębnej umowy — **powierzenie nie jest wymagane**. Dane nadal przetwarza administrator (<firma>), tylko na własnej infrastrukturze.

Powierzenie wymagane gdy:
- Zewnętrzna firma hostingowa (np. AWS, OVH, Hetzner) hostuje dane klientów — wtedy umowa powierzenia (DPA, art. 28 RODO).
- Zewnętrzny dostawca SaaS (np. Mailchimp, SendGrid) przetwarza dane klientów — umowa DPA.

**Dla <projekt> v1:** brak zewnętrznych procesorów przetwarzających dane klientów = brak obowiązku umów DPA poza ewentualnym dostawcą VPS prod.

## Kategorie danych przetwarzanych przez <firma>

| Kategoria | Przykłady | Reżim |
|---|---|---|
| **Dane zwykłe — identyfikacyjne** | Imię, nazwisko, telefon | Art. 6 RODO |
| **Dane zwykłe — lokalizacyjne** | Adres budowy, adres zamieszkania | Art. 6 RODO |
| **Dane wrażliwe (szczególna kategoria)** | Zdrowie, biometria, rasa, religia | Art. 9 RODO — NIE DOTYCZY |

<firma> przetwarza **wyłącznie dane zwykłe** — adres budowy bywa tożsamy z adresem zamieszkania (art. 9 nie jest aktywowany). Brak obowiązku DPIA przy normalnej skali przetwarzania.

## Podstawy prawne przetwarzania — art. 6 RODO

### 6.1.b — Wykonanie umowy (domyślna podstawa <firma>)

Stosuj gdy: przetwarzanie jest niezbędne do wykonania umowy lub podjęcia działań przed jej zawarciem (ofertowanie = działania przedumowne).

Zakres dla <firma>:
- Dane klienta na etapie ofertowania (imię, telefon, adres budowy)
- Dane na fakturze (jeśli wystawiana)
- Dane w archiwum oferty zaakceptowanej

Ograniczenie: wygasa gdy umowa wygasła lub nie doszła do skutku. Dlatego odrzucone oferty potrzebują innej podstawy dla dalszego przechowywania.

### 6.1.f — Uzasadniony interes administratora

Stosuj gdy: administrator ma prawnie uzasadniony interes, który nie jest nadrzędny wobec praw podmiotu danych. Wymaga **testu balansowania**.

Test balansowania dla archiwum odrzuconych ofert <firma>:
1. Interes administratora: zachowanie historii ofert dla ewentualnych roszczeń klientów lub sporu o warunki umowy (ochrona przed roszczeniami art. 556 KC — rękojmia).
2. Interes podmiotu danych: prywatność — ograniczony, bo dane nie są ujawniane osobom trzecim.
3. Wynik: interes administratora jest uzasadniony i proporcjonalny przy retencji max 2 lata po odrzuceniu oferty.

Dokumentuj test balansowania w Rejestrze Czynności Przetwarzania (RCP).

### 6.1.a — Zgoda (NIE stosuj w <projekt> v1)

Stosuj wyłącznie dla celów marketingowych lub gdy brak innej podstawy. <projekt> v1 nie wysyła marketingu — nie zbieramy zgód. Unikaj zbierania zgody tam gdzie działa 6.1.b — zgoda jest słabszą podstawą (można ją wycofać, co usuwa podstawę przetwarzania).

## Rejestr Czynności Przetwarzania (RCP)

Obowiązkowy dla każdego administratora (art. 30 RODO). Forma: plik, arkusz, lub tabela w dokumentacji wewnętrznej. Nie wysyła się do PUODO — przechowuje dla ewentualnej kontroli.

### Wzorzec RCP dla <firma>

| Czynność | Cel | Podstawa | Kategoria danych | Odbiorcy | Retencja |
|---|---|---|---|---|---|
| Ofertowanie | Wystawienie oferty kosztorysowej | art. 6.1.b | Imię, tel, adres budowy | Brak | Oferta akceptowana: 5 lat; odrzucona: 2 lata |
| Archiwum ofert | Ochrona przed roszczeniami | art. 6.1.f | Imię, tel, adres budowy (pseudonimizacja po retencji) | Brak | 5 lat od akceptacji, 2 lata od odrzucenia |
| Audit-trail | Integralność dokumentów + audyt IT | art. 6.1.f | Pseudonimy + hash dokumentów | Brak | 6 lat |
| Logi techniczne | Bezpieczeństwo systemu | art. 6.1.f | IP, timestamps | Brak | 90 dni |

## Kiedy wymagane dodatkowe działania

| Sytuacja | Obowiązek | Dotyczy <projekt> v1 |
|---|---|---|
| Dane wrażliwe (zdrowie, biometria) | DPIA art. 35, dodatkowe zabezpieczenia | NIE |
| >250 pracowników lub ryzykowne przetwarzanie | Pełny RCP + DPO | NIE |
| Masowe profilowanie | DPIA obowiązkowe | NIE |
| Naruszenie ochrony danych | Zgłoszenie do PUODO 72h | TAK — jeśli incydent |
| Przekazanie danych poza EOG | Mechanizm transferu (SCC, adequacy) | NIE (VPS w EOG) |
| Zewnętrzny procesor | Umowa powierzenia art. 28 | TAK — przy zewnętrznym hostingu |
