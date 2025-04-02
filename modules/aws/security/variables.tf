########################################
# IAM 설정
########################################
variable "iam_custom_role" {
  description = "IAM Role 생성"
  type = map(object({
    create_yn   = bool
    name        = optional(string)
    description = optional(string)
    version     = optional(string)
    statement = object({
      Sid    = optional(string)
      Action = string
      Effect = string
      Principal = object({
        Service = string
      })
    })
    env = string
  }))
}

# 사용자가 생성하는 정책
variable "iam_custom_policy" {
  description = "IAM 사용자 생성 정책"
  type = map(object({
    create_yn   = bool
    name        = optional(string)
    description = optional(string)
    version     = optional(string)
    statement = optional(object({
      Sid      = optional(string)
      Action   = optional(list(string))
      Effect   = optional(string)
      Resource = optional(list(string))
    }))
    env = string
  }))
}

# 관리형 정책
variable "iam_managed_policy" {
  description = "IAM 관리형 정책"
  type = map(object({
    create_yn = bool
    name      = string
    arn       = string
    env       = string
  }))
}

variable "iam_policy_attachment" {
  description = "IAM Policy를 Role에 연결"
  type = map(object({
    create_yn   = bool
    role_name   = optional(string)
    policy_name = optional(string)
    policy_type = optional(string)
  }))
}

########################################
# ECS 클러스터 설정
########################################
variable "ecs_task_role" {
  description = "ECS Task Role 설정"
  type        = string
}

variable "ecs_task_role_policy" {
  description = "ECS Task Policy 설정"
  type        = string
}

variable "ecs_task_exec_role" {
  description = "ECS Task Exec Role 설정"
  type        = string
}

variable "ecs_task_exec_role_policy" {
  description = "ECS Task Exec Policy 설정"
  type        = string
}

variable "ecs_auto_scaling_role" {
  description = "ECS Auto Scaling Role 설정"
  type        = string
}

variable "ecs_auto_scaling_policy_arn" {
  description = "ECS Auto Scaling Policy 설정"
  type        = string
}

####################
# 공통 태그 설정
####################
variable "tags" {
  description = "공통 태그 설정"
  type        = map(string)
}
