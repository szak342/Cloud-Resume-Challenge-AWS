resource "aws_lambda_function" "streams_lambda" {
    function_name = "process-streams-lambda"
    filename = data.archive_file.streams_lambda.output_path
    source_code_hash = data.archive_file.streams_lambda.output_base64sha256
    handler = "app.lambda_handler"
    runtime = "python3.11"
    role = aws_iam_role.lambda_assume_role.arn
  
  environment {
    variables = {
      SNS_TOPIC = aws_sns_topic.visit_couter.arn
    }
    }

    lifecycle {
      create_before_destroy = true
    }

    depends_on = [ 
      data.archive_file.streams_lambda
      ]
}

resource "aws_lambda_function_event_invoke_config" "streams_lambda_to_sns" {
  function_name = aws_lambda_function.streams_lambda.arn
  destination_config {
    on_success {
      destination = aws_sns_topic.visit_couter.arn
    }
  }
}


resource "null_resource" "build-streams-lambda" { # Building Lambda package from script

 provisioner "local-exec" {

    command = "/bin/bash script.sh streams-app"
  }
}

data "archive_file" "streams_lambda" {
  type        = "zip"
  source_dir = "../streams-app/.aws-sam/build/StreamsLambda"
  output_path = "streams_lambda.zip"
  depends_on = [
    null_resource.build-lambda
  ]
}

resource "aws_lambda_event_source_mapping" "streams_source_mapping" {
  event_source_arn  = aws_dynamodb_table.resume-dynamodb.stream_arn
  function_name     = aws_lambda_function.streams_lambda.arn
  starting_position = "LATEST"
}