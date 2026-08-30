# ===========================================================================
# Monitoring and Alerting — CloudWatch and SNS
# ===========================================================================

# Single SNS topic for all CloudWatch alarms
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"

  tags = {
    Name = "${local.name_prefix}-alerts"
  }
}

# Optional email subscription — leave alert_email empty to disable
resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ---------------------------------------------------------------------------
# EC2 Alarms
# ---------------------------------------------------------------------------

# Web Server CPU above 80% for two consecutive 5-minute periods
resource "aws_cloudwatch_metric_alarm" "web_cpu_high" {
  alarm_name          = "${local.name_prefix}-web-cpu-high"
  alarm_description   = "Web Server CPU above 80% - check load or potential DDoS"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.web.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${local.name_prefix}-web-cpu-alarm"
  }
}

# App Server CPU above 80% for two consecutive 5-minute periods
resource "aws_cloudwatch_metric_alarm" "app_cpu_high" {
  alarm_name          = "${local.name_prefix}-app-cpu-high"
  alarm_description   = "App Server CPU above 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.app.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${local.name_prefix}-app-cpu-alarm"
  }
}

# ---------------------------------------------------------------------------
# RDS Alarms
# ---------------------------------------------------------------------------

# Database connection count above 50 — possible connection pool leak or unusual activity
resource "aws_cloudwatch_metric_alarm" "db_connections_high" {
  alarm_name          = "${local.name_prefix}-db-connections-high"
  alarm_description   = "RDS connection count above 50 - check the application for connection leaks"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${local.name_prefix}-db-connections-alarm"
  }
}

# Free storage below 20% of allocated size
resource "aws_cloudwatch_metric_alarm" "db_storage_low" {
  alarm_name          = "${local.name_prefix}-db-storage-low"
  alarm_description   = "RDS free storage below 20% - take action before the database runs out of space"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.db_allocated_storage * 1024 * 1024 * 1024 * 0.20  # 20% in bytes
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${local.name_prefix}-db-storage-alarm"
  }
}

# ---------------------------------------------------------------------------
# CloudWatch Dashboard — consolidated view of all metrics
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "CPU Utilization - EC2 Instances"
          region = var.aws_region
          period = 300
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web.id, { label = "Web Server" }],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.app.id, { label = "App Server" }],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.bastion.id, { label = "Bastion" }]
          ]
          view    = "timeSeries"
          stacked = false
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "RDS - Connections and CPU"
          region = var.aws_region
          period = 300
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.main.id, { label = "DB Connections" }],
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.main.id, { label = "RDS CPU" }]
          ]
          view    = "timeSeries"
          stacked = false
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 6
        width  = 24
        height = 4
        properties = {
          title = "Alarm Status"
          alarms = [
            aws_cloudwatch_metric_alarm.web_cpu_high.arn,
            aws_cloudwatch_metric_alarm.app_cpu_high.arn,
            aws_cloudwatch_metric_alarm.db_connections_high.arn,
            aws_cloudwatch_metric_alarm.db_storage_low.arn
          ]
        }
      }
    ]
  })
}
