
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # S3バケット名とDynamoDBテーブル名は、後で手動で作成し、設定を有効化します。
    # bucket         = "your-terraform-state-bucket-name"
    # key            = "gophish/terraform.tfstate"
    # region         = "ap-northeast-1"
    # dynamodb_table = "your-terraform-lock-table"
    # encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
