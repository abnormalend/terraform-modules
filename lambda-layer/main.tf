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
    command = <<-EOT
      set -e  # Exit on any error
      set -x  # Debug mode

      echo "Current working directory: $(pwd)"
      echo "Path module: ${path.module}"

      # Change to the module directory
      cd ${path.module}

      echo "Changed to directory: $(pwd)"

      # Clean up and recreate python directory
      rm -rf python layer.zip
      mkdir -p python

      echo "Installing Python packages..."

      # Try multiple approaches for pip installation
      if command -v pip3 >/dev/null 2>&1; then
        PIP_CMD="pip3"
      elif command -v pip >/dev/null 2>&1; then
        PIP_CMD="pip"
      else
        echo "ERROR: Neither pip nor pip3 found"
        exit 1
      fi

      echo "Using pip command: $PIP_CMD"

      # Install packages
      $PIP_CMD install --upgrade pip --quiet
      $PIP_CMD install -r requirements.txt --target python --quiet --no-cache-dir

      # Verify packages were installed
      if [ ! -d "python" ] || [ -z "$(ls -A python)" ]; then
        echo "ERROR: Python packages were not installed successfully"
        ls -la
        exit 1
      fi

      echo "Packages installed successfully. Cleaning up..."

      # Remove unnecessary files
      find python -name "*.pyc" -delete 2>/dev/null || true
      find python -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

      echo "Creating ZIP archive..."

      # Create ZIP archive
      cd python && zip -r ../layer.zip . -q

      # Verify ZIP was created and has content
      if [ ! -f ../layer.zip ] || [ ! -s ../layer.zip ]; then
        echo "ERROR: Failed to create layer.zip or it's empty"
        ls -la ..
        exit 1
      fi

      echo "Layer ZIP created successfully: $(du -h ../layer.zip)"
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
