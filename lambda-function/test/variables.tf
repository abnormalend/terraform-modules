variable "region" {
  description = "AWS region to deploy test"
  type        = string
  default     = "us-east-2"
}

variable "profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = ""
}
