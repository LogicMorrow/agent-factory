# manifest-format.md — Format pliku `next-session-index.md`

Dokument referencyjny dla skilla `multi-plan-workflow`.
Czytaj gdy: tworzysz nowy manifest, weryfikujesz poprawność istniejącego, piszesz konsumenta (hook/agent).

---

## Struktura pliku

```markdown
# next-session-index
last_update: <ISO-8601 date>
project: <nazwa projektu — opcjonalne, przydatne w worktrees>

| slot | title | branch/module | status | last_update | plik |
|---|---|---|---|---|---|
| 1 | <tytuł> | <branch lub module:nazwa> | <status> | <ISO date> | next-session-1.md |
| 2 | <tytuł> | <branch lub module:nazwa> | <status> | <ISO date> | next-session-2.md |
| 3 | <tytuł> | <branch lub module:nazwa> | <status> | <ISO date> | next-session-3.md |

## Notatki
<opcjonalne notatki cross-slot — np. "slot 2 zależy od slot 1 etap E3">
```

---

## Opis kolumn

| Kolumna | Typ | Wymagane | Wartości |
|---|---|---|---|
| `slot` | liczba | tak | 1, 2 lub 3 |
| `title` | tekst | tak | czytelny tytuł wątku (do 60 znaków) |
| `branch/module` | tekst | tak | nazwa brancha GIT lub `module:<nazwa>` dla non-branch |
| `status` | enum | tak | `active`, `paused`, `done` |
| `last_update` | data ISO | tak | RRRR-MM-DD |
| `plik` | ścieżka | tak | `next-session-N.md` (relative do katalogu manifestu) |

### Semantyka statusów

| Status | Znaczenie | Czy slot zlicza się do limitu 3? |
|---|---|---|
| `active` | Wątek w trakcie — bieżąca sesja lub ostatnio aktywna | tak |
| `paused` | Wątek zawieszony — powróci w przyszłości | tak |
| `done` | Wątek zakończony — slot wolny dla nowego wątku | nie (nie blokuje limitu) |

**Limit 3 slotów** liczy tylko `active` + `paused`. Sloty `done` nie blokują.

### Format kolumny `branch/module`

```
# Gdy slot odpowiada gałęzi git:
security/faza-b

# Gdy slot odpowiada modułowi (bez brancha lub non-git):
module:brand-switcher
module:klienci-crm
module:-plan-sync

# Gdy main branch + moduł (rzadkie ale poprawne):
main/module:cleanup
```

---

## Wymagane pola w frontmatterze pliku slotu

Manifest i plik slotu muszą być spójne. Konsument (`plan-progress-tracker`) weryfikuje zgodność.

```yaml
---
slot: 1                         # musi pasować do numeru w manifeście
title: "Security Faza B"        # musi pasować do kolumny title w manifeście
branch: "security/faza-b"       # wymagane gdy slot=branch
module: "security"              # wymagane gdy slot=module
last_update: "2026-05-07"       # musi być >= daty w manifeście po update
status: "active"                # musi być taki sam jak w manifeście
---
```

**W razie rozbieżności manifest vs frontmatter pliku — manifest wygrywa.**
Konsumenci powinni emitować ostrzeżenie o desynchronizacji i czekać na decyzję operatora.

---

## Przyklad: wypelniony manifest — 3 sloty (external-crm)

Rzeczywisty scenariusz: 3 terminale, projekt external-crm, `docs/next-session-index.md`.

```markdown
# next-session-index
last_update: 2026-05-07
project: external-crm

| slot | title | branch/module | status | last_update | plik |
|---|---|---|---|---|---|
| 1 | Security  | security/faza-b | active | 2026-05-07 | next-session-1.md |
| 2 | Klienci Pilot — code-implementer | klienci/pilot | paused | 2026-05-06 | next-session-2.md |
| 3 | Brand Cleanup — switcher refaktor | module:brand-switcher | done | 2026-05-05 | next-session-3.md |

## Notatki
- Slot 3 (brand-cleanup) zamknięty 2026-05-05 — po tym wpisie slot wolny dla nowego wątku.
- Slot 2 wznawia się po ukończeniu Security  (slot 1 musi być done).
```

Odpowiadające frontmatter pliku `next-session-1.md`:

```yaml
---
slot: 1
title: "Security Faza B"
branch: "security/faza-b"
last_update: "2026-05-07"
status: "active"
---

## Priorytety tej sesji
1. [E3] Wdrożenie `fail2ban` — konfiguracja jail.local dla SSH + nginx
2. [E4] Test security-watchdog agent na staging

## W trakcie
- E2 ukończone 2026-05-06: firewall UFW + iptables rules

## Zamknięte
- E1 ukończone 2026-05-05: audyt portów + docker expose
```

---

## Przyklad: manifest fabryki (po migracji single→multi)

Ścieżka: `knowledge-base/next-session-index.md`

```markdown
# next-session-index
last_update: 2026-05-07
project: agent-factory

| slot | title | branch/module | status | last_update | plik |
|---|---|---|---|---|---|
| 1 | Master plan rozbudowy fabryki -4 | module:-plan-sync | active | 2026-05-07 | next-session-1.md |

## Notatki
- Slot 1 kontynuuje po migracji z legacy next-session.md (migration-guide.md krok 1).
- Sloty 2-3 wolne — dodaj gdy operator otworzy drugi wątek w fabryce.
```

---

## Walidacja ręczna (przed oddaniem do konsumenta)

Checklist do uruchomienia gdy tworzysz lub edytujesz manifest:

- [ ] Kolumna `slot` ma tylko wartości 1, 2, 3 (brak duplikatów)
- [ ] Kolumna `status` zawiera tylko: `active`, `paused`, `done`
- [ ] Liczba slotów `active` + `paused` <= 3
- [ ] Kolumna `plik` zawiera istniejące pliki `next-session-N.md`
- [ ] `last_update` manifestu >= `last_update` wszystkich plików slotów
- [ ] Frontmatter każdego `next-session-N.md` ma `slot:` zgodny z numerem w tabeli
- [ ] Brak jednoczesnego istnienia `next-session.md` i `next-session-1.md` (stan mieszany)

**Pełna walidacja schema (JSON Schema) planowana w  — poza scope tego skilla.**

---

## Odniesienia

- `SKILL.md` (ten katalog) — sekcja 4 "Manifest" (widok skrócony)
- `migration-guide.md` (ten katalog) — jak stworzyć manifest po raz pierwszy
- `plan-progress-tracker` — agent który aktualizuje manifest po każdym ukończonym etapie 
