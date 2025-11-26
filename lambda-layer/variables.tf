variable "layer_name" {
  description = "Name of the Lambda layer"
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix for the layer name"
  type        = string
  default     = null
}

variable "requirements_content" {
  description = "Content of requirements.txt file for Python packages"
  type        = string
  default     = ""
}

variable "python_packages" {
  description = "List of Python packages to install (alternative to requirements_content)"
  type        = list(string)
  default     = []
}

variable "runtime" {
  description = "Lambda runtime for the layer"
  type        = string
  default     = "python3.11"
}

variable "architectures" {
  description = "Instruction set architecture for the layer (x86_64 or arm64)"
  type        = list(string)
  default     = ["x86_64"]
  validation {
    condition = alltrue([
      for arch in var.architectures : contains(["x86_64", "arm64"], arch)
    ])
    error_message = "Architectures must be either 'x86_64' or 'arm64'."
  }
}

variable "compatible_runtimes" {
  description = "Compatible Lambda runtimes for the layer"
  type        = list(string)
  default     = ["python3.11"]
}

variable "description" {
  description = "Description of the Lambda layer"
  type        = string
  default     = ""
}

variable "license_info" {
  description = "License info for the Lambda layer"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to attach to the layer"
  type        = map(string)
  default     = {}
}
