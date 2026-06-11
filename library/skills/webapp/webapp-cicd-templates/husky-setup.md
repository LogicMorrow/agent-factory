# Husky + lint-staged + commitlint — setup

Pre-commit hooks wymuszajace lint + typecheck na staged plikach oraz Conventional Commits przed kazda zmiana.

## Instalacja

```bash
pnpm add -D husky lint-staged @commitlint/cli @commitlint/config-conventional
pnpm exec husky init
```

`husky init` tworzy `.husky/` z przykladowym pre-commit hookiem.

## pre-commit hook

Zamien zawartosc `.husky/pre-commit`:

```sh
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

pnpm exec lint-staged
```

Lint-staged uruchamia tylko na staged plikach (szybko — nie cale repo).

## commit-msg hook

Utworz `.husky/commit-msg`:

```sh
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

pnpm exec commitlint --edit "$1"
```

## .lintstagedrc.json

Utowrz w root projektu:

```json
{
  "*.{ts,tsx}": ["eslint --max-warnings 0", "tsc-files --noEmit"],
  "*.{ts,tsx,js,jsx,json,md}": ["prettier --write"]
}
```

`tsc-files` sprawdza typecheck tylko na zmienionych plikach (szybciej niz `tsc --noEmit` na calym projekcie).

Instalacja `tsc-files` jesli nie masz: `pnpm add -D tsc-files`

## package.json scripts

Dodaj/zaktualizuj `scripts` w `package.json`:

```json
{
  "scripts": {
    "lint": "eslint . --max-warnings 0",
    "lint:fix": "eslint . --fix",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "test:coverage": "vitest run --coverage",
    "test:watch": "vitest",
    "build": "next build",
    "prepare": "husky"
  }
}
```

`"prepare": "husky"` — automatyczna inicjalizacja hookow po `pnpm install` (np. po `git clone`).

## Weryfikacja

```bash
# Test pre-commit hook
echo "console.log('test')" >> src/test-file.ts
git add src/test-file.ts
git commit -m "test"
# Powinien uruchomic lint-staged

# Test commit-msg hook
git commit --allow-empty -m "invalid commit message without type"
# Powinno zwrocic blad commitlint

# Prawidlowy commit
git commit --allow-empty -m "chore: test commitlint setup"
# Powinno przejsc
```

## Czeste problemy

**Hook nie uruchamia sie:**
- Sprawdz uprawnienia: `chmod +x .husky/pre-commit .husky/commit-msg`
- Sprawdz czy husky zainstalowany: `ls -la .git/hooks/`

**lint-staged zawiesza sie na typecheck:**
- `tsc --noEmit` na duzym projekcie moze byc wolny — uzyj `tsc-files` lub ogranicz do `lint` w staged, a `typecheck` uruchamiaj tylko w CI

**pnpm prepare nie dziala w CI:**
- Dodaj do CI `env: HUSKY: 0` zeby pominac inicjalizacje hookow w GitHub Actions (hooks dzialaja lokalnie, nie w CI runner)

```yaml
# ci.yml — dodaj do kazdego job env
env:
  HUSKY: 0
```
