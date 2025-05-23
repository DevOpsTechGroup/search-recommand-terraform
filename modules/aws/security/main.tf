# ALB security group
resource "aws_security_group" "alb_security_group" {
  for_each = var.alb_security_group

  name        = each.value.security_group_name
  description = each.value.description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = [
      for rule in local.alb_ingress_rules_flat : rule if rule.security_group_name == each.value.security_group_name
    ]
    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      description     = ingress.value.description
      cidr_blocks     = ingress.value.cidr_ipv4 != null ? [ingress.value.cidr_ipv4] : []
      security_groups = ingress.value.security_groups != null ? [ingress.value.security_groups] : []
    }
  }

  dynamic "egress" {
    for_each = [
      for rule in local.alb_egress_rules_flat : rule if rule.security_group_name == each.value.security_group_name
    ]
    content {
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      description     = egress.value.description
      cidr_blocks     = egress.value.cidr_ipv4 != null ? [egress.value.cidr_ipv4] : []
      security_groups = egress.value.security_groups != null ? [egress.value.security_groups] : []
    }
  }

  tags = merge(var.tags, {
    Name = "${each.value.security_group_name}-${each.value.env}"
  })
}

# ECS security group
resource "aws_security_group" "ecs_security_group" {
  for_each = var.ecs_security_group

  name        = each.value.security_group_name # 보안그룹명
  description = each.value.description         # 보안그룹 내용
  vpc_id      = var.vpc_id                     # module에서 넘겨 받아야함

  dynamic "ingress" {
    for_each = [
      for rule in local.ecs_ingress_rules_flat : rule if rule.security_group_name == each.value.security_group_name
    ]
    content {
      to_port         = ingress.value.to_port
      from_port       = ingress.value.from_port
      protocol        = ingress.value.protocol
      description     = ingress.value.description
      cidr_blocks     = ingress.value.cidr_ipv4 != null ? [ingress.value.cidr_ipv4] : []
      security_groups = ingress.value.security_groups != null ? [ingress.value.security_groups] : []
    }
  }

  dynamic "egress" {
    for_each = [
      for rule in local.ecs_egress_rules_flat : rule if rule.security_group_name == each.value.security_group_name
    ]
    content {
      to_port         = egress.value.to_port
      from_port       = egress.value.from_port
      protocol        = egress.value.protocol
      description     = egress.value.description
      cidr_blocks     = egress.value.cidr_ipv4 != null ? [egress.value.cidr_ipv4] : []
      security_groups = egress.value.security_groups != null ? [egress.value.security_groups] : []
    }
  }

  tags = merge(var.tags, {
    Name = "${each.value.security_group_name}-${each.value.env}"
  })
}

# EC2 security group
resource "aws_security_group" "ec2_security_group" {
  for_each = var.ec2_security_group

  name        = each.value.security_group_name # 보안그룹명
  description = each.value.description         # 보안그룹 내용
  vpc_id      = var.vpc_id                     # module에서 넘겨 받아야함

  dynamic "ingress" {
    for_each = [
      for rule in local.ec2_ingress_rules_flat : rule if rule.security_group_name == each.value.security_group_name
    ]
    content {
      to_port         = ingress.value.to_port
      from_port       = ingress.value.from_port
      protocol        = ingress.value.protocol
      description     = ingress.value.description
      cidr_blocks     = ingress.value.cidr_ipv4 != null ? [ingress.value.cidr_ipv4] : []
      security_groups = ingress.value.security_groups != null ? [ingress.value.security_groups] : []
    }
  }

  dynamic "egress" {
    for_each = [
      for rule in local.ec2_egress_rules_flat : rule if rule.security_group_name == each.value.security_group_name
    ]
    content {
      to_port         = egress.value.to_port
      from_port       = egress.value.from_port
      protocol        = egress.value.protocol
      description     = egress.value.description
      cidr_blocks     = egress.value.cidr_ipv4 != null ? [egress.value.cidr_ipv4] : []
      security_groups = egress.value.security_groups != null ? [egress.value.security_groups] : []
    }
  }

  tags = merge(var.tags, {
    Name = "${each.value.security_group_name}-${each.value.env}"
  })
}
