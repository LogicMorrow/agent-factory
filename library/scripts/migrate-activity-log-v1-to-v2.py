#!/usr/bin/env python3
"""
migrate-activity-log-v1-to-v2.py — migracja legacy wpisów activity-log bez `action`.

Origin:  A6 (2026-05-13).
Adresuje audyt: 14 wpisów bez pola `action` (legacy z pre-2026-04-29 konwencji).

Workflow:
  1. Backup oryginalny → activity-log.v1.backup.jsonl
  2. Per wpis: if 'action' not in entry → add action: "legacy_unknown" + migrated_at + migration_note
  3. Idempotent (skip wpisy które już mają migrated_at)
  4. Verify: każdy wpis ma `action`
  5. Swap (po operator approve lub --apply flag)

Usage:
  python3 library/scripts/migrate-activity-log-v1-to-v2.py            # dry-run
  python3 library/scripts/migrate-activity-log-v1-to-v2.py --apply    # execute migration
"""
import json
import sys
import shutil
from datetime import datetime, timezone
from pathlib import Path

LOG_FILE = "knowledge-base/activity-log.jsonl"
BACKUP_FILE = "knowledge-base/activity-log.v1.backup.jsonl"

APPLY = '--apply' in sys.argv

# Read all entries
entries = []
total = 0
needs_migration = 0
already_migrated = 0
with open(LOG_FILE) as f:
    for line in f:
        line = line.strip
        if not line:
            continue
        total += 1
        try:
            e = json.loads(line)
        except json.JSONDecodeError:
            # Keep raw line as-is (corrupt entry)
            entries.append({"__raw__": line})
            continue

        if 'action' in e:
            if 'migrated_at' in e:
                already_migrated += 1
            entries.append(e)
        else:
            needs_migration += 1
            if APPLY:
                e['action'] = 'legacy_unknown'
                e['migrated_at'] = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
                e['migration_note'] = ' A6 — added action=legacy_unknown (originally no action field)'
            entries.append(e)

print(f"Total entries: {total}")
print(f"Already migrated: {already_migrated}")
print(f"Needs migration: {needs_migration}")

if not APPLY:
    print("\n[DRY-RUN] Use --apply to execute migration.")
    sys.exit(0)

# Backup
if not Path(BACKUP_FILE).exists:
    shutil.copy(LOG_FILE, BACKUP_FILE)
    print(f"\n✓ Backup created: {BACKUP_FILE}")
else:
    print(f"\nℹ️  Backup already exists: {BACKUP_FILE} (skip overwrite)")

# Write migrated
with open(LOG_FILE, 'w') as f:
    for e in entries:
        if '__raw__' in e:
            f.write(e['__raw__'] + '\n')
        else:
            f.write(json.dumps(e) + '\n')

print(f"\n✅ Migration applied: {needs_migration} legacy entries → action=legacy_unknown")

# Verify
with open(LOG_FILE) as f:
    bad = 0
    for line in f:
        line = line.strip
        if not line: continue
        try:
            e = json.loads(line)
            if 'action' not in e:
                bad += 1
        except: pass

print(f"\nVerification: {bad} entries still without `action` (should be 0)")
