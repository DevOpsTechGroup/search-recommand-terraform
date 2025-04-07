# modules/aws/security/outputs.tf

# TODO: 변수 개별적으로 분리 필요...
output "iam_role_ids" {
  description = "Map of IAM role IDs"
  value = {
    for key, role in try(aws_iam_role.custom_role, {}) :
    key => role.id
  }
}

output "iam_role_names" {
  description = "Map of IAM role names"
  value = {
    for key, role in try(aws_iam_role.custom_role, {}) :
    key => role.name
  }
}

output "iam_role_arns" {
  description = "Map of IAM role ARNs"
  value = {
    for key, role in try(aws_iam_role.custom_role, {}) :
    key => role.arn
  }
}

output "iam_policy_ids" {
  description = "Map of IAM policy IDs"
  value = {
    for key, policy in merge(
      try(aws_iam_policy.custom_policy, {}),
      try(data.aws_iam_policy.managed_policy, {})
    ) :
    key => policy.id
  }
}

output "iam_policy_names" {
  description = "Map of IAM policy names"
  value = {
    for key, policy in merge(
      try(aws_iam_policy.custom_policy, {}),
      try(data.aws_iam_policy.managed_policy, {})
    ) :
    key => policy.name
  }
}

output "iam_policy_arns" {
  description = "Map of IAM policy ARNs"
  value = {
    for key, policy in merge(
      try(aws_iam_policy.custom_policy, {}),
      try(data.aws_iam_policy.managed_policy, {})
    ) :
    key => policy.arn
  }
}

output "iam_instance_profile" {
  description = "Map of IAM instance profiles"
  value = {
    for key, profile in try(aws_iam_instance_profile.ec2_iam_instance_profile, {}) :
    profile.name => profile
  }
}