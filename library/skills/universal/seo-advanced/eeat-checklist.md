# E-E-A-T Checklist per industry

Plik pomocniczy do `seo-advanced` SKILL.md sekcja 2. Szczegółowy checklist per branża.

Legenda kolumn:
- **Marker** — konkretny element E-E-A-T
- **Typ** — Experience / Expertise / Authority / Trust
- **Gdzie wstawić** — location na stronie lub pole schema
- **Jak weryfikować** — sposób sprawdzenia obecności/prawdziwości

---

## E-E-A-T: Construction (Branża budowlana)

Branża YMYL-adjacent — inwestycja 300-600k PLN, bezpieczeństwo konstrukcji. Wysoki próg E-E-A-T.

| Marker | Typ | Gdzie wstawić | Jak weryfikować |
|---|---|---|---|
| Case study: realizacja (m², lokalizacja, czas, zdjęcia before/after) | Experience | Blog post / portfolio page + Article schema | Min 3 realizacje z datami + zdjęciami z budowy (nie stock photos) |
| Imię i nazwisko autora artykułu (kierownik budowy / architekt) | Experience + Expertise | Author bio na każdej article page | Widoczne nad lub pod treścią artykułu |
| Uprawnienia budowlane PIIB (numer uprawnień) | Expertise | Author bio text + `hasCredential` w Person schema | Sprawdź rejestr PIIB online: https://is.piib.org.pl |
| Specjalizacja (np. "Konstrukcje żelbetowe") | Expertise | Author bio + `jobTitle` w Person schema | Zgodna z numerem uprawnień w rejestrze |
| Lata praktyki na rynku (np. "15 lat w branży") | Expertise | Author bio, About page, Organization schema description | Data założenia firmy / pierwsze realizacje |
| Foto autora (prawdziwe, nie AI/stock) | Experience | Author bio na każdej article page | Reverse image search (Google Lens) — wynik NIE powinien wskazywać na stock |
| Pełna strona autora (/o-autorze/imie-nazwisko) | Expertise + Authority | Link z bio do dedykowanej strony | Strona istnieje, nie 404 |
| Członkostwo PIIB / Polska Izba Inżynierów Budownictwa | Authority | About page text + `memberOf` w Person schema | Weryfikuj numer w rejestrze PIIB |
| Przynależność do Izby Budowlanej / PZITB | Authority | About page, footer | Link do strony izby z wzmianka o firmie (reciprocal) |
| Realizacje dla samorządów / przetargi publiczne | Authority | Portfolio section | Linki do BIP ogłoszeń przetargowych jako evidence |
| Ubezpieczenie OC kontraktorskie (numer polisy) | Trust | About page / "Dokumenty" page | Nazwa ubezpieczyciela + numer polisy + termin ważności |
| Gwarancja 5-letnia (zapis w umowie) | Trust | Service page / FAQ / About | Screenshot umowy z paragrafem gwarancyjnym (anonimizowany) |
| NIP + REGON + KRS widoczne | Trust | Footer + About page | Sprawdź w CEIDG lub KRS online |
| Fizyczny adres siedziby | Trust | Footer + LocalBusiness schema | Google Maps verifiable |
| Kontakt (telefon, email) w footer | Trust | Footer | Działający numer — test call lub email bounce |
| Polityka prywatności + regulamin + cookies | Trust | Footer links | Strony istnieją, data aktualizacji <2 lata |
| Customer reviews (imię, data, treść — prawdziwe) | Trust | Reviews section + AggregateRating schema | Skrzyżowanie z Google Business Profile / Facebook opiniami |
| Certyfikaty PN-EN (normy budowlane) | Expertise | "Dokumenty" / "Certyfikaty" page | Skan certyfikatu z datą ważności |

### Schema embedding (Construction)

```json
"author": {
  "@type": "Person",
  "name": "{{AUTHOR_NAME}}",
  "jobTitle": "Kierownik budowy",
  "hasCredential": "Uprawnienia budowlane PIIB nr {{PIIB_NUMBER}}",
  "memberOf": {
    "@type": "Organization",
    "name": "Polska Izba Inżynierów Budownictwa",
    "url": "https://piib.org.pl"
  },
  "sameAs": ["{{LINKEDIN_URL}}", "{{PIIB_PROFILE_URL}}"]
}
```

---

## E-E-A-T: Medical (Branża medyczna)

Branża YMYL — zdrowie i życie. Najwyższy próg E-E-A-T ze wszystkich branż.

| Marker | Typ | Gdzie wstawić | Jak weryfikować |
|---|---|---|---|
| Anonimizowane case studies pacjentów (objaw → diagnoza → wynik) | Experience | Blog post (RODO: brak danych osobowych) | Data + opis bez danych identyfikujących |
| Lata praktyki klinicznej | Experience | Author bio | Spójne z datą ukończenia specjalizacji |
| Imię i nazwisko lekarza autora | Experience + Expertise | Author bio na każdej article page | Widoczne, prawdziwe |
| Numer Prawa Wykonywania Zawodu (PWZ) | Expertise | Author bio text + `hasCredential` w Person schema | Sprawdź w rejestrze Naczelnej Izby Lekarskiej: rejestr.nil.org.pl |
| Specjalizacja (np. "kardiolog II stopnia") | Expertise | Author bio + `jobTitle` | Zgodna z wpisem w rejestrze NIL |
| Certyfikaty towarzystw naukowych (PTNS, PTC, EBCOG etc.) | Expertise | "Certyfikaty" / Author page | Link do strony towarzystwa + numer certyfikatu |
| Publikacje naukowe (PubMed, krajowe czasopisma) | Authority | Author page → "Publikacje" section | Link do PubMed / DOI artykułu |
| Stanowisko szpitalne / akademickie | Authority | Author bio | Link do strony szpitala / uczelni z profile |
| Wywiad w mediach / cytowania | Authority | Press section | Link do źródła |
| RODO compliance (polityka + zgody) | Trust | Footer + Popup | Data policy visible, UODO-compliant |
| Regulamin teleporad / udzielania świadczeń | Trust | Footer link | Dokument istnieje, aktualna data |
| OC zawodowe lekarza | Trust | About / Dokumenty | Nazwa ubezpieczyciela (nie musi być polisa number — wystarczy wzmianka) |
| Dane rejestrowe (NIP, REGON) | Trust | Footer | Zgodne z KRS / CEIDG |

### Schema embedding (Medical)

```json
"author": {
  "@type": "Person",
  "name": "{{DOCTOR_NAME}}",
  "jobTitle": "{{SPECIALIZATION}}",
  "hasCredential": "Prawo Wykonywania Zawodu nr {{PWZ_NUMBER}}",
  "memberOf": {
    "@type": "Organization",
    "name": "Naczelna Izba Lekarska",
    "url": "https://nil.org.pl"
  },
  "sameAs": ["{{NIL_PROFILE_URL}}", "{{PUBMED_PROFILE_URL}}"]
}
```

---

## E-E-A-T: Finance (Branża finansowa)

Branża YMYL — pieniądze i inwestycje.

| Marker | Typ | Gdzie wstawić | Jak weryfikować |
|---|---|---|---|
| Track record portfela / ROI case studies (dane historyczne) | Experience | Blog / case studies section | Dane historyczne z disclaimerem "wyniki historyczne nie gwarantują przyszłych" |
| Lata praktyki w branży | Experience | Author bio | Spójne z datą pierwszej licencji |
| Licencja KNF (numer wpisu) | Expertise | Author bio + `hasCredential` | Sprawdź w rejestrze KNF: https://www.knf.gov.pl/podmioty/Rejestry_i_Listy |
| Certyfikaty zawodowe (CFA, ACCA, FRM, CFP) | Expertise | Author bio + certyfikaty page | Link do bazy weryfikacyjnej (np. CFA Institute verify.cfainstitute.org) |
| Wykształcenie (ekonomia, aktuariat, prawo finansowe) | Expertise | Author bio | Uczelnia + rok ukończenia |
| Przynależność (CFA Institute, ACCA Polska, SKwP) | Authority | About page + `memberOf` | Link do strony stowarzyszenia |
| Cytowania w mediach finansowych (Puls Biznesu, Bankier, Rzeczpospolita) | Authority | Press section | Link do artykułu |
| Audyt zewnętrzny (firma audytorska, rok) | Trust | About / Dokumenty page | Nazwa audytora + rok raportu |
| Regulamin świadczenia usług finansowych | Trust | Footer link | Aktualna data, MIFID/UKNF compliance |
| KNF compliance statement | Trust | Footer / About | Widoczne oświadczenie o nadzorze KNF |
| Ubezpieczenie zawodowe OC | Trust | About / Dokumenty | Wzmianka z nazwą ubezpieczyciela |
| Disclaimer inwestycyjny | Trust | Każda strona z analizami | "Niniejszy materiał ma charakter edukacyjny i nie stanowi doradztwa inwestycyjnego" |

---

## E-E-A-T: Legal (Branża prawna)

Branża YMYL — prawo i skutki prawne decyzji.

| Marker | Typ | Gdzie wstawić | Jak weryfikować |
|---|---|---|---|
| Opisy prowadzonych spraw (anonimizowane, wyniki) | Experience | Case studies / blog | Brak danych klienta, spójna narracja prawna |
| Lata praktyki w specjalizacji | Experience | Author bio | Spójne z datą wpisu na listę |
| Numer wpisu na listę adwokatów / radców prawnych | Expertise | Author bio + `hasCredential` | Sprawdź: https://www.adwokatura.pl/znajdz-adwokata lub https://kirp.pl/znajdz-radce/ |
| Specjalizacja (np. "prawo budowlane", "prawo nieruchomości") | Expertise | Author bio + `jobTitle` | Spójna z case studies |
| Publikacje prawne (monografie, artykuły w Palestrze, Radcy Prawnym) | Authority | Author page → "Publikacje" | Link do wydawnictwa / DOI |
| Stanowisko w samorządzie zawodowym | Authority | Author bio | Link do strony samorządu z potwierdzeniem |
| Wykłady akademickie / szkolenia zawodowe | Authority | About page | Link do uczelni / okręgowej izby |
| OC zawodowe wymagane prawem (adwokat / radca) | Trust | About / Dokumenty | Wzmianka obowiązkowa (prawo wymaga ubezpieczenia) |
| Tajemnica zawodowa statement | Trust | Regulamin / About | Zdanie o zobowiązaniu do tajemnicy zawodowej |
| Regulamin świadczenia pomocy prawnej | Trust | Footer link | Aktualna data, RODO-compliant |
| NIP + dane rejestrowe kancelarii | Trust | Footer | Zgodne z CEIDG / KRS |

---

## E-E-A-T: Generic fallback

Dla branż niezdefiniowanych powyżej. Kopiuj i podmień markers per regulator branżowy.

| Marker | Typ | Gdzie wstawić | Jak weryfikować |
|---|---|---|---|
| Lata działalności / data założenia firmy | Experience | About page, footer | Data w KRS / CEIDG |
| Case studies / realizacje (anonimizowane lub za zgodą) | Experience | Portfolio / case studies | Min 3 z datą, opisem projektu, wynikiem |
| Imię i nazwisko eksperta + stanowisko | Expertise | Author bio | Widoczne, linkowalne do profilu |
| Certyfikaty branżowe (ISO, branżowe izby) | Expertise | Certyfikaty page + `hasCredential` | Link do wystawiającego certyfikat |
| Nagrody / wyróżnienia branżowe | Authority | About / footer | Link do organizatora nagrody |
| Przynależność do izb / stowarzyszeń branżowych | Authority | About + `memberOf` | Link do strony izby |
| Wzmianki w mediach branżowych / ogólnych | Authority | Press section | Link do artykułu z datą |
| Kontakt widoczny (tel, email, adres) | Trust | Footer | Działający kontakt |
| Dane rejestrowe (NIP, REGON, KRS) | Trust | Footer | Weryfikowalne w CEIDG / KRS online |
| Polityka prywatności + regulamin | Trust | Footer links | Istnieją, data aktualizacji <2 lata |
| Opinie klientów (imię, data, treść) | Trust | Reviews section + AggregateRating schema | Tylko prawdziwe — crosscheck z Google/FB |
| HTTPS + valid SSL | Trust | Everywhere (technical) | SSL Labs test: https://www.ssllabs.com/ssltest/ |

### Jak dodać nową branżę

1. Skopiuj sekcję "Generic fallback" powyżej
2. Zmień nagłówek: `## E-E-A-T: {{NOWA_BRANZA}}`
3. Podmień markers per regulator branżowy (np. dla edukacji: MEN, Kuratoria, numer uprawnień pedagogicznych)
4. Dodaj wiersz w tabeli "Per industry preview" w `SKILL.md` sekcja 2
5. Commit: `docs(seo-advanced): add eeat-checklist {{branża}}`

---

## Wspólne resources do weryfikacji

| Resource | URL | Do czego |
|---|---|---|
| PIIB rejestr (budownictwo) | https://is.piib.org.pl | Numer uprawnień budowlanych |
| NIL rejestr (medycyna) | https://rejestr.nil.org.pl | Numer PWZ lekarza |
| KNF rejestry (finanse) | https://www.knf.gov.pl/podmioty/Rejestry_i_Listy | Licencje finansowe |
| KIRP/NRA (prawo) | https://kirp.pl, https://www.adwokatura.pl | Wpis na listę adwokatów/radców |
| CEIDG (działalność gospod.) | https://www.biznes.gov.pl/pl/firma/rejestry/ceidg | NIP, REGON, data założenia |
| KRS (spółki) | https://ekrs.ms.gov.pl | KRS, dane spółki |
| SSL Labs | https://www.ssllabs.com/ssltest/ | Weryfikacja SSL |
| Google Rich Results Test | https://search.google.com/test/rich-results | Schema eligibility |
