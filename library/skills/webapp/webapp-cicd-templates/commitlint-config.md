# commitlint — konfiguracja

Conventional Commits enforcement przez commitlint.

## commitlint.config.cjs

Utowrz w root projektu (`.cjs` — dziala z ESM i CJS projektami):

```js
// commitlint.config.cjs
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Dozwolone typy commitow
    'type-enum': [
      2,
      'always',
      [
        'feat',     // nowa funkcjonalnosc
        'fix',      // naprawa buga
        'docs',     // zmiany dokumentacji
        'chore',    // task maintenance (deps, config)
        'refactor', // refaktoring bez zmiany zachowania
        'test',     // testy
        'perf',     // optymalizacja wydajnosci
        'ci',       // zmiany w CI/CD
        'build',    // system budowania, deps zewnetrzne
        'revert',   // cofniecie poprzedniego commita
        'style',    // formatowanie, brakujace sredniki (nie logika)
      ],
    ],
    // Scope opcjonalny, free-form (nie ograniczamy listy)
    'scope-case': [0], // wylewczony
    // Naglowek max 100 znakow
    'header-max-length': [2, 'always', 100],
    // Body max 100 znakow per linia
    'body-max-line-length': [2, 'always', 100],
    // Typ zawsze lowercase
    'type-case': [2, 'always', 'lower-case'],
    // Temat nie konczy sie kropka
    'subject-full-stop': [2, 'never', '.'],
  },
};
```

## Przyklady

```bash
# Prawidlowe
feat: add user authentication
fix(auth): handle expired JWT token
docs: update README deployment section
chore(deps): bump next to 15.2.0
refactor(api): extract validation to middleware
ci: add Node 22 to test matrix

# Nieprawidlowe — blad commitlint
Added new feature              # brak typu
feat: Add user auth.           # kropka na koncu
FEAT: add auth                 # typ nie lowercase
update: change something       # nieznany typ "update"
```

## Integracja z commitlint.config.mjs (ESM)

Jesli projekt uzywa `"type": "module"` w package.json, musisz uzyc formatu `.mjs` lub `.js` z named export:

```js
// commitlint.config.mjs (ESM)
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // ... te same reguly
  },
};
```

Lub zachowaj `.cjs` (dziala w obu trybach).

## Weryfikacja konfiguracji

```bash
echo "feat: test commit" | pnpm exec commitlint
# Brak bledu = OK

echo "invalid commit" | pnpm exec commitlint
# Powinno zwrocic blad type-empty
```

## Powiazania

Commitlint egzekwowany przez commit-msg hook — patrz [`husky-setup.md`](husky-setup.md).
