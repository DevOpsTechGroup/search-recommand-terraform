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
# Route 53 설정
########################################
variable "route53_zone_settings" {
  description = "Route53 Zone 설정"
  type = map(object({
    mode = string
    name = string
  }))
}

variable "route53_record_settings" {
  description = "Route53 Record 설정"
  type = map(object({
    ttl             = number
    allow_overwrite = bool
  }))
}

variable "domain_validation_options" {
  description = "Route53 레코드 속성"
  type = map(list(object({
    domain_name           = string
    resource_record_name  = string
    resource_record_type  = string
    resource_record_value = string
  })))
  default = {}
}

########################################
# 공통 태그 설정
########################################
variable "tags" {
  description = "공통 태그 설정"
  type        = map(string)
}
