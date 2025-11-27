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

# Install Python packages and create layer ZIP
resource "terraform_data" "create_layer" {
  triggers_replace = [
    local.layer_id,
    join(",", var.architectures)
  ]

  provisioner "local-exec" {
    command = <<-EOT
      # Clean up and recreate python directory
      rm -rf ${path.module}/python ${path.module}/layer.zip
      mkdir -p ${path.module}/python

      # Install packages
      pip install -r ${path.module}/requirements.txt --target ${path.module}/python --quiet

      # Remove unnecessary files
      find ${path.module}/python -name "*.pyc" -delete
      find ${path.module}/python -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

      # Create ZIP archive
      cd ${path.module}/python && zip -r ../layer.zip . -q

      # Verify ZIP was created and has content
      if [ ! -f ${path.module}/layer.zip ] || [ ! -s ${path.module}/layer.zip ]; then
        echo "Failed to create layer.zip or it's empty"
        exit 1
      fi
    EOT
  }

  depends_on = [local_file.requirements_txt]
}

# Create the Lambda layer
resource "aws_lambda_layer_version" "layer" {
  layer_name               = local.layer_name
  compatible_runtimes      = var.compatible_runtimes
  compatible_architectures = var.architectures
  filename                 = "${path.module}/layer.zip"
  source_code_hash         = local.layer_id

  description  = var.description != "" ? var.description : "Python dependencies layer"
  license_info = var.license_info

  depends_on = [terraform_data.create_layer]
}
