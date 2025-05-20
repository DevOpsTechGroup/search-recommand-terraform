########################################
# IAM 설정
########################################
# 사용자가 생성하는 역할
variable "iam_custom_role" {
  description = "IAM Role 생성"
  type = map(object({
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
    name = string
    arn  = string
    env  = string
  }))
}

# 사용자가 생성한 역할에 정책 연결
variable "iam_policy_attachment" {
  description = "IAM Policy를 Role에 연결"
  type = map(object({
    role_name   = optional(string)
    policy_name = optional(string)
  }))
}

# EC2에 붙힐 IAM instance profile
variable "iam_instance_profile" {
  description = "IAM instance profile"
  type = map(object({
    name      = string
    role_name = string
  }))
}

####################
# 공통 태그 설정
####################
variable "tags" {
  description = "공통 태그 설정"
  type        = map(string)
}
