terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.24.0" # Fixed terraform version
    }
     github = {
      source  = "integrations/github"
      }
  }
 
  required_version = ">= 1.2.0" # Backend for .tfstate
  backend "s3" {
    bucket = "main-bucket-28357"
    key    = "terraform/resume.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}
# TODO ------
resource "null_resource" "shutdown_website" { # Removes index.html
  count = var.enable_shutdown_website ? 1 : 0
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "aws s3 rm s3://${aws_s3_bucket.resume-bucket.id}/index.html"
  }
}





































