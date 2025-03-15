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
  description = "Lambda function handler (e.g. index.handler)"
  type        = string
}

variable "runtime" {
  description = "Lambda function runtime"
  type        = string
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 900  # 15 minutes to match project standard
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "layers" {
  description = "List of Lambda layer ARNs to attach"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to attach to resources"
  type        = map(string)
  default     = {}
}

# SQS-specific variables
variable "project_name" {
  description = "Name of the project, used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "queue_suffix" {
  description = "Suffix to append to the queue name after {project_name}-{environment}-"
  type        = string
  default     = "processor"
}

variable "message_retention_seconds" {
  description = "Message retention period in seconds"
  type        = number
  default     = 1209600  # 14 days to match project standard
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout in seconds - should match or exceed Lambda timeout"
  type        = number
  default     = 900  # 15 minutes to match project standard
}

variable "batch_size" {
  description = "Maximum number of records to include in each batch. For media processing, keep this at 1 to process one thread at a time."
  type        = number
  default     = 1
}

variable "maximum_batching_window_in_seconds" {
  description = "Maximum amount of time to gather records before invoking the function"
  type        = number
  default     = 0
}

variable "enable_dlq" {
  description = "Enable a Dead Letter Queue for failed message processing"
  type        = bool
  default     = false
}

variable "dlq_retention_days" {
  description = "Number of days to retain messages in the Dead Letter Queue"
  type        = number
  default     = 14
}

variable "enable_queue_encryption" {
  description = "Enable server-side encryption for the SQS queue"
  type        = bool
  default     = true
}

variable "additional_queue_tags" {
  description = "Additional tags to attach to the SQS queue"
  type        = map(string)
  default     = {}
}

variable "reserved_concurrent_executions" {
  description = "Number of concurrent executions reserved for the Lambda function"
  type        = number
  default     = 5
}
