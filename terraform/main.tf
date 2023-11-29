terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.24.0"        # Fixed terraform version
    }
  }
  required_version = ">= 1.2.0" # Backend for .tfstate
  backend "s3" {
    bucket = "main-bucket-28357"
    key = "terraform/resume.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

data "aws_caller_identity" "current" {}
    output "account_id" {
    value = data.aws_caller_identity.current.account_id
    }

locals {
    account_id = data.aws_caller_identity.current.account_id
}




































