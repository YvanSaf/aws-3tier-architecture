# ADR-010: Monitoring and Alerting Strategy

Date: 2026-08-26
Status: Accepted

## Context

I needed to decide what to monitor, what thresholds to alert on, and how to deliver those alerts. The options ranged from no monitoring at all to a full observability stack with third-party tools. For this architecture, I focused on the built-in AWS monitoring tools: CloudWatch Metrics, CloudWatch Alarms, SNS, and the CloudWatch Dashboard.

## Decision

Four CloudWatch alarms are configured:

- CPU utilization on the Web Server above 80% for two consecutive 5-minute periods
- CPU utilization on the App Server above 80% for two consecutive 5-minute periods
- Database connection count above 50 for two consecutive 5-minute periods
- Free storage space on RDS below 20% of total allocated storage

All alarms publish to a single SNS topic. An optional email subscription can be added by setting the `alert_email` variable. A CloudWatch Dashboard consolidates all metrics in one view.

## Why This Solution

The two evaluation periods (10 minutes total before an alarm fires) reduce false positives from short CPU spikes that resolve on their own. A single sustained burst should not wake someone up at night.

The database connection count alarm is specifically relevant for this architecture because the App Server connects to RDS directly. If a connection pool is misconfigured or leaking connections, the count will grow steadily. Catching this early prevents the database from running out of available connections.

The 20% free storage threshold gives enough lead time to take action (increasing storage or cleaning up data) before the database runs out of space and starts refusing writes.

A single SNS topic for all alarms keeps the alerting infrastructure simple. In a larger system with multiple teams, separate topics per component or severity level would make more sense.

## Consequences and Trade-offs

The 80% CPU threshold is a starting point, not a universal rule. Some workloads run at high CPU normally. If the application is CPU-intensive by design, this threshold will generate constant noise. The right value depends on the actual workload and should be adjusted after observing real traffic patterns.

CloudWatch Dashboard costs nothing to view but does count API calls when loading the metrics. For a lab environment this is negligible. For a high-traffic production system with many metrics, dashboard refresh frequency might contribute to CloudWatch API costs.
