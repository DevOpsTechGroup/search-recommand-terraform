########################################
# 프로젝트 기본 설정
########################################
variable "env" {
  description = "Environment (e.g., dev, staging, prod)"
  type        = string
  default     = "stg"
}

# AWS 가용영역
variable "availability_zones" {
  description = "가용 영역 설정"
  type        = list(string)
}

########################################
# 네트워크 설정
########################################
variable "vpc_id" {
  description = "VPC ID where the security groups will be created"
  type        = string
}

# 퍼블릭 서브넷 ID
variable "public_subnet_ids" {
  description = "퍼블릭 서브넷 대역 ID([subnet-xxxxxxxx, subnet-xxxxxxxx])"
  type        = list(string)
}

# 프라이빗 서브넷 ID
variable "private_subnet_ids" {
  description = "프라이빗 서브넷 대역 ID([subnet-xxxxxxxx, subnet-xxxxxxxx])"
  type        = list(string)
}

########################################
# EC2 설정
########################################
# EC2 생성
variable "ec2_instance" {
  description = "EC2 생성 정보 입력"
  type = map(object({
    create_yn = bool

    # SSH key pair
    key_pair_name         = string
    key_pair_algorithm    = string
    rsa_bits              = number
    local_file_name       = string
    local_file_permission = string

    # ECS Option
    ami_type                    = string # 기존 AMI or 신규 생성 EC2 여부 지정
    instance_type               = string
    subnet_type                 = string
    availability_zones          = string
    associate_public_ip_address = bool
    disable_api_termination     = bool
    instance_name               = string
    security_group_name         = string
    env                         = string
    script_file_name            = optional(string)

    # AMI filter
    owners = string
    filter = list(object({
      name   = optional(string)
      values = optional(list(string))
    }))
  }))
}

# EC2 보안그룹 ID
variable "ec2_security_group_id" {
  description = "EC2 보안그룹 ID"
  type        = map(string)
}

########################################
# 공통 태그 설정
########################################
variable "tags" {
  description = "공통 태그 설정"
  type        = map(string)
}
