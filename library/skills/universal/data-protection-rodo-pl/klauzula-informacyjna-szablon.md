# Klauzula informacyjna — szablon art. 13 RODO

## Zastosowanie

Klauzula musi pojawić się na każdej ofercie PDF przekazywanej klientowi. Umieszczona w stopce dokumentu lub na ostatniej stronie oferty (sekcja dedykowana). Klient musi ją otrzymać w momencie gdy dane są pobierane (przed złożeniem oferty lub jednocześnie z ofertą).

Dwa warianty użycia:
- **Wariant A (stopka PDF):** skrócona klauzula + link/odesłanie do pełnej polityki prywatności.
- **Wariant B (pełna na PDF):** cała klauzula na ostatniej stronie dokumentu PDF.

Wybór wariantu zależy od konfiguracji projektu (czy istnieje publiczna strona www z polityką prywatności).

## Wariant B — pełna klauzula PL (gotowa do użycia na PDF, z placeholderami)

> Wszystkie wartości w nawiasach trójkątnych (`<...>`) zastąp danymi firmy z konfiguracji projektu / karty projektu. Tabela placeholderów na końcu dokumentu (z przykładem wypełnienia).

---

**INFORMACJA O PRZETWARZANIU DANYCH OSOBOWYCH (art. 13 RODO)**

**Administrator danych osobowych:**
<NAZWA_FIRMY>, NIP: <NIP>
Właściciel i osoba kontaktowa: <WLASCICIEL>, tel. <TELEFON>

**Cel i podstawa prawna przetwarzania:**
Pana/Pani dane osobowe (imię i nazwisko, numer telefonu, adres budowy) przetwarzamy w następujących celach:
1. Przygotowania i przekazania oferty kosztorysowej oraz realizacji ewentualnej umowy o <CEL_USLUG> — podstawa: art. 6 ust. 1 lit. b) RODO (niezbędność do wykonania umowy lub podjęcia działań przed jej zawarciem).
2. Przechowywania dokumentacji ofertowej dla celów rozpatrywania ewentualnych reklamacji i roszczeń — podstawa: art. 6 ust. 1 lit. f) RODO (prawnie uzasadniony interes administratora).

**Okres przechowywania danych:**
- Oferty zaakceptowane i zrealizowane: <RETENCJA_AKCEPTOWANE> od daty realizacji (okres rękojmi za roboty budowlane).
- Oferty odrzucone lub niezrealizowane: <RETENCJA_ODRZUCONE> od daty wystawienia oferty.
- Po upływie powyższych terminów dane osobowe zostają zanonimizowane.

**Odbiorcy danych:**
Pana/Pani dane osobowe nie są udostępniane osobom trzecim ani podmiotom zewnętrznym.

**Prawa przysługujące w związku z przetwarzaniem danych:**
Ma Pan/Pani prawo do:
- dostępu do swoich danych osobowych (art. 15 RODO),
- sprostowania danych nieprawidłowych (art. 16 RODO),
- żądania usunięcia danych po upływie celu przetwarzania (art. 17 RODO),
- przenoszenia danych w formacie elektronicznym (art. 20 RODO),
- wniesienia sprzeciwu wobec przetwarzania opartego na uzasadnionym interesie (art. 21 RODO),
- wniesienia skargi do Prezesa Urzędu Ochrony Danych Osobowych (PUODO), ul. Stawki 2, 00-193 Warszawa.

**Dobrowolność podania danych:**
Podanie danych osobowych jest dobrowolne, jednak konieczne do wystawienia oferty. Brak danych uniemożliwia realizację usługi.

**Kontakt w sprawach ochrony danych:**
<WLASCICIEL>, tel. <TELEFON>

---

## Wariant A — skrócona stopka PDF (gdy klauzula pełna dostępna online)

Stosuj gdy firma posiada stronę www z Polityką Prywatności:

---

**Ochrona danych osobowych:** Administratorem Pana/Pani danych jest <NAZWA_FIRMY> (NIP <NIP>). Dane przetwarzamy w celu realizacji oferty i umowy (art. 6.1.b RODO) oraz archiwizacji (art. 6.1.f RODO). Szczegółowe informacje: <URL_POLITYKI> lub kontakt: <WLASCICIEL>, tel. <TELEFON>.

---

## Integracja z PDF generator (`@react-pdf/renderer`)

```tsx
// components/pdf/InformationClause.tsx
import { Text, View, StyleSheet } from '@react-pdf/renderer';

const styles = StyleSheet.create({
  container: {
    marginTop: 20,
    paddingTop: 12,
    borderTopWidth: 0.5,
    borderTopColor: '#cccccc',
    fontSize: 7,
    color: '#666666',
    lineHeight: 1.4,
  },
  title: {
    fontWeight: 'bold',
    marginBottom: 4,
    fontSize: 7.5,
  },
  section: {
    marginBottom: 4,
  },
  bold: {
    fontWeight: 'bold',
  },
});

interface InformationClauseProps {
  companyName: string;   // np. '<NAZWA_FIRMY> sp. z o.o.' (z konfiguracji projektu)
  nip: string;           // np. '<NIP>' (10 cyfr)
  ownerName: string;     // np. '<WLASCICIEL>'
  ownerPhone: string;    // np. '<TELEFON>'
}

export function InformationClause({ companyName, nip, ownerName, ownerPhone }: InformationClauseProps) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>INFORMACJA O PRZETWARZANIU DANYCH OSOBOWYCH (art. 13 RODO)</Text>

      <View style={styles.section}>
        <Text>
          <Text style={styles.bold}>Administrator: </Text>
          {companyName}, NIP: {nip}. Kontakt: {ownerName}, tel. {ownerPhone}.
        </Text>
      </View>

      <View style={styles.section}>
        <Text>
          <Text style={styles.bold}>Cel i podstawa: </Text>
          Przygotowanie i realizacja oferty (art. 6.1.b RODO) oraz archiwum dla celów
          roszczeń (art. 6.1.f RODO).
        </Text>
      </View>

      <View style={styles.section}>
        <Text>
          <Text style={styles.bold}>Retencja: </Text>
          Oferty zaakceptowane: 5 lat. Odrzucone: 2 lata. Następnie anonimizacja.
        </Text>
      </View>

      <View style={styles.section}>
        <Text>
          <Text style={styles.bold}>Prawa: </Text>
          Dostęp, sprostowanie, usunięcie, przenoszenie danych, sprzeciw (art. 15–21 RODO).
          Skarga do PUODO: ul. Stawki 2, 00-193 Warszawa.
        </Text>
      </View>

      <Text>Podanie danych jest dobrowolne, lecz niezbędne do wystawienia oferty.</Text>
    </View>
  );
}
```

Użycie w szablonie PDF oferty:

```tsx
// components/pdf/OfferDocument.tsx
import { InformationClause } from './InformationClause';

// PDF_CONFIG ładowany z .env / configu projektu (NIE hardcode w komponencie)
const PDF_CONFIG = {
  companyName: process.env.COMPANY_NAME!,
  nip: process.env.COMPANY_NIP!,
  ownerName: process.env.COMPANY_OWNER!,
  ownerPhone: process.env.COMPANY_PHONE!,
};

export function OfferDocument({ offer }: { offer: Offer }) {
  return (
    <Document>
      <Page size="A4" style={pageStyle}>
        {/* ... treść oferty ... */}

        {/* Klauzula RODO — zawsze na końcu dokumentu */}
        <InformationClause {...PDF_CONFIG} />
      </Page>
    </Document>
  );
}
```

## Tabela placeholderów

Klauzula używa placeholderów w formacie `<NAZWA>`. Wartości pochodzą z konfiguracji projektu (np. `.env`, karta projektu w `knowledge-base/projects/<slug>.md`).

| Placeholder | Opis | Przykład wypełnienia (referencja: firma dekarska PL) |
|---|---|---|
| `<NAZWA_FIRMY>` | Pełna nazwa prawna | "ABC sp. z o.o." |
| `<NIP>` | NIP firmy (10 cyfr) | "0000000000" |
| `<WLASCICIEL>` | Imię i nazwisko osoby kontaktowej | "Jan Kowalski" |
| `<TELEFON>` | Numer kontaktowy | "000 000 000" |
| `<CEL_USLUG>` | Opis usług (branża) | "roboty dekarskie" |
| `<RETENCJA_AKCEPTOWANE>` | Okres dla ofert zaakceptowanych | "5 lat" |
| `<RETENCJA_ODRZUCONE>` | Okres dla ofert odrzuconych | "2 lata" |
| `<URL_POLITYKI>` | URL polityki prywatności (gdy strona www istnieje) | "https://example.pl/polityka-prywatnosci" |

## Polityka prywatności — zarys dla wariantu z publiczną stroną www

Gdy firma posiada stronę www, polityka prywatności musi zawierać:
1. Tożsamość i dane kontaktowe administratora.
2. Cele i podstawy prawne przetwarzania (jak w klauzuli powyżej).
3. Odbiorcy danych lub kategorie odbiorców.
4. Okres przechowywania danych (tabela retencji).
5. Prawa podmiotów danych (lista art. 15–21) z informacją jak je wykonać.
6. Prawo do wniesienia skargi do PUODO.
7. Informacja o cookies (wymagana dla strony www): cookies niezbędne (session, CSRF) — bez zgody; cookies analityczne/marketingowe — wymagają zgody w bannerze. Nie dotyczy v1 jeśli aplikacja jest prywatna bez publicznej strony www.
8. Data ostatniej aktualizacji.
