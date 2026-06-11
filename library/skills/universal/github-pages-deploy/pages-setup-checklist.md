# Checklista: od zera do https://twojadomena.pl na GitHub Pages

##  — Strona lokalnie
- [ ] `index.html` otwiera się w przeglądarce, wszystkie sekcje renderują.
- [ ] Zero błędów w konsoli (DevTools → Console).
- [ ] Zero placeholderów w wersji do publikacji (VIDEO_ID, FORM_ID, lorem).
- [ ] Linki względne działają (CV PDF, assets/img) — testuj z `file://` lub lokalnym serwerem (`python3 -m http.server`).
- [ ] Lighthouse ≥ 95 (Perf/A11y/Best/SEO).

##  — Repo + Pages (jeszcze BEZ domeny)
- [ ] Repo na GitHub **public**, np. `LogicMorrow/<repo>`.
- [ ] `index.html` w katalogu głównym (root) — lub `/docs` jeśli tak wolisz.
- [ ] `git add . && git commit && git push` na `main`.
- [ ] Settings → Pages → Source: „Deploy from a branch", Branch `main` / `/ (root)` → Save.
- [ ] Po ~1 min otwórz `https://<user>.github.io/<repo>` — strona działa. **Nie idź dalej, dopóki to nie działa.**

##  — Custom domain (DOPIERO gdy  zielona)
- [ ] Plik `CNAME` w repo z gołą domeną (np. `twojadomena.pl`), commit + push.
- [ ] U rejestratora: 4× rekord A (apex → 185.199.108-111.153) + CNAME `www → <user>.github.io.` (patrz `dns-records.md`).
- [ ] Usuń kolidujące domyślne rekordy A (parking rejestratora).
- [ ] Settings → Pages → Custom domain → wpisz `twojadomena.pl` → Save. Poczekaj na zielony „DNS check successful".
- [ ] `dig +short twojadomena.pl` zwraca 4 adresy GitHub.

##  — HTTPS
- [ ] Po zielonej weryfikacji DNS: Settings → Pages → **Enforce HTTPS** (zaznacz).
- [ ] Poczekaj na certyfikat Let's Encrypt (minuty–godziny po propagacji).
- [ ] `https://twojadomena.pl` ładuje stronę z kłódką, brak ostrzeżeń.
- [ ] `http://` i `www.` przekierowują na kanoniczny `https://twojadomena.pl`.

## Diagnostyka szybka
| Objaw | Przyczyna | Akcja |
|---|---|---|
| 404 na `*.github.io` | Pages nie włączone / zły branch/folder | Settings→Pages, sprawdź source |
| 404 po podpięciu domeny | brak pliku CNAME w repo | dodaj `CNAME` do repo |
| „DNS could not be retrieved" | rekordy błędne/niespropagowane | sprawdź `dig`, popraw u rejestratora |
| HTTPS szare/niedostępne | DNS niespropagowany | poczekaj, odśwież; re-add domeny jeśli utknie |
| Domena pokazuje parking | stare rekordy A rejestratora | usuń je, zostaw tylko 4× GitHub |
