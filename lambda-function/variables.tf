variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix for the Lambda function name"
  type        = string
  default     = null
}

variable "source_dir" {
  description = "Directory containing Lambda function code. If provided, filename and source_code_hash will be generated automatically."
  type        = string
  default     = null
}

variable "filename" {
  description = "Path to the function's deployment package within the local filesystem. Required if source_dir is not provided."
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the package file. Required if source_dir is not provided."
  type        = string
  default     = null
}

variable "handler" {
  description = "Function entrypoint in your code"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "python3.9"
}

variable "timeout" {
  description = "Amount of time your Lambda Function has to run in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime"
  type        = number
  default     = 128
}

variable "managed_policies" {
  description = "List of managed policies to attach to the Lambda role"
  type        = list(string)
  default     = []
}

variable "layers" {
  description = "List of layers to attach to the Lambda function"
  type        = list(string)
  default     = []
}

variable "environment_variables" {
  description = "Map of environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "VPC configuration for the Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "manage_log_group" {
  description = "If true, create and manage the /aws/lambda/<name> log group. Set to false to let Lambda create it automatically."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to attach to resources"
  type        = map(string)
  default     = {}
}

variable "additional_policy_statements" {
  description = "List of additional IAM policy statements to attach to the Lambda role"
  type        = list(any)
  default     = []
}

variable "reserved_concurrent_executions" {
  description = "Number of concurrent executions reserved for the Lambda function"
  type        = number
  default     = 5
}

variable "architectures" {
  description = "Instruction set architecture for the Lambda function (x86_64 or arm64)"
  type        = list(string)
  default     = ["x86_64"]
  validation {
    condition = alltrue([
      for arch in var.architectures : contains(["x86_64", "arm64"], arch)
    ])
    error_message = "Architectures must be either 'x86_64' or 'arm64'."
  }
}

variable "tracing_mode" {
  description = "X-Ray tracing mode for the Lambda function. Valid values are 'Active' or 'PassThrough'. Set to null to disable."
  type        = string
  default     = null
  validation {
    condition     = var.tracing_mode == null || contains(["Active", "PassThrough"], var.tracing_mode)
    error_message = "tracing_mode must be 'Active', 'PassThrough', or null."
  }
}
