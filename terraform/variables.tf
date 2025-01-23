variable "region" {
  type        = string
  description = "The AWS region to deploy the application in"
  default     = "eu-west-2"
}
variable "environment" {
  type        = string
  description = "The environment"
  default     = "dev"
}

