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
      ALLOWED_SITES = join("," , ["https://www.${var.domain_name}", "https://${var.domain_name}", "https://${aws_cloudfront_distribution.resume_cf_distribution.domain_name}"])
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

resource "null_resource" "build-lambda" { # Building Lambda package from script

 provisioner "local-exec" {

    command = "/bin/bash script.sh"
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir = "../sam-app/.aws-sam/build/resumelambda"
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