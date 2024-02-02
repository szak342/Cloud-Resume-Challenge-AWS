
provider "github" {
  token = var.TOKEN
}

data "github_repository" "repo" {
  name = "cloud_resume_challenge_aws"
}

resource "github_repository_file" "script_js" {
  repository          = data.github_repository.repo.name
  branch              = "main"
  file                = "webpage/js/script.js"
  content             = resource.local_file.jsfile.content
  commit_message      = "script.js from terraform"
  commit_email        = "krzysztof.szadkowski@gmail.com"
  commit_author       = "Chris"
  overwrite_on_create = true
}

resource "github_repository_file" "script_js_dev" {
  repository          = data.github_repository.repo.name
  branch              = "dev"
  file                = "webpage/js/script.js"
  content             = resource.local_file.jsfile.content
  commit_message      = "script.js from terraform"
  commit_email        = "krzysztof.szadkowski@gmail.com"
  commit_author       = "Chris"
  overwrite_on_create = true
}


resource "github_actions_secret" "cloudfront_id" {
  repository      = data.github_repository.repo.name
  secret_name     = "CLOUDFRONT_ID"
  plaintext_value = aws_cloudfront_distribution.resume_cf_distribution.id
}

resource "github_actions_secret" "cloudfront_url" {
  repository      = data.github_repository.repo.name
  secret_name     = "CLOUDFRONT_URL"
  plaintext_value = aws_cloudfront_distribution.resume_cf_distribution.domain_name
}

resource "github_actions_secret" "s3bucket" {
  repository      = data.github_repository.repo.name
  secret_name     = "S3BUCKET"
  plaintext_value = aws_s3_bucket.resume-bucket.id
}

resource "github_actions_secret" "invoke_url" {
  repository      = data.github_repository.repo.name
  secret_name     = "API_INVOKE_URL"
  plaintext_value = aws_api_gateway_deployment.deployment.invoke_url
}


