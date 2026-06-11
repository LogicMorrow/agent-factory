---
description: Tygodniowy batch-intake rozwiązań solution-memory z projektów do fabryki. Skanuje solutions-index.jsonl projektów (fabryka self + ~/projekty/* + opcjonalnie af-pack-* repos), zbiera wpisy scope=factory-candidate & promoted_to_factory=false, prezentuje listę, BRAMKA HITL (c) — operator zatwierdza, promuje zatwierdzone → candidate-lessons fabryki z origin. Podpięte pod weekly cron agent-factory-weekly-self-pilot (pon 10:00). Druga oś learning-loopu (vs /pull-promoted-lessons dla conversation-learning).
---

Cel: **federacja ROZWIĄZAŃ (solution-memory) z projektów do fabryki** — druga oś obok `/pull-promoted-lessons` (która federuje lessons z conversation-learning). Warstwa projektu zapisuje rozwiązania autonomicznie (bez bramki); TA komenda jest BRAMKĄ HITL (c) przed wejściem reużywalnych rozwiązań do fabryki.

Granica: solution-memory = co projekt ZROBIŁ (rozwiązany problem). Tylko `scope: factory-candidate` (generalizowalne) trafia do intake — `project-local` zostaje lokalnie. Patrz `library/skills/universal/solution-memory/SKILL.md` + ADR-001.

## Flagi

- `--dry-run` — preview listy bez pisania (gdy uruchamiane przez cron lub do podglądu). **Domyślne.**
- `--apply` — po zatwierdzeniu HITL pisz do `knowledge-base/candidate-lessons.jsonl` fabryki + oznacz źródła `promoted_to_factory: true`.
- `--sources=<CSV>` — nadpisz ścieżki skanu. Default: `knowledge-base/solutions-index.jsonl` (fabryka self) + `~/projekty/*/.claude/knowledge-base/solutions-index.jsonl`.
- `--repos=<CSV>` — dodatkowo skanuj remote af-pack-* repos przez `gh api` (jak `/pull-promoted-lessons`; analog dla rozwiązań poza VPS). Default: brak (tylko lokalne źródła).
- `--since=<YYYY-MM-DD>` — tylko solutions z `ts` po dacie. Default: 7 dni temu (okno tygodniowe).
- `--project=<slug>` — ogranicz do jednego projektu.

## Krok 0 — Verify środowisko

```bash
PROJECT_DIR="$(pwd)"
if [ "$(basename "$PROJECT_DIR")" != "agent-factory" ]; then
  echo "❌ /weekly-factory-intake musi działać z agent-factory (centralna fabryka)"; exit 1
fi
SINCE="${SINCE:-$(date -u -d '7 days ago' +%Y-%m-%d 2>/dev/null || date -u -v-7d +%Y-%m-%d)}"
```

## Krok 1 — Discover źródła + zbierz factory-candidate

Zbierz wszystkie linie z `solutions-index.jsonl` ze źródeł, gdzie `scope == "factory-candidate"` AND `promoted_to_factory == false` AND `ts >= SINCE`. Zachowaj informację o ścieżce źródła (do późniejszego oznaczenia + nadania `origin`).

```bash
# Domyślne źródła: fabryka self + lokalne projekty
SOURCES=$(ls knowledge-base/solutions-index.jsonl ~/projekty/*/.claude/knowledge-base/solutions-index.jsonl 2>/dev/null)
TMP_COLLECT="$(mktemp)"
for SRC in $SOURCES; do
  [ -s "$SRC" ] || continue
  # origin: 'agent-factory' dla self, inaczej slug projektu z ścieżki
  case "$SRC" in
    knowledge-base/*) ORIGIN="agent-factory" ;;
    *) ORIGIN="$(echo "$SRC" | sed -E 's#.*/projekty/([^/]+)/.*#\1#')" ;;
  esac
  jq -c --arg origin "$ORIGIN" --arg since "$SINCE" --arg src "$SRC" '
    select(.scope == "factory-candidate")
    | select((.promoted_to_factory // false) == false)
    | select((.ts // "0") >= ($since + "T00:00:00Z"))
    | . + {_origin: $origin, _src: $src}' "$SRC" 2>/dev/null >> "$TMP_COLLECT"
done
COUNT=$(wc -l < "$TMP_COLLECT" | tr -d ' ')
echo "Znaleziono $COUNT factory-candidate solutions (od $SINCE)."
```

(Jeśli `--repos=<CSV>`: dodatkowo dla każdego repo `gh api repos/LogicMorrow/<repo>/contents/.claude/knowledge-base/solutions-index.jsonl` — base64 decode, ten sam filtr. Mirror logiki `/pull-promoted-lessons` Krok 1 dla prywatnych repo przez `gh api` zamiast `curl raw`.)

## Krok 2 — Prezentuj listę (BRAMKA HITL c)

Dla każdego zebranego rozwiązania pokaż operatorowi **zwięzłą kartę** (NIE całe md):

```
[N] <title>
    projekt(origin): <_origin>   scope: factory-candidate   reusability: <reusability>
    problem: <problem (1 linia)>
    rozwiązanie: <solution_summary (1 linia)>
    dead_ends: <dead_ends[0..2] skrót>
    md: <_src dir>/solutions/<id>.md
```

Następnie **ZATRZYMAJ SIĘ i zapytaj operatora** (AskUserQuestion lub lista do odhaczenia): które rozwiązania promować do fabryki. To jest bramka HITL (c) — **NIE promuj nic bez explicit akceptacji**. Domyślna rekomendacja: promuj te z `reusability: high` + niepustym `dead_ends`; do rozważenia te z `med`. Odrzuć duplikaty istniejących lessons (sprawdź `knowledge-base/lessons.jsonl` po podobnym tytule/tagach).

W trybie `--dry-run` (default): zakończ po prezentacji listy + rekomendacji. NIE pisz nic. (Cron uruchamia dry-run → raport; operator odpala `--apply` ręcznie po przeglądzie.)

## Krok 3 — Promocja zatwierdzonych (tylko `--apply` + po akceptacji)

Dla każdego ZATWIERDZONEGO rozwiązania zbuduj wpis candidate-lessons fabryki (schema `candidate-lessons-schema.json`) i dopisz do `knowledge-base/candidate-lessons.jsonl`:

```bash
# Per zatwierdzone (przykład budowy linii — pętla po wybranych indeksach)
TS_NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
jq -c -n \
  --arg ts "$TS_NOW" \
  --arg origin "$ORIGIN" \
  --arg lesson "$SOLUTION_SUMMARY (problem: $PROBLEM)" \
  '{schema_version:1, ts:$ts, origin:("solution-intake:" + $origin),
    pattern:"surprise", user_prompt_snippet:null, context_window_hint:null,
    candidate_lesson:$lesson, severity:"medium", confidence_hits:1,
    secondary_patterns:[], scope:"factory-candidate",
    promoted_to_factory:false, hitl_approved:null, session_id:null}' \
  >> knowledge-base/candidate-lessons.jsonl
```

Uwagi:
- `origin: "solution-intake:<projekt>"` — odróżnia od conversation-learning capture (`conversation-learning-hook`).
- `hitl_approved: null` — wpada do normalnego pipeline'u `/review-candidate-lessons` → `lessons.jsonl` (DRUGA brama dla treści lekcji; intake to brama dla SELEKCJI rozwiązań).
- `scope: factory-candidate` — zgodne z lekcją #118.

Oznacz źródła jako promowane (idempotencja — nie promuj dwa razy):

```bash
# W source solutions-index.jsonl ustaw promoted_to_factory=true + promoted_at dla promowanych id
jq -c --arg id "$SOL_ID" --arg now "$TS_NOW" '
  if .id == $id then . + {promoted_to_factory:true, promoted_at:$now} else . end' \
  "$SRC" > "$SRC.tmp" && mv "$SRC.tmp" "$SRC"
```

## Krok 4 — Activity-log

```bash
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"actor\":\"weekly-factory-intake\",\"action\":\"solution_promoted\",\"artifact\":\"knowledge-base/candidate-lessons.jsonl\",\"notes\":\"<N> rozwiazan promowanych z <projekty>; HITL approved\"}" \
  >> knowledge-base/activity-log.jsonl
```

## Krok 5 — Raport

Podsumuj: ile zebrano, ile zatwierdzono, ile promowano, z jakich projektów. Wskaż następny krok: `/review-candidate-lessons` (wzbogać treść lekcji + finalna promocja do `lessons.jsonl`).

## Integracja z cron

Wpięte w `agent-factory-weekly-self-pilot` (pon 10:00 CEST) jako step `--dry-run` — generuje raport listy factory-candidate. operator przegląda raport i odpala `--apply` ręcznie (bramka HITL c świadomie poza cronem — cron tylko ZBIERA i RAPORTUJE, nie promuje autonomicznie). Patrz `.claude/automation/review-lessons-schedule.md` + ADR-002.

## Czego komenda NIE robi

- NIE promuje bez akceptacji operatora (HITL c twardy).
- NIE dotyka `project-local` solutions (zostają lokalnie).
- NIE wzbogaca treści lekcji — to `/review-candidate-lessons` (osobna brama).
- NIE federuje conversation-learning candidate-lessons — to `/pull-promoted-lessons` (siostrzana oś).
