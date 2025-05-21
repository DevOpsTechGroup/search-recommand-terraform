# Route53 호스팅 영역 생성
resource "aws_route53_zone" "route53_domain_from_acm" {
  for_each = var.route53_domain_from_acm
  name     = each.value.name
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
# Route53 레코드 생성
# resource "aws_route53_record" "route53_record_from_acm" {

#   zone_id         = aws_route53_zone.route53_domain_from_acm.id # Route53 호스팅 영역 참조
#   name            = each.value.name
#   type            = each.value.type
#   ttl             = each.value.ttl
#   records         = [each.value.record]
#   allow_overwrite = each.value.allow_overwrite

#   depends_on = [
#     aws_route53_zone.route53_domain_from_acm
#   ]
# }

# ACM 없이 Route53만 만들어야 하는 경우 사용
# resource "aws_route53_record" "route53_record_menual" {
# }
