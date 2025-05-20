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
    domain_name               = string # ACM 인증서를 발급할 도메인명
    validation_method         = string # ACM 인증서 발급 방법(DNS, EMAIL) 소유권 검증
    subject_alternative_names = string # 추가로 인증서에 포함시킬 도메인 목록
    env                       = string # 환경 변수
  }))
}

########################################
# 공통 태그 설정
########################################
variable "tags" {
  description = "공통 태그 설정"
  type        = map(string)
}
