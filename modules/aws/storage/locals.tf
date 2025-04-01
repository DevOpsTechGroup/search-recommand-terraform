locals {
  project_name = var.project_name
  env          = var.env

  # 리소스 생성여부 지정
  create_s3_bucket                         = false
  create_s3_bucket_versioning              = false
  create_s3_bucket_server_side_encryption  = false
  create_aws_s3_bucket_public_access_block = false
  create_aws_dynamodb_table                = false
}
