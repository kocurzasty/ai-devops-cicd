variable "uczestnik" {
  description = "Identyfikator uczestnika szkolenia — małe litery, cyfry i myślniki, wchodzi w nazwy i tagi zasobów"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,20}$", var.uczestnik))
    error_message = "Dozwolone są tylko małe litery, cyfry i myślniki, od 2 do 20 znaków."
  }
}

variable "blok" {
  description = "Numer bloku szkolenia — wchodzi w nazwy zasobów i tagi, ułatwia sprzątanie"
  type        = string
  default     = "b1"
}

variable "region" {
  description = "Region AWS, w którym powstają zasoby"
  type        = string
  default     = "eu-central-1"
}

variable "cidr_vpc" {
  description = "Zakres adresów CIDR dla VPC aplikacji quotes-api"
  type        = string
  default     = "10.20.0.0/16"
}
