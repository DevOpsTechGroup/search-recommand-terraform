locals {
  project_name = var.project_name               # 프로젝트 이름
  env          = var.env                        # 환경변수
  az_count     = length(var.availability_zones) # 가용영역 개수

  # ALB security group ingress rule
  alb_security_group_ingress_rules = {
    search-recommand-alb-sg-ingress-rule = [
      {
        create_yn           = true
        security_group_name = "search-recommand-alb-sg"
        type                = "ingress"
        description         = "search-recommand alb http security group ingress rule"
        from_port           = 80
        to_port             = 80
        protocol            = "http"
        cidr_ipv4 = [
          "220.75.180.0/24"
        ]
        source_security_group_id = null
        env                      = "stg"
      },
      {
        create_yn           = true
        security_group_name = "search-recommand-alb-sg-ingress-rule"
        type                = "ingress"
        description         = "search-recommand alb https security group ingress rule"
        from_port           = 443
        to_port             = 443
        protocol            = "https"
        cidr_ipv4 = [
          "220.75.180.0/24"
        ]
        source_security_group_id = null
        env                      = "stg"
      }
    ]
  }

  # ALB security group egress rule
  alb_security_group_egress_rules = {
    search-recommand-alb-sg-egress-rule = [
      {
        create_yn                = true
        security_group_name      = "search-recommand-alb-sg"
        type                     = "egress"
        description              = "search-recommand alb all traffic security group egress rule"
        from_port                = 0
        to_port                  = 0
        protocol                 = "-1"
        cidr_ipv4                = null
        source_security_group_id = var.ecs_security_group_id["opensearch-api-sg"] # INFO: ECS API 보안 그룹을 받아야함
        env                      = "stg"
      },
      {
        create_yn                = true
        security_group_name      = "search-recommand-alb-sg"
        type                     = "egress"
        description              = "search-recommand alb all traffic security group egress rule"
        from_port                = 0
        to_port                  = 0
        protocol                 = "-1"
        cidr_ipv4                = null
        source_security_group_id = var.ecs_security_group_id["elasticsearch-api-sg"] # INFO: ECS API 보안 그룹을 받아야함
        env                      = "stg"
      }
    ]
  }
}
