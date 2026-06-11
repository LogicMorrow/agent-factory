---
spec_id: pack-agent-v2.0-design
title: Pack-agent v2.0 — design dla S9 implementation (Krok N+1 embedded-factory auto-include)
date: 2026-05-24
author: agent-architect (auto-mode for operator)
phase: 10B.E8 (architecture deliverable, S9 implements)
status: ready_for_implementation
references:
  - knowledge-base/docs/embedded-factory/adr/012-pack-agent-krok-n-plus-1.md
  - .claude/agents/pack-agent.md (v1.x source)
  - library/embedded-factory/manifest.json
  - library/embedded-factory/build.sh
---

# Pack-agent v2.0 — design document (dla S9 implementation)

## Cel

Spec dla S9: konkretna lista edycji w `.claude/agents/pack-agent.md` żeby przejść z v1.x (202l, 10 kroków workflow, statyczne snapshoty) → v2.0.0 (~330l, 11 kroków workflow z Krok 7.5 a-f, paczki ze embedded-factory).

**Cel NIE-w-zakresie:** pełny tekst patched pack-agent.md. Ten dokument to **specification dla S9**, pseudo-kod + diff annotations + smoke test plan. S9 implementuje konkretne kroki.

## Diff pack-agent v1.x → v2.0.0 (overview)

### Frontmatter

```diff
 ---
 name: pack-agent
-description: Przygotowuje paczkę agentów/skilli z biblioteki dopasowaną do opisanego projektu, tworzy folder `packages/<nazwa>/` i pushuje na `LogicMorrow/af-pack-<nazwa>`. Uruchamiaj przez komendę `/pack`. Nie wywołuj bezpośrednio do tworzenia agentów.
+description: "v2.0+ auto-includes library/embedded-factory/ (mini-fabryka samouczenia się) w każdej paczce — zasada #14 CLAUDE.md. Przygotowuje paczkę agentów/skilli z biblioteki dopasowaną do opisanego projektu, tworzy folder `packages/<nazwa>/` i pushuje na `LogicMorrow/af-pack-<nazwa>`. Uruchamiaj przez komendę `/pack`. Nie wywołuj bezpośrednio do tworzenia agentów."
 tools: Read, Write, Bash, Glob
 model: sonnet
+version: "2.0.0"
 ---
```

**Zmiany:**
- `description` rozszerzony o explicit v2.0 nota (rozpoznawalne dla `/agents` listing).
- `version: "2.0.0"` NEW — MAJOR bump z implicit v1.x. Frontmatter zgodny z #12 quality gates (frontmatter MUSI mieć version).
- `tools`: BEZ ZMIAN (Read, Write, Bash, Glob — wszystko już jest dla nowego workflow).
- `model`: BEZ ZMIAN (sonnet — wystarczająco do bash/jq/markdown, nie potrzebujemy opus).

### Workflow — wstawienie Krok 7.5 (Krok N+1)

**Lokalizacja insertu:** MIĘDZY Krok 7 (`Wygeneruj packages/<nazwa>/README.md`) a Krok 8 (`Utwórz repo na GitHub`).

**Powód lokalizacji:**
- Krok 6b real-test gate (BLOKER) odpala się PRZED Krok 7.5 — operator HITL approval dotyczy istniejących agentów (Krok 4-6). Embedded-factory nie wymaga HITL bo to deterministyczna kopia z fabryki (parity check + version stamp dają audytowalność).
- Krok 7.5 PRZED Krok 8 = fail-fast przed `gh repo create`. Jeśli parity FAIL = nie tworzymy repo na GitHub (no cleanup needed).
- Krok 7 README MUSI być wygenerowany PRZED Krok 7.5 bo Krok 7.5 dorzuca embedded-factory entries do README (lub Krok 7 jest rozszerzony o embedded-factory sekcję — decyzja S9).

**S9 decyzja sub-pytanie:** Czy Krok 7 README enumeruje embedded artefakty (tabela agentów + tabela skilli)?
- **Zalecane:** YES — README musi pokazywać że paczka MA embedded-factory (transparent dla użytkownika).
- **Implementacja S9:** Krok 7 generuje README z section "Embedded-factory artifacts" przed footer. Listing pobierany z `library/embedded-factory/manifest.json` przez jq.

### Nowy Krok 7.5: "Krok N+1 — auto-include embedded-factory"

**Pseudo-tekst dla S9 (insert do pack-agent.md):**

```markdown
7.5. **Auto-include embedded-factory (Krok N+1, , zasada #14)** — wkleja mini-fabrykę samouczenia się do paczki. **BLOKER przed Krok 8 (push).**

   7.5a **Verify embedded-factory build (pre-flight)**:
   ```bash
   bash library/embedded-factory/build.sh --check 2>&1 | tee /tmp/embedded-check-<nazwa>.log
   PARITY_EXIT=${PIPESTATUS[0]}
   if [ "$PARITY_EXIT" != "0" ]; then
     echo "❌ BLOCKER Krok 7.5a: library/embedded-factory/ out-of-sync z source."
     echo "Run: bash library/embedded-factory/build.sh"
     echo "Potem ponownie /pack."
     exit 2
   fi
   echo "✅ 7.5a: embedded-factory parity check PASS"
   ```

   7.5b **Copy embedded artefakty (z collision detection)** — patrz funkcja `copy_embedded_with_collision_check` poniżej.

   7.5c **Merge settings.json (idempotent, preserve user hooks)** — patrz `merge_settings_json` poniżej.

   7.5d **Init scaffold (preserve istniejące dane)** — patrz `init_scaffold_preserve` poniżej.

   7.5e **Parity check per artefakt (post-copy MD5 vs manifest.source_hash)** — patrz `parity_check_per_artifact` poniżej.

   7.5f **Embedded-factory version stamp** — `.claude/embedded-factory-version.json` z {version, source_factory_version, generated_at, manifest_md5, pack_agent_version}.

   **Pełna spec sub-kroków a-f w:** `library/embedded-factory/LITE-SPECS/pack-agent-v2.0-design.md` sekcje "Krok 7.5a-f pseudo-code".

   **Anti-patterns guard (Krok 7.5b):**
   - Recursive packaging: `pack-agent.md` NIE może być w embedded artefaktach. Explicit exit 2 jeśli `library/embedded-factory/agents/pack-agent.md` exists.
   - Settings.json overwrite: jq merge, NIE `cp`.
   - Scaffold pollution: per-file `[ ! -f ] && cp`, NIE overwrite existing lessons.jsonl z N entries.
   - Silent collision: MD5 compare + warning + log do `/tmp/embedded-collisions-<nazwa>.txt`.
```

### Sekcja "Zasady jakości" — patches

```diff
+- **Embedded-factory ZAWSZE w paczce (zasada #14 CLAUDE.md fabryki).** Krok 7.5 BLOKER przed push. Brak embedded = paczka unfit for distribution.
+- **Settings.json MERGE, nigdy REPLACE.** Krok 7.5c używa jq idempotent merge. User customizations preserved.
+- **Recursive packaging anti-pattern.** Krok 7.5b explicit exclude pack-agent.md (factory-only). Brief 10B sekcja 12 Q1 invariant.
+- **Pre-flight `build.sh --check` PASS = warunek konieczny.** Bez świeżego build = ABORT przed push.
+- **Collision preserve user customizations.** Krok 7.5b MD5 compare detects user-modified embedded agents. Domyślnie: preserve user + warning. Reconcile via `/upgrade-factory --merge` w paczce (ADR 013).
```

### Sekcja "Format outputu" — patches

```diff
 1. Tabela wybranych agentów: nazwa | model | token_cost | uzasadnienie wyboru.
 2. Lista skilli w paczce.
+   **Embedded skille (auto-included, ):** conversation-learning, cross-agent-learning, error-memory-framework, model-routing.
 3. URL nowego repo: `git@github.com:LogicMorrow/af-pack-<nazwa>.git`
 4. Komenda instalacyjna: `git clone git@github.com:LogicMorrow/af-pack-<nazwa> .claude/`
 5. Pytanie: "Chcesz od razu sklonować tę paczkę do istniejącego projektu?"
+6. **Embedded-factory summary :** 7 agentów (opus×3, sonnet×3, haiku×1) + 4 skille + 3 hooki + 3 slash commands. Version: <embedded_factory_version z manifest.json>. Stamp: `.claude/embedded-factory-version.json` (manifest_md5: <hash>).
+7. **Collisions report (jeśli były):** lista plików gdzie user customization została preserved zamiast embedded version. Akcja: `/upgrade-factory --merge` w paczce dla reconcile.
```

### Sekcja "Czego NIE robisz" — patches

```diff
 - **Nie tworzysz nowych agentów** — pakujesz tylko to co istnieje w `library/`. Jeśli brak odpowiedniego → powiedz użytkownikowi i zasugeruj `/new-agent`.
 - **Nie modyfikujesz agentów z biblioteki** — paczka to kopia, nie fork.
 - **Nie tworzysz projektów w `~/projekty/`** → `project-bootstrap`.
 - **Nie analizujesz lessons.jsonl** → `meta-reviewer`.
+- **Nie kopiujesz pack-agent.md do embedded-factory** — recursive packaging anti-pattern (paczki nie tworzą paczek). Krok 7.5b explicit guard.
+- **Nie nadpisujesz user customizations** — Krok 7.5b collision detection + preserve. Reconcile manual przez `/upgrade-factory --merge`.
+- **Nie uruchamiasz `build.sh` automatycznie** — to manual operation operatora (deferred sync z ADR 009). Pack-agent tylko `build.sh --check` (read-only).
```

### Activity-log entry — patches

```diff
 ```bash
 echo '{"ts":"'$(date -Iseconds)'","actor":"pack-agent","action":"package_pushed","artifact":"packages/<nazwa>/","notes":"repo=af-pack-<nazwa>, agenci=<N>, skille=<M>"}' \
   >> ~/agent-factory/knowledge-base/activity-log.jsonl
 ```
+
+**Dla v2.0+ — embedded-factory metadata w notes:**
+```bash
+EF_VER=$(jq -r '.embedded_factory_version' packages/<nazwa>/.claude/embedded-factory-version.json)
+COLLISIONS=$(wc -l < /tmp/embedded-collisions-<nazwa>.txt 2>/dev/null || echo 0)
+echo '{"ts":"'$(date -Iseconds)'","actor":"pack-agent","action":"package_pushed","artifact":"packages/<nazwa>/","notes":"repo=af-pack-<nazwa>, agenci=<N>, skille=<M>, embedded_factory_version='$EF_VER', collisions='$COLLISIONS', pack_agent_version=2.0.0"}' \
+  >> ~/agent-factory/knowledge-base/activity-log.jsonl
+```
```

## Krok 7.5a-f pseudo-code (S9 implementuje)

### Krok 7.5a: `verify_embedded_build`

```bash
verify_embedded_build {
  local check_log
  check_log=$(mktemp -t embedded-check-XXXXXX.log)
  trap 'rm -f "$check_log"' RETURN

  if ! bash library/embedded-factory/build.sh --check >"$check_log" 2>&1; then
    cat "$check_log" >&2
    echo "" >&2
    echo "❌ BLOCKER Krok 7.5a: library/embedded-factory/ out-of-sync z source." >&2
    echo "Akcja:" >&2
    echo "  1. bash library/embedded-factory/build.sh" >&2
    echo "  2. git diff library/embedded-factory/  # review zmian" >&2
    echo "  3. git add library/embedded-factory/ && git commit" >&2
    echo "  4. /pack <nazwa> <opis>  # ponownie" >&2
    return 2
  fi

  echo "✅ Krok 7.5a: embedded-factory parity check PASS" >&2
  return 0
}
```

**Wywołanie:** `verify_embedded_build || exit 2`

### Krok 7.5b: `copy_embedded_with_collision_check`

```bash
copy_embedded_with_collision_check {
  local package_name="$1"
  local embedded=library/embedded-factory
  local package=packages/$package_name/.claude
  local collisions_log
  collisions_log=$(mktemp -t embedded-collisions-XXXXXX.txt)
  # Note: collisions_log NIE cleanup — używamy w Krok 7.5e jako skip list

  echo "" >&2
  echo "▶ Krok 7.5b: copy embedded artefakty → packages/$package_name/.claude/" >&2

  for cat in agents skills hooks commands; do
    [ ! -d "$embedded/$cat" ] && continue

    for src in "$embedded/$cat"/*; do
      [ ! -e "$src" ] && continue   # empty glob

      local name
      name=$(basename "$src")

      # Anti-pattern guard: recursive packaging
      if [ "$name" = "pack-agent.md" ]; then
        echo "❌ BLOCKER Krok 7.5b: pack-agent.md detected w $src — recursive packaging anti-pattern." >&2
        echo "Embedded-factory NIE może zawierać pack-agent (factory-only)." >&2
        return 2
      fi

      local dst="$package/$cat/$name"

      # Collision detection
      if [ -e "$dst" ]; then
        local src_md5 dst_md5
        src_md5=$(md5sum "$src" 2>/dev/null | awk '{print $1}')
        dst_md5=$(md5sum "$dst" 2>/dev/null | awk '{print $1}')

        if [ "$src_md5" = "$dst_md5" ]; then
          echo "  ↻ skip $cat/$name (identyczny MD5)" >&2
        else
          echo "  ⚠️  PRESERVED $cat/$name (user customization, embedded NIE nadpisał)" >&2
          echo "$cat/$name" >> "$collisions_log"
        fi
        continue
      fi

      # No collision — copy
      mkdir -p "$package/$cat"
      if [ -d "$src" ]; then
        cp -r "$src" "$dst"
      else
        cp "$src" "$dst"
      fi
      echo "  + $cat/$name" >&2
    done
  done

  # Hooki MUSZĄ być executable
  chmod +x "$package/hooks/"*.sh 2>/dev/null || true

  echo "✅ Krok 7.5b: copy complete" >&2

  if [ -s "$collisions_log" ]; then
    echo "" >&2
    echo "ℹ️  Collisions zachowane (count: $(wc -l < "$collisions_log"))" >&2
    echo "    Lista: $collisions_log" >&2
    echo "    Reconcile: /upgrade-factory --merge w paczce" >&2
  fi

  # Export collisions_log path dla Krok 7.5e
  echo "$collisions_log"
  return 0
}
```

### Krok 7.5c: `merge_settings_json`

```bash
merge_settings_json {
  local package_name="$1"
  local settings=packages/$package_name/.claude/settings.json
  local manifest=library/embedded-factory/manifest.json

  echo "" >&2
  echo "▶ Krok 7.5c: merge settings.json (idempotent, preserve user hooks)" >&2

  # Init jeśli brak
  if [ ! -f "$settings" ]; then
    echo '{"hooks": {}}' > "$settings"
    echo "  + initialized empty settings.json" >&2
  fi

  # Per hook z manifest.hooks[]
  local added=0
  local skipped=0

  while IFS=$'\t' read -r hook_name event; do
    [ -z "$hook_name" ] && continue
    local command=".claude/hooks/$hook_name"

    # Check idempotency: czy command już istnieje w hooks[event]
    local exists
    exists=$(jq --arg ev "$event" --arg cmd "$command" '
      [.hooks[$ev]?[]?.hooks[]?.command] | index($cmd) // empty
    ' "$settings")

    if [ -n "$exists" ]; then
      echo "  ↻ skip $event:$hook_name (already in settings.json)" >&2
      skipped=$((skipped + 1))
      continue
    fi

    # Append jako NEW matcher group (matcher: "*")
    local tmp
    tmp=$(mktemp)
    jq --arg ev "$event" --arg cmd "$command" '
      .hooks //= {}
      | .hooks[$ev] //= []
      | .hooks[$ev] += [{"matcher": "*", "hooks": [{"type": "command", "command": $cmd}]}]
    ' "$settings" > "$tmp" && mv "$tmp" "$settings"

    echo "  + added $event:$hook_name" >&2
    added=$((added + 1))
  done < <(jq -r '
    .hooks[]?
    | [.name, .event]
    | @tsv
  ' "$manifest")

  echo "✅ Krok 7.5c: merge complete (added: $added, skipped: $skipped — idempotent)" >&2
  return 0
}
```

**Idempotency invariant:** ponowny run NIE dodaje duplicates (sprawdzane przez `index($cmd)` w jq).

**Multi-matcher edge case:** jeśli paczka ma SessionStart hook z `matcher: "git"` (specific), embedded dodaje jako KOLEJNY matcher group z `matcher: "*"`. Oba działają niezależnie (matcher-based dispatch w Claude Code).

### Krok 7.5d: `init_scaffold_preserve`

```bash
init_scaffold_preserve {
  local package_name="$1"
  local scaffold_src=library/embedded-factory/scaffold/.claude
  local kb=packages/$package_name/.claude/knowledge-base
  local memory=packages/$package_name/.claude/memory

  echo "" >&2
  echo "▶ Krok 7.5d: init scaffold (preserve existing data)" >&2

  mkdir -p "$kb/reflections" "$kb/errors" "$memory"

  # Per-file: init tylko jeśli brak
  for file in lessons.jsonl candidate-lessons.jsonl activity-log.jsonl; do
    local target="$kb/$file"
    if [ ! -f "$target" ]; then
      if [ -f "$scaffold_src/knowledge-base/$file" ]; then
        cp "$scaffold_src/knowledge-base/$file" "$target"
      else
        touch "$target"
      fi
      echo "  + scaffold $file (empty init)" >&2
    else
      local size
      size=$(wc -l < "$target")
      echo "  ↻ preserve $file ($size lines, NIE init)" >&2
    fi
  done

  # .gitkeep tylko dla empty dirs
  for dir in "$kb/reflections" "$kb/errors" "$memory"; do
    if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
      touch "$dir/.gitkeep"
    fi
  done

  echo "✅ Krok 7.5d: scaffold initialized (preserved existing data)" >&2
  return 0
}
```

**Re-pack invariant:** paczka z 50-entry lessons.jsonl NIE traci danych. Tylko brakujące pliki są tworzone.

### Krok 7.5e: `parity_check_per_artifact`

```bash
parity_check_per_artifact {
  local package_name="$1"
  local collisions_log="$2"   # z Krok 7.5b
  local manifest=library/embedded-factory/manifest.json
  local package=packages/$package_name/.claude
  local fail=0

  echo "" >&2
  echo "▶ Krok 7.5e: parity check per artefakt" >&2

  while IFS=$'\t' read -r embedded_path expected_hash; do
    [ -z "$embedded_path" ] || [ "$expected_hash" = "null" ] && continue

    # Skip jeśli plik był collision (user customization preserved)
    if [ -f "$collisions_log" ] && grep -qx "$embedded_path" "$collisions_log"; then
      echo "  ↻ skip parity $embedded_path (user customization preserved)" >&2
      continue
    fi

    local package_file="$package/$embedded_path"
    if [ ! -f "$package_file" ]; then
      echo "  ❌ PARITY FAIL: $embedded_path missing w paczce" >&2
      fail=1
      continue
    fi

    local actual_hash
    actual_hash=$(md5sum "$package_file" | awk '{print $1}')
    if [ "$actual_hash" != "$expected_hash" ]; then
      echo "  ❌ PARITY FAIL: $embedded_path (expected=${expected_hash:0:8} actual=${actual_hash:0:8})" >&2
      fail=1
    else
      echo "  ✓ $embedded_path" >&2
    fi
  done < <(jq -r '
    (.agents[]?, .skills[]?, .hooks[]?, .commands[]?)
    | [.embedded_path, (.source_hash // "null")]
    | @tsv
  ' "$manifest")

  if [ "$fail" != "0" ]; then
    echo "" >&2
    echo "❌ BLOCKER Krok 7.5e: parity check failed — paczka uszkodzona." >&2
    echo "Akcje:" >&2
    echo "  1. bash library/embedded-factory/build.sh   # rebuild source_hash" >&2
    echo "  2. rm -rf packages/$package_name/            # clean re-pack" >&2
    echo "  3. /pack $package_name <opis>                # re-run" >&2
    return 2
  fi

  echo "✅ Krok 7.5e: parity check PASS (all artifacts MD5 match manifest)" >&2
  return 0
}
```

### Krok 7.5f: `write_version_stamp`

```bash
write_version_stamp {
  local package_name="$1"
  local stamp=packages/$package_name/.claude/embedded-factory-version.json
  local manifest=library/embedded-factory/manifest.json
  local pack_agent_md=.claude/agents/pack-agent.md

  local ef_ver source_factory now manifest_md5 pack_ver
  ef_ver=$(jq -r '.embedded_factory_version' "$manifest")
  source_factory=$(jq -r '.generator_factory_version' "$manifest")
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  manifest_md5=$(md5sum "$manifest" | awk '{print $1}')
  pack_ver=$(grep '^version:' "$pack_agent_md" | head -1 | awk -F'"' '{print $2}')
  [ -z "$pack_ver" ] && pack_ver="2.0.0"   # fallback

  cat > "$stamp" <<EOF
{
  "schema_version": 1,
  "embedded_factory_version": "$ef_ver",
  "source_factory_version": "$source_factory",
  "generated_at": "$now",
  "manifest_md5": "$manifest_md5",
  "pack_agent_version": "$pack_ver",
  "package_name": "af-pack-$package_name"
}
EOF

  echo "✅ Krok 7.5f: version stamp written → $stamp" >&2
  echo "    embedded_factory_version: $ef_ver" >&2
  echo "    source_factory_version: $source_factory" >&2
  echo "    pack_agent_version: $pack_ver" >&2
  return 0
}
```

## Settings.json merge logic — detail

### Edge case 1: paczka brak settings.json

**Input:** brak `packages/<nazwa>/.claude/settings.json`
**Action:** init `{"hooks": {}}`, potem merge 3 embedded hooków.
**Output:**
```json
{
  "hooks": {
    "SessionStart": [{"matcher":"*","hooks":[{"type":"command","command":".claude/hooks/session-start-embedded.sh"}]}],
    "UserPromptSubmit": [{"matcher":"*","hooks":[{"type":"command","command":".claude/hooks/userPromptSubmit-conversation-learning.sh"}]}],
    "PostToolUse": [{"matcher":"*","hooks":[{"type":"command","command":".claude/hooks/on-error-record.sh"}]}]
  }
}
```

### Edge case 2: paczka ma istniejące hooki (CRM scenariusz)

**Input:**
```json
{
  "hooks": {
    "SessionStart": [{"matcher":"*","hooks":[{"type":"command","command":".claude/hooks/session-start-multi-plan.sh"}]}],
    "PreToolUse": [{"matcher":"Bash","hooks":[{"type":"command","command":".claude/hooks/block-env-leak.sh"}]}]
  }
}
```

**Action:** merge 3 embedded. SessionStart już istnieje (multi-plan) → embedded session-start-embedded jako NEW matcher group. PreToolUse nietknięty.

**Output:**
```json
{
  "hooks": {
    "SessionStart": [
      {"matcher":"*","hooks":[{"type":"command","command":".claude/hooks/session-start-multi-plan.sh"}]},
      {"matcher":"*","hooks":[{"type":"command","command":".claude/hooks/session-start-embedded.sh"}]}
    ],
    "PreToolUse": [{"matcher":"Bash","hooks":[{"type":"command","command":".claude/hooks/block-env-leak.sh"}]}],
    "UserPromptSubmit": [{"matcher":"*","hooks":[{"type":"command","command":".claude/hooks/userPromptSubmit-conversation-learning.sh"}]}],
    "PostToolUse": [{"matcher":"*","hooks":[{"type":"command","command":".claude/hooks/on-error-record.sh"}]}]
  }
}
```

**Decyzja design:** kolejność matcher groups w tablicy = kolejność wykonania hooków (FIFO). Embedded hooks dodawane na końcu (lower priority niż user hooks). User control: jeśli kolejność musi być inna, manual edit settings.json po re-pack.

### Edge case 3: idempotent re-run

**Input (po pierwszym packu):** settings.json z 3 embedded hooks + 4 user hooks (CRM scenariusz).
**Action:** drugi run merge. Per hook: check `index($cmd)` → already exists → skip.
**Output:** identyczne settings.json. Brak duplicates.

### Edge case 4: user customized hook command path

**Input:** user zmienił command z `.claude/hooks/session-start-embedded.sh` na `.claude/hooks/my-custom-session-start.sh` (zachowując nazwę pliku embedded, ale wskazując inny script).
**Action:** `index($cmd)` szuka exact `.claude/hooks/session-start-embedded.sh` → nie znajduje → DODAJE embedded jako NEW entry. User customization zachowane jako kolejny entry.
**Output:** settings.json ma BOTH (custom + embedded). User decyduje który zostawić (manual edit).

**Decyzja design:** brak smart-detection custom vs embedded. Treat każdy command path jako unique key. User accepts że re-pack może dodać "duplikat funkcjonalnie" — manual cleanup w UPGRADE.md jako procedura.

## Smoke test plan dla S9

### Test 1: Re-pack af-pack-<nazwa> (backwards compat scenario)

**Setup:**
```bash
# Założenie: packages/af-pack-<nazwa>/ istnieje z v1.0.0
# (jeśli nie — git clone git@github.com:LogicMorrow/af-pack-<nazwa>.git packages/af-pack-<nazwa>/)

# Pre-conditions snapshot
EXISTING_AGENTS=$(find packages/af-pack-<nazwa>/.claude/agents/ -name "*.md" | wc -l)
EXISTING_HOOKS=$(jq '[.hooks[][].hooks[].command] | length' packages/af-pack-<nazwa>/.claude/settings.json 2>/dev/null || echo 0)
EXISTING_LESSONS=$(wc -l < packages/af-pack-<nazwa>/.claude/knowledge-base/lessons.jsonl 2>/dev/null || echo 0)
EXISTING_SETTINGS_MD5=$(md5sum packages/af-pack-<nazwa>/.claude/settings.json | awk '{print $1}')

echo "Pre: $EXISTING_AGENTS agents, $EXISTING_HOOKS hooks, $EXISTING_LESSONS lessons"
```

**Run:**
```bash
# Ensure build.sh up-to-date
bash library/embedded-factory/build.sh

# Pack (assuming pack-agent v2.0.0 patched)
# Note: real-test gate (Krok 6b) requires .real-test-status.json — for smoke test
# we set --skip-real-test=cosmetic-smoke-test
/pack af-pack-<nazwa> "CRM dla demo-targi.example (v2.0 smoke test)" --skip-real-test=cosmetic-smoke-test
```

**Assertions:**
```bash
# 1. Embedded agents added (7 new)
NEW_AGENTS=$(find packages/af-pack-<nazwa>/.claude/agents/ -name "*.md" | wc -l)
[ "$NEW_AGENTS" -ge "$((EXISTING_AGENTS + 7))" ] || { echo "FAIL Test 1.1: expected $((EXISTING_AGENTS + 7)) agents, got $NEW_AGENTS"; exit 1; }
test -f packages/af-pack-<nazwa>/.claude/agents/agent-architect.md
test -f packages/af-pack-<nazwa>/.claude/agents/requirements-interviewer.md
test -f packages/af-pack-<nazwa>/.claude/agents/skill-builder.md
test -f packages/af-pack-<nazwa>/.claude/agents/self-pilot-lite.md
test -f packages/af-pack-<nazwa>/.claude/agents/version-bumper.md
test -f packages/af-pack-<nazwa>/.claude/agents/mistake-recorder.md
test -f packages/af-pack-<nazwa>/.claude/agents/pattern-detector-lite.md

# 2. Embedded skills added (4 new)
test -f packages/af-pack-<nazwa>/.claude/skills/conversation-learning/SKILL.md
test -f packages/af-pack-<nazwa>/.claude/skills/cross-agent-learning/SKILL.md
test -f packages/af-pack-<nazwa>/.claude/skills/error-memory-framework/SKILL.md
test -f packages/af-pack-<nazwa>/.claude/skills/model-routing.md

# 3. Embedded hooks added (3 new) + executable
test -x packages/af-pack-<nazwa>/.claude/hooks/session-start-embedded.sh
test -x packages/af-pack-<nazwa>/.claude/hooks/userPromptSubmit-conversation-learning.sh
test -x packages/af-pack-<nazwa>/.claude/hooks/on-error-record.sh

# 4. Embedded commands added (3 new)
test -f packages/af-pack-<nazwa>/.claude/commands/upgrade-factory.md
test -f packages/af-pack-<nazwa>/.claude/commands/promote-lessons.md
test -f packages/af-pack-<nazwa>/.claude/commands/review-candidate-lessons.md

# 5. Settings.json merged (existing hooks preserved + 3 new)
NEW_HOOKS=$(jq '[.hooks[][].hooks[].command] | length' packages/af-pack-<nazwa>/.claude/settings.json)
[ "$NEW_HOOKS" -ge "$((EXISTING_HOOKS + 3))" ] || { echo "FAIL Test 1.5: expected ≥$((EXISTING_HOOKS + 3)) hooks, got $NEW_HOOKS"; exit 1; }

# 6. Lessons preserved (NIE overwritten)
NEW_LESSONS=$(wc -l < packages/af-pack-<nazwa>/.claude/knowledge-base/lessons.jsonl 2>/dev/null || echo 0)
[ "$NEW_LESSONS" -ge "$EXISTING_LESSONS" ] || { echo "FAIL Test 1.6: lessons regressed from $EXISTING_LESSONS to $NEW_LESSONS"; exit 1; }

# 7. Recursive packaging guard: pack-agent NIE w embedded
test ! -f packages/af-pack-<nazwa>/.claude/agents/pack-agent.md || { echo "FAIL Test 1.7: pack-agent.md should NOT be in embedded"; exit 1; }

# 8. Version stamp present
test -f packages/af-pack-<nazwa>/.claude/embedded-factory-version.json
EF_VER=$(jq -r '.embedded_factory_version' packages/af-pack-<nazwa>/.claude/embedded-factory-version.json)
PACK_VER=$(jq -r '.pack_agent_version' packages/af-pack-<nazwa>/.claude/embedded-factory-version.json)
[ "$EF_VER" = "1.0.0" ] && [ "$PACK_VER" = "2.0.0" ] || { echo "FAIL Test 1.8: version stamp mismatch (ef=$EF_VER pack=$PACK_VER)"; exit 1; }

echo "✅ Test 1 PASS: backwards compat scenario"
```

### Test 2: Idempotency (re-run 2× = same result)

```bash
# Snapshot po 1st run
SETTINGS_MD5_1=$(md5sum packages/af-pack-<nazwa>/.claude/settings.json | awk '{print $1}')
HOOK_COUNT_1=$(jq '[.hooks[][].hooks[].command] | length' packages/af-pack-<nazwa>/.claude/settings.json)
AGENT_COUNT_1=$(find packages/af-pack-<nazwa>/.claude/agents/ -name "*.md" | wc -l)

# 2nd run
/pack af-pack-<nazwa> "..." --skip-real-test=cosmetic-smoke-test

SETTINGS_MD5_2=$(md5sum packages/af-pack-<nazwa>/.claude/settings.json | awk '{print $1}')
HOOK_COUNT_2=$(jq '[.hooks[][].hooks[].command] | length' packages/af-pack-<nazwa>/.claude/settings.json)
AGENT_COUNT_2=$(find packages/af-pack-<nazwa>/.claude/agents/ -name "*.md" | wc -l)

# Assertions: identyczne (idempotent)
[ "$HOOK_COUNT_1" = "$HOOK_COUNT_2" ] || { echo "FAIL Test 2.1: hooks duplicated ($HOOK_COUNT_1 → $HOOK_COUNT_2)"; exit 1; }
[ "$AGENT_COUNT_1" = "$AGENT_COUNT_2" ] || { echo "FAIL Test 2.2: agents duplicated ($AGENT_COUNT_1 → $AGENT_COUNT_2)"; exit 1; }
# Note: SETTINGS_MD5 może różnić się jeśli generated_at w settings.json (ale obecnie NIE — settings.json nie ma timestampu, więc MD5 powinno match)

echo "✅ Test 2 PASS: idempotent re-run"
```

### Test 3: Collision preservation (user customization)

```bash
# Setup: paczka ma user-modified agent-architect.md
cp library/embedded-factory/agents/agent-architect.md packages/af-pack-<nazwa>/.claude/agents/agent-architect.md
echo "" >> packages/af-pack-<nazwa>/.claude/agents/agent-architect.md
echo "# Test user customization $(date +%s)" >> packages/af-pack-<nazwa>/.claude/agents/agent-architect.md
USER_VERSION_MD5=$(md5sum packages/af-pack-<nazwa>/.claude/agents/agent-architect.md | awk '{print $1}')

# Run /pack
/pack af-pack-<nazwa> "..." --skip-real-test=cosmetic-smoke-test 2>&1 | tee /tmp/pack-test3.log

# Assertions
# 1. Warning w outputie
grep -q "PRESERVED.*agent-architect" /tmp/pack-test3.log || { echo "FAIL Test 3.1: missing collision warning"; exit 1; }

# 2. User version PRESERVED (not overwritten)
NEW_MD5=$(md5sum packages/af-pack-<nazwa>/.claude/agents/agent-architect.md | awk '{print $1}')
[ "$NEW_MD5" = "$USER_VERSION_MD5" ] || { echo "FAIL Test 3.2: user customization overwritten"; exit 1; }

# 3. Last line zachowana
tail -1 packages/af-pack-<nazwa>/.claude/agents/agent-architect.md | grep -q "Test user customization" || { echo "FAIL Test 3.3: user line missing"; exit 1; }

# 4. Parity check skip dla collision (NIE failed)
grep -q "skip parity.*agent-architect.*user customization preserved" /tmp/pack-test3.log || { echo "FAIL Test 3.4: parity should skip collisions"; exit 1; }

echo "✅ Test 3 PASS: collision preservation"

# Cleanup: restore embedded version
cp library/embedded-factory/agents/agent-architect.md packages/af-pack-<nazwa>/.claude/agents/agent-architect.md
```

### Test 4: Build.sh out-of-date → ABORT przed push

```bash
# Setup: zmień source agent w fabryce, NIE uruchamiaj build.sh
cp .claude/agents/agent-architect.md /tmp/agent-architect-backup.md
echo "" >> .claude/agents/agent-architect.md
echo "# Test edit out-of-sync $(date +%s)" >> .claude/agents/agent-architect.md

# Run /pack — expected ABORT
/pack af-pack-<nazwa> "..." --skip-real-test=cosmetic-smoke-test 2>&1 | tee /tmp/pack-test4.log
PACK_EXIT=${PIPESTATUS[0]}

# Assertions
[ "$PACK_EXIT" = "2" ] || { echo "FAIL Test 4.1: expected exit 2, got $PACK_EXIT"; exit 1; }

grep -q "BLOCKER Krok 7.5a" /tmp/pack-test4.log || { echo "FAIL Test 4.2: missing BLOCKER message"; exit 1; }
grep -q "Run: bash library/embedded-factory/build.sh" /tmp/pack-test4.log || { echo "FAIL Test 4.3: missing remediation hint"; exit 1; }

# Paczka NIE pushed (gh repo NIE created)
# (skip verification — wymaga gh API call, robione manualnie)

# Cleanup
cp /tmp/agent-architect-backup.md .claude/agents/agent-architect.md
rm /tmp/agent-architect-backup.md

echo "✅ Test 4 PASS: build.sh out-of-date ABORT"
```

### Test 5: Recursive packaging guard

```bash
# Setup: omyłkowo dodaj pack-agent.md do embedded (anti-pattern)
cp .claude/agents/pack-agent.md library/embedded-factory/agents/pack-agent.md
# Note: build.sh nie odpalamy żeby manifest.json nie był updated z fake entry
# (test izolowany dla Krok 7.5b guard, NIE manifest validation)

# Run /pack — expected ABORT w Krok 7.5b
/pack af-pack-<nazwa> "..." --skip-real-test=cosmetic-smoke-test 2>&1 | tee /tmp/pack-test5.log
PACK_EXIT=${PIPESTATUS[0]}

# Assertions
[ "$PACK_EXIT" = "2" ] || { echo "FAIL Test 5.1: expected exit 2, got $PACK_EXIT"; exit 1; }
grep -q "recursive packaging anti-pattern" /tmp/pack-test5.log || { echo "FAIL Test 5.2: missing anti-pattern message"; exit 1; }

# Cleanup
rm library/embedded-factory/agents/pack-agent.md

echo "✅ Test 5 PASS: recursive packaging guard"
```

### Acceptance criteria dla S9 (pre-merge gate)

**Implementation S9 MUSI dostarczyć:**

- [ ] Patched `.claude/agents/pack-agent.md` v2.0.0 z Krok 7.5 (a-f) inline (~330 linii total)
- [ ] Frontmatter `version: "2.0.0"` + rozszerzony `description`
- [ ] 6 zasad jakości dodanych do sekcji "Zasady jakości"
- [ ] 3 entries dodanych do sekcji "Czego NIE robisz"
- [ ] Format outputu rozszerzony o punkty 6-7
- [ ] Activity-log entry rozszerzony o embedded_factory_version + collisions count
- [ ] Smoke test plan (Test 1-5) wykonany ręcznie LUB skryptem `test-pack-agent-v2.sh` w `library/embedded-factory/build-fixtures/`
- [ ] `.real-test-status.json` w `packages/af-pack-<nazwa>/` (po smoke test) z `approved_by_human: true` (operator)
- [ ] Quality-checker dispatch PASS (E16 )

**Acceptance criterion EXIT:**

- Wszystkie 5 testów PASS (manualnie lub script).
- Backwards compat verified: CRM v1.0 → v2.0 preserved 100% existing artefakty.
- Idempotency verified: re-run NIE duplikuje hooków/agentów.
- Anti-patterns guards verified: recursive packaging blocked, scaffold pollution blocked, settings overwrite blocked.

## Open questions (deferred do S9)

Patrz ADR 012 sekcja "Open questions for S9 implementation" — 6 pytań rozstrzygniętych z default decisions. S9 może override jeśli implementation wykaże konieczność (dokumentacja w reflection 10B).

## References

- **ADR 012** (`knowledge-base/docs/embedded-factory/adr/012-pack-agent-krok-n-plus-1.md`) — pełna decyzja architektoniczna + 8 decision drivers + Option A/B/C analysis
- **Pack-agent v1.x** (`.claude/agents/pack-agent.md`) — source-of-truth dla S9 baseline
- **Manifest.json** (`library/embedded-factory/manifest.json`) — Krok 7.5b/c/e konsument
- **Build.sh** (`library/embedded-factory/build.sh`) — Krok 7.5a konsument (`--check` mode)
- **Brief 10B** (`knowledge-base/interviews/2026-05-24-embedded-factory.md`) — Q1 recursive packaging invariant, Krok 6c-6e specification
- **Plan 10B** (`knowledge-base/plans/2026-05-24--portable-self-learning-loop.md`) — E8 spec, sesje S8 (architektura) + S9 (implementation)
- **Master plan** (`knowledge-base/plans/2026-05-24-master--11-portable-learning.md`) — Kontrakt B schema

---

**Status:** ready_for_implementation
**Next step (S9):** Główny Claude (`/model sonnet`) implementuje Krok 7.5 a-f w `.claude/agents/pack-agent.md` zgodnie z tym design + executes smoke test plan + zapisuje `.real-test-status.json`.
