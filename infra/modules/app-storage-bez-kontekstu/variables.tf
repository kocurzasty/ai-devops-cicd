variable "region" {
  default = "us-east-1"
}

variable "bucket_name" {
  type    = string
  default = "app-artifacts-bucket"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "environment" {
  type    = string
  default = "dev"
}
