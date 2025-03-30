# EC2 amazon ami
data "aws_ami" "amazon_ami" {
  for_each = var.ec2_instance

  most_recent = true                # AMI 중에서 가장 최신 버전 조회
  owners      = [each.value.owners] # 소유자 지정('amazon', 'self')

  dynamic "filter" {
    for_each = each.value.filter

    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

# EC2 instance status(running, stopped)
resource "aws_ec2_instance_state" "ec2_state" {
  for_each = {
    for key, value in var.ec2_instance : key => value if local.create_ec2_instance_state
  }

  instance_id = aws_instance.ec2[each.key].id
  state       = each.value.state
}

# EC2 instance
resource "aws_instance" "ec2" {
  for_each = {
    for key, value in var.ec2_instance : key => value if local.create_ec2_instance
  }

  ami           = data.aws_ami.amazon_ami[each.key].id # AMI 지정(offer: 기존 AWS 제공, custom: 생성한 AMI)
  instance_type = each.value.instance_type             # EC2 인스턴스 타입 지정

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
    aws_security_group.ec2_security_group[each.value.security_group_name].id
  ]
  #iam_instance_profile = xxxx # EC2에 IAM 권한이 필요한 경우 활성화

  # lookup(map, key, default)
  user_data = (
    lookup(each.value, "script_file_name", null) != null &&
    lookup(each.value, "script_file_name", "") != ""
  ) ? file("${path.module}/script/${each.value.script_file_name}") : null

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${each.value.instance_name}-${each.value.env}"
  })
}

# EC2 key pair Decide encryption method + generate a TLS/SSL private key
resource "tls_private_key" "ec2_key_pair_rsa" {
  for_each = {
    for key, value in var.ec2_instance : key => value if local.create_tls_private_key
  }

  algorithm = each.value.key_pair_algorithm # RSA 알고리즘 설정
  rsa_bits  = each.value.rsa_bits           # RSA 키 길이를 4096 bit로 설정 (4096 => 보안성 높은 설정 값, default => 2048)
}

# EC2 key pair
resource "aws_key_pair" "ec2_key_pair" {
  for_each = {
    for key, value in var.ec2_instance : key => value if local.create_key_pair
  }

  key_name   = each.value.key_pair_name
  public_key = tls_private_key.ec2_key_pair_rsa[each.key].public_key_openssh # Terraform이 생성한 RSA키의 공개 키를 가져와 EC2 SSH 키 페어로 등록
}

# EC2 key pair to save local file
resource "local_file" "ec2_key_pair_local_file" {
  for_each = {
    for key, value in var.ec2_instance : key => value if local.create_local_file
  }

  content         = tls_private_key.ec2_key_pair_rsa[each.key].private_key_pem
  filename        = "${path.module}/${each.value.local_file_name}"
  file_permission = each.value.local_file_permission
}

# EC2 security group
resource "aws_security_group" "ec2_security_group" {
  for_each = {
    for key, value in var.ec2_security_group : key => value if local.create_ec2_security_group
  }

  name        = each.value.security_group_name # 보안그룹명
  description = each.value.description         # 보안그룹 내용
  vpc_id      = var.vpc_id                     # module에서 넘겨 받아야함

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${each.value.security_group_name}-${var.env}"
  })
}

# EC2 security group ingress rule
resource "aws_security_group_rule" "ec2_ingress_security_group" {
  for_each = {
    for rule in local.valid_ec2_security_group_ingress_rules :
    "${rule.security_group_name}-${rule.type}-${rule.from_port}-${rule.to_port}" => rule
    if local.create_ec2_security_group_ingress_rule
  }

  description       = each.value.description                                                   # 보안그룹 DESC
  security_group_id = aws_security_group.ec2_security_group[each.value.security_group_name].id # 참조하는 보안그룹 ID
  type              = each.value.type                                                          # 타입 지정(ingress, egress)
  from_port         = each.value.from_port                                                     # 포트 시작 허용 범위
  to_port           = each.value.to_port                                                       # 포트 종료 허용 범위
  protocol          = each.value.protocol                                                      # 보안그룹 프로토콜 지정

  cidr_blocks              = try(each.value.cidr_ipv4, null)                # 허용할 IP 범위
  source_security_group_id = try(each.value.source_security_group_id, null) # 인바운드로 보안그룹이 들어가야 하는 경우 사용
}

# EC2 security group egress rule
resource "aws_security_group_rule" "ec2_egress_security_group" {
  for_each = {
    for rule in local.valid_ec2_security_group_egress_rules :
    "${rule.security_group_name}-${rule.type}-${rule.from_port}-${rule.to_port}" => rule
    if local.create_ec2_security_group_egress_rule
  }

  description       = each.value.description
  security_group_id = aws_security_group.ec2_security_group[each.value.security_group_name].id # 참조하는 보안그룹 ID
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol

  cidr_blocks              = try(each.value.cidr_ipv4, null)                # 허용할 IP 범위
  source_security_group_id = try(each.value.source_security_group_id, null) # 아웃바운드로 보안그룹이 들어가야 하는 경우 사용
}