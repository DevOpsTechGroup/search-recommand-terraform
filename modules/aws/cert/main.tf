# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate#example-usage
# ACM SSL/TLS 인증서 생성
resource "aws_acm_certificate" "acm_certificate" {
  for_each = var.acm_certificate

  domain_name               = each.value.domain_name                 # ACM 인증서를 발급할 도메인명
  validation_method         = each.value.validation_method           # ACM 인증서 발급 방법(DNS, EMAIL) 소유권 검증
  subject_alternative_names = [each.value.subject_alternative_names] # ACM 인증서 서브 도메인 지정

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${each.value.domain_name}-${each.value.env}"
  })
}

# Route53 레코드 생성
# resource "aws_route53_record" "route53_record" {
#   for_each = {
#     for cert_key, cert_val in aws_acm_certificate.acm_certificate : 
#       for dvo in cert_val.domain_validation_options :
#   }

#   zone_id         = data.aws_route53_zone.route53_zone.id
#   name            = each.value.name
#   type            = each.value.type
#   ttl             = each.value.ttl
#   records         = [each.value.record]
#   allow_overwrite = each.value.allow_overwrite
# }
