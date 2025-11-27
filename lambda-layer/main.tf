locals {
  layer_name = var.name_prefix != null ? "${var.name_prefix}-${var.layer_name}" : var.layer_name

  # Determine requirements content
  requirements_content = var.requirements_content != "" ? var.requirements_content : join("\n", [for pkg in var.python_packages : "${pkg}"])

  # Create a unique ID for the layer to force recreation when requirements change
  layer_id = sha256(local.requirements_content)
}

# Create the Lambda layer using pre-built ZIP file
resource "aws_lambda_layer_version" "layer" {
  layer_name               = local.layer_name
  compatible_runtimes      = var.compatible_runtimes
  compatible_architectures = var.architectures
  filename                 = "/Users/brent/code/terraform-modules/lambda-layer/layer.zip"
  source_code_hash         = "layer-v1"

  description  = var.description != "" ? var.description : "Python dependencies layer"
  license_info = var.license_info
}
