# Antywzorce — webapp-threat-model-template

6 krytycznych antywzorców z lesson  (fundamental error: paczka v1.0 zadeklarowała PASS mimo placeholderów w SECURITY.md).

---

## AP1: SECURITY.md jako placeholder (KRYTYCZNY — lesson )

**Opis:** SECURITY.md zawiera `[TBD]`, `[TODO]`, `// TODO: fill this`, `<GPG_KEY_HERE>` zamiast konkretnej treści.

**Jak wygląda:**
```markdown
## Reporting a vulnerability
Contact security@example.com.
[TBD — add GPG key when ready]
Supported versions: [TODO]
Rotation schedule: [TODO: document quarterly process]
```

**Dlaczego fatal:**
- Audytor widzi SECURITY.md w pierwszych 5 minutach
- `[TBD]` = "security nie jest priorytetem" — immediate red flag
- Paczka v1.0  przeszła QC mimo tego — POST-MORTEM  fundamental error
- OWASP ASVS V1.1.1: "Documented and accepted all security decisions" — placeholder ≠ decision

**Mitigation:**
- Template z `{{GPG_FINGERPRINT}}` — łatwy do podmiany `sed`
- Zero-placeholder gate przed deploy (patrz `placeholders-reference.md`)
- `quality-checker` MUSI sprawdzać brak `[TBD]`/`[TODO]` w SECURITY.md

**Test:**
```bash
grep -n '\[TBD\]\|\[TODO\]\|TODO:' SECURITY.md
# Oczekiwane: 0 wyników
```

---

## AP2: Threat model bez mitigations (mock STRIDE)

**Opis:** threat-model.md ma tabelę STRIDE z H/M/L, ale bez konkretnych mitigations ani referencji do kodu.

**Jak wygląda:**
```markdown
| Komponent | Spoofing | Tampering | ...
|---|---|---|
| app | H | M | ...
| db | L | H | ...
```

**Dlaczego fail:**
- STRIDE matrix bez mitigations = lista ryzyk bez planu mitygacji
- Audytor (OWASP ASVS V1.6): "All threats identified must have documented mitigations"
- Tabela bez treści = dekoracja, nie threat model

**Mitigation:**
- Każdy cell H/M/L MUSI mieć: scenariusz ataku (1 zdanie) + ≥2 mitigations + code reference
- Threshold minimum: HIGH cells muszą mieć ≥3 mitigations
- Template `threat-model-template.md` ma per-component sekcje z pełną treścią

**Test:**
```bash
# Sprawdź czy są sekcje per-komponent (nie tylko tabela)
grep -c "#### Spoofing\|#### Tampering" docs/threat-model.md
# Oczekiwane: ≥5 (5 komponentów × niektóre threats szczegółowo)
```

---

## AP3: ADR bez `Alternatives considered` (jednostronna decyzja)

**Opis:** ADR opisuje tylko wybraną opcję bez sekcji "Alternatives considered".

**Jak wygląda:**
```markdown
# ADR-001 — Stack

## Context
Potrzebujemy frameworka.

## Decision
Wybrano Next.js 14.2.

## Consequences
- Dobry framework
- Szybki development
```

**Dlaczego fail:**
- Audytor ZAWSZE pyta: "Dlaczego nie Auth.js v5? Dlaczego nie Next 15?"
- ADR bez alternatives to "notatka decyzyjna", nie Architecture Decision Record
- Brak alternatives = niemożliwe odtworzenie kontekstu decyzji za 2 lata
- Zasada #15 pkt 17: "minimum 3 ADR-y konkretne" → konkretne = z alternatives

**Mitigation:**
- Każdy ADR MUSI mieć tabelę Alternatives z ≥2 odrzuconymi opcjami
- Każda odrzucona opcja: kolumna "Why rejected" z konkretnym powodem
- Format: tabela Markdown (łatwa do skanowania)

**Test:**
```bash
# Sprawdź czy każdy ADR ma tabelę alternatives
for adr in docs/adr/ADR-*.md; do
  if ! grep -q "| Option\|| Why rejected" "$adr"; then
    echo "MISSING alternatives: $adr"
  fi
done
```

---

## AP4: Runbook abstrakcyjny bez konkretnych komend

**Opis:** Runbook opisuje kroki słownie bez konkretnych komend bash/docker.

**Jak wygląda:**
```markdown
## Deploy procedure
1. Build the container
2. Deploy to production
3. Verify deployment succeeded
4. Check for errors in logs
5. Confirm application is healthy
```

**Dlaczego fatal:**
- Na incydencie (Down 2h SLA) nie ma czasu szukać konkretnych komend
- "Verify deployment succeeded" = co konkretnie? curl? docker ps? Sentry?
- Runbook bez komend = nieużyteczny w stresowej sytuacji
- "Runbook untested is not a runbook" — brak komend = niemożliwy do przetestowania

**Mitigation:**
- Każdy krok = konkretna komenda (bash, docker, curl)
- Healthcheck: konkretny URL + oczekiwany output
- Rollback: konkretny `docker tag` + `docker compose up -d` + weryfikacja SHA
- Template `runbook.md.template` ma wszystkie komendy gotowe do copy-paste

**Test:**
```bash
# Sprawdź czy runbook ma konkretne komendy
grep -c "docker\|curl\|ssh\|kubectl\|pnpm" docs/runbook.md
# Oczekiwane: ≥10
```

---

## AP5: IR procedure bez SLA numbers

**Opis:** IR procedure opisuje kroki obsługi incydentu, ale nie zawiera konkretnych SLA (czas reakcji, MTTR).

**Jak wygląda:**
```markdown
## Incident Response

### Detection
Monitor alerts from UptimeRobot.

### Response
Respond as quickly as possible.

### Resolution
Resolve the issue promptly.
```

**Dlaczego fail:**
- Bez SLA numbers nie można mierzyć czy IR jest skuteczna
- OWASP ASVS V1.10.1: "Incident response plan exists and has been tested"
- "Respond as quickly as possible" = bez baseline = audytor odrzuca
- Single-developer SLA MUSI być explicite (2h/8h Down, 4h/24h Degraded, 1h/isolation Security)

**Mitigation:**
- Tabela SLA w sekcji 0 (summary) + w sekcji Escalation matrix
- Każdy severity: Reaction time + MTTR + konkretna definicja triggera
- Single-developer: SLA dostosowane do working hours (8:00-18:00 CET)

**Test:**
```bash
# Sprawdź czy SLA numbers są obecne
grep -E "[0-9]h reaction|[0-9]h MTTR|reakcja.*[0-9]h" docs/IR-procedure.md
# Oczekiwane: ≥3 wyniki (Down/Degraded/Security)
```

---

## AP6: CHANGELOG zaczynający się od wersji powyżej 1.0.0 lub bez [Unreleased]

**Opis 1:** CHANGELOG.md zaczyna się od `## [2.0.0]` bez historii poprzednich wersji.
**Opis 2:** CHANGELOG.md nie ma sekcji `## [Unreleased]`.

**Jak wygląda (AP6a — bez Unreleased):**
```markdown
# Changelog

## [1.5.0] - 2026-05-29
### Added
- Feature X
```

**Jak wygląda (AP6b — wersja z powietrza):**
```markdown
# Changelog

## [3.0.0] - 2026-05-29
### Added
- Initial release
```

**Dlaczego fail:**
- keepachangelog.com: "## [Unreleased]" jest wymagana (zbiera zmiany do następnego release)
- Brak historii = niemożliwe śledzenie regression security (kiedy dodano HSTS? Kiedy TLS?)
- "3.0.0 Initial release" = SemVer violation (initial = 1.0.0 lub 0.x.0 pre-release)
- Audytor sprawdza CHANGELOG pod kątem Security entries (kiedy łatano CVE)

**Mitigation:**
- Template `CHANGELOG.md.template` zaczyna się od `## [Unreleased]` sekcji
- Pierwsza wersja: `## [1.0.0] - YYYY-MM-DD` z Security sekcją
- Każdy deploy: wpis w CHANGELOG przed merge do main

**Test:**
```bash
# Sprawdź format
head -10 CHANGELOG.md | grep -q "## \[Unreleased\]" && echo "OK: Unreleased sekcja" || echo "FAIL: brak Unreleased"
grep -c "### Security" CHANGELOG.md
# Oczekiwane: ≥1 Security sekcja
```

---

## Bonus AP7: threat-model tylko dla "happy path" (pomija backup i ci-cd)

**Opis:** Threat model pokrywa tylko app + db, pomija proxy/backup/ci-cd jako "mniej ważne".

**Dlaczego fail:**
- ci-cd komponenty (GH Actions + self-hosted runner) to najczęstszy wektor ataku w nowoczesnych aplikacjach (supply chain attacks)
- backup leak = pełne PII w jednym pliku — Information disclosure HIGH
- OWASP ASVS V1.2: "All trust boundaries, data flows, and entry points documented"

**Mitigation:**
- `threat-model-template.md` zawiera wszystkie 5 komponentów explicite
- CI/CD i backup sekcje NIE są opcjonalne
- Reguła: jeśli coś ma network access lub secret — musi być w threat model

---

## Checklista weryfikacyjna — zero antywzorców

```bash
# AP1: zero [TBD]/TODO w security docs
grep -rn '\[TBD\]\|\[TODO\]\|TODO:' SECURITY.md docs/ | grep -v ".md:#" | wc -l
# Oczekiwane: 0

# AP2: threat-model ma per-component sekcje
grep -c "####" docs/threat-model.md
# Oczekiwane: ≥10 (komponent × threats)

# AP3: ADR-y mają alternatives
for f in docs/adr/ADR-*.md; do grep -q "Why rejected" "$f" || echo "FAIL: $f"; done

# AP4: runbook ma komendy
grep -c "docker\|curl\|ssh" docs/runbook.md
# Oczekiwane: ≥10

# AP5: IR ma SLA
grep -Ec "[0-9]h" docs/IR-procedure.md
# Oczekiwane: ≥3

# AP6: CHANGELOG format
head -5 CHANGELOG.md | grep -q "Unreleased" && echo "OK" || echo "FAIL"
```
