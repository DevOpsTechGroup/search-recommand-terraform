# S3 bucket
resource "aws_s3_bucket" "s3" {
  for_each = {
    for key, value in var.s3_bucket : key => value if value.create_yn
  }

  #   region = var.aws_region
  bucket = "${each.value.bucket_name}-${each.value.env}"

  tags = merge(var.tags, {
    Name = "${each.value.bucket_name}-${local.env}"
  })
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "versioning" {
  for_each = {
    for key, value in var.s3_bucket : key => value if value.create_yn
  }

  bucket = aws_s3_bucket.s3[each.key].id

  versioning_configuration {
    status = each.value.bucket_versioning.versioning_configuration.status
  }
}

# S3 object encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "server_side_encrypt" {
  for_each = {
    for key, value in var.s3_bucket : key => value if value.create_yn
  }

  bucket = aws_s3_bucket.s3[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = each.value.server_side_encryption.rule.apply_server_side_encryption_by_default.sse_algorithm
    }
  }
}

# S3 bucket access configuration
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  for_each = {
    for key, value in var.s3_bucket : key => value if value.create_yn
  }

  bucket                  = aws_s3_bucket.s3[each.key].id
  block_public_acls       = each.value.public_access_block.block_public_acls
  block_public_policy     = each.value.public_access_block.block_public_policy
  ignore_public_acls      = each.value.public_access_block.ignore_public_acls
  restrict_public_buckets = each.value.public_access_block.restrict_public_buckets
}

# DynamoDB for terraform state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  for_each = {
    for key, value in var.dynamodb_table : key => value if value.create_yn
  }

  name         = "${each.value.name}-${each.value.env}" # DynamoDB Table 이름 지정
  hash_key     = each.value.hash_key                    # DynamoDB 테이블의 파티션 키(Partition Key, Hash Key) 이름
  billing_mode = each.value.billing_mode                # 비용 관련 설정(사용한 만큼만 과금)

  attribute {
    name = each.value.attribute.name # 해시 키(Primary Key)로 사용할 컬럼 지정
    type = each.value.attribute.type # 데이터 타입을 'S'(String)로 지정
  }

  tags = merge(var.tags, {
    Name = "${each.value.name}-${each.value.env}"
  })
}
