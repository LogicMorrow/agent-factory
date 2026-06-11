---
name: regional-seo-poland
description: Local SEO PL — Google Business Profile optimization (10 GBP categories EN canonical), NAP consistency, citation building (priority queue P1-P5, top 20 PL portali), reviews playbook (email + SMS + WhatsApp PL templates), 16 województw × 10 powiatów dict + demand_construction. Pattern reuse dla ekspansji regionalnej.
version: 1.0.0
compatible_with: [universal]
tags: [seo, local, regional, gbp, pl]
requires: [seo-fundamentals, polish-language-seo]
token_cost: medium
distribution: library/skills/universal/
last_updated: 2026-05-11
---

# regional-seo-poland

Wiedza GEO-specyficzna dla SEO regionalnego PL. Nadbudowa nad `seo-fundamentals` (meta, LocalBusiness schema — JEST TAM) i `polish-language-seo` (fleksja, transliteration, katalogi PL — JEST TAM). Tu: GEO — województwa, Google Business Profile deep, NAP consistency, citation building strategia, reviews playbook.

**Bundle pliki:**
- `SKILL.md` — wiedza referencyjna (ten plik)
- `wojewodztwa-powiaty.yaml` — 16 województw × 10 powiatów = 160 entries + demand_construction
- `gbp-checklist.md` — GBP setup / optimization / ongoing tasks (120-200 linii)
- `nap-template.md` — NAP format PL dla branży budowlanej + audyt checklist (80-120 linii)

**Prerequisite:** `seo-fundamentals` wdrożone (LocalBusiness schema, areaServed, PostalAddress) + `polish-language-seo` (fleksja, stop words, katalogi PL jako data źródłowe).

---

## When to use this skill

Uruchamiaj gdy:
- `seo-strategist` projektuje local SEO dla firmy PL z fizyczną lokalizacją
- `local-seo-specialist` konfiguruje GBP, audytuje NAP, buduje citation queue
- Projekt klienta ma budżet na local pack (Google Maps 3-pak) — podstawa: GBP + NAP
- Firma działa w konkretnym województwie/regionie PL i szuka ekspansji na sąsiednie powiaty
- Zbierasz/odpowiadasz na opinie Google — potrzeba gotowych templates PL

NIE uruchamiaj gdy:
- Brakuje meta tagów, LocalBusiness schema, sitemapy → `seo-fundamentals`
- Szukasz wariantów fleksyjnych keyword lub transliteration URL → `polish-language-seo`
- Planujesz topical clusters, E-E-A-T content → `seo-advanced`
- Piszesz content regionalny (landing page "Firma budowlana Warszawa") → `seo-content-writer` (5B)
- Audytujesz site live (Lighthouse, GSC pull) → `seo-auditor`

---

## 1. Google Business Profile (GBP) optimization

GBP to fundament local pack (3-pak Google Maps). Bez GBP firma nie pojawia się w wynikach lokalnych niezależnie od jakości strony.

### Kategorie GBP — branża budowlana (GW)

GBP używa angielskich nazw kategorii canonical — w profilu klienta widzą polskie tłumaczenie.

| Slot | Kategoria EN (canonical) | Kiedy używać |
|---|---|---|
| **Primary** | **General contractor** | Generalny wykonawca — budownictwo od fundamentów |
| Secondary 1 | Construction company | Firmy budowlane ogólnobudowlane |
| Secondary 2 | Custom home builder | Budowa domów jednorodzinnych na zamówienie |
| Secondary 3 | Building design company | Jeśli firma oferuje też projektowanie |
| Secondary 4 | Roofing contractor | Wykonawstwo dachowe |
| Secondary 5 | Mason | Murarstwo, prace murowe |
| Secondary 6 | Concrete contractor | Fundamenty, wylewki betonowe |
| Secondary 7 | Foundation contractor | Specjalizacja fundamenty |
| Secondary 8 | Building consultant | Doradztwo budowlane |
| Secondary 9 | Construction equipment supplier | Jeśli firma wynajmuje sprzęt |

**Reguła:** primary category = najważniejsza usługa (od niej zależy ranking w local pack). Secondary = 3-9 kategorii uzupełniających. NIE dodawaj kategorii niezwiązanych — penalty.

**Inna sub-branża GW?** Jeśli firma specjalizuje się w Roofing (nie generalka): primary = "Roofing contractor". Sprawdź listę kategorii Google pod "GBP category tool" lub `pleper.pl/google-business-profile-kategorie`.

### Kluczowe elementy optymalizacji GBP

- **Weryfikacja:** pocztówka (7-14 dni), telefon (natychmiastowa dla uprawnionych), wideo (nowe — konto musi mieć 3 miesiące aktywności). Bez weryfikacji profil nie jest publicznie widoczny.
- **Godziny:** uzupełnij godziny główne + godziny wyjątkowe (święta, urlopy) — "Nie podano godzin" obniża ranking.
- **Atrybuty branżowe:** Wykonuje usługi na miejscu, Obsługuje klientów indywidualnych, Oferuje wycenę online — dostępność zależy od wybranej kategorii.
- **Zdjęcia min 10 initial:** hero fasada/logo, interior biura/warsztatu, zespół, realizacje (min 5), certyfikaty/nagrody. Cadence: +1-2/tydzień (sygnał aktywności).
- **Posty cadence:** 1-2/tydzień. Typy: Oferta (promocja), Nowości (realizacja), Wydarzenie, FAQ. Rzadkość poniżej 1/miesiąc = sygnał "martwa firma".
- **FAQ / Q&A:** dodaj min 5 pytań w sekcji Q&A (sam zadaj, sam odpowiedz). Pytania klientów też monitoruj i odpowiadaj w 24-48h.
- **Produkty/Usługi:** uzupełnij sekcję Services z opisem i ceną (lub "Cena na zapytanie") — pojawia się w profilu firmy.

Deep checklist setup/optymalizacja/ongoing → `gbp-checklist.md`.

---

## 2. NAP consistency

NAP = Name, Address, Phone. Google porównuje NAP across wszystkich citations — niespójność (różne formaty, różny numer) sygnalizuje nierzetelność i obniża local ranking.

### Wzorzec NAP dla branży budowlanej PL

```
Name:    {{COMPANY_LEGAL_NAME}} sp. z o.o.
         (lub sp.j. / s.c. / jednoosobowa działalność — użyj pełnej nazwy z KRS)

Address: ul. {{STREET}} {{NUMBER}}, {{POSTCODE}} {{CITY}}, woj. {{WOJEWODZTWO}}
         Przykład: ul. Lipowa 12, 20-001 Warszawa, woj. mazowieckie

Phone:   +48 {{AREA_CODE}} {{NUMBER}}
         Przykład: +48 81 123 45 67 (landline) lub +48 501 234 567 (komórka)
```

**Zasada spójności:** ten sam format wszędzie — GBP, Aleo, Panorama, OLX, www, social. Jedna zmiana adresu = ponowny audyt WSZYSTKICH citations.

Pary "dobrze/źle" NAP i audyt checklist → `nap-template.md`.

---

## 3. Citation building — priority queue P1-P5

Citation = każde miejsce w internecie gdzie pojawia się NAP firmy. Ilość + jakość citations to ranking factor local SEO.

**Zasada:** `polish-catalogs.json` (z `polish-language-seo` E3) zawiera metadane 18 katalogów (URL, format NAP, submission method, koszt). Tu używamy ich jako strategię z priorytetem. Dodajemy GBP (P1) + Tablica.pl (nie ma w E3) = 20 portali total.

### Kolejka priorytetów

| Priorytet | Portal | Audience | Koszt | Uwaga |
|---|---|---|---|---|
| **P1** | Google Business Profile | Lokalni klienci Google Maps | Free | Zawsze PIERWSZY — bez GBP nie ma local pack |
| **P2** | Aleo | B2B przetargi, podwykonawcy | Freemium | Weryfikacja NIP — kluczowy B2B |
| **P2** | Panorama Firm | Lokalni klienci, Google Maps integration | Freemium | Citation + recenzje |
| **P3** | MuratorPlus | Architekci, inwestorzy, branża | Płatny (model freemium) | Autorytet editorial — E-E-A-T backlink |
| **P3** | FirmyBudowlane.pl | Inwestorzy szukający firm budowlanych | Freemium | Niszowy = wysoka intencja zakupu |
| **P3** | BudGet | Kosztorysy, oferty budowlane | Freemium | Aktywni zamawiający |
| **P3** | Oferia | Zlecenia usługowe, wyceny | Freemium (kontakty płatne) | Model incoming zapytań |
| **P4** | OLX | B2C lokalne, ogłoszenia | Freemium | Największy PL classified — zasięg ogólny |
| **P4** | Allegro Lokalnie | B2C lokalne | Freemium | Mniejszy zasięg niż OLX dla usług |
| **P4** | Tablica.pl | B2C ogłoszenia lokalne | Freemium | Dodatkowe citation, marginalny ruch |
| **P5** | BudoGuru | Prosumenci budowlani | Freemium | Nisza inwestorów indywidualnych |
| **P5** | Pkt.pl | Ogólny katalog firm | Freemium | Dobre DA — citation |
| **P5** | Gratka.pl | B2C ogłoszenia | Freemium | Mniejszy niż OLX |
| **P5** | Otodom | Nieruchomości | Płatny | Tylko jeśli GW sprzedaje domy |
| **P5** | Morizon | Nieruchomości | Płatny | Jak Otodom — tylko deweloper |
| **P5** | Domiporta | Nieruchomości | Płatny | Jak Otodom — tylko deweloper |
| **P5** | Tabelaofert.pl | Nowe mieszkania | Płatny | Tylko deweloper |
| **P5** | Sprzedajemy.pl | B2C ogłoszenia | Freemium | Mniejszy zasięg, dodatkowe citation |
| **P5** | Gumtree PL | B2C ogłoszenia | Freemium | Marginalny ruch dla usług budowlanych |
| **P5** | (inne z polish-catalogs.json) | — | — | Extend per potrzebę |

**Plan submisji:**
- Tydzień 1: P1 (GBP) + P2 (Aleo, Panorama)
- Tydzień 2-3: P3 (4 portale) — focus branżowe
- Miesiąc 2: P4 + najważniejsze P5
- Ongoing: monitoruj aktywność listingów, odpowiadaj na recenzje

**Weryfikacja po submisji:** sprawdź listing po 7-14 dniach — czy dane widoczne, czy NAP zgodne z wzorcem.

**Boundary z `polish-language-seo`:** `polish-catalogs.json` (E3) = meta katalogów (URL, format NAP, submission). Ten skill = strategia submisji z priorytetem i planem działań. Nie duplikuj danych katalogu — referencuj `polish-catalogs.json`.

---

## 4. Reviews playbook PL

Opinie to ranking signal GBP (liczba + średnia + aktualność + odpowiedzi). Playbook = kiedy prosić, jak prosić, jak odpowiadać.

### Kiedy prosić o opinię

- **Moment:** po zakończeniu etapu prac (nie po pierwszej wizycie) lub po odbiorze końcowym
- **Format:** ustny "Bylibyśmy wdzięczni za opinię" → follow-up pisemny w 24-48h
- **Kanał:** wybierz aktywny dla klienta — defaulty poniżej

### Templates request (PL)

**Email — universal (formal):**
```
Temat: Dziękujemy za współpracę — [Nazwa firmy]

Szanowni Państwo,

Dziękujemy za powierzone nam prace budowlane. Mamy nadzieję, że realizacja
spełniła Państwa oczekiwania.

Bylibyśmy bardzo wdzięczni, gdyby zechcieli Państwo podzielić się swoją opinią
na naszym profilu Google — zajmuje to tylko chwilę:
[LINK do profilu Google Maps — skrócony via g.page/twojafirma]

Opinie pomagają nam doskonalić usługi i są cenną informacją dla innych klientów.

Z poważaniem,
[Imię i nazwisko] | [Stanowisko]
[Nazwa firmy]
```

**SMS — formal/urzędowy (160 znaków):**
```
Dziękujemy za współpracę! Będziemy wdzięczni za opinię na Google:
[LINK] — [Nazwa firmy]
```

**WhatsApp — informal/follow-up (gdy klient komunikuje się WhatsApp):**
```
Cześć [Imię]!

Fajnie się z Tobą pracowało przy projekcie. Jeśli jesteś zadowolony/a,
będziemy wdzięczni za krótką opinię na Google — zajmie dosłownie minutę:
[LINK]

Dzięki i do zobaczenia przy kolejnym projekcie!
[Imię wykonawcy]
```

**Wybierz aktywne kanały:** email = ALWAYS. SMS = klienci preferujący formalny kontakt. WhatsApp = klienci z którymi masz aktywną konwersację WhatsApp. Nie wysyłaj na wszystkich 3 naraz — wyglądasz desperacko.

### Templates response (PL)

**Odpowiedź na opinię pozytywną (4-5 gwiazdek):**
```
Dziękujemy za ciepłe słowa, [Imię klienta]! Cieszymy się, że realizacja
[temat projektu, np. "budowy fundamentów"] spełniła Państwa oczekiwania.
Zapraszamy do współpracy przy kolejnych projektach!
```

**Odpowiedź na opinię negatywną (1-2 gwiazdki):**
```
Szanowna Pani/Szanowny Panie [Imię], dziękujemy za feedback — traktujemy
każdą opinię poważnie. Przykro nam, że realizacja nie spełniła oczekiwań.
Prosimy o kontakt bezpośredni na [email/telefon], aby wyjaśnić sytuację
i znaleźć rozwiązanie. Zależy nam na satysfakcji każdego klienta.
```

**Odpowiedź na opinię neutralną (3 gwiazdki, bez komentarza):**
```
Dziękujemy za ocenę! Zależy nam na doskonaleniu usług — jeśli moglibyśmy
coś poprawić, prosimy o kontakt bezpośredni. Będziemy wdzięczni za wszelkie
sugestie.
```

### Schema Review/AggregateRating integration

Schema `Review` i `AggregateRating` zdefiniowane w `seo-fundamentals` (E1) sekcja 2. Do integracji z GBP:
- `AggregateRating` w JSON-LD `LocalBusiness` — importuj z `seo-fundamentals/schema-templates.json`
- Tylko **prawdziwe opinie** — schema z wymyślonych recenzji → manual penalty Google
- `ratingValue` i `reviewCount` muszą odpowiadać rzeczywistym danym Google

---

## 5. Województwa jako modifier

16 województw to natural keyword modifier dla local SEO PL. Firmie z Warszawy dodajemy "mazowieckie" do targeting. Dict z pełnymi danymi → `wojewodztwa-powiaty.yaml`.

### Demand classification (GUS Budownictwo mieszkaniowe 2024)

| Demand | Województwa (5/6/5) | Strategia |
|---|---|---|
| **HIGH** | mazowieckie, dolnoslaskie, malopolskie, wielkopolskie, pomorskie | Agresywne GBP + citation + ads |
| **MED** | slaskie, lodzkie, kujawsko-pomorskie, zachodniopomorskie, mazowieckie, małopolskie | Solidna baza GBP + top P1-P3 citations |
| **LOW** | swietokrzyskie, lubuskie, opolskie, podlaskie, warminsko-mazurskie | GBP + P1-P2, focus organic + referrals |

**Metodologia:** klasyfikacja oparta na rocznej liczbie pozwoleń na budowę per województwo (GUS "Budownictwo mieszkaniowe 2024"). HIGH = top 5 województw pod względem liczby pozwoleń.

### Pary "dobrze/źle" — użycie województwa w SEO

**Scenario 1 — keyword targeting z województwem:**
```
DOBRZE: Meta title: "Budowa domu jednorodzinnego Warszawa | Firma GW Mazowieckie"
        (miasto primary keyword, województwo secondary — natural geo modifier)

ZLE:    Meta title: "Firma budowlana mazowieckie mazowieckie budowa domów tanio"
        (duplikacja, keyword stuffing — penalty BERT)
```

**Scenario 2 — URL z regionem:**
```
DOBRZE: /uslugi/budowa-domu           (universal URL)
        + tag/kategoria "mazowieckie" w CMS
        + dedykowany landing "/mazowieckie/budowa-domu" jeśli realnie serwujesz region

ZLE:    /mazowieckie/fundamenty          (region w URL bez dedykowanej treści = doorway page)
        /mazowieckie/sciany/mazowieckie    (duplikacja regionu w path)
```

### Powiaty jako głębszy targeting

Top-10 powiatów per województwo → `wojewodztwa-powiaty.yaml`. Użyj gdy firma serwuje konkretne powiaty (nie całe województwo). Przykład: firma z Warszawy serwuje powiaty: mazowiecki, puławski, świdnicki — landing pages lub meta targety per powiat.

---

## 6. Pattern reuse — jak rozszerzyć na nowy region

**Adapter pattern dla nowego województwa lub powiatu:**

1. **Wczytaj** `wojewodztwa-powiaty.yaml` → sprawdź entry dla docelowego województwa
2. **Sprawdź demand_construction** — HIGH = inwestuj więcej w citation P4-P5, LOW = fokus P1-P3
3. **Uzupełnij override lokalnego dialektu (jeśli potrzeba):**
   - Śląskie: "kamienica" (PL ogólne: "blok mieszkalny") — jeśli firma z regionu, użyj lokalnego
   - Małopolskie: Kraków i Przemyśl mają własne portale lokalne (np. nowiny24.pl, krakow.pl)
4. **Local listings discovery:** wyszukaj `"[miasto] + branża + katalog firmy"` — lokalne portale informacyjne często mają własne katalogi (cityportal.pl, MiastoXYZ.pl) nie ujęte w polish-catalogs.json
5. **Zaktualizuj GBP areaServed** — dodaj nowe powiaty do `areaServed: []` w LocalBusiness schema

**Szablon rozszerzenia:**
```yaml
# Override dla nowego regionu (przykład: małopolskie)
nowy_region:
  wojewodztwo: małopolskie
  demand_construction: MED
  primary_city: Krakow
  local_portals:
    - url: "nowiny24.pl/firmy"
      priority: MED
      note: "Lokalny portal Podkarpacie — citation"
  dialect_notes:
    - "Krakow: popularne 'krakowianie' zamiast 'mieszkancy Krakowa'"
```

---

## Powiązania

**Skille (load przed `regional-seo-poland`):**
- `seo-fundamentals` (E1) — LocalBusiness JSON-LD, areaServed, PostalAddress format PL, Review/AggregateRating schema templates
- `polish-language-seo` (E3) — `polish-catalogs.json` (18 katalogów meta), fleksja PL dla nazw województw/miast

**Skille (powiązane, NIE wymagane):**
- `seo-advanced` (E2) — E-E-A-T markers per industry (cross-ref dla construction reviews authority)

**Agenty downstream (konsumują `regional-seo-poland`):**
- `seo-strategist` (E5) — citation queue input do content roadmap
- `seo-auditor` (E6) — audit NAP consistency + GBP setup completeness
- `local-seo-specialist` (5B) — wykonawca GBP setup, citation submission, review request automation
- `seo-content-writer` (5B) — wojewódzkie modyfikatory w title/meta/H1 (np. "Budowa domu mazowieckie")
- `competitor-watcher` (5D) — monitoring konkurencji per region (wojewódzkie SERPs)

Boundary z każdym z 3 najbliższych powiązań — sekcje poniżej.

---

## Boundary z seo-fundamentals (E1)

**seo-fundamentals (E1):** LocalBusiness JSON-LD struktura, `areaServed` pole, `PostalAddress` format PL, `Review`/`AggregateRating` schema template (używaj schema-templates.json z E1).

**regional-seo-poland (TU):** Google Business Profile DEEP (10 kategorii, godziny, atrybuty, foto, posty, Q&A), NAP consistency wzorzec, citation queue P1-P5 (20 portali), reviews playbook (6 templates), województwa+powiaty dict.

| Pytanie | Skill |
|---|---|
| "Jak zbudować LocalBusiness JSON-LD?" | `seo-fundamentals` |
| "Jaka jest struktura pola areaServed?" | `seo-fundamentals` |
| "Jak skonfigurować GBP dla firmy budowlanej w Warszawie?" | `regional-seo-poland` |
| "Jak zbierać opinie Google po zakończeniu projektu?" | `regional-seo-poland` |

---

## Boundary z polish-language-seo (E3)

**Kluczowa granica: LANGUAGE vs GEO.**

**polish-language-seo (E3):** fleksja PL keyword research (7 przypadków), transliteration ąęłńóśźż → ASCII, stop words PL, polskie SERP behavior. `polish-catalogs.json` = meta katalogów (URL, format, submission).

**regional-seo-poland (TU):** gdzie geograficznie — województwa, powiaty, GBP deep, NAP consistency, citation building (strategia submisji z priorytetem), reviews playbook, demand_construction mapping.

Cross-ref: `polish-catalogs.json` (E3) dostarcza dane katalogów → regional-seo-poland używa je w priority queue P1-P5. Nie duplikuj danych katalogów w tym skillu — referencuj `polish-catalogs.json`.

| Pytanie | Skill |
|---|---|
| "Jak deklinować 'Warszawa' we wszystkich przypadkach?" | `polish-language-seo` |
| "Jak skonfigurować GBP dla firmy w Warszawie?" | `regional-seo-poland` |
| "Jak pisać URL slug po polsku?" | `polish-language-seo` |
| "Jak budować cytowania NAP w woj. mazowieckim?" | `regional-seo-poland` |
| "Jakie są metadane katalogu Aleo?" | `polish-language-seo` → `polish-catalogs.json` |
| "W jakim priorytecie submittować do Aleo?" | `regional-seo-poland` → sekcja 3 (P2) |

---

## Boundary z local-seo-specialist (agent 5B)

**regional-seo-poland (TEN SKILL):** wiedza referencyjna — dane statyczne (16 województw dict, GBP kategorie, NAP template, citation queue). Skill = data + procedure.

**local-seo-specialist (agent 5B, planowany):** wykonawca — czyta ten skill, uruchamia checklisty, robi audyt NAP dla konkretnego projektu, dopisuje konkretne listings dla danego klienta. Agent = action.

Podział: skill NIE tworzy plików, NIE modyfikuje profili — to agent. Skill dostarcza wiedzę, agent ją wykonuje.

---

## Anti-patterns

| Anti-pattern | Mechanizm problemu | Naprawa |
|---|---|---|
| **Fake reviews schema** | JSON-LD `Review` z wymyślonych recenzji → manual penalty Google, deindeksacja | Tylko prawdziwe opinie z imieniem + datą. Zero fikcji. |
| **Niespójne NAP** | "ul. Lipowa" w GBP vs "Ulica Lipowa" w Aleo vs "+48 81 123..." vs "81 123..." | Jeden wzorzec NAP (patrz sekcja 2), stosuj wszędzie. Audyt checklist w `nap-template.md` |
| **GBP keyword stuffing w nazwie** | "JanKowalski Budowa Domów Mazowieckie" zamiast "JanKowalski" | GBP Terms of Service: nazwa profilu = prawna nazwa firmy. Violation = suspension |
| **Pominięcie GBP weryfikacji** | Unverified profil = brak widoczności w local pack | Weryfikuj natychmiast po setup — pocztówka, telefon lub wideo |
| **Citation w low-DA katalogach ze spamem** | Backlink z toxycznego katalogu może zaszkodzić, nie pomóc | Submittuj tylko do portali z listy P1-P5. Sprawdź DA (Moz/Ahrefs) przed nieznany katalogiem |
| **Województwa w URL bez realnej treści** | `/mazowieckie/fundamenty` bez unikalnej strony dla woj. mazowieckiego = doorway page | Twórz landing page per region tylko gdy masz unikalną treść. Bez contentu = tag/filtr, nie URL |
| **Brak hreflang dla PL multi-region** | Jeśli masz subdomeny per miasto (warszawa.firma.pl, krakow.firma.pl) bez hreflang → duplicate content | Ustaw hreflang per subdomena LUB użyj jednej domeny z lokalnymi landing pages |
| **Posty GBP rzadkie** | Cadence <1/miesiąc = sygnał "martwa firma" → obniżenie local ranking | Min 1 post/tydzień. Przygotuj bank postów na 4 tygodnie z góry |
| **Reviews bait — incentywizowanie materialne** | Oferowanie rabatu/nagrody za opinię = Google TOS violation → ryzyko suspension profilu | Proszenie naturalne (templates sekcja 4) bez materialnej zachęty |
| **Zmiana NAP raz na rok** | Google potrzebuje czasu na reindeksację. Każda zmiana = ranking reset GBP na 2-8 tygodni | Ustal stały NAP format PRZED pierwszym submission. Zmiana = audyt wszystkich citations natychmiast |

---

## References

- **Google Business Profile Help Center:** https://support.google.com/business
- **Google Search Quality Rater Guidelines (Local):** https://static.googleusercontent.com/media/guidelines.raterhub.com/en//searchqualityevaluatorguidelines.pdf
- **web.dev — Local SEO guide:** https://web.dev/articles/local-seo
- **Whitespark — Citation Building Guide:** https://whitespark.ca/local-citation-finder/
- **Moz — Local SEO Learning Center:** https://moz.com/learn/seo/local
- **GUS Budownictwo mieszkaniowe 2024:** https://stat.gov.pl/obszary-tematyczne/przemysl-budownictwo-srodki-trwale/budownictwo/budownictwo-mieszkaniowe-2024/
- **Poczta Polska — kody pocztowe (NAP reference):** https://kody.poczta-polska.pl/

---

## How to extend / customize

Sekcja 6 ("Pattern reuse") zawiera adapter pattern dla nowego regionu. Kroki:
1. Wczytaj `wojewodztwa-powiaty.yaml` → entry dla nowego województwa
2. Sprawdź demand_construction → dostosuj agresywność citation building
3. Wyszukaj local portals specyficzne dla miasta/regionu
4. Uzupełnij dialect_notes jeśli region ma specyficzne określenia (śląskie, kaszubskie)
5. Zaktualizuj GBP `areaServed` + landing pages per powiat jeśli serwujesz

**Inna branża niż budowlana:** sekcja 1 (GBP kategorie) ma reguły wyboru — wybierz primary category odpowiednią dla swojej branży. P1-P5 citation queue: P3 portale branżowe (MuratorPlus, FirmyBudowlane.pl) zamień na portale swojej branży. `polish-catalogs.json` (E3) ma `priority_for_construction` — dodaj `priority_for_{twoja_branza}` dla własnej klasyfikacji.
