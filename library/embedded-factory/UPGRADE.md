# UPGRADE.md — embedded-factory upgrade workflow

Procedura aktualizacji embedded-factory w projekcie zewnętrznym po release nowej wersji w `agent-factory`. Decyzja Q4: **manual `/upgrade-factory`** (NIE auto-pull) — świadoma decyzja operatora, bo upgrade może łamać lokalne customizations.

## Kiedy aktualizować

- Nowa wersja embedded-factory wypuszczona w `LogicMorrow/agent-factory` (changelog notification)
- Bugfix dla agenta którego używasz aktywnie w projekcie
- Quartal-ly review (co kwartał sprawdź czy są aktualizacje warte upgrade)

**Kiedy NIE aktualizować:**
- Active sprint / critical work — upgrade po sprincie, ryzyko regression
- Lokalny patch projekt-specific (np. zmodyfikowany agent-architect) — upgrade nadpisze. Przedtem manual reconcile.

## Workflow `/upgrade-factory`

### Krok 1 — Pre-upgrade audit

```bash
# W projekcie-konsumencie paczki
/upgrade-factory --dry-run
```

Command:
1. Fetch latest `library/embedded-factory/manifest.json` z `LogicMorrow/agent-factory` repo (raw GitHub URL)
2. Porównuje `manifest.json.embedded_factory_version` lokalny vs remote
3. Jeśli local >= remote → exit "Already up to date"
4. Jeśli local < remote → lista zmian per agent/skill/hook/command:
   - `source_hash` mismatch (artefakt zmieniony)
   - NEW (artefakt dodany)
   - DELETED (artefakt usunięty)
5. Sprawdza lokalne customizations:
   - Jeśli plik w `.claude/agents/<name>.md` ma `local_patch: true` w frontmatter → flag `CONFLICT`
6. Output: lista zmian + estymata risk per artefakt + recommendation (proceed / manual reconcile / abort)

### Krok 2 — Backup

```bash
/upgrade-factory --backup
```

Command:
1. Mkdir `.claude/embedded-factory-backup-pre-upgrade-<YYYY-MM-DD>/`
2. Copy obecne `.claude/agents/`, `.claude/skills/`, `.claude/hooks/`, `.claude/commands/`
3. Copy obecne `.claude/knowledge-base/` (cały — lessons + reflections + errors + activity-log)
4. Copy obecne `.claude/settings.json`
5. Output: backup location + total size

**Backup retention:** keep last 3 backups, auto-delete starsze (FIFO).

### Krok 3 — Apply upgrade

```bash
/upgrade-factory --apply
```

Command:
1. Re-run dry-run (Krok 1) jeśli >24h od ostatniego dry-run
2. Confirm interactive: "Proceed with upgrade? [y/N]"
3. Per artefakt z zmianami:
   - Pull source content z `LogicMorrow/agent-factory` raw URL
   - Verify source_hash MD5 match z manifest.json
   - Write do `.claude/agents/<name>.md` (overwrite)
4. Update `.claude/embedded-factory/manifest.json` (local) z nowymi wersjami
5. Update `.claude/settings.json` jeśli hooks zmienione (auto-merge nowych hooks; preserve user customizations)
6. Run smoke test: każdy hook ma exit 0 dla empty stdin
7. Output: summary changes + lista failed (jeśli)

### Krok 4 — Post-upgrade validation

```bash
/upgrade-factory --validate
```

Command:
1. Run każdy hook z synthetic input → exit 0?
2. Verify manifest.json matches actual files
3. Verify `.claude/settings.json` hooks paths exist
4. Verify `.claude/knowledge-base/` struktura intakt (nic nie nadpisane backup-em)
5. Output: PASS/FAIL per check

### Krok 5 — Rollback (jeśli problemy)

```bash
/upgrade-factory --rollback=<backup-id>
```

Command:
1. List dostępne backupy w `.claude/embedded-factory-backup-pre-upgrade-*`
2. User wybiera backup_id (default: latest)
3. Confirm interactive: "Rollback to <backup-id>? Current state will be backed up to .claude/embedded-factory-backup-rollback-<ts>/. [y/N]"
4. Backup current state (safety)
5. Restore z backup_id (copy reverse)
6. Output: restored to <backup-id>, current backup-ed to <new-backup-id>

## Edge cases

### Conflict: lokalny patch agenta

Scenariusz: user zmodyfikował `agent-architect.md` lokalnie w projekcie (np. dodał project-specific instructions). Remote ma update.

**Workflow:**
1. Dry-run flag `CONFLICT` w sekcji "Files with local customizations"
2. User wybiera per-file: `keep-local` / `take-remote` / `manual-merge`
3. `manual-merge` → opens 3-way diff (local | remote | base) w default editor (vim diff mode)
4. After save → apply merged version

### Schema migration

Scenariusz: lessons.jsonl schema v1 → v2 w embedded-factory (.E13).

**Workflow:**
1. Pre-upgrade: dry-run wykrywa schema delta (new optional fields: `origin`, `confidence_hits`, `promoted_at`)
2. User confirm migration: "Migrate 47 existing lessons to schema v2 (adding default values for new fields)? [y/N]"
3. Backup lessons.jsonl
4. Run migration script: per lesson, add missing fields with defaults (`origin: af-pack-<nazwa>`, `confidence_hits: 1`, `promoted_at: null`)
5. Validate post-migration: all lessons pass new schema
6. Output: migrated N lessons + delta count

### Cron routines update

Scenariusz: embedded-factory introduces cron routine (np. weekly self-pilot in projekt).

**Workflow:**
1. Dry-run informuje: "This upgrade adds cron routine. Run `/web-setup` after upgrade to enable."
2. Post-upgrade: print reminder
3. User decyduje czy aktywować (opcjonalne —  decyzja Q3)

## Anti-patterns

- ❌ **NIE upgrade w trakcie active sprint** — wait until sprint end
- ❌ **NIE skip dry-run** — zawsze sprawdź zmiany przed apply
- ❌ **NIE skip backup** — rollback wymaga backup-u
- ❌ **NIE manual edit `manifest.json`** — to output build-script, edit source agentów/skilli w `.claude/`
- ❌ **NIE upgrade > 1 major version naraz** — incremental upgrades (1.0 → 1.1 → 1.2), nie 1.0 → 2.0 direct

## Recovery procedures

### Hook broken po upgrade

1. `/upgrade-factory --rollback=latest` → restore
2. Report issue na `LogicMorrow/agent-factory` issues
3. Wait fix → re-attempt

### Settings.json corrupted

1. Restore z `.claude/embedded-factory-backup-pre-upgrade-<date>/settings.json`
2. Manual reconcile jeśli były user customizations

### Knowledge-base data loss

**Unlikely** — upgrade NIE modyfikuje `.claude/knowledge-base/`, tylko `.claude/agents,skills,hooks,commands/`. Jeśli się stanie:
1. Restore z backup `.claude/embedded-factory-backup-pre-upgrade-<date>/.claude/knowledge-base/`
2. Report jako BUG (P0) — naruszenie separation of concerns

## References

- Build-script: `library/embedded-factory/build.sh` (ADR 009)
- Manifest schema: `library/embedded-factory/manifest.json`
- Cron routines: .E14
- ADR 013: `knowledge-base/docs/embedded-factory/adr/013-upgrade-factory-backup-dry-run.md` (do napisania w .S11)
