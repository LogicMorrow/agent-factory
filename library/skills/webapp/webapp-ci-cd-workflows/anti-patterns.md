# Antywzorce — webapp-ci-cd-workflows

Pelna lista antywzorców z bloczkami dobrze/zle i wyjaśnieniem dlaczego bolesne.

---

## 1. Sekrety hardkodowane w workflow YAML (krytyczny)

**Zle:**
```yaml
env:
  POSTGRES_PASSWORD: "supersecret123"
  SENTRY_DSN: "https://abc@sentry.io/123"
  DATABASE_URL: "postgres://user:pass@localhost:5432/db"
```

**Dobrze:**
```yaml
env:
  POSTGRES_PASSWORD: ${{ secrets.POSTGRES_PASSWORD }}
  SENTRY_DSN: ${{ secrets.SENTRY_DSN }}
  DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

Dlaczego bolesne: sekret w historii git = rotacja wymagana natychmiastowo + audit finding
CRITICAL. Gitleaks w pre-commit hook (husky) blokuje przy commitcie — ale YAML workflowów
jest latwy do pomylki przy copypaste z dokumentacji. Nawet po `git filter-branch` sekret
moze byc w cache GitHub.

---

## 2. `docker compose pull` bez `docker login ghcr.io` na self-hosted runner

**Zle:**
```yaml
# deploy-prod job - brak logowania
- name: Deploy
  run: |
    cd /srv/{{PROJECT_NAME}}
    docker compose pull && docker compose up -d
    # FAIL: "Error response from daemon: unauthorized"
    # Lub: cicha porazka — uzywa starego cachedowanego obrazu
```

**Dobrze:**
```yaml
- name: Login to ghcr.io
  run: echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin

- name: Deploy
  run: |
    cd /srv/{{PROJECT_NAME}}
    docker compose pull
    docker compose up -d

- name: Healthcheck
  run: curl -f --retry 10 --retry-delay 3 http://localhost:{{APP_PORT}}/api/ready
```

Dlaczego bolesne: cicha porazka — `docker compose pull` moze zwrocic exit 0 gdy obraz jest
w local cache, nawet jesli pull z ghcr.io sie nie udal. Deployment "sie udal" ale stara
wersja nadal dziala. Diagnoza trudna bo logi CD sa zielone.

---

## 3. Tag `:latest` jako jedyny tag w ghcr.io

**Zle:**
```yaml
# cd.yml - tylko latest tag
tags: ghcr.io/{{GHCR_OWNER}}/{{PROJECT_NAME}}:latest
```

**Dobrze:**
```yaml
# cd.yml - SHA + latest (oba wymagane)
tags: |
  ghcr.io/{{GHCR_OWNER}}/{{PROJECT_NAME}}:${{ github.sha }}
  ghcr.io/{{GHCR_OWNER}}/{{PROJECT_NAME}}:latest
```

Dlaczego bolesne: rollback bez SHA tag = niemozliwy bez re-pushu starego kodu. Incydent
produkcyjny wymaga natychmiastowego rollbacku — z SHA tag to 30s (docker pull + compose up),
bez SHA tag to 5-15 minut (revert commit + push + czekanie na CI/CD). SHA jest immutowalne
— `:latest` zawsze wskazuje najnowszy push.

---

## 4. ZAP full scan w job `deploy-prod` zamiast schedule nightly/weekly

**Zle:**
```yaml
# cd.yml - ZAP full scan podczas deploymentu na prod
jobs:
  deploy-prod:
    steps:
      - name: Deploy
        run: docker compose up -d
      - name: ZAP full scan
        uses: zaproxy/action-full-scan@v0.10.0
        with:
          target: https://prod.{{PROJECT_NAME}}.pl  # NIGDY prod podczas deploymentu
```

**Dobrze:**
```yaml
# security.yml - ZAP tylko na schedule, tylko staging
on:
  schedule:
    - cron: '0 2 * * 1'  # weekly, poniedziałki 2:00 UTC, pora niskiego ruchu

jobs:
  zap-full:
    steps:
      - uses: zaproxy/action-full-scan@v0.10.0
        with:
          target: ${{ env.STAGING_URL }}  # NIE prod
```

Dlaczego bolesne: ZAP full scan trwa 30-60 minut + generuje traffic wygladajacy jak atak
(fuzzing, SQL injection proby, path traversal). Na URL produkcyjnym:
1. WAF moze zablokować i wymagac reconfiguracji
2. Hosting moze zawiesic konto za "atak"
3. Wydluzony deployment = downtime
4. False positive alerty w monitoring (Sentry error spike)

---

## 5. Trivy scan przed pushowaniem obrazu (race condition)

**Zle:**
```yaml
jobs:
  trivy-scan:
    # Brak: needs: [build-and-push]
    # Uruchamia sie rownolegle z build-and-push — obraz moze nie istniesc
    steps:
      - uses: aquasecurity/trivy-action@master
        with:
          image-ref: ghcr.io/{{GHCR_OWNER}}/{{PROJECT_NAME}}:${{ github.sha }}
          # FAIL: "image not found" lub skanuje poprzedni obraz z inna SHA
```

**Dobrze:**
```yaml
jobs:
  build-and-push:
    # ... buduje i pushuje obraz

  trivy-scan:
    needs: [build-and-push]  # WYMAGANE: czeka na push obrazu
    steps:
      - name: Login to ghcr.io
        run: echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin

      - uses: aquasecurity/trivy-action@master
        with:
          image-ref: ghcr.io/{{GHCR_OWNER}}/{{PROJECT_NAME}}:${{ github.sha }}
          severity: HIGH,CRITICAL
          exit-code: 1  # BLOKER przy znalezieniu HIGH/CRITICAL
          format: sarif
          output: trivy-results.sarif

      - uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-results.sarif
```

Dlaczego bolesne: bez `needs` Trivy job rusza rownolegle z build — jesli build trwa 3 min,
Trivy zacznie skanowac przed pushiem. Albo fail "image not found", albo Trivy sciagnie
poprzedni obraz (`:latest` sprzed tego commitu) i da falszywy wynik PASS.

---

## 6. `pnpm install` bez `--frozen-lockfile` w CI

**Zle:**
```yaml
- run: pnpm install
  # W CI: jesli lockfile jest out-of-sync, pnpm go zaktualizuje
  # = dirty state, potencjalnie inna wersja dep niz na dev maszynach
```

**Dobrze:**
```yaml
- run: pnpm install --frozen-lockfile
  # Fail jesli lockfile != package.json
  # Wymusza synchronizacje przed push
```

Dlaczego bolesne: CI instaluje inna wersje dep niz jest w lockfile = "works on my machine"
bug. Testy przechodzą w CI z dependency X v1.2.3 ale na prod deploymerntujesz X v1.2.4
bo ktos zapomnial commit lockfile.

---

## 7. `self-hosted` runner bez labels (routing do wszystkich runnerow)

**Zle:**
```yaml
jobs:
  deploy-prod:
    runs-on: self-hosted  # Bez labels = any self-hosted runner
```

**Dobrze:**
```yaml
jobs:
  deploy-prod:
    runs-on: [self-hosted, demoapp-prod]  # Precyzyjny routing
```

Dlaczego bolesne: jesli masz wiecej niz 1 self-hosted runner (np. prod + staging),
`runs-on: self-hosted` wylosuje pierwszy dostepny. Deployment produkcyjny moze trafic
na runner stagingowy (lub odwrotnie). Labels sa tanie — brak labels kosztuje drogo.
