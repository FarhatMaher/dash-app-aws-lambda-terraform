locals {
  # Define source path and patterns for including/excluding files
  source_path   = "../dash-app"
  path_include  = ["**"] # Include all files
  path_exclude  = ["**/__pycache__/**"] # Exclude Python cache directories
  files_include = setunion([for f in local.path_include : fileset(local.source_path, f)]...)
  files_exclude = setunion([for f in local.path_exclude : fileset(local.source_path, f)]...)
  files         = sort(setsubtract(local.files_include, local.files_exclude)) # Final file list
  dir_sha       = sha1(join("", [for f in local.files : filesha1("${local.source_path}/${f}")])) # Generate a unique hash based on file contents
}

module "docker_build_app" {
  # Use a pre-built Terraform module to build a Docker image for Lambda
  source        = "terraform-aws-modules/lambda/aws//modules/docker-build"
  ecr_repo      = aws_ecr_repository.ecr_repo.name
  use_image_tag = true
  image_tag     = "app-${local.dir_sha}" # Unique image tag for each build
  source_path   = local.source_path
  platform      = "linux/x86_64" # Target architecture
  triggers = {
    dir_sha = local.dir_sha # Rebuild Docker image if files change
  }
}

module "lambda_function_web" {
  # Define the Lambda function to deploy the Dash app
  source        = "terraform-aws-modules/lambda/aws"
  version       = "7.20.0"
  function_name = "dash-app"
  description   = "My awesome dash app"
  package_type  = "Image" # Use Docker image for Lambda deployment
  architectures = ["x86_64"]
  image_uri     = module.docker_build_app.image_uri
  create_package = false
  timeout       = 60 # Lambda timeout in seconds

  environment_variables = {
    ENV                      = var.environment
    REQUESTS_PATHNAME_PREFIX = "/${var.environment}/"
  }
  tags = {
    environment = var.environment
  }
}

resource "aws_lambda_permission" "api_gateway" {
  # Grant API Gateway permission to invoke the Lambda function
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function_web.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"
}