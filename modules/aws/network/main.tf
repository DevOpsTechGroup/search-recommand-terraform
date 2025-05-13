# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr             # IPv4 CIDR Block(172.22.0.0/16)
  enable_dns_hostnames = var.enable_dns_hostnames # DNS hostname을 만들건지 안 만들건지 지정하는 옵션
  enable_dns_support   = var.enable_dns_support   # DNS 사용 옵션, 기본 false(VPC 내 리소스가 AWS DNS 주소 사용 가능)

  tags = merge(var.tags, {
    Name = "${local.project_name}-vpc-${local.env}"
  })
}

# Public subnets
resource "aws_subnet" "public_subnet" {
  count = local.az_count

  vpc_id            = aws_vpc.main.id                      # 위에서 만든 VPC ID 별칭 참조
  cidr_block        = var.public_subnets_cidr[count.index] # IPv4 Public Subnet CIDR Block
  availability_zone = var.availability_zones[count.index]  # 가용영역 지정

  map_public_ip_on_launch = true # 서브넷 내의 인스턴스의 퍼블릭 IP를 자동 할당 여부 지정

  tags = merge(var.tags, {
    Name = "${format("%s-sub-pub-%s-%02d", local.project_name, local.env, count.index + 1)}"
  })
}

# Private subnets
resource "aws_subnet" "private_subnet" {
  count = local.az_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets_cidr[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    # %: 포맷팅의 시작
    # %s: 문자열 데이터를 삽입하겠다는 의미
    # %02d: 최소 2자리 보장
    Name = "${format("%s-sub-pri-%s-%02d", local.project_name, local.env, count.index + 1)}"
  })
}

# Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "${local.project_name}-igw-${local.env}"
  })
}

# Public routing table
resource "aws_route_table" "public_route_table" {
  # TODO: Route Table은 현재 1개만 생성, 추후 N개의 Route Table이 필요한 경우 수정 필요 
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                 # VPC Public Subnet 내의 모든 요청(0.0.0.0/0)을 IGW로 라우팅
    gateway_id = aws_internet_gateway.igw.id # Internet Gateway 참조 설정
  }

  tags = merge(var.tags, {
    Name = "${local.project_name}-rt-pub-${local.env}"
  })
}

# Public routing table association
resource "aws_route_table_association" "public_route_table_association" {
  count = local.az_count

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id

  depends_on = [
    aws_route_table.public_route_table
  ]
}

# Private routing table
resource "aws_route_table" "private_route_table" {
  # TODO: Route Table은 현재 1개만 생성, 추후 N개의 Route Table이 필요한 경우 수정 필요 
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${local.project_name}-rt-pri-${local.env}"
  })
}

# Private routing table association
resource "aws_route_table_association" "private_route_table_association" {
  count = local.az_count

  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id

  depends_on = [
    aws_route_table.private_route_table
  ]
}