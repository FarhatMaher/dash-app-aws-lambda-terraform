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

resource "aws_api_gateway_rest_api" "rest_api" {
  # Create a REST API for the Dash app
  name        = "dash-app-rest-api"
  description = "API Gateway REST API for the Dash app"
}

resource "aws_api_gateway_resource" "root" {
  # Define the root resource to act as a catch-all proxy
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "{proxy+}" # Catch-all path
}

resource "aws_api_gateway_method" "root_proxy" {
  # Allow any HTTP method on the root proxy
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE" # No authentication required
}

resource "aws_api_gateway_integration" "root_lambda" {
  # Integrate root proxy with Lambda
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_rest_api.rest_api.root_resource_id
  http_method             = aws_api_gateway_method.root_proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY" # Use AWS_PROXY for Lambda integration
  uri                     = module.lambda_function_web.lambda_function_invoke_arn
}

resource "aws_api_gateway_method" "proxy" {
  # Allow any HTTP method on the proxy resource
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.root.id
  http_method   = "ANY"
  authorization = "NONE" # No authentication required
}

resource "aws_api_gateway_integration" "lambda" {
  # Integrate proxy resource with Lambda
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.root.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_function_web.lambda_function_invoke_arn
}

resource "aws_api_gateway_deployment" "rest_api" {
  # Deploy the REST API
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.root_lambda
  ] # Ensure integrations are set up before deployment
}

resource "aws_api_gateway_stage" "dev" {
  # Create a stage for the REST API
  rest_api_id   = aws_api_gateway_rest_api.id
  deployment_id = aws_api_gateway_deployment.rest_api.id
  stage_name    = var.environment # Environment-specific stage
  description   = "${var.environment} stage for the REST API"
}

resource "aws_lambda_permission" "api_gateway" {
  # Grant API Gateway permission to invoke the Lambda function
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function_web.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"
}
