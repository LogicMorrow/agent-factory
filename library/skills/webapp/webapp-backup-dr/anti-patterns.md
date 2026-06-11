# Antywzorce — webapp-backup-dr v1.0.0

---

## AP-1 — B2 credentials hardcoded w pliku konfig lub skrypcie

**Co widać:**
```bash
# pg-dump-cron.sh — ZLE
B2_KEY_ID="K001abcXXXXXXXXX"
B2_KEY="K001secretXXXXXXXXXXXXXXXX"
```

lub w `rclone.conf`:
```ini
[b2remote]
account = K001abcXXXXXXXXX   # ZLE — hardcoded
key = K001secretXXXXXXXXXX   # ZLE — hardcoded
```

**Skutek:** git push → credentials widoczne w historii na zawsze (nawet po git rm). Rotacja wszystkich kluczy B2. Potencjalny storage cost spike jeśli ktoś znajdzie i uploaduje do bucket.

**Korekta:**
```bash
# W .env.backup (NIE w git):
B2_APPLICATION_KEY_ID=K001abcXXXXXXXXX
B2_APPLICATION_KEY=K001secretXXXXXXXXXX
```
```yaml
# W compose.prod.yml:
env_file: .env.backup
```
```bash
# W .gitignore:
.env.backup
.env.*.local
```
Weryfikacja: `git grep "K001" || echo "OK"` — powinno być puste.

---

## AP-2 — `rclone sync` zamiast `rclone copy` przy backup

**Co widać:**
```bash
# ZLE — sync kasuje pliki na B2 które nie ma lokalnie!
rclone sync /backups/daily/ b2remote:bucket/daily/
```

**Skutek:** retention-rotation.sh usunął stare pliki lokalnie → rclone sync usuwa je też z B2. Po 7 dniach masz ZERO historii. Disaster recovery niemożliwy.

**Korekta:**
```bash
# DOBRZE — copy dodaje pliki, nigdy nie kasuje
rclone copy /backups/daily/<plik>.sql.gz b2remote:bucket/daily/
```

Reguła: `rclone sync` = mirror (kasuje różnice). `rclone copy` = additive. Przy backup **zawsze** `copy`.

---

## AP-3 — Brak monthly restore drill (backup nigdy nie testowany)

**Co widać:** backup sidecar działa, dumpy są na B2, ale `restore-drill.sh` nie jest w crontab lub jest zakomentowany.

**Skutek:** po 6 miesiącach okazuje się że pg_restore nie działa bo:
- dump format nie pasuje do nowej wersji PostgreSQL
- `--no-privileges --no-owner` pominięty i restore wymaga superuser
- dump był partial (disk full w połowie pg_dump, ale skrypt to ignorował)
- Odkrywasz to przy realnym disaster, nie w drilu.

**Korekta:** `restore-drill.sh` w crontab co miesiąc (`0 4 1 * *`). Sprawdź że cron jest aktywny:
```bash
docker compose exec backup crontab -l | grep restore-drill
# → 0 4 1 * * /usr/local/bin/restore-drill.sh >> /var/log/drill.log 2>&1
```

---

## AP-4 — Restore na live produkcyjnej bazie danych

**Co widać:**
```bash
# ZLE — pg_restore bezpośrednio na produkcyjną bazę
pg_restore -h db -U demoapp_user -d demoapp_production backup.sql.gz
```

**Skutek:**
- Jeśli backup jest starszy niż ostatnie dane → utrata danych z ostatnich N godzin
- `--single-transaction` nie działa z dużymi bazami → partial restore który korumpuje dane
- Użytkownik widzi błędy w trakcie restore

**Korekta:** zawsze restore do ephemeral container (drill) lub do staging. Przy realnym disaster — zatrzymaj `app` container PRZED restore:
```bash
docker compose stop app  # najpierw
docker compose exec db pg_restore ...  # potem restore
docker compose start app  # na końcu po weryfikacji
```

---

## AP-5 — Retention zbyt krótka lub brak rotation (tylko daily)

**Co widać:**
```bash
# retention-rotation.sh zatrzymuje się na daily — brak logiki weekly/monthly
find /backups/daily/ -mtime +7 -delete
# I nic więcej — brak weekly/, brak monthly/
```

**Skutek:** można przywrócić z maks. 7 dni temu. Błąd wykryty po 10 dniach = nieodwracalne. Audytor może zapytać "czy możesz odtworzyć dane sprzed 2 miesięcy?" → NIE.

**Korekta:** pełna rotacja z `retention-rotation.sh`: 7 daily + 4 weekly + 12 monthly. Dla DemoApp z retencją RODO 5 lat na ofertach — monthly backupy przez 12 miesięcy dają rolling 1-roczne pokrycie. Starsze dane w DB (nie usunięte) nie wymagają backupu sprzed 12m bo są w żywej bazie.

---

## AP-6 — pg_dump bez `--format=custom`

**Co widać:**
```bash
# ZLE — plain SQL dump
pg_dump --dbname=demoapp_production > backup.sql
```

**Skutek:**
- Brak kompresji wbudowanej (`--compress`)
- `pg_restore` nie może restorować selektywnie (per tabela)
- Duże dumpy (z TOAST, large objects) są wolniejsze i większe
- Nie można użyć parallel restore (`-j 4`)

**Korekta:**
```bash
pg_dump --format=custom --compress=9 --no-privileges --no-owner | gzip -9 > backup.sql.gz
```
`--format=custom` = format binarny, kompresja, selective restore, parallel. Standardowo używany w tym skill.

---

## AP-7 — Sidecar z elevated privileges (root container)

**Co widać:**
```dockerfile
# ZLE — backup sidecar działa jako root
FROM postgres:16-alpine
# brak USER directive
CMD ["crond", "-f"]
```

**Skutek:** skompromitowany sidecar ma root access do hosta przez mounted volumes. Może nadpisać pliki backupów lub eskalować uprawnienia.

**Korekta:** backup-sidecar.dockerfile.template używa `postgres` user (UID 70 w alpine), który ma dostęp do pg narzędzi, ale nie do roota hosta. Jeśli potrzebujesz innego UID, dodaj:
```dockerfile
RUN addgroup -S backup && adduser -S backup -G backup -u 1001
USER backup
```
