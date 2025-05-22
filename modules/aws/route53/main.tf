# Route53 호스팅 영역 가져오기
data "aws_route53_zone" "route53_zone_import" {
  for_each = {
    for key, value in var.route53_zone_settings : key => value if value.mode == "import"
  }

  name         = each.value.name
  private_zone = false
}

# Route53 호스팅 영역 생성
resource "aws_route53_zone" "route53_zone_create" {
  for_each = {
    for key, value in var.route53_zone_settings : key => value if value.mode == "create"
  }

  name = each.value.name
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
# Route53 레코드 생성
resource "aws_route53_record" "route53_record" {

  name            = each.value.name
  type            = each.value.type
  ttl             = each.value.ttl
  records         = [each.value.record]
  allow_overwrite = each.value.allow_overwrite

  zone_id = aws_route53_zone.route53_zone.id # Route53 호스팅 영역 참조

  depends_on = [
    aws_route53_zone.route53_zone
  ]
}
