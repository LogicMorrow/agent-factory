# Testy automatyzacji

## Automation-n8n — brak Vitest, 5 scenariuszy manualnych

Projekty n8n nie mają własnego kodu → nie piszemy testów Vitest. Zamiast tego: **5 obowiązkowych scenariuszy testowych** wykonywanych ręcznie lub przez n8n Test Runner.

### Scenariusz 1: Poprawny przypadek (happy path)
- Dane wchodzą poprawnie sformatowane
- Flow przechodzi wszystkie kroki
- Dane wychodzą w oczekiwanym miejscu (baza / mail / CRM)
- **Weryfikacja:** sprawdź w docelowym systemie że dane dotarły

### Scenariusz 2: Brakujące pola wymagane
- Wyślij payload bez wymaganego pola (np. brak `email`)
- **Oczekiwane:** HTTP 400, `{"error": "Missing required field: email"}`
- **Weryfikacja:** workflow odrzuca, nic nie trafia do CRM/bazy, brak crashu

### Scenariusz 3: Błąd zewnętrznego API
- Symuluj niedostępność zewnętrznego API (nieprawidłowy URL lub wyłącz serwis)
- **Oczekiwane:** retry policy aktywna (3x z backoff), po wyczerpaniu → alert
- **Weryfikacja:** dane nie giną (fallback do kolejki/logu), alert dotarł, brak duplikatów przy retry

### Scenariusz 4: Duplikat — idempotentność
- Wyślij ten sam payload dwa razy (ten sam email, te same dane)
- **Oczekiwane:** jeden rekord w docelowym systemie, nie dwa
- **Weryfikacja:** sprawdź w CRM/bazie że nie ma duplikatu

### Scenariusz 5: Skrajne wartości
- Puste stringi: `{"email": "", "name": ""}`
- Null: `{"email": null}`
- Bardzo długi tekst (>1000 znaków w polu name)
- **Oczekiwane:** walidacja odrzuca lub przetwarza gracefully, brak crashu

## Automation-native — testy Vitest

Dla projektów automation-native (TypeScript + Hono): **identyczne zasady jak webapp**.

### Struktura
```
src/workflows/[nazwa]/
├── index.ts
├── steps/
│   ├── step1.ts
│   └── step2.ts
├── types.ts
└── [nazwa].test.ts    ← testy tu
```

### Obowiązkowe testy per workflow
```typescript
// Przykład: processContactForm
describe('processContactForm',  => {
  it('zapisuje kontakt i wysyła email przy poprawnych danych', async  => {
    // happy path
  });

  it('przy błędzie CRM email NIE jest wysyłany', async  => {
    vi.mocked(crmService.create).mockRejectedValue(new Error('CRM down'));
    const result = await processContactForm(validData);
    expect(emailService.send).not.toHaveBeenCalled;
    expect(result.savedToFallback).toBe(true); // dane zabezpieczone
  });

  it('odrzuca payload bez wymaganego pola email', async  => {
    await expect(processContactForm({ name: 'Jan' })).rejects.toThrow('email');
  });

  it('jest idempotentny — drugi call nie tworzy duplikatu', async  => {
    await processContactForm(validData);
    await processContactForm(validData);
    expect(crmService.create).toHaveBeenCalledTimes(1);
  });
});
```

### Kluczowa zasada
Przy błędzie zewnętrznego systemu (CRM, mail) — dane NIE mogą się zgubić.
Test musi weryfikować że `savedToFallback: true` lub odpowiednik.
