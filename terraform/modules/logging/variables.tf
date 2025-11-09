variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be one of the valid CloudWatch Logs retention periods."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN"
  type        = string
  validation {
    condition     = can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:(key/[a-fA-F0-9-]+|alias/.+)$", var.kms_key_arn))
    error_message = "KMS key ARN must be a valid AWS KMS key ARN format."
  }
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}# Updated Sun Nov  9 12:52:18 CET 2025
