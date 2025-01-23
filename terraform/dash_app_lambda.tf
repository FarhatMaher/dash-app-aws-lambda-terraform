module "lambda_function_web" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "7.20.0"
  function_name = "dash-app"
  description   = "My awesome dash app"
  handler       = "lambda.lambda_handler"
  runtime       = "python3.8"
  timeout       = 60
  source_path   = "../dash-app"

  environment_variables = {
    ENV                      = var.environment
    REQUESTS_PATHNAME_PREFIX = "/${var.environment}/"
  }
  tags = {
    environment = var.environment
  }
}

resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "dash-app-rest-api"
  description = "API Gateway REST API for the Dash app"
}

resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "{proxy+}"  # Catch-all proxy for the API
}

resource "aws_api_gateway_method" "root_proxy" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  http_method   = "ANY"  # Allow any HTTP method
  authorization = "NONE" # No authorization required
}

resource "aws_api_gateway_integration" "root_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_rest_api.rest_api.root_resource_id
  http_method             = aws_api_gateway_method.root_proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY" # Use AWS_PROXY integration
  uri                     = module.lambda_function_web.lambda_function_invoke_arn
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.root.id
  http_method   = "ANY"  # Allow any HTTP method
  authorization = "NONE" # No authorization required
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.root.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY" # Use AWS_PROXY integration
  uri                     = module.lambda_function_web.lambda_function_invoke_arn
}

resource "aws_api_gateway_deployment" "rest_api" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.root_lambda
  ] # Ensure integrations are set up before deployment
}

resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  deployment_id = aws_api_gateway_deployment.rest_api.id
  stage_name    = var.environment
  description   = "${var.environment} stage for the REST API"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function_web.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*" # Allow invocation from any method and resource path
}
