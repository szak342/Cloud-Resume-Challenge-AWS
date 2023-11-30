resource "aws_dynamodb_table" "resume-dynamodb" {
  name         = "resume-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

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
# TODO ----------

resource "null_resource" "create_dynamodb_backup" {
  count = var.enable_create_dynamodb_backup ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "aws dynamodb create-backup --table-name ${aws_dynamodb_table.resume-dynamodb.name} --backup-name backup-${aws_dynamodb_table.resume-dynamodb.name}"
  }
}


resource "null_resource" "restore_dynamodb_backup" { #with deletion of current table
  count = var.enable_restore_dynamodb_backup ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      env = ".env"
    }
    command = <<-EOT
    latest_backup_arn=$(aws dynamodb list-backups --table-name ${aws_dynamodb_table.resume-dynamodb.name} --query "BackupSummaries | [-1].BackupArn" --output text)
    aws dynamodb delete-table --table-name ${aws_dynamodb_table.resume-dynamodb.name}
    aws dynamodb restore-table-from-backup --target-table-name ${aws_dynamodb_table.resume-dynamodb.name} --backup-arn $latest_backup_arn
    EOT
  }
}


