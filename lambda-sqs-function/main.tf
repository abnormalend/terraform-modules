locals {
  lambda_name = var.name_prefix != null ? "${var.name_prefix}-${var.function_name}" : var.function_name
  queue_name = "${var.project_name}-${var.environment}-${var.queue_suffix}"
  dlq_name   = "${local.queue_name}-dlq"
}

# Create DLQ if enabled
resource "aws_sqs_queue" "dlq" {
  count = var.enable_dlq ? 1 : 0
  
  name                       = local.dlq_name
  message_retention_seconds  = var.dlq_retention_days * 86400
  visibility_timeout_seconds = var.visibility_timeout_seconds
  sqs_managed_sse_enabled   = var.enable_queue_encryption

  tags = merge(
    var.tags,
    var.additional_queue_tags,
    {
      Environment = var.environment
      Project     = var.project_name
      Type        = "DLQ"
    }
  )
}

module "lambda_function" {
  source = "../lambda-function"

  name_prefix           = var.name_prefix
  function_name        = var.function_name
  handler              = var.handler
  runtime              = var.runtime
  source_dir           = var.source_dir
  filename             = var.filename
  source_code_hash     = var.source_code_hash
  memory_size          = var.memory_size
  timeout              = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions
  environment_variables = merge(
    var.environment_variables,
    {
      QUEUE_NAME = local.queue_name
    }
  )
  layers               = var.layers
  tags                 = var.tags
}

resource "aws_sqs_queue" "queue" {
  name                       = local.queue_name
  message_retention_seconds  = var.message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  sqs_managed_sse_enabled   = var.enable_queue_encryption
  redrive_policy = var.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = 3  # Retry failed messages 3 times before moving to DLQ
  }) : null

  tags = merge(
    var.tags,
    var.additional_queue_tags,
    {
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn        = aws_sqs_queue.queue.arn
  function_name          = module.lambda_function.function_arn
  batch_size             = var.batch_size
  maximum_batching_window_in_seconds = var.maximum_batching_window_in_seconds
}

data "aws_iam_policy_document" "sqs_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:SendMessage",
      "sqs:GetQueueUrl"
    ]
    resources = concat(
      [aws_sqs_queue.queue.arn],
      var.enable_dlq ? [aws_sqs_queue.dlq[0].arn] : []
    )
  }
}

resource "aws_iam_role_policy" "lambda_sqs" {
  name   = "${local.lambda_name}-sqs-policy"
  role   = module.lambda_function.role_name
  policy = data.aws_iam_policy_document.sqs_policy.json
}

# Allow other Lambda functions to send messages to this queue
resource "aws_sqs_queue_policy" "lambda_send" {
  queue_url = aws_sqs_queue.queue.url
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueUrl"
        ]
        Resource = aws_sqs_queue.queue.arn
      }
    ]
  })
}
