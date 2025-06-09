locals {

  # ALB security group ingress rule
  alb_security_group_ingress_rules = {
    search-alb-sg-ingress-rule = [
      {
        security_group_name = "search-opensearch-alb-sg"
        type                = "ingress"
        description         = "search-recommand alb http security group ingress rule"
        from_port           = 80
        to_port             = 80
        protocol            = "tcp"
        cidr_ipv4 = [
          "220.75.180.0/24",
          "183.111.245.0/24"
        ]
        security_groups = null
        env             = "stg"
      },
      {
        security_group_name = "search-opensearch-alb-sg"
        type                = "ingress"
        description         = "search-recommand alb https security group ingress rule"
        from_port           = 443
        to_port             = 443
        protocol            = "tcp"
        cidr_ipv4 = [
          "220.75.180.0/24",
          "183.111.245.0/24"
        ]
        security_groups = null
        env             = "stg"
      }
    ]
  }

  # Flatten alb security group ingress rule
  alb_ingress_rules_flat = flatten([
    for group in values(local.alb_security_group_ingress_rules) : [
      for rule in group : [
        for cidr in rule.cidr_ipv4 != null ? rule.cidr_ipv4 : [] : {
          security_group_name = rule.security_group_name
          type                = rule.type
          description         = rule.description
          from_port           = rule.from_port
          to_port             = rule.to_port
          protocol            = rule.protocol
          cidr_ipv4           = cidr
          security_groups     = rule.security_groups
          env                 = rule.env
        }
      ]
    ]
  ])

  # ALB security group egress rule
  alb_security_group_egress_rules = {
    search-opensearch-alb-sg-egress-rule = [
      {
        security_group_name = "search-opensearch-alb-sg"
        type                = "egress"
        description         = "search-recommand alb all traffic security group egress rule"
        from_port           = 0
        to_port             = 0
        protocol            = "-1"
        cidr_ipv4 = [
          "172.21.50.0/24",
          "172.21.60.0/24",
          "172.21.70.0/24"
        ]
        security_groups = null
        env             = "stg"
      }
    ]
  }

  # Flatten alb security group ingress rule
  alb_egress_rules_flat = flatten([
    for group in values(local.alb_security_group_egress_rules) : [
      for rule in group :
      rule.cidr_ipv4 != null ? [
        for cidr in rule.cidr_ipv4 : {
          security_group_name = rule.security_group_name
          type                = rule.type
          description         = rule.description
          from_port           = rule.from_port
          to_port             = rule.to_port
          protocol            = rule.protocol
          cidr_ipv4           = cidr
          security_groups     = null
          env                 = rule.env
        }
        ] : [
        {
          security_group_name = rule.security_group_name
          type                = rule.type
          description         = rule.description
          from_port           = rule.from_port
          to_port             = rule.to_port
          protocol            = rule.protocol
          cidr_ipv4           = null
          security_groups     = rule.security_groups
          env                 = rule.env
        }
      ]
    ]
  ])

  # ECS security group ingress rule
  ecs_security_group_ingress_rules = {
    search-opensearch-api-sg-ingress-rule = [
      {
        security_group_name = "search-opensearch-api-sg"
        type                = "ingress"
        description         = "opensearch api service port"
        from_port           = 8443
        to_port             = 8443
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.50.0/24",
          "172.21.60.0/24",
          "172.21.70.0/24",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        security_groups = null
        env             = "stg"
      },
      {
        security_group_name = "search-opensearch-api-sg"
        type                = "ingress"
        description         = "opensearch api vpc endpoint port"
        from_port           = 443
        to_port             = 443
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.50.0/24",
          "172.21.60.0/24",
          "172.21.70.0/24"
        ]
        security_groups = null
        env             = "stg"
      }
    ],
    search-embed-api-sg-ingress-rule = [
      {
        type                = "ingress"
        security_group_name = "search-embed-api-sg"
        description         = "embed api service port"
        from_port           = 8000
        to_port             = 8000
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.50.0/24",
          "172.21.60.0/24",
          "172.21.70.0/24",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        security_groups = null
        env             = "stg"
      },
      {
        security_group_name = "search-embed-api-sg"
        type                = "ingress"
        description         = "embed api vpc endpoint port"
        from_port           = 443
        to_port             = 443
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.50.0/24",
          "172.21.60.0/24",
          "172.21.70.0/24"
        ]
        security_groups = null
        env             = "stg"
      }
    ]
  }

  # Flatten ecs security group ingress rule
  ecs_ingress_rules_flat = flatten([
    for group in values(local.ecs_security_group_ingress_rules) : [
      for rule in group : rule.cidr_ipv4 != null ? [
        for cidr in rule.cidr_ipv4 : {
          security_group_name = rule.security_group_name
          type                = rule.type
          description         = rule.description
          from_port           = rule.from_port
          to_port             = rule.to_port
          protocol            = rule.protocol
          cidr_ipv4           = cidr
          security_groups     = null
          env                 = rule.env
        }
        ] : [
        {
          security_group_name = rule.security_group_name
          type                = rule.type
          description         = rule.description
          from_port           = rule.from_port
          to_port             = rule.to_port
          protocol            = rule.protocol
          cidr_ipv4           = null
          security_groups     = rule.security_groups
          env                 = rule.env
        }
      ]
    ]
  ])

  # ECS security group egress rule
  ecs_security_group_egress_rules = {
    search-opensearch-api-sg-egress-rule = [
      {
        security_group_name = "search-opensearch-api-sg"
        type                = "egress"
        description         = "opensearch api vpc endpoint port"
        from_port           = 9200
        to_port             = 9200
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.50.0/24",
          "172.21.60.0/24",
          "172.21.70.0/24"
        ]
        security_groups = null
        env             = "stg"
      },
      {
        security_group_name = "search-opensearch-api-sg"
        type                = "egress"
        description         = "opensearch api vpc endpoint port"
        from_port           = 443
        to_port             = 443
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.50.0/24",
          "172.21.60.0/24",
          "172.21.70.0/24"
        ]
        security_groups = null
        env             = "stg"
      }
    ],
    search-embed-api-sg-egress-rule = [
      {
        security_group_name = "search-embed-api-sg"
        type                = "egress"
        description         = "embed api vpc endpoint port"
        from_port           = 0
        to_port             = 0
        protocol            = "-1"
        cidr_ipv4 = [
          "0.0.0.0/0"
        ]
        security_groups = null
        env             = "stg"
      }
    ]
  }

  # Flatten ecs security group egress rule
  ecs_egress_rules_flat = flatten([
    for group in values(local.ecs_security_group_egress_rules) : [
      for rule in group : [
        for cidr in rule.cidr_ipv4 != null ? rule.cidr_ipv4 : [] : {
          security_group_name = rule.security_group_name
          type                = rule.type
          description         = rule.description
          from_port           = rule.from_port
          to_port             = rule.to_port
          protocol            = rule.protocol
          cidr_ipv4           = cidr
          security_groups     = rule.security_groups
          env                 = rule.env
        }
      ]
    ]
  ])

  # EC2 security group ingress rule
  ec2_security_group_ingress_rules = {
    search-jenkins-sg-ingress-rule = [
      {
        security_group_name = "search-jenkins-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "jenkins security group inbound"
        from_port           = 8080
        to_port             = 8080
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.0.0/16",
          "220.75.180.0/24",
          "39.118.148.0/24",
          "192.30.252.0/22",
          "185.199.108.0/22",
          "140.82.112.0/20",
          "143.55.64.0/20",
          "211.234.181.0/24"
        ]
        security_groups = null
        env             = "stg"
      },
      {
        security_group_name = "search-jenkins-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "jenkins security group inbound"
        from_port           = 22
        to_port             = 22
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.0.0/16",
          "220.75.180.0/24",
          "39.118.148.0/24",
          "211.234.197.0/24",
          "211.234.181.0/24"
        ]
        security_groups = null
        env             = "stg"
      }
    ],
    search-opensearch-sg-ingress-rule = [
      {
        security_group_name = "search-opensearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "opensearch ssh security group inbound"
        from_port           = 22
        to_port             = 22
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.50.0/24",
          "172.21.60.0/24",
          "172.21.70.0/24",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        security_groups = null
        env             = "stg"
      },
      {
        security_group_name = "search-opensearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "opensearch es security group inbound"
        from_port           = 9100
        to_port             = 9100
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.50.0/24",
          "172.21.60.0/24",
          "172.21.70.0/24",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        security_groups = null
        env             = "stg"
      },
      {
        security_group_name = "search-opensearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "opensearch es security group inbound"
        from_port           = 9200
        to_port             = 9200
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.50.0/24",
          "172.21.60.0/24",
          "172.21.70.0/24",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        security_groups = null
        env             = "stg"
      },
      {
        security_group_name = "search-opensearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "opensearch es security group inbound"
        from_port           = 9300
        to_port             = 9300
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.50.0/24",
          "172.21.60.0/24",
          "172.21.70.0/24",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        security_groups = null
        env             = "stg"
      },
      {
        security_group_name = "search-opensearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "opensearch es security group inbound"
        from_port           = 9400
        to_port             = 9400
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.50.0/24",
          "172.21.60.0/24",
          "172.21.70.0/24",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        security_groups = null
        env             = "stg"
      },
      {
        security_group_name = "search-opensearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "opensearch es security group inbound"
        from_port           = 5601
        to_port             = 5601
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.50.0/24",
          "172.21.60.0/24",
          "172.21.70.0/24",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        security_groups = null
        env             = "stg"
      }
    ],
    search-embed-sg-ingress-rule = [
      {
        security_group_name = "search-embed-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "embed es security group inbound"
        from_port           = 8000
        to_port             = 8000
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.50.0/24",
          "172.21.60.0/24",
          "172.21.70.0/24",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        security_groups = null
        env             = "stg"
      },
      {
        security_group_name = "search-embed-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "embed es security group inbound"
        from_port           = 22
        to_port             = 22
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.50.0/24",
          "172.21.60.0/24",
          "172.21.70.0/24",
          "220.75.180.0/24",
          "39.118.148.0/24"
        ]
        security_groups = null
        env             = "stg"
      }
    ],
    # search-atlantis-sg-ingress-rule = [
    #   {
    #     security_group_name = "search-atlantis-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
    #     type                = "ingress"
    #     description         = "atlantis ssh security group inbound"
    #     from_port           = 22
    #     to_port             = 22
    #     protocol            = "tcp"
    #     cidr_ipv4 = [
    #       "172.21.0.0/16",
    #       "220.75.180.0/24",
    #       "39.118.148.0/24",
    #       "192.30.252.0/22",
    #       "185.199.108.0/22"
    #     ]
    #     security_groups = null
    #     env                      = "stg"
    #   },
    #   {
    #     security_group_name = "search-atlantis-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
    #     type                = "ingress"
    #     description         = "atlantis server security group inbound"
    #     from_port           = 4141
    #     to_port             = 4141
    #     protocol            = "tcp"
    #     cidr_ipv4 = [ # INFO: https://ybchoi.com/28
    #       "172.21.0.0/16",
    #       "220.75.180.0/24",
    #       "39.118.148.0/24",
    #       "192.30.252.0/22",
    #       "185.199.108.0/22",
    #       "140.82.112.0/20",
    #       "143.55.64.0/20"
    #     ]
    #     security_groups = null
    #     env                      = "stg"
    #   }
    # ]
  }

  # Flatten ec2 security group ingress rule
  ec2_ingress_rules_flat = flatten([
    for group in values(local.ec2_security_group_ingress_rules) : [
      for rule in group : [
        for cidr in rule.cidr_ipv4 != null ? rule.cidr_ipv4 : [] : {
          security_group_name = rule.security_group_name
          type                = rule.type
          description         = rule.description
          from_port           = rule.from_port
          to_port             = rule.to_port
          protocol            = rule.protocol
          cidr_ipv4           = cidr
          security_groups     = rule.security_groups
          env                 = rule.env
        }
      ]
    ]
  ])

  # EC2 security group egress rule
  ec2_security_group_egress_rules = {
    search-jenkins-sg-egress-rule = [
      {
        security_group_name = "search-jenkins-sg"
        description         = "jenkins security group egress rule"
        type                = "egress"
        from_port           = 0
        to_port             = 0
        protocol            = "-1" # 모든 프로토콜 허용
        cidr_ipv4 = [
          "0.0.0.0/0"
        ]
        security_groups = null
        env             = "stg"
      }
    ],
    search-opensearch-sg-egress-rule = [
      {
        security_group_name = "search-opensearch-sg"
        description         = "opensearch security group egress rule"
        type                = "egress"
        from_port           = 0
        to_port             = 0
        protocol            = "-1" # 모든 프로토콜 허용
        cidr_ipv4 = [
          "0.0.0.0/0"
        ]
        security_groups = null
        env             = "stg"
      }
    ],
    search-embed-sg-egress-rule = [
      {
        security_group_name = "search-embed-sg"
        description         = "embed security group egress rule"
        type                = "egress"
        from_port           = 0
        to_port             = 0
        protocol            = "-1" # 모든 프로토콜 허용
        cidr_ipv4 = [
          "0.0.0.0/0"
        ]
        security_groups = null
        env             = "stg"
      }
    ],
    # search-atlantis-sg-egress-rule = [
    #   {
    #     security_group_name = "search-atlantis-sg"
    #     description         = "atlantis security group egress rule"
    #     type                = "egress"
    #     from_port           = 0
    #     to_port             = 0
    #     protocol            = "-1"
    #     cidr_ipv4 = [
    #       "0.0.0.0/0"
    #     ],
    #     security_groups = null
    #     env                      = "stg"
    #   }
    # ]
  }

  # Flatten ec2 security group egress rule
  ec2_egress_rules_flat = flatten([
    for group in values(local.ec2_security_group_egress_rules) : [
      for rule in group : [
        for cidr in rule.cidr_ipv4 != null ? rule.cidr_ipv4 : [] : {
          security_group_name = rule.security_group_name
          description         = rule.description
          type                = rule.type
          from_port           = rule.from_port
          to_port             = rule.to_port
          protocol            = rule.protocol
          cidr_ipv4           = cidr
          security_groups     = rule.security_groups
          env                 = rule.env
        }
      ]
    ]
  ])
}
