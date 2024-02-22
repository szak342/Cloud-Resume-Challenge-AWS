resource "aws_apigatewayv2_api" "websocket_api_gateway" {
  name                       = "resume-websocket-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_integration" "websocket_api_integration" {
  api_id                    = aws_apigatewayv2_api.websocket_api_gateway.id
  integration_type          = "AWS_PROXY"
  integration_uri           = aws_lambda_function.websocket_lambda.invoke_arn
  credentials_arn           = aws_iam_role.websocket_api_gateway_role.arn
  content_handling_strategy = "CONVERT_TO_TEXT"
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_integration_response" "websocket_api_integration_response" {
  api_id                   = aws_apigatewayv2_api.websocket_api_gateway.id
  integration_id           = aws_apigatewayv2_integration.websocket_api_integration.id
  integration_response_key = "/200/"
}

resource "aws_apigatewayv2_route" "websocket_api_connect_route" {
  api_id    = aws_apigatewayv2_api.websocket_api_gateway.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.websocket_api_integration.id}"
}


resource "aws_apigatewayv2_route" "websocket_api_disconnect_route" {
  api_id    = aws_apigatewayv2_api.websocket_api_gateway.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.websocket_api_integration.id}"
}


resource "aws_apigatewayv2_stage" "websocket_api_stage" {
  api_id      = aws_apigatewayv2_api.websocket_api_gateway.id
  name        = "production"
  auto_deploy = true
  route_settings {
    throttling_rate_limit  = 100
    throttling_burst_limit = 100
    route_key              = "$connect"
  }
}

resource "aws_lambda_permission" "websocket_api_lambda_permissions" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.websocket_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api_gateway.execution_arn}/*/*"
}

data "aws_iam_policy_document" "websocket_api_gateway_policy" {
  statement {
    actions = [
      "lambda:InvokeFunction",
    ]
    effect    = "Allow"
    resources = [aws_lambda_function.websocket_lambda.arn]
  }
}

resource "aws_iam_policy" "websocket_api_gateway_policy" {
  name   = "websocket_api_gateway_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.websocket_api_gateway_policy.json
}

resource "aws_iam_role" "websocket_api_gateway_role" {
  name = "websocket_api_gateway_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [aws_iam_policy.websocket_api_gateway_policy.arn]
}
