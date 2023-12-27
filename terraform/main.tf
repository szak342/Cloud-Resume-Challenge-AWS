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
    bucket = var.BACKEND
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






































