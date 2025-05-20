# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate#example-usage
# ACM SSL/TLS 인증서 생성 요청
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
