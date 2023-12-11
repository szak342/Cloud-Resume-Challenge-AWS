output "cloudfront_address" {
  value = aws_cloudfront_distribution.resume_cf_distribution.domain_name
}

output "api_address" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}