---
name: multi-plan-workflow
version: "1.0.0"
type: skill
category: universal
description: "Use when working in a project with `next-session*.md` files (knowledge-base/ or docs/) or with `plans/` directory containing >1 active plan. Manages 3-slot system for parallel work in multiple terminals/branches."
compatible_with: [universal]
requires: []
tags: [planning, workflow, multi-plan, sessions, universal]
token_cost: medium
files:
  - SKILL.md
  - manifest-format.md
  - migration-guide.md
---

# multi-plan-workflow

Konwencja 3 slotow kontekstu sesji dla rownoległej pracy w wielu terminalach/branchach.
Powstał po identyfikacji problemu #2 masterplanu fabryki (2026-05-06): jeden `next-session.md`
= jeden slot → Claude miesza priorytety 3 otwartych terminali.

## 1. Kiedy uruchomić

**Uruchamiaj gdy:**
- W projekcie istnieje wiecej niz jeden plik `next-session-*.md`
- W projekcie jest katalog `plans/` z >1 aktywnym planem
- operator pyta "co dalej" / "kontynuujemy" / "który terminal" i w cwd jest `next-session-index.md`
- Zaczynasz sesje w projekcie gdzie poprzednio działały równolegle 2+ wątki pracy

**NIE uruchamiaj gdy:**
- Projekt ma jeden `next-session.md` i jeden aktywny plan (wystarczy standardowy flow)
- Sesja jest jednorazowa, bez ciągłości (np. exploration session)
- Chcesz zmigrować z single na multi — czytaj najpierw `migration-guide.md`

---

## 2. Twardy limit: 3 sloty

**Maksymalna liczba aktywnych slotów to 3.** To dyscyplina, nie ograniczenie techniczne.

**Dlaczego 3, a nie N:**
- 3 terminale = praktyczny limit dla jednego człowieka bez utraty kontekstu
- Przy 4+ slotach koszt "przełączania głowy" przewyższa korzyść z równoległości
- Slot to nie tylko plik — to aktywna gałąź uwagi; >3 = jeden zawsze zaniedbany
- Każdy dodatkowy slot multiplikuje ryzyko dryfu planu (problem #3 masterplanu)

**Gdy potrzebujesz 4. slotu:**
1. Znajdź slot ze statusem `active` który można zamknąć jako `done`
2. Zmień jego status: `status: done` w frontmatterze + w manifeście
3. Dopiero wtedy utwórz nowy slot na jego miejscu

---

## 3. Format `next-session-{N}.md`

Kazdy plik slotu **musi** mieć frontmatter YAML. Bez frontmattera konsumenci (hook, agent) nie
mogą wykryć który slot dotyczy bieżącego kontekstu.

```yaml
---
slot: 1
title: "Security Faza B"
branch: "security/faza-b"   # opcjonalne gdy slot=branch
module: "security"           # opcjonalne gdy slot=module
last_update: "2026-05-07"
status: "active"             # active | paused | done
---
```

**Pola wymagane:** `slot`, `title`, `last_update`, `status`
**Pola warunkowe:** `branch` (wymagane gdy allocation rule = slot=branch), `module` (wymagane gdy slot=module)

Po frontmatterze — standardowa treść `next-session.md`: priorytety, "W trakcie", "Zamknięte".

### Bledy które skill wykrywa (dla konsumentow)

| Sytuacja | Komunikat |
|---|---|
| Istnieje `next-session.md` + `next-session-1.md` równocześnie | "Stan mieszany — uruchom `migration-guide.md`, single→multi" |
| Brak pola `slot:` lub `status:` w frontmatterze | "Frontmatter niekompletny — patrz sekcja 3 SKILL.md" |
| `branch:` puste gdy allocation rule = slot=branch | "Brak `branch:` mimo że slot odpowiada gałęzi git" |
| >3 plików `next-session-N.md` ze statusem `active/paused` | "Przekroczono limit 3 slotów — zamknij jeden jako `done`" |
| Dwa pliki mają ten sam `slot: N` | "Duplikat slotu — max 1 plik na slot" |

---

## 4. Manifest `next-session-index.md`

Manifest to widok wszystkich slotow w jednym miejscu. Czytany najpierw na starcie sesji.

Szczegółowy format i wypełniony przykład: `manifest-format.md`

**Skrót struktury:**

```markdown
# next-session-index
last_update: 2026-05-07

| slot | title | branch/module | status | last_update | plik |
|---|---|---|---|---|---|
| 1 | Security  | security/faza-b | active | 2026-05-07 | next-session-1.md |
| 2 | Klienci Pilot | klienci/pilot | paused | 2026-05-06 | next-session-2.md |
| 3 | Brand Cleanup | module:brand-switcher | done | 2026-05-05 | next-session-3.md |
```

**Manifest jest źródłem prawdy o statusach.** Frontmatter w `next-session-N.md` musi być
spójny z manifestem. W razie rozbieżności — manifest wygrywa (bo `plan-progress-tracker`
aktualizuje manifest po każdej zmianie).

---

## 5. Allocation rule: slot=branch vs slot=module

| Warunek | Reguła | `branch:` | `module:` |
|---|---|---|---|
| >1 aktywny git branch | `slot=branch` — każdy branch = osobny slot | wymagane | opcjonalne |
| 1 branch, wiele równoległych modułów | `slot=module` — każdy moduł = osobny slot | opcjonalne | wymagane |
| Projekt bez git | `slot=module` — fallback non-git | brak | wymagane |

**Wykrywanie slotu na starcie sesji (przez konsumentów):**
1. `git branch --show-current` → porównaj z `branch:` we frontmatterach
2. Jeśli match → to jest aktywny slot
3. Jeśli brak matcha lub non-git → zapytaj operatora "który slot?" albo sprawdź `module:`

---

## 6. Migracja single→multi

Krótka sekwencja (szczegóły z przykładem rzeczywistym w `migration-guide.md`):

1. `mv next-session.md next-session-1.md`
2. Dodaj frontmatter do `next-session-1.md` (slot=1, title, last_update, status=active)
3. Utwórz `next-session-index.md` z 1 wpisem
4. Opcjonalnie: utwórz `next-session-2.md` i `next-session-3.md` dla nowych kontekstów
5. Zaktualizuj `CLAUDE.md` projektu — zmień instrukcję "Przeczytaj `next-session.md`"
   na "Sprawdź `next-session-index.md` → wybierz slot"

---

## 7. Stan mieszany (legacy + sloty)

Stan mieszany = `next-session.md` (legacy) i `next-session-1.md` istnieją równocześnie.

**Jest to błąd konfiguracji.** Konsumenci (hook, agent) powinni:
1. Ostrzec: "Stan mieszany — uruchom kroki z `migration-guide.md`"
2. Nie ładować żadnego slotu automatycznie (ryzyko złego kontekstu)
3. Poczekać na decyzję operatora

Auto-naprawa stanu mieszanego **nie jest w scope tego skilla** — to osobny agent jeśli
potrzebny w przyszłości.

---

## 8. Git worktrees

Gdy projekt używa `git worktree`:
- **1 worktree = 1 katalog = 1 niezależny indeks slotów**
- Każdy worktree ma własny `next-session-index.md` w swoim katalogu `knowledge-base/` lub `docs/`
- Sloty w worktree A i worktree B są niezależne — nie współdzielą numeracji
- Jeśli worktree jest na branchu `security/faza-b` → slot=branch, `branch: security/faza-b`

**Nie próbuj tworzyć cross-worktree manifestu** — to prowadzi do konfliktów merge.

---

## 9. Konsumenci skilla ( — do wdrożenia)

| Konsument | Etap  | Model | Rola |
|---|---|---|---|
| `plan-progress-tracker` | E3 | sonnet | Aktualizuje `next-session-index.md` po każdej zmianie statusu etapu planu |
| `session-start-multi-plan` hook | E5 | haiku | Na starcie sesji odczytuje manifest, wykrywa branch, ładuje właściwy slot |
| `session-router` agent | E4 | haiku | Gdy ≥2 sloty → pyta operatora który wybrać, emit zawartości do kontekstu |

**Ten skill definiuje format i konwencje. Konsumenci implementują automatykę.**

---

## 10. Czego skill NIE robi

- **Nie aktualizuje manifestu automatycznie** — robi to `plan-progress-tracker` .
  Skill tylko opisuje format i reguły.
- **Nie ładuje slotu do kontekstu** — robi to hook `session-start-multi-plan` .
  Skill tylko opisuje konwencję wykrywania.
- **Nie zarządza >3 slotami** — twardy limit; skill nie opisuje jak obsłużyć 4. slot (bo go nie ma).
- **Nie naprawia stanu mieszanego automatycznie** — ostrzega, decyzja należy do operatora.
- **Nie zarządza planami ani ich postępem** — to robi skill `plan-sync-protocol` .

---

## 11. Antywzorce

| Antywzorzec | Problem | Poprawka |
|---|---|---|
| >3 sloty ze statusem `active` lub `paused` | Kontekst rozproszony, Claude nie wie co ważne | Zamknij najstarszy wątek (`status: done`) przed otwarciem nowego |
| `next-session-N.md` bez frontmattera | Hook nie może wykryć slotu, ładuje zły kontekst | Dodaj frontmatter z `slot:`, `title:`, `last_update:`, `status:` |
| Dwa pliki z `slot: 1` | Duplikat — konsumenci nie wiedzą który wybrać | Usuń lub przemianuj jeden; każdy slot max 1 plik |
| Ręczna edycja manifestu zamiast przez `plan-progress-tracker` | Desync manifest vs frontmatter pliku slotu | Zawsze aktualizuj przez agenta; ręcznie tylko gdy agent nie istnieje ( projektu) |
| `compatible_with: [universal, webapp]` w frontmatterze | Niejednoznaczne — `universal` już oznacza wszędzie | Użyj tylko `[universal]` |

---

## 12. Powiązania

- **`manifest-format.md`** (ten katalog) — szczegółowy format `next-session-index.md` z przykładem 3 slotów
- **`migration-guide.md`** (ten katalog) — step-by-step migracja single→multi z realnym przykładem (fabryka)
- **`plan-sync-protocol`** (`library/skills/universal/plan-sync-protocol/`) — ; protokół synchronizacji stanu planu po wykonanym etapie
- **`plan-progress-tracker`** (`library/agents/universal/plan-progress-tracker.md`) — ; agent aktualizujący manifest
- **`session-router`** (`library/agents/universal/session-router.md`) — ; agent wybierający slot na starcie sesji
- **`planner-design-patterns`** (`.claude/skills/planner-design-patterns/`) — wzorce projektowania planów; ten skill jest uzupełnieniem
- **`model-routing`** (`library/skills/universal/model-routing/`) — rutowanie modeli dla konsumentów tego skilla
