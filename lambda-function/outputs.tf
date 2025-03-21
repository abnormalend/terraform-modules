output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.function.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.function.function_name
}

output "function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.function.invoke_arn
}

output "role_arn" {
  description = "ARN of the IAM role created for the Lambda function"
  value       = aws_iam_role.lambda_role.arn
}

output "role_name" {
  description = "Name of the IAM role created for the Lambda function"
  value       = aws_iam_role.lambda_role.name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group for the Lambda function"
  value       = aws_cloudwatch_log_group.lambda_log_group.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group for the Lambda function"
  value       = aws_cloudwatch_log_group.lambda_log_group.arn
}
