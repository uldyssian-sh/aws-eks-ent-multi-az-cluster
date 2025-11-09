resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.cluster_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "EKS CPU utilization high"
  alarm_actions       = var.enable_alerts ? [aws_sns_topic.alerts.arn] : []
  ok_actions          = var.enable_alerts ? [aws_sns_topic.alerts.arn] : []
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = var.tags
}# Updated Sun Nov  9 12:52:18 CET 2025
# Updated Sun Nov  9 12:56:40 CET 2025
