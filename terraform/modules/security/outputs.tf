output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.eks.arn
}

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.eks.key_id
}

output "cluster_security_group_id" {
  description = "ID of the cluster security group"
  value       = aws_security_group.cluster.id
}

output "node_group_security_group_id" {
  description = "ID of the node group security group"
  value       = aws_security_group.node_group.id
}

output "additional_iam_policy_arn" {
  description = "ARN of the additional IAM policy"
  value       = aws_iam_policy.node_group_additional.arn
}# Updated 20251109_123803
