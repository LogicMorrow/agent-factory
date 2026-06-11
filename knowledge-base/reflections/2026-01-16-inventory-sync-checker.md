# Reflection: inventory-sync-checker (EXAMPLE — fictional)

> Reflexja zmyślona — pokazuje, co `agent-architect` zapisuje po zbudowaniu komponentu, by następny projekt startował mądrzej.

**Data:** 2026-01-16
**Brief:** `interviews/2026-01-15-inventory-sync-checker.md`
**Karta:** `projects/example-lumen-bookstore.md`

## Worked (co zadziałało)
- Wąski zakres („tylko synchronizacja stanu") dał ostry `description` i mały zestaw `tools` (Read, Grep, Glob) — agent jest tani i przewidywalny.
- Reguły domenowe z briefu (transakcja + idempotencja) przełożyły się 1:1 na dwa konkretne checki — bez domysłów.

## Failed (co poszło źle)
- Pierwsza wersja flagowała ścieżki read-only jako ryzyko (false-positive). Trzeba było dodać heurystykę: ostrzegaj tylko, gdy w bloku jest zapis do `stock`/`inventory`.

## Surprises (zaskoczenia)
- Najwięcej wartości dał nie sam agent, a wymuszenie, by właściciel **nazwał reguły współbieżności wprost** podczas wywiadu. Połowa „bugów" to były nieuświadomione założenia.

## Reusable (do biblioteki / lekcji)
- Wzorzec „checker domenowy = brief z twardymi regułami → 1 reguła = 1 check" jest przenośny na inne projekty (płatności, rezerwacje, limity).
- Kandydaci na lekcje: patrz `lessons.jsonl` #1 i #2.
