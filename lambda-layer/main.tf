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

# Create initial dummy ZIP file (will be replaced by provisioner)
resource "local_file" "layer_zip" {
  content  = "dummy"
  filename = "${path.module}/layer.zip"
}

# Install Python packages and replace the dummy ZIP
resource "null_resource" "create_layer" {
  triggers = {
    requirements_hash = local.layer_id
    architectures     = join(",", var.architectures)
  }

  provisioner "local-exec" {
    working_dir = "${path.module}"
    command = <<-EOT
      set -e

      echo "Creating layer in $(pwd)"

      # Clean up and recreate python directory
      rm -rf python
      mkdir -p python

      # Install packages
      pip3 install -r requirements.txt --target python --quiet --no-cache-dir

      # Create real ZIP archive
      cd python && zip -r ../layer.zip . -q

      echo "Layer created successfully"
    EOT
  }

  depends_on = [local_file.requirements_txt, local_file.layer_zip]
}

# Create the Lambda layer
resource "aws_lambda_layer_version" "layer" {
  layer_name               = local.layer_name
  compatible_runtimes      = var.compatible_runtimes
  compatible_architectures = var.architectures
  filename                 = local_file.layer_zip.filename
  source_code_hash         = null_resource.create_layer.id

  description  = var.description != "" ? var.description : "Python dependencies layer"
  license_info = var.license_info

  depends_on = [null_resource.create_layer]
}
