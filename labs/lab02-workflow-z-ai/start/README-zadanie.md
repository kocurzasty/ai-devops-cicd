# Dane Twojego środowiska

Uzupełnij przed rozpoczęciem — wartości dostaniesz od prowadzącego.

| Co | Gdzie to jest | Wartość |
|---|---|---|
| Rola OIDC do AWS | zmienna repozytorium `AWS_DEPLOY_ROLE_ARN` | `arn:aws:iam::<KONTO>:role/github-actions-deploy` |
| Twoje repozytorium ECR | nazwa w workflow; adres rejestru zwraca akcja `aws-actions/amazon-ecr-login` | `quotes-api-<Twój login>`, czyli `quotes-api-$UCZESTNIK` — już istnieje, nie twórz go. W workflow: `IMAGE_NAME: quotes-api-${{ vars.K8S_NAMESPACE }}` |
| Region | — | `eu-central-1` |
| Twój namespace | zmienna repozytorium `K8S_NAMESPACE` | = `UCZESTNIK` z `.env` |
| Manifesty do wdrożenia | `app/k8s-dzien1/` | `Deployment` i `Service` `quotes-api-d1` |

**Uwaga:** `ECR_REPO` z `.env` wskazuje wspólne repozytorium `quotes-api` (dzień 2). W lab02 go **nie używaj** —
wypchnięcie tam nadpisze tag `staging` innym uczestnikom, a obraz może zostać skasowany przez politykę czyszczenia.

Rola `github-actions-deploy` przyjmuje tokeny tylko z repozytoriów zgłoszonych prowadzącemu
(`setup/README.md`, punkt 1). Błąd `Not authorized to perform sts:AssumeRoleWithWebIdentity`
oznacza, że Twojego repo jeszcze nie ma na liście — zgłoś to, nie zmieniaj workflow.

Ustawienie zmiennej repozytorium:

```bash
gh variable set AWS_DEPLOY_ROLE_ARN --body "arn:aws:iam::123456789012:role/github-actions-deploy"
gh variable set K8S_NAMESPACE --body "$UCZESTNIK"     # po: set -a; source .env; set +a
```

Namespace ma limity zasobów (ResourceQuota), dlatego manifesty w `app/k8s-dzien1/` mają
ustawione `resources`. Jeśli agent napisze własne manifesty bez nich, klaster odrzuci poda.

## Gdzie utworzyć workflow

Nie twórz `.github/workflows/` wewnątrz tego katalogu `start/`. GitHub rozpoznaje workflow
wyłącznie w `.github/workflows/` znajdującym się w głównym katalogu repozytorium — tam, gdzie
znajduje się katalog `.git`.

Przejdź do głównego katalogu i utwórz plik:

```bash
cd "$(git rev-parse --show-toplevel)"
mkdir -p .github/workflows
$EDITOR .github/workflows/deploy.yml
```

Oczekiwana struktura:

```text
ai-devops-cicd/
├── .git/
├── .github/
│   └── workflows/
│       └── deploy.yml      # wynik tego laboratorium
├── app/
└── labs/
    └── lab02-workflow-z-ai/
        └── start/
            └── README-zadanie.md
```

Każdy uczestnik tworzy ten plik w głównym katalogu **swojego** repozytorium lub forka.
