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
# ACM 설정
########################################
variable "acm_certificate" {
  description = "ACM 인증서 설정"
  type = map(object({
    mode                      = string
    domain_name               = string # ACM 인증서를 발급할 도메인명
    subject_alternative_names = string # 추가로 인증서에 포함시킬 도메인 목록
    dns_validate              = bool
    certificate_body          = optional(string)
    private_key               = optional(string)
    certificate_chain         = optional(string)
    env                       = string # 환경 변수
  }))
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

########################################
# 공통 태그 설정
########################################
variable "tags" {
  description = "공통 태그 설정"
  type        = map(string)
}
