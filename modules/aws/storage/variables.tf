########################################
# 프로젝트 기본 설정
########################################
# 프로젝트 이름
variable "project_name" {
  description = "프로젝트 이름 설정"
  type        = string
  default     = "terraform-ecs"
}

# AWS 리전
variable "aws_region" {
  description = "AWS 리전 설정"
  type        = string
  default     = "ap-northeast-2"
  validation {
    condition     = contains(["ap-northeast-2"], var.aws_region)
    error_message = "지원되지 않는 AWS 리전입니다."
  }
}

# AWS 개발 환경
variable "env" {
  description = "AWS 개발 환경 설정"
  type        = string
}

########################################
# S3 설정
########################################
variable "s3_bucket" {
  description = "생성하고자 하는 S3 버킷 정보 기재"
  type = map(object({
    create_yn              = bool
    bucket_name            = string
    versioning             = bool
    server_side_encryption = bool
    public_access_block    = bool
  }))
}

########################################
# 공통 태그 설정
########################################
variable "tags" {
  description = "공통 태그 설정"
  type        = map(string)
}
