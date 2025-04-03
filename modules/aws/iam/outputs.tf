# modules/aws/security/outputs.tf

output "iam_resources" {
  description = "Dynamically generated map of IAM roles and policies"
  value = merge(
    {
      for key, role in merge(
        try(aws_iam_role.custom_role, {}),
      ) : "${key}-id" => role.id
    },
    {
      for key, role in merge(
        try(aws_iam_role.custom_role, {}),
      ) : "${key}-name" => role.name
    },
    {
      for key, role in merge(
        try(aws_iam_role.custom_role, {}),
      ) : "${key}-arn" => role.arn
    },
    {
      for key, policy in merge(
        try(aws_iam_policy.custom_policy, {}),
        try(data.aws_iam_policy.managed_policy, {})
      ) : "${key}-id" => policy.id
    },
    {
      for key, policy in merge(
        try(aws_iam_policy.custom_policy, {}),
        try(data.aws_iam_policy.managed_policy, {})
      ) : "${key}-name" => policy.name
    },
    {
      for key, policy in merge(
        try(aws_iam_policy.custom_policy, {}),
        try(data.aws_iam_policy.managed_policy, {})
      ) : "${key}-arn" => policy.arn
    }
  )
}