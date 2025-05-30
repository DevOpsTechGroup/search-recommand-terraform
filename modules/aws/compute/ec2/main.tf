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

# EC2 key pair
data "aws_key_pair" "key_pair" {
  for_each = var.ec2_key_pair

  key_name = each.value.name

  tags = merge(var.tags, {
    Name = "${each.value.name}-${each.value.env}"
  })
}

# EC2 instance
resource "aws_instance" "ec2" {
  for_each = {
    for key, value in var.ec2_instance : key => value if value.create_yn
  }

  ami                  = data.aws_ami.amazon_ami[each.key].id # AMI 지정(offer: 기존 AWS 제공, custom: 생성한 AMI)
  instance_type        = each.value.instance_type             # EC2 인스턴스 타입 지정
  private_ip           = try(each.value.private_ip, null)     # EC2 private ip 지정
  iam_instance_profile = try(var.iam_instance_profile[each.value.iam_instance_profile].name, null)

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

  key_name = data.aws_key_pair.key_pair[each.value.key_pair_name].key_name # SSH key pair 지정

  vpc_security_group_ids = [ # 인스턴스에 지정될 보안그룹 ID 지정
    var.ec2_security_group_id[each.value.security_group_name]
  ]
  #iam_instance_profile = xxxx # EC2에 IAM 권한이 필요한 경우 활성화

  # lookup(map, key, default)
  user_data = (
    lookup(each.value, "script_file_name", null) != null &&
    lookup(each.value, "script_file_name", "") != ""
  ) ? file("${path.module}/script/${each.value.script_file_name}") : null

  dynamic "root_block_device" {
    for_each = each.value.root_block_device != null ? [each.value.root_block_device] : []
    content {
      volume_type           = root_block_device.value.volume_type
      volume_size           = root_block_device.value.volume_size
      delete_on_termination = root_block_device.value.delete_on_termination
      encrypted             = root_block_device.value.encrypted
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = all # Terraform EC2 생성 후 전부 무시
  }

  tags = merge(var.tags, {
    Name = "${each.value.instance_name}-${each.value.env}"
  })
}
