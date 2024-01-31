resource "local_file" "jsfile" {
    content = templatefile("templates/script.tpl",{invoke_url = aws_api_gateway_deployment.deployment.invoke_url})
    filename = "../webpage/js/script.js"
    depends_on = [ aws_api_gateway_deployment.deployment ]
    lifecycle {
      create_before_destroy = true
    }
}

resource "null_resource" "upload_website" {
  provisioner "local-exec" {
    command = <<EOT
    aws s3 sync ../webpage "s3://${aws_s3_bucket.resume-bucket.id}"
    EOT
  }
  depends_on = [aws_s3_bucket.resume-bucket, local_file.jsfile]
}
