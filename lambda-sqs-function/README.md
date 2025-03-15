# Lambda SQS Function Module

This module creates an AWS Lambda function with an SQS queue trigger. It builds upon the base lambda-function module and adds:
- An SQS queue
- Event source mapping to trigger the Lambda from the queue
- Required IAM permissions for the Lambda to process SQS messages

## Usage

```hcl
module "processor_lambda" {
  source = "path/to/lambda-sqs-function"

  project_name = "my-project"
  environment  = "dev"
  
  # Lambda Configuration
  function_name = "process-messages"
  handler      = "index.handler"
  runtime      = "python3.9"
  source_dir   = "${path.module}/src/processor"
  timeout      = 30
  memory_size  = 128
  
  # SQS Configuration
  queue_name                = "message-processor"
  message_retention_seconds = 1209600  # 14 days
  visibility_timeout_seconds = 30
  batch_size                = 1
}
```

## Requirements

- An existing lambda-function module in the parent directory
- AWS provider configured

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment (dev/prod) | `string` | n/a | yes |
| function_name | Name of the Lambda function | `string` | n/a | yes |
| handler | Lambda function handler | `string` | n/a | yes |
| runtime | Lambda function runtime | `string` | n/a | yes |
| source_dir | Directory containing Lambda function code | `string` | n/a | yes |
| memory_size | Lambda function memory size in MB | `number` | `128` | no |
| timeout | Lambda function timeout in seconds | `number` | `30` | no |
| environment_variables | Environment variables for Lambda | `map(string)` | `{}` | no |
| layers | List of Lambda layer ARNs | `list(string)` | `[]` | no |
| queue_name | Name of the SQS queue | `string` | n/a | yes |
| message_retention_seconds | Message retention period | `number` | `1209600` | no |
| visibility_timeout_seconds | Visibility timeout | `number` | `30` | no |
| batch_size | Max records per batch | `number` | `1` | no |
| maximum_batching_window_in_seconds | Max batching window | `number` | `0` | no |

## Outputs

| Name | Description |
|------|-------------|
| function_name | Name of the Lambda function |
| function_arn | ARN of the Lambda function |
| role_name | Name of the Lambda IAM role |
| role_arn | ARN of the Lambda IAM role |
| queue_url | URL of the SQS queue |
| queue_arn | ARN of the SQS queue |
| queue_name | Name of the SQS queue |
