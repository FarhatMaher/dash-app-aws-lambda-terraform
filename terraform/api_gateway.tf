
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
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  deployment_id = aws_api_gateway_deployment.rest_api.id
  stage_name    = var.environment # Environment-specific stage
  description   = "${var.environment} stage for the REST API"
}
