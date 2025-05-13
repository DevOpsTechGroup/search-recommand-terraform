########################################
# 프로젝트 기본 설정
########################################
# 프로젝트 이름
variable "project_name" {
  description = "프로젝트 이름 설정"
  type        = string
  default     = "terraform-ecs"
}

# AWS 개발 환경
variable "env" {
  description = "AWS 개발 환경 설정"
  type        = string
}

# AWS 리전
variable "aws_region" {
  description = "AWS 리전 설정"
  type        = string
  default     = "ap-northeast-2"
  validation {
    condition     = contains(["ap-northeast-2"], var.aws_region)
    error_message = "지원되지 않는 AWS 리전입니다."
  }
}

########################################
# 네트워크 설정
########################################
# VPC ID(이미 생성되어 있는 VPC ID를 data 통해 받아오거나, 아니면 생성된 VPC ID를 넣는다)
variable "vpc_id" {
  description = "VPC ID 설정"
  type        = string
}

# TODO: route_table_ids, security_group_ids, subnet_id 변수 추가
# 그 다음에, vpc_endpoint 모듈 안의 리로스 수정

# VPC Endpoint Gateway 설정
variable "vpc_endpoint_gateway" {
  description = "VPC Endpoint Gateway 설정"
  type = map(object({
    endpoint_name     = string
    service_name      = string
    vpc_endpoint_type = string
  }))
}

# VPC Endpoint Interface 설정
variable "vpc_endpoint_interface" {
  description = "VPC Endpoint Interface 설정"
  type = map(object({
    endpoint_name       = string
    security_group_name = list(string)
    service_name        = string
    vpc_endpoint_type   = string
    private_dns_enabled = bool
  }))
}

# Private Route Table IDS
variable "private_route_table_ids" {
  description = "Private Route Table IDS"
  type        = list(string)
}

# Security Group IDs
variable "security_group_ids" {
  description = "Security Group IDs"
  type        = map(string)
}

# Subnet IDs
variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

########################################
# 공통 태그 설정
########################################
variable "tags" {
  description = "공통 태그 설정"
  type        = map(string)
}
