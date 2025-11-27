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
resource "null_resource" "create_layer" {
  triggers = {
    requirements_hash = local.layer_id
    architectures     = join(",", var.architectures)
  }

  provisioner "local-exec" {
    working_dir = "${path.module}"
    command = <<-EOT
      set -e  # Exit on any error
      set -x  # Debug mode

      echo "Working directory: $(pwd)"

      # Clean up and recreate python directory
      rm -rf python layer.zip
      mkdir -p python

      echo "Installing Python packages..."

      # Use pip3 directly
      pip3 install --upgrade pip --quiet
      pip3 install -r requirements.txt --target python --quiet --no-cache-dir

      # Verify packages were installed
      if [ ! -d "python" ] || [ -z "$(ls -A python)" ]; then
        echo "ERROR: Python packages were not installed successfully"
        ls -la
        exit 1
      fi

      echo "Packages installed successfully."

      # Create ZIP archive
      cd python && zip -r ../layer.zip . -q

      # Verify ZIP was created
      if [ ! -f ../layer.zip ]; then
        echo "ERROR: Failed to create layer.zip"
        exit 1
      fi

      echo "Layer ZIP created successfully"
    EOT
  }

  depends_on = [local_file.requirements_txt]
}

# Create the Lambda layer using the generated ZIP file
resource "aws_lambda_layer_version" "layer" {
  layer_name               = local.layer_name
  compatible_runtimes      = var.compatible_runtimes
  compatible_architectures = var.architectures
  filename                 = "${path.module}/layer.zip"
  source_code_hash         = null_resource.create_layer.id

  description  = var.description != "" ? var.description : "Python dependencies layer"
  license_info = var.license_info

  depends_on = [null_resource.create_layer]
}
