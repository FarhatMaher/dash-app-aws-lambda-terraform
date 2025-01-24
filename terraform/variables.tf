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
variable "docker_host" {
  type        = string
  description = "The docker host"
  default     = "unix:///var/run/docker.sock"
}