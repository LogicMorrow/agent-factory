# Apple HIG dla Seniora 50+ — DESKTOP-FIRST v2.0.0

## Kontekst persona (REBUILD )

Użytkownik docelowy: **właściciel małej firmy, 50+, nie-IT**. Używa apki:
- **Na laptopie w biurze** (70-80% użycia) — mysz i klawiatura, ekran 1280-1920px
- **Na iPhonie na budowie** (20-30%) — read-only przegląd, jeden kciuk, możliwe brudne rękawice

**v1.0.0 BŁĄD :** zakładał touch-first 48pt minimum jako absolutne. Desktop był "modyfikacją".
**v2.0.0 REVERSAL:** desktop mouse = primary ergonomia. Mobile touch = responsive fallback.

---

## 1. Touch / Click Targets

### Dual target sizes (DESKTOP-FIRST v2.0.0)

| Parametr | Apple HIG minimum | Desktop primary (mouse) | Mobile responsive (touch senior) |
|---|---|---|---|
| Button CTA | 44pt | **44pt (44px) — default klasy** | **48-56pt `max-md:`** |
| Ikona interaktywna | 44pt | 44pt | 48pt `max-md:` |
| Input field | 44pt | 44pt | 52pt `max-md:` |
| Link tekstowy | 44pt highlight | 44pt | 48pt `max-md:` |
| Switch / Toggle | 51pt iOS | 44pt (slider-like) | 51pt `max-md:` |
| Checkbox / Radio | 44pt | 44pt | 48pt `max-md:` |

**Uwaga:** 1pt CSS ≈ 1px przy standardowym DPR. Apple HIG pt = CSS px w domyślnym scale.

### Implementacja (desktop-first)

```tsx
// POPRAWNIE — 44px desktop default, 48px mobile override
<button
  className="min-h-[44px] min-w-[44px] max-md:min-h-[48px] max-md:min-w-[48px]
             flex items-center justify-center px-3"
  aria-label="Usuń pozycję"
>
  <TrashIcon className="w-5 h-5" />
</button>

// BŁĘDNIE (v1.0.0) — 48px absolutne, ignoruje desktop-first
<button className="min-h-[48px] min-w-[48px] p-3">
  <TrashIcon />
</button>

// KRYTYCZNY BŁĄD — 32px za małe na desktop mouse dla seniora
<button className="w-8 h-8 p-1">
  <TrashIcon />
</button>
```

```tsx
// Input field — 44px desktop, 52px mobile
<Input
  className="min-h-[44px] max-md:min-h-[52px] text-lg-body px-4"
  placeholder="Nazwisko klienta"
/>
```

---

## 2. Typografia — Czytelność dla 50+

### Minimalne rozmiary

| Element | Min size | Klasa Tailwind | Uwaga |
|---|---|---|---|
| Body / label formularza | **17pt (17px)** | `text-lg-body` | iOS System Font Body default |
| Placeholder input | 16pt | `text-base` | Nie zmniejszaj poniżej 16pt |
| Tekst pomocniczy / footnote | 13pt | `text-lg-footnote` | Absolutne minimum — nie mniej |
| Nagłówek sekcji | 22pt+ | `text-lg-title-2` | Separacja wizualna między sekcjami |
| CTA / przycisk | 17pt semibold | `text-lg-body font-semibold` | Wyraźna etykieta akcji |
| PDF (dla klienta) | 11pt+ | `text-lg-caption-2` | Druk fizyczny — drobne OK |

**Skala iOS desktop-first (max 3 hierarchie widoczne jednocześnie):**

```tsx
// Tytul ekranu — zawsze jeden
<h1 className="text-lg-large-title font-bold text-[--lg-label-primary]">
  Nowa oferta
</h1>

// Nagłówek sekcji — jeden per panel
<h2 className="text-lg-headline font-semibold text-[--lg-label-primary]">
  Pozycje kosztorysowe
</h2>

// Treść formularza — body minimum 17pt
<label className="text-lg-body font-medium text-[--lg-label-secondary]">
  Metraż dachu (m²)
</label>
<Input className="min-h-[44px] text-lg-body" type="number" inputMode="decimal" />

// Pomocnicza notatka — footnote OK dla secondary info
<p className="text-lg-footnote text-[--lg-label-tertiary]">
  Podaj w metrach kwadratowych
</p>
```

---

## 3. Kontrast — WCAG AA na glass surface

### Reguła

Glass surface zmienia się zależnie od tła pod nią. Kontrast MUSI być weryfikowany
z faktycznym tłem aplikacji (gradient Wariantu 1: `#FAF7F2 → #EEE4D3`).

| Relacja | Min ratio | Standard |
|---|---|---|
| body text na surface | **4.5:1** | WCAG AA SC 1.4.3 |
| large text (22pt bold+) na surface | **3:1** | WCAG AA SC 1.4.3 |
| ikona aktywna na surface | 3:1 | WCAG AA SC 1.4.11 |
| placeholder text w input | 4.5:1 | Brak wyjątku dla placeholdera |

### Pre-wyliczone (Wariant 1 light mode — tło `#FAF7F2`)

| Tekst | Kolor | Na surface-1 (60% white) | Ratio | Wynik |
|---|---|---|---|---|
| Primary | `#0F172A` (slate-900) | Surface 1 light | ~17:1 | PASS AAA |
| Secondary | `#334155` (slate-700) | Surface 1 light | ~10:1 | PASS |
| Tertiary | `#64748B` (slate-500) | Surface 1 light | ~4.9:1 | PASS body |
| Disabled | `#94A3B8` (slate-400) | Surface 1 light | ~2.6:1 | Zgodnie ze spec — disabled wyjęty |

**Wariant 1 zapewnia wyjątkowo wysoki kontrast** dzięki ciemnemu slate-900 na ciepłym kremowym tle.

---

## 4. Max 3 CTA per viewport

```tsx
// POPRAWNIE — desktop: 3 CTA + overflow w Popover
<div className="flex gap-3 items-center">
  {/* Primary */}
  <Button size="lg" className="min-h-[44px]">
    Generuj PDF
  </Button>
  {/* Secondary */}
  <Button variant="secondary" className="min-h-[44px]">
    Zapisz wersję roboczą
  </Button>
  {/* Overflow menu — Popover na desktop */}
  <Popover>
    <PopoverTrigger asChild>
      <Button variant="ghost" size="icon" className="min-h-[44px] min-w-[44px]">
        <MoreHorizontal className="w-5 h-5" />
      </Button>
    </PopoverTrigger>
    <PopoverContent className="lg-modal w-44 p-1">
      <Button variant="ghost" className="w-full justify-start text-[--lg-material-red]" onClick={onDelete}>
        Usuń ofertę
      </Button>
    </PopoverContent>
  </Popover>
</div>

// BŁĘDNIE — 5 CTA w viewport
<div>
  <Button>Generuj PDF suma</Button>
  <Button>Generuj PDF rozbicie</Button>
  <Button>Podgląd</Button>
  <Button>Zapisz</Button>
  <Button>Wyślij mailem</Button>
</div>
```

---

## 5. Popover desktop / Bottom Sheet mobile — primary pattern v2.0.0

### Kiedy użyć Popover vs Sheet (desktop-first)

| Sytuacja | Desktop (≥768px) | Mobile responsive (<768px) |
|---|---|---|
| Wybór jednej z 3-7 opcji | `<Popover>` lub `<DropdownMenu>` | `<Sheet side="bottom">` |
| Formularz z 2-5 polami | `<Dialog>` (wycentrowany) | `<Sheet side="bottom">` |
| Potwierdzenie destructive | `<AlertDialog>` | `<Sheet side="bottom">` |
| Duży formularz (8+ pól) | Osobna strona (push nav) | Osobna strona |
| Context menu (kliknięcie prawy przycisk) | `<DropdownMenu>` | `<Sheet side="bottom">` |

### Implementacja wzorcowa (responsive)

```tsx
// hooks/useIsDesktop.ts
import { useMediaQuery } from '@/hooks/useMediaQuery'
export const useIsDesktop =  => useMediaQuery('(min-width: 768px)')

// Komponent akcji z responsive pattern
function OfferActions({ offer }: { offer: Offer }) {
  const isDesktop = useIsDesktop
  const [sheetOpen, setSheetOpen] = useState(false)

  if (isDesktop) {
    return (
      <Popover>
        <PopoverTrigger asChild>
          <Button variant="secondary" className="min-h-[44px]">
            Opcje oferty
          </Button>
        </PopoverTrigger>
        <PopoverContent className="lg-modal w-48 p-1 space-y-0.5">
          <Button variant="ghost" className="w-full justify-start" onClick={ => generatePdf(offer)}>
            Pobierz PDF
          </Button>
          <Button variant="ghost" className="w-full justify-start" onClick={ => editOffer(offer)}>
            Edytuj
          </Button>
          <Button variant="ghost" className="w-full justify-start text-[--lg-material-red]"
                  onClick={ => confirmDelete(offer)}>
            Usuń
          </Button>
        </PopoverContent>
      </Popover>
    )
  }

  return (
    <>
      <Button variant="ghost" size="icon" className="min-h-[44px]" onClick={ => setSheetOpen(true)}>
        <MoreHorizontal className="w-5 h-5" />
      </Button>
      <Sheet open={sheetOpen} onOpenChange={setSheetOpen}>
        <SheetContent side="bottom" className="lg-modal pb-safe px-4 pt-0">
          <div className="flex justify-center py-3">
            <div className="w-10 h-1 rounded-full bg-[--lg-separator-opaque]" />
          </div>
          <div className="flex flex-col gap-3">
            <Button size="lg" className="w-full" onClick={ => generatePdf(offer)}>
              Pobierz PDF
            </Button>
            <Button variant="secondary" size="default" className="w-full" onClick={ => editOffer(offer)}>
              Edytuj
            </Button>
          </div>
        </SheetContent>
      </Sheet>
    </>
  )
}
```

---

## 6. Hover + Focus-visible + Active (desktop-first triad)

Touch nie ma hover. Desktop ma mysz. Oba konteksty wymagają feedback.

```tsx
// POPRAWNIE — wszystkie 3 stany
<button className={cn(
  // hover: — mysz laptop (primary)
  "hover:bg-[--lg-interactive-pressed]",
  // focus-visible: — klawiatura TAB
  "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[--lg-accent-brand]",
  // active: — click desktop + touch mobile
  "active:scale-[0.97] active:bg-[--lg-interactive-pressed]",
  "transition-all duration-200 ease-spring"
)}>
  Kliknij
</button>

// BŁĘDNIE — tylko hover, klawiatura i touch bez feedback
<button className="hover:bg-slate-100 transition">
```

---

## 7. Polski copy — zero żargonu IT

| Zły anglicyzm | Dobre polskie | Uwaga |
|---|---|---|
| "Submit" | "Wyślij" / "Zatwierdź" | Max 2 słowa w CTA |
| "Cancel" | "Anuluj" | Zawsze PL |
| "Delete" | "Usuń" | Nie "Kasuj" (zbyt potoczne) |
| "Draft" | "Wersja robocza" | |
| "Export PDF" | "Pobierz PDF" / "Generuj PDF" | |
| "Dashboard" | "Główna" / "Panel" | |
| "Quote" | "Oferta" / "Wycena" | Kontekst decyduje |
| "Error 422" | "Sprawdź wypełnione pola" | Brak kodów HTTP w UI |
| "N/A" | "Brak" / "Nie dotyczy" | |
| "Save" | "Zapisz" | |
| "Sign in / Login" | "Zaloguj się" | |

**Zasada:** jeśli Jan (50+, dekarz, pracuje w terenie) nie używa tego słowa w rozmowie — nie używaj w UI.

---

## 8. Safe area — mobile responsive (NIE bloker dla desktop)

Laptopy nie mają notch ani home indicator. Safe area dotyczy tylko iPhone responsive.

```tsx
// layout.tsx — obowiązkowe dla mobile Safari
export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  viewportFit: 'cover',   // WYMAGANE dla env(safe-area-inset-*) na iPhone
}

// Sticky elementy: safe area tylko na mobile (max-md:)
<nav className="fixed bottom-0 left-0 right-0 px-4
                max-md:pb-safe bg-[--lg-surface-1]">
  {/* tab items */}
</nav>

// Bottom Sheet — pb-safe zawsze (sheet pojawia się na mobile)
<SheetContent side="bottom" className="lg-modal pb-safe px-4">
  {content}
</SheetContent>
```
