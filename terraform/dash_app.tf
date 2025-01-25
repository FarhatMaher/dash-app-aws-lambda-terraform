module "lambda_function_web" {
  # Define the Lambda function for the Dash app
  source        = "terraform-aws-modules/lambda/aws"
  version       = "7.20.0"
  function_name = "dash-app"
  description   = "My awesome dash app"
  handler       = "lambda.handler" # Lambda handler function
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

resource "aws_lambda_permission" "api_gateway" {
  # Grant API Gateway permission to invoke the Lambda function
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function_web.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*" # Allow access from any method and path
}
