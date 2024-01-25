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
    aws s3 sync ../webpage s3://${aws_s3_bucket.resume-bucket.id}
    EOT
  }
  depends_on = [aws_s3_bucket.resume-bucket, local_file.jsfile]
}
#
#resource "aws_s3_object" "jsfile" {
#  source = local_file.jsfile.filename
#  key = "script.js"
#  bucket = aws_s3_bucket.resume-bucket.id
#  content_type = "application/javascript"
#  depends_on = [ local_file.jsfile ]
#  }
#
#resource "aws_s3_object" "index" {
#  bucket = aws_s3_bucket.resume-bucket.id
#  key = "index.html"
#  source = "../webpage/index.html"
#  content_type = "text/html"
#  depends_on = [ 
#                aws_api_gateway_deployment.deployment 
#                ]
#}
#
#resource "aws_s3_object" "cssfiles" {
#  for_each = fileset("../webpage/css/", "*.css")
#  bucket = aws_s3_bucket.resume-bucket.id
#  key = "css/${each.value}"
#  source = "../webpage/css/${each.value}"
#  content_type = "text/css"
#  depends_on = [ 
#                aws_api_gateway_deployment.deployment 
#                ]
#}
#
#resource "aws_s3_object" "scssfiles" {
#  for_each = fileset("../webpage/scss/", "*.scss")
#  bucket = aws_s3_bucket.resume-bucket.id
#  key = "scss/${each.value}"
#  source = "../webpage/scss/${each.value}"
#  content_type = "text/css"
#  depends_on = [ 
#                aws_api_gateway_deployment.deployment 
#                ]
#}
#
#resource "aws_s3_object" "images_png" {
#  for_each = fileset("../webpage/img/", "*.png")
#  bucket = aws_s3_bucket.resume-bucket.id
#  key = "img/${each.value}"
#  source = "../webpage/img/${each.value}"
#  content_type = "image/png"
#  depends_on = [ 
#                aws_api_gateway_deployment.deployment 
#                ]
#}
#
#resource "aws_s3_object" "images_jpg" {
#  for_each = fileset("../webpage/img/", "*.jpg")
#  bucket = aws_s3_bucket.resume-bucket.id
#  key = "img/${each.value}"
#  source = "../webpage/img/${each.value}"
#  content_type = "image/jpg"
#  depends_on = [ 
#                aws_api_gateway_deployment.deployment 
#                ]
#}