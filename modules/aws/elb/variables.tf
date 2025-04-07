########################################
# 프로젝트 기본 설정
########################################
# 프로젝트 이름
variable "project_name" {
  description = "프로젝트 이름 설정"
  type        = string
  default     = "terraform-ecs"
}

# AWS 가용영역
variable "availability_zones" {
  description = "가용 영역 설정"
  type        = list(string)
}

# AWS 개발 환경
variable "env" {
  description = "AWS 개발 환경 설정"
  type        = string
}

########################################
# 네트워크 설정
########################################
# VPC ID(이미 생성되어 있는 VPC ID를 data 통해 받아오거나, 아니면 생성된 VPC ID를 넣는다)
variable "vpc_id" {
  description = "VPC ID 설정"
  type        = string
}

# 퍼블릭 서브넷
variable "public_subnet_ids" {
  description = "퍼블릭 서브넷 대역 ID([subnet-xxxxxxxx, subnet-xxxxxxxx])"
  type        = list(string)
}

########################################
# 로드밸런서 설정
########################################
# Application Load Balancer
# ALB의 KEY 이름과, Target Group 변수의 KEY 이름을 일치시켜야 함
variable "alb" {
  description = "ALB 설정"
  type = map(object({
    name                             = string
    internal                         = bool
    load_balancer_type               = string
    enable_deletion_protection       = bool
    enable_cross_zone_load_balancing = bool
    idle_timeout                     = number
    security_group_name              = string
    env                              = string
  }))
}

# ALB 보안그룹 이름
variable "alb_security_group" {
  description = "ALB 보안그룹 이름"
  type = map(object({
    security_group_name = string
    description         = string
    env                 = string
  }))
}

# ALB Listencer
variable "alb_listener" {
  description = "ALB Listener 설정"
  type = map(object({
    name              = string
    port              = number
    protocol          = string
    load_balancer_arn = string
    default_action = object({
      type             = string           # ALB Listener Rule 지정 -> forward, redirect,fixed-response
      target_group_arn = optional(string) # target group forward 하는 경우 사용
      fixed_response = optional(object({  # 고정 값을 응답해야 하는 경우 사용
        content_type = optional(string)
        message_body = optional(string)
        status_code  = optional(string)
      }))
    })
    env = string
  }))
}

# ALB Listener Rule 생성
variable "alb_listener_rule" {
  description = "ALB listener rule"
  type = map(object({
    type              = string
    path              = list(string)
    alb_listener_name = string
    target_group_name = string
    priority          = number
  }))
}

# ALB Target Group 생성
# FIXME: 변수명 수정 필요 -> ALB야 아니면 NLB야? 정확히 명시
variable "target_group" {
  description = "Target group configuration"
  type = map(object({
    name        = string
    port        = number
    elb_type    = string
    protocol    = string
    target_type = string
    env         = string
    health_check = object({
      path                = string
      enabled             = bool
      healthy_threshold   = number
      interval            = number
      port                = number
      protocol            = string
      timeout             = number
      unhealthy_threshold = number
      internal            = bool
    })
  }))
}

# ECS 보안그룹 ID
variable "alb_security_group_id" {
  description = "ECS 보안그룹 ID"
  type        = map(string)
}

########################################
# 공통 태그 설정
########################################
variable "tags" {
  description = "공통 태그 설정"
  type        = map(string)
}
