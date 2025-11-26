output "layer_arn" {
  description = "ARN of the Lambda layer"
  value       = aws_lambda_layer_version.layer.arn
}

output "layer_version_arn" {
  description = "ARN of the specific layer version"
  value       = aws_lambda_layer_version.layer.layer_arn
}

output "version" {
  description = "Version number of the layer"
  value       = aws_lambda_layer_version.layer.version
}

output "created_date" {
  description = "Date the layer was created"
  value       = aws_lambda_layer_version.layer.created_date
}

output "layer_name" {
  description = "Name of the Lambda layer"
  value       = local.layer_name
}
