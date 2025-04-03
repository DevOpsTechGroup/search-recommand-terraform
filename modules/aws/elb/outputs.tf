# modules/aws/load_balancer/outputs.tf

# 생성된 ALB N개의 ARN 반환
output "alb_arns" {
  description = "생성된 N개의 ALB의 ARN 반환"
  value = {
    for key, value in aws_lb.alb : key => value.arn
  }
}

# 생성된 N개의 ALB의 DNS 반환
output "alb_dns_names" {
  description = "생성된 N개의 ALB의 DNS 반환"
  value = {
    for key, value in aws_lb.alb : key => value.dns_name
  }
}

# 생성된 N개의 TG의 ARN 반환
output "alb_target_group_arn" {
  description = "생성된 N개의 TG의 ARN 반환"
  value = {
    for key, value in aws_lb_target_group.target_group : key => value.arn
  }
}

# 생성된 N개의 ALB의 listener ARN 반환
output "alb_listener_arn" {
  description = "생성된 N개의 ALB의 listener ARN 반환"
  value = {
    for key, value in aws_lb_listener.alb_listener : key => value.arn
  }
}
