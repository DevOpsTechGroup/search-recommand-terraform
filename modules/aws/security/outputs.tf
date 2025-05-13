# modules/aws/security/outputs.tf

# TODO: ALB는 N개의 보안그룹을 저장할 수 있도록 수정 필요

# 생성된 ALB 보안 그룹의 ARN 반환
output "alb_security_group_arn" {
  description = "생성된 ALB 보안 그룹의 ARN 반환"
  value = {
    for key, sg in aws_security_group.alb_security_group : key => sg.arn
  }
}

# 생성된 ALB 보안 그룹의 ID 반환
output "alb_security_group_id" {
  description = "생성된 ALB 보안 그룹의 ID 반환"
  value = {
    for key, sg in aws_security_group.alb_security_group : key => sg.id
  }
}

# 생성된 ECS 보안 그룹의 ARN 반환
output "ecs_security_group_arn" {
  description = "생성된 ECS 보안 그룹의 ARN 반환"
  value = {
    for key, value in aws_security_group.ecs_security_group : key => value.arn
  }
}

# 생성된 ECS 보안 그룹의 ID 반환
output "ecs_security_group_id" {
  description = "생성된 ECS 보안 그룹의 ID 반환"
  value = {
    for key, value in aws_security_group.ecs_security_group : key => value.id
  }
}

# 생성된 EC2 보안 그룹의 ARN 반환
output "ec2_security_group_arn" {
  description = "생성된 EC2 보안 그룹의 ARN 반환"
  value = {
    for key, value in aws_security_group.ec2_security_group : key => value.arn
  }
}

# 생성된 EC2 보안 그룹의 ID 반환
output "ec2_security_group_id" {
  description = "생성된 EC2 보안 그룹의 ID 반환"
  value = {
    for key, value in aws_security_group.ec2_security_group : key => value.id
  }
}

# 모든 보안그룹 ID만 합쳐서 반환
output "all_security_group_id" {
  description = "모든 보안그룹 ID만 합쳐서 반환"
  value = merge(
    { for key, value in aws_security_group.alb_security_group : key => value.id },
    { for key, value in aws_security_group.ecs_security_group : key => value.id },
    { for key, value in aws_security_group.ec2_security_group : key => value.id }
  )
}
