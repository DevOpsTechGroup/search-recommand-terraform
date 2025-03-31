locals {
  # 리소스 생성여부 지정
  create_ec2_instance                    = true
  create_ec2_instance_state              = true
  create_ec2_security_group              = true
  create_ec2_security_group_ingress_rule = true
  create_ec2_security_group_egress_rule  = true
  create_tls_private_key                 = true
  create_key_pair                        = true
  create_local_file                      = true

  # EC2 security group ingress rule
  valid_ec2_security_group_ingress_rules = [
    for rule in flatten(values(var.ec2_security_group_ingress_rules)) : rule
    if rule != null &&
    rule.security_group_name != null &&
    rule.type != null &&
    rule.from_port != null &&
    rule.to_port != null &&
    length(keys(rule)) > 0
  ]

  # EC2 security group egress rule
  valid_ec2_security_group_egress_rules = [
    for rule in flatten(values(var.ec2_security_group_egress_rules)) : rule
    if rule != null &&
    rule.security_group_name != null &&
    rule.type != null &&
    rule.from_port != null &&
    rule.to_port != null &&
    length(keys(rule)) > 0
  ]
}
