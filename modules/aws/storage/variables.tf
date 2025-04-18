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
    bucket_name = string
    bucket_versioning = object({
      versioning_configuration = object({
        status = string
      })
    })
    server_side_encryption = object({
      rule = object({
        apply_server_side_encryption_by_default = object({
          sse_algorithm = string
        })
      })
    })
    public_access_block = object({
      block_public_acls       = bool
      block_public_policy     = bool
      ignore_public_acls      = bool
      restrict_public_buckets = bool
    })
    env = string
  }))
}

########################################
# 공통 태그 설정
########################################
variable "tags" {
  description = "공통 태그 설정"
  type        = map(string)
}
