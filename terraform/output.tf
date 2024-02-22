output "cloudfront_address" {
  value = aws_cloudfront_distribution.resume_cf_distribution.domain_name
}


output "account_id" {
  value = data.aws_caller_identity.current.account_id
}


output "websocket_api_url" {
  value = aws_apigatewayv2_stage.websocket_api_stage.invoke_url
}

output "websocket_api_domain_name" {
  value = aws_apigatewayv2_api.websocket_api_gateway.api_endpoint
}

output "websocket_api_id" {
  value = aws_apigatewayv2_api.websocket_api_gateway.id
}

output "url_for_lambda_function" {
  value = "https://${aws_apigatewayv2_api.websocket_api_gateway.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_apigatewayv2_stage.websocket_api_stage.name}"
}