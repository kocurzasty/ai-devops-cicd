# Infrastruktura pod quotes-api. Konwencje nazw i tagów: .claude/CLAUDE.md

locals {
  prefix = "szkolenie-${var.blok}"

  tags = {
    Projekt   = "ai-devops-cicd"
    Uczestnik = var.uczestnik
    Blok      = var.blok
    Usuwac    = "tak"
  }
}

data "aws_availability_zones" "dostepne" {
  state = "available"
}

# ── Bucket S3 na artefakty buildów ──────────────────────────────────────

resource "aws_s3_bucket" "artefakty" {
  bucket = "${local.prefix}-artifacts-${var.uczestnik}"

  tags = merge(local.tags, {
    Name = "${local.prefix}-artifacts-${var.uczestnik}"
  })
}

resource "aws_s3_bucket_versioning" "artefakty" {
  bucket = aws_s3_bucket.artefakty.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artefakty" {
  bucket = aws_s3_bucket.artefakty.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Bez tego zasobu bucket jest prywatny tylko dopóki ktoś nie doda mu polityki.
resource "aws_s3_bucket_public_access_block" "artefakty" {
  bucket = aws_s3_bucket.artefakty.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── VPC z podsiecią publiczną i prywatną ─────────────────────────────────

resource "aws_vpc" "glowna" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name = "${local.prefix}-vpc-${var.uczestnik}"
  })
}

resource "aws_internet_gateway" "glowna" {
  vpc_id = aws_vpc.glowna.id

  tags = merge(local.tags, {
    Name = "${local.prefix}-igw-${var.uczestnik}"
  })
}

resource "aws_subnet" "publiczna" {
  vpc_id                  = aws_vpc.glowna.id
  cidr_block              = cidrsubnet(var.cidr_vpc, 8, 1)
  availability_zone       = data.aws_availability_zones.dostepne.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${local.prefix}-subnet-publiczna-${var.uczestnik}"
  })
}

resource "aws_subnet" "prywatna" {
  vpc_id                  = aws_vpc.glowna.id
  cidr_block              = cidrsubnet(var.cidr_vpc, 8, 2)
  availability_zone       = data.aws_availability_zones.dostepne.names[1]
  map_public_ip_on_launch = false

  tags = merge(local.tags, {
    Name = "${local.prefix}-subnet-prywatna-${var.uczestnik}"
  })
}

resource "aws_route_table" "publiczna" {
  vpc_id = aws_vpc.glowna.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.glowna.id
  }

  tags = merge(local.tags, {
    Name = "${local.prefix}-rt-publiczna-${var.uczestnik}"
  })
}

resource "aws_route_table_association" "publiczna" {
  subnet_id      = aws_subnet.publiczna.id
  route_table_id = aws_route_table.publiczna.id
}

# ── Security group aplikacji ─────────────────────────────────────────────
# Tylko HTTPS z internetu, bez NAT dla podsieci prywatnej — poza zakresem tego zadania.

resource "aws_security_group" "aplikacja" {
  name        = "${local.prefix}-sg-app-${var.uczestnik}"
  description = "Security group aplikacji quotes-api — wyłącznie HTTPS"
  vpc_id      = aws_vpc.glowna.id

  tags = merge(local.tags, {
    Name = "${local.prefix}-sg-app-${var.uczestnik}"
  })
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.aplikacja.id
  description       = "HTTPS z internetu"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# Wyjście zawężone do HTTPS — domyślne "wszystko wszędzie" przechodzi przez skanery,
# ale to właśnie tą drogą wychodzą dane po udanym włamaniu.
resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.aplikacja.id
  description       = "Ruch wychodzacy HTTPS - ECR, API AWS"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}
