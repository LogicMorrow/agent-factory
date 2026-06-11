# Rekordy DNS dla GitHub Pages + custom domain

## Adresy IP GitHub Pages (apex / domena gołą)

GitHub Pages serwuje apex przez 4 anycastowe adresy IPv4. Ustaw **wszystkie cztery** jako rekordy A:

```
Typ  Host/Nazwa  Wartość
A    @           185.199.108.153
A    @           185.199.109.153
A    @           185.199.110.153
A    @           185.199.111.153
```

Opcjonalnie IPv6 (rekordy AAAA — zalecane, jeśli rejestrator wspiera):
```
AAAA @           2606:50c0:8000::153
AAAA @           2606:50c0:8001::153
AAAA @           2606:50c0:8002::153
AAAA @           2606:50c0:8003::153
```

## Subdomena www (CNAME)

```
Typ    Host/Nazwa  Wartość
CNAME  www         <user>.github.io.      ← kropka na końcu, podmień <user>
```

Przykład dla `LogicMorrow`: `CNAME  www  logicmorrow.github.io.`

## Wybór: apex czy www jako główna?

- **Domena gołą (`twojadomena.pl`) jako główna** → rekordy A (apex) obowiązkowe + CNAME `www` dla przekierowania. To zalecane dla wizytówki (krótszy URL).
- W Settings→Pages→Custom domain wpisz wariant, który ma być kanoniczny; GitHub ustawi przekierowanie drugiego.

## Konfiguracja u popularnych rejestratorów PL

- **OVH / home.pl / nazwa.pl / cyber_Folks / Aftermarket**: panel domeny → „Strefa DNS" / „Rekordy DNS" → dodaj 4× A (host `@` lub puste) + 1× CNAME (host `www`). Usuń kolidujące domyślne rekordy A wskazujące na parking rejestratora.
- **Cloudflare**: dodaj te same rekordy, ale **wyłącz proxy (szara chmurka, DNS only)** dla rekordów Pages — pomarańczowa chmurka (proxy) kłóci się z certyfikatem GH Pages. Tryb SSL „Full".

## Weryfikacja

```bash
dig +short twojadomena.pl            # → 4 adresy 185.199.108-111.153
dig +short www.twojadomena.pl CNAME  # → <user>.github.io.
```

Propagacja: zwykle minuty, maksymalnie do 24-48h. Certyfikat HTTPS pojawia się po udanej weryfikacji DNS.

## Uwagi

- **TTL**: domyślny (3600s) jest OK. Niższy (300s) przyspiesza poprawki podczas konfiguracji.
- **Nie mieszaj** rekordu A apex z rekordem CNAME na tym samym hoście `@` — apex używa A, nie CNAME (CNAME tylko dla `www`).
- Plik `CNAME` w repo musi zawierać dokładnie tę samą domenę, co w Settings→Pages.
