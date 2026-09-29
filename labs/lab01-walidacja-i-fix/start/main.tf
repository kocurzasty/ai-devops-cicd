# Moduł logów aplikacji quotes-api.
# Napisany przez asystenta AI, przeszedł `terraform validate` i trafił do PR.
# Twoje zadanie: znaleźć, co jest z nim nie tak.

locals {
  prefix = "szkolenie-lab01-${var.uczestnik}"
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "logi" {
  description         = "Klucz do szyfrowania bucketu z logami kolektora (${local.prefix})"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PelnyDostepKontaAWS"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "UzycieKluczaPrzezKolektora"
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.kolektor.arn }
        Action    = ["kms:GenerateDataKey", "kms:Decrypt"]
        Resource  = "*"
      }
    ]
  })

  tags = {
    Projekt   = "ai-devops-cicd"
    Uczestnik = var.uczestnik
    Blok      = "lab01"
    Usuwac    = "tak"
  }
}

resource "aws_kms_alias" "logi" {
  name          = "alias/${local.prefix}-logs"
  target_key_id = aws_kms_key.logi.key_id
}

resource "aws_s3_bucket" "logi" {
  bucket = "${local.prefix}-logs"

  tags = {
    Projekt   = "ai-devops-cicd"
    Uczestnik = var.uczestnik
    Blok      = "lab01"
    Usuwac    = "tak"
  }
}

resource "aws_s3_bucket_versioning" "logi" {
  bucket = aws_s3_bucket.logi.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "logi" {
  bucket = aws_s3_bucket.logi.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logi" {
  bucket = aws_s3_bucket.logi.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.logi.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logi" {
  bucket = aws_s3_bucket.logi.id

  rule {
    id     = "sprzatanie-logow"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket" "logi_dostep" {
  bucket = "${local.prefix}-logs-access"

  tags = {
    Projekt   = "ai-devops-cicd"
    Uczestnik = var.uczestnik
    Blok      = "lab01"
    Usuwac    = "tak"
  }
}

resource "aws_s3_bucket_versioning" "logi_dostep" {
  bucket = aws_s3_bucket.logi_dostep.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "logi_dostep" {
  bucket = aws_s3_bucket.logi_dostep.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 access logging wymaga docelowego bucketu szyfrowanego SSE-S3 (AES256) —
# AWS nie wspiera KMS jako celu dostawy logów dostępu.
resource "aws_s3_bucket_server_side_encryption_configuration" "logi_dostep" {
  bucket = aws_s3_bucket.logi_dostep.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logi_dostep" {
  bucket = aws_s3_bucket.logi_dostep.id

  rule {
    id     = "sprzatanie-logow-dostepu"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_logging" "logi" {
  bucket = aws_s3_bucket.logi.id

  target_bucket = aws_s3_bucket.logi_dostep.id
  target_prefix = "access-logs/"
}

resource "aws_iam_role" "kolektor" {
  name = "${local.prefix}-collector"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Projekt   = "ai-devops-cicd"
    Uczestnik = var.uczestnik
    Blok      = "lab01"
    Usuwac    = "tak"
  }
}

resource "aws_iam_role_policy" "kolektor" {
  name = "${local.prefix}-write-logs"
  role = aws_iam_role.kolektor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${aws_s3_bucket.logi.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["kms:GenerateDataKey", "kms:Decrypt"]
        Resource = aws_kms_key.logi.arn
      }
    ]
  })
}

resource "aws_security_group" "kolektor" {
  name        = "${local.prefix}-collector"
  description = "Kolektor logow"
  vpc_id      = var.vpc_id

  ingress {
    description = "Syslog z sieci wewnetrznej"
    from_port   = 514
    to_port     = 514
    protocol    = "tcp"
    cidr_blocks = [var.kolektor_cidr]
  }

  egress {
    description = "HTTPS do S3"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Projekt   = "ai-devops-cicd"
    Uczestnik = var.uczestnik
    Blok      = "lab01"
    Usuwac    = "tak"
  }
}
