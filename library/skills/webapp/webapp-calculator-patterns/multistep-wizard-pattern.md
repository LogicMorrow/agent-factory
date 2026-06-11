# Multistep Wizard Pattern + Zod Walidacje

Companion file dla `webapp-calculator-patterns §1` (wizard) i `§2` (Zod).

---

## §1 Struktura wizarda — useReducer dla 4+ kroków

```tsx
// types.ts
type WizardState = {
  step: number;
  data: {
    step1: Step1Data | null;
    step2: Step2Data | null;
    step3: Step3Data | null;
    step4: Step4Data | null;
  };
  dirty: boolean;
};

type WizardAction =
  | { type: 'NEXT'; payload: Partial<WizardState['data']> }
  | { type: 'BACK' }
  | { type: 'RESTORE'; payload: WizardState }
  | { type: 'RESET' };

function wizardReducer(state: WizardState, action: WizardAction): WizardState {
  switch (action.type) {
    case 'NEXT':
      return { ...state, step: state.step + 1, data: { ...state.data, ...action.payload }, dirty: true };
    case 'BACK':
      return { ...state, step: Math.max(1, state.step - 1) };
    case 'RESTORE':
      return { ...action.payload, dirty: false };
    case 'RESET':
      return initialState;
    default:
      return state;
  }
}
```

## §1.1 LocalStorage Save/Restore

```tsx
const STORAGE_KEY = `calc-${slug}-state`;

// Save po każdym NEXT
useEffect( => {
  if (state.dirty) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  }
}, [state]);

// Restore on mount
useEffect( => {
  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved) {
    try {
      const parsed = JSON.parse(saved) as WizardState;
      dispatch({ type: 'RESTORE', payload: parsed });
    } catch {
      localStorage.removeItem(STORAGE_KEY); // corrupt data → reset
    }
  }
}, []);

// Cleanup po submit
function handleSubmit {
  localStorage.removeItem(STORAGE_KEY);
  // ... reszta submit logic
}
```

## §1.2 beforeunload Warning

```tsx
useEffect( => {
  function handleBeforeUnload(e: BeforeUnloadEvent) {
    if (state.dirty && !state.submitted) {
      e.preventDefault;
      e.returnValue = ''; // required by modern browsers
    }
  }
  window.addEventListener('beforeunload', handleBeforeUnload);
  return  => window.removeEventListener('beforeunload', handleBeforeUnload);
}, [state.dirty, state.submitted]);
```

## §1.3 Focus Management Between Steps

```tsx
const firstFieldRef = useRef<HTMLInputElement>(null);

// Po przejściu do nowego kroku — programmatic focus
useEffect( => {
  if (firstFieldRef.current) {
    firstFieldRef.current.focus;
  }
}, [currentStep]);

// W JSX pierwszego pola nowego kroku
<input ref={firstFieldRef} ... />
```

## §1.4 Step Indicator (dostępny)

```tsx
function StepIndicator({ current, total }: { current: number; total: number }) {
  return (
    <div role="group" aria-label="Postęp wypełniania">
      <p aria-live="polite" className="text-sm text-gray-500 mb-2">
        Krok {current} z {total}
      </p>
      <div className="flex gap-2" aria-hidden="true">
        {Array.from({ length: total }, (_, i) => (
          <div
            key={i}
            className={`h-2 flex-1 rounded-full ${
              i < current ? 'bg-blue-600' : 'bg-gray-200'
            }`}
          />
        ))}
      </div>
    </div>
  );
}
```

---

## §2 Zod Schema Per-Step + Cross-Field Rules

### Schema step z refine

```tsx
import { z } from 'zod';

// Step 1 — dane podstawowe
export const step1Schema = z.object({
  nazwaFirmy: z.string.min(2, "Min. 2 znaki").max(100),
  branża: z.enum(["budowlana", "it", "retail", "inne"]),
});

// Step 2 — z cross-field rule
export const step2Schema = z.object({
  powierzchnia: z.number({ invalid_type_error: "Podaj liczbę" })
    .min(4, "Min 4m²").max(400, "Max 400m²"),
  rodzajStoiska: z.enum(["liniowe", "wyspowe", "narozne"]),
  budzet: z.number.min(500, "Min 500 PLN"),
}).refine(
  (data) => !(data.rodzajStoiska === "wyspowe" && data.powierzchnia < 9),
  { message: "Stoisko wyspowe wymaga min. 9m²", path: ["powierzchnia"] }
).refine(
  (data) => !(data.rodzajStoiska === "wyspowe" && data.budzet < 2000),
  { message: "Stoisko wyspowe: min. budżet 2000 PLN", path: ["budzet"] }
);

// Step 3 — zależny od step1 (cross-step) — przekaż context
export const step3SchemaFactory = (step1: z.infer<typeof step1Schema>) =>
  z.object({
    terminMontazu: z.string.min(1, "Wybierz termin"),
    dodatkiOczekiwane: z.array(z.string),
  }).refine(
    (data) => step1.branża !== "budowlana" || data.dodatkiOczekiwane.includes("wywietrzenie"),
    { message: "Branża budowlana wymaga wywietrzenia", path: ["dodatkiOczekiwane"] }
  );
```

### Inline Error Component

```tsx
function FieldError({ error }: { error?: string }) {
  if (!error) return null;
  return (
    <p role="alert" aria-live="assertive" className="text-red-600 text-sm mt-1">
      {error}
    </p>
  );
}

// Użycie z react-hook-form + zod resolver:
const { register, formState: { errors } } = useForm({ resolver: zodResolver(step2Schema) });

<div>
  <label htmlFor="powierzchnia">Powierzchnia (m²)</label>
  <input
    id="powierzchnia"
    type="text"
    inputMode="numeric"
    aria-invalid={!!errors.powierzchnia}
    aria-describedby={errors.powierzchnia ? "pow-error" : undefined}
    {...register('powierzchnia', { valueAsNumber: true })}
    className={`input ${errors.powierzchnia ? 'border-red-500' : 'border-gray-300'}`}
  />
  <FieldError error={errors.powierzchnia?.message} />
</div>
```

### Prevent Next Na Invalid + Scroll To Error

```tsx
async function handleNext {
  const result = step2Schema.safeParse(currentStepData);
  if (!result.success) {
    // Scroll do pierwszego błędu
    const firstErrorField = document.querySelector('[aria-invalid="true"]') as HTMLElement;
    firstErrorField?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    firstErrorField?.focus;
    setErrors(result.error.flatten.fieldErrors);
    return;
  }
  dispatch({ type: 'NEXT', payload: { step2: result.data } });
}
```

### Full Schema Validate Na Submit

```tsx
// Ochrona przed pominięciem kroków (np. manipulacja URL)
const fullSchema = step1Schema.and(step2Schema).and(step3Schema);

async function handleSubmit {
  const merged = { ...state.data.step1, ...state.data.step2, ...state.data.step3 };
  const result = fullSchema.safeParse(merged);
  if (!result.success) {
    // Wróć do pierwszego kroku z błędem
    dispatch({ type: 'BACK' }); // lub reset do step 1
    return;
  }
  // OK — kontynuuj
}
```
