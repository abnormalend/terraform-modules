# AWS Lambda Function Terraform Module

This Terraform module creates a fully featured AWS Lambda function with associated IAM roles, CloudWatch logging, and optional VPC configuration.

## Features

- Lambda function creation with configurable runtime settings
- Automatic IAM role and policy creation
- CloudWatch log group with configurable retention
- Optional VPC configuration
- Environment variables support
- Additional IAM policy attachment support
- Customizable naming with optional prefix
- Resource tagging

## Usage

```hcl
module "lambda_function" {
  source = "./lambda-function"

  function_name    = "my-function"
  filename         = "function.zip"
  source_code_hash = filebase64sha256("function.zip")
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  
  # Optional configurations
  timeout         = 30
  memory_size     = 256
  
  environment_variables = {
    ENV_VAR_1 = "value1"
    ENV_VAR_2 = "value2"
  }
  
  # VPC Configuration (optional)
  vpc_config = {
    subnet_ids         = ["subnet-123", "subnet-456"]
    security_group_ids = ["sg-123"]
  }
  
  # Additional IAM policies (optional)
  additional_policy_statements = [
    {
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      Resource = ["arn:aws:s3:::my-bucket/*"]
    }
  ]
  
  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

## Requirements

- AWS provider
- Terraform >= 0.13

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| function_name | Name of the Lambda function | string | - | yes |
| filename | Path to the function's deployment package | string | - | yes |
| source_code_hash | Base64-encoded SHA256 hash of the package file | string | - | yes |
| handler | Function entrypoint in your code | string | - | yes |
| runtime | Lambda function runtime | string | - | yes |
| name_prefix | Optional prefix for the Lambda function name | string | null | no |
| timeout | Amount of time your Lambda Function has to run in seconds | number | 3 | no |
| memory_size | Amount of memory in MB your Lambda Function can use | number | 128 | no |
| environment_variables | Map of environment variables | map(string) | {} | no |
| vpc_config | VPC configuration for the Lambda function | object | null | no |
| log_retention_days | Number of days to retain Lambda logs | number | 14 | no |
| tags | Tags to attach to resources | map(string) | {} | no |
| additional_policy_statements | Additional IAM policy statements | list(any) | [] | no |

## Outputs

| Name | Description |
|------|-------------|
| function_arn | ARN of the Lambda function |
| function_name | Name of the Lambda function |
| function_invoke_arn | Invoke ARN of the Lambda function |
| role_arn | ARN of the IAM role |
| role_name | Name of the IAM role |
| log_group_name | Name of the CloudWatch log group |
| log_group_arn | ARN of the CloudWatch log group |
