
provider "github" {
 token = var.TOKEN
}

data "github_repository" "repo" {
  name = "cloud_resume_challenge_aws"
}

resource "github_repository_file" "config_file" {
  repository          = data.github_repository.repo.name
  branch              = "main"
  file                = "terraform/config"
  content             = resource.local_file.config.content
  commit_message      = "config from terraform"
  commit_email        = "krzysztof.szadkowski@gmail.com"
  commit_author       = "Chris"
  overwrite_on_create = true
}

resource "github_repository_file" "script_js" {
  repository = data.github_repository.repo.name
  branch = "main"
  file = "webpage/js/script.js"
  content = resource.local_file.jsfile.content
  commit_message = "script.js from terraform"
  commit_email = "krzysztof.szadkowski@gmail.com"
  commit_author = "Chris"
  overwrite_on_create = true
}

resource "github_actions_variable" "cloudfront_id" {
  repository = data.github_repository.repo.name
  variable_name = "CLOUDFRONT_ID"
  value = aws_cloudfront_distribution.resume_cf_distribution.id
}

resource "github_actions_variable" "cloudfront_url" {
  repository = data.github_repository.repo.name
  variable_name = "CLOUDFRONT_URL"
  value = aws_cloudfront_distribution.resume_cf_distribution.domain_name
}

resource "github_actions_variable" "s3bucket" {
  repository = data.github_repository.repo.name
  variable_name = "S3BUCKET"
  value = aws_s3_bucket.resume-bucket.id
}

resource "github_actions_variable" "invoke_url" {
  repository = data.github_repository.repo.name
  variable_name = "API_INVOKE_URL"
  value = aws_api_gateway_deployment.deployment.invoke_url
}


