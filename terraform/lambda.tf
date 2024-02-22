resource "aws_lambda_function" "websocket_lambda" {
  filename         = data.archive_file.websocket_lambda_zip.output_path
  function_name    = "websocket-lambda"
  role             = aws_iam_role.websocket_lambda_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.websocket_lambda_zip.output_base64sha256

  environment {
    variables = {
      CONNECTION_ID_TABLE = "${aws_dynamodb_table.resume-dynamodb-connection-ids.name}"
      COUNTER_TABLE       = "${aws_dynamodb_table.resume-dynamodb.name}"
      ALLOWED_ORIGINS = join("," , ["https://www.${var.DOMAIN_NAME}", "https://${var.DOMAIN_NAME}", "https://${aws_cloudfront_distribution.resume_cf_distribution.domain_name}"])
      ALLOWED_HOST = "${aws_apigatewayv2_api.websocket_api_gateway.id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
    }
  }
}

resource "aws_cloudwatch_log_group" "websocket_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.websocket_lambda.function_name}"
  retention_in_days = 30
}

resource "null_resource" "build-lambda-websockets" { # Building Lambda package from script

  provisioner "local-exec" {

    command = "/bin/bash script.sh websockets-app"
  }
}

data "archive_file" "websocket_lambda_zip" {
  type        = "zip"
  source_dir  = "../websockets-app/.aws-sam/build/websocketsLambda/"
  output_path = "websockets_lambda.zip"
  depends_on  = [null_resource.build-lambda-websockets]
}

resource "aws_iam_policy" "websocket_lambda_policy" {
  name   = "websocket-lambda-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.websocket_lambda_policy.json
}


resource "aws_iam_role" "websocket_lambda_role" {
  name = "websocket-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name   = "lambda-to-dynamodb-policy-websockets"
    policy = data.aws_iam_policy_document.websocket_lambda_policy.json
  }
}

data "aws_iam_policy_document" "websocket_lambda_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:GetItem",
      "dynamodb:GetRecords",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:GetShardIterator",
      "dynamodb:DescribeStream",
      "dynamodb:ListStreams",
      "dynamodb:PutItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
    ]
    effect = "Allow"
    resources = [
      "${aws_dynamodb_table.resume-dynamodb-connection-ids.arn}",
      "${aws_dynamodb_table.resume-dynamodb-connection-ids.arn}/*",
      "${aws_dynamodb_table.resume-dynamodb.arn}",
      "${aws_dynamodb_table.resume-dynamodb.arn}/*"
    ]
  }
}
