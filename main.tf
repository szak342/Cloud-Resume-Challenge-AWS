terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

data "aws_caller_identity" "current" {}
    output "account_id" {
    value = data.aws_caller_identity.current.account_id
    }

locals {
    account_id = data.aws_caller_identity.current.account_id
}

provider "aws" {
  region = "eu-west-1"
}


resource "aws_s3_bucket" "resume-bucket" {
    bucket = "resume-bucket-${local.account_id}"
    tags = {
        Name = "resume-bucket"
        Environment = "Dev"
    }
}

#resource "aws_s3_bucket_acl" "resume_bucket_acl" {
# bucket = aws_s3_bucket.resume-bucket.id
#  acl    = "private"
#}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.resume-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "default-resume"
  description                       = "Resume Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "allow_access_from_cloud_front" {
  bucket = aws_s3_bucket.resume-bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_cloud_front.json
}

resource "aws_cloudfront_origin_access_identity" "resume_cf" {
  comment = "resume_cf"
}

resource "aws_cloudfront_distribution" "resume_cf_distribution" {
  origin {
    domain_name              = aws_s3_bucket.resume-bucket.bucket_regional_domain_name # ??
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    #origin_access_identity = aws_cloudfront_origin_access_identity.resume_cf.cloudfront_access_identity_path # ??
    origin_id                = aws_s3_bucket.resume-bucket.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  #aliases = ["mysite.example.com", "yoursite.example.com"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.resume-bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all" # Dev settings
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE", "PL"]
    }
  }

  tags = {
    Environment = "Dev"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


data "aws_iam_policy_document" "allow_access_from_cloud_front" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    } 

    effect = "Allow"
    
    actions = ["s3:GetObject"]
    
    resources = [
      "${aws_s3_bucket.resume-bucket.arn}/*",
    ]

    condition {
      test = "StringEquals"
      variable = "AWS:SourceArn"
      values = [aws_cloudfront_distribution.resume_cf_distribution.arn]
    }
  }
}