resource "aws_backup_vault" "cross_region" {
  name        = "${var.cluster_name}-cross-region-vault"
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

resource "aws_backup_plan" "cross_region" {
  name = "${var.cluster_name}-cross-region-plan"

  rule {
    rule_name         = "cross_region_backup"
    target_vault_name = aws_backup_vault.cross_region.name
    schedule          = "cron(0 3 * * ? *)"

    copy_action {
      destination_vault_arn = "arn:aws:backup:${var.dr_region}:${data.aws_caller_identity.current.account_id}:backup-vault:${var.cluster_name}-dr-vault"
    }

    lifecycle {
      cold_storage_after = 30
      delete_after       = 365
    }
  }

  tags = var.tags
}

data "aws_caller_identity" "current" {}# Updated Sun Nov  9 12:52:18 CET 2025
# Updated Sun Nov  9 12:56:40 CET 2025
