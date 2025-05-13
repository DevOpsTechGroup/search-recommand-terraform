# VPC Endpoint Gateway Type
resource "aws_vpc_endpoint" "vpc_endpoint_gateway" {
  for_each = var.vpc_endpoint_gateway

  vpc_id            = aws_vpc.main.id # TODO: 모듈에서 받아야함
  service_name      = each.value.service_name
  vpc_endpoint_type = each.value.vpc_endpoint_type
  route_table_ids   = [aws_route_table.private_route_table.id] # TODO: 모듈에서 받아야함

  tags = merge(var.tags, {
    Name = "${local.project_name}-${each.value.name}-${local.env}"
  })
}

# VPC Endpoint Interface Type
resource "aws_vpc_endpoint" "vpc_endpoint_interface" {
  for_each = var.vpc_endpoint_interface

  vpc_id            = aws_vpc.main.id # TODO: 모듈에서 받아야함
  service_name      = each.value.service_name
  vpc_endpoint_type = each.value.vpc_endpoint_type

  # VPC 안에서 AWS 도메인 입력시 인터넷을 안타고 VPC Endpoint로 연결해주는 설정
  # 만약, false로 설정하게 되면 인터넷을 통해서만 접속 가능
  private_dns_enabled = each.value.private_dns_enabled
  security_group_ids  = [each.value.security_group_ids] # TODO: 모듈에서 받아야함
  subnet_ids          = aws_subnet.private_subnet[*].id # TODO: 모듈에서 받아야함

  tags = merge(var.tags, {
    Name = "${local.project_name}-${each.value.name}-${local.env}"
  })
}
