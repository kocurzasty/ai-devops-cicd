# Przygotowanie środowiska

Wszystko poniżej zrób **przed** dniem 1. Na sali zaczynamy od razu od pracy.

## 1. GitHub i własna kopia repozytorium

Potrzebujesz zwykłego konta osobistego na GitHubie. Darmowy plan wystarcza — musisz móc
założyć repozytorium i uruchamiać Actions.

GitHub CLI (`gh`) jest już zainstalowany na maszynie szkoleniowej. Zaloguj się:

```bash
gh auth login                # GitHub.com → HTTPS → Login with a web browser
gh auth status               # powinno pokazać Twój login
```

Jeśli na maszynie nie otworzy się przeglądarka, `gh` wypisze jednorazowy kod i adres
`https://github.com/login/device`. Otwórz go na swoim laptopie i wklej kod.

**Okno „Authentication required … no longer matches that of your login keyring”.**
To nie jest błąd GitHuba, tylko systemowy magazyn haseł (GNOME Keyring). `gh` i Chrome
próbują w nim zapisać dane, a keyring ma inne hasło niż Twoje obecne konto na maszynie.
Linie `DEPRECATED_ENDPOINT` i `ConnectionHandler failed` w terminalu to logi Chrome —
możesz je zignorować.

Najprościej: kliknij **Anuluj**, przerwij `gh` (`Ctrl+C`) i zaloguj się bez keyringa —
token trafi do pliku `~/.config/gh/hosts.yml`:

```bash
gh auth login --insecure-storage
gh auth status
```

Jeśli okno ma przestać wyskakiwać, usuń keyring i przy następnym pytaniu ustaw mu
**aktualne hasło logowania do maszyny**:

```bash
rm -f ~/.local/share/keyrings/login.keyring
```

Kod z `gh auth login` jest jednorazowy i wygasa po kilku minutach — przy ponownej
próbie dostaniesz nowy.

Workflow GitHub Actions i zmienne repozytorium (lab02, lab03) działają tylko
w repozytorium, które należy do Ciebie. Dlatego robisz **fork**, czyli własną kopię repo
na swoim koncie GitHub, i klonujesz ją na maszynę:

```bash
cd ~
gh repo fork dawid-marniok/ai-devops-cicd --clone
cd ai-devops-cicd
```

Przykład dla użytkownika `anna-k`:

```text
$ gh repo fork dawid-marniok/ai-devops-cicd --clone
✓ Created fork anna-k/ai-devops-cicd
Cloning into 'ai-devops-cicd'...
✓ Cloned fork
```

Sprawdź, czy zdalne repozytoria są ustawione poprawnie:

```text
$ git remote -v
origin    https://github.com/anna-k/ai-devops-cicd.git (fetch)          ← Twój fork, tu pushujesz
origin    https://github.com/anna-k/ai-devops-cicd.git (push)
upstream  https://github.com/dawid-marniok/ai-devops-cicd.git (fetch)   ← repo prowadzącego
upstream  https://github.com/dawid-marniok/ai-devops-cicd.git (push)
```

Ustaw swój fork jako domyślne repo dla `gh`. Po sklonowaniu forka `gh` wypisuje
ostrzeżenie `dawid-marniok/ai-devops-cicd set as the default repository`, czyli domyślnie
celuje w repo prowadzącego. Wtedy `gh variable set` (lab02), `gh run list`
i `gh pr create` trafiałyby nie tam, gdzie trzeba:

```bash
gh repo set-default <twój-login>/ai-devops-cicd    # np. anna-k/ai-devops-cicd
gh repo set-default --view                         # ma pokazać Twój fork
```

Jeśli w trakcie szkolenia prowadzący poprawi materiały, pobierzesz zmiany poleceniem
`git pull upstream main`.

**Błąd „You have divergent branches and need to specify how to reconcile them”.**
Pojawia się, gdy masz już własne commity (np. rozwiązania zadań), a na `upstream/main`
są nowe commity prowadzącego. To nie błąd — git od wersji 2.x wymaga wskazania strategii.
Wybierz merge, nie rebase, żeby nie przepisywać własnej historii:

```bash
git config pull.rebase false   # raz na cały czas trwania szkolenia
git pull upstream main
```

Materiały labów (pliki, których nie edytujesz) i Twoje rozwiązania leżą w różnych
plikach, więc taki merge z reguły przechodzi bez konfliktów.

Bez `gh`: na stronie https://github.com/dawid-marniok/ai-devops-cicd kliknij **Fork**,
a potem `git clone https://github.com/<twój-login>/ai-devops-cicd.git`.

**Wyślij prowadzącemu nazwę swojej kopii** (w przykładzie: `anna-k/ai-devops-cicd`). Bez tego rola AWS
dla GitHub Actions nie przyjmie tokenu z Twojego repo i pipeline w lab02 nie zaloguje się do AWS.

Wszystkie kolejne polecenia uruchamiasz w katalogu `ai-devops-cicd`.

## 2. Sprawdź, czego Ci brakuje

```bash
./setup/check-prereqs.sh
```

Czerwone pozycje blokują udział w ćwiczeniach. Żółte możesz zignorować.

## 3. Zainstaluj brakujące narzędzia

Środowisko szkoleniowe to Linux (Ubuntu). Większość narzędzi jest już zainstalowana
na maszynie. Na starcie doinstalowujesz cztery: TFLint, Checkov, actionlint i plugin Argo Rollouts.
Po instalacji uruchom ponownie `./setup/check-prereqs.sh` — nie powinno być nic na czerwono.

| Narzędzie | Min. wersja | Na maszynie | Instalacja |
|---|---|---|---|
| **TFLint** | 0.50 | ⬜ instalujesz | `curl -fsSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh \| bash` |
| **Checkov** | 3.2 | ⬜ instalujesz | `sudo apt install -y pipx && pipx install checkov && pipx ensurepath` (potem otwórz nowy terminal) |
| **Plugin Argo Rollouts** | — | ⬜ instalujesz | `curl -fsSLO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64 && sudo install kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts` |
| **actionlint** | 1.7 | ⬜ instalujesz | `bash <(curl -fsSL https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash) && sudo mv actionlint /usr/local/bin/` |
| Git, GitHub CLI | 2.30 / 2.40 | ✅ jest | — |
| Python | 3.11 | ✅ jest | — |
| Terraform | 1.10 | ✅ jest | — |
| AWS CLI | 2.32 (`aws login`) | ✅ jest | — |
| kubectl | 1.29 | ✅ jest | — |
| Helm | 3.14 | ✅ jest | — |
| Docker | — | ✅ jest | — |
| Claude Code | — | ✅ jest | — |
| VS Code + Cline | — | ✅ jest | — |

TFLint, Checkov i actionlint są wymagane (actionlint weryfikuje workflowy w lab02 i lab03).
Pozostałe narzędzia (`trivy`, `conftest`) są opcjonalne — prowadzący pokaże je podczas demonstracji.

## 4. Konta

### Claude Code i Cline — jedna subskrypcja na oba narzędzia

Claude Code wymaga płatnego planu (Pro, Max, Team, Enterprise albo Console/API).
Darmowy plan claude.ai **nie wystarczy**. Dostęp na czas warsztatów zapewnia prowadzący.

Cline może korzystać z tej samej subskrypcji — nie potrzebujesz osobnego klucza API:

1. Zainstaluj i zaloguj Claude Code (`claude`, potem `/login`)
2. VS Code → Cline → Settings → API Configuration → provider **„Claude Code"**
3. W polu ze ścieżką do CLI zwykle wystarczy `claude`, jeśli jest w `PATH`

W tym trybie odpowiedzi nie strumieniują się token po tokenie — pojawiają się naraz po chwili.
Dla ćwiczeń z code review nie ma to znaczenia.

### Model: Sonnet 5, nie Opus

Na szkoleniu używamy modelu **Sonnet 5**. Wystarcza do wszystkich ćwiczeń, jest szybszy
i nie wyczerpuje tak szybko limitu subskrypcji jak Opus. Ustaw go przed pierwszą pracą:

```bash
claude --model sonnet     # uruchomienie z Sonnetem
```

albo w już działającej sesji Claude Code:

```text
/model sonnet
```

Sprawdzenie: `/status` pokazuje aktualny model — ma być `claude-sonnet-5`.

W Cline: Settings → API Configuration → pole **Model** → wybierz Sonnet 5 (`claude-sonnet-5`).

### AWS

Login i hasło startowe dostajesz od prowadzącego — **nie używaj konta firmowego**.
Nie potrzebujesz kluczy dostępowych: CLI loguje się tym samym loginem i hasłem co konsola
i dostaje krótkotrwałe poświadczenia.

Konto szkoleniowe AWS: **574921529806**

**1. Konsola.** Otwórz https://574921529806.signin.aws.amazon.com/console, zaloguj się i ustaw
nowe hasło — AWS wymaga tego przy pierwszym logowaniu. Zrób to **przed** `aws login`.

Jeśli w przeglądarce jesteś zalogowany na inne konto AWS (np. firmowe), użyj okna incognito
albo najpierw się wyloguj. `aws login` bierze konto z aktualnej sesji konsoli w przeglądarce.

**2. CLI.** Wymaga AWS CLI 2.32 lub nowszego (`aws --version`).

```bash
aws configure set region eu-central-1   # najpierw region, inaczej aws login zapyta o niego
aws login                               # otworzy przeglądarkę; zatwierdź dostęp dla CLI
aws sts get-caller-identity             # ma pokazać user/<login-od-prowadzącego>
```

Bez przeglądarki na maszynie: `aws login --remote` wypisze adres i poprosi o kod ze strony.

Jeśli po zalogowaniu przeglądarka zostanie na stronie konsoli, a terminal dalej czeka,
wklej w tym samym oknie jeszcze raz adres, który wypisał `aws login`.

**3. Profil dla Terraform.** Terraform nie odczytuje jeszcze sesji z `aws login`, dlatego
tworzysz profil pośredni, który pobiera poświadczenia przez CLI. Z tego profilu korzystają też
boto3 (lab05) i `kubectl` (lab02 i dzień 2).

```bash
aws configure set credential_process "aws configure export-credentials --profile default --format process" --profile szkolenie
aws configure set region eu-central-1 --profile szkolenie
echo 'export AWS_PROFILE=szkolenie' >> ~/.bashrc && export AWS_PROFILE=szkolenie
aws sts get-caller-identity             # ten sam użytkownik, już przez profil szkolenie
```

Sesja trwa do 12 godzin. Gdy wygaśnie (np. rano w dniu 2), zaloguj się ponownie:

```bash
aws login --profile default   # koniecznie z --profile default, bo AWS_PROFILE wskazuje profil pośredni
```

**4. Dostęp do klastra.** Potrzebny od lab02 (dzień 1), gdy sprawdzasz swoje pierwsze
wdrożenie. Najpierw uzupełnij `.env` (niżej, „Plik .env”):

```bash
set -a; source .env; set +a     # UCZESTNIK i ECR_REPO
aws eks update-kubeconfig --name szkolenie-ai-devops --region eu-central-1
kubectl get pods -n $UCZESTNIK  # przed lab02 "No resources found" to poprawny wynik
```

Po lab02 w namespace zostaje pod `quotes-api-d1` — to Twoje wdrożenie z dnia 1, nie usuwaj go.
Rano w dniu 2 wystarczy nowa sesja: `aws login --profile default`.

Grafana (dashboardy w lab07, lab10, lab11) działa w klastrze — adres i hasło poda prowadzący.

## 5. Środowisko Python i testy

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r app/requirements-dev.txt
cd app && pytest -q && cd ..    # 6 testów ma przejść
```

`source .venv/bin/activate` powtarzasz w każdym nowym terminalu, w którym używasz
`pytest`, `ruff`, `uvicorn` albo `python` z zależnościami aplikacji.

## 6. Sprawdź, że aplikacja startuje

W `app/` jest **quotes-api**, mała aplikacja w FastAPI, która zwraca losowe cytaty o DevOps.
Sama w sobie nie jest ważna. To na niej przez dwa dni budujesz pipeline, wdrażasz na klaster
(zwykły Deployment w dniu 1, canary z Argo Rollouts w dniu 2), włączasz feature flagi,
skalujesz i zbierasz metryki. Każdy endpoint ma swoje zadanie:

| Endpoint | Co robi | Gdzie się przydaje |
|---|---|---|
| `/` | Baner z numerem wersji: niebieski dla v1, zielony dla v2 | Canary — w przeglądarce widać, która wersja odpowiedziała |
| `/healthz` | Stan aplikacji dla probe'ów Kubernetesa | Wdrożenia, symulacja incydentu |
| `/metrics` | Metryki w formacie Prometheusa | Grafana, automatyczna analiza canary |
| `/api/quote` | Losowy cytat; flaga `nowy-format-cytatu` dokłada metadane | Feature flagi (lab08) |
| `/api/slow?ms=250` | Obciąża CPU przez podany czas (maks. 5 s) | Autoskalowanie HPA (lab10) |

Wersja podana w `APP_VERSION` zmienia kolor banera. Obraz z wersją `-broken` (np. `v2-broken`)
celowo zwraca błąd 500 na części żądań. Na nim ćwiczysz rollback w lab07.

```bash
cd app && uvicorn main:app --reload --port 8000
# w drugim terminalu:
curl localhost:8000/healthz
```

Jeśli to działa, jesteś gotowy. Możesz jeszcze otworzyć http://localhost:8000/ (baner)
i http://localhost:8000/docs (wszystkie endpointy do przeklikania w Swaggerze).

## Plik .env

Lab02 i laby dnia 2 (lab07, lab08, lab10, lab11) potrzebują dwóch wartości, które poda prowadzący:
Twojego identyfikatora i adresu rejestru obrazów. Zapisz je w pliku `.env`
(jest w `.gitignore`, nie trafi do repo):

```bash
cp setup/env.example .env
# uzupełnij UCZESTNIK i ECR_REPO
```

Na początku każdego labu, w każdym terminalu, wczytujesz je poleceniem:

```bash
set -a; source .env; set +a
```

## 7. Przed dniem 2 — strażnik promptów (lab09)

Zależności labu 09 ważą około 1 GB, dlatego zainstaluj je wcześniej, w osobnym venv:

```bash
python3 -m venv labs/lab09-llm-firewall/.venv
labs/lab09-llm-firewall/.venv/bin/pip install -r labs/lab09-llm-firewall/start/requirements.txt
```

## Jeśli coś nie działa w dniu szkolenia

Zgłoś prowadzącemu wynik `./setup/check-prereqs.sh` oraz dokładny komunikat błędu.
