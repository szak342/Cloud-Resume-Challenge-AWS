resource "aws_lambda_function" "websocket_lambda_response" {
  filename         = data.archive_file.websocket_lambda_response_zip.output_path
  function_name    = "websocket-lambda-response"
  role             = aws_iam_role.websocket_lambda_response_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.websocket_lambda_response_zip.output_base64sha256

  environment {
    variables = {
      CONNECTION_ID_TABLE = "${aws_dynamodb_table.resume-dynamodb-connection-ids.name}"
      COUNTER_TABLE       = "${aws_dynamodb_table.resume-dynamodb.name}"
      WEBSOCKET_ENDPOINT  = "https://${aws_apigatewayv2_api.websocket_api_gateway.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_apigatewayv2_stage.websocket_api_stage.name}"
      SNS_TOPIC = "${aws_sns_topic.visit_counter.arn}"
    }
  }
}


resource "null_resource" "build-lambda-websockets-response" { # Building Lambda package from script

  provisioner "local-exec" {

    command = "/bin/bash script.sh websockets-response-app"
  }
}

resource "aws_lambda_event_source_mapping" "streams_source_mapping" {
  event_source_arn  = aws_dynamodb_table.resume-dynamodb.stream_arn
  function_name     = aws_lambda_function.websocket_lambda_response.arn
  starting_position = "LATEST"
}

data "archive_file" "websocket_lambda_response_zip" {
  type        = "zip"
  source_dir  = "../websockets-response-app/.aws-sam/build/websocketsResponseLambda/"
  output_path = "websockets_lambda_response.zip"
  depends_on  = [null_resource.build-lambda-websockets-response]
}

resource "aws_iam_policy" "websocket_lambda_response_policy" {
  name   = "websocket-lambda-repsponse-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.websocket_lambda_response_policy.json
}


resource "aws_iam_role" "websocket_lambda_response_role" {
  name = "websocket-lambda-response-role"

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
    name   = "lambda-to-dynamodb-policy-websockets-response"
    policy = data.aws_iam_policy_document.websocket_lambda_response_policy.json
  }
  inline_policy {
    name   = "lambda-to-sns-policy"
    policy = data.aws_iam_policy_document.lambda_to_sns_policy.json
  }
}

data "aws_iam_policy_document" "websocket_lambda_response_policy" {
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
      "dynamodb:UpdateItem"
    ]
    effect = "Allow"
    resources = [
      "${aws_dynamodb_table.resume-dynamodb-connection-ids.arn}",
      "${aws_dynamodb_table.resume-dynamodb-connection-ids.arn}/*",
      "${aws_dynamodb_table.resume-dynamodb.arn}",
      "${aws_dynamodb_table.resume-dynamodb.arn}/*"
    ]
  }
  statement {
    actions = [
      "apigatewayv2:ApiInvoke",
      "apigatewayv2:ManageConnections",
      "execute-api:ManageConnections",
      "execute-api:Invoke"
    ]
    effect = "Allow"
    resources = [
      "${aws_apigatewayv2_api.websocket_api_gateway.execution_arn}/*",
      "${aws_apigatewayv2_api.websocket_api_gateway.execution_arn}"
    ]
  }
}