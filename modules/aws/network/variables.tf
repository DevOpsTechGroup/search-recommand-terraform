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

########################################
# 네트워크 설정
########################################
# VPC CIDR
variable "vpc_cidr" {
  description = "VPC CIDR 설정"
  type        = string
  default     = "172.22.0.0/16" # 2^16 => 65,536 / 가용영역(4개) => 16,384
}

# DNS Hostname 사용 옵션, 기본 false(VPC 내 리소스가 AWS DNS 주소 사용 가능)
variable "enable_dns_support" {
  description = "AWS DNS 사용 가능 여부 지정"
  type        = bool
}

# DNS hostname을 만들건지 안 만들건지 지정하는 옵션
# 결국 enable_dns_support, enable_dns_hostnames 옵션 2개다 켜야 DNS 통신 가능할 듯
variable "enable_dns_hostnames" {
  description = "DNS hostname 사용 가능 여부 지정"
  type        = bool
}

# 퍼블릭 서브넷
variable "public_subnets_cidr" {
  description = "퍼블릭 서브넷 설정"
  type        = list(string)
}

# 프라이빗 서브넷
variable "private_subnets_cidr" {
  description = "프라이빗 서브넷 설정"
  type        = list(string)
}

# AWS 가용영역
variable "availability_zones" {
  description = "가용 영역 설정"
  type        = list(string)
}

########################################
# 공통 태그 설정
########################################
variable "tags" {
  description = "공통 태그 설정"
  type        = map(string)
}
