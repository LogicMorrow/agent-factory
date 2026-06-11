---
name: model-routing
description: Zasady doboru modelu Claude do zadania — kiedy opus, kiedy sonnet, kiedy haiku. Uruchamiaj przy projektowaniu każdego agenta, planowaniu taskflow i optymalizacji kosztów. Fundament wszystkich projektów LogicMorrow.
---

# Model Routing — fundament oszczędności tokenów

## Zasada główna
**Płać tylko za inteligencję której faktycznie potrzebujesz.** Każde zadanie ma "minimalny model który je poprawnie wykona" — to właśnie ten model powinieneś użyć.

## Hierarchia modeli

| Model | Kiedy używać | Przykłady zadań | Koszt względny |
|---|---|---|---|
| **opus** | Złożona analiza, architektura, niejednoznaczne problemy wymagające oceny | Projektowanie agentów, analiza lessons, security review, planowanie systemu | wysoki |
| **sonnet** | Standardowe kodowanie, generowanie struktury, walidacja reguł | Pisanie kodu, bootstrap projektu, quality-checker, budowa skilli | średni |
| **haiku** | Proste transformacje, operacje na plikach, grep, formatowanie | Rename, copy, format JSON, proste szablony, wyciąganie danych | niski |

## Wzorzec "Plan → Execute → Format"

Najefektywniejszy pattern dla złożonych tasków:

```
1. PLAN (opus)
   → Co robimy, jakie kroki, jakie ryzyka, jakie decyzje architektoniczne
   → Output: ustrukturyzowany plan przekazany do następnego agenta

2. EXECUTE (sonnet)
   → Realizacja planu — pisanie kodu, tworzenie plików, transformacje
   → Output: gotowy artefakt

3. FORMAT/VALIDATE (haiku lub sonnet)
   → Sprawdzenie formatu, prostych reguł, refactor kosmetyczny
   → Output: polished result
```

## Reguły decyzyjne — kiedy opus JEST konieczny
- Projektowanie nowego agenta od zera (agent-architect)
- Analiza wzorców z wielu lekcji (meta-reviewer)
- Decyzja architektoniczna z wieloma trade-offami
- Security review kodu produkcyjnego
- Wymagania są niejednoznaczne i trzeba zadać właściwe pytania

## Reguły decyzyjne — kiedy sonnet WYSTARCZY
- Realizacja jasno zdefiniowanych wymagań (coding task z gotową specyfikacją)
- Walidacja według checklisty (quality-checker)
- Bootstrap projektu według szablonu (project-bootstrap)
- Budowa skilla z jasnym zakresem (skill-builder)
- Review commita według reguł (commit-reviewer)

## Reguły decyzyjne — kiedy haiku WYSTARCZY
- Grep, find, rename plików
- Formatowanie JSON/YAML
- Proste szablonowanie (kopiowanie z podstawianiem wartości)
- Wyciąganie danych ze struktury (parsowanie, ekstrakcja pól)
- Prosty routing (przeczytaj plik, zdecyduj gdzie zapisać)

## Antywzorce — czego unikać
- ❌ Opus do commitowania lub kopiowania plików — to marnotrawstwo 10x kosztów
- ❌ Haiku do projektowania architektury — oszczędność pozorna, efekt zły
- ❌ Jeden duży agent opus zamiast pipeline sonnet+haiku — podziel zadanie
- ❌ "Dla bezpieczeństwa damy opus" bez uzasadnienia — bezpieczeństwo to nie uzasadnienie

## Jak stosować przy projektowaniu agenta
Przed wpisaniem `model:` w frontmatter odpowiedz na 3 pytania:
1. Czy agent musi **oceniać** (niejednoznaczne wejście, trade-offy, ryzyko)? → opus
2. Czy agent **wykonuje** jasno zdefiniowane zadanie? → sonnet
3. Czy agent **transformuje lub przenosi** dane/pliki? → haiku

## Przykłady z agent-factory

| Agent | Model | Uzasadnienie |
|---|---|---|
| agent-architect | opus | Projektuje agentów — wymaga oceny trade-offów |
| meta-reviewer | opus | Analizuje wzorce z lekcji — niejednoznaczne wejście |
| quality-checker | sonnet | Waliduje wg checklisty — jasne reguły |
| skill-builder | sonnet | Realizuje jasną specyfikację skilla |
| project-bootstrap | sonnet | Scaffold wg szablonu — deterministyczne |
| commit-reviewer | sonnet | Review wg reguł — jasne kryteria |

## Powiązania
- Przy projektowaniu agenta → stosuj razem z `agent-design-patterns`
- Przy budowie skilla → stosuj razem z `skill-design-patterns`
- Meta-analiza kosztów → `meta-reviewer` może analizować model-usage z lessons.jsonl
