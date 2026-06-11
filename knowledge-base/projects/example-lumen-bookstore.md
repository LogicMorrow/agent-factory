---
name: Lumen Bookstore (EXAMPLE — fictional)
slug: example-lumen-bookstore
type: webapp
status: active
path: ~/projekty/example-lumen-bookstore
repo: git@github.com:example/example-lumen-bookstore.git
created: 2026-01-14
last_updated: 2026-01-16
---

# Karta projektu: Lumen Bookstore (przykład fikcyjny)

> Ta karta jest zmyślona. Służy jako wzorzec formatu i jako kontekst dla przykładowego briefu/reflexji.

## 1. Cel biznesowy
- **Co budujemy:** mały sklep internetowy z książkami (katalog + koszyk + zamówienia).
- **Kto używa:** klienci końcowi (kupujący) + jeden administrator (właściciel sklepu).
- **Dlaczego to powstaje:** właściciel sprzedawał dotąd przez marketplace; chce własny kanał z kontrolą nad stanami magazynowymi.
- **Metryka sukcesu:** zero rozjazdów stanu magazynowego między bazą a widokiem katalogu przez 30 dni.

## 2. Moduły / funkcjonalności
- Katalog + wyszukiwarka — przeglądanie i filtrowanie tytułów.
- Koszyk + checkout — zamówienie z płatnością.
- Panel admina — import stanów magazynowych z pliku CSV dostawcy.

## 3. Stack techniczny
- **Frontend/Backend:** Next.js 15 App Router + React 19
- **DB:** PostgreSQL 16 + Prisma 5
- **Extra:** webhook płatności, import CSV
- **Dev/infra:** Docker Compose, GitHub Actions CI

## 4. Architektura
- **Porty lokalne:** Next 3002, PG 5434 — by nie kolidować z innymi projektami.
- **Integracje zewnętrzne:** bramka płatności (sandbox), feed CSV dostawcy.
- **Webhooks:** przyjmuje `payment.succeeded`.
- **Schemat deployu:** dev → prod (uproszczony, jeden VPS).

## 5. Dane i użytkownicy
- **Persony:** kupujący (anonimowy/konto), administrator (1 osoba).
- **Wrażliwość danych:** dane zamówień (PII: adres dostawy) — wymaga ostrożności.

## 6. Design / UX
- **Styl:** jasny, czytelny, system font.
- **Responsywność:** mobile-first (większość ruchu z telefonów).

## 7. Dominujące problemy i wyzwania
- **Rozjazd stanu magazynowego** — import CSV potrafi nadpisać świeże zamówienia, jeśli kolejność operacji jest zła. To główny ból projektu.
- Idempotencja webhooków płatności.

## 8. Zasoby projektu
- **Agenci:** `inventory-sync-checker` (zbudowany pod ten projekt), `commit-reviewer` (universal).
- **Skille:** `model-routing`, `webapp-standards`.

## 9. Ryzyka i rzeczy do zapamiętania
- Import CSV i przyjęcie zamówienia to operacje współbieżne — kolejność i blokady mają znaczenie.
- Sandbox płatności bywa wolny — testy nie mogą zakładać natychmiastowego webhooka.

## 10. Referencje
- **Baza wiedzy:** `knowledge-base/`
- **Brief:** `interviews/2026-01-15-inventory-sync-checker.md`

---

## Historia zmian karty
- 2026-01-14: utworzenie karty (project-profiler).
- 2026-01-16: dodano `inventory-sync-checker` do zasobów po zbudowaniu.
