locals {
  lambda_name = var.name_prefix != null ? "${var.name_prefix}-${var.function_name}" : var.function_name

  # Handle source directory packaging if provided
  create_package = var.source_dir != null
  dist_dir       = "${path.module}/dist"

  # Compute a stable hash across all files in source_dir to force code updates on change
  source_files = var.source_dir != null ? fileset(var.source_dir, "**") : []
  # Exclude common noisy paths when hashing by filtering after fileset if desired
  # (keep it simple for now; users can structure their source_dir appropriately)
  source_hash  = var.source_dir != null ? sha1(join(",", [for f in local.source_files : filesha256("${var.source_dir}/${f}")])) : null

  # Include hash in the zip filename so Terraform sees a new artifact when code changes
  filename = local.create_package ? "${local.dist_dir}/${local.lambda_name}-${local.source_hash}.zip" : var.filename
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
  source_validation = (
    (var.source_dir != null) ||
    (var.filename != null && var.source_code_hash != null)
  )
  source_validation_message = (
    var.source_dir != null ?
    "Using source_dir for packaging" :
    (var.filename != null && var.source_code_hash != null ?
     "Using provided filename and source_code_hash" :
     "ERROR: Must provide either source_dir or both filename and source_code_hash")
  )
}

resource "aws_lambda_function" "function" {
  filename         = local.filename
  source_code_hash = local.create_package ? data.archive_file.lambda_package[0].output_base64sha256 : var.source_code_hash
  function_name    = local.lambda_name
  role            = aws_iam_role.lambda_role.arn
  handler         = var.handler
  runtime         = var.runtime
  architectures   = var.architectures
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
  count             = var.manage_log_group ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.function.function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
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
