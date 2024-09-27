terraform {
  required_version = ">=1.0"
  backend "local" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.67.0"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.2.0"
    }
  }
}

provider "aws" {
  region                   = var.region
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "iamadmin-general"
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}
