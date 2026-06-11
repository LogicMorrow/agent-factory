# Przykłady i Anti-patterns — v2.0.0 DESKTOP-FIRST

## Para 1 — Glass Card DESKTOP-FIRST (dobrze vs źle)

### Źle — mobile-first, brak tokenów, brak fallback

```tsx
// BŁĄD  — mobile-first w desktop-first projekcie
function OfferList {
  return (
    // Mobile-first: grid 1 → md:2 → lg:3
    <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
      <div style={{
        background: 'rgba(255,255,255,0.15)',
        backdropFilter: 'blur(8px)',    // hardcoded, nie token, mobile blur
        borderRadius: '12px',           // nie token --lg-radius-xl
        padding: '16px',
      }}>
        <h3 className="text-sm">Kowalski Jan</h3>   {/* text-sm = 14px < 17pt FAIL */}
        <button className="h-9 bg-blue-500 text-white px-3">Pobierz PDF</button>  {/* 36px < 44pt */}
      </div>
    </div>
  )
}
```

Problemy: mobile-first prefiksy `md:`/`lg:`, inline style bez tokenów, brak `@supports` fallback,
tekst `text-sm` (14px) < minimum 17pt, przycisk 36px < 44pt desktop minimum.

### Dobrze — desktop-first, tokeny, fallback, dual targets

```tsx
// POPRAWNIE — desktop-first grid, tokeny --lg-*, @supports via .lg-card
function OfferList({ offers }: { offers: Offer[] }) {
  return (
    // Desktop-first: grid 3 → max-lg:2 → max-md:1
    <div className="grid grid-cols-3 gap-6 max-lg:grid-cols-2 max-md:grid-cols-1 p-6 max-md:p-4">
      {offers.map(offer => (
        <article
          key={offer.id}
          className="lg-card p-5 cursor-pointer transition-all duration-200 ease-spring active:scale-[0.98]"
        >
          <header className="flex justify-between items-start mb-3">
            <h3 className="text-lg-title-3 font-medium text-[--lg-label-primary]">
              {offer.client_name}
            </h3>
            <span className="text-lg-footnote text-[--lg-label-tertiary]">
              {formatDate(offer.created_at)}
            </span>
          </header>
          <hr className="border-t border-[--lg-separator-nonopaque] mb-3" />
          <div className="flex justify-between items-baseline">
            <span className="text-lg-callout text-[--lg-label-secondary]">Wartość netto</span>
            <span className="text-lg-headline font-semibold text-[--lg-label-primary]">
              {formatPLN(offer.total_net)} zł
            </span>
          </div>
          {/* Popover z akcjami — desktop primary */}
          <OfferActions offer={offer} />
        </article>
      ))}
    </div>
  )
}
```

Dlaczego poprawnie: `lg-card` zawiera `@supports` fallback, tokeny `--lg-*` reagują na dark mode,
desktop-first grid `grid-cols-3` default + `max-lg:`/`max-md:` downgrade, typografia spójna z iOS scale.

---

## Para 2 — Popover desktop + Sheet mobile (NOWY wzorzec v2.0.0)

### Źle — Bottom Sheet everywhere (v1.0.0 mobile-first error)

```tsx
// BŁĄD — bottom sheet na desktop jak na mobile
function OfferActions({ offer }: { offer: Offer }) {
  const [open, setOpen] = useState(false)
  return (
    <>
      <Button variant="ghost" size="icon" onClick={ => setOpen(true)}>
        <MoreHorizontal className="w-5 h-5" />
      </Button>
      {/* Sheet wszędzie — ergonomia desktop zepsuta */}
      <Sheet open={open} onOpenChange={setOpen}>
        <SheetContent side="bottom">
          <Button className="w-full" onClick={onPdf}>Pobierz PDF</Button>
          <Button className="w-full" onClick={onEdit}>Edytuj</Button>
          <Button className="w-full text-red-500" onClick={onDelete}>Usuń</Button>
        </SheetContent>
      </Sheet>
    </>
  )
}
```

Problemy: Sheet z `side="bottom"` na desktopie = otwiera się od dołu ekranu laptopa = nieergonomiczne.
Mysz pracuje od góry/środka. Brak `pb-safe`. Brak modalu zamknięcia klawiszem ESC desktop.

### Dobrze — Popover desktop primary, Sheet mobile responsive

```tsx
// POPRAWNIE — Popover desktop, Sheet mobile, responsive switch
function OfferActions({ offer }: { offer: Offer }) {
  const isDesktop = useIsDesktop  // useMediaQuery('(min-width: 768px)')
  const [sheetOpen, setSheetOpen] = useState(false)
  const [deleteOpen, setDeleteOpen] = useState(false)

  if (isDesktop) {
    return (
      <Popover>
        <PopoverTrigger asChild>
          <Button variant="ghost" size="icon" className="min-h-[44px] min-w-[44px] mt-3">
            <MoreHorizontal className="w-5 h-5" />
          </Button>
        </PopoverTrigger>
        <PopoverContent className="w-44 p-1 space-y-0.5" align="end">
          <Button variant="ghost" className="w-full justify-start text-lg-callout min-h-[40px]"
                  onClick={ => generatePdf(offer)}>
            Pobierz PDF
          </Button>
          <Button variant="ghost" className="w-full justify-start text-lg-callout min-h-[40px]"
                  onClick={ => editOffer(offer)}>
            Edytuj ofertę
          </Button>
          <hr className="border-[--lg-separator-nonopaque] my-1" />
          <Button variant="ghost"
                  className="w-full justify-start text-lg-callout min-h-[40px] text-[--lg-material-red]"
                  onClick={ => setDeleteOpen(true)}>
            Usuń ofertę
          </Button>
        </PopoverContent>
      </Popover>
    )
  }

  return (
    <>
      <Button variant="ghost" size="icon" className="min-h-[44px] max-md:min-h-[48px] mt-3"
              onClick={ => setSheetOpen(true)}>
        <MoreHorizontal className="w-5 h-5" />
      </Button>
      <Sheet open={sheetOpen} onOpenChange={setSheetOpen}>
        <SheetContent side="bottom" className="lg-modal lg-sheet-bottom pb-safe px-4 pt-0">
          <div className="flex justify-center py-3">
            <div className="w-10 h-1 rounded-full bg-[--lg-separator-opaque]" />
          </div>
          <div className="flex flex-col gap-3 pb-4">
            <Button size="lg" className="w-full" onClick={ => generatePdf(offer)}>
              Pobierz PDF
            </Button>
            <Button variant="secondary" size="default" className="w-full" onClick={ => editOffer(offer)}>
              Edytuj ofertę
            </Button>
            <Button variant="ghost" size="sm"
                    className="w-full text-[--lg-material-red]"
                    onClick={ => { setSheetOpen(false); setDeleteOpen(true) }}>
              Usuń ofertę
            </Button>
          </div>
        </SheetContent>
      </Sheet>
    </>
  )
}
```

---

## Para 3 — Formularz desktop-first (dobrze vs źle)

### Źle — input za mały, layout mobile-first

```tsx
// BŁĄD
<form className="w-full px-4">   {/* brak max-width desktop */}
  <label className="text-xs text-gray-400">Metraż dachu</label>   {/* 12px FAIL */}
  <input className="w-full border text-sm py-1 px-2" />            {/* h ~32px < 44pt */}
  <label className="text-xs text-gray-400">Klient</label>
  <input className="w-full border text-sm py-1 px-2" />
  <button className="mt-4 bg-blue-500 text-white px-4 py-2">      {/* h ~36px < 44pt */}
    Submit
  </button>
</form>
```

Problemy: `text-xs` labels (12px), inputs h~32px, przycisk h~36px, "Submit" EN.

### Dobrze — desktop-first layout, tokeny, 44pt targets

```tsx
// POPRAWNIE
<form className="max-w-2xl w-full mx-auto px-6 max-md:px-4 space-y-5">
  {/* Input group — desktop układ kolumny */}
  <div className="grid grid-cols-2 gap-4 max-md:grid-cols-1">
    <div className="space-y-1.5">
      <label className="text-lg-body font-medium text-[--lg-label-secondary]">
        Metraż dachu (m²)
      </label>
      <Input
        type="number"
        inputMode="decimal"
        placeholder="np. 120.5"
        className="min-h-[44px] max-md:min-h-[52px] text-lg-body px-4"
      />
      <p className="text-lg-footnote text-[--lg-label-tertiary]">
        Podaj w metrach kwadratowych
      </p>
    </div>
    <div className="space-y-1.5">
      <label className="text-lg-body font-medium text-[--lg-label-secondary]">
        Nazwisko klienta
      </label>
      <Input
        type="text"
        placeholder="np. Kowalski Jan"
        className="min-h-[44px] max-md:min-h-[52px] text-lg-body px-4"
      />
    </div>
  </div>

  {/* CTA row — max 3 */}
  <div className="flex gap-3 justify-end max-md:flex-col max-md:justify-stretch">
    <Button variant="ghost" size="sm" className="max-md:w-full">Anuluj</Button>
    <Button variant="secondary" className="min-h-[44px] max-md:w-full">Zapisz wersję roboczą</Button>
    <Button size="lg" className="max-md:w-full">Generuj PDF</Button>
  </div>
</form>
```

---

## Para 4 — Kontrast nad glass (dobrze vs źle)

### Źle — jasny tekst na jasnym glass

```tsx
// BŁĄD — white text na light glass = WCAG FAIL
<div className="backdrop-blur-md bg-white/30">
  <p className="text-gray-400 text-sm">Wartość netto</p>   {/* 2.6:1 FAIL */}
  <p className="text-white font-bold">12 500 zł</p>         {/* ~1.5:1 FAIL */}
</div>
```

### Dobrze — tokeny label, kontrast AAA

```tsx
// POPRAWNIE — --lg-label-primary (slate-900) na surface-1 = ~17:1
<div className="lg-card p-5">
  <p className="text-lg-callout text-[--lg-label-secondary]">
    Wartość netto
  </p>
  <p className="text-lg-headline font-bold text-[--lg-label-primary]">
    12 500 zł
  </p>
</div>
```

---

## Anti-patterns — pełna lista

### AP1 — Mobile-first prefiksy w desktop-first projekcie (Lesson  POST-MORTEM)

**Problem:**
```tsx
// BŁĄD — mobile-first upgrade pattern
<div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3 px-4 md:px-6">
```
Mobile staje się "bazą", desktop "nadpisaniem". W projekcie DemoApp 70-80% użycia = laptop.
Efekt: mobile layout wyglądał dobrze, desktop był afterthought.

**Rozwiązanie:**
```tsx
// POPRAWNIE — desktop-first default
<div className="grid grid-cols-3 gap-6 px-6 max-lg:grid-cols-2 max-md:grid-cols-1 max-md:px-4">
```
Default klasy = desktop (1280-1920px). `max-lg:`/`max-md:`/`max-sm:` = downgrade na mniejsze ekrany.

---

### AP2 — Brak fallback dla backdrop-filter

**Problem:**
```css
/* BŁĄD — Firefox <100 renderuje przezroczyste tło */
.card { background: rgba(255, 255, 255, 0.15); backdrop-filter: blur(6px); }
```

**Rozwiązanie:** Klasa `.lg-card` z tailwind.config.ts zawiera `@supports` z solid fallback.
Nigdy nie piszesz raw `backdrop-filter` bez `@supports`. Używaj `.lg-card`, `.lg-modal`, `.lg-overlay`.

---

### AP3 — Prefix `--portfolio-*` zamiast `--lg-*`

**Problem:**
```css
/* BŁĄD — portfolio-design-patterns prefix w webapp single-tenant */
.card { background: var(--portfolio-surface-1); }
```
ADR w SKILL.md: zero nakładania CSS variables. `--portfolio-*` = portfolio estetyka.
`--lg-*` = liquid glass desktop webapp.

**Rozwiązanie:** Zawsze `--lg-*`. Patrz ADR "Scope i desktop-first reversal".

---

### AP4 — Hardcoded rgba zamiast tokenów

**Problem:**
```css
/* BŁĄD — nie reaguje na dark mode, zmianę wariantu palety, mobile blur */
.card { background: rgba(255, 255, 255, 0.60); backdrop-filter: blur(6px); }
```

**Rozwiązanie:**
```css
/* POPRAWNIE — tokeny reagują na dark mode i media query */
.card {
  background: rgba(var(--lg-surface-1-rgb), var(--lg-glass-opacity-1));
  backdrop-filter: blur(var(--lg-blur-1)) saturate(var(--lg-saturate-1));
}
/* Mobile override automatycznie przez media query w globals.css */
```

---

### AP5 — Single-mode tokens (brak dark)

**Problem:**
```css
/* BŁĄD — brak [data-theme="dark"] bloku */
:root { --lg-accent-brand: #B97A35; }
/* Dark mode nie działa */
```

**Rozwiązanie:** Każdy token ma wersję `:root` i `[data-theme="dark"]`.
Patrz `tokens-color-typography.md` — każdy wariant palety ma oba bloki.

---

### AP6 — Bottom Sheet wszędzie na desktopie

**Problem:**
```tsx
// BŁĄD — sheet od dołu na laptop = nieergonomiczne
<Sheet><SheetContent side="bottom">...</SheetContent></Sheet>
```
Mysz na laptopie pracuje od góry/środka. Sheet od dołu = daleka podróż kursora.

**Rozwiązanie:** `isDesktop ? <Popover> : <Sheet side="bottom">`.
Patrz Para 2 powyżej + `apple-hig-senior.md` sekcja 5.

---

### AP7 — 5+ CTA per viewport

**Problem:**
```tsx
// BŁĄD — 6 CTA w viewport seniora
<Button>Generuj suma</Button><Button>Generuj rozbicie</Button>
<Button>Wyślij mailem</Button><Button>Drukuj</Button>
<Button>Duplikuj</Button><Button>Usuń</Button>
```

**Rozwiązanie:**
- MAX 3 CTA widocznych jednocześnie (primary + secondary + tertiary/ghost)
- Pozostałe w `<Popover>` desktop lub `<Sheet>` mobile
- Hierarchia: PRIMARY (1) + SECONDARY (1) + GHOST/DESTRUCTIVE (1)
