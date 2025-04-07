# ECR repositories
resource "aws_ecr_repository" "ecr_repository" {
  for_each = var.ecr_repository

  name                 = "${each.value.ecr_repository_name}-${each.value.env}" # 리포지토리 이름
  image_tag_mutability = each.value.ecr_image_tag_mutability                   # TAG 변경 가능 여부 지정
  force_delete         = each.value.ecr_force_delete

  image_scanning_configuration {
    scan_on_push = each.value.ecr_scan_on_push # ECR 이미지 PUSH 스캔 여부
  }

  tags = merge(var.tags, {
    Name = "${each.value.ecr_repository_name}-${each.value.env}"
  })
}
