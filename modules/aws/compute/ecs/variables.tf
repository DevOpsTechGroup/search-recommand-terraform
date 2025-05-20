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
variable "aws_region" {
  description = "AWS 가용영역 설정"
  type        = string
  default     = "ap-northeast-2"
  validation {
    condition     = contains(["ap-northeast-2"], var.aws_region)
    error_message = "지원되지 않는 AWS 리전입니다."
  }
}

# AWS 가용영역
variable "availability_zones" {
  description = "가용 영역 설정"
  type        = list(string)
}

# AWS 계정 ID
variable "aws_account" {
  description = "AWS 계정 ID 설정"
  type        = string
}

# AWS 개발 환경
variable "env" {
  description = "AWS 개발 환경 설정"
  type        = string
  default     = "stg"
}

########################################
# 네트워크 설정
########################################
variable "vpc_id" {
  description = "VPC ID 설정"
  type        = string
}

# VPC CIDR
variable "vpc_cidr" {
  description = "VPC CIDR 설정"
  type        = string
  default     = "172.22.0.0/16" # 2^16 => 65,536 / 가용영역(4개) => 16,384
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
# Modules - ECS               
########################################
# ECS Clusters
variable "ecs_cluster" {
  description = "ECS Cluster 설정"
  type = map(object({
    cluster_name = string
    env          = string
  }))
}

# ECS Service 보안그룹
variable "ecs_security_group" {
  description = "ECS 보안그룹 설정"
  type = map(object({
    security_group_name = string
    description         = string
    env                 = string
  }))
}

# ECS Task role arn
variable "ecs_task_role_arn" {
  description = "security module에서 생성된 role arn을 참조"
  type        = string
}

# ECS Task exec role arn
variable "ecs_task_exec_role_arn" {
  description = "security module에서 생성된 role arn을 참조"
  type        = string
}

# AWS ECS Task
variable "ecs_task_definitions" {
  description = "ECS Task Definition 설정"
  type = map(object({
    name                                    = string
    task_role                               = string
    task_exec_role                          = string
    network_mode                            = string
    launch_type                             = string
    task_total_cpu                          = string
    task_total_memory                       = string
    runtime_platform_oprating_system_family = string
    runtime_platform_cpu_architecture       = string
    task_family                             = string
    env                                     = string
    volume = object({
      name = string
    })
    ephemeral_storage = number
    containers = list(object({
      name          = string
      image         = string
      version       = string
      cpu           = number
      memory        = number
      port          = number
      protocol      = string
      essential     = bool
      env_variables = map(string)
      mount_points = list(object({
        sourceVolume  = string
        containerPath = string
        readOnly      = bool
      }))
      health_check = object({
        command  = string
        interval = number
        timeout  = number
        retries  = number
      })
      env = string
    }))
  }))
}

# ECS Service
variable "ecs_service" {
  description = "ECS 서비스 설정"
  type = map(object({
    subnets                       = string
    launch_type                   = string # ECS Launch Type ( EC2 or Fargate )
    service_role                  = string # ECS Service Role
    deployment_controller         = string
    cluster_name                  = string
    service_name                  = string # ECS 서비스 도메인명
    desired_count                 = number # ECS 서비스 Task 개수
    container_name                = string # ECS Container Name
    container_port                = number # ALB Listen Container Port
    task_definitions              = string
    env                           = string
    health_check_grace_period_sec = number # 헬스 체크 그레이스 기간
    assign_public_ip              = bool   # 퍼블릭 IP 지정 여부
    target_group_arn              = string
    security_group_name           = string
    deployment_circuit_breaker    = bool
  }))
}

# ECS Auto Scaling 시 사용하는 변수
variable "ecs_appautoscaling_target" {
  description = "ECS Auto Scaling Target 설정"
  type = map(object({
    min_capacity       = number # 최소 Task 2개가 항상 실행되도록 설정
    max_capacity       = number # 최대 Task 6개까지 증가 할 수 있도록 설정
    resource_id        = string # AG를 적용할 대상 리소스 지정, 여기서는 ECS 서비스 ARN 형식의 일부 기재
    scalable_dimension = string # 조정할 수 있는 AWS 리소스의 특정 속성을 지정하는 필드
    service_namespace  = string
    cluster_name       = string # AG가 어떤 ecs cluster에 매핑되는지 ecs cluster의 이름 지정
    service_name       = string # AG가 어떤 ecs service에 매핑되는지 ecs service의 이름 지정
  }))
}

# ECS Auto Scaling policy
variable "ecs_appautoscaling_target_policy" {
  description = "ECS Auto Scaling Target Policy 설정"
  type = map(object({
    scale_out = object({
      name        = string
      policy_type = string
      step_scaling_policy_conf = object({
        adjustment_type         = string
        cooldown                = number
        metric_aggregation_type = string
        step_adjustment = map(object({
          metric_interval_lower_bound = number
          metric_interval_upper_bound = optional(number)
          scaling_adjustment          = number
        }))
      })
    })
  }))
}

# ECS CPU Scale Out Alert
variable "ecs_cpu_scale_out_alert" {
  description = "ECS CPU Scale Out Alert Policy"
  type = map(object({
    alarm_name          = string
    comparison_operator = string
    evaluation_periods  = string
    metric_name         = string
    namespace           = string
    period              = string
    statistic           = string
    threshold           = string
    dimensions = object({
      cluster_name = string
      service_name = string
    })
    env = string
  }))
}

# ECS 보안그룹 ID
variable "ecs_security_group_id" {
  description = "ECS 보안그룹 ID"
  type        = map(string)
}

# ECS 보안그룹 ARN
variable "ecs_security_group_arn" {
  description = "ECS 보안그룹 ARN"
  type        = map(string)
}

########################################
# 로드밸런서 설정
########################################
# ECS Service에서 사용하는 ALB TG ARN으로, loadbalancer module에서 리소스 생성 후 외부 변수로 받는다
variable "alb_tg_arn" {
  description = "AWS ECS ALB TG ARN"
  type        = map(string)
}

# ECS Service에서 사용하는 ALB ARN으로, loadbalancer module에서 리소스 생성 후 외부 변수로 받는다
variable "alb_listener_arn" {
  description = "AWS ECS ALB LISTENER ARN"
  type        = map(string)
}

########################################
# 공통 태그 설정
########################################
variable "tags" {
  description = "공통 태그 설정"
  type        = map(string)
}
