resource "aws_eks_node_group" "spot" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-spot-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  instance_types  = ["t3.medium", "t3a.medium", "m5.large"]
  capacity_type   = "SPOT"

  scaling_config {
    desired_size = var.spot_desired_size
    max_size     = var.spot_max_size
    min_size     = var.spot_min_size
  }

  update_config {
    max_unavailable_percentage = var.max_unavailable_percentage
  }

  tags = var.tags
}# Updated Sun Nov  9 12:52:18 CET 2025
