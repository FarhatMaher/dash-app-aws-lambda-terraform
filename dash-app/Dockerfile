# Use AWS Lambda Python 3.8 base image
FROM public.ecr.aws/lambda/python:3.8

# Copy application files into the container
COPY . ${LAMBDA_TASK_ROOT}

# Install dependencies
RUN pip install --no-cache-dir -r ${LAMBDA_TASK_ROOT}/requirements.txt

# Set the handler
CMD ["lambda.handler"]