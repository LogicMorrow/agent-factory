# Workflow konsumenta — jak produkować docs od zera

Dokładny opis 10 kroków dla agenta `tech-doc-writer` lub operatora budującego docs dla nowego projektu webapp.

---

## Założenia startowe

- Projekt zbuildowany: Docker działa, CI/CD skonfigurowane, app dostępna lokalnie
- Brief wywiadu dostępny (np. `knowledge-base/interviews/2026-05-29--reset-demoapp.md`)
- Skille z `requires` wdrożone: `webapp-docker-templates`, `webapp-ci-cd-workflows`, `webapp-observability-stack`, `webapp-backup-dr`, `webapp-reverse-proxy-tls`

---

## Krok 1: Utwórz strukturę katalogów

```bash
mkdir -p docs/adr
touch docs/threat-model.md
touch docs/runbook.md
touch docs/IR-procedure.md
touch SECURITY.md
touch CHANGELOG.md
```

Wynikowa struktura:
```
docs/
├── adr/
│   ├── ADR-001-stack.md
│   ├── ADR-002-iac.md
│   ├── ADR-003-auth-totp.md
│   └── ADR-004-pdf-engine.md
├── threat-model.md
├── runbook.md
└── IR-procedure.md
SECURITY.md
CHANGELOG.md
README.md
```

---

## Krok 2: Podmień `{{PLACEHOLDER}}` na wartości projektu

1. Skopiuj skrypt z `placeholders-reference.md` sekcja "Skrypt podmiany"
2. Edytuj zmienne na górze skryptu (PROJECT_NAME, PROD_DOMAIN, etc.)
3. Uruchom: `bash scripts/setup-docs-placeholders.sh`
4. Dopełnij ręcznie te z listy "opcjonalne" (GPG_FINGERPRINT, VPS_PROD_HOST, etc.)

**Walidacja:** `grep -r '{{' docs/ SECURITY.md CHANGELOG.md` → zero wyników.

---

## Krok 3: Napisz ADR-001 Stack (zasada #15 pkt 17)

Użyj `templates/ADR-001-stack-example.md` jako wzorzec wypełniony.

**Co wypełnić konkretnie:**
- Context: wymogi projektu, deadline, istniejący stack
- Decision: wybrany stack (1-3 zdania uzasadnienia)
- Consequences: ≥3 pozytywne + ≥2 negatywne
- Alternatives: każda odrzucona opcja z konkretnym powodem odrzucenia

**Czas:** ~30 min przy dobrym briefie wywiadu.

**Weryfikacja:** `grep -c "| " docs/adr/ADR-001-stack.md` → ≥4 wiersze tabeli Alternatives.

---

## Krok 4: Napisz ADR-002 IaC + ADR-003 Auth + ADR-004+ (zasada #15 pkt 17)

Dla każdego ADR — te same sekcje co ADR-001.

**ADR-002 IaC (Docker Compose + Caddy + B2):**
- Context: dlaczego Docker Compose vs Swarm/K3s
- Alternatives: Swarm (overkill single-host), K3s (overkill), Nomad (sztabowy ecosystem)

**ADR-003 Auth + TOTP:**
- Context: single-user, audit-ready OWASP ASVS L2, TOTP requirement
- Alternatives: Auth.js v5 (więcej deps, magia), Keycloak (overkill single-user)
- Decision: iron-session + bcryptjs + optional TOTP (feature flag)

**ADR-004 PDF engine:**
- Context: PL typografia, determinizm, deadline
- Alternatives: Puppeteer (Chromium bloat +200MB, niedeterministyczny PL fonts), pdf-lib (boilerplate)

---

## Krok 5: Wypełnij threat-model.md (zasada #15 pkt 14)

Użyj `templates/threat-model-template.md`.

**Metodologia STRIDE per komponent:**
1. Lista komponentów projektu (app / db / proxy / backup / ci-cd)
2. Dla każdego komponentu × 6 STRIDE threats:
   - Przypisz poziom: **H/M/L**
   - Opisz konkretny scenariusz ataku (1 zdanie)
   - Wymień ≥2 mitigations z referencjami do kodu lub ADR

**Typowy czas:** ~2-3h dla pełnego threat-model (30 cells)

**Priorytet:** zacznij od HIGH threats (H w matrix) — te wymagają konkretnych mitigations przed audytem.

**Weryfikacja:** każdy cell w tabeli STRIDE matrix zawiera H/M/L + krótki opis (nie puste).

---

## Krok 6: Napisz SECURITY.md (zasada #15 pkt 13)

Użyj `templates/SECURITY.md.template`.

**Krytyczne sekcje:**
1. **GPG key** — wygeneruj klucz jeśli nie ma: `gpg --full-gen-key` → publikuj na keys.openpgp.org
2. **Rotation cadence** — wypełnij konkretnymi datami (nie "quarterly" ogólnie, ale "Jan/Apr/Jul/Oct")
3. **Supported versions** — dla single-user: "latest only, no legacy support"
4. **Known limitations** — wypełnij szczerze (np. TOTP optional w v1)

**Czas:** ~45 min

---

## Krok 7: Napisz runbook.md (zasada #15 pkt 15)

Użyj `templates/runbook.md.template`.

**Kluczowe sekcje do weryfikacji:**
1. **Pre-deploy checklist** — czy masz wszystkie 10 checks? Dodaj projekt-specificzne.
2. **Manual deploy** — testuj komendy na dev/staging PRZED wpisaniem do runbooka
3. **Rollback** — przetestuj rollback procedure raz ręcznie na dev zanim zapiszesz
4. **Restore from B2** — masz restore drill skrypt z `webapp-backup-dr`? Połącz.

**Zasada:** każda komenda w runbooku MUSI być przetestowana. "Runbook untested is not a runbook."

**Czas:** ~2h (włącznie z testowaniem komend)

---

## Krok 8: Napisz IR-procedure.md (zasada #15 pkt 16)

Użyj `templates/IR-procedure.md.template`.

**Krytyczne:**
- SLA numbers MUSZĄ być realistyczne dla twojego kontekstu (single-developer vs team)
- Post-mortem template — wypełnij przykładowo jeden "fikcyjny" incydent, żeby Jan wiedział czego się spodziewać
- Communication: konkretny kontakt do Jana (telefon/email z jego strony)

**Czas:** ~1h

---

## Krok 9: Utwórz CHANGELOG.md (zasada #15 pkt 18)

Użyj `templates/CHANGELOG.md.template`.

**Checklist:**
- `## [Unreleased]` sekcja na górze
- `## [1.0.0] - YYYY-MM-DD` wypełniony z konkretną listą Added + Security
- Security entries MUSZĄ zawierać: TLS, CSP, security headers, backup, scanning tools

**Czas:** ~30 min

---

## Krok 10: Weryfikacja zero-placeholder i audit-ready gate

```bash
# Krok 1: Zero-placeholder check
grep -rn '{{[A-Z_]*}}' docs/ SECURITY.md CHANGELOG.md
# Oczekiwane: 0 wyników

# Krok 2: Zero TBD/TODO
grep -rn '\[TBD\]\|// TODO:\|<placeholder>' docs/ SECURITY.md CHANGELOG.md
# Oczekiwane: 0 wyników

# Krok 3: ADR count (minimum 3)
ls docs/adr/ADR-*.md | wc -l
# Oczekiwane: ≥3

# Krok 4: STRIDE matrix complete
grep -c "| **" docs/threat-model.md
# Oczekiwane: ≥5 (5 komponentów)

# Krok 5: Runbook ma komendy (nie abstrakcyjne kroki)
grep -c "docker\|curl\|ssh\|kubectl" docs/runbook.md
# Oczekiwane: ≥10 konkretnych komend

# Krok 6: IR-procedure ma SLA numbers
grep -E "[0-9]h" docs/IR-procedure.md | head -5
# Oczekiwane: ≥3 SLA entries (Down 2h/8h, Degraded 4h/24h, Security 1h)

# Krok 7: CHANGELOG format
head -5 CHANGELOG.md
# Oczekiwane: "# Changelog" + "## [Unreleased]"
```

**Jeśli wszystko PASS → zasada #15 pkt 13-18 spełniona.**

---

## Estymacja czasu produkcji kompletnych docs

| Dokument | Czas (z briefem) | Czas (bez briefu) |
|---|---|---|
| ADR-001 Stack | 30 min | 90 min |
| ADR-002 IaC | 20 min | 60 min |
| ADR-003 Auth+TOTP | 20 min | 60 min |
| ADR-004 PDF engine | 15 min | 45 min |
| threat-model.md | 2-3h | 4-5h |
| SECURITY.md | 45 min | 90 min |
| runbook.md (z testami) | 2h | 3h |
| IR-procedure.md | 1h | 2h |
| CHANGELOG.md | 30 min | 45 min |
| **TOTAL** | **~8-9h** | **~15-18h** |

**Skrót z briefem:** te templates + brief  = ~6-7h realnie (Opus heavy, ale konkretne dane gotowe).
