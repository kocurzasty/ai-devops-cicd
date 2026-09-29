# Lab 02 — pipeline promptem

**Blok 2 · 20 minut**

## Zadanie

Napisz promptem workflow, który dla aplikacji z `app/` wykona: lint, testy, build obrazu,
push do ECR i deploy na klaster EKS do Twojego namespace'u. Ma przejść na zielono,
a na koniec sprawdzisz, że aplikacja naprawdę odpowiada z klastra.

Dziś wdrażamy najprościej, jak się da: zwykły `Deployment` i `Service` z `app/k8s-dzien1/`,
bez Ingressu i bez Argo Rollouts. Canary na Rolloutach robimy w dniu 2.

Workflow GitHub Actions musi powstać w `.github/workflows/` **w głównym katalogu Twojego
repozytorium**. GitHub nie wyszukuje workflow w `labs/.../start/.github/workflows/`.
Katalog `start/` zawiera wyłącznie opis zadania i dane środowiska — nie przechodź do niego,
aby tworzyć workflow.

```bash
cd "$(git rev-parse --show-toplevel)"
cat labs/lab02-workflow-z-ai/start/README-zadanie.md
claude       # albo Cline w VS Code — wybierz, czym chcesz dziś pracować
```

Prompt startowy jest w `prompts/blok2-pipeline.md`, sekcja „Workflow od zera".
Możesz go użyć wprost albo napisać własny. Wynikiem ma być dokładnie plik:

```text
<root Twojego repo>/.github/workflows/deploy.yml
```

Każdy uczestnik wykonuje zadanie w swoim repozytorium lub forku. Katalog `.github/workflows/`
jest wspólny dla całego repozytorium, nie dla pojedynczego labu ani użytkownika.

## Wymagania, które musi spełnić wynik

- [ ] `permissions` ustawione na poziomie joba, minimalny zakres
- [ ] `timeout-minutes` na każdym jobie
- [ ] uwierzytelnianie do AWS przez OIDC, **zero kluczy w sekretach**
- [ ] akcje przypięte do wersji (`@v4`), nie do `@main`
- [ ] obraz trafia do **Twojego** repozytorium ECR `quotes-api-<login>` (nazwa z `vars.K8S_NAMESPACE`), nie do wspólnego `quotes-api`
- [ ] build, push i deploy tylko z gałęzi `main`
- [ ] deploy stosuje manifesty z `app/k8s-dzien1/` w namespace z `vars.K8S_NAMESPACE`
      i czeka, aż Deployment będzie gotowy
- [ ] workflow przechodzi na zielono, a `curl` przez port-forward zwraca odpowiedź aplikacji

Przed pierwszym pushem ustaw zmienne repozytorium (wartości masz w `.env` i od prowadzącego):

```bash
set -a; source .env; set +a
gh variable set AWS_DEPLOY_ROLE_ARN --body "arn:aws:iam::<KONTO>:role/github-actions-deploy"
gh variable set K8S_NAMESPACE --body "$UCZESTNIK"
gh variable list                # obie zmienne mają być w Twoim forku
```

## Podpowiedzi

<details>
<summary>Podpowiedź 1 — agent pominął uprawnienia</summary>

Dopisz do promptu: „wyjaśnij przy każdym jobie, dlaczego nadałeś mu takie uprawnienia".
Konieczność uzasadnienia sama z siebie zawęża zakres — trudniej napisać uzasadnienie
dla `write-all` niż dla `contents: read`.
</details>

<details>
<summary>Podpowiedź 2 — agent prosi o AWS_SECRET_ACCESS_KEY</summary>

To znaczy, że nie wie o OIDC w tym repo. Powiedz wprost: „użyj
`aws-actions/configure-aws-credentials` z `role-to-assume`, rola jest w zmiennej
repozytorium `AWS_DEPLOY_ROLE_ARN`. Job potrzebuje `id-token: write`."

Zauważ, że `id-token: write` jest potrzebne **tylko** w jobie, który gada z AWS.
</details>

<details>
<summary>Podpowiedź 3 — pipeline pada, nie wiadomo na czym</summary>

```
Pobierz logi ostatniego nieudanego przebiegu (gh run view --log-failed), znajdź PIERWSZY
prawdziwy błąd — nie ostatnią linię — i wyjaśnij, co go wywołało.
```

Koniec logu to prawie zawsze `Process completed with exit code 1`, czyli informacja,
że coś padło, a nie co. Przyczyna jest wyżej.
</details>

<details>
<summary>Podpowiedź 4 — deploy pada na klastrze</summary>

| Błąd w logu joba deploy | Przyczyna |
|---|---|
| `Forbidden ... in the namespace "default"` albo pusty `-n` | brak zmiennej `K8S_NAMESPACE` w repo |
| `the server doesn't have a resource type "rollouts"` / `rollouts.argoproj.io "quotes-api" not found` | agent użył Rollout zamiast manifestów z `app/k8s-dzien1/` |
| `ImagePullBackOff`, `rollout status` kończy się timeoutem | w manifeście został `PODMIEN_NA_OBRAZ` albo zły adres obrazu |
| `name unknown: The repository with name 'quotes-api-...' does not exist` albo `denied` przy pushu | zła nazwa obrazu: ma być `quotes-api-` + login (`vars.K8S_NAMESPACE`); brak zmiennej daje `quotes-api-` bez loginu |
| `Not authorized to perform sts:AssumeRoleWithWebIdentity` | job ma `environment:` (zmienia tożsamość w tokenie OIDC — usuń) albo Twojego forka nie ma jeszcze na liście prowadzącego — zgłoś to |
</details>

## Weryfikacja

```bash
cd "$(git rev-parse --show-toplevel)"
actionlint .github/workflows/*.yml
git add .github/workflows/deploy.yml
git commit -m "Dodaj pipeline CI/CD"
git push
gh run watch
```

Jeżeli `git rev-parse --show-toplevel` pokazuje katalog inny niż repozytorium, w którym chcesz
uruchomić Actions, zatrzymaj się. Workflow zostanie zarejestrowany przez GitHub tylko wtedy,
gdy plik `.github/workflows/deploy.yml` zostanie wypchnięty do tego konkretnego repozytorium.

### Sprawdzenie na klastrze

Zielony job deploy to jeszcze nie dowód, że aplikacja działa. Zapytaj ją bezpośrednio.
Dostęp do klastra (`aws eks update-kubeconfig`) konfigurowałeś rano — `setup/README.md`, sekcja „AWS”, krok 4.

```bash
set -a; source .env; set +a
kubectl get deploy,pods,svc -n $UCZESTNIK        # quotes-api-d1: 1/1 READY
kubectl port-forward -n $UCZESTNIK svc/quotes-api-d1 8080:80 &
sleep 2
curl -s localhost:8080/healthz
curl -s localhost:8080/api/quote
kill %1                                          # zamyka port-forward
```

Pole `version` w odpowiedzi `/api/quote` pochodzi z build-arg `APP_VERSION`. Jeśli Twój
pipeline przekazuje tam SHA commita, widzisz dowód, że na klastrze działa dokładnie ten commit.
Jeśli widzisz `v1`, build-arg nie został ustawiony — obraz działa, ale nie powie, z czego powstał.
Przed `kill` możesz też otworzyć `http://localhost:8080` w przeglądarce.

Port-forward tuneluje ruch przez API klastra do jednego poda. Nie potrzebuje load balancera
ani publicznego adresu, dlatego działa bez Ingressu — i dlatego nie nadaje się do ruchu
produkcyjnego.

Po zakończeniu prowadzący pokaże wzorcowy workflow i porówna go z Waszymi wersjami.

## Pułapki

**`permissions: write-all`.** Wygodne i przechodzi. Oznacza, że każdy krok w workflow
— łącznie z akcją z marketplace'u, której nie czytałeś — może pisać do repozytorium,
tworzyć release'y i publikować pakiety.

**Akcja przypięta do `@master` albo `@main`.** To cudzy kod, wykonywany na Twoim runnerze,
w wersji, której nikt nie zatwierdził. Autor może zmienić zawartość taga w każdej chwili.

**Deploy odpalający się z pull requesta.** Bez warunku na gałąź każdy PR — także z forka —
próbuje wdrożyć. Agent często o tym zapomina, bo w promptcie mówimy „zbuduj i wdróż",
a nie „wdróż tylko z main".

**Obraz `latest` albo tag zgadywany w jobie deploy.** Deploy ma dostać dokładnie ten obraz,
który zbudował job `build` (tag = SHA commita), przekazany przez `outputs`. Inaczej nie wiesz,
co właściwie działa na klastrze.
