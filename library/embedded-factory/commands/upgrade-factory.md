---
description: Manual pull aktualizacji embedded-factory z fabryki do projektu-konsumenta paczki af-pack-*. Źródło LOCAL (fabryka na tym samym VPS — domyślne, bez GitHuba) LUB REMOTE przez gh api (private-repo-safe, lekcja #116 — NIE raw.githubusercontent). Workflow 5 trybów (--dry-run, --backup, --apply, --validate, --rollback). Q4: NIE auto-pull (świadoma decyzja operatora).
---

Cel: aktualizacja `embedded-factory` w projekcie-konsumencie po release nowej wersji w fabryce.

## Źródło aktualizacji (`--source`)

- `--source=local:<ścieżka-fabryki>` — **preferowane gdy fabryka jest na tym samym serwerze** (np. VPS: `--source=local:~/agent-factory`). Czyta `library/embedded-factory/` bezpośrednio z dysku — bez GitHuba, bez auth, bez klasyfikatora sieci.
- `--source=gh` (**default**) — remote przez `gh api repos/LogicMorrow/agent-factory/contents/...` (działa dla PRYWATNYCH repo; wymaga `gh auth status` OK). **NIE używamy `raw.githubusercontent` — 404 dla private repo (lekcja #116).**
- `--source=<raw-url>` — legacy public raw URL (tylko gdyby fabryka była publiczna).

## Flagi (jedna na raz)

- `--dry-run` (preview, nic nie pisze) **domyślne**
- `--backup` · `--apply` · `--validate` · `--rollback=<backup-id>`

**Workflow:** `--dry-run` → review → `--backup` → `--apply` → `--validate`.

## Krok 0 — Środowisko + auto-detekcja layoutu

```bash
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Auto-detekcja LOKALNEGO manifestu — layout paczki flat-root trzyma go w
# library/embedded-factory/, starszy/założony layout w .claude/embedded-factory/.
if   [ -f "${PROJECT_DIR}/library/embedded-factory/manifest.json" ]; then
  EMBEDDED_LOCAL="${PROJECT_DIR}/library/embedded-factory"
elif [ -f "${PROJECT_DIR}/.claude/embedded-factory/manifest.json" ]; then
  EMBEDDED_LOCAL="${PROJECT_DIR}/.claude/embedded-factory"
else
  echo "📭 Brak embedded-factory w tym projekcie (manifest nie znaleziony w library/ ani .claude/). Paczka może być pre- → re-pack przez fabrykę (pack-agent v2.0+)."
  exit 0
fi
MANIFEST_LOCAL="${EMBEDDED_LOCAL}/manifest.json"
VERSION_FILE="${PROJECT_DIR}/.claude/embedded-factory-version.json"   # stamp osobno
SETTINGS="${PROJECT_DIR}/.claude/settings.json"
DEPLOY_DIR="${PROJECT_DIR}/.claude"   # deployed agents/skills/hooks/commands tu

# Resolver źródła: ustaw FETCH_MANIFEST i FETCH_FILE(embedded_path)
SRC="${SOURCE_FLAG:-gh}"
case "$SRC" in
  local:*)
    FACTORY_DIR="${SRC#local:}"
    [ ! -f "${FACTORY_DIR}/library/embedded-factory/manifest.json" ] && { echo "❌ Lokalna fabryka bez manifestu: ${FACTORY_DIR}/library/embedded-factory/manifest.json"; exit 1; }
    fetch_manifest { cat "${FACTORY_DIR}/library/embedded-factory/manifest.json"; }
    fetch_file     { cat "${FACTORY_DIR}/library/embedded-factory/$1"; }
    ;;
  gh)
    command -v gh >/dev/null || { echo "❌ gh CLI brak. Użyj --source=local:<ścieżka> jeśli fabryka jest na tym serwerze."; exit 1; }
    gh auth status >/dev/null 2>&1 || { echo "❌ gh nie zalogowany (gh auth login). Albo --source=local:<ścieżka>."; exit 1; }
    GH_REPO="LogicMorrow/agent-factory"
    fetch_manifest { gh api "repos/${GH_REPO}/contents/library/embedded-factory/manifest.json" --jq '.content' 2>/dev/null | base64 -d; }
    fetch_file     { gh api "repos/${GH_REPO}/contents/library/embedded-factory/$1" --jq '.content' 2>/dev/null | base64 -d; }
    ;;
  http*://*)
    fetch_manifest { curl -sf "${SRC%/}/library/embedded-factory/manifest.json"; }
    fetch_file     { curl -sf "${SRC%/}/library/embedded-factory/$1"; }
    ;;
  *) echo "❌ Nieznane --source=$SRC (użyj local:<path> | gh | http...)"; exit 1 ;;
esac
```

## Krok 1 — Dry-run audit (--dry-run, default)

```bash
MANIFEST_REMOTE="$(fetch_manifest)"
[ -z "$MANIFEST_REMOTE" ] && { echo "❌ Nie udało się pobrać zdalnego manifestu (źródło: $SRC). Dla private repo użyj --source=gh (gh api) lub --source=local:<ścieżka>."; exit 1; }

LOCAL_VERSION=$(jq -r '.embedded_factory_version' "$MANIFEST_LOCAL")
REMOTE_VERSION=$(echo "$MANIFEST_REMOTE" | jq -r '.embedded_factory_version')

# Lista zmienionych (hash mismatch) + NOWYCH (są w remote, brak w local).
# UWAGA jq: `($lo[]|select(...)) as $m` zabija iterację gdy brak dopasowania
# (NEW znikają!). Dlatego wrap w [ ... ]|length / |first — bezpieczne dla braku.
CHANGED=$(jq -n --argjson L "$(cat "$MANIFEST_LOCAL")" --argjson R "$MANIFEST_REMOTE" '
  ($L.agents + $L.skills + $L.hooks + $L.commands) as $lo
  | ($R.agents + $R.skills + $R.hooks + $R.commands) as $ro
  | [ $ro[] | . as $r
      | ([$lo[] | select(.name==$r.name)] | length) as $cnt
      | ([$lo[] | select(.name==$r.name) | .source_hash] | first) as $lh
      | if $cnt==0 then {name:$r.name, embedded_path:$r.embedded_path, kind:"NEW"}
        elif ($lh != $r.source_hash) then {name:$r.name, embedded_path:$r.embedded_path, kind:"CHANGED"}
        else empty end ]')
N=$(echo "$CHANGED" | jq 'length')

echo "═══ /upgrade-factory dry-run ═══"
echo "  Źródło:  $SRC"
echo "  Local:   v${LOCAL_VERSION}    Remote: v${REMOTE_VERSION}"
echo "  Zmian:   ${N}"
if [ "$N" = "0" ]; then echo "✅ Już aktualne (embedded-factory v${LOCAL_VERSION})"; exit 0; fi
echo "$CHANGED" | jq -r '.[] | "  - [\(.kind)] \(.name) → \(.embedded_path)"'
```

Wypisz podsumowanie per kategoria (Agents/Skills/Hooks/Commands), oznacz NEW vs CHANGED, ostrzeż o lokalnych customizacjach (`grep "^local_patch: true"` w deployed pliku). Zapytaj: `Proceed with --backup before --apply? [y/N]`.

> **Uwaga dot. komend factory-only:** manifest celowo NIE zawiera `/weekly-factory-intake` (działa tylko z fabryki). Upgrade nie wdraża go do projektu.

## Krok 2 — Backup (--backup)

```bash
BACKUP_ID="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_DIR="${PROJECT_DIR}/.claude/embedded-factory-backup-pre-upgrade-${BACKUP_ID}"
mkdir -p "$BACKUP_DIR"
for d in agents skills hooks commands knowledge-base; do
  cp -r "${DEPLOY_DIR}/${d}" "${BACKUP_DIR}/${d}" 2>/dev/null
done
cp -r "$EMBEDDED_LOCAL" "${BACKUP_DIR}/embedded-factory-src" 2>/dev/null
cp "$SETTINGS" "${BACKUP_DIR}/settings.json" 2>/dev/null
cp "$VERSION_FILE" "${BACKUP_DIR}/embedded-factory-version.json" 2>/dev/null
ls -dt "${PROJECT_DIR}/.claude/embedded-factory-backup-pre-upgrade-"* 2>/dev/null | tail -n +4 | xargs -r rm -rf
echo "💾 Backup: ${BACKUP_DIR} ($(du -sh "$BACKUP_DIR" | awk '{print $1}'))"
```

Po backup → `Continue with --apply? [y/N]`.

## Krok 3 — Apply (--apply)

**Pre-apply re-check:** jeśli dry-run >24h temu → re-run.

```bash
echo "$CHANGED" | jq -c '.[]' | while read -r item; do
  NAME=$(echo "$item" | jq -r '.name')
  EPATH=$(echo "$item" | jq -r '.embedded_path')   # np. hooks/stop-solution-record.sh, agents/solution-reflector.md, skills/solution-memory/SKILL.md
  EXPECTED=$(echo "$MANIFEST_REMOTE" | jq -r --arg n "$NAME" '(.agents[]?,.skills[]?,.hooks[]?,.commands[]?)|select(.name==$n)|.source_hash')

  CONTENT="$(fetch_file "$EPATH")"
  [ -z "$CONTENT" ] && { echo "⚠️  $NAME: pusta treść — skip"; continue; }
  GOT=$(printf '%s' "$CONTENT" | md5sum | awk '{print $1}')
  # Uwaga: hash w manifeście to md5 pliku zbudowanego (po sed). Local source = identyczny.
  [ "$GOT" != "$EXPECTED" ] && echo "ℹ️  $NAME: hash differ (got ${GOT:0:8} exp ${EXPECTED:0:8}) — kontynuuję (sed/EOL), weryfikuj w --validate"

  # Cel DEPLOYED = .claude/<embedded_path> (embedded_path MA już prefiks kategorii)
  DEPLOY_PATH="${DEPLOY_DIR}/${EPATH}"
  # Ochrona lokalnych patchy
  if [ -f "$DEPLOY_PATH" ] && grep -q "^local_patch: true" "$DEPLOY_PATH" 2>/dev/null && [ -z "$KEEP_LOCAL_FLAG" ]; then
    echo "⚠️  $NAME: local_patch — skip (użyj --keep-local=$NAME aby nadpisać)"; continue
  fi
  mkdir -p "$(dirname "$DEPLOY_PATH")"
  printf '%s' "$CONTENT" > "$DEPLOY_PATH"
  # Druga kopia: źródło embedded (spójność manifest+source dla przyszłych upgrade)
  SRC_PATH="${EMBEDDED_LOCAL}/${EPATH}"
  mkdir -p "$(dirname "$SRC_PATH")"
  printf '%s' "$CONTENT" > "$SRC_PATH"
  case "$EPATH" in *.sh) chmod +x "$DEPLOY_PATH" "$SRC_PATH" 2>/dev/null;; esac
  echo "✅ $NAME → ${EPATH}"
done

# Update lokalny manifest + version stamp
echo "$MANIFEST_REMOTE" > "$MANIFEST_LOCAL"
echo "$MANIFEST_REMOTE" | jq '{embedded_factory_version, manifest_md5:"recompute"}' > /dev/null  # info
```

**Merge nowych hooków do settings.json (KONKRETNIE — nie stub):** dla każdego NOWEGO hooka z manifestu zmapuj `event` (`SessionStart`/`UserPromptSubmit`/`Stop`/`PreToolUse`/`PostToolUse`) i dodaj wpis komendy, jeśli jeszcze go nie ma (preserve istniejące). Solution-memory dodaje **`Stop`** (`stop-solution-record.sh`), którego paczki sprzed 1.1.0 nie mają:

```bash
python3 - "$SETTINGS" "$MANIFEST_REMOTE" <<'PY'
import json,sys
settings_path=sys.argv[1]; manifest=json.loads(sys.argv[2])
s=json.load(open(settings_path)); s.setdefault("hooks",{})
for h in manifest.get("hooks",[]):
    ev=h.get("event"); cmd=".claude/"+h["embedded_path"]
    if not ev: continue
    arr=s["hooks"].setdefault(ev,[])
    flat=json.dumps(arr)
    if cmd in flat: continue   # już zarejestrowany — preserve
    arr.append({"matcher":"","hooks":[{"type":"command","command":cmd,"timeout":15}]})
    print(f"  + settings.json: {ev} ← {cmd}")
json.dump(s,open(settings_path,"w"),indent=2,ensure_ascii=False)
PY
```

**Scaffold knowledge-base (P0 data preservation — NIE nadpisuj istniejących):** utwórz brakujące katalogi/pliki z `manifest.scaffold` (np. `solutions/`, `solutions-index.jsonl`) tylko jeśli nie istnieją.

```bash
jq -r '.scaffold.directories[]?.path' "$MANIFEST_LOCAL" | while read -r p; do mkdir -p "${PROJECT_DIR}/${p}"; done
jq -r '.scaffold.files[]?.path' "$MANIFEST_LOCAL" | while read -r p; do [ -f "${PROJECT_DIR}/${p}" ] || : > "${PROJECT_DIR}/${p}"; done
```

## Krok 4 — Validate (--validate)

```bash
# Smoke test hooków (Stop hook na pustym stdin = exit 0 cicho)
for hook in "${DEPLOY_DIR}/hooks/"*.sh; do
  [ -f "$hook" ] || continue
  echo '{}' | bash "$hook" >/dev/null 2>&1 && echo "✅ hook OK: $(basename "$hook")" || echo "❌ hook FAIL: $(basename "$hook")"
done
# Każdy embedded_path z manifestu ma deployed plik?
jq -r '(.agents[]?,.skills[]?,.hooks[]?,.commands[]?)|.embedded_path' "$MANIFEST_LOCAL" | while read -r e; do
  [ -f "${DEPLOY_DIR}/${e}" ] && echo "✅ ${e}" || echo "❌ missing deployed: ${e}"
done
jq -e '.hooks' "$SETTINGS" >/dev/null 2>&1 && echo "✅ settings.json valid (Stop present: $(jq 'has("Stop")|.hooks.Stop!=null' "$SETTINGS" 2>/dev/null || echo "?"))" || echo "❌ settings.json invalid"
```

## Krok 5 — Rollback (--rollback=<backup-id>)

```bash
BACKUP_DIR="${PROJECT_DIR}/.claude/embedded-factory-backup-pre-upgrade-${ROLLBACK_FLAG}"
[ ! -d "$BACKUP_DIR" ] && { echo "❌ Backup nie znaleziony: ${ROLLBACK_FLAG}"; exit 1; }
SAFETY="${PROJECT_DIR}/.claude/embedded-factory-backup-rollback-$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$SAFETY"; for d in agents skills hooks commands; do cp -r "${DEPLOY_DIR}/${d}" "${SAFETY}/${d}" 2>/dev/null; done
echo "Rollback do ${ROLLBACK_FLAG}? Bieżący stan → ${SAFETY}. [y/N]"; read -r c; [ "$c" != "y" ] && exit 0
for d in agents skills hooks commands knowledge-base; do cp -r "${BACKUP_DIR}/${d}/." "${DEPLOY_DIR}/${d}/" 2>/dev/null; done
cp "${BACKUP_DIR}/settings.json" "$SETTINGS" 2>/dev/null
cp -r "${BACKUP_DIR}/embedded-factory-src/." "$EMBEDDED_LOCAL/" 2>/dev/null
cp "${BACKUP_DIR}/embedded-factory-version.json" "$VERSION_FILE" 2>/dev/null
echo "✅ Restored ${ROLLBACK_FLAG} (safety: ${SAFETY})"
```

## Activity-log

```bash
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"actor\":\"/upgrade-factory\",\"action\":\"<mode>_completed\",\"artifact\":\"library/embedded-factory/\",\"notes\":\"source=$SRC, <N> artefaktów\"}" >> "${PROJECT_DIR}/.claude/knowledge-base/activity-log.jsonl"
```

## Anti-patterns

- ❌ **`raw.githubusercontent` dla repo PRYWATNEGO** — zwraca 404. Użyj `--source=gh` (gh api) lub `--source=local:` (lekcja #116).
- ❌ NIE skip dry-run · NIE skip backup · NIE >1 major naraz · NIE w trakcie sprintu.
- ❌ NIE auto-apply `local_patch` (wymaga `--keep-local=<plik>`).
- ❌ NIE modyfikuj `.claude/knowledge-base/` treści — scaffold tylko TWORZY brakujące, nigdy nie nadpisuje.

## References

- Manifest: `library/embedded-factory/manifest.json` (layout flat-root paczki).
- Source default: `gh api repos/LogicMorrow/agent-factory/contents/library/embedded-factory/` (private-safe).
- Lekcja #116 (gh api zamiast raw dla private) + #119 (ten fix — upgrade-factory layout/source).
