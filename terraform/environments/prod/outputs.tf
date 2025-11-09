output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = try(module.eks.cluster_id, null)
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = try(module.eks.cluster_endpoint, null)
}

output "cluster_security_group_id" {
  description = "Security group id attached to the cluster control plane"
  value       = try(module.eks.cluster_security_group_id, null)
}# Updated Sun Nov  9 12:52:18 CET 2025
# Updated Sun Nov  9 12:56:40 CET 2025
