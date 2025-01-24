terraform {
  required_providers {
    # Specifies the AWS provider and its version
    aws = {
      source  = "hashicorp/aws"
      version = "5.84.0"
    }
    # Specifies the Docker provider and its version
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}
provider "aws" {
  # Configure the AWS provider with the specified region
  region = var.region
}

provider "docker" {
  # Configure the Docker provider with the specified host
  host = var.docker_host

  # Set up authentication with the AWS ECR registry
  registry_auth {
    address  = format("%v.dkr.ecr.%v.amazonaws.com", data.aws_caller_identity.this.account_id, var.region) # ECR registry URL
    username = data.aws_ecr_authorization_token.token.user_name # Username for ECR
    password = data.aws_ecr_authorization_token.token.password  # Password for ECR
  }
}
