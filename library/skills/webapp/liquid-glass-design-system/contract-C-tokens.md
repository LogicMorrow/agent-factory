# Kontrakt C — Design Tokens (JSON Schema v2) — DESKTOP-FIRST

## Meta

**Contract ID:** `liquid-glass-design-tokens-c`
**Schema version:** 2 (bump z 1 — breaking change desktop-first reversal)
**Producer:** `liquid-glass-design-system` skill (ten plik + `assets/design-tokens.json`)
**Consumers:** `web-builder` (agent), `code-implementer` (agent)
**Verifier:** `ios-ux-checker` (agent) — 12 checków A-L

### Breaking changes v1 → v2

| Pole | v1 | v2 |
|---|---|---|
| `elevation.blur_per_level_px` | `[0, 8, 16, 24]` (mobile default) | `[0, 6, 12, 20]` (desktop default) |
| `elevation.blur_mobile_override_px` | nie istniało | `[0, 8, 16, 24]` (mobile `max-md:`) |
| `elevation.glass_opacity_per_level` | `[1, 0.70, 0.80, 0.90]` | `[1, 0.60, 0.72, 0.88]` (desktop primary) |
| `touch_targets.minimum_pt` | `48` (mobile-first) | `44` desktop primary |
| `touch_targets.mobile_minimum_pt` | nie istniało | `48` (`max-md:` override) |
| `brand_palette_variant` | nie istniało | `1` (default), `2`, `3` |
| `action_sheet_pattern` | nie istniało | `"popover-desktop|sheet-mobile"` |

---

## Pełny JSON — design-tokens.json (v2)

Plik `library/skills/webapp/liquid-glass-design-system/assets/design-tokens.json`.

```json
{
  "schema_version": 2,
  "contract_id": "liquid-glass-design-tokens-c",
  "tokens_version": "2.0.0",
  "producer": "liquid-glass-design-system",
  "consumers": ["web-builder", "code-implementer"],
  "verified_by": "ios-ux-checker",

  "brand_palette_variant": 1,
  "brand_palette_note": "1=ciepły drewno+dach (DEFAULT DemoApp), 2=chłodny stal, 3=czerwony lakier. Zmień brand_palette_variant i apply odpowiedni blok colors.palette_N. Finalizacja w  przy bootstrappie.",

  "payload": {

    "colors": {
      "active_variant": 1,
      "palette_1": {
        "name": "Ciepły gradient drewno+dach",
        "accent":              "#B97A35",
        "accent_hover":        "#9E6828",
        "accent_muted":        "#F5EBD8",
        "accent_dark":         "#D4943F",
        "accent_muted_dark":   "#3A2A15",
        "bg_gradient_from":    "#FAF7F2",
        "bg_gradient_to":      "#EEE4D3",
        "bg_primary":          "#FAF7F2",
        "surface_1_rgb":       "240, 244, 250",
        "contrast_note":       "13:1 WCAG AAA slate-900 na surface-1"
      },
      "palette_2": {
        "name": "Chłodny przemysłowy stal",
        "accent":              "#2E5C8A",
        "accent_hover":        "#234970",
        "accent_muted":        "#DBEAFE",
        "accent_dark":         "#4B8BC2",
        "bg_gradient_from":    "#F5F7FA",
        "bg_gradient_to":      "#E8EDF5",
        "bg_primary":          "#F5F7FA",
        "surface_1_rgb":       "235, 240, 248",
        "contrast_note":       "14:1 WCAG AAA slate-900 na surface-1"
      },
      "palette_3": {
        "name": "Akcentowy lakier samochodowy",
        "accent":              "#C53030",
        "accent_hover":        "#9B1C1C",
        "accent_muted":        "#FEE2E2",
        "accent_dark":         "#FC8181",
        "bg_gradient_from":    "#FCFCFD",
        "bg_gradient_to":      "#F0F1F3",
        "bg_primary":          "#FCFCFD",
        "surface_1_rgb":       "248, 248, 250",
        "contrast_note":       "15:1 WCAG AAA zinc-950 na surface-1"
      },
      "light": {
        "label": {
          "primary":    "hsl(0, 0%, 9%)",
          "secondary":  "hsl(0, 0%, 38%)",
          "tertiary":   "hsl(0, 0%, 57%)",
          "quaternary": "hsl(0, 0%, 72%)"
        },
        "surface": {
          "0": "var(--lg-bg-primary)",
          "1": "rgba(var(--lg-surface-1-rgb), var(--lg-glass-opacity-1))",
          "2": "rgba(var(--lg-surface-2-rgb), var(--lg-glass-opacity-2))",
          "3": "rgba(var(--lg-surface-3-rgb), var(--lg-glass-opacity-3))",
          "1_solid": "var(--lg-surface-1-solid)",
          "2_solid": "var(--lg-surface-2-solid)",
          "3_solid": "var(--lg-surface-3-solid)"
        },
        "separator": {
          "opaque":    "hsl(0, 0%, 84%)",
          "nonopaque": "rgba(60, 60, 67, 0.29)"
        },
        "highlight_top": "rgba(255, 255, 255, 0.30)",
        "interactive_pressed": "rgba(0, 0, 0, 0.08)",
        "interactive_focus": "<accent-brand-from-palette>"
      },
      "dark": {
        "label": {
          "primary":    "hsl(0, 0%, 100%)",
          "secondary":  "hsl(0, 0%, 60%)",
          "tertiary":   "hsl(0, 0%, 42%)",
          "quaternary": "hsl(0, 0%, 28%)"
        },
        "surface": {
          "0": "var(--lg-bg-primary)",
          "1_solid": "hsl(0, 0%, 17%)",
          "2_solid": "hsl(0, 0%, 20%)",
          "3_solid": "hsl(0, 0%, 23%)"
        },
        "separator": {
          "opaque":    "hsl(0, 0%, 22%)",
          "nonopaque": "rgba(84, 84, 88, 0.65)"
        },
        "highlight_top": "rgba(255, 255, 255, 0.08)",
        "interactive_pressed": "rgba(255, 255, 255, 0.12)"
      },
      "css_variable_prefix": "--lg-",
      "css_no_conflict_note": "NIE koliduje z --portfolio-* (portfolio-design-patterns). Zero wspólnych nazw."
    },

    "typography": {
      "font_primary": "SF Pro Display, SF Pro Text, Inter, system-ui, -apple-system, sans-serif",
      "font_license_note": "SF Pro dostępne przez system-ui/-apple-system na Apple. Inter open-source fallback. NIE bundluj SF Pro.",
      "pl_ogonki_note": "Inter v4+ pełna obsługa ąćęłńóśźż. SF Pro na Apple = native. Testuj na Windows (Inter jako fallback).",
      "scale": {
        "large_title":   { "size_rem": 2.125,  "lh_rem": 2.5625, "weight": 700, "class": "text-lg-large-title" },
        "title_1":       { "size_rem": 1.75,   "lh_rem": 2.125,  "weight": 400, "class": "text-lg-title-1" },
        "title_2":       { "size_rem": 1.375,  "lh_rem": 1.75,   "weight": 400, "class": "text-lg-title-2" },
        "title_3":       { "size_rem": 1.25,   "lh_rem": 1.5625, "weight": 400, "class": "text-lg-title-3" },
        "headline":      { "size_rem": 1.0625, "lh_rem": 1.375,  "weight": 600, "class": "text-lg-headline" },
        "body":          { "size_rem": 1.0625, "lh_rem": 1.375,  "weight": 400, "class": "text-lg-body",    "min_senior": true },
        "callout":       { "size_rem": 1.0,    "lh_rem": 1.3125, "weight": 400, "class": "text-lg-callout" },
        "subheadline":   { "size_rem": 0.9375, "lh_rem": 1.25,   "weight": 400, "class": "text-lg-subheadline" },
        "footnote":      { "size_rem": 0.8125, "lh_rem": 1.125,  "weight": 400, "class": "text-lg-footnote" },
        "caption_1":     { "size_rem": 0.75,   "lh_rem": 1.0,    "weight": 400, "class": "text-lg-caption-1" },
        "caption_2":     { "size_rem": 0.6875, "lh_rem": 0.8125, "weight": 400, "class": "text-lg-caption-2" }
      },
      "minimum_body_pt": 17,
      "note_senior": "Jan 50+ — body min 17pt. Footnote 13pt = absolutne minimum. Caption (11-12pt) TYLKO microtext."
    },

    "spacing": {
      "scale_px":                  [0, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64],
      "grid_base_px":              8,
      "screen_padding_desktop_px": 24,
      "screen_padding_mobile_px":  16,
      "safe_area_note": "env(safe-area-inset-*) dla iPhone notch / home indicator. viewportFit=cover obowiązkowe w layout.tsx."
    },

    "radius": {
      "xs_px": 8, "sm_px": 12, "md_px": 16, "lg_px": 20, "xl_px": 24, "modal_px": 28, "full": "9999px",
      "note": "xl (24px) dla kart iOS-like. modal (28px) dla Sheet/Dialog. md (16px) dla przycisków drugorzędnych."
    },

    "elevation": {
      "depth_levels":              [0, 1, 2, 3],
      "blur_per_level_px":         [0, 6, 12, 20],
      "blur_mobile_override_px":   [0, 8, 16, 24],
      "blur_note":                 "blur_per_level_px = desktop primary :root. blur_mobile_override_px = @media max-width: 767px override.",
      "saturate_per_level":        [1, 1.3, 1.5, 1.7],
      "shadow_per_level": [
        "none",
        "0 2px 12px rgba(0,0,0,0.06)",
        "0 8px 32px rgba(0,0,0,0.10)",
        "0 16px 56px rgba(0,0,0,0.18)"
      ],
      "glass_opacity_per_level":   [1, 0.60, 0.72, 0.88],
      "glass_opacity_mobile_override": [1, 0.40, 0.60, 0.80],
      "css_classes":               ["lg-bg", "lg-card", "lg-modal", "lg-overlay"],
      "use_per_level": [
        "background — solid gradient, bez glass",
        "cards, list items, sekcje formularza",
        "modals desktop (Dialog) + popovers + sheets mobile",
        "context menus, tooltips, toasts"
      ]
    },

    "touch_targets": {
      "desktop_primary_pt":      44,
      "mobile_responsive_min_pt": 48,
      "mobile_responsive_pref_pt": 56,
      "apple_hig_absolute_min_pt": 44,
      "tailwind_desktop":        "min-h-[44px] min-w-[44px]",
      "tailwind_mobile_override": "max-md:min-h-[48px] max-md:min-w-[48px]",
      "note": "v2.0.0 reversal: 44pt desktop primary (mouse), 48-56pt mobile responsive (touch senior). v1.0.0 było 48pt absolute."
    },

    "action_sheet_pattern": "popover-desktop|sheet-mobile",
    "action_sheet_note": "Desktop (≥768px): shadcn Popover lub DropdownMenu. Mobile (<768px): Sheet side='bottom' + pb-safe. v2.0.0 reversal — v1.0.0 używało Sheet everywhere.",

    "animation": {
      "spring_easing":      "cubic-bezier(0.32, 0.72, 0, 1)",
      "tailwind_class":     "ease-spring",
      "duration_fast_ms":   150,
      "duration_normal_ms": 200,
      "duration_slow_ms":   300,
      "duration_slower_ms": 400
    }
  }
}
```

---

## Instrukcja konsumpcji dla web-builder i code-implementer

1. **Wczytaj `assets/design-tokens.json`** — sprawdź `brand_palette_variant` (default: 1).
2. **Zastosuj paletę** — wklej CSS variables z odpowiedniego `palette_N` bloku z `tokens-color-typography.md`.
3. **Ustaw `--lg-surface-1-rgb`** na wartość `surface_1_rgb` z aktywnej palety.
4. **Skopiuj `tailwind.config.ts`** snippet z `tailwind-shadcn-integration.md`.
5. **Implementuj komponenty** — Card, Button, Popover, Sheet z adapterów w `tailwind-shadcn-integration.md`.
6. **Uruchom `ios-ux-checker`** po pierwszym ekranie — 12 checków A-L. Verdict PASS lub PASS-WITH-NOTES przed merge.

## Weryfikacja kontraktu przez quality-checker

```
quality-checker sprawdza:
- [ ] schema_version == 2
- [ ] contract_id == "liquid-glass-design-tokens-c"
- [ ] consumers zawiera ["web-builder", "code-implementer"]
- [ ] elevation.blur_per_level_px == [0, 6, 12, 20]   (desktop primary)
- [ ] elevation.blur_mobile_override_px == [0, 8, 16, 24]
- [ ] touch_targets.desktop_primary_pt == 44
- [ ] touch_targets.mobile_responsive_min_pt == 48
- [ ] brand_palette_variant in [1, 2, 3]
- [ ] action_sheet_pattern == "popover-desktop|sheet-mobile"
- [ ] css_variable_prefix == "--lg-"
```
