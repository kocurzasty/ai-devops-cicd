output "nazwa_budzetu" {
  description = "Nazwa budżetu — do wyszukania w konsoli Billing → Budgets"
  value       = aws_budgets_budget.konto.name
}

output "arn_budzetu" {
  description = "ARN budżetu"
  value       = aws_budgets_budget.konto.arn
}
