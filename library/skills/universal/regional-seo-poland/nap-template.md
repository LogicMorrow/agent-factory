# NAP Template — Branża Budowlana PL

NAP = Name, Address, Phone. Spójność NAP across wszystkich citations to critical ranking factor local SEO. Jedna niespójność rozmywa sygnał lokalizacji dla Google.

---

## 1. Formal NAP Format — Branża Budowlana PL

### Wzorzec kanoniczni

```
Name:    {{COMPANY_LEGAL_NAME}} {{FORMA_PRAWNA}}

Address: ul. {{STREET}} {{NUMBER}}, {{POSTCODE}} {{CITY}}, woj. {{WOJEWODZTWO}}

Phone:   +48 {{AREA_CODE}} {{NUMBER}}
```

### Szczegóły każdego pola

**Name — zasady:**
- Użyj pełnej nazwy z KRS/CEIDG (np. "Budownictwo Kowalski Sp. z o.o.")
- NIE skracaj: "Kowalski" zamiast "Budownictwo Kowalski Sp. z o.o." = niespójność
- Formy prawne: `sp. z o.o.` / `sp.j.` / `s.c.` / `sp.k.` / bez formy (jednoosobowa DG)
- Nazwa DBA (działalność pod inną nazwą): jeśli wpis w CEIDG = "Jan Kowalski", ale firma używa nazwy "JK Budownictwo" → zawsze użyj formy z CEIDG jako canonical NAP

**Address — zasady:**
- Zawsze z prefiksem `ul.` (NIE "Ulica", NIE bez prefiksu)
- Numer budynku bez spacji przed: `ul. Lipowa 12` (NIE `ul. Lipowa  12`)
- Numer lokalu: `ul. Lipowa 12/3` lub `ul. Lipowa 12 m. 3` — wybierz jeden format i stosuj konsekwentnie
- Kod pocztowy: zawsze format `XX-XXX` (np. `20-001`) — bez spacji w kodzie
- Miasto: bez "m." prefiksu (NIE "m. Warszawa" — tylko "Warszawa")
- Województwo: małe litery, bez "woj." skrótu w niektórych katalogach — dostosuj do wymagań portalu, ale canonical zawiera `woj. {{WOJEWODZTWO}}`

**Phone — zasady:**
- Format canonical: `+48 81 123 45 67` (landline) lub `+48 501 234 567` (komórka)
- `+48` — ZAWSZE z plusem. NIE `48` bez plusa, NIE `0048`
- Spacje: po `+48` spacja, potem numer w formatach regionalnych (2-3-2-2 dla landline lub 3-3-3 dla komórki)
- Jeden numer kontaktowy — jeśli masz kilka, wybierz JEDEN jako canonical NAP
- Jeśli numer zmieniony → natychmiast audyt wszystkich citations

### Przykłady — pełny NAP canonical

```
Przykład 1 (sp. z o.o., Warszawa):
Name:    Budownictwo Kowalski sp. z o.o.
Address: ul. Lipowa 12, 20-001 Warszawa, woj. mazowieckie
Phone:   +48 81 123 45 67

Przykład 2 (DG, Kraków):
Name:    Jan Kowalski JK Budownictwo
Address: ul. Podkarpacka 5/2, 35-082 Kraków, woj. małopolskie
Phone:   +48 501 234 567

Przykład 3 (sp.j., Wrocław):
Name:    Kowalski i Wspólnicy Budownictwo sp.j.
Address: ul. Świdnicka 30, 50-066 Wrocław, woj. dolnośląskie
Phone:   +48 71 234 56 78
```

---

## 2. Audyt Checklist — Gdzie Sprawdzić NAP

Użyj tej listy po każdej zmianie NAP lub raz na kwartał dla aktywnych profili.

### Miejsca wymagające audytu (priorytetowo)

| # | Miejsce | Jak sprawdzić | Jak poprawić |
|---|---|---|---|
| 1 | **Google Business Profile** | business.google.com → Profil → Informacje | Edytuj bezpośrednio w panelu GBP |
| 2 | **Aleo** | Wejdź na aleo.com → szukaj po NIP lub nazwie | Zaloguj się do panelu Aleo |
| 3 | **Panorama Firm** | panoramafirm.pl → szukaj nazwy | Panel zarządzania profilem |
| 4 | **OLX** | olx.pl → konto firmy → ogłoszenia | Edytuj profil konta + ogłoszenia |
| 5 | **Strona WWW (www)** | Sekcja "Kontakt" + stopka | CMS / kod strony |
| 6 | **Facebook / LinkedIn** | Sekcja "Informacje" profilu | Panel ustawień profilu |
| 7 | **Google Maps** | Szukaj nazwy w Maps — weryfikuj dane | Przez GBP panel (powiązane) |
| 8 | **FirmyBudowlane.pl** | Szukaj po nazwie / NIP | Panel zarządzania profilem |
| 9 | **MuratorPlus** | Szukaj w katalogu firm | Panel / email do redakcji |
| 10 | **Oferia** | Profil wykonawcy | Panel konta |

**Narzędzia automatyczne do audytu citations:**
- Whitespark Citation Finder (płatne, najdokładniejsze)
- Moz Local (płatne)
- BrightLocal (płatne, wersja trial dostępna)
- Ręcznie: `site:portal.pl "{{NAZWA FIRMY}}"` w Google

### Diff tool — jak porównać NAP

Prosta procedura ręczna:
1. Utwórz tabelę: Platforma | Name | Address | Phone | Status
2. Wpisz canonical NAP w wierszu "STANDARD"
3. Kopiuj NAP z każdej platformy — porównaj pole po polu
4. Status: OK / MISMATCH (co dokładnie się różni)
5. Popraw wszystkie MISMATCH przed kolejnym audytem

Przykład tabeli audytu:
```
| Platforma       | Name                          | Address                              | Phone           | Status  |
| STANDARD        | Budownictwo Kowalski sp. z o.o. | ul. Lipowa 12, 20-001 Warszawa         | +48 81 123 45 67| —       |
| GBP             | Budownictwo Kowalski sp. z o.o. | ul. Lipowa 12, 20-001 Warszawa         | +48 81 123 45 67| OK      |
| Aleo            | Budownictwo Kowalski           | ul. Lipowa 12, 20-001 Warszawa         | 81 123 45 67    | MISMATCH (Name: brak sp. z o.o., Phone: brak +48) |
| Panorama Firm   | Budownictwo Kowalski sp. z o.o. | Lipowa 12, 20-001 Warszawa             | +48 81 123 45 67| MISMATCH (Address: brak "ul.") |
```

---

## 3. Anti-patterns NAP — Najczęstsze Błędy

### Różne formaty tej samej informacji

**Name — błędy:**
```
DOBRZE: "Budownictwo Kowalski sp. z o.o."  (jednolite wszędzie)
ZLE:    "Budownictwo Kowalski"               (brak formy prawnej)
ZLE:    "BUDOWNICTWO KOWALSKI SP. Z O.O."   (duże litery — inny string)
ZLE:    "Kowalski Budownictwo sp.z.o.o."    (odwrócona kolejność + brak spacji w skrócie)
```

**Address — błędy:**
```
DOBRZE: "ul. Lipowa 12, 20-001 Warszawa, woj. mazowieckie"
ZLE:    "Ulica Lipowa 12, 20001 Warszawa"     (Ulica zamiast ul., brak myślnika w kodzie)
ZLE:    "Lipowa 12 Warszawa"                  (brak "ul.", brak kodu pocztowego)
ZLE:    "ul. Lipowa 12/Warszawa/20-001"       (niestandardowy separator)
```

**Phone — błędy:**
```
DOBRZE: "+48 81 123 45 67"
ZLE:    "81 123 45 67"                      (brak +48 — format krajowy bez kierunkowego)
ZLE:    "0048 81 123 45 67"                 (stary format IDD — niekanoniczny)
ZLE:    "+48 (81) 123-45-67"               (nawiasy i myślniki — różni się od canonical)
ZLE:    "Tel.: 81 123 45 67"               (prefix "Tel.:" — niespójność)
```

**Zmiana numeru — anti-pattern:**
```
ZLE:    Zmieniono numer telefonu tylko w GBP, zapomniano zaktualizować Aleo i Panorama Firm.
NAPRAWA: Lista audytu (sekcja 2) — użyj po KAŻDEJ zmianie NAP.
```

### Skutki niespójnego NAP dla rankingu

Google algorytm local search (Vicinity update 2021 + aktualizacje 2023-2024) cross-referuje citations. Niespójna NAP:
1. Obniżenie confidence score Google że firma istnieje pod tym adresem
2. Gorszy ranking w local pack (3-pak Maps)
3. W skrajnych przypadkach: "Zweryfikuj te informacje" na profilu GBP = odstraszenie klientów

**Zasada:** jeden błędny katalog z starymi danymi może zepsuć robotę 20 poprawnych listings. Audyt systematyczny > reaktywny.
