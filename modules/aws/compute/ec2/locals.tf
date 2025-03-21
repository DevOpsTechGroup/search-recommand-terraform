locals {

  # EC2 보안그룹 Ingress 설정
  valid_ec2_security_group_ingress_rules = [
    for rule in flatten(values(var.ec2_security_group_ingress_rules)) :
    rule if rule != null &&
    rule.ec2_security_group_name != null &&
    rule.type != null &&
    rule.from_port != null &&
    rule.to_port != null &&
    length(keys(rule)) > 0
  ]

  # EC2 보안그룹 Egress 설정
  valid_ec2_security_group_egress_rules = [
    for rule in flatten(values(var.ec2_security_group_egress_rules)) :
    rule
    if rule != null &&
    rule.ec2_security_group_name != null &&
    rule.type != null &&
    rule.from_port != null &&
    rule.to_port != null &&
    length(keys(rule)) > 0
  ]
}
