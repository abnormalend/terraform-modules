terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# Test the lambda-layer module
module "test_layer" {
  source = "../"

  layer_name = "test-python-deps"

  requirements_content = "requests\nebooklib\nbeautifulsoup4"

  compatible_runtimes = ["python3.11"]
  architectures       = ["arm64"]

  description = "Test Python dependencies layer"
}

# Output the layer ARN for verification
output "layer_arn" {
  value = module.test_layer.layer_arn
}

output "layer_version_arn" {
  value = module.test_layer.layer_version_arn
}
