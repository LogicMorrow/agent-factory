# Agent Factory

Meta-workflow do tworzenia agentów, skilli i konfiguracji `.claude/` dla innych projektów. Produkuje przenośne paczki gotowe do wdrożenia lokalnie lub na serwerze.

> **Uwaga:** to jest **publiczny, anonimizowany mirror** fabryki. Realna praca (projekty klienckie, pełna baza wiedzy) dzieje się w prywatnym repo, które jest źródłem prawdy. Tutaj `knowledge-base/` zawiera wyłącznie **fikcyjne przykłady** ilustrujące mechanizm.

## Cel
Ten projekt nie zawiera kodu aplikacji — zawiera narzędzia do budowania innych projektów. Typowy flow:

1. `/new-project` — bootstrap nowego projektu (kopiuje agentów/skille z `library/`)
2. `/new-agent` lub `/new-skill` — dodanie komponentu do biblioteki lub projektu
3. `/pack` — zbuduj przenośną paczkę i wypchnij na nowe repo
4. `/log-lesson` — zapis wniosków do `knowledge-base/lessons.jsonl`
5. `/review-lessons` — okresowy przegląd, propozycje ulepszeń systemu

## Struktura
```
.claude/
├── agents/     — meta-agenci fabryki (requirements-interviewer, agent-architect, skill-builder,
│                 project-profiler, quality-checker, pack-agent, meta-reviewer, ...)
├── commands/   — slash-komendy (/new-project, /new-agent, /new-skill, /pack, /log-lesson, ...)
└── skills/     — wzorce meta (agent-design-patterns, skill-design-patterns, model-routing, ...)
library/
├── agents/     — universal | webapp | cli | automation | ai-agents
├── skills/     — universal (model-routing i inne fundamentalne) | webapp | cli | automation
└── embedded-factory/ — mini-fabryka samouczenia się, bundlowana do każdej paczki
knowledge-base/ — pamięć systemu (tu: anonimowe przykłady)
```

## Flow projektowania (3 etapy, niełamane)
1. **Wywiad** — `requirements-interviewer` zadaje pytania biznesowe, czyta kartę projektu, zapisuje brief.
2. **Projekt** — `agent-architect` / `skill-builder` czyta brief + kartę + ostatnie reflexje, projektuje technicznie.
3. **Walidacja** — `quality-checker` sprawdza zgodność ze standardami (PASS/FAIL).

**Zasada:** architekt/builder NIE startują bez briefu. To wymusza konkret zamiast domysłów.

## Modele (skill `model-routing`)
- **opus** → architektura, projektowanie agentów, analiza wzorców, bezpieczeństwo
- **sonnet** → kodowanie, budowanie skilli, bootstrap, walidacja wg reguł
- **haiku** → operacje na plikach, grep, formatowanie, proste transformacje

`model-routing` kopiowany jest do każdego projektu — to fundament oszczędności tokenów.

## Ciągłe uczenie się
- `project-profiler` zapisuje/aktualizuje kartę projektu
- `requirements-interviewer` zapisuje brief (z kontekstem karty)
- `agent-architect` zapisuje reflection po każdym agencie
- `meta-reviewer` analizuje lessons/reflections/projekty i proponuje ulepszenia
- Wzorce z reflections wstrzykiwane są do kontekstu przy następnym uruchomieniu architekta

Szczegóły pętli uczenia: `docs/how-it-works.md`.

## Zasady których nigdy nie łamiemy
1. Każdy nowy agent/skill zaczyna od `requirements-interviewer`. Bez briefu — architekt/builder nie pracują.
2. `meta-reviewer` nigdy nie modyfikuje plików agentów/skilli. Tylko propozycje.
3. Każdy agent ma sekcję „Czego NIE robi i do kogo odesłać".
4. Każdy agent ma minimalny zestaw `tools` zgodny ze skillem `model-routing`.
5. `description` agenta mówi *kiedy* go uruchomić — z konkretnym przykładem.
6. Agenty w `library/` mają rozszerzone metadane (tags, version, compatible_with, token_cost).
7. Skill `model-routing` zawsze trafia do każdego projektu.
8. `knowledge-base/` jest w git — to pamięć systemu.
9. Nie tworzymy plików bez zgody użytkownika. Pytaj, jeśli niejasne.
10. Każdy meta-agent loguje zdarzenie do `knowledge-base/activity-log.jsonl`.
11. Każde zadanie >30 min dziel na sesje 20-30 min z explicit checkpoint (commit + zapis stanu).
12. Default quality gates dla każdego nowego artefaktu — agent/skill nie wychodzi z fabryki bez quality-checker PASS + spójnych zależności + wymaganego frontmatter.

## Styl komunikacji
- Krótko, konkretnie. Decyzje techniczne podejmowane samodzielnie, z meldunkiem co zrobione.
- Priorytety: **bezpieczeństwo → responsywność → przenoszalność → porządek**.
- Decyzje architektoniczne (stack / infrastruktura / scope) — **zawsze konsultowane**, nigdy zakładane z góry.
