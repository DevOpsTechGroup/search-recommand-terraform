# VPC Endpoint Gateway Type
resource "aws_vpc_endpoint" "vpc_endpoint_gateway" {
  for_each = var.vpc_endpoint_gateway

  vpc_id            = var.vpc_id # TODO: 모듈에서 받아야함
  service_name      = each.value.service_name
  vpc_endpoint_type = each.value.vpc_endpoint_type
  route_table_ids   = var.private_route_table_ids # TODO: 모듈에서 받아야함

  tags = merge(var.tags, {
    Name = "${each.value.endpoint_name}-${local.env}"
  })
}

# VPC Endpoint Interface Type
resource "aws_vpc_endpoint" "vpc_endpoint_interface" {
  for_each = var.vpc_endpoint_interface

  vpc_id            = var.vpc_id # TODO: 모듈에서 받아야함
  service_name      = each.value.service_name
  vpc_endpoint_type = each.value.vpc_endpoint_type

  # VPC 안에서 AWS 도메인 입력시 인터넷을 안타고 VPC Endpoint로 연결해주는 설정
  # 만약, false로 설정하게 되면 인터넷을 통해서만 접속 가능
  private_dns_enabled = each.value.private_dns_enabled
  security_group_ids = [
    for sg_name in each.value.security_group_name :
    lookup(var.security_group_ids, sg_name)
  ]
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${each.value.endpoint_name}-${local.env}"
  })
}
