resource "aws_cloudfront_distribution" "resume_cf_distribution" {
  origin {
    domain_name              = aws_s3_bucket.resume-bucket.bucket_regional_domain_name 
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = aws_s3_bucket.resume-bucket.id
  }

  enabled             = true
  is_ipv6_enabled     = false
  comment             = "Terraform Cloud Front Distribution"
  default_root_object = "index.html"

  aliases = ["www.${var.DOMAIN_NAME}", "${var.DOMAIN_NAME}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.resume-bucket.id

    forwarded_values {
      query_string = false
      headers = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https" 
    min_ttl                = 3600
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "Production"
  }

  viewer_certificate {
    acm_certificate_arn = var.ACM_ARN
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1"
  }
}


resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "default-resume"
  description                       = "Resume Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_access_identity" "resume_cf" {
  comment = "resume_cf"
}


data "aws_route53_zone" "myzone" {
  name = var.DOMAIN_NAME
}

resource "aws_route53_record" "www-a-apex" {
  zone_id = "${data.aws_route53_zone.myzone.zone_id}"
  name    = "${var.DOMAIN_NAME}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.resume_cf_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.resume_cf_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www-aaaa-apex" {
  zone_id = "${data.aws_route53_zone.myzone.zone_id}"
  name    = "${var.DOMAIN_NAME}"
  type    = "AAAA"

  alias {
    name                   = "${aws_cloudfront_distribution.resume_cf_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.resume_cf_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www-a" {
  zone_id = "${data.aws_route53_zone.myzone.zone_id}"
  name    = "www.${var.DOMAIN_NAME}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.resume_cf_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.resume_cf_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www-aaaa" {
  zone_id = "${data.aws_route53_zone.myzone.zone_id}"
  name    = "www.${var.DOMAIN_NAME}"
  type    = "AAAA"

  alias {
    name                   = "${aws_cloudfront_distribution.resume_cf_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.resume_cf_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}