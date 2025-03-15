locals {
  lambda_name = var.name_prefix != null ? "${var.name_prefix}-${var.function_name}" : var.function_name
}

resource "aws_lambda_function" "function" {
  filename         = var.filename
  source_code_hash = var.source_code_hash
  function_name    = local.lambda_name
  role            = aws_iam_role.lambda_role.arn
  handler         = var.handler
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size

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

  dynamic "layers" {
    for_each = var.layers
    content {
      layers = layers.value
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
