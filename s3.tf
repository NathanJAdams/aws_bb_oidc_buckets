resource "aws_s3_bucket" "bucket" {
  for_each = local.bucket_names

  bucket        = each.key
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  for_each = aws_s3_bucket.bucket

  bucket = each.value.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  for_each = aws_s3_bucket.bucket

  bucket = each.value.id
  versioning_configuration {
    status = var.bucket_versioning
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  for_each = aws_s3_bucket.bucket

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "secure_transport" {
  for_each = aws_s3_bucket.bucket

  bucket = each.value.id
  policy = data.aws_iam_policy_document.secure_transport[each.value.id].json
}
