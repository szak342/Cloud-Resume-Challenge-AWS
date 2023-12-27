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

resource "aws_api_gateway_integration" "lambda" {
    rest_api_id   = "${aws_api_gateway_rest_api.resume-api.id}"
    resource_id   = "${aws_api_gateway_resource.api-resource.id}"
    http_method   = "${aws_api_gateway_method.api-method.http_method}"
    type          = "AWS_PROXY"
    integration_http_method = "POST"
    uri = "${aws_lambda_function.resume-lambda.invoke_arn}"
    depends_on = [aws_api_gateway_method.api-method]
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.resume-api.id}"
  resource_id = "${aws_api_gateway_method.api-method.resource_id}"
  http_method = "${aws_api_gateway_method.api-method.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.resume-lambda.invoke_arn}"
}

resource "aws_api_gateway_deployment" "deployment" {
    rest_api_id   = "${aws_api_gateway_rest_api.resume-api.id}"
    stage_name    = "prod"
    depends_on    = [
      aws_api_gateway_integration.lambda,
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