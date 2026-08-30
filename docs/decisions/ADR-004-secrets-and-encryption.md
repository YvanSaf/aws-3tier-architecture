# ADR-004: Secret Management and Encryption Strategy

Date: 2026-08-26
Status: Accepted (partially constrained by sandbox environment)

## Context

Every database deployment requires a password. The simplest approach is to write the password directly in the code or in a configuration file. This is also one of the most common causes of credential leaks, since configuration files often end up committed to Git repositories.

I also needed to decide how to handle encryption for RDS storage and EC2 EBS volumes.

## Decision

The RDS password is generated using Terraform's `random_password` resource (20 characters, mixed case, numbers, and special characters). It is never written by hand anywhere in the codebase.

When running on a full-permission AWS account, the password is stored in AWS Secrets Manager using a dedicated secret (`yvan-3tier-dev/rds/credentials`). The feature is controlled by the `enable_secrets_manager` variable and is disabled by default for the Vocareum sandbox environment (see Consequences below).

For encryption at rest, all RDS storage uses the AWS-managed KMS key (`aws/rds`). All EC2 EBS root volumes are encrypted using the same mechanism. No data is stored unencrypted on disk.

## Why This Solution

Generating the password with `random_password` means it never appears in source code, commit history, or any human-readable configuration file. Even with Secrets Manager disabled, the password only exists in the Terraform state file, which is excluded from Git via `.gitignore`.

AWS Secrets Manager adds a second layer: the password is stored in an encrypted, access-controlled vault, and any read access to it is logged in CloudWatch via CloudTrail. This makes it auditable and rotatable without touching any code.

AWS-managed KMS keys (`aws/rds`, `aws/ebs`) are used instead of customer-managed keys because the Vocareum sandbox restricts KMS to read-only access. On a production account, customer-managed keys (CMKs) would be the right choice, as they allow fine-grained key policies and explicit rotation control.

## Consequences and Trade-offs

In the Vocareum sandbox, `secretsmanager:CreateSecret` is blocked by IAM policy. Secrets Manager is therefore disabled by default (`enable_secrets_manager = false`). The password can still be retrieved using `terraform output -raw db_password`, which reads from the Terraform state. This is a sandbox-only fallback. On a real AWS account, Secrets Manager should always be enabled.

The use of AWS-managed KMS keys instead of CMKs means slightly less control over key rotation and access policies. This is an acceptable trade-off for a sandbox environment, but not for production.
