terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.70"
      configuration_aliases = [
        aws.eu-west-2,
        aws.eu-west-1,
        aws.us-east-1,
        aws.us-east-2,
        aws.us-west-2,
        aws.us-west-1,
        aws.ap-southeast-1,
        aws.ap-southeast-2,
        aws.ap-northeast-1,
        aws.ap-northeast-2,
        aws.ap-south-1,
        aws.eu-central-1,
        aws.eu-west-3,
        aws.sa-east-1,
        aws.ca-central-1
      ]
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
  }
}

