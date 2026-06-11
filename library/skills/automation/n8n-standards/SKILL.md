---
name: n8n-standards
description: Kompletne standardy budowy automatyzacji n8n operatora — Docker, workflow, backup, security, webhooks, testy. Uruchamiaj przy każdej pracy nad projektem n8n lub automation-native.
---

# Standardy n8n — DemoTargi / LogicMorrow

## Podpliki (czytaj wg kontekstu)
- [`stack.md`](stack.md) — stos, wersje, kiedy n8n vs automation-native
- [`docker-compose.md`](docker-compose.md) — exact konfiguracja Docker + pułapki
- [`workflows.md`](workflows.md) — format dokumentacji workflow, specyfikacja webhooków
- [`backup.md`](backup.md) — dwa poziomy backup (baza + workflow export)
- [`security.md`](security.md) — N8N_ENCRYPTION_KEY, sekrety, HMAC, HTTPS
- [`testing.md`](testing.md) — 5 obowiązkowych scenariuszy testowych
- [`boilerplate.md`](boilerplate.md) — docker-compose.yml, .env.example, backup.sh

## 5 zasad które nigdy nie mają wyjątku
1. **PostgreSQL 16, nie SQLite** — SQLite łamie się przy restartach kontenerów. Zawsze.
2. **N8N_ENCRYPTION_KEY nigdy nie zmieniamy po wdrożeniu** — zmiana unieważnia wszystkie zaszyfrowane credentiale w n8n.
3. **HTTPS obowiązkowo na prod** — Nginx/Caddy + Let's Encrypt. HTTP = FAIL security review.
4. **Backup dwa poziomy** — pg_dump codziennie + n8n export:workflow tygodniowo (i przed każdą większą zmianą).
5. **Konkretny tag Docker** — `n8nio/n8n:1.70.0`, nigdy `latest`. Sprawdzaj aktualną stable na hub.docker.com/r/n8nio/n8n/tags.

## Powiązania
- Agenci: `n8n-bootstrapper`, `n8n-workflow-reviewer`, `n8n-pre-deploy-checker`
- Skills: `model-routing`, `webapp-standards/stack.md` (dla automation-native — identyczny TypeScript stack)
