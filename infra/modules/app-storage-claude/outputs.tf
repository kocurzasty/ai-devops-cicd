output "bucket_name" {
  description = "Nazwa bucketu S3 na artefakty buildów"
  value       = aws_s3_bucket.artefakty.id
}

output "bucket_arn" {
  description = "ARN bucketu S3 na artefakty buildów"
  value       = aws_s3_bucket.artefakty.arn
}

output "vpc_id" {
  description = "ID utworzonej VPC"
  value       = aws_vpc.glowna.id
}

output "public_subnet_id" {
  description = "ID podsieci publicznej"
  value       = aws_subnet.publiczna.id
}

output "private_subnet_id" {
  description = "ID podsieci prywatnej"
  value       = aws_subnet.prywatna.id
}

output "security_group_id" {
  description = "ID security group aplikacji"
  value       = aws_security_group.aplikacja.id
}
