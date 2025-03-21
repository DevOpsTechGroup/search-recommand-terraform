locals {
  project_name = var.project_name               # 프로젝트 이름
  env          = var.env                        # 환경변수
  az_count     = length(var.availability_zones) # 가용영역 개수

  # ECS Service 생성 여부(true: 생성, false: 생성 x)
  create_ecs_service = false

  # ECS 보안그룹 관련 변수 지정
  ecs_security_group_rules = {
    ingress_rules = {
      "http-alb" = {
        referenced_security_group_id = var.alb_security_group_id # ALB 보안그룹 생성 후 module에서 받아와야함
        from_port                    = 80
        ip_protocol                  = "tcp"
        to_port                      = 80
        type                         = "ingress"
      }
      "https-alb" = {
        referenced_security_group_id = var.alb_security_group_id
        from_port                    = 443
        ip_protocol                  = "tcp"
        to_port                      = 443
        type                         = "ingress"
      }
    }
    egress_rules = {
      "all" = {
        cidr_ipv4   = "0.0.0.0/0"
        from_port   = 0
        ip_protocol = -1
        to_port     = 0
      }
    }
  }
}
