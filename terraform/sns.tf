resource "aws_sns_topic" "visit_couter" {
  name = "visit-counter-update"
}

resource "aws_sns_topic_subscription" "email-target" {
  topic_arn = aws_sns_topic.visit_couter.arn
  protocol = "email"
  endpoint = var.EMAIL
}