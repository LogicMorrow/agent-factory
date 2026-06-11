# ADR ↔ Runbook Pairing — Reguła i Przykłady

## Reguła

**ADR z `kind: infrastructure` MUSI mieć ≥1 powiązany runbook** w polu `related`.

Dlaczego: decyzja infrastrukturalna (wybór Redis, storage, deploy target) bez procedury obsługi awarii jest niepełna. "Zdecydowaliśmy użyć Redis" bez "co robimy gdy Redis padnie" = ukryty dług.

**Wymagany runbook:** `<komponent>-down.md` LUB `<komponent>-degraded.md` (dla usług z graceful degradation).

Egzekwowanie: CI soft gate `docs-lint` ostrzega gdy ADR `kind: infrastructure` nie ma runbooka w `related`. Hard gate nie blokuje — daje czas na napisanie runbooka.

---

## Przykład 1: Redis jako pub/sub

**ADR:** `docs/adr/0003-redis-pubsub.md`
```yaml
---
kind: infrastructure
related: ["../runbooks/redis-down.md", "../runbooks/redis-degraded.md"]
---
```

**Runbook wymagany:** `docs/runbooks/redis-down.md`
- severity: p0 (WebSocket przestaje działać dla wszystkich)
- Procedura: diagnoza → restart → weryfikacja → rollback do polling jeśli Redis niedostępny
- Rollback: przełączenie frontendu na long-polling (feature flag `USE_WEBSOCKET=false`)

**Runbook opcjonalny:** `docs/runbooks/redis-degraded.md`
- severity: p1 (degradacja — WebSocket wolny, ale działa)
- Procedura: skalowanie Redis, czyszczenie expired sessions

---

## Przykład 2: PostgreSQL — wybór jako główna baza

**ADR:** `docs/adr/0001-postgresql-storage.md`
```yaml
---
kind: infrastructure
related: ["../runbooks/pg-down.md", "../runbooks/pg-migration-rollback.md"]
---
```

**Runbooki wymagane:**
- `docs/runbooks/pg-down.md` (severity: p0 — aplikacja nie działa bez DB)
- `docs/runbooks/pg-migration-rollback.md` (severity: p1 — rollback failed migration)

---

## Przykład 3: Deploy na VPS z Docker Compose

**ADR:** `docs/adr/0004-deploy-vps-docker.md`
```yaml
---
kind: infrastructure
related: ["../runbooks/deploy.md", "../runbooks/rollback.md", "../runbooks/vps-disk-full.md"]
---
```

**Runbooki wymagane:**
- `docs/runbooks/deploy.md` (hard rule — deploy zawsze ma runbook)
- `docs/runbooks/rollback.md` (hard rule — rollback zawsze ma runbook)

**Runbook opcjonalny ale rekomendowany:**
- `docs/runbooks/vps-disk-full.md` (severity: p1 — prod może paść przez pełny disk)

---

## Wyjątki — kiedy ADR `kind: infrastructure` bez runbooka jest OK

1. **Runbook istnieje ale w innym repo** — dodaj zewnętrzny link w `related` i komentarz dlaczego.
2. **Usługa zewnętrzna bez możliwości mitigacji** — np. ADR "użyjemy Resend SMTP" — gdy Resend padnie, nic nie możemy zrobić lokalnie. W ADR zaznacz: `related: []` + uwaga w Consequences: "Brak runbooka — zewnętrzna usługa SaaS, brak kontroli. Plan B: fallback do alternatywnego providera (patrz ADR-NNNN)".
3. **ADR `kind: code | process | security`** — reguła nie dotyczy, runbook opcjonalny.

---

## Jak oznaczyć powiązanie w obu kierunkach

**W ADR (`adr/0003-redis-pubsub.md`):**
```yaml
related: ["../runbooks/redis-down.md"]
```

**W Runbooku (`runbooks/redis-down.md`):**
```yaml
related_adrs: ["../adr/0003-redis-pubsub.md"]
```

Skrypt `validate-docs.sh` sprawdza czy ścieżki w `related` istnieją (hard gate #3 — broken internal links).
