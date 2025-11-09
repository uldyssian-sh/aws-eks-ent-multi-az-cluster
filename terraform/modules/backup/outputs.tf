output "backup_vault_arn" {
  description = "ARN of the backup vault"
  value       = try(aws_backup_vault.main.arn, null)
}

output "backup_plan_arn" {
  description = "ARN of the backup plan"
  value       = try(aws_backup_plan.main.arn, null)
}

output "backup_role_arn" {
  description = "ARN of the backup service role"
  value       = try(aws_iam_role.backup.arn, null)
}# Updated Sun Nov  9 12:52:18 CET 2025
# Updated Sun Nov  9 12:56:40 CET 2025
