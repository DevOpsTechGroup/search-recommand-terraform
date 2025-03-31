# S3 bucket
resource "aws_s3_bucket" "s3" {
  for_each = {
    for key, value in var.s3_bucket : key => value if local.create_s3_bucket
  }

  #   region = var.aws_region
  bucket = each.value.bucket_name

  # 삭제 가능하도록 지정(실무에서는 true로 해야함)
  lifecycle {
    prevent_destroy = false
  }

  tags = merge(var.tags, {
    Name = "${each.value.bucket_name}-${local.env}"
  })
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "versioning" {
  for_each = {
    for key, value in var.s3_bucket : key => value
    if value.versioning && local.create_s3_bucket_versioning
  }

  bucket = aws_s3_bucket.s3[each.key].id
  versioning_configuration {
    status = "Enabled" # 버전 관리 설정 - true
  }
}

# S3 object encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "server_side_encrypt" {
  for_each = {
    for key, value in var.s3_bucket : key => value
    if value.server_side_encryption && local.create_s3_bucket_server_side_encryption
  }

  bucket = aws_s3_bucket.s3[each.key].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # 암호화 Rule(규칙) 지정
    }
  }
}

# S3 bucket access configuration
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  for_each = {
    for key, value in var.s3_bucket : key => value
    if value.public_access_block && local.create_aws_s3_bucket_public_access_block
  }

  bucket                  = aws_s3_bucket.s3[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB for terraform state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "tfstate-lock"    # DynamoDB Table 이름 지정
  hash_key     = "LockID"          # DynamoDB 테이블의 파티션 키(Partition Key, Hash Key) 이름
  billing_mode = "PAY_PER_REQUEST" # 비용 관련 설정(사용한 만큼만 과금)

  attribute {
    name = "LockID" # 해시 키(Primary Key)로 사용할 컬럼 지정
    type = "S"      # 데이터 타입을 'S'(String)로 지정
  }
}
