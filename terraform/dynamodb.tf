resource "aws_dynamodb_table" "resume-dynamodb" {
  name             = "resume-table"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
  server_side_encryption { enabled = true } 
  tags = {
    Name        = "dynamodb-resume-table"
    Environment = "dev"
  }
#  lifecycle {
#    prevent_destroy = true
#  }
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