# Budżet kosztów konta szkoleniowego. Konwencje nazw i tagów: .claude/CLAUDE.md
#
# To jest ALARM, nie hamulec: budżet wysyła e-mail, niczego nie zatrzymuje ani nie usuwa.
# Dane o kosztach AWS odświeża kilka razy dziennie, więc powiadomienie przychodzi
# z opóźnieniem liczonym w godzinach.

locals {
  prefix = "szkolenie-${var.blok}-budzet-${var.uczestnik}"

  tags = {
    Projekt   = "ai-devops-cicd"
    Uczestnik = var.uczestnik
    Blok      = var.blok
    Usuwac    = "tak"
  }
}

resource "aws_budgets_budget" "konto" {
  name         = local.prefix
  budget_type  = "COST"
  limit_amount = format("%.2f", var.limit_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Bez cost_filter budżet obejmuje koszt CAŁEGO konta, nie tylko zasobów tego uczestnika.
  # Dla ograniczenia do zasobów z tagiem trzeba najpierw aktywować tag `Projekt`
  # jako cost allocation tag w Billing — inaczej filtr zwraca zero.

  dynamic "notification" {
    for_each = toset(var.progi_procent)

    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "FORECASTED"
      subscriber_email_addresses = [var.email_powiadomien]
    }
  }

  tags = local.tags
}
