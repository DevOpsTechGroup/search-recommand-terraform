locals {

  # ALB security group ingress rule
  alb_security_group_ingress_rules = {
    search-recommand-alb-sg-ingress-rule = [
      {
        create_yn           = false
        security_group_name = "search-recommand-alb-sg"
        type                = "ingress"
        description         = "search-recommand alb http security group ingress rule"
        from_port           = 80
        to_port             = 80
        protocol            = "tcp"
        cidr_ipv4 = [
          "220.75.180.0/24"
        ]
        source_security_group_id = null
        env                      = "stg"
      },
      {
        create_yn           = false
        security_group_name = "search-recommand-alb-sg"
        type                = "ingress"
        description         = "search-recommand alb https security group ingress rule"
        from_port           = 443
        to_port             = 443
        protocol            = "tcp"
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
        create_yn                = false
        security_group_name      = "search-recommand-alb-sg"
        type                     = "egress"
        description              = "search-recommand alb all traffic security group egress rule"
        from_port                = 0
        to_port                  = 0
        protocol                 = "-1"
        cidr_ipv4                = null
        source_security_group_id = aws_security_group.ecs_security_group["opensearch-api-sg"].id # INFO: ECS API의 보안그룹을 목적지로 지정
        env                      = "stg"
      },
      {
        create_yn                = false
        security_group_name      = "search-recommand-alb-sg"
        type                     = "egress"
        description              = "search-recommand alb all traffic security group egress rule"
        from_port                = 0
        to_port                  = 0
        protocol                 = "-1"
        cidr_ipv4                = null
        source_security_group_id = aws_security_group.ecs_security_group["elasticsearch-api-sg"].id # INFO: ECS API의 보안그룹을 목적지로 지정
        env                      = "stg"
      }
    ]
  }

  # ECS security group ingress rule
  ecs_security_group_ingress_rules = {
    opensearch-api-sg-ingress-rule = [
      {
        create_yn                = false
        security_group_name      = "opensearch-api-sg"
        type                     = "ingress"
        description              = "opensearch api security group ingress rule"
        from_port                = 10091
        to_port                  = 10091
        protocol                 = "tcp"
        cidr_ipv4                = null
        source_security_group_id = aws_security_group.alb_security_group["search-recommand-alb-sg"].id # INFO: ECS의 출발지는 ALB만 지정
        env                      = "stg"
      }
    ],
    elasticsearch-api-sg-ingress-rule = [
      {
        create_yn                = false
        type                     = "ingress"
        security_group_name      = "elasticsearch-api-sg"
        description              = "elasticsearch api security group ingress rule"
        from_port                = 10092
        to_port                  = 10092
        protocol                 = "tcp"
        cidr_ipv4                = null
        source_security_group_id = aws_security_group.alb_security_group["search-recommand-alb-sg"].id # INFO: ECS의 출발지는 ALB만 지정
        env                      = "stg"
      }
    ]
  }

  # ECS security group egress rule
  ecs_security_group_egress_rules = {
    opensearch-api-sg-ingress-rule = [
      {
        create_yn           = false
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
        create_yn           = false
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

  # EC2 security group ingress rule
  ec2_security_group_ingress_rules = {
    opensearch-sg-ingress-rule = [
      {
        create_yn           = false
        security_group_name = "opensearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "opensearch ssh security group inbound"
        from_port           = 22
        to_port             = 22
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.0.0/16",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        source_security_group_id = null
        env                      = "stg"
      },
      {
        create_yn           = false
        security_group_name = "opensearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "opensearch es security group inbound"
        from_port           = 9200
        to_port             = 9200
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.0.0/16",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        source_security_group_id = null
        env                      = "stg"
      },
      {
        create_yn           = false
        security_group_name = "opensearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "opensearch es security group inbound"
        from_port           = 5601
        to_port             = 5601
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.0.0/16",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        source_security_group_id = null
        env                      = "stg"
      }
    ],
    elasticsearch-sg-ingress-rule = [
      {
        create_yn           = false
        security_group_name = "elasticsearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "elasticsearch ssh security group inbound"
        from_port           = 22
        to_port             = 22
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.0.0/16",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        source_security_group_id = null
        env                      = "stg"
      },
      {
        create_yn           = false
        security_group_name = "elasticsearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "elasticsearch es security group inbound"
        from_port           = 9200
        to_port             = 9200
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.0.0/16",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        source_security_group_id = null
        env                      = "stg"
      }
    ],
    atlantis-sg-ingress-rule = [
      {
        create_yn           = true
        security_group_name = "atlantis-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "atlantis ssh security group inbound"
        from_port           = 22
        to_port             = 22
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.0.0/16",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        source_security_group_id = null
        env                      = "stg"
      },
      {
        create_yn           = true
        security_group_name = "atlantis-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "atlantis server security group inbound"
        from_port           = 4114
        to_port             = 4114
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.0.0/16",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        source_security_group_id = null
        env                      = "stg"
      }
    ]
  }

  # EC2 security group egress rule
  ec2_security_group_egress_rules = {
    opensearch-sg-egress-rule = [
      {
        create_yn           = false
        security_group_name = "opensearch-sg"
        description         = "opensearch security group egress rule"
        type                = "egress"
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
    elasticsearch-sg-egress-rule = [
      {
        create_yn           = false
        security_group_name = "elasticsearch-sg"
        description         = "elasticsearch security group egress rule"
        type                = "egress"
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
    atlantis-sg-egress-rule = [
      {
        create_yn           = true,
        security_group_name = "atlantis-sg"
        description         = "atlantis security group egress rule"
        type                = "egress"
        from_port           = 0
        to_port             = 0
        protocol            = "-1"
        cidr_ipv4 = [
          "0.0.0.0/0"
        ],
        source_security_group_id = null
        env                      = "stg"
      }
    ]
  }
}
