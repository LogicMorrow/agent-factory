---
name: github-pages-deploy
description: Publikacja strony statycznej (HTML/CSS/JS) na GitHub Pages z własną domeną — repo public + Settings→Pages source main/root, plik CNAME, rekordy DNS (4× A na 185.199.108-111.153 + CNAME www→<user>.github.io), custom domain + Enable HTTPS, kolejność „domena na końcu", checklista pre-publish i weryfikacja propagacji DNS. Reusable dla każdej statycznej strony hostowanej na GH Pages. NIE pokrywa budowy strony (→ static-site-premium-patterns) ani deploymentu webapp na VPS (→ webapp-standards).
version: 1.0.0
compatible_with: [webapp, cli, automation, other]
tags: [github-pages, deployment, dns, custom-domain, static-site, https, cname]
requires: []
token_cost: low
distribution: library/skills/universal/
last_updated: 2026-06-06
---

# github-pages-deploy

Referencja: jak wystawić stronę statyczną na **GitHub Pages** z własną domeną, krok po kroku, bezpiecznie.
GH Pages = darmowy hosting statyczny (HTML/CSS/JS), wymaga **repo publicznego** (na darmowym planie) i daje
HTTPS na własnej domenie. Idealny pod wizytówki/portfolio/landingi bez backendu.

**Scope:** konfiguracja Pages, plik CNAME, rekordy DNS, custom domain, HTTPS, kolejność wdrożenia, weryfikacja.
**NIE pokrywa:** budowa HTML/CSS/JS (→ `static-site-premium-patterns`), deployment Next.js/Node na VPS
(→ `webapp-standards`), GitHub Actions CI dla SSG (opcjonalne, §6).

Pliki towarzyszące:
- `dns-records.md` — dokładne rekordy DNS (A + AAAA + CNAME) + konfiguracja u popularnych rejestratorów PL
- `pages-setup-checklist.md` — checklista wdrożenia od zera do `https://twojadomena.pl`

---

## 1. Kiedy uruchomić

Uruchom gdy: publikujesz stronę statyczną na GH Pages (§2), podpinasz własną domenę (§3-§4), włączasz HTTPS (§5),
diagnozujesz „domena nie działa / brak HTTPS" (§7). Kolejność wdrożenia jest istotna — patrz §2 zasada „domena na końcu".

NIE uruchamiaj: gdy aplikacja ma backend/DB/SSR — to nie pasuje do Pages, użyj VPS + `webapp-standards`.

---

## 2. Model i ZASADA „domena na końcu"

GH Pages serwuje zawartość z gałęzi (zwykle `main`, katalog `/root` lub `/docs`). URL bazowy projektu:
`https://<user>.github.io/<repo>`. Z własną domeną → `https://twojadomena.pl`.

**Kolejność (NIE odwracać):**
1. Zbuduj i zweryfikuj stronę **lokalnie**.
2. Push do **publicznego** repo na GitHub.
3. Włącz Pages → potwierdź, że działa na `https://<user>.github.io/<repo>`.
4. **DOPIERO TERAZ** podepnij domenę (DNS + CNAME + Enable HTTPS).

Dlaczego: podpinanie domeny przed działającą stroną generuje błędy 404 i opóźnia diagnozę (mieszają się dwa źródła problemów — kod vs DNS). Najpierw potwierdź kod na `*.github.io`, potem warstwa domeny.

---

## 3. Włączenie GitHub Pages

GitHub UI: **repo → Settings → Pages**:
- **Source:** „Deploy from a branch".
- **Branch:** `main`, folder `/ (root)` (lub `/docs` jeśli strona w podfolderze).
- Save. Po ~1 min strona dostępna na `https://<user>.github.io/<repo>`.

> Repo MUSI być **public** (darmowy plan). Jeśli kod ma być prywatny — albo płatny plan, albo trzymaj kod w osobnym repo private, a do public repo pushuj tylko gotowy `index.html`.

---

## 4. Custom domain — plik CNAME + DNS

### 4a. Plik CNAME w repo
Dodaj plik `CNAME` (bez rozszerzenia) w katalogu głównym repo z jedną linią — gołą domeną:
```
twojadomena.pl
```
GitHub doda go automatycznie, gdy wpiszesz domenę w Settings→Pages→Custom domain. Trzymanie go w repo zapobiega znikaniu przy kolejnych deployach.

### 4b. Rekordy DNS u rejestratora (szczegóły: `dns-records.md`)
Dla **domeny apex** (`twojadomena.pl`) — 4 rekordy A na adresy GitHub Pages:
```
A   @   185.199.108.153
A   @   185.199.109.153
A   @   185.199.110.153
A   @   185.199.111.153
```
Dla **subdomeny `www`** — CNAME:
```
CNAME   www   <user>.github.io.
```
(opcjonalnie rekordy AAAA dla IPv6 — patrz `dns-records.md`).

### 4c. Custom domain w UI
Settings→Pages→**Custom domain** → wpisz `twojadomena.pl` → Save. GitHub zweryfikuje DNS (może potrwać do kilku-kilkunastu min, czasem do 24h propagacji).

---

## 5. HTTPS

Po poprawnej weryfikacji DNS: Settings→Pages → zaznacz **Enforce HTTPS**. GitHub wystawia darmowy certyfikat Let's Encrypt automatycznie (pojawia się po propagacji DNS, czasem trzeba odczekać; jeśli szare/niedostępne — poczekaj i odśwież).

> Jeśli „Enforce HTTPS" jest niedostępne — DNS jeszcze się nie spropagował albo rekordy są błędne. Sprawdź `dig`/`nslookup` (§7).

---

## 6. (Opcjonalnie) Deploy przez GitHub Actions

Dla czystego statyku `main/root` Actions NIE jest potrzebne — Pages serwuje pliki wprost. Actions ma sens, gdy:
- strona ma build-step (SSG) — wtedy workflow buduje i publikuje artefakt,
- chcesz pre-publish lint/test (np. walidacja HTML, sprawdzenie martwych linków).

Dla vanilla single-page: **pomiń** — prostota > ceremonia.

---

## 7. Weryfikacja i diagnostyka

- **Strona na `*.github.io` działa?** Jeśli nie — problem w kodzie/Settings, NIE w DNS.
- **DNS spropagowany?** `dig +short twojadomena.pl` → powinno zwrócić 4 adresy 185.199.108-111.153.
  `dig +short www.twojadomena.pl CNAME` → `<user>.github.io.`
- **„Domain's DNS record could not be retrieved"** → rekordy A/CNAME błędne lub niespropagowane (poczekaj, sprawdź u rejestratora).
- **HTTPS szare** → poczekaj na certyfikat po propagacji; usuń i dodaj ponownie custom domain jeśli utknie.
- **404 po podpięciu domeny** → brak/niepoprawny plik CNAME w repo (znikł przy deployu) — dodaj go do repo na stałe.

---

## 8. Antywzorce

- ❌ **Podpinanie domeny przed działającą stroną na `*.github.io`** — miesza dwa źródła problemów (kod vs DNS), wydłuża diagnozę. Najpierw potwierdź `https://<user>.github.io/<repo>`, domena na końcu.
- ❌ **Plik `CNAME` tylko w UI, nie w repo** — znika przy kolejnym deployu → 404. Commituj `CNAME` do repo na stałe.
- ❌ **Proxy Cloudflare (pomarańczowa chmurka) na rekordach Pages** — kłóci się z certyfikatem GH Pages. Ustaw „DNS only" (szara chmurka), SSL „Full".
- ❌ **CNAME na hoście apex `@`** zamiast 4× rekord A — apex nie używa CNAME; CNAME tylko dla `www`.

## 9. Dobrze vs źle (wzorce)

**A. Kolejność wdrożenia**
- ✅ Dobrze: build lokalny → push → Pages działa na `*.github.io` → DOPIERO potem domena + DNS + HTTPS.
- ❌ Źle: najpierw DNS i custom domain, potem dopiero sprawdzanie czy strona w ogóle się buduje.
- *Dlaczego:* gdy domena jest pierwsza, każdy 404 jest dwuznaczny (kod czy DNS?) — tracisz godziny na propagację, by odkryć błąd w kodzie.

**B. Plik CNAME**
- ✅ Dobrze: `CNAME` z gołą domeną zacommitowany do repo (root), zgodny z Settings→Pages.
- ❌ Źle: domena wpisana tylko w UI, brak pliku w repo.
- *Dlaczego:* deploy nadpisuje katalog publikacji — bez pliku w repo GitHub gubi custom domain i serwuje 404.

## 10. Powiązania

- `static-site-premium-patterns` — budowa strony, którą tu publikujesz (vanilla single-page).
- `static-site-builder` (agent) — może `optional_requires` ten skill, by wygenerować plik `CNAME`.
- `webapp-standards` — alternatywna ścieżka: deploy webapp z backendem na VPS (NIE Pages).

## 11. Checklist (pełna w `pages-setup-checklist.md`)

- [ ] Strona zweryfikowana lokalnie (otwarta w przeglądarce, zero błędów konsoli).
- [ ] Repo **public**, `index.html` w roocie (lub `/docs`).
- [ ] Pages włączone (Settings→Pages, branch `main` / root) — działa na `*.github.io`.
- [ ] Plik `CNAME` w repo z gołą domeną.
- [ ] 4× rekord A (apex) + CNAME `www` u rejestratora.
- [ ] Custom domain wpisana w UI, DNS zweryfikowany (zielony).
- [ ] **Enforce HTTPS** zaznaczone, certyfikat aktywny.
- [ ] `dig` potwierdza rekordy; `https://twojadomena.pl` ładuje stronę z kłódką.
