output "spot_fleet_id" {
  description = "ID of the spot fleet request"
  value       = try(aws_spot_fleet_request.main.id, null)
}

output "autoscaling_group_arn" {
  description = "ARN of the autoscaling group"
  value       = try(aws_autoscaling_group.spot_nodes.arn, null)
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = try(aws_launch_template.spot_nodes.id, null)
}# Updated Sun Nov  9 12:52:18 CET 2025
# Updated Sun Nov  9 12:56:40 CET 2025
