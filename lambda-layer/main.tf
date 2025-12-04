locals {
  layer_name = var.name_prefix != null ? "${var.name_prefix}-${var.layer_name}" : var.layer_name

  # Determine requirements content
  requirements_content = var.requirements_content != "" ? var.requirements_content : join("\n", [for pkg in var.python_packages : "${pkg}"])

  # Create a unique ID for the layer to force recreation when requirements change
  layer_id = sha256(local.requirements_content)

  use_pip_build = length(trimspace(local.requirements_content)) > 0
  build_dir     = "${path.module}/.layer_build/${local.layer_id}"
}

# When using inline requirements/python_packages, materialize requirements.txt
resource "local_file" "requirements" {
  count    = local.use_pip_build ? 1 : 0
  filename = "${local.build_dir}/requirements.txt"
  content  = local.requirements_content
}

# Build site-packages into build_dir/python using pip
resource "null_resource" "pip_build" {
  count = local.use_pip_build ? 1 : 0
  triggers = {
    layer_id = local.layer_id
  }

  provisioner "local-exec" {
    working_dir = local.build_dir
    command     = "mkdir -p python && ${var.python_executable} -m pip install -r requirements.txt -t python --upgrade"
  }

  depends_on = [local_file.requirements]
}

# Archive from pip build
data "archive_file" "from_build" {
  count       = local.use_pip_build ? 1 : 0
  type        = "zip"
  source_dir  = local.build_dir
  output_path = "${path.module}/layer.zip"
  depends_on  = [null_resource.pip_build]
}

# Archive from provided source_dir (expects a python/ folder)
data "archive_file" "from_source" {
  count       = local.use_pip_build ? 0 : 1
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/layer.zip"
}

# Create the Lambda layer using the built ZIP
resource "aws_lambda_layer_version" "layer" {
  layer_name               = local.layer_name
  compatible_runtimes      = var.compatible_runtimes
  compatible_architectures = var.architectures
  filename                 = local.use_pip_build ? data.archive_file.from_build[0].output_path : data.archive_file.from_source[0].output_path
  source_code_hash         = local.use_pip_build ? data.archive_file.from_build[0].output_base64sha256 : data.archive_file.from_source[0].output_base64sha256

  description  = var.description != "" ? var.description : "Python dependencies layer"
  license_info = var.license_info
}
