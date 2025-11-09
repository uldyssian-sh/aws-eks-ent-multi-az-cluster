resource "aws_backup_vault" "eks" {
  name        = "${var.cluster_name}-backup-vault"
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

resource "aws_backup_plan" "eks" {
  name = "${var.cluster_name}-backup-plan"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.eks.name
    schedule          = "cron(0 2 * * ? *)"

    lifecycle {
      cold_storage_after = 30
      delete_after       = 365
    }

    recovery_point_tags = var.tags
  }

  tags = var.tags
}# Updated Sun Nov  9 12:52:18 CET 2025
