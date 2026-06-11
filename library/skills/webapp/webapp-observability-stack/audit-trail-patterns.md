# Audit Trail Patterns — webapp-observability-stack

Wzorce implementacji audit trail dla aplikacji produkcyjnych LogicMorrow.
Referencja: hook `audit-trail-on-offer-write.sh` z paczki DemoApp (/13).

---

## 1. Struktura katalogów

```
artifacts/
└── audit-trail/
    ├── index.jsonl               # append-only indeks wszystkich snapshotów
    ├── 2026/
    │   ├── 01/
    │   │   ├── oferta-2026-001/
    │   │   │   ├── oferta.pdf    # chmod 0444 (immutable)
    │   │   │   ├── oferta.json   # chmod 0444 (immutable)
    │   │   │   └── manifest.json # chmod 0444 (immutable)
    │   │   └── oferta-2026-002/
    │   └── 05/
    │       └── oferta-2026-123/
    └── 2027/
        └── ...
```

**Zasady struktury:**
- `<YYYY>/<MM>/<offer-id>/` — partycjonowanie czasowe umożliwia selektywne usuwanie RODO
- `index.jsonl` — append-only (nigdy nie nadpisuj, tylko `echo >> index.jsonl`)
- Każdy offer-id katalog ma dokładnie 3 pliki: pdf + json + manifest

---

## 2. Hook implementation patterns

### Pattern A — PostToolUse (rekomendowany dla Claude-based workflow)

```json
// .claude/settings.json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/audit-trail-on-offer-write.sh",
            "environment": {
              "OFFER_ID": "${OFFER_ID}",
              "SOURCE_PDF": "${GENERATED_PDF_PATH}",
              "SOURCE_JSON": "${OFFER_DATA_PATH}"
            }
          }
        ]
      }
    ]
  }
}
```

### Pattern B — Server-side (Next.js Route Handler)

```typescript
// app/api/offers/route.ts
import { createAuditSnapshot } from '@/lib/audit-trail'

export async function POST(req: Request) {
  const offer = await saveOfferToDb(data)
  const pdfPath = await generatePdf(offer)

  // Audit trail — nie blokuje odpowiedzi API
  createAuditSnapshot({
    offerId: offer.id,
    pdfPath,
    offerData: offer,
    actor: 'jankowalski',
  }).catch((err) => logger.error({ err }, 'audit trail failed'))

  return NextResponse.json({ success: true, offerId: offer.id })
}
```

### Pattern C — Sidecar service (dla high-reliability)

Osobny Node.js proces nasłuchuje na queue (Redis/BullMQ) → zapisuje snapshoty asynchronicznie.
Overkill dla single-user MVP — rozważyć w v2 jeśli volumeny ofert > 100/dzień.

---

## 3. Immutable storage (chmod 0444)

```bash
# Po zapisie pliku — natychmiast immutable
chmod 0444 "artifacts/audit-trail/${YYYY}/${MM}/${OFFER_ID}/oferta.pdf"
chmod 0444 "artifacts/audit-trail/${YYYY}/${MM}/${OFFER_ID}/oferta.json"
chmod 0444 "artifacts/audit-trail/${YYYY}/${MM}/${OFFER_ID}/manifest.json"
```

**Co daje chmod 0444:**
- Zapobiega przypadkowemu `echo > plik` (overwrite)
- Zapobiega edycji przez `vim`, `nano` itp.
- NIE zapobiega `rm` przez root — plik jest immutable tylko przed nadpisaniem

**Dla silniejszej gwarancji (opcjonalne):**
```bash
# Linux chattr — prawdziwy immutable (nawet root nie może nadpisać/usunąć)
chattr +i "artifacts/audit-trail/${YYYY}/${MM}/${OFFER_ID}/"*
# Aby usunąć (RODO erasure) — root musi najpierw: chattr -i plik, potem rm
```

**Zalecenie dla DemoApp:** `chmod 0444` wystarcza dla audit trail. `chattr +i` tylko jeśli
audytor zewnętrzny explicite wymaga.

---

## 4. Retencja 5 lat (RODO compliance)

**Podstawa prawna:** art. 5 ust. 1 lit. e RODO (ograniczenie przechowywania) + art. 74 ustawy
o rachunkowości PL (5-letni obowiązek przechowywania faktur/ofert).

**Retention policy:**
- Domyślna retencja: **5 lat (1826 dni)** od daty snapshot
- Retention zapisany w `manifest.json` jako `retention_until`

**Automated retention check (cron w docker-compose):**
```bash
#!/usr/bin/env bash
# cleanup-expired-audit-trail.sh — uruchamiany monthly
# UWAGA: przed usunięciem — weryfikuj z operatorem/Janem

TODAY=$(date +%Y-%m-%d)

find artifacts/audit-trail -name "manifest.json" | while read manifest; do
  retention_until=$(jq -r '.retention_until' "$manifest")
  if [[ "$retention_until" < "$TODAY" ]]; then
    offer_dir=$(dirname "$manifest")
    echo "EXPIRED: ${offer_dir} (retention_until=${retention_until})"
    # NIE usuwaj automatycznie — tylko loguj do review
    # rm -rf "$offer_dir"  # odkomentuj po manualnej weryfikacji
  fi
done
```

**RODO erasure on request (art. 17):**
```bash
# Procedura usunięcia danych konkretnego klienta (name/phone search)
# 1. Znajdź oferty klienta
grep -l "Kowalski" artifacts/audit-trail/*/*/oferta.json

# 2. Dla każdej oferty — usuń PII z JSON (anonimizacja, nie usunięcie)
# lub usuń cały katalog jeśli brak interesu nadrzędnego
chmod 0644 artifacts/audit-trail/2026/01/oferta-2026-001/oferta.json
# Edytuj JSON — zastąp nazwisko/telefon/adres "[usunięto na wniosek]"
chmod 0444 artifacts/audit-trail/2026/01/oferta-2026-001/oferta.json

# 3. Odnotuj w index.jsonl
echo '{"action":"gdpr_erasure","offer_id":"oferta-2026-001","date":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' \
  >> artifacts/audit-trail/index.jsonl
```

---

## 5. Recovery from backup

Audit trail jest lokalny — backup jest krytyczny.

**Backup audit-trail (via webapp-backup-dr):**
```yaml
# W backup sidecar compose — dodaj audit-trail do archiwum
volumes:
  - ./artifacts/audit-trail:/audit-trail:ro
# Skrypt backup: pg_dump + tar audit-trail → B2
```

**Restore:**
```bash
# Download z B2 (rclone)
rclone copy b2:{{PROJECT_NAME}}-backups/audit-trail/latest ./restore/audit-trail/

# Weryfikacja integralności MD5
while IFS= read -r line; do
  offer_id=$(echo "$line" | jq -r '.offer_id')
  pdf_md5=$(echo "$line" | jq -r '.pdf_md5')
  pdf_file="./restore/audit-trail/..."
  actual_md5=$(md5sum "$pdf_file" | awk '{print $1}')
  if [[ "$pdf_md5" != "$actual_md5" ]]; then
    echo "INTEGRITY FAIL: ${offer_id}"
  fi
done < restore/audit-trail/index.jsonl
```
