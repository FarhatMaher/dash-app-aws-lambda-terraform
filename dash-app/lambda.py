from app import app
import awsgi2
# Lambda handler, Do not remove or change this
def lambda_handler(event, context):
    return awsgi2.response(app.server, event, context)