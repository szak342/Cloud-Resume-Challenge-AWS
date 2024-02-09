resource "aws_dynamodb_table" "resume-dynamodb" {
  name         = "resume-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  stream_enabled = true
  stream_view_type = "NEW_IMAGE"

  attribute {
    name = "id"
    type = "S"
  }
  server_side_encryption { enabled = true }
  tags = {
    Name        = "dynamodb-resume-table"
    Environment = "dev"
  }
}

resource "aws_dynamodb_table_item" "example" {
  table_name = aws_dynamodb_table.resume-dynamodb.name
  hash_key   = aws_dynamodb_table.resume-dynamodb.hash_key

  item = <<ITEM
{
  "id": {"S": "Counter"},
  "count": {"N": "0"}
}
ITEM
}
