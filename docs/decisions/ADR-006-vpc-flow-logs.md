# ADR-006: VPC Flow Logs for Network Traffic Auditing

Date: 2026-08-26
Status: Accepted (disabled in sandbox, enabled on full-permission accounts)

## Context

Without any network logging, there is no way to detect whether unauthorized connection attempts are happening, which ports are being probed, or whether traffic patterns are unusual. This is a significant blind spot for a security-focused architecture.

## Decision

VPC Flow Logs are configured to capture ALL traffic (both ACCEPT and REJECT) and send it to a CloudWatch Log Group with a 30-day retention period. This feature is controlled by the `enable_flow_logs` variable, which is set to `false` by default to accommodate the Vocareum sandbox environment.

## Why This Solution

Flow Logs provide a complete record of every network connection attempt in the VPC: source IP, destination IP, port, protocol, and whether the connection was accepted or rejected by the security controls. This data is essential for:

- Detecting port scanning attempts against the infrastructure
- Identifying traffic that is being blocked by Security Groups or NACLs (REJECT entries)
- Investigating incidents after the fact
- Verifying that the network isolation between tiers is working as expected

A 30-day retention period was chosen as a balance between audit coverage and storage cost. CloudWatch Logs pricing is based on ingested data volume, so keeping logs indefinitely would become expensive for a production environment with significant traffic.

## Consequences and Trade-offs

In the Vocareum sandbox, creating a VPC Flow Log requires `iam:PassRole` on the LabRole, which the sandbox IAM policy does not allow. The feature is therefore disabled by default via a feature flag. Setting `enable_flow_logs = true` in `terraform.tfvars` on a full-permission AWS account will activate it without any code changes.

The 30-day retention period means that events older than 30 days are not available for investigation. In a real production environment, a longer retention period or an export to S3 with lifecycle archiving to Glacier would be more appropriate for compliance use cases.
