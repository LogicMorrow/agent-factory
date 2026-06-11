# Secrets Management — sops + age

Default dla self-hosted (VPS, własny Docker). Cel: `.env` zaszyfrowany at-rest, bezpieczny commit do repo.

---

## QUICKSTART (5 komend, ~5 minut)

```bash
# 1. Zainstaluj age (macOS: brew install age | Ubuntu: apt install age | lub https://github.com/FiloSottile/age/releases)
age --version

# 2. Wygeneruj klucz (1 klucz per developer/serwer)
age-keygen -o ~/.config/age/key.txt
# Output: Public key: age1xxxx...
# Zapisz public key — potrzebujesz go w .sops.yaml

# 3. Utwórz .sops.yaml w katalogu głównym projektu
cat > .sops.yaml << 'EOF'
creation_rules:
  - path_regex: \.env.*
    age: age1xxxx...   # ← wklej swój public key z kroku 2
EOF

# 4. Zaszyfruj istniejący .env
sops --encrypt .env > .env.sops.yaml
# Sprawdź: .env.sops.yaml powinien zawierać zaszyfrowane wartości

# 5. Dodaj do .gitignore i commit
echo ".env" >> .gitignore
git add .env.sops.yaml .sops.yaml .gitignore
git commit -m "chore: encrypt secrets with sops+age"
# Teraz .env.sops.yaml jest bezpieczny w repo, .env lokalnie NIE jest w repo
```

Instalacja sops: https://github.com/getsops/sops/releases

---

## Retrofit (istniejący projekt)

### Sytuacja wyjściowa
`.env` z wartościami jest (lub był) w repozytorium, brak szyfrowania.

### Krok 1 — sprawdź czy .env jest w git historii

```bash
git log --all --full-history -- .env
# Jeśli są wyniki → .env był w repo → patrz "Czyszczenie historii" poniżej
```

### Krok 2 — quickstart powyżej (kroki 1-5)

### Krok 3 — odszyfruj do pracy lokalnie

```bash
# Odszyfruj do lokalnego .env (tylko na dev/serwer z kluczem)
export SOPS_AGE_KEY_FILE=~/.config/age/key.txt
sops --decrypt .env.sops.yaml > .env
```

Dodaj do skryptów `package.json`:

```json
{
  "scripts": {
    "secrets:decrypt": "sops --decrypt .env.sops.yaml > .env",
    "secrets:encrypt": "sops --encrypt .env > .env.sops.yaml"
  }
}
```

### Czyszczenie historii (gdy .env był w repo)

```bash
# UWAGA: rewrite historii — koordynuj z zespołem przed wykonaniem
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all

git push origin --force --all
# Wszyscy współpracownicy muszą: git fetch --all && git reset --hard origin/main
```

Po wyczyszczeniu: zmień WSZYSTKIE sekrety które były w repozytorium (JWT_SECRET, hasła DB, klucze API).

---

## New project (greenfield)

Wykonaj quickstart PRZED pierwszym commitem. Zasada: `.env` nigdy nie wchodzi do repo.

---

## Multi-recipient (team)

Każdy developer i serwer produkcyjny ma własny klucz. Wszyscy muszą być w `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: \.env.*
    age: >-
      age1operator...,
      age1developer2...,
      age1vps-prod...
```

Każda z wymienionych osób może odszyfrować plik własnym kluczem.

Po dodaniu nowego developera:
```bash
# 1. Developer generuje klucz (krok 2 quickstart)
# 2. Wysyła public key do operatora
# 3. operator dodaje do .sops.yaml + re-encrypt
sops --rotate --add-age age1newdev... .env.sops.yaml
```

---

## Rotacja klucza age

Gdy klucz jest skompromitowany lub developer odchodzi z projektu:

```bash
# 1. Każdy pozostały developer generuje nowy klucz (lub stary jest OK)
# 2. Zaktualizuj .sops.yaml (usuń stary public key, dodaj nowy)
# 3. Re-encrypt z nowym zestawem odbiorców
sops --rotate .env.sops.yaml
# 4. Commit zaktualizowanego .env.sops.yaml
git add .env.sops.yaml .sops.yaml
git commit -m "chore: rotate age keys — remove [imie] access"
# 5. Jeśli klucz był skompromitowany: zmień wartości sekretów (nowe JWT_SECRET, hasła)
```

---

## Troubleshooting

**`Error: no matching creation rules found`**
- Sprawdź czy `.sops.yaml` jest w katalogu z którego wywołujesz sops.
- Sprawdź `path_regex` — `\.env.*` matchuje `.env`, `.env.local`, `.env.production`.

**`Error: failed to get the data key required to decrypt the SOPS file`**
- Klucz prywatny nie jest dostępny.
- Sprawdź: `echo $SOPS_AGE_KEY_FILE` — powinno wskazywać na plik z `AGE-SECRET-KEY`.
- Sprawdź uprawnienia: `chmod 600 ~/.config/age/key.txt` — klucz musi być dostępny tylko dla właściciela.

**`Error: AGE-SECRET-KEY not found`**
- Ustaw zmienną środowiskową: `export SOPS_AGE_KEY_FILE=~/.config/age/key.txt`
- Lub: `export SOPS_AGE_KEY=$(cat ~/.config/age/key.txt)`
- Dodaj do `~/.bashrc` lub `~/.zshrc` żeby było persistentne.

**Utrata klucza prywatnego (recovery)**
- Bez klucza prywatnego nie ma recovery z zaszyfrowanego pliku.
- Prewencja: trzymaj kopię klucza w bezpiecznym miejscu (password manager — 1Password, Bitwarden).
- Jeśli klucz utracony a nie masz backupu: odtwórz sekrety z innych źródeł (panel hosting, email od providera API) i re-encrypt z nowym kluczem.

**Plik `.env.sops.yaml` w repo ale nikt nie może odszyfrować**
- Sprawdź czy public key w `.sops.yaml` zgadza się z private key w `~/.config/age/key.txt`.
- `age-keygen -y ~/.config/age/key.txt` wypisuje public key z private key file.

---

## Alternatywy SaaS (wzmianka)

Dla projektów z większym teamem lub wymaganiami enterprise:

- **dotenv-vault** (https://www.dotenv.org/) — darmowy do 3 projektów, CLI podobne do sops. Przechowuje zaszyfrowane sekrety w chmurze dotenv.
- **Doppler** (https://www.doppler.com/) — enterprise-grade, GUI, RBAC, auditlog, integracja z CI/CD. Płatny powyżej 5 projektów.
- **HashiCorp Vault** (https://www.vaultproject.io/) — self-hosted, bardzo rozbudowany, overdone dla single-VPS projektu.

Default (ten skill): sops+age — zero external dependency, zero vendor lock-in, działa offline, open source.

---

## Antywzorce

- ❌ `.env` w repozytorium bez `.gitignore` — najczęstszy błąd, patrz checklist security.md.
- ❌ Jeden klucz age dla całego zespołu — rotacja klucza wymaga re-generacji dla wszystkich.
- ❌ Brak backupu klucza prywatnego — utrata klucza = utrata dostępu do sekretów.
- ❌ `SOPS_AGE_KEY` z pełnym kluczem jako env var w CI bez maskowania — klucz widoczny w logach.
- ❌ Re-encrypt bez zmiany wartości sekretów po kompromitacji — nowy klucz nie pomaga jeśli wartości wyciekły.

## Oficjalne docs

- sops: https://github.com/getsops/sops
- age: https://github.com/FiloSottile/age
- sops + age tutorial: https://github.com/getsops/sops#encrypting-using-age
