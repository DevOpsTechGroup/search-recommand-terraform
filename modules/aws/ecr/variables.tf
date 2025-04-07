########################################
# ECR 설정
########################################
# ECR 리포지토리 생성
variable "ecr_repository" {
  description = "ECR repository"
  type = map(object({
    ecr_repository_name      = string
    ecr_image_tag_mutability = string
    ecr_scan_on_push         = bool
    ecr_force_delete         = bool
    env                      = string
  }))
}

########################################
# 공통 태그 설정
########################################
variable "tags" {
  description = "공통 태그 설정"
  type        = map(string)
}
