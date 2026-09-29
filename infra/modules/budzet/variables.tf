variable "uczestnik" {
  description = "Identyfikator uczestnika — małe litery i myślniki, wchodzi w nazwy zasobów"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,20}$", var.uczestnik))
    error_message = "Dozwolone są tylko małe litery, cyfry i myślniki, od 2 do 20 znaków."
  }
}

variable "blok" {
  description = "Numer bloku szkolenia — trafia do tagów, ułatwia sprzątanie"
  type        = string
  default     = "b5"
}

variable "email_powiadomien" {
  description = "Adres e-mail, na który AWS Budgets wysyła powiadomienia o prognozowanym koszcie"
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.email_powiadomien))
    error_message = "Podaj poprawny adres e-mail."
  }
}

variable "limit_usd" {
  description = "Miesięczny limit kosztów konta w USD — od niego liczone są progi powiadomień"
  type        = number
  default     = 50

  validation {
    condition     = var.limit_usd > 0
    error_message = "Limit musi być większy od zera."
  }
}

variable "progi_procent" {
  description = "Progi powiadomień w procentach limitu, liczone od PROGNOZOWANEGO kosztu miesiąca"
  type        = list(number)
  default     = [50, 80, 100]
}
