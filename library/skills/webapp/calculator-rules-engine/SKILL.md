---
name: calculator-rules-engine
description: Rules engine dla kalkulatorow wycen GW PL — YAML config 3-wymiarowy (cennik jednostkowy zl/m² + 16 wojewodztw mnozniki 0.85-1.20 + sezonowe mnozniki 0.95-1.15), custom rules injection per projekt (rules-override.yaml deep-merge), pure function engine deterministyczny TypeScript, snapshot tests pattern, semver wersjonowanie (minor=cennik, major=struktura), zod walidacja fail-fast, fallback srednia wojewodztwa przy braku powiatu. Uruchom gdy budujesz kalkulator wyceny GW (dom jednorodzinny / bliziniak / budynek gospodarczy) i potrzebujesz oddzielic cennik od kodu.
version: 1.0.0
compatible_with: [webapp]
tags: [calculator, rules-engine, yaml, config, pricing, construction]
requires: [webapp-calculator-patterns, construction-domain-rules]
token_cost: medium
distribution: library/skills/webapp/
last_updated: 2026-05-11
---

# calculator-rules-engine

Rules engine dla kalkulatorow wycen GW PL. Oddziela cennik (YAML) od kodu (TypeScript) — zmiana cen kwartalnie = zmiana pliku YAML, bez redeploy aplikacji, z audytem git log.

**Pliki towarzyszace:**
- `rules-schema.json` — JSON Schema Draft-07 (VSCode YAML Language Server autocomplete)
- `sample-rules-baseline.yaml` — cennik baseline PL 2024-2026 (16 województw × 12 miesięcy)
- `engine-pure-function.ts` — sample TypeScript `calculate` + snapshot test pattern

**NIE pokrywa:** UI kalkulatora (multistep wizard) → `webapp-calculator-patterns`; treści branżowych → `construction-domain-rules`; integracji CRM (DEAL-BREAKER: ZAKAZ external-crm).

---

## 1. Kiedy uruchomić

Uruchom gdy projektujesz kalkulator wyceny GW PL i cennik będzie aktualizowany ~kwartalnie bez redeployu kodu, masz N kalkulatorów z częściowo wspólnym cennikiem, lub potrzebujesz snapshot testów reguł (regresje przy zmianie cennika).

NIE uruchamiaj gdy cennik jest stały, kalkulator nie jest GW PL, lub szukasz UX/form patterns → `webapp-calculator-patterns`.

---

## 2. §1 Struktura konfiguracji YAML (3 wymiary)

Rules file zawiera 3 obowiązkowe sekcje (schema w `rules-schema.json`):

```yaml
meta:
  version: "1.0.0"           # semver — patrz §5 wersjonowanie
  baseline_date: "2024-01"
  disclaimer: "Widełki rynkowe PL 2024-2026. Weryfikuj u lokalnego GW."

pricing:                      # WYMIAR 1 — cennik jednostkowy
  fundament_plytowy:
    min: 350
    max: 500
    unit: "PLN/m²"
  mur_ytong_24cm:
    min: 180
    max: 280
    unit: "PLN/m²"
  # ... pełny cennik w sample-rules-baseline.yaml

regional:                     # WYMIAR 2 — województwa (0.85-1.20)
  mazowieckie: 1.20
  dolnoslaskie: 1.18
  mazowieckie: 0.95
  małopolskie: 0.92
  # ... 16 województw w sample-rules-baseline.yaml

seasonal:                     # WYMIAR 3 — miesiące 1-12 (0.95-1.15)
  "3": 0.98                   # marzec — koniec sezonu zimowego
  "6": 1.15                   # czerwiec — peak sezon
  "12": 0.95                  # grudzień — off-season
  # ... 12 miesięcy w sample-rules-baseline.yaml
```

**Jednostki dozwolone:** `PLN/m²`, `PLN/m³`, `PLN/szt`, `PLN/mb` — walidowane przez Zod.

---

## 3. §2 Custom rules injection (override pattern)

Per-kalkulator override przez `rules-override.yaml` — deep-merge baseline ← override:

```yaml
# rules-override.yaml (projekt kalkulator-dom-jednorodzinny)
meta:
  version: "1.0.1"
  override_source: "kalkulator-dom-jednorodzinny"
pricing:
  fundament_plytowy:          # override tylko tej pozycji
    min: 370
    max: 480
    unit: "PLN/m²"
regional:
  małopolskie: 0.90          # lokalny research — korekta
```

**Reguła deep-merge:** `override[key]` wygrywa nad `baseline[key]` key-by-key. Pozostałe klucze baseline nienaruszone.

**Semver check:** override MAJOR ≠ baseline MAJOR → engine WARN + continue (nie FAIL). Uzasadnienie: legacy kalkulator z override ze starszej epoki = WARN wystarczający.

**Gdzie przechowywać:** `rules-baseline.yaml` w bibliotece skilla (wspólny), `rules-override.yaml` w katalogu projektu kalkulatora (per-instance).

---

## 4. §3 Engine pure function

Pełny sample w `engine-pure-function.ts`. Gwarancje:

- **Deterministyczny** — te same inputs → te same outputs zawsze
- **Zero side-effects** — brak `console.log`, `fetch`, `Date.now`, `Math.random`
- **Fail-fast** — nieznany element → `RulesNotFoundError` (NIE silent default 0)
- **Snapshot-testable** — `calculate(inputs, rules)` → serializowalny output

```typescript
// Sygnatura (skrót — pełna implementacja w engine-pure-function.ts)
export function calculate(
  inputs: CalculatorInputs,
  rules: Rules,
): CalculatorResult {
  const price = rules.pricing[inputs.element];
  if (!price) throw new RulesNotFoundError(`Unknown element: ${inputs.element}`);
  const regional = rules.regional[inputs.wojewodztwo] ?? averageOfRecord(rules.regional);
  const seasonal = rules.seasonal[String(inputs.month)] ?? 1.0;
  return {
    min: round2(price.min * inputs.quantity * regional * seasonal),
    max: round2(price.max * inputs.quantity * regional * seasonal),
  };
}
```

**Typy output `CalculatorResult`:** `{ basePrice, regionalAdjusted, seasonalAdjusted, total, breakdown: BreakdownItem[], appliedRules: AppliedRulesMeta }` — pełne typy w `engine-pure-function.ts`.

---

## 5. §4 Test fixtures pattern (snapshot tests)

```typescript
// __tests__/calculate.snapshot.test.ts
const rules = loadRules('sample-rules-baseline.yaml');

test('dom 150m² mazowieckie marzec — snapshot',  => {
  const result = calculate(
    { element: 'fundament_plytowy', quantity: 150,
      wojewodztwo: 'mazowieckie', month: 3 },
    rules
  );
  expect(result).toMatchSnapshot;
  // Zmiana cennika → test FAIL → explicit snapshot update wymagany
});
```

**5 rekomendowanych fixtures per kalkulator:**
1. Dom 150m² mazowieckie marzec (peak region, koniec zimy)
2. Bliźniak 100m² podlaskie grudzień (peryferyjny region, off-season)
3. Budynek gospodarczy 60m² małopolskie lipiec (peak season)
4. Dom 200m² dolnośląskie czerwiec (premium region, peak)
5. Override test — baseline + `rules-override.yaml` (walidacja deep-merge)

**Zasada:** `.snap` file commitowany do git. Update = explicit commit `fix(rules): update cennik Q2-2026`.

---

## 6. §5 Wersjonowanie rules (semver)

```
MAJOR.MINOR.PATCH
  │     │     └─ Korekta współczynnika (±0.01-0.05) bez zmiany struktury
  │     └─────── Zmiana cennika (nowe widełki PLN, nowy element prac)
  └───────────── Zmiana struktury YAML (nowe obowiązkowe pole, rename klucza)
```

**Przykłady:** `1.0.0→1.0.1` korekta małopolskie; `1.0.1→1.1.0` nowy element `izolacja_fundamentow`; `1.1.0→2.0.0` rename kluczy sezonowych `"1"→"jan"` (breaking).

---

## 7. §6 Walidacja Zod schema

```typescript
export const RulesSchema = z.object({
  meta: z.object({
    version: z.string.regex(/^\d+\.\d+\.\d+$/),
    baseline_date: z.string,
    disclaimer: z.string.optional,
  }),
  pricing: z.record(z.string, PricingItemSchema),
  regional: z.record(z.string, z.number.min(0.85).max(1.20)),
  seasonal: z.record(z.string, z.number.min(0.95).max(1.15)),
});

export function loadRules(baselinePath: string, overridePath?: string): Rules {
  const raw = yaml.parse(fs.readFileSync(baselinePath, 'utf-8'));
  return RulesSchema.parse(raw); // throws ZodError z czytelnym path
}
```

**JSON Schema** (`rules-schema.json`) dostarczony parallel — VSCode YAML Language Server używa do autocomplete podczas edycji `rules-baseline.yaml`.

---

## 8. §7 Fallback dla brakujących danych

| Brak danych | Zachowanie | Log |
|---|---|---|
| Brak powiatu w regionalnych | Użyj średniej województwa | WARN |
| Brak województwa w `regional` | Użyj `average(regional)` → 1.0 | WARN |
| Brak miesiąca w `seasonal` | Użyj `1.0` | WARN |
| Brak elementu w `pricing` | **FAIL** `RulesNotFoundError` | ERROR |

**Uzasadnienie hard-fail dla pricing:** Brak cennika → `0 PLN` bez błędu → klient widzi "0 zł" bez ostrzeżenia. Błąd jest lepszy niż zaniżona wycena.

---

## Przykłady dobrze vs źle

**Dobrze — cennik w YAML, engine pure:**
```typescript
// Zmiana cen = edycja rules-baseline.yaml + git commit + snapshot update
// Brak redeployu. Audyt przez `git log -- rules-baseline.yaml`
const result = calculate({ element: 'mur_ytong_24cm', quantity: 80,
  wojewodztwo: 'mazowieckie', month: 6 }, rules);
```

**Zle — cennik hardkodowany w TypeScript:**
```typescript
// Każda zmiana = redeploy + brak audytu + rozbieżności między kalkulatorami
const price = { min: 180, max: 280 }; // hardkod — nie testowalne, nie audytowalne
const result = price.min * 80 * 1.20 * 1.15;
```

**Dobrze — override z deltą:**
```yaml
# rules-override.yaml — tylko zmieniona pozycja, reszta z baseline
pricing:
  fundament_plytowy: { min: 370, max: 480, unit: "PLN/m²" }
```

**Zle — override = kopia baseline:**
```yaml
# Kopia całego baseline + 1 zmiana = 2 pliki do synchronizacji przy update
pricing:
  fundament_plytowy: { min: 370, max: 480, unit: "PLN/m²" }
  mur_ytong_24cm: { min: 180, max: 280, unit: "PLN/m²" }  # duplikat
```

---

## Antywzorce

1. **Side-effects w `calculate`** — `console.log`, `Date.now`, `Math.random` → testy niedeterministyczne, snapshot nieprzewidywalny.
2. **Silent fallback dla pricing** — `rules.pricing[el] ?? { min: 0, max: 0 }` → wycena 0 PLN, klient widzi "0 zł" bez błędu.
3. **Brak snapshot testów** — zmiana cennika bez code review, regresje silent. Zawsze commit `.snap`.
4. **YAML klucze z polskimi znakami** — `małopolskie` vs `malopolskie` → parse error. Używaj ASCII slug.
5. **Override jako kopia baseline** — drift przy update, 2 pliki do synchronizacji. Override = tylko delta.
6. **MAJOR mismatch hard-fail** — blokuje legacy kalkulatory bez wartości. Użyj WARN + continue.
7. **rules-baseline.yaml poza git** — brak historii zmian, brak rollback. Zawsze version-controlled.
8. **Brak `meta.disclaimer`** — wynik engine w UI bez disclaimera = "cena gwarantowana". Zawsze disclamer.

---

## Powiązania

**Requires:** `webapp-calculator-patterns` (UX layer), `construction-domain-rules` (cennik baseline PL)

**Upstream:** `webapp-standards` (TS strict + Zod), `regional-seo-poland` (mapa 16 województw)

**Downstream:** `calculator-builder` agent (5C E5 — planowany, cite §1-§7 podczas impl.)

**Companion files:** `rules-schema.json` (VSCode spec), `sample-rules-baseline.yaml` (cennik PL 2024-2026), `engine-pure-function.ts` (TS boilerplate + snapshot pattern)

---

## References

1. zod.dev — Zod schema validation API (RulesSchema, refine, ZodError path)
2. json-schema.org/specification — JSON Schema Draft-07 (`rules-schema.json`)
3. npmjs.com/package/yaml — `yaml` package TS-native (schema-aware, preferowany nad `js-yaml`)
4. construction-domain-rules §7 — Stawki rynkowe PL 2024-2026 (źródło danych baseline)
5. jestjs.io/docs/snapshot-testing — Jest `.toMatchSnapshot` pattern
