# ALB security group
resource "aws_security_group" "alb_security_group" {
  for_each = var.alb_security_group

  name        = each.value.security_group_name
  description = each.value.description
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${each.value.security_group_name}-${each.value.env}"
  })
}

# ALB security group ingress rule
resource "aws_security_group_rule" "alb_security_group_ingress_rule" {
  for_each = {
    for idx, rule in local.alb_ingress_rules_flat :
    "${rule.security_group_name}-${rule.env}-${rule.from_port}-${rule.to_port}-${idx}" => rule
  }

  type              = each.value.type
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.alb_security_group[each.value.security_group_name].id

  cidr_blocks              = each.value.cidr_ipv4 != null ? [each.value.cidr_ipv4] : null
  source_security_group_id = each.value.source_security_group_id
}

# ALB security group egress rule
resource "aws_security_group_rule" "alb_security_group_egress_rule" {
  for_each = {
    for idx, rule in local.alb_egress_rules_flat :
    "${rule.security_group_name}-${rule.env}-${rule.from_port}-${rule.to_port}-${idx}" => rule
  }

  type              = each.value.type
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.alb_security_group[each.value.security_group_name].id

  cidr_blocks              = each.value.cidr_ipv4 != null ? [each.value.cidr_ipv4] : null
  source_security_group_id = each.value.source_security_group_id
}

# ECS security group
resource "aws_security_group" "ecs_security_group" {
  for_each = var.ecs_security_group

  name        = each.value.security_group_name # 보안그룹명
  description = each.value.description         # 보안그룹 내용
  vpc_id      = var.vpc_id                     # module에서 넘겨 받아야함

  tags = merge(var.tags, {
    Name = "${each.value.security_group_name}-${each.value.env}"
  })
}

# ECS security group ingress rule
resource "aws_security_group_rule" "ecs_ingress_security_group" {
  for_each = {
    for idx, rule in local.ecs_ingress_rules_flat :
    "${rule.security_group_name}-${rule.env}-${rule.from_port}-${rule.to_port}-${idx}" => rule
  }

  type              = each.value.type                                                          # 보안그룹 타입(ingress, egress)
  description       = each.value.description                                                   # 보안그룹 내용
  from_port         = each.value.from_port                                                     # 포트 시작 허용 범위
  to_port           = each.value.to_port                                                       # 포트 종료 허용 범위
  protocol          = each.value.protocol                                                      # 보안그룹 프로토콜(TCP.. 등)
  security_group_id = aws_security_group.ecs_security_group[each.value.security_group_name].id # 매핑되는 보안그룹명

  # 조건적으로 참조된 보안 그룹 또는 CIDR 블록 사용
  cidr_blocks              = each.value.cidr_ipv4 != null ? [each.value.cidr_ipv4] : null
  source_security_group_id = each.value.source_security_group_id
}

# ECS security group egress rule
resource "aws_security_group_rule" "ecs_egress_security_group" {
  for_each = {
    for idx, rule in local.ecs_egress_rules_flat :
    "${rule.security_group_name}-${rule.env}-${rule.from_port}-${rule.to_port}-${idx}" => rule
  }

  type              = each.value.type
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.ecs_security_group[each.value.security_group_name].id

  cidr_blocks              = each.value.cidr_ipv4 != null ? [each.value.cidr_ipv4] : null
  source_security_group_id = each.value.source_security_group_id
}

# EC2 security group
resource "aws_security_group" "ec2_security_group" {
  for_each = var.ec2_security_group

  name        = each.value.security_group_name # 보안그룹명
  description = each.value.description         # 보안그룹 내용
  vpc_id      = var.vpc_id                     # module에서 넘겨 받아야함

  tags = merge(var.tags, {
    Name = "${each.value.security_group_name}-${each.value.env}"
  })
}

# EC2 security group ingress rule
resource "aws_security_group_rule" "ec2_ingress_security_group" {
  for_each = {
    for idx, rule in local.ec2_ingress_rules_flat :
    "${rule.security_group_name}-${rule.env}-${rule.from_port}-${rule.to_port}-${idx}" => rule
  }

  description       = each.value.description                                                   # 보안그룹 DESC
  security_group_id = aws_security_group.ec2_security_group[each.value.security_group_name].id # 참조하는 보안그룹 ID
  type              = each.value.type                                                          # 타입 지정(ingress, egress)
  from_port         = each.value.from_port                                                     # 포트 시작 허용 범위
  to_port           = each.value.to_port                                                       # 포트 종료 허용 범위
  protocol          = each.value.protocol

  cidr_blocks              = each.value.cidr_ipv4 != null ? [each.value.cidr_ipv4] : null
  source_security_group_id = each.value.source_security_group_id
}

# EC2 security group egress rule
resource "aws_security_group_rule" "ec2_egress_security_group" {
  for_each = {
    for idx, rule in local.ec2_egress_rules_flat :
    "${rule.security_group_name}-${rule.env}-${rule.from_port}-${rule.to_port}-${idx}" => rule
  }

  description       = each.value.description
  security_group_id = aws_security_group.ec2_security_group[each.value.security_group_name].id # 참조하는 보안그룹 ID
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol

  cidr_blocks              = each.value.cidr_ipv4 != null ? [each.value.cidr_ipv4] : null
  source_security_group_id = each.value.source_security_group_id
}
