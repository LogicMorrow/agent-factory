# injection-template — cross-agent-learning

Gotowy boilerplate sekcji "## Before starting work" do wklejenia w body agenta.
Wstaw jako PIERWSZY krok workflow agenta (krok 0) — przed dotychczasowym krokiem 1.

---

## Instrukcja uzytkownika

1. Skopiuj odpowiedni wariant (Full / Haiku-trim / Custom) do pliku agenta
2. Zamien `{this-agent-name}` na nazwe agenta (kebab-case, dokladnie jak w frontmatter `name:`)
3. Wstaw sekcje jako krok 0 — przed numerowanym krokiem "1." w sekcji workflow agenta
4. Bump version w frontmatterze (+0.0.1) i dodaj wpis w changelogu
5. Commit: `feat({agent-name}): retrofit pre-execution context loading (E2 cross-agent-learning)`

---

## Wariant A — Full (opus / sonnet)

Dla agentow z modelem opus lub sonnet. Czyta 3 zrodla, max 5k tokenow pre-context.

```markdown
## Before starting work

<!-- cross-agent-learning E2: pre-execution context loading, model=opus|sonnet, full mode -->
<!-- Zamien {this-agent-name} na nazwe agenta (np. code-implementer) -->

Przed przystapnieniem do zadania wlasciwego wykonaj krok 0:

**Krok 0 — Wczytaj kontekst historyczny (apply silently):**

1. Czytaj `.claude/memory/errors-{this-agent-name}.md` (full) — jesli plik nie istnieje, skip cicho
2. Czytaj 3 najnowsze reflections:
   - `Glob: knowledge-base/reflections/{this-agent-name}*.md` (sort desc, head 3)
   - `Read` kazdy znaleziony plik
   - Jesli glob zwraca 0 wynikow: skip cicho
3. Czytaj `knowledge-base/lessons.jsonl` — tail 20 wierszy

**Budget:** lacznie max ~5 000 tokenow. Jesli przekroczone — pomijaj w kolejnosci:
lessons.jsonl najpierw, potem ogranicz reflections do 1 (najnowszej), errors-{name}.md nigdy nie pomijaj.

**Apply silently:** nie wypisuj co wczytalas/es. Stosuj wnioski cicho w dalszych krokach.
Wzmianka w outputcie TYLKO gdy decyzja faktycznie sie zmienia vs default — 1 zdanie z referencja
(data lesson lub sciezka pliku reflection). Przyklad: "Pomijam X — ref: lessons.jsonl 2026-04-23."
```

---

## Wariant B — Haiku-trim (haiku)

Dla agentow z modelem haiku. Czyta tylko errors-{name}.md, max 1 500 tokenow.

```markdown
## Before starting work

<!-- cross-agent-learning E2: pre-execution context loading, model=haiku, trim mode -->
<!-- Zamien {this-agent-name} na nazwe agenta (np. mistake-recorder) -->

Przed przystapnieniem do zadania wlasciwego wykonaj krok 0:

**Krok 0 — Wczytaj historyczne bledy (apply silently):**

1. Czytaj `.claude/memory/errors-{this-agent-name}.md` (full, max 1 500 tokenow)
   - Jesli plik nie istnieje: skip cicho, przejdz do kroku 1

**Apply silently:** nie wypisuj zawartosci pliku. Stosuj wnioski cicho.
Wzmianka TYLKO gdy decyzja sie zmienia — 1 zdanie z referencja do pliku i daty wpisu.
```

---

## Wariant C — Custom (override budgetu lub filtrowanie lessons)

Gdy agent potrzebuje zawezenia scope lessons (np. tylko lessons dla danego projektu).

```markdown
## Before starting work

<!-- cross-agent-learning E2: pre-execution context loading, custom mode -->
<!-- Zamien {this-agent-name} i dostoswuj parametry ponizej do potrzeb agenta -->

Przed przystapnieniem do zadania wlasciwego wykonaj krok 0:

**Krok 0 — Wczytaj kontekst historyczny (apply silently):**

1. Czytaj `.claude/memory/errors-{this-agent-name}.md` (full) — skip jesli brak
2. Czytaj 3 najnowsze reflections:
   - `Glob: knowledge-base/reflections/{this-agent-name}*.md` (sort desc, head 3)
   - `Read` kazdy znaleziony plik — skip jesli 0 wynikow
3. Czytaj `knowledge-base/lessons.jsonl` tail 20
   <!-- CUSTOM: mozesz zawezic do lessons gdzie "project":"<projekt>" przez Grep/Read + filter -->
   <!-- CUSTOM: mozesz zmienic tail 20 na inne N wedlug potrzeb agenta -->

**Budget:** <!-- CUSTOM: zdefiniuj limit tokenow per potrzeby agenta, domyslnie 5k -->

**Apply silently:** stosuj wnioski cicho. Wzmianka z referencja gdy decyzja sie zmienia.
```

---

## Pelny przyklad — code-implementer z Wariantem A

Ponizej fragment body agenta `code-implementer.md` PO retroficie:

```markdown
## Workflow

## Before starting work

<!-- cross-agent-learning E2: pre-execution context loading, model=opus, full mode -->

Przed przystapnieniem do zadania wlasciwego wykonaj krok 0:

**Krok 0 — Wczytaj kontekst historyczny (apply silently):**

1. Czytaj `.claude/memory/errors-code-implementer.md` (full) — skip jesli brak
2. Czytaj 3 najnowsze reflections:
   - `Glob: knowledge-base/reflections/code-implementer*.md` (sort desc, head 3)
   - `Read` kazdy znaleziony plik — skip jesli 0 wynikow
3. Czytaj `knowledge-base/lessons.jsonl` — tail 20 wierszy

**Budget:** max ~5 000 tokenow lacznie. Trim: pominij lessons najpierw, potem ogranicz reflections.
**Apply silently:** wnioski stosuj cicho. Wzmianka + referencja tylko przy zmianie decyzji.

## 1. Przeczytaj brief i karte projektu
...
```

---

## Notatki o pozycjonowaniu

- Sekcja "## Before starting work" musi byc PRZED numerowanym krokiem "## 1." lub "**Krok 1**"
- Jesli agent ma sekcje "## Workflow" z numerowanymi krokami — wstaw sekcje przed krokiem 1 (nie w srodku)
- Jesli agent nie ma sekcji workflow (jest plaska lista krokow) — wstaw na poczatku ciala agenta

**Blad pozycjonowania — ❌ zle:**
```markdown
## 1. Czytaj brief
## 2. Analizuj
## Before starting work   <-- za pozno, po krokach wlasciwych
## 3. Pisz output
```

**Poprawna kolejnosc — ✅ dobrze:**
```markdown
## Before starting work   <-- krok 0, przed wszystkim
## 1. Czytaj brief
## 2. Analizuj
## 3. Pisz output
```
