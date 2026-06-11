# TOTP feature flag — guide włączenia przed audytem

> Dotyczy: iron-session 8 + `@otplib/preset-default` + zmienna `TOTP_REQUIRED`
> Użytkownik końcowy: Jan Nowak, 50+, nie-IT, właściciel Acme Sp. z o.o.

---

## Kiedy włączyć TOTP

### Domyślnie: `TOTP_REQUIRED=false`

Aplikacja startuje BEZ wymaganego TOTP. Jan loguje się hasłem + sesją iron-session.
Wymaganie TOTP dodane dopiero przed audytem zewnętrznym.

### Kiedy przestawić na `TOTP_REQUIRED=true`:

1. **Przed audytem OWASP ASVS L2** — audytor sprawdza sekcję §2.8 (weryfikacja wieloskładnikowa)
   - ASVS L2 wymaga MFA dla aplikacji przetwarzającej PII klientów
   - DemoApp przetwarza: imię/nazwisko, telefon, adres budowy → PII → L2 wymaga MFA
   
2. **Na prośbę ubezpieczyciela** — część polis cyber wymaga MFA dla systemów z PII

3. **Wolicjonalnie** — operator + Jan decydują o zwiększeniu bezpieczeństwa

### NIE włączaj TOTP gdy:
- Jan nie przeszedł jeszcze onboardingu TOTP (zob. sekcja UX poniżej)
- Backup codes nie są jeszcze zapisane w bezpiecznym miejscu
- Nie ma planu rollback jeśli Jan zgubi telefon

---

## Jak włączyć TOTP — procedura (4 kroki)

### Krok 1 — Onboarding Jana (z pomocą operatora)

Czas: ~20-30 minut, jednorazowo.

```
operator siedzi razem z Janem lub dzwoni na video call.

1. Jan instaluje aplikację authenticator:
   - Google Authenticator (iOS App Store: "Google Authenticator")
   - Lub: Microsoft Authenticator (prościej dla seniora — ikona kciuka)
   - ZALECANE dla seniora 50+: Microsoft Authenticator
     (bardziej czytelny UI, powiadomienie zamiast kodu)

2. operator otwiera DemoApp → Settings → "Włącz weryfikację dwuetapową"
   (przycisk widoczny gdy TOTP_REQUIRED=false — użytkownik może opcjonalnie skonfigurować)

3. Wyświetla się ekran z kodem QR.
   WAŻNE dla seniora: duży QR kod (min 300×300px), jasne instrukcje poniżej.

4. Jan otwiera aplikację authenticator → "+" → "Skanuj kod QR"
   Nakieruje kamerę na ekran laptopa.
   → Konto "DemoApp" pojawia się w liście z 6-cyfrowym kodem

5. Jan wpisuje aktualny kod z aplikacji → "Potwierdź"
   System weryfikuje → TOTP aktywowane.

6. KLUCZOWE: Ekran backup codes (10 jednorazowych kodów)
   operator drukuje lub Jan zapisuje ręcznie → koperta w szufladzie biura
   INSTRUKCJA USTNA: "Jan, te kody to zapasowy klucz jeśli zgubisz telefon.
   Schowaj je w bezpiecznym miejscu. Bez nich jeśli zgubisz telefon — zadzwoń do mnie."
```

### Krok 2 — Okres testowy (7-14 dni)

```
TOTP_REQUIRED=false (dalej)
Jan loguje się normalnie, ale MA skonfigurowane TOTP.

Co 2-3 dni operator pyta: "Jak idzie z kodem z telefonu?"
Cel: upewnić się że Jan:
  - Wie gdzie znaleźć aplikację authenticator
  - Rozumie że kod zmienia się co 30 sekund
  - Przetestował logowanie z kodem (opcjonalnie na tym etapie)
```

### Krok 3 — Włączenie TOTP_REQUIRED=true

```bash
# Na serwerze VPS (lub przez CI/CD secret update)
# Edytuj .env.prod
TOTP_REQUIRED=true

# Restart aplikacji
docker compose restart app

# Weryfikacja: operator loguje się → po haśle pojawia się ekran TOTP
# operator wpisuje kod z aplikacji → OK
```

### Krok 4 — Weryfikacja z Janem

```
operator dzwoni do Jana lub jest obok:
"Zaloguj się do DemoApp."
Jan:
  1. Wpisuje email + hasło → "Dalej"
  2. Ekran: "Podaj kod z aplikacji authenticator"
  3. Otwiera Microsoft Authenticator → widzi 6-cyfrowy kod dla DemoApp
  4. Wpisuje → logowanie OK

Jeśli problem: zob. sekcja Rollback poniżej.
```

---

## UX dla seniora 50+ — wytyczne ekranu TOTP

### Ekran logowania (krok 2 — TOTP code)

**Wymagania UX:**
- Nagłówek: "Kod z aplikacji authenticator" (nie "TOTP", nie "2FA", nie "kod OTP")
- Podtytuł: "Otwórz Microsoft Authenticator lub Google Authenticator i wpisz 6-cyfrowy kod."
- Pole input: duże, auto-focus, type="text" inputMode="numeric" pattern="[0-9]{6}"
  - NIE type="number" (usuwa leading zero na iOS Safari)
- Przycisk: duży, min 56px height, tekst "Zaloguj się" (nie "Verify", nie "Submit")
- Link pomocniczy: "Nie mam dostępu do telefonu → Użyj kodu zapasowego"
- Komunikat błędu: "Kod nieprawidłowy. Sprawdź czy wpisałeś aktualny kod (zmienia się co 30 sekund)."
  - Nie: "TOTP verification failed" (żargon techniczny)

### Ekran setup TOTP (Settings)

**Wymagania UX:**
- Krok 1: "Zainstaluj aplikację authenticator na telefonie" + linki do App Store
- Krok 2: "Zeskanuj kod QR telefonem" — QR min 300×300px, wyraźny kontrast
- Krok 3: "Wpisz 6-cyfrowy kod z aplikacji" — duże pole
- Krok 4 (backup codes): "WAŻNE — zapisz te kody zapasowe"
  - Czerwony nagłówek z ikoną ostrzeżenia
  - Tekst: "Jeśli zgubisz telefon, te kody pozwolą Ci się zalogować. Wydrukuj je lub zapisz i schowaj w bezpiecznym miejscu."
  - Przycisk: "Pobierz PDF z kodami" lub "Wydrukuj"
  - Checkbox potwierdzenia: "Zapisałem kody zapasowe" — wymagany przed zamknięciem ekranu

---

## Rollback — gdy Jan ma problemy

### Scenariusz A: Jan nie może znaleźć aplikacji

```
1. operator pomaga znaleźć ikonę Microsoft Authenticator na iPhonie
2. Jeśli aplikacja usunięta — reinstalacja + ponowny setup (wymaga kodu zapasowego lub reset)
```

### Scenariusz B: Kod z telefonu "nie działa"

Przyczyny i rozwiązania:
```
Kod wygasł — kod zmienia się co 30 sekund
→ Poczekaj na nowy kod (pasek czasu w aplikacji) i wpisz nowy

Czas telefonu desynchronizowany
→ iOS: Ustawienia → Ogólne → Data i godzina → "Ustaw automatycznie: WŁ"
→ iOS: Ustawienia → Microsoft Authenticator → "Czas korekty" → "Synchronizuj"

Jan ma TOTP dla innego konta o nazwie "DemoApp"
→ Sprawdź który wpis to DemoApp (może być kilka w historii setup)
```

### Scenariusz C: Jan zgubił telefon

```bash
# NATYCHMIASTOWE działanie:
# 1. operator loguje się z backup code (10 jednorazowych kodów z setup)
# 2. Wyłącza TOTP dla konta Jana w DB

# W scripts/disable-totp-emergency.ts:
await db.user.update({
  where: { email: "wlasciciel@demoapp.pl" },
  data: { totpSecret: null, totpSecretPending: null, totpBackupCodes: [] },
});
# 3. Audit log entry o emergency disable
# 4. Jan kupuje nowy telefon → powtarza onboarding TOTP (Krok 1)
```

### Scenariusz D: Bouncing — Jan nie chce TOTP

```
Jeśli przed audytem Jan zbyt mocno opiera się TOTP:
1. Nie wymuszaj na siłę — UX frustration = błędy, porzucenie systemu
2. Wróć do TOTP_REQUIRED=false tymczasowo
3. Zaplanuj krótką sesję onboarding z Janem

Pamiętaj: Jan robi ~5-20 ofert/miesiąc. System ma ZASTĄPIĆ zeszyt + SMS.
Jeśli system jest trudniejszy niż zeszyt → cel nie osiągnięty.
TOTP jest dla OWASP/audytora, nie dla Jana — minimalizuj friction.
```

---

## Checklist przed audytem (TOTP_REQUIRED=true)

- [ ] Jan przeszedł onboarding TOTP (krok 1-4 powyżej)
- [ ] Backup codes wydrukowane i bezpiecznie przechowywane
- [ ] Test logowania z TOTP przez Jana OK
- [ ] `TOTP_REQUIRED=true` w prod env
- [ ] Audit log zawiera `login.success` z `metadata: { totp_verified: true }`
- [ ] Skrypt emergency disable (`disable-totp-emergency.ts`) gotowy i przetestowany
- [ ] ADR-003 zaktualizowany: TOTP enforced od daty X
