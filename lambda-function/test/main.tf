terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  profile = var.profile != "" ? var.profile : null
}

module "test_lambda" {
  source = "../"

  # minimal required inputs
  function_name = "lambda-function-test"
  handler       = "handler.handler"
  runtime       = "python3.11"

  # build from local source_dir
  source_dir = "${path.module}/src"

  architectures = ["arm64"]
  timeout       = 10
  memory_size   = 128

  # Let Lambda own the log group to avoid ResourceAlreadyExists on re-runs
  manage_log_group = false

  # demonstrate env support
  environment_variables = {
    EXAMPLE_VAR = "hello"
  }

  tags = {
    Project = "lambda-function-test"
  }
}

# Useful outputs
output "function_name" {
  value = module.test_lambda.function_name
}

output "function_arn" {
  value = module.test_lambda.function_arn
}
