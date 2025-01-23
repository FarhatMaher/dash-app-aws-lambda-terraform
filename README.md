# dash-app-aws-lambda-terraform

This repository demonstrates deploying a dash app on AWS Lambda using Terraform.

## Prerequisites

To deploy the application in AWS:
- [Python](https://www.python.org/downloads/)
- [AWS account](https://aws.amazon.com/free/)
- [AWS CLI](https://aws.amazon.com/cli/)
- [Terraform](https://www.terraform.io/downloads)

## Folder structure

- `dash-app`: contains the dash app code
- `terraform`: contains the terraform code to deploy the application in AWS

## Deployment

1. Clone the repository
2. Verify that the AWS CLI is installed by running:   
     ```bash
     aws --version
     ```  
     This should return the installed version details.  

3. Configure the AWS CLI to connect to your AWS account:  
     ```bash
     aws configure
     ```  
     During configuration, you’ll be prompted to provide the following details:
     - **AWS Access Key ID**: Your IAM user’s access key.
     - **AWS Secret Access Key**: Your IAM user’s secret key.

4. Create the `terraform.tfvars` file in the `terraform` directory with the following variables:
   - **region**: The AWS region to deploy the application in.
   - **environment**: The environment name.
  example: 
  ```
  region=eu-west-2
  environment=dev
  ```
   
1. Navigate to the `terraform` directory
2. Run `terraform init`
3. Run `terraform apply --auto-approve`

