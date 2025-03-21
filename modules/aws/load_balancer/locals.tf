locals {
  project_name = var.project_name               # 프로젝트 이름
  env          = var.env                        # 환경변수
  az_count     = length(var.availability_zones) # 가용영역 개수

  alb_security_group_rules = {
    ingress_rules = {
      "http-ingress" = {
        cidr_ipv4   = "0.0.0.0/0" # 외부 트래픽 허용
        from_port   = 80
        ip_protocol = "tcp"
        to_port     = 80
        type        = "ingress"
        description = "Allow HTTP traffic from anywhere"
      }
      "https-ingress" = {
        cidr_ipv4   = "0.0.0.0/0" # 외부 트래픽 허용
        from_port   = 443
        ip_protocol = "tcp"
        to_port     = 443
        type        = "ingress"
        description = "Allow HTTPS traffic from anywhere"
      }
    }
    egress_rules = {
      "all-outbound" = {
        cidr_ipv4   = "0.0.0.0/0" # 모든 외부로 트래픽 허용
        from_port   = 0
        ip_protocol = -1 # 모든 프로토콜 허용
        to_port     = 0
        description = "Allow all outbound traffic"
      }
    }
  }
}