locals {
  project_name = var.project_name               # 프로젝트 이름
  env          = var.env                        # 환경변수
  az_count     = length(var.availability_zones) # 가용영역 개수

  # ALB 보안그룹 관련 변수 지정
  alb_security_group_rules = {
    ingress_rules = {
      "http-ingress" = {
        type        = "ingress"
        description = "Allow HTTP traffic from anywhere"
        from_port   = 80
        to_port     = 80
        ip_protocol = "tcp"
        cidr_ipv4   = "0.0.0.0/0"
      }
      "https-ingress" = {
        type        = "ingress"
        description = "Allow HTTPS traffic from anywhere"
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
        cidr_ipv4   = "0.0.0.0/0"
      }
    }
    egress_rules = {
      "all" = {
        type        = "egress"
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        ip_protocol = -1
        cidr_ipv4   = "0.0.0.0/0"
      }
    }
  }
}
