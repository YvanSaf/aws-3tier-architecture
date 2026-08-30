# ADR-008: Terraform Code Organization and Sandbox Constraints

Date: 2026-08-26
Status: Accepted

## Context

When using Terraform, there are two common approaches to code organization: a flat structure where all resources are defined in a single directory with multiple files, or a modular structure where reusable components are extracted into separate modules. I also needed to decide how to handle the Terraform backend (where the state is stored) and how to structure the project repository.

Additionally, the Vocareum sandbox environment imposes constraints that differ from a production AWS account: temporary credentials that expire every four hours, no ability to create IAM roles, and restrictions on some services.

## Decision

The Terraform code uses a flat structure with one file per layer of the architecture: `vpc.tf`, `security_groups.tf`, `security_group_rules.tf`, `nacl.tf`, `compute.tf`, `database.tf`, `secrets.tf`, `monitoring.tf`. There are no separate modules.

The backend is configured as local (`backend "local" {}`), meaning the state file stays on the machine running Terraform.

Two feature flags (`enable_secrets_manager` and `enable_flow_logs`) control resources that are not supported in the Vocareum sandbox, so the same codebase can be deployed in both environments without modification.

## Why This Solution

Modules are most useful when the same infrastructure pattern is reused across multiple projects or environments. For a single project at this stage, modules would add indirection without a clear benefit. The flat structure is easier to read and understand for anyone reviewing the code, and each file maps directly to a recognizable architectural layer.

A local backend is the right choice for a sandbox environment where the session expires frequently. A remote backend using S3 and DynamoDB would be better for a team or production setup, but it would require creating S3 buckets and DynamoDB tables that also get wiped when the Vocareum session ends.

The feature flags approach keeps the code honest: the Secrets Manager and Flow Logs code is fully written and tested, just disabled. The comments explain exactly why each flag exists and what to change to enable the feature on a real account. This is more informative for a portfolio than simply removing the code.

## Consequences and Trade-offs

The local backend means the Terraform state file is tied to a single machine. If the machine is lost or the file is deleted, Terraform loses track of what it deployed. For a sandbox this is acceptable. For production, the state must be stored remotely with locking to prevent concurrent modifications.

The flat file structure becomes harder to navigate as the project grows. If this architecture were extended to support multiple environments or multiple regions, extracting modules would become necessary.
