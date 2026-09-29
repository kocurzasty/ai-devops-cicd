variable "uczestnik" {
  description = "Twój identyfikator — wchodzi w nazwy zasobów"
  type        = string
}

variable "vpc_id" {
  description = "ID VPC, w której działa kolektor"
  type        = string
}

variable "kolektor_cidr" {
  description = "CIDR sieci wewnętrznej, z której kolektor przyjmuje syslog po porcie 514"
  type        = string
}
