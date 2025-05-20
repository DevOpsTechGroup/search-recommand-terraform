data "aws_iam_policy" "managed_policy" {
  for_each = var.iam_managed_policy
  arn      = each.value.arn
}

# IAM 역할(Role)
resource "aws_iam_role" "custom_role" {
  for_each = var.iam_custom_role

  name = each.value.name
  assume_role_policy = jsonencode({
    Version   = each.value.version
    Statement = each.value.statement
  })

  tags = merge(var.tags, {
    Name = "${each.value.name}-${each.value.env}"
  })
}

# IAM 정책(Policy)
resource "aws_iam_policy" "custom_policy" {
  for_each = var.iam_custom_policy

  name = each.value.name
  policy = jsonencode({
    Version   = each.value.version
    Statement = [each.value.statement]
  })

  tags = merge(var.tags, {
    Name = "${each.value.name}-${each.value.env}"
  })
}

# IAM 역할(Role)에 정책(Policy)을 연결
resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  for_each = var.iam_policy_attachment

  # coalesce(collection function) : null 또는 빈 문자열이 아닌 첫 번째 인수를 반환
  role = aws_iam_role.custom_role[each.value.role_name].name

  # custom인 경우 신규 생성한 policy를 attachment 하고
  # managed policy인 경우 data source의 arn을 attachment 한다
  policy_arn = try(
    aws_iam_policy.custom_policy[each.value.policy_name].arn,
    data.aws_iam_policy.managed_policy[each.value.policy_name].arn
  )

  depends_on = [
    aws_iam_policy.custom_policy,
    data.aws_iam_policy.managed_policy
  ]
}

# EC2 인스턴스 프로파일
resource "aws_iam_instance_profile" "ec2_iam_instance_profile" {
  for_each = var.iam_instance_profile

  name = each.value.name
  role = aws_iam_role.custom_role[each.value.role_name].name
}
