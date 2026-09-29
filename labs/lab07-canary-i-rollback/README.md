# Lab 07 — canary i wycofanie

**Blok 4 · 30 minut**

## Zadanie

Wdróż nową wersję jako canary, zauważ, że coś jest z nią nie tak, i wycofaj ją —
zanim zobaczy ją cały ruch.

Wszystkie polecenia uruchamiaj z głównego katalogu repozytorium:

```bash
cd "$(git rev-parse --show-toplevel)"
set -a; source .env; set +a
export NS=$UCZESTNIK
L=labs/lab07-canary-i-rollback/start

kubectl apply -n $NS -f $L/flagd.yaml -f $L/service.yaml -f $L/ingress.yaml \
  -f $L/analysis.yaml -f $L/hpa.yaml
# rollout.yaml ma w miejscu obrazu znacznik PODMIEN_NA_ECR — podstawiamy adres z .env
sed "s|PODMIEN_NA_ECR/quotes-api:v1|${ECR_REPO}:v1|" $L/rollout.yaml | kubectl apply -n $NS -f -
```

W `start/` jest komplet manifestów — lab działa niezależnie od tego, co robiłeś wcześniej.
Obrazy `v1` i `v2-broken` przygotował prowadzący. Adres ALB pojawia się po 2–3 minutach.

### Etap 1 — stan wyjściowy (5 min)

```bash
kubectl argo rollouts get rollout quotes-api -n $NS
```

Otwórz `http://` + adres z `kubectl get ingress -n $NS`. Baner ma być niebieski (v1).
W drugim terminalu, też z głównego katalogu repo, puść obciążenie i zostaw je działające —
bez ruchu nie będzie czego mierzyć:

```bash
set -a; source .env; set +a
./scripts/obciaz.sh $UCZESTNIK 1800    # 30 min; bez liczby skończy się po 5 min, w trakcie analizy
```

### Etap 2 — canary (10 min)

```bash
kubectl argo rollouts set image quotes-api "quotes-api=${ECR_REPO}:v2-broken" -n $NS
kubectl argo rollouts get rollout quotes-api -n $NS --watch
```

Obserwuj podział ruchu i odświeżaj przeglądarkę. Canary ma baner szary z napisem
`v2-broken` i dostaje ok. 10% ruchu — na kilkudziesięciu odświeżeniach zobaczysz go kilka razy.

### Etap 3 — diagnoza (10 min)

Otwórz dashboard `quotes-api` w Grafanie (adres i hasło od prowadzącego).
Odpowiedz sobie na trzy pytania:

1. Jaki odsetek odpowiedzi 5xx ma canary, a jaki stable?
2. Kiedy dokładnie zaczął rosnąć?
3. Czy `AnalysisRun` już zareagował, czy jeszcze zbiera dane?

```bash
kubectl get analysisrun -n $NS
kubectl describe analysisrun -n $NS | tail -30
```

### Etap 4 — wycofanie (5 min)

Automat potrzebuje ok. 5 minut (2 minuty zbierania danych, potem trzy pomiary co minutę).
Jeśli zdążył pierwszy — świetnie, opisz, co się stało i na jakiej podstawie.
Jeśli nie, wycofaj ręcznie:

```bash
kubectl argo rollouts undo quotes-api -n $NS
```

Potwierdź, że ruch wrócił w całości na v1.

## Podpowiedzi

<details>
<summary>Podpowiedź 1 — rollout stoi i nic się nie dzieje</summary>

Krok `pause: {}` bez `duration` czeka na człowieka:

```bash
kubectl argo rollouts promote quotes-api -n $NS
```

Sprawdź, na którym kroku stoisz: `kubectl argo rollouts get rollout quotes-api -n $NS`.
</details>

<details>
<summary>Podpowiedź 1a — pody w ImagePullBackOff albo rollout „zawieszony" od startu</summary>

Sprawdź adres obrazu: `kubectl get rollout quotes-api -n $NS -o jsonpath='{..image}'`.
Pusty `ECR_REPO` albo zapis `$ECR_REPO:tag` w zsh (dla tagów zaczynających się na t, h, u, r, e)
daje błędny adres — pisz `${ECR_REPO}:tag`.

Jeśli pierwsza wersja nigdy nie wstała, Rollout nie ma zdrowego stable i kolejne zmiany
się na nim blokują. Najprościej: `kubectl delete rollout quotes-api -n $NS` i ponowne
`sed … | kubectl apply` z poprawnym adresem.
</details>

<details>
<summary>Podpowiedź 2 — AnalysisRun w stanie Inconclusive</summary>

Zapytanie liczy odsetek błędów, więc przy zerowym ruchu dzieli przez zero i pomiar kończy się
błędem. Upewnij się, że `./scripts/obciaz.sh` naprawdę działa i że trafia na właściwy adres.

Jeśli rollout przerwał się **w pierwszej minucie** z komunikatem `consecutiveErrors`,
to nie bramka złapała błąd, tylko zapytanie nie dostało danych. Sprawdź w `describe analysisrun`,
co zwrócił pomiar — to różnica, którą trzeba umieć rozpoznać.
</details>

<details>
<summary>Podpowiedź 3 — wykres pokazuje jedną linię zamiast dwóch</summary>

Panel dzieli dane po etykiecie `wersja` — to hash szablonu poda (`rollouts-pod-template-hash`),
który dokłada kolektor OpenTelemetry. Aplikacja sama eksportuje też `version` (v1, v2-broken).
Jeśli `wersja` nie ma, sprawdź adnotacje `prometheus.io/scrape` na podach canary — nowe pody
muszą je mieć tak samo jak stare. Hash stable i canary odczytasz z
`kubectl get pods -n $NS -L rollouts-pod-template-hash`.
</details>

## Weryfikacja

```bash
kubectl argo rollouts get rollout quotes-api -n $NS
```

Rollout w stanie `Healthy`, obraz na `v1`, 100% ruchu na stable. Po `abort` (albo po przerwaniu
przez analizę) Rollout zostaje w stanie `Degraded`, dopóki nie zrobisz `undo` — ruch jest już
na stable, ale specyfikacja nadal wskazuje zepsuty obraz.

Zatrzymaj `./scripts/obciaz.sh` (Ctrl+C).

## Pułapki

**`argocd app rollback` przy włączonym auto-sync.** Jeśli aplikacją zarządza Argo CD
z auto-sync, rollback zostanie cofnięty w ciągu kilkudziesięciu sekund — Argo zobaczy
różnicę wobec repozytorium i zsynchronizuje z powrotem. W GitOps wycofanie to `git revert`,
nie komenda na klastrze.

**Rollback cofa obraz, nie skutki.** Wiersze, które zła wersja zdążyła zapisać do bazy,
zostają. Wiadomości, które wysłała — też. Rollback jest tani tylko w warstwie, w której działa.

**Zaufanie do automatycznej bramki.** `AnalysisTemplate` patrzy na odsetek 5xx.
Aplikacja, która zwraca 200 z błędem w treści odpowiedzi, przejdzie tę bramkę bez zająknięcia.
Bramka jest tak dobra, jak metryka, na której stoi.
