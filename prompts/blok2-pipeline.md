# Blok 2 — GitHub Actions

## Workflow od zera

```
Napisz .github/workflows/deploy.yml dla aplikacji z katalogu app/.

Joby, w tej kolejności:
1. lint — ruff check
2. test — pytest
3. build — zbuduj obraz z app/Dockerfile i wypchnij do ECR, do repozytorium
   quotes-api-<wartość zmiennej repozytorium K8S_NAMESPACE> (każdy uczestnik ma własne)
4. deploy — wdróż na EKS manifesty z app/k8s-dzien1/ (zwykły Deployment i Service,
   bez Argo Rollouts) z obrazem zbudowanym w jobie build, w namespace ze zmiennej
   repozytorium K8S_NAMESPACE, i poczekaj, aż Deployment będzie gotowy

Wymagania:
- uwierzytelnianie do AWS przez OIDC, bez długoterminowych kluczy
- permissions na poziomie joba, minimalny zakres
- timeout-minutes na każdym jobie
- deploy tylko z gałęzi main

Wyjaśnij przy każdym jobie, dlaczego nadałeś mu takie uprawnienia.
```

Ostatnie zdanie jest ważniejsze niż wygląda — wymusza uzasadnienie zamiast `write-all`.

„Bez Argo Rollouts" jest w prompcie celowo. Kontekst projektu (`.claude/CLAUDE.md`)
mówi, że wdrożenia idą przez Rollout — to prawda od dnia 2. Bez tego zastrzeżenia agent
chętnie wybiera Rollout, którego w Twoim namespace jeszcze nie ma.

## Kontrola kosztów

```
Ten workflow zużywa około 40 minut runnera na każdy push. Obetnij to poniżej 8 minut
bez rezygnacji z żadnego kroku.

Rozważ: cache zależności, cache warstw Dockera (buildx z cache-from i cache-to),
concurrency z cancel-in-progress, uruchamianie jobów równolegle tam, gdzie nie mają
zależności, filtrowanie po paths.

Dla każdej zmiany napisz, ile minut oszczędza i skąd to wiesz.
```

**Pytanie, które warto zadać agentowi na sali:** „skąd wiesz, że 15 minut to dobry timeout?".
Odpowiedź pokazuje, gdzie kończy się wiedza, a zaczyna wypełnianie wzorca.

## Retencja artefaktów

```
Dodaj retention-days dla artefaktów: 7 dni dla wyników z PR i 90 dni dla wydań.
Wyjaśnij, z jakich danych lub wymagań wynikają te wartości. Jeśli nie masz wystarczających
danych, nazwij je przykładowymi zamiast przedstawiać jako optymalne.
```

## Promocja buildów — pierwsza, zbyt ogólna wersja

```
Przygotuj GitHub Actions dla aplikacji kontenerowej.
Po zmianie na main wdróż aplikację kolejno na dev, staging i prod.
Produkcja ma wymagać zatwierdzenia.
```

Po wygenerowaniu zapytaj: **czy produkcja dostanie dokładnie ten sam digest obrazu,
który został przetestowany na stagingu?**

## Promocja buildów — prompt z gwarancją

```
Przebuduj workflow zgodnie z zasadą build once, deploy many.

Wymagania:
- obraz budujemy dokładnie raz;
- otrzymuje niezmienny identyfikator odpowiadający pełnemu SHA commita;
- dev, staging i prod promują ten sam manifest obrazu;
- wdrożenie nie może zależeć wyłącznie od ruchomego taga;
- prod wymaga zatwierdzenia człowieka;
- workflow pokazuje digest promowanego obrazu;
- wyjaśnij, jak mechanicznie udowodnić, że staging i prod używają identycznego obrazu.
```

## Debugowanie czerwonego builda

```
Workflow padł. Pobierz logi ostatniego uruchomienia (gh run view --log-failed),
znajdź pierwszy prawdziwy błąd — nie ostatnią linię, tylko pierwszą przyczynę —
i wyjaśnij, co go wywołało. Zaproponuj poprawkę i powiedz, jak sprawdzić, że działa,
bez pushowania dziesięciu commitów.
```
