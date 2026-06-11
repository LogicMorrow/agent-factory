# Cron Auto `/review-lessons` co 14 dni

**Origin:**  pkt A4 (2026-05-13)
**Cel:** meta-reviewer dispatched automatycznie zamiast czekać aż operator pamięta o ręcznym `/review-lessons`.

## Stan przed fazą

Audyt 2026-05-13 wykazał:
- Tylko 1 dispatch meta-reviewera w całej historii (2026-04-28)
- 60 lessons dodanych w maju → 0 nowych improvement-proposals z maja
- improvement-proposals/ folder stale (13 plików z kwietnia, 0 z maja)

**Cel:** auto-dispatch co 14 dni → continuous flow proposals → continuous improvements.

---

## Setup (3 warianty)

### Wariant A (preferowany) — Claude Code Schedule skill

```bash
# Jednorazowy setup (operator uruchamia raz):
claude
# W sesji:
/schedule create agent-factory-biweekly-review \
  --cron "0 9 */14 * *" \
  --prompt "/review-lessons --since=-14d" \
  --output-dir "knowledge-base/improvement-proposals/auto-{date}.md"
```

**Plus:**
- Native Claude Code integration
- Output trafia bezpośrednio do `improvement-proposals/auto-YYYY-MM-DD.md`
- operator nie musi pamiętać — schedule fires sam

**Minus:**
- Wymaga aktywnej Claude Code sesji w momencie firingu
- Jeśli VPS śpi → schedule skip

---

### Wariant B (fallback) — Systemd timer / cron user-level

```bash
# Konfiguracja w /etc/cron.d/agent-factory-review (user-level, NIE root)
# Edytuj jako operator:
crontab -e

# Dodaj linię:
0 9 */14 * * cd ~/agent-factory && claude --prompt "/review-lessons --since=-14d" --output-file "knowledge-base/improvement-proposals/auto-$(date +%Y-%m-%d).md" 2>&1 | tee -a /tmp/agent-factory-cron.log
```

**Plus:**
- Niezależny od sesji Claude Code (fires nawet jeśli operator nie pracuje)
- Standard linux cron — niezawodny

**Minus:**
- Wymaga `claude` CLI dostępnego w cron env (PATH może być inny)
- Output do logfile — operator musi sprawdzać manualnie
- Wymaga aktywnego claude auth tokenu

---

### Wariant C (fallback najszerszy) — Manualny nag email/notification

Jeśli A i B problematyczne — utwórz minimalny systemd timer który **tylko przypomina**:

```bash
# /etc/systemd/user/agent-factory-review-nag.service
[Unit]
Description=Agent-Factory Bi-weekly Review Nag

[Service]
Type=oneshot
ExecStart=/usr/bin/notify-send -u normal "Agent-Factory" "Time for /review-lessons (last run was %u days ago)"
```

```bash
# /etc/systemd/user/agent-factory-review-nag.timer
[Unit]
Description=Run nag every 14 days

[Timer]
OnCalendar=*-*-1,15 09:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

Aktywacja:
```bash
systemctl --user enable agent-factory-review-nag.timer
systemctl --user start agent-factory-review-nag.timer
```

---

## Workflow po dispatch (manualny lub auto)

1. **Auto-dispatch fires** → meta-reviewer analizuje `lessons.jsonl` last 14d
2. **Output:** `knowledge-base/improvement-proposals/auto-YYYY-MM-DD-<N>-<topic>.md`
3. **operator review** (tygodniowy nawyk):
   - Open `improvement-proposals/` folder
   - Per proposal: accept (rename to `accepted-...`) / reject (rename `rejected-...`) / defer (zostaw)
4. **Accept → trigger version-bumper** ( B1):
   - `version-bumper --proposal=<path>` generuje proposal v1.0.X patches
   - HITL gate → architect implementuje

---

## Status implementacji

| Element | Status | Komentarz |
|---|---|---|
| Dokumentacja workflow (ten plik) | ✅  pkt A4 | 2026-05-13 |
| Setup Wariantu A (Claude Code Schedule) | ✅ KOMPLET 2026-05-13 | 3 routines created via RemoteTrigger |
| Pierwszy auto-dispatch weekly | ⏳ 2026-05-18 (poniedziałek 8:08 UTC = 10 AM PL CEST) | trig_REDACTED |
| Pierwszy auto-dispatch biweekly | ⏳ 2026-05-15 (piątek 8:01 UTC) | trig_REDACTED |
| Pierwszy auto-dispatch monthly | ⏳ 2026-06-01 (wtorek 9:02 UTC) | trig_REDACTED |

## Routines aktywne (Claude Code Schedule)

### 1. `agent-factory-weekly-self-pilot`

- **ID:** `trig_REDACTED`
- **Cron:** `0 8 * * 1` (poniedziałki 8:00 UTC = 10 AM CEST)
- **Model:** claude-sonnet-4-6
- **Repo:** LogicMorrow/agent-factory
- **Co robi:** factory-status + version-bumper proposals + pattern check + stale proposals nag + weekly health report + **`/weekly-factory-intake --dry-run`** (solution-memory intake, od 2026-06-06 Plan autonomiczne-samouczenie etap 12) → commit + push
- **Output:** `knowledge-base/self-pilot-reports/<date>-weekly.md` + `version-bumper-reports/` + `activity-log.jsonl` entry + **raport listy factory-candidate solutions** (dry-run — operator odpala `--apply` ręcznie, bramka HITL c poza cronem)
- **Next run:** 2026-05-18T08:05:38Z
- **⚠️ Wymaga aktualizacji promptu routine'u w chmurze (one-time):** dopisać step `cd agent-factory && claude --prompt "/weekly-factory-intake --dry-run"` do prompt body trig `trig_REDACTED` (przez `/web-setup` lub RemoteTrigger update). Patrz ADR-002 — dlaczego podpięcie pod istniejący cron, nie nowy.

### 2. `agent-factory-biweekly-review-lessons`

- **ID:** `trig_REDACTED`
- **Cron:** `0 8 1,15 * *` (1-szy i 15-ty każdego miesiąca 8:00 UTC)
- **Model:** claude-sonnet-4-6
- **Co robi:** meta-reviewer logic — analizuje lessons.jsonl last 14d → generuje improvement-proposals/auto-* z controlled vocabulary + severity + effort + decision flag
- **Output:** `knowledge-base/improvement-proposals/auto-<date>-*.md` (max 5 per run anti-noise)
- **Next run:** 2026-05-15T08:01:26Z

### 3. `agent-factory-monthly-intelligence`

- **ID:** `trig_REDACTED`
- **Cron:** `0 9 1 * *` (1-szy każdego miesiąca 9:00 UTC)
- **Model:** claude-sonnet-4-6
- **Co robi:** pattern-detector + recommendation-engine ( C1+C2 logic):
  - Cluster root causes z lessons + errors-*.md + reflections (min 3 occurrences)
  - Generuj `patterns/<date>-*.md`
  - Recommendation engine compute gaps + TOP 5 z effort estimates
- **Output:** `knowledge-base/patterns/` + `knowledge-base/recommendations/<date>-monthly.md`
- **Cold start protection:** SKIP jeśli <50 lessons + 0 errors-*.md
- **Next run:** 2026-06-01T09:02:40Z

## ⚠️ GitHub auth wymagane dla auto-push

**Status na 2026-05-13:** GitHub NOT connected dla `LogicMorrow/agent-factory` w Claude Code Schedule cloud.

**Konsekwencja:** routines wykonają zadania, ale **`git push` zwróci 403** — output zostaje w cloud session, NIE w repo main.

**Fix (one-time, ~2 min):**

1. Uruchom `/web-setup` w Claude Code sesji
2. Lub install Claude GitHub App: https://claude.ai/code/onboarding?magic=github-app-setup
3. App auto-discovers `LogicMorrow/agent-factory` permissions

**Workaround dopóki auth missing:**
- Routines uruchamiają się w cloud, output zostaje (możesz przeglądać przez https://claude.ai/code/routines)
- Manual `git pull` post-run wyłapuje commit-y JEŚLI auth dostępny
- Lub: temporary `enabled: false` dla 3 routines do czasu setup

## Management

**Lista routines:**
- Web UI: https://claude.ai/code/routines
- CLI (in session): `Skill schedule` → `list`

**Update routine:**
- Web UI: kliknij routine → edit
- CLI: `RemoteTrigger action=update trigger_id=<id> body={...}`

**Delete:**
- TYLKO web UI: https://claude.ai/code/routines (delete button)
- CLI nie obsługuje delete

**Disable (temporary):**
- `RemoteTrigger action=update trigger_id=<id> body={"enabled": false}`

---

## Manual fallback (do czasu wyboru wariantu)

operator może zamiast cron uruchomić manualnie raz na 2 tygodnie:

```bash
cd ~/agent-factory && claude /review-lessons --since=-14d
```

Albo dodać do `next-session.md` przypomnienie z konkretną datą next run.

---

## Update procedure tego dokumentu

- Co 6 miesięcy review — czy ścieżka manual/auto się sprawdza
- Po pierwszych 3 dispatch — review jakości proposals generowanych przez meta-reviewer
- Last review: 2026-05-13 (initial  A4)
- Next review: 2026-11-13

---

**Wersja:** 1.0.0 (initial  A4)
