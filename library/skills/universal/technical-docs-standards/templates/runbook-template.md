---
# Runbook front-matter — wypełnij wszystkie pola
title: "<Nazwa procedury, np. Redis Down — Recovery>"
severity: p1
# severity enum: p0 (krytyczny, cała platforma) | p1 (degradacja prod) | p2 (impact na użytkowników) | p3 (ostrzeżenie, brak immediate impact)
mttr_target: 30
# MTTR target w minutach — realistyczny czas od wykrycia do recovery
related_adrs: []
# przykład: ["../adr/0003-redis-pubsub.md"]
owner: "<team lub osoba, np. backend-team>"
last_updated: YYYY-MM-DD
---

# <Nazwa procedury>

<!-- Przykład: "Redis Down — Recovery Procedure" -->

---

## 1. Kiedy użyć

<!-- Konkretne symptomy i warunki triggera. Nie ogólniki. -->
<!-- Przykład: "Gdy Redis nie odpowiada na ping / aplikacja loguje 'ECONNREFUSED 6379' / alert z Uptime Kuma." -->

Uruchom ten runbook gdy:
- ...
- ...

NIE uruchamiaj gdy:
- ... (wskaż alternatywny runbook jeśli dotyczy)

---

## 2. Wymagania wstępne

<!-- Co musisz mieć przed startem. Linki do _shared-prerequisites.md jeśli dotyczy. -->

- [ ] Dostęp SSH do serwera — patrz [`_shared-prerequisites.md`](./_shared-prerequisites.md)
- [ ] Uprawnienia do `docker compose` na hoście
- [ ] ...

---

## 3. Procedura

<!-- Kroki numerowane. Każdy krok ma JEDEN cel. -->
<!-- Jeśli krok ma warianty — używaj if/then jawnie. -->
<!-- Komendy: zawsze w bloku kodu z shell prompt. -->

### Krok 1 — Diagnoza

```bash
# Sprawdź status kontenera
docker ps | grep redis

# Sprawdź logi
docker logs <redis-container-name> --tail 50
```

**Oczekiwane wyjście:** `... * Ready to accept connections`

Jeśli kontener nie istnieje → przejdź do Kroku 3.
Jeśli kontener działa ale aplikacja nie łączy → przejdź do Kroku 2.

### Krok 2 — <Opis>

```bash
# komenda
```

**Oczekiwane wyjście:** ...

### Krok 3 — <Opis>

```bash
# komenda
```

---

## 4. Weryfikacja sukcesu

<!-- Jak sprawdzić że procedura zadziałała? Konkretne komendy + oczekiwany output. -->

```bash
# Weryfikacja 1
redis-cli -h localhost ping
# oczekiwane: PONG

# Weryfikacja 2 — aplikacja łączy się z Redis
curl -s http://localhost:<port>/api/health | jq .redis
# oczekiwane: "ok"
```

Recovery uznany za sukces gdy: ...

---

## 5. Rollback

<!-- Co zrobić jeśli procedura nie zadziałała lub pogorszyła sytuację? -->

Jeśli Weryfikacja sukcesu nie przeszła po <N> próbach:

```bash
# rollback komendy
```

Następny krok: przejdź do sekcji Eskalacja.

---

## 6. Troubleshooting

<!-- FAQ — najczęstsze problemy podczas wykonania tej procedury. -->

| Problem | Możliwa przyczyna | Akcja |
|---------|-------------------|-------|
| `Error: ECONNREFUSED 6379` | Redis nie nasłuchuje na porcie | Sprawdź `redis.conf bind` i `protected-mode` |
| Kontener restartuje się w pętli | OOM (brak pamięci) | `docker stats` → sprawdź memory limit |
| ... | ... | ... |

---

## 7. Eskalacja *(opcjonalne)*

<!-- Kiedy escalować i do kogo. Pomiń sekcję jeśli nie dotyczy projektu. -->

Escaluj gdy:
- procedura nie przywróciła usługi w ciągu `mttr_target` minut
- widzisz oznaki utraty danych

Kontakt: ...
Kanał: ...

---

## 8. Linki

- ADR: [<tytuł>](<ścieżka do ADR>)
- Runbook powiązany: [<tytuł>](<ścieżka>)
- Dokumentacja zewnętrzna: ...

---

## Historia zmian

| Data | Autor | Zmiana |
|------|-------|--------|
| YYYY-MM-DD | <imię> | Pierwsze wydanie |
