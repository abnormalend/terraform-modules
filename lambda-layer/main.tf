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

# Create shell script for layer creation
resource "local_file" "create_layer_script" {
  content = <<-EOF
    #!/bin/bash
    set -e
    set -x

    echo "Starting layer creation script..."
    echo "Current directory: $(pwd)"
    echo "PATH: $PATH"
    echo "Python version: $(python3 --version 2>&1)"
    echo "Pip version: $(pip3 --version 2>&1)"

    # Clean up
    rm -rf python
    mkdir -p python

    echo "Installing requests..."
    pip3 install requests --target python --quiet --no-cache-dir

    echo "Verifying installation..."
    ls -la python/

    # Create ZIP
    cd python && zip -r ../layer.zip . -q

    echo "Verifying ZIP..."
    ls -la ../layer.zip

    echo "Layer created successfully"
  EOF

  filename = "${path.module}/create_layer.sh"
}

# Create initial dummy ZIP file
resource "local_file" "layer_zip" {
  content  = "dummy"
  filename = "${path.module}/layer.zip"
}

# Execute the layer creation script
resource "null_resource" "create_layer" {
  triggers = {
    requirements_hash = local.layer_id
    architectures     = join(",", var.architectures)
  }

  provisioner "local-exec" {
    working_dir = "${path.module}"
    command     = "chmod +x create_layer.sh && ./create_layer.sh"
  }

  depends_on = [local_file.requirements_txt, local_file.create_layer_script, local_file.layer_zip]
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
