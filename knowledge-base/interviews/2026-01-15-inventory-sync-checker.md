# Brief: inventory-sync-checker (EXAMPLE — fictional)

> Brief zmyślony — ilustruje, jak wygląda wsad z wywiadu `requirements-interviewer` przed projektowaniem agenta.

**Projekt:** example-lumen-bookstore
**Data wywiadu:** 2026-01-15
**Cel artefaktu:** agent, który wychwytuje błędy synchronizacji stanu magazynowego w kodzie i migracjach.

## 1. Problem (słowami właściciela)
„Po imporcie CSV od dostawcy czasem znika stan z książek, które ktoś właśnie kupił. Chcę, żeby ktoś pilnował, że kod nie nadpisuje świeżych zamówień."

## 2. Zakres
- **Robi:** czyta zmiany w warstwie danych (Prisma schema, route handlers importu CSV i checkoutu), wskazuje miejsca, gdzie zapis stanu może wyścigowo nadpisać zamówienie; proponuje blokady/transakcje/idempotencję.
- **NIE robi:** nie pisze migracji (→ code-implementer), nie review'uje całego PR-a (→ commit-reviewer), nie konfiguruje płatności (→ poza zakresem).

## 3. Wejście / wyjście
- **Wejście:** ścieżka do projektu + opcjonalnie lista zmienionych plików.
- **Wyjście:** lista findings `{plik, linia, ryzyko, rekomendacja}` + werdykt PASS/WARN/FAIL.

## 4. Model
- **sonnet** — analiza kodu wg konkretnych reguł, nie projektowanie architektury.

## 5. Reguły domenowe (od właściciela)
- Import CSV i przyjęcie zamówienia są współbieżne — każdy zapis stanu MUSI być w transakcji z blokadą wiersza.
- Webhook płatności bywa wielokrotny — operacje muszą być idempotentne.

## 6. Kryteria sukcesu
- Wychwytuje brak transakcji wokół aktualizacji `stock`.
- Wychwytuje nieidempotentny handler webhooka.
- Zero false-positive na ścieżkach tylko do odczytu.
