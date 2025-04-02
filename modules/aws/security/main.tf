# FIXME: IAM Role도 FOR - LOOP로 처리하는게 맞을지 모르겠음..
# IAM은 아무래도 수정이 계속 발생할 것 같기도 하고..

data "aws_iam_policy" "managed_policy" {
  for_each = {
    for key, value in var.iam_managed_policy : key => value if value.create_yn
  }
  arn = each.value.arn
}

# IAM Role
resource "aws_iam_role" "custom_role" {
  for_each = {
    for key, value in var.iam_custom_role : key => value if value.create_yn
  }

  name = each.value.name
  assume_role_policy = jsonencode({
    Version   = each.value.version
    Statement = each.value.statement
  })

  tags = merge(var.tags, {
    Name = "${each.value.name}-${each.value.env}"
  })
}

# IAM Policy
resource "aws_iam_policy" "custom_policy" {
  for_each = {
    for key, value in var.iam_custom_policy : key => value if value.create_yn
  }

  name = each.value.name
  policy = jsonencode({
    Version   = each.value.version
    Statement = [each.value.statement]
  })

  tags = merge(var.tags, {
    Name = "${each.value.name}-${each.value.env}"
  })
}

# Attachment iam role to policy
resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  for_each = {
    for key, value in var.iam_policy_attachment : key => value if value.create_yn
  }

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