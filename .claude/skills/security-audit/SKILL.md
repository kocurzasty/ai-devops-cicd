---
name: security-audit
description: >
  Pełny audyt bezpieczeństwa stanu repozytorium — Terraform (infra/), GitHub Actions
  (.github/workflows/), Kubernetes (manifesty w app/) i kod aplikacji (app/). Użyj tego
  skilla zawsze, gdy użytkownik prosi o "audyt bezpieczeństwa", "security audit",
  "sprawdź czy repo jest bezpieczne", "znajdź podatności/błędy bezpieczeństwa w projekcie",
  albo chce ogólnego przeglądu security niezależnego od konkretnego PR czy diffa.
  To audyt CAŁEGO aktualnego stanu repo, nie recenzja zmian — jeśli użytkownik chce
  recenzji konkretnego PR lub diffa, to nie ten skill (patrz sekcja "Kiedy NIE używać").
---

# Audyt bezpieczeństwa repozytorium

Audytujesz aktualny **stan** repozytorium (nie diff) pod kątem błędów bezpieczeństwa
w czterech warstwach: Terraform, GitHub Actions, Kubernetes, kod aplikacji. Repo to
środowisko szkoleniowe `ai-devops-cicd` — stack i konwencje są opisane w `.claude/CLAUDE.md`,
przeczytaj go, jeśli jeszcze nie masz go w kontekście.

## Kiedy NIE używać tego skilla

- Recenzja konkretnego PR albo diffa — to zadanie dla przeglądu diffa (np. `git diff`
  pod komendę `pr-review`), nie dla pełnego audytu stanu.
- Recenzja wyłącznie zmian w Terraform przed `apply` — osobny, węższy przepływ
  (`tf-review`) skupiony na diffie `.tf`.
- Jeśli użytkownik pyta tylko o jedną warstwę (np. "sprawdź uprawnienia w workflow X"),
  możesz ograniczyć się do sekcji 2 zamiast przechodzić przez wszystkie cztery.

## Zakres

Jeśli użytkownik wskazał konkretną ścieżkę, katalog albo warstwę — ogranicz się do niej.
W przeciwnym razie audytuj cały stan repozytorium, warstwa po warstwie.

Pomiń świadomie i napisz o tym jednym zdaniem na początku raportu:
- `labs/*/start/` — pliki startowe ćwiczeń, nie kod produktu
- `infra/modules/app-storage-bledny` — moduł z celowymi błędami do ćwiczeń; audytujesz go
  tylko jeśli użytkownik wprost o to poprosi, i nie „naprawiasz" go z własnej inicjatywy

## Format znaleziska

Każde znalezisko w jednej linii:

```
[KRYTYCZNE/WYSOKIE/ŚREDNIE/NISKIE] plik:linia — co jest źle — czym to grozi konkretnie — poprawka
```

Znalezisko bez opisanego konkretnego skutku pomiń — brak opisu skutku znaczy, że nie
jesteś go pewien, a niepewne znalezisko tylko rozmywa raport.

## Warstwy audytu

**1. Terraform (`infra/`, poza wykluczeniami)**

Najpierw uruchom i przeczytaj wyjście, zanim cokolwiek napiszesz:
```
terraform fmt -check -recursive
terraform validate
tflint --recursive   # jeśli dostępne
```
Potem sprawdź:
- ekspozycja sieciowa — `0.0.0.0/0` na porcie innym niż 443, zasoby z publicznym IP
- S3 — brak szyfrowania, brak public access block, brak wersjonowania
- IAM — `Action: "*"`, `Resource: "*"`, role szersze niż wynika z użycia
- nazewnictwo i tagi zgodne z `.claude/CLAUDE.md` (`Projekt`, `Uczestnik`, `Blok`, `Usuwac`)
- sekrety zaszyte wprost w plikach `.tf`

**2. GitHub Actions (`.github/workflows/`)**
- brak bloku `permissions:` na poziomie joba, albo `permissions: write-all`
- `pull_request_target` łączony z checkoutem kodu z forka
- akcje przypięte do ruchomego taga (`@main`, `@v1`) zamiast do SHA commita
- długoterminowe klucze AWS w sekretach tam, gdzie powinno być OIDC
- sekrety przekazywane przez `run:` zamiast `env:`, albo widoczne w argumentach komendy (`ps`)
- brak `timeout-minutes` na jobie

**3. Kubernetes (manifesty w `app/`, np. `app/k8s-dzien1/`)**
- kontener uruchamiany jako root, brak `securityContext`
- obraz bez przypiętej wersji (`latest` albo brak tagu)
- brak `resources.limits` — jeden pod może zjeść cały węzeł
- nadmiarowy RBAC — `ClusterRole` tam, gdzie wystarczy `Role`, `*` w `verbs` albo `resources`
- sekrety jako zmienne środowiskowe tam, gdzie wrażliwość danych uzasadnia wolumen

**4. Aplikacja (`app/`)**
- sekrety, klucze albo hasła zaszyte w kodzie
- zależności z podatnościami — jeśli masz dostęp do `pip-audit` (albo odpowiednika),
  uruchom go; jeśli nie, oznacz jako `[do sprawdzenia ręcznie]`, nie zgaduj CVE
- dane od użytkownika trafiające bezpośrednio do zapytań, komend albo ścieżek plików
  bez walidacji

## Struktura raportu

Zakończ zawsze w tej kolejności:
1. Jedno zdanie o pominiętych wykluczeniach (jeśli dotyczy)
2. Znaleziska warstwa po warstwie, w formacie z sekcji wyżej
3. Tabela: liczba znalezisk w każdej kategorii ważności
4. **Top 3** — trzy najpoważniejsze znaleziska, jedno zdanie każde, z `plik:linia`
5. Werdykt: `BEZPIECZNE` / `DO POPRAWY` / `BLOKUJĄCE`

## Twarde zasady

- Nie dopisuj `#checkov:skip`, `#tfsec:ignore` ani żadnego innego wyciszenia skanera jako
  „poprawki" — to ukrywa problem, a nie go rozwiązuje. Zaproponuj naprawę przyczyny.
- To tylko audyt — nie uruchamiaj `terraform apply` ani `kubectl delete`, zero zmian
  w środowisku, nawet jeśli poprawka wydaje się oczywista.
- Nie czytaj `.env`, `*.tfvars`, `credentials` — są celowo poza repo i poza zakresem audytu.
