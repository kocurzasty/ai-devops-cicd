variable "uczestnik" {
  description = "Identyfikator uczestnika szkolenia, używany w nazwach i tagach zasobów"
  type        = string
}

variable "blok" {
  description = "Oznaczenie bloku szkoleniowego, używane w nazwach i tagach zasobów"
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
