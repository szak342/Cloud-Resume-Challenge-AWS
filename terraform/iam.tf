resource "aws_iam_policy" "lambda_exec_role" {
  name = "lambda-tf-pattern-ddb-post"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem"
            ],
            "Resource": "${aws_dynamodb_table.resume-dynamodb.arn}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_exec_role.arn
}

data "aws_iam_policy_document" "allow_access_from_cloud_front" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    effect = "Allow"

    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.resume-bucket.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.resume_cf_distribution.arn]
    }
  }
}

resource "aws_iam_role" "lambda_assume_role" {
  name               = "lambda-dynamodb-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "LambdaAssumeRole"
    }
  ]
}
EOF

  inline_policy {
    name   = "lambda-to-sns-policy"
    policy = data.aws_iam_policy_document.lambda_to_sns_policy.json
  }

}

data "aws_iam_policy_document" "lambda_to_sns_policy" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = ["${aws_sns_topic.visit_couter.arn}"]
  }
    statement {
    effect    = "Allow"
    actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "dynamodb_read_log_policy" {
  name   = "lambda-dynamodb-log-policy"
  role   = aws_iam_role.lambda_assume_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": [ "logs:*" ],
        "Effect": "Allow",
        "Resource": [ "arn:aws:logs:*:*:*" ]
    },
    {
        "Action": [ "dynamodb:BatchGetItem",
                    "dynamodb:GetItem",
                    "dynamodb:GetRecords",
                    "dynamodb:Scan",
                    "dynamodb:Query",
                    "dynamodb:GetShardIterator",
                    "dynamodb:DescribeStream",
                    "dynamodb:ListStreams" ],
        "Effect": "Allow",
        "Resource": [
          "${aws_dynamodb_table.resume-dynamodb.arn}",
          "${aws_dynamodb_table.resume-dynamodb.arn}/*"
        ]
    }

  ]
}
EOF
}
