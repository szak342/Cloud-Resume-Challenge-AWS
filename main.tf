terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.24.0"        # Fixed terraform version
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

resource "aws_s3_object" "webpage" {
  for_each = fileset("./webpage/", "*")
  bucket = aws_s3_bucket.resume-bucket.id
  key = each.value
  source = "./webpage/${each.value}"
  content_type = "text/html"
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
  is_ipv6_enabled     = false
  comment             = "Terraform Cloud Front Distribution"
  default_root_object = "index.html"

  #aliases = ["mysite.example.com", "yoursite.example.com"]

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

    viewer_protocol_policy = "redirect-to-https" # Dev settings
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
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

resource "aws_lambda_function" "resume-lambda" {
  function_name = "resume-lambda"

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = "main-bucket-28357"
  s3_key    = "lambda/ResumeReadFunction.zip"

  handler = "app.lambda_handler"
  runtime = "python3.11"

  role = "${aws_iam_role.lambda_exec.arn}"
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_example_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.resume-lambda.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.resume-api.execution_arn}/*/*"
}


resource "aws_api_gateway_rest_api" "resume-api" {
  name        = "resume-api"
  description = "Terraform resume-api"
}

resource "aws_api_gateway_resource" "api-resource" {
  rest_api_id = "${aws_api_gateway_rest_api.resume-api.id}"
  parent_id   = "${aws_api_gateway_rest_api.resume-api.root_resource_id}"
  path_part   = "dev"
}

resource "aws_api_gateway_method" "api-method" {
  rest_api_id   = "${aws_api_gateway_rest_api.resume-api.id}"
  resource_id   = "${aws_api_gateway_resource.api-resource.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options_200" {
    rest_api_id   = "${aws_api_gateway_rest_api.resume-api.id}"
    resource_id   = "${aws_api_gateway_resource.api-resource.id}"
    http_method   = "${aws_api_gateway_method.api-method.http_method}"
    status_code   = "200"
    response_parameters = {
        "method.response.header.Access-Control-Allow-Origin" = true
    }
    depends_on = [aws_api_gateway_method.api-method]
}

resource "aws_api_gateway_integration" "lambda" {
    rest_api_id   = "${aws_api_gateway_rest_api.resume-api.id}"
    resource_id   = "${aws_api_gateway_resource.api-resource.id}"
    http_method   = "${aws_api_gateway_method.api-method.http_method}"
    type          = "AWS"
    integration_http_method = "POST"
    uri = "${aws_lambda_function.resume-lambda.invoke_arn}"
    depends_on = [aws_api_gateway_method.api-method]
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.resume-api.id}"
  resource_id = "${aws_api_gateway_method.api-method.resource_id}"
  http_method = "${aws_api_gateway_method.api-method.http_method}"

  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "${aws_lambda_function.resume-lambda.invoke_arn}"
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
    rest_api_id   = "${aws_api_gateway_rest_api.resume-api.id}"
    resource_id   = "${aws_api_gateway_resource.api-resource.id}"
    http_method   = "${aws_api_gateway_method.api-method.http_method}"
    status_code   = "${aws_api_gateway_method_response.options_200.status_code}"
    response_parameters = {
        "method.response.header.Access-Control-Allow-Origin" = "'https://${aws_cloudfront_distribution.resume_cf_distribution.domain_name}'"
    }
    depends_on = [aws_api_gateway_method_response.options_200]
}

resource "aws_api_gateway_deployment" "deployment" {
    rest_api_id   = "${aws_api_gateway_rest_api.resume-api.id}"
    stage_name    = "Dev"
    depends_on    = [aws_api_gateway_integration.lambda]
}


output "cloudfront_address" {
  value = aws_cloudfront_distribution.resume_cf_distribution.domain_name
}

output "api_address" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}