#!/usr/bin/env bash
# Retrofit warstwy solution-memory do projektu-konsumenta z LOKALNEJ fabryki.
# Nieinteraktywny: backup -> apply (NEW+CHANGED) -> settings Stop merge ->
# scaffold -> validate. Idempotentny. Źródło: lokalna fabryka na VPS.
set -uo pipefail

PROJECT_DIR="${1:-$(pwd)}"
FACTORY="${2:-~/agent-factory}"
FSRC="${FACTORY}/library/embedded-factory"
DEPLOY="${PROJECT_DIR}/.claude"

# Detekcja lokalnego embedded (flat-root library/ vs .claude/)
if   [ -f "${PROJECT_DIR}/library/embedded-factory/manifest.json" ]; then EMB="${PROJECT_DIR}/library/embedded-factory"
elif [ -f "${PROJECT_DIR}/.claude/embedded-factory/manifest.json" ]; then EMB="${PROJECT_DIR}/.claude/embedded-factory"
else echo "❌ Brak embedded-factory manifestu w ${PROJECT_DIR}"; exit 1; fi
ML="${EMB}/manifest.json"
[ -f "${FSRC}/manifest.json" ] || { echo "❌ Brak fabryki: ${FSRC}/manifest.json"; exit 1; }

LV=$(jq -r '.embedded_factory_version' "$ML")
RV=$(jq -r '.embedded_factory_version' "${FSRC}/manifest.json")
echo "═══ retrofit solution-memory ═══"
echo "  Projekt: ${PROJECT_DIR}"
echo "  Fabryka: ${FACTORY}  (v${RV})    Lokalnie: v${LV}"

# Diff NEW+CHANGED (jq-safe: [...]|length/first)
DIFF=$(jq -n --argjson L "$(cat "$ML")" --argjson R "$(cat "${FSRC}/manifest.json")" '
  ($L.agents+$L.skills+$L.hooks+$L.commands) as $lo
  | ($R.agents+$R.skills+$R.hooks+$R.commands) as $ro
  | [ $ro[] | . as $r
      | ([$lo[]|select(.name==$r.name)]|length) as $c
      | ([$lo[]|select(.name==$r.name)|.source_hash]|first) as $lh
      | if $c==0 then {name:$r.name,ep:$r.embedded_path,k:"NEW"}
        elif $lh!=$r.source_hash then {name:$r.name,ep:$r.embedded_path,k:"CHANGED"}
        else empty end ]')
N=$(echo "$DIFF" | jq 'length')
echo "  Zmian: ${N}"
echo "$DIFF" | jq -r '.[]|"    [\(.k)] \(.name) → \(.ep)"'
[ "$N" = "0" ] && { echo "✅ Już aktualne — nic do zrobienia."; exit 0; }

# BACKUP
BID="$(date +%Y-%m-%d_%H-%M-%S)"
BDIR="${DEPLOY}/embedded-factory-backup-pre-upgrade-${BID}"
mkdir -p "$BDIR"
for d in agents skills hooks commands knowledge-base; do cp -r "${DEPLOY}/${d}" "${BDIR}/${d}" 2>/dev/null; done
cp -r "$EMB" "${BDIR}/embedded-factory-src" 2>/dev/null
cp "${DEPLOY}/settings.json" "${BDIR}/settings.json" 2>/dev/null
ls -dt "${DEPLOY}/embedded-factory-backup-pre-upgrade-"* 2>/dev/null | tail -n +4 | xargs -r rm -rf
echo "💾 Backup: ${BDIR}"

# APPLY — kopiuj z lokalnej fabryki do deployed .claude/<ep> ORAZ źródła embedded
echo "$DIFF" | jq -c '.[]' | while read -r it; do
  EP=$(echo "$it" | jq -r '.ep'); NM=$(echo "$it" | jq -r '.name')
  SRCF="${FSRC}/${EP}"
  [ -f "$SRCF" ] || { echo "  ⚠️  brak źródła ${EP} — skip"; continue; }
  DST="${DEPLOY}/${EP}"; SRCDST="${EMB}/${EP}"
  if [ -f "$DST" ] && grep -q "^local_patch: true" "$DST" 2>/dev/null; then echo "  ⚠️  ${NM}: local_patch — skip"; continue; fi
  mkdir -p "$(dirname "$DST")" "$(dirname "$SRCDST")"
  cp "$SRCF" "$DST"; cp "$SRCF" "$SRCDST"
  case "$EP" in *.sh) chmod +x "$DST" "$SRCDST" 2>/dev/null;; esac
  echo "  ✅ ${NM} → ${EP}"
done

# Manifest + version stamp lokalnie
cp "${FSRC}/manifest.json" "$ML"
[ -f "${DEPLOY}/embedded-factory-version.json" ] && \
  jq --arg v "$RV" '.embedded_factory_version=$v' "${DEPLOY}/embedded-factory-version.json" > /tmp/_vf.json 2>/dev/null && \
  mv /tmp/_vf.json "${DEPLOY}/embedded-factory-version.json"

# settings.json — dodaj NOWE hooki (Stop) jeśli brak, preserve istniejące
python3 - "${DEPLOY}/settings.json" "${FSRC}/manifest.json" <<'PY'
import json,sys
sp,mp=sys.argv[1],sys.argv[2]
s=json.load(open(sp)); m=json.load(open(mp)); s.setdefault("hooks",{})
for h in m.get("hooks",[]):
    ev=h.get("event"); cmd=".claude/"+h["embedded_path"]
    if not ev: continue
    arr=s["hooks"].setdefault(ev,[])
    if cmd in json.dumps(arr): continue
    arr.append({"matcher":"","hooks":[{"type":"command","command":cmd,"timeout":15}]})
    print(f"  + settings.json: {ev} ← {cmd}")
json.dump(s,open(sp,"w"),indent=2,ensure_ascii=False)
PY

# Scaffold solutions (NIE nadpisuj istniejących danych)
jq -r '.scaffold.directories[]?.path' "$ML" 2>/dev/null | while read -r p; do [ -n "$p" ] && mkdir -p "${PROJECT_DIR}/${p}"; done
jq -r '.scaffold.files[]?.path' "$ML" 2>/dev/null | while read -r p; do [ -n "$p" ] && { [ -f "${PROJECT_DIR}/${p}" ] || : > "${PROJECT_DIR}/${p}"; }; done

# VALIDATE
echo "─── validate ───"
FAIL=0
for hook in "${DEPLOY}/hooks/"*.sh; do [ -f "$hook" ] || continue; echo '{}' | bash "$hook" >/dev/null 2>&1 || { echo "  ❌ hook FAIL: $(basename "$hook")"; FAIL=$((FAIL+1)); }; done
jq -r '(.agents[]?,.skills[]?,.hooks[]?,.commands[]?)|.embedded_path' "$ML" | while read -r e; do [ -f "${DEPLOY}/${e}" ] || echo "  ❌ missing: ${e}"; done
if jq -e '.hooks' "${DEPLOY}/settings.json" >/dev/null 2>&1; then
  STOP_OK=$(jq -r '.hooks | has("Stop")' "${DEPLOY}/settings.json" 2>/dev/null)
  echo "  ✅ settings.json valid; Stop hook zarejestrowany: ${STOP_OK}"
else echo "  ❌ settings.json invalid"; FAIL=$((FAIL+1)); fi
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"actor\":\"retrofit-solution-memory\",\"action\":\"apply_completed\",\"artifact\":\"library/embedded-factory/\",\"notes\":\"source=local ${FACTORY}, ${N} artefaktow, backup ${BID}\"}" >> "${DEPLOY}/knowledge-base/activity-log.jsonl" 2>/dev/null
[ "$FAIL" = "0" ] && echo "✅ Retrofit OK (${N} artefaktów). RESTART sesji apki — SessionStart + Stop hook ładują się przy starcie." || echo "⚠️  Retrofit z ${FAIL} ostrzeżeniami — sprawdź wyżej. Backup: ${BDIR}"
