module "lambda_function_web" {
  # Define the Lambda function for the Dash app
  source        = "terraform-aws-modules/lambda/aws"
  version       = "7.20.0"
  function_name = "dash-app"
  description   = "My awesome dash app"
  handler       = "lambda.lambda_handler" # Lambda handler function
  runtime       = "python3.8" # Python runtime version
  timeout       = 60 # Function timeout in seconds
  source_path   = "../dash-app" # Path to the source code

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
  # Define a root resource to catch all requests
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "{proxy+}" # Catch-all path for the API
}

resource "aws_api_gateway_method" "root_proxy" {
  # Allow any HTTP method on the root proxy
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE" # No authentication required
}

resource "aws_api_gateway_integration" "root_lambda" {
  # Integrate root proxy with the Lambda function
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_rest_api.rest_api.root_resource_id
  http_method             = aws_api_gateway_method.root_proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY" # Direct integration with Lambda
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
  # Integrate proxy resource with the Lambda function
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.root.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY" # Direct integration with Lambda
  uri                     = module.lambda_function_web.lambda_function_invoke_arn
}

resource "aws_api_gateway_deployment" "rest_api" {
  # Deploy the REST API
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.root_lambda
  ] # Ensure all integrations are set before deployment
}

resource "aws_api_gateway_stage" "dev" {
  # Create a stage for the REST API
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  deployment_id = aws_api_gateway_deployment.rest_api.id
  stage_name    = var.environment # Environment-specific stage name
  description   = "${var.environment} stage for the REST API"
}

resource "aws_lambda_permission" "api_gateway" {
  # Grant API Gateway permission to invoke the Lambda function
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function_web.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*" # Allow access from any method and path
}
