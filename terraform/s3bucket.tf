resource "aws_s3_bucket" "resume-bucket" {
    bucket = "resume-bucket-${local.account_id}"
    force_destroy = true
    tags = {
        Name = "resume-bucket"
        Environment = "Prod"
    }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.resume-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "allow_access_from_cloud_front" {
  bucket = aws_s3_bucket.resume-bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_cloud_front.json
}