locals {
  project_name = var.project_name               # 프로젝트 이름
  env          = var.env                        # 환경변수
  az_count     = length(var.availability_zones) # 가용영역 개수

  # ECS security group ingress rule
  ecs_security_group_ingress_rules = {
    opensearch-api-sg-ingress-rule = [
      {
        create_yn                = true
        security_group_name      = "opensearch-api-sg"
        type                     = "ingress"
        description              = "opensearch api security group ingress rule"
        from_port                = 10091
        to_port                  = 10091
        protocol                 = "tcp"
        cidr_ipv4                = null
        source_security_group_id = var.alb_security_group_id
        env                      = "stg"
      }
    ],
    elasticsearch-api-sg-ingress-rule = [
      {
        create_yn                = true
        type                     = "ingress"
        security_group_name      = "elasticsearch-api-sg"
        description              = "elasticsearch api security group ingress rule"
        from_port                = 10092
        to_port                  = 10092
        protocol                 = "tcp"
        cidr_ipv4                = null
        source_security_group_id = var.alb_security_group_id
        env                      = "stg"
      }
    ]
  }

  # ECS security group egress rule
  ecs_security_group_egress_rules = {
    opensearch-api-sg-ingress-rule = [
      {
        create_yn           = true
        security_group_name = "opensearch-api-sg"
        type                = "egress"
        description         = "opensearch api security group egress rule"
        from_port           = 0
        to_port             = 0
        protocol            = "-1" # 모든 프로토콜 허용
        cidr_ipv4 = [
          "0.0.0.0/0"
        ]
        source_security_group_id = null
        env                      = "stg"
      }
    ],
    elasticsearch-api-sg-ingress-rule = [
      {
        create_yn           = true
        security_group_name = "elasticsearch-api-sg"
        type                = "egress"
        description         = "elasticsearch api security group egress rule"
        from_port           = 0
        to_port             = 0
        protocol            = "-1" # 모든 프로토콜 허용
        cidr_ipv4 = [
          "0.0.0.0/0"
        ]
        source_security_group_id = null
        env                      = "stg"
      }
    ]
  }
}
