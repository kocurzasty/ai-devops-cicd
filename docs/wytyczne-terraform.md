# Wytyczne dla Terraforma

Ten dokument opisuje reguły, które musi spełniać każdy plan Terraform w tym repozytorium.
Reguły są wymuszane automatycznie przez politykę OPA/Rego w
`tmp/conftest/policy/terraform.rego`, uruchamianą przez `conftest` na wygenerowanym
planie (nie na plikach `.tf`):

```bash
terraform plan -out=tfplan && terraform show -json tfplan > plan.json
conftest test --policy tmp/conftest/policy plan.json
```

Conftest sprawdza plan, bo dopiero tam widać wartości po rozwinięciu zmiennych i modułów —
czyli to, co naprawdę powstanie w AWS.

## S3 — bucket zawsze szyfrowany i bez publicznego dostępu

- Każdy tworzony `aws_s3_bucket` musi mieć towarzyszący
  `aws_s3_bucket_server_side_encryption_configuration` (dopasowywany po nazwie bucketu).
- Każdy tworzony `aws_s3_bucket` musi mieć towarzyszący `aws_s3_bucket_public_access_block`.

To pokrywa się z konwencją repo: bucket S3 = szyfrowanie włączone, publiczny dostęp
zablokowany, wersjonowanie włączone.

## Security groups — z internetu wyłącznie 443

- W `aws_vpc_security_group_ingress_rule` reguła z `cidr_ipv4 = "0.0.0.0/0"` może mieć
  tylko `from_port = 443`. Każdy inny port z `0.0.0.0/0` jest odrzucany.
- Analogicznie w `aws_security_group` (starszy, inline styl): reguła `ingress` z
  `0.0.0.0/0` w `cidr_blocks` może mieć tylko `from_port = 443`.
- Dla innych portów: zawężaj CIDR albo wpuszczaj ruch przez bastion/VPN, nigdy przez
  otwarty internet.

## IAM — bez wildcardów w Action i bez luźnego Resource "*"

- W `aws_iam_role_policy` i `aws_iam_policy`, dla stwierdzeń z `Effect = "Allow"`:
  - **Action** nie może zawierać wildcardu — ani `"*"`, ani formy `"s3:*"` (wygląda
    niewinnie, ale obejmuje też operacje kasujące). Wypisuj konkretne akcje, których
    aplikacja faktycznie używa.
  - **Resource** nie może być `"*"`, chyba że *wszystkie* akcje w danym stwierdzeniu są
    akcjami działającymi na poziomie konta — pasującymi do wzorca
    `:(Describe|List|Get)[A-Za-z]*$` (np. `ec2:DescribeInstances`). Tylko dla takich akcji
    `Resource = "*"` jest dopuszczalne, bo inaczej nie da się ich zawęzić do ARN-u.

## Tagi — komplet wymaganych tagów na każdym zasobie AWS

- Każdy tworzony zasób zaczynający się od `aws_`, jeśli w ogóle ma sekcję `tags`, musi
  mieć w niej wszystkie cztery klucze: `Projekt`, `Uczestnik`, `Blok`, `Usuwac`.
- Zasób bez żadnych tagów nie jest łapany przez tę regułę (ostrzeżenie, nie blokada) —
  ale zgodnie z konwencją repo tagi i tak są obowiązkowe na każdym zasobie AWS.
- Bez kompletu tagów `cleanup/sprawdz-koszty.sh` nie znajdzie zasobu po zakończeniu
  szkolenia — zostanie osierocony i będzie dalej generował koszty.

## Jak z tego korzystać przy pisaniu Terraforma

1. Zawsze parami: `aws_s3_bucket` + encryption config + public access block.
2. Zawsze `variable` z jawnym `type` i `description` (osobna konwencja repo, patrz
   `.claude/CLAUDE.md`).
3. Reguły ingress z `0.0.0.0/0` — tylko port 443. Wszystko inne przez zawężony CIDR.
4. Polityki IAM pisz akcja po akcji, bez `*` ani `service:*`. `Resource = "*"` tylko dla
   akcji Describe/List/Get.
5. Każdy zasób AWS: tagi `Projekt`, `Uczestnik`, `Blok`, `Usuwac = tak`.
6. Nie uciszaj naruszeń przez pominięcie polityki czy komentarze w stylu
   `#tfsec:ignore` — napraw przyczynę (patrz „Czego nie rób" w `.claude/CLAUDE.md`).

Pełna treść reguł: `tmp/conftest/policy/terraform.rego`.
