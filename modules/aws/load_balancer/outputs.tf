# modules/aws/load_balancer/outputs.tf

# 생성된 ALB N개의 ARN 반환
output "alb_arns" {
  description = "생성된 N개의 ALB의 ARN 반환"
  value = {
    for key, alb in aws_lb.alb : key => alb.arn
  }
}

# 생성된 N개의 ALB의 DNS 반환
output "alb_dns_names" {
  description = "생성된 N개의 ALB의 DNS 반환"
  value = {
    for key, alb in aws_lb.alb : key => alb.dns_name
  }
}

# 생성된 N개의 TG의 ARN 반환
output "alb_target_group_arn" {
  description = "생성된 N개의 TG의 ARN 반환"
  value = {
    for key, target_group in aws_lb_target_group.target_group : key => target_group.arn
  }
}

# 생성된 N개의 ALB의 listener ARN 반환
output "alb_listener_arn" {
  description = "생성된 N개의 ALB의 listener ARN 반환"
  value = {
    for key, listener in aws_lb_listener.alb_listener : key => listener.arn
  }
}

# 생성된 ALB 보안 그룹의 ARN 반환
output "alb_security_group_arn" {
  description = "생성된 ALB 보안 그룹의 ARN 반환"
  value       = aws_security_group.alb_security_group.arn
}

# 생성된 ALB 보안 그룹의 ID 반환
output "alb_security_group_id" {
  description = "생성된 ALB 보안 그룹의 ID 반환"
  value       = aws_security_group.alb_security_group.id
}