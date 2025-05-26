# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate#example-usage
################################
# ACM SSL/TLS 인증서 생성
################################
resource "aws_acm_certificate" "create_cert" {
  for_each = {
    for key, value in var.acm_certificate : key => value
    if value.mode == "create"
  }

  domain_name               = each.value.domain_name
  subject_alternative_names = [each.value.subject_alternative_names]
  validation_method         = each.value.dns_validate ? "DNS" : "EMAIL"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${each.key}-${each.value.env}"
  })
}

################################
# ACM SSL/TLS 인증서 가져오기
################################
resource "aws_acm_certificate" "import_cert" {
  for_each = {
    for key, value in var.acm_certificate : key => value
    if value.mode == "import"
  }

  domain_name       = each.value.domain_name
  certificate_body  = each.value.certificate_body
  private_key       = each.value.private_key
  certificate_chain = each.value.certificate_chain
}

################################
# Route53 Zone 생성
################################
resource "aws_route53_zone" "create_route53_zone" {
  for_each = {
    for key, value in var.route53_zone_settings : key => value
    if value.mode == "create"
  }
  name = each.value.name
}

################################
# Route53 Zone 가져오기
################################
data "aws_route53_zone" "import_route53_zone" {
  for_each = {
    for key, value in var.route53_zone_settings : key => value
    if value.mode == "import"
  }
  name         = each.value.name
  private_zone = false
}

################################
# Route53 레코드 생성
################################
resource "aws_route53_record" "acm_validation_record" {
  for_each = local.acm_validation_records

  name            = each.value.name
  type            = each.value.type
  ttl             = 300
  records         = [each.value.record]
  allow_overwrite = true

  zone_id = try(
    aws_route53_zone.create_route53_zone[each.value.zone].zone_id,
    data.aws_route53_zone.import_route53_zone[each.value.zone].zone_id
  )

  depends_on = [
    aws_acm_certificate.create_cert
  ]
}
