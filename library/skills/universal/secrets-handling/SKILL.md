---
name: secrets-handling
version: "1.0.0"
type: skill
category: universal
description: "Use when working in a project with .env file present, handling Docker Compose configurations, environment variables, or any task involving secrets/credentials. Prevents env interpolation leaks to chat context."
compatible_with: [universal]
requires: []
tags: [security, secrets, env, docker-compose, universal]
token_cost: medium
files:
  - SKILL.md
  - examples.md
  - rotation-procedure.md
---

# secrets-handling

Skill zapobiegający wyciekom wartosci sekretow do context window konwersacji Claude.
Powstal po incydencie 2026-05-06 (CRM, 8x rotacja `POSTGRES_PASSWORD` w jednej sesji).

## 1. Kiedy uruchomic

**Uruchamiaj gdy:**
- w cwd projektu istnieje plik `.env`
- planujesz komende dotyczaca plikow `.env*` lub `docker-compose*.yml`
- uzytkownik pyta o zmienne srodowiskowe, sekrety, credentials
- hook `block-env-leak.sh` zablokował komende

**NIE uruchamiaj gdy:**
- projekt nie ma zadnych sekretow (czysty frontend bez API keys)
- pracujesz w srodowisku testowym z wylacznie placeholderami (`.env.example`)

---

## 2. Trzy warstwy obrony

```
Warstwa 1 — SKILL (intencja)
  Ten plik. Wiedza wstrzyknieta do context window — Claude zna zasady
  i NIE proponuje zakazanych komend zanim jakikolwiek hook sie uruchomi.

Warstwa 2 — block-env-leak.sh (PRE-execution)
  PreToolUse hook, matcher: Bash. Blokuje komende zanim zostanie
  wykonana, gdy .env istnieje w cwd. Exit 2 + komunikat do Claude.
  Plik: library/hooks/block-env-leak.sh

Warstwa 3 — post-bash-secrets-filter.sh (POST-execution)
  PostToolUse hook, matcher: Bash. Skanuje stdout/stderr legalnych
  komend (np. docker logs) pod katem sekretow. Blokuje wynik zanim
  trafi do context window.
  Plik: library/hooks/post-bash-secrets-filter.sh

Warstwa 4 — pre-git-commit-no-env.sh (GIT-TIME)
  PreToolUse hook, matcher: Bash dla git commit. Blokuje commit
  jesli w staged files jest .env, klucz PEM, AWS credentials, kubeconfig
  lub GCP service-account JSON. Whitelist dla .env.example/.env.sample/
  .env.template oraz public.pem.
  Plik: library/hooks/pre-git-commit-no-env.sh
```

**Zasada: kazda warstwa jest niezalezna.** Skill dziala bez hookow (edukacja).
Hooki dzialaja bez skilla (enforcement). Razem = defense-in-depth.

---

## 3. ZAKAZ — komendy blokowane

Kazda z ponizszych komend ROZWIJA wartosci zmiennych lub ujawnia zawartosc `.env`
do outputu, ktory trafia do context window.

| Komenda | Dlaczego niebezpieczna | Bezpieczna alternatywa |
|---|---|---|
| `docker compose config` | Inline'uje wszystkie `${VAR}` z `.env` do YAML output | `docker compose config --no-interpolate` |
| `cat .env` | Wyswietla caly plik ze wszystkimi wartosciami | `grep -c '^KEY=' .env` (liczy wpisy) |
| `head .env` / `tail .env` | Partial display ale wciaz ujawnia wartosci | `wc -l .env` (liczba linii) |
| `less .env` / `more .env` / `view .env` | Interaktywny widok pliku | `grep -c '^KEY=' .env` |
| `awk/sed/xxd/od/hexdump/strings .env` | Dump lub parsowanie zawartosci `.env` | Edycja przez `sed -i 's/^KEY=.*/KEY=new/'` (zapis, nie display) |
| `printenv` (bez argumentow) | Dump wszystkich zmiennych shell (po source lub inherit) | `printenv SPECIFIC_VAR_NAME` lub zapytaj uzytkownika |
| `env` (bez argumentow) | Jak printenv — dump calego srodowiska | `printenv SPECIFIC_VAR_NAME` |
| `source .env` / `. .env` | Importuje zmienne do shell; kolejne komendy moga leakowac | Nie sourcuj — uzyj `docker compose` ktore samo czyta `.env` |
| `node -e '...process.env...'` | Wyprowadza wartosci do stdout | Sprawdz konkretna zmiennad przez warunek (exit 0/1), nie print |
| `python -c '...os.environ...'` | Jak node — dump do stdout | `python -c 'import os; print(bool(os.environ.get("KEY")))'` |
| `git diff .env` / `git show .env` / `git log -p .env` | Moze pokazac tresc jesli `.env` jest tracked | Upewnij sie ze `.env` jest w `.gitignore` |
| Obejscie hooka po blokadzie | Kazde obejscie = cela obrony nieaktywna | Przeczytaj message hooka i uzyj alternatywy z tabeli NAKAZ |

---

## 4. NAKAZ — bezpieczne alternatywy

| Cel | Bezpieczna komenda | Uwagi |
|---|---|---|
| Sprawdz strukture docker-compose | `docker compose config --no-interpolate` | Literalne `${VAR}` bez podstawienia |
| Sprawdz strukture compose (parse-only) | `yq eval '.services' docker-compose.yml` | yq nie czyta `.env`, zero expansion |
| Sprawdz czy klucz istnieje w `.env` | `grep -c '^POSTGRES_PASSWORD=' .env` | Zwraca 1 lub 0, NIE wartosc |
| Sprawdz liczbe linii `.env` | `wc -l .env` | Bezpieczne — metadane |
| Zaktualizuj wartosc w `.env` | `sed -i 's/^KEY=.*/KEY=nowa-wartosc/' .env` | Zapis in-place, nie wyswietla |
| Sprawdz konkretna zmienna | Zapytaj uzytkownika przez out-of-band channel | Claude nie powinien widziec wartosci |
| Debug containera (logi) | `docker logs --tail 20 container_name` | Uwaga: logi moga zawierac sekrety — warstwa 3 skanuje |
| Sprawdz jakie serwisy sa zdefiniowane | `yq eval '.services | keys' docker-compose.yml` | Safe — tylko nazwy kluczy |
| Sprawdz port lub image | `yq eval '.services.postgres.image' docker-compose.yml` | Safe — nie czyta env wartosci |

---

## 5. Decision tree — 3 najczestsze potrzeby

```
Chce zobaczyc STRUKTURE docker-compose
  └─ Tylko serwisy/sieci/volumes (nie wartosci)?
       ├─ TAK → yq eval '.services' docker-compose.yml
       └─ NIE, potrzebuje pelnego YAML z wartosciami →
            docker compose config --no-interpolate
            (albo: skopiuj compose do /tmp bez .env, tam config)

Chce SPRAWDZIC zmienną srodowiskowa
  └─ Czy wiem co sprawdzam (nazwa klucza)?
       ├─ TAK (sprawdzam istnienie) → grep -c '^KEY=' .env
       ├─ TAK (aktualizuje wartosc) → sed -i 's/^KEY=.*/KEY=val/' .env
       └─ NIE (chce wartosc) → zapytaj uzytkownika out-of-band
                               (NIE uzywaj cat/printenv)

Chce DEBUGOWAC container
  └─ docker logs --tail 50 container_name
     (post-bash-secrets-filter.sh skanuje stdout — jesli sekret
      pojawi sie w logach, hook zablokuje i zapyta o rotacje)
  └─ docker inspect container_name | yq '.[] | .Config.Env | keys'
     (pokazuje NAZWY zmiennych, nie wartosci)
```

---

## 6. Co robic gdy hook blokuje

1. **Przeczytaj message hooka** — `block-env-leak.sh` w komunikacie podaje konkretna bezpieczna alternatywe. Nie ignoruj.
2. **Wybierz alternatywe z tabeli NAKAZ** (sekcja 4 tego skilla) lub z message hooka.
3. **Jesli blokada jest falszywa (false-positive):** NIE pomijaj hooka (`--no-verify`, modyfikacja JSON). Zamiast tego — zglos aktualizacje `ALLOWED_PATTERNS` w `block-env-leak.sh`. Wzorzec: otwórz hook, dodaj regex do tablicy `ALLOWED_PATTERNS`, uzasadnij komentarzem.

**Nigdy nie szukaj obejscia hooka. Hook jest celowy.**

---

## 7. Co robic gdy sekret JUZ widac w chacie

Jesli wartosc sekretu pojawiła sie w oknie konwersacji (mimo hookow lub w sesji bez hookow):

1. Nie kontynuuj sesji na tym sekrecie — traktuj go jako skompromitowany.
2. Uruchom procedure rotacji: `library/skills/universal/secrets-handling/rotation-procedure.md`
3. Kolejnosc: identyfikuj sekrety → rotuj → invalidate sesji JWT → update `.env` → restart compose → log incident.
4. Dopiero po rotacji wznow prace.

Skrocone komendy w `rotation-procedure.md` — kopiuj-wklejaj, nie szukaj po dokumentach.

---

## 8. Czego skill NIE robi

- **Nie jest hookiem** — nie blokuje wykonania komendy. Blokuje `block-env-leak.sh` (warstwa 2).
- **Nie pokrywa POST-execution leaks samodzielnie** — to robi `post-bash-secrets-filter.sh` (warstwa 3). Skill tylko wzmiankuje warstwe 3.
- **Nie robi monitoringu ani auditu** — to terytorium `<your-org>/vps-security` (weekly-security-report, audit-monthly, fail2ban, WireGuard, SSH hardening). Skill linku do `vps-security/docs/05-INCIDENT-RESPONSE.md` jako external reference.
- **Nie definiuje nowych standardow rotacji per-service** — `rotation-procedure.md` zawiera generyczne komendy z disclaimerem "verify against project card".
- **Nie zastepuje security-monitoring** — wykryte incydenty sa logowane do `.claude/security-incidents.log` przez hook, dalszy audyt = vps-security.

---

## 9. Antywzorce

| Antywzorzec | Ryzyko | Poprawka |
|---|---|---|
| `docker compose config` bez `--no-interpolate` | Wszystkie sekrety w stdout → context window | Dodaj `--no-interpolate` lub uzyj `yq` |
| `source .env` przed komenda diagnostyczna | Shell dziedziczy env; kazdy `printenv` po tym leakuje | Nie sourcuj; uruchom komende przez compose |
| `cat .env` "tylko zeby sprawdzic strukture" | "Tylko" nie istnieje — wartosc i tak trafia do okna | `grep -c '^KEY=' .env` pokazuje czy klucz istnieje |
| Szukanie obejscia po blokadzie hooka | Omijasz warstwe 2, ryzykujesz leak | Czytasz message hooka, uzywasz alternatywy |
| Commit `.env` "tymczasowo" | Sekret w historii git — nawet po usunieciu widoczny przez `git log -p` | Zawsze `.gitignore` dla `.env`; jesli juz committed: BFG Repo Cleaner |
| `node -e 'console.log(process.env)'` w debug | Caly env w stdout → context window | Sprawdz konkretna flage: `node -e 'process.exit(process.env.KEY ? 0 : 1)'` |

---

## 10. Powiązania

- **`block-env-leak.sh`** (`library/hooks/block-env-leak.sh`) — warstwa 2 (PRE-execution enforcement). Instalacja w projekcie: patrz nagłowek pliku hooka.
- **`post-bash-secrets-filter.sh`** (`library/hooks/post-bash-secrets-filter.sh`) — warstwa 3 (POST-execution skan). Komplementarny do block-env-leak.sh.
- **`pre-git-commit-no-env.sh`** (`library/hooks/pre-git-commit-no-env.sh`) — warstwa 4 (GIT-TIME).
- **`rotation-procedure.md`** (`library/skills/universal/secrets-handling/rotation-procedure.md`) — co robic po incydencie.
- **`examples.md`** (`library/skills/universal/secrets-handling/examples.md`) — 7 case'ow zle vs dobrze.
- **`<your-org>/vps-security`** — monitoring, audyt, incident-response na poziomie serwera. Skill secrets-handling nie duplikuje tych zakresow.
- **`model-routing`** (`library/skills/universal/model-routing/`) — fundament doboru modeli w fabryce (wzmianka, nie twarda zaleznosc tego skilla).

---

## 11. Reference

- Incydent zrodlowy: 2026-05-06, external-crm  etap B2, 8x rotacja `POSTGRES_PASSWORD`
- Memory feedback (CRM): `~/.claude/projects/-project-app/memory/feedback_no_env_interpolation_commands.md`
- Masterplan fabryki: `knowledge-base/plans/` (2026-05-06),  sekrecty-handling
- vps-security incident response: `<your-org>/vps-security/docs/05-INCIDENT-RESPONSE.md`
