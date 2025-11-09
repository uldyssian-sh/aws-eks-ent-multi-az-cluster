variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "node_role_arn" {
  description = "Node group IAM role ARN"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "spot_desired_size" {
  description = "Desired number of spot instances"
  type        = number
  default     = 2
}

variable "spot_max_size" {
  description = "Maximum number of spot instances"
  type        = number
  default     = 10
}

variable "spot_min_size" {
  description = "Minimum number of spot instances"
  type        = number
  default     = 1
  
  validation {
    condition     = var.spot_min_size <= var.spot_desired_size && var.spot_desired_size <= var.spot_max_size
    error_message = "spot_min_size must be <= spot_desired_size <= spot_max_size."
  }
}

variable "max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during updates"
  type        = number
  default     = 25
  validation {
    condition     = var.max_unavailable_percentage >= 1 && var.max_unavailable_percentage <= 100
    error_message = "Max unavailable percentage must be between 1 and 100."
  }
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}# Updated Sun Nov  9 12:52:18 CET 2025
# Updated Sun Nov  9 12:56:40 CET 2025
