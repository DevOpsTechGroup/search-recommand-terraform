# modules/aws/acm/outputs.tf
output "acm_certificate_arn" {
  description = "ACM ARN 정보 반환"
  value = {
    for key, value in aws_acm_certificate.acm_certificate : key => value.arn
  }
}

output "acm_domain_validation_options" {
  description = "ACM 도메인 소유권 DNS 레코드 정보"
  value = {
    for key, value in aws_acm_certificate.acm_certificate : key => value.domain_validation_options
  }
}
