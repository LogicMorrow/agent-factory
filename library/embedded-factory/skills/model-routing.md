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

## Auto-downgrade reguły ( B3, 2026-05-13)

5 reguł kiedy agent z deklaracji `model: opus` lub `sonnet` może realnie wykonać przez haiku/sonnet bez utraty jakości:

### Reguła 1 — Mechaniczne patche (Edit/Write na istniejącym pliku)

**Trigger:** task = "dodaj X w sekcji Y do pliku Z" (NIE design, NIE decision-making)

**Routing:** opus → sonnet (50% saved tokens) lub sonnet → haiku (75% saved)

**Przykład:** "Zaktualizuj wersję v1.0.0 → v1.0.1 w frontmatter cv-builder.md" → haiku wystarczy (mechaniczny Edit).

### Reguła 2 — JSON schema validation / deterministic processing

**Trigger:** input ma schema, output ma schema, transformation deterministyczna

**Routing:** force haiku regardless of declared model

**Przykład:** validate-lesson-schema.sh ( A3) — deterministic, haiku perfect.

### Reguła 3 — Grep + filter + format

**Trigger:** Bash/Grep tools dominant, NO complex reasoning

**Routing:** force haiku

**Przykład:** `list-stale-proposals.sh` — find + grep + format markdown. Haiku.

### Reguła 4 — Status report agregacja

**Trigger:** factory-status, weekly-health-report, factory-status checks

**Routing:** sonnet (NIE opus — to agregacja, NIE analysis)

**Przykład:** factory-status.sh — read multiple sources, compute simple stats, format output. Sonnet.

### Reguła 5 — Simple acknowledgment / activity-log emit

**Trigger:** post-execution side effects (activity-log emit, notification)

**Routing:** force haiku

**Przykład:** każdy emit activity-log JSON entry — haiku.

---

## Implementation (jak stosować auto-downgrade)

**Per agent w frontmatter** — dodać:
```yaml
model: opus              # declared (preferred)
model_downgrade_rules:   # NEW  B3
  - rule: 1  # mechaniczne patche
    fallback: sonnet
  - rule: 5  # activity-log emit
    fallback: haiku
```

**W runtime** — orchestrator decyduje per task: jeśli task pasuje reguły → wywołuje agent z `model: <fallback>` zamiast declared.

**Activity-log emit** — pole `actual_token_cost.model` MUSI być realnie użytego model, NIE declared (audyt downgrade decisions).

## Antywzorce — czego unikać
- ❌ Opus do commitowania lub kopiowania plików — to marnotrawstwo 10x kosztów
- ❌ Haiku do projektowania architektury — oszczędność pozorna, efekt zły
- ❌ Jeden duży agent opus zamiast pipeline sonnet+haiku — podziel zadanie
- ❌ "Dla bezpieczeństwa damy opus" bez uzasadnienia — bezpieczeństwo to nie uzasadnienie
- ❌ Auto-downgrade dla design/decision tasks — quality loss większy niż tokens saved ( R4)
- ❌ Hardcoded model w activity-log — emit faktyczny user model (auto-downgrade traceable)

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
