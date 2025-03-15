# Lambda outputs
output "function_name" {
  description = "Name of the created Lambda function"
  value       = module.lambda_function.function_name
}

output "function_arn" {
  description = "ARN of the created Lambda function"
  value       = module.lambda_function.function_arn
}

output "role_name" {
  description = "Name of the IAM role created for the Lambda function"
  value       = module.lambda_function.role_name
}

output "role_arn" {
  description = "ARN of the IAM role created for the Lambda function"
  value       = module.lambda_function.role_arn
}

# SQS outputs
output "queue_url" {
  description = "URL of the created SQS queue"
  value       = aws_sqs_queue.queue.url
}

output "queue_arn" {
  description = "ARN of the created SQS queue"
  value       = aws_sqs_queue.queue.arn
}

output "queue_name" {
  description = "Name of the created SQS queue"
  value       = aws_sqs_queue.queue.name
}

output "queue_id" {
  description = "ID of the created SQS queue"
  value       = aws_sqs_queue.queue.id
}
