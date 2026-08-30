# ADR-009: RDS Backup and Availability Strategy

Date: 2026-08-26
Status: Accepted (partially constrained by sandbox environment)

## Context

I needed to decide on the backup and availability configuration for the RDS MariaDB instance. The key choices were: whether to enable Multi-AZ for high availability, how many days of automated backups to keep, and whether to enable deletion protection.

The Vocareum sandbox explicitly prohibits creating a Multi-AZ standby instance.

## Decision

Multi-AZ is disabled (`multi_az = false`) as required by the sandbox. The DB subnet group still spans two Availability Zones so that enabling Multi-AZ in the future requires no infrastructure change.

Automated backups are enabled with a 7-day retention period and a backup window of 03:00-04:00 UTC. This provides Point-in-Time Recovery (PITR) for any moment within the last seven days.

Deletion protection is disabled for the sandbox environment to allow easy cleanup. `skip_final_snapshot` is set to `true` for the same reason.

## Why This Solution

Keeping backups for 7 days is a reasonable default that supports recovery from accidental data deletion or corruption for most use cases. It also means that a mistake made on a Monday can still be recovered from the following Sunday, which covers the typical work week without keeping data longer than necessary.

The subnet group spanning two AZs is a deliberate design choice even though only one AZ is used. When Multi-AZ is eventually enabled on a production account, AWS can immediately place the standby instance in the second subnet without requiring any subnet group changes. This avoids a future disruption.

## Consequences and Trade-offs

Without Multi-AZ, the RDS instance has no automatic failover. If the underlying hardware in us-east-1a fails, the database will be unavailable until AWS recovers it or I restore from a snapshot. For a production database, this is not acceptable, and Multi-AZ should always be enabled. For a sandbox demonstrating the architecture, this is a documented limitation.

Disabling deletion protection and skipping the final snapshot means the database can be destroyed with `terraform destroy` without any manual confirmation step. This is convenient for a lab but would be dangerous in production.
