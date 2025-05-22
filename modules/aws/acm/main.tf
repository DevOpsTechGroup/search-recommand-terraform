# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate#example-usage
# ACM SSL/TLS 인증서 생성
resource "aws_acm_certificate" "acm_certificate" {
  for_each = var.acm_certificate

  domain_name               = each.value.domain_name                 # ACM 인증서를 발급할 도메인명
  subject_alternative_names = [each.value.subject_alternative_names] # ACM 인증서 서브 도메인 지정

  # mode가 create면 validation_method가 필요하고, import면 validation_method가 필요하지 않음
  validation_method = each.value.mode == "create" ? (each.value.dns_validate ? "DNS" : "EMAIL") : null

  # mode가 import 방식이면 certificate_body, private_key, certificate_chain가 필요함
  private_key       = each.value.mode == "import" ? each.value.private_key : null
  certificate_body  = each.value.mode == "import" ? each.value.certificate_body : null
  certificate_chain = each.value.mode == "import" ? each.value.certificate_chain : null

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${each.key}-${each.value.env}"
  })
}
