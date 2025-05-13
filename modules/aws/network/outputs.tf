# modules/aws/network/outputs.tf
output "vpc_id" {
  description = "생성된 VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR 블록"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 목록"
  value       = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
  description = "프라이빗 서브넷 ID 목록"
  value       = aws_subnet.private_subnet[*].id
}

output "public_route_table_id" {
  description = "퍼블릭 라우트 테이블 ID"
  value       = aws_route_table.public_route_table[*].id
}

output "private_route_table_id" {
  description = "프라이빗 라우트 테이블 ID"
  value       = aws_route_table.private_route_table[*].id
}
