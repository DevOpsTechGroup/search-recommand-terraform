/*
  TODO: EC2도 여러개 생성할 수 있기에 for - loop 사용하는 방향으로 변경 필요
*/
# EC2 AMI Amazon Linux 2
data "aws_ami" "amazon-linux-2" {
  most_recent = true # AMI 중에서 가장 최신 버전을 가져온다

  filter { # AMI를 제공하는 소유자 필터링
    name   = "owner-alias"
    values = ["amazon"] # AWS 공식 AMI만 가져온다
  }

  filter { # AMI 이름이 amzn2-ami-hvm* 시작하는것만 필터링
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# Create EC2 Terraform Atlantis ssh private key(RSA)
# 암호화 방식 결정 + TLS(SSL) 개인키 생성
# https://dev.classmethod.jp/articles/terraform-keypair-create/
resource "tls_private_key" "ec2_key_pair_rsa" {
  for_each = {
    for key, value in var.ec2_instance : key => value if value.create
  }

  algorithm = each.value.key_pair_algorithm # RSA 알고리즘 설정
  rsa_bits  = each.value.rsa_bits           # RSA 키 길이를 4096 bit로 설정 (4096 => 보안성 높은 설정 값, default => 2048)
}

# EC2 key pair 생성 - Atlantis
resource "aws_key_pair" "ec2_key_pair" {
  for_each = {
    for key, value in var.ec2_instance : key => value if value.create
  }

  key_name   = each.value.key_pair_name
  public_key = tls_private_key.ec2_key_pair_rsa[each.key].public_key_openssh # Terraform이 생성한 RSA키의 공개 키를 가져와 EC2 SSH 키 페어로 등록
}

# Local에 생성한 EC2 key pair 저장
resource "local_file" "ec2_key_pair_local_file" {
  for_each = {
    for key, value in var.ec2_instance : key => value if value.create
  }

  content         = tls_private_key.ec2_key_pair_rsa[each.key].private_key_pem # 어떤 파일을 대상으로 할지 지정
  filename        = "${path.module}/${each.value.local_file_name}"             # key pair 이름+경로 지정
  file_permission = each.value.local_file_permission                           # 0600 설정
}

# EC2 security group
resource "aws_security_group" "ec2_security_group" {
  for_each = {
    for key, value in var.ec2_security_group : key => value if value.create
  }

  name        = each.value.ec2_security_group_name
  description = each.value.ec2_security_group_description
  vpc_id      = var.vpc_id # module에서 넘겨 받아야함

  lifecycle {
    create_before_destroy = true # 리소스 삭제 되기 전 생성 후 삭제 진행
  }

  tags = merge(var.tags, {
    Name = "${each.value.ec2_security_group_name}-${var.env}"
  })
}

# EC2 security group rule ingress
resource "aws_security_group_rule" "ec2_ingress_security_group" {
  for_each = {
    for rule in local.valid_ec2_security_group_ingress_rules :
    "${rule.ec2_security_group_name}-${rule.type}-${rule.from_port}-${rule.to_port}" => rule if rule.create
  }

  description       = each.value.description                                                       # 보안그룹 DESC
  security_group_id = aws_security_group.ec2_security_group[each.value.ec2_security_group_name].id # 참조하는 보안그룹 ID
  type              = each.value.type                                                              # 타입 지정(ingress, egress)
  from_port         = each.value.from_port                                                         # 포트 시작 허용 범위
  to_port           = each.value.to_port                                                           # 포트 종료 허용 범위
  protocol          = each.value.protocol                                                          # 보안그룹 프로토콜 지정

  cidr_blocks              = try(each.value.cidr_ipv4, null)                # 허용할 IP 범위
  source_security_group_id = try(each.value.source_security_group_id, null) # 인바운드로 보안그룹이 들어가야 하는 경우 사용
}

# EC2 security group rule egress
resource "aws_security_group_rule" "ec2_egress_security_group" {
  for_each = {
    for rule in local.valid_ec2_security_group_egress_rules :
    "${rule.ec2_security_group_name}-${rule.type}-${rule.from_port}-${rule.to_port}" => rule if rule.create
  }

  description       = each.value.description
  security_group_id = aws_security_group.ec2_security_group[each.value.ec2_security_group_name].id # 참조하는 보안그룹 ID
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol

  cidr_blocks              = try(each.value.cidr_ipv4, null)                # 허용할 IP 범위
  source_security_group_id = try(each.value.source_security_group_id, null) # 아웃바운드로 보안그룹이 들어가야 하는 경우 사용
}

# EC2 Instance 생성
resource "aws_instance" "ec2" {
  for_each = {
    for key, value in var.ec2_instance : key => value if value.create
  }

  ami           = data.aws_ami.amazon-linux-2.id # Amazon Linux2 AMI ID 지정
  instance_type = each.value.instance_type       # EC2 인스턴스 타입 지정

  # EC2가 위치할 VPC Subnet 영역 지정(az-2a, az-2b)
  subnet_id = lookup(
    {
      "public"  = try(element(var.public_subnet_ids, index(var.availability_zones, each.value.availability_zones)), var.public_subnet_ids[0]),
      "private" = try(element(var.private_subnet_ids, index(var.availability_zones, each.value.availability_zones)), var.private_subnet_ids[0])
    },
    each.value.subnet_type,
    var.public_subnet_ids[0]
  )

  associate_public_ip_address = each.value.associate_public_ip_address # 퍼블릭 IP 할당 여부 지정(true면 공인 IP 부여 -> 고정 IP 아님)
  disable_api_termination     = each.value.disable_api_termination     # TRUE인 경우 콘솔/API로 삭제 불가

  key_name = aws_key_pair.ec2_key_pair[each.key].key_name # SSH key pair 지정

  vpc_security_group_ids = [ # 인스턴스에 지정될 보안그룹 ID 지정
    aws_security_group.ec2_security_group[each.value.ec2_security_group_name].id
  ]
  #iam_instance_profile = xxxx # EC2에 IAM 권한이 필요한 경우 활성화

  # lookup(map, key, default)
  user_data = lookup(each.value, "script_file_name", null) != null ? file("${path.module}/script/${each.value.script_file_name}") : null

  tags = merge(var.tags, {
    Name = "${each.value.ec2_instance_name}-${each.value.env}"
  })
}
