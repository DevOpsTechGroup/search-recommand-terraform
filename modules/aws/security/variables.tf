########################################
# 네트워크 설정
########################################
# VPC ID(이미 생성되어 있는 VPC ID를 data 통해 받아오거나, 아니면 생성된 VPC ID를 넣는다)
variable "vpc_id" {
  description = "VPC ID 설정"
  type        = string
}

########################################
# 로드밸런서 설정
########################################
# ALB 보안그룹 이름
variable "alb_security_group" {
  description = "ALB 보안그룹 이름"
  type = map(object({
    security_group_name = string
    description         = string
    env                 = string
  }))
}

########################################
# ECS 설정
########################################
# ECS Service 보안그룹
variable "ecs_security_group" {
  description = "ECS 보안그룹 설정"
  type = map(object({
    security_group_name = string
    description         = string
    env                 = string
  }))
}

########################################
# EC2 설정
########################################
# EC2 보안그룹 설정
variable "ec2_security_group" {
  description = "EC2 보안그룹 생성"
  type = map(object({
    security_group_name = optional(string)
    description         = optional(string)
    env                 = optional(string)
  }))
}

########################################
# 공통 태그 설정
########################################
variable "tags" {
  description = "공통 태그 설정"
  type        = map(string)
}
