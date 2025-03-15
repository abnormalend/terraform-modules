locals {
  lambda_name = var.name_prefix != null ? "${var.name_prefix}-${var.function_name}" : var.function_name
  
  # Handle source directory packaging if provided
  create_package = var.source_dir != null
  dist_dir = "${path.module}/dist"
  filename = local.create_package ? "${local.dist_dir}/${local.lambda_name}.zip" : var.filename
}

# Ensure dist directory exists
resource "local_file" "ensure_dist_dir" {
  count    = local.create_package ? 1 : 0
  content  = "Created by Terraform to ensure directory exists"
  filename = "${local.dist_dir}/.keep"

  lifecycle {
    ignore_changes = [content]
  }
}

# Create package from source directory if provided
data "archive_file" "lambda_package" {
  count       = local.create_package ? 1 : 0
  type        = "zip"
  source_dir  = var.source_dir
  output_path = local.filename
  
  depends_on = [local_file.ensure_dist_dir]
}

# Validate that either source_dir or both filename and source_code_hash are provided
locals {
  validation_error = (var.source_dir == null && (var.filename == null || var.source_code_hash == null)) ? file("ERROR: Must provide either source_dir or both filename and source_code_hash") : null
}

resource "aws_lambda_function" "function" {
  filename         = local.filename
  source_code_hash = local.create_package ? data.archive_file.lambda_package[0].output_base64sha256 : var.source_code_hash
  function_name    = local.lambda_name
  role            = aws_iam_role.lambda_role.arn
  handler         = var.handler
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrent_executions
  layers          = var.layers
  
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  tags = merge(
    var.tags,
    {
      Name = local.lambda_name
    }
  )
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.function.function_name}"
  retention_in_days = var.log_retention_days
  tags             = var.tags
}

resource "aws_iam_role" "lambda_role" {
  name = "${local.lambda_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count      = var.vpc_config != null ? 1 : 0
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "additional_policies" {
  count  = length(var.additional_policy_statements) > 0 ? 1 : 0
  name   = "${local.lambda_name}-additional-policies"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = var.additional_policy_statements
  })
}

resource "aws_iam_role_policy_attachment" "managed_policies" {
  count      = length(var.managed_policies) > 0 ? length(var.managed_policies) : 0
  role       = aws_iam_role.lambda_role.name
  policy_arn = var.managed_policies[count.index]
}
