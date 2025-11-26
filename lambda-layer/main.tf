locals {
  layer_name = var.name_prefix != null ? "${var.name_prefix}-${var.layer_name}" : var.layer_name

  # Determine requirements content
  requirements_content = var.requirements_content != "" ? var.requirements_content : join("\n", [for pkg in var.python_packages : "${pkg}"])

  # Create a unique ID for the layer to force recreation when requirements change
  layer_id = sha256(local.requirements_content)
}

# Create requirements.txt file locally
resource "local_file" "requirements_txt" {
  content  = local.requirements_content
  filename = "${path.module}/requirements.txt"
}

# Install Python packages to local directory
resource "null_resource" "install_packages" {
  triggers = {
    requirements_hash = local.layer_id
    architectures     = join(",", var.architectures)
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Clean up any existing python directory
      rm -rf ${path.module}/python

      # Create python directory structure
      mkdir -p ${path.module}/python

      # Install packages
      pip install -r ${path.module}/requirements.txt --target ${path.module}/python --quiet

      # Remove unnecessary files to reduce size
      find ${path.module}/python -name "*.pyc" -delete
      find ${path.module}/python -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    EOT
  }

  depends_on = [local_file.requirements_txt]
}

# Create ZIP archive of the Python packages
data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/python"
  output_path = "${path.module}/layer.zip"

  depends_on = [null_resource.install_packages]
}

# Create the Lambda layer
resource "aws_lambda_layer_version" "layer" {
  layer_name               = local.layer_name
  compatible_runtimes      = var.compatible_runtimes
  compatible_architectures = var.architectures
  filename                 = data.archive_file.layer_zip.output_path
  source_code_hash         = data.archive_file.layer_zip.output_base64sha256

  description  = var.description != "" ? var.description : "Python dependencies layer"
  license_info = var.license_info
}
