resource "local_file" "config" {
    content = templatefile("templates/config.tpl",{
      invoke_url = aws_api_gateway_deployment.deployment.invoke_url
      s3bucket = aws_s3_bucket.resume-bucket.id
      cloudfront_url = aws_cloudfront_distribution.resume_cf_distribution.domain_name
      cloudfront_id = aws_caller_identity.resume_cf_distribution.id
      })
    filename = "config"
    #depends_on = [ aws_api_gateway_deployment.deployment ]
}