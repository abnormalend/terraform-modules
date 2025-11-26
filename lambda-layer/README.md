# AWS Lambda Layer Terraform Module

This Terraform module creates a fully managed AWS Lambda layer with Python dependencies. It automatically handles package installation, ZIP creation, and layer versioning.

## Features

- Automatic Python package installation from requirements.txt or package list
- Support for ARM64 and x86_64 architectures
- Automatic layer versioning based on package changes
- Compatible with multiple Lambda runtimes
- Resource tagging support

## Usage

### Using requirements.txt content

```hcl
module "python_layer" {
  source = "./lambda-layer"

  layer_name = "python-deps"

  requirements_content = <<-EOT
    requests==2.31.0
    beautifulsoup4==4.12.2
    ebooklib==0.18
  EOT

  compatible_runtimes = ["python3.11"]
  architectures       = ["arm64"]

  description = "Python dependencies for EPUB processing"
}
```

### Using package list

```hcl
module "python_layer" {
  source = "./lambda-layer"

  layer_name = "python-deps"

  python_packages = [
    "requests",
    "beautifulsoup4",
    "ebooklib"
  ]

  compatible_runtimes = ["python3.11"]
  architectures       = ["arm64"]

  tags = {
    Environment = "production"
    Purpose     = "epub-processing"
  }
}
```

### Using with Lambda function

```hcl
module "lambda_function" {
  source = "./lambda-function"

  function_name = "my-function"
  # ... other function config

  layers = [module.python_layer.layer_arn]
}
```

## Requirements

- AWS provider
- Terraform >= 0.13
- Python 3.x with pip (for local package installation)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| layer_name | Name of the Lambda layer | string | - | yes |
| name_prefix | Optional prefix for the layer name | string | null | no |
| requirements_content | Content of requirements.txt file | string | "" | no* |
| python_packages | List of Python packages to install | list(string) | [] | no* |
| runtime | Lambda runtime (for compatibility) | string | python3.11 | no |
| architectures | Architecture for the layer | list(string) | ["x86_64"] | no |
| compatible_runtimes | Compatible Lambda runtimes | list(string) | ["python3.11"] | no |
| description | Description of the layer | string | "" | no |
| license_info | License info for the layer | string | "" | no |
| tags | Tags to attach to resources | map(string) | {} | no |

*Either `requirements_content` or `python_packages` must be provided.

## Outputs

| Name | Description |
|------|-------------|
| layer_arn | ARN of the Lambda layer |
| layer_version_arn | ARN of the specific layer version |
| version | Version number of the layer |
| created_date | Date the layer was created |
| layer_name | Name of the Lambda layer |

## How it Works

1. **Package Installation**: The module creates a local `requirements.txt` file and installs packages to a `python/` directory using pip
2. **ZIP Creation**: Packages are archived into a ZIP file compatible with Lambda layers
3. **Layer Creation**: The ZIP is uploaded to AWS as a Lambda layer with specified architectures and runtimes
4. **Versioning**: Changes to packages automatically create new layer versions

## Architecture Support

The module supports both x86_64 and ARM64 architectures:

```hcl
architectures = ["arm64"]        # ARM64 only
architectures = ["x86_64"]       # x86_64 only
architectures = ["x86_64", "arm64"]  # Both architectures
```

## Best Practices

- Use specific package versions in requirements to ensure reproducible builds
- Test layers with your Lambda functions before deploying to production
- Use descriptive layer names and descriptions
- Leverage tags for organization and cost tracking

## Troubleshooting

**Layer creation fails**: Ensure Python and pip are installed locally and packages are compatible with Lambda runtime.

**Import errors**: Verify package names and versions in requirements match what your Lambda function expects.

**Architecture mismatch**: Ensure the layer architecture matches your Lambda function's architecture.
