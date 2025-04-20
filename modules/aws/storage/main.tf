# S3 bucket
resource "aws_s3_bucket" "s3" {
  for_each = var.s3_bucket

  #   region = var.aws_region
  bucket = "${each.value.bucket_name}-${each.value.env}"

  tags = merge(var.tags, {
    Name = "${each.value.bucket_name}-${local.env}"
  })
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "versioning" {
  for_each = var.s3_bucket

  bucket = aws_s3_bucket.s3[each.key].id

  versioning_configuration {
    status = each.value.bucket_versioning.versioning_configuration.status
  }
}

# S3 object encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "server_side_encrypt" {
  for_each = var.s3_bucket

  bucket = aws_s3_bucket.s3[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = each.value.server_side_encryption.rule.apply_server_side_encryption_by_default.sse_algorithm
    }
  }
}

# S3 bucket access configuration
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  for_each = var.s3_bucket

  bucket                  = aws_s3_bucket.s3[each.key].id
  block_public_acls       = each.value.public_access_block.block_public_acls
  block_public_policy     = each.value.public_access_block.block_public_policy
  ignore_public_acls      = each.value.public_access_block.ignore_public_acls
  restrict_public_buckets = each.value.public_access_block.restrict_public_buckets
}
