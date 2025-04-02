locals {

  # EC2 security group ingress rule
  ec2_security_group_ingress_rules = {
    opensearch-sg-ingress-rule = [
      {
        create_yn           = true
        security_group_name = "opensearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "opensearch ssh security group inbound"
        from_port           = 22
        to_port             = 22
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.0.0/16",
          "220.75.180.0/24"
        ]
        source_security_group_id = null
        env                      = "stg"
      },
      {
        create_yn           = true
        security_group_name = "opensearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "opensearch es security group inbound"
        from_port           = 9200
        to_port             = 9200
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.0.0/16",
          "220.75.180.0/24"
        ]
        source_security_group_id = null
        env                      = "stg"
      }
    ],
    elasticsearch-sg-ingress-rule = [
      {
        create_yn           = true
        security_group_name = "elasticsearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "elasticsearch ssh security group inbound"
        from_port           = 22
        to_port             = 22
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.0.0/16",
          "220.75.180.0/24"
        ]
        source_security_group_id = null
        env                      = "stg"
      },
      {
        create_yn           = true
        security_group_name = "elasticsearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
        type                = "ingress"
        description         = "elasticsearch es security group inbound"
        from_port           = 9200
        to_port             = 9200
        protocol            = "tcp"
        cidr_ipv4 = [
          "172.21.0.0/16",
          "220.75.180.0/24"
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
        create_yn           = true
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
        create_yn           = true
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
    ]
  }
}
