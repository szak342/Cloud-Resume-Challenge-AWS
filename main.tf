terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.24.0"        # Fixed terraform version
    }
  }
  required_version = ">= 1.2.0"
}

resource "null_resource" "build-lambda" { # Building Lambda package from script

 provisioner "local-exec" {

    command = "/bin/bash script.sh"
  }
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

resource "local_file" "jscode" {
    content = templatefile("templates/script.tpl",{invoke_url = aws_api_gateway_deployment.deployment.invoke_url})
    filename = "webpage/script.js"
    depends_on = [ aws_api_gateway_deployment.deployment ]
    
}


resource "aws_s3_object" "webpage" {
  for_each = fileset("./webpage/", "*")
  bucket = aws_s3_bucket.resume-bucket.id
  key = each.value
  source = "./webpage/${each.value}"
  content_type = "text/html"
  depends_on = [ 
                local_file.jscode,
                aws_api_gateway_deployment.deployment 
                ]
}

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

    viewer_protocol_policy = "redirect-to-https" # Dev settings, no cache
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
  #s3_bucket = "main-bucket-28357"
  #s3_key    = "lambda/ResumeReadFunction.zip"

  filename = "resumelambda.zip"
  handler = "app.lambda_handler"
  runtime = "python3.11"

  source_code_hash = data.archive_file.lambda.output_base64sha256
  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      DDB_TABLE = "${aws_dynamodb_table.resume-dynamodb.name}"
    }
} 
    depends_on = [ 
      data.archive_file.lambda
      ]
}

resource "aws_lambda_alias" "alias_dev" {
  name             = "dev"
  description      = "dev"
  function_name    = aws_lambda_function.resume-lambda.arn
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "alias_prod" {
  name             = "prod"
  description      = "prod"
  function_name    = aws_lambda_function.resume-lambda.arn
  function_version = "$LATEST"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir = "sam-app/.aws-sam/build/resumelambda"
  output_path = "resumelambda.zip"
  depends_on = [
    null_resource.build-lambda
  ]
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_example_lambda"

  assume_role_policy = jsonencode(
{
  Version: "2012-10-17",
  Statement: [
    {
      Action: "sts:AssumeRole",
      Principal: {
        Service: "lambda.amazonaws.com" # Sus
      },
      Effect: "Allow",
      Sid: ""
    }
  ]
}
)
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.resume-lambda.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.resume-api.execution_arn}/*/*" # Sus
}


resource "aws_api_gateway_rest_api" "resume-api" {
  name        = "resume-api"
  description = "Terraform resume-api"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
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
    stage_name    = "prod"
    depends_on    = [
      aws_api_gateway_integration.lambda,
      aws_api_gateway_integration_response.options_integration_response
      ]

        lifecycle {
    create_before_destroy = true
  }

      variables = {
    "stage" = "prod"
  }
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.resume-api.id
  stage_name    = "dev"

  variables = {
    "stage" = "dev"
  }

}

resource "aws_dynamodb_table" "resume-dynamodb" {
  name             = "resume-table"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
  server_side_encryption { enabled = true } 
  tags = {
    Name        = "dynamodb-resume-table"
    Environment = "dev"
  }
#  lifecycle {
#    prevent_destroy = true
#  }
}

resource "aws_dynamodb_table_item" "example" {
  table_name = aws_dynamodb_table.resume-dynamodb.name
  hash_key   = aws_dynamodb_table.resume-dynamodb.hash_key

  item = <<ITEM
{
  "id": {"S": "Counter"},
  "count": {"N": "0"}
}
ITEM
}

resource "aws_iam_policy" "lambda_exec_role" {
  name = "lambda-tf-pattern-ddb-post"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem"
            ],
            "Resource": "${aws_dynamodb_table.resume-dynamodb.arn}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_exec_role.arn
}

output "cloudfront_address" {
  value = aws_cloudfront_distribution.resume_cf_distribution.domain_name
}

output "api_address" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}


resource "local_file" "config" {
    content = templatefile("templates/config.tpl",{
      invoke_url = aws_api_gateway_deployment.deployment.invoke_url
      s3bucket = aws_s3_bucket.resume-bucket.id
      cloudfront_url = aws_cloudfront_distribution.resume_cf_distribution.domain_name
      })
    filename = "config"
    #depends_on = [ aws_api_gateway_deployment.deployment ]
}