variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}# Updated Sun Nov  9 12:52:18 CET 2025
