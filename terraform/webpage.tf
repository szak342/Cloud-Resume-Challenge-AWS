resource "local_file" "jsfile" {
    content = templatefile("templates/script.tpl",{invoke_url = aws_api_gateway_deployment.deployment.invoke_url})
    filename = "../webpage/script.js"
    depends_on = [ aws_api_gateway_deployment.deployment ]
    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_s3_object" "jsfile" {
  source = local_file.jsfile.filename
  key = "script.js"
  bucket = aws_s3_bucket.resume-bucket.id
  content_type = "application/javascript"
  depends_on = [ local_file.jsfile ]
  }

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.resume-bucket.id
  key = "index.html"
  source = "../webpage/index.html"
  content_type = "text/html"
  depends_on = [ 
                aws_api_gateway_deployment.deployment 
                ]
}

resource "aws_s3_object" "cssfile" {
  source = "../webpage/styles.css"
  key = "styles.css"
  bucket = aws_s3_bucket.resume-bucket.id
  content_type = "text/css"
  depends_on = [ 
                aws_api_gateway_deployment.deployment 
                ]
}

resource "aws_s3_object" "images" {
  for_each = fileset("../webpage/img/", "*")
  bucket = aws_s3_bucket.resume-bucket.id
  key = "img/${each.value}"
  source = "../webpage/img/${each.value}"
  content_type = "image/png"
  depends_on = [ 
                aws_api_gateway_deployment.deployment 
                ]
}