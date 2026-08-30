# AWS 3-Tier Architecture with Security-by-Design

**Yvan Raffi** | AWS Certified Solutions Architect Associate | Cloud Security

This project deploys a 3-tier web application infrastructure on AWS. I built it to demonstrate how to apply security controls at every layer of an architecture, not just at the perimeter.

The three tiers are isolated from each other at the network level. Each one can only communicate with the tier directly adjacent to it, using the minimum set of ports required. The database has no internet access at all.

---

## Architecture

![Architecture Diagram](docs/architecture/architecture.png)

```
Internet
    |
    v
[Internet Gateway]
    |
    v
Public Subnet (10.0.1.0/24, AZ us-east-1a)
    |-- Bastion Host (SSM access only, no open ports)
    |-- Web Server  (Apache/PHP, ports 80 and 443)
    |
    v  port 8080 only
Private Subnet (10.0.2.0/24, AZ us-east-1a)
    |-- App Server (MariaDB client, SSM access only)
    |
    v  port 3306 only
Private Subnet (10.0.3.0/24 + 10.0.4.0/24, AZ us-east-1a and us-east-1b)
    |-- RDS MariaDB (encrypted, no public access, no internet route)
```

---

## Security Controls

| Layer | Control | What it does |
|-------|---------|--------------|
| Network | VPC with 4 subnets | Separates each tier into its own network segment |
| Network | Security Groups (SG to SG rules) | Only allows the exact ports between adjacent tiers |
| Network | Network ACLs | Second, independent layer of subnet-level filtering |
| Network | Route tables | Database subnet has no internet route at all |
| Network | VPC Flow Logs | Captures all accepted and rejected traffic (full-permission account) |
| Access | SSM Session Manager | No SSH, no open port 22, full session audit trail |
| Access | IMDSv2 enforced | Prevents SSRF attacks against the metadata endpoint |
| Data | EBS encryption | All instance root volumes encrypted at rest |
| Data | RDS encryption | Database storage encrypted using AWS-managed KMS key |
| Secrets | AWS Secrets Manager | RDS password never written in code or committed to Git |

---

## Repository Structure

```
aws-3tier-architecture/
├── infra/
│   ├── terraform/       Terraform code for automated deployment
│   └── console/         Step-by-step console guide with screenshot list
├── docs/
│   ├── architecture/    Architecture diagrams
│   ├── decisions/       Architecture Decision Records (ADR-001 to ADR-010)
│   └── lessons-learned.md
└── README.md
```

---

## Deploying with Terraform

### Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured
- SSM Plugin for AWS CLI ([installation guide](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html))

### 1. Set your AWS credentials

```bash
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
export AWS_DEFAULT_REGION="us-east-1"
```

### 2. Initialize and deploy

```bash
cd infra/terraform
terraform init
terraform plan
terraform apply
```

Deployment takes around 12 to 15 minutes. RDS is the slowest resource to provision.

### 3. Test the deployment

After `terraform apply` finishes, the outputs give you all the commands you need:

```bash
# Check that the web server is responding
curl http://<web_server_public_ip>/health.html

# Connect to the Bastion Host (no SSH key needed)
aws ssm start-session --target <bastion_instance_id> --region us-east-1

# Connect to the App Server
aws ssm start-session --target <app_instance_id> --region us-east-1

# Get the RDS password
terraform output -raw db_password
```

### 4. Clean up

```bash
terraform destroy
```

The NAT Gateway is the most expensive resource (~$0.045 per hour). Always destroy after finishing a lab session.

---

## Feature Flags

Two features are disabled by default because they require IAM permissions that are not available in all environments. They are fully implemented in the code and can be enabled by editing `infra/terraform/terraform.tfvars`.

| Flag | Default | What it enables |
|------|---------|-----------------|
| `enable_secrets_manager` | false | Store the RDS password in AWS Secrets Manager |
| `enable_flow_logs` | false | Send VPC network logs to CloudWatch |

---

## Console Deployment

A full step-by-step guide for deploying the same architecture through the AWS Management Console is available in [`infra/console/console-guide.md`](infra/console/console-guide.md). It includes a precise list of screenshots to capture at each step.

---

## Architecture Decisions

The `docs/decisions/` folder contains 10 Architecture Decision Records explaining the reasoning behind every significant choice in this project.

| ADR | Decision |
|-----|----------|
| [ADR-001](docs/decisions/ADR-001-network-architecture.md) | Four-subnet layout across two AZs |
| [ADR-002](docs/decisions/ADR-002-database-network-isolation.md) | Complete network isolation for the database tier |
| [ADR-003](docs/decisions/ADR-003-ssm-session-manager.md) | SSM Session Manager instead of SSH |
| [ADR-004](docs/decisions/ADR-004-secrets-and-encryption.md) | Secret management and encryption strategy |
| [ADR-005](docs/decisions/ADR-005-nacls-as-second-defense-layer.md) | NACLs as a second layer of network defense |
| [ADR-006](docs/decisions/ADR-006-vpc-flow-logs.md) | VPC Flow Logs for network traffic auditing |
| [ADR-007](docs/decisions/ADR-007-imdsv2-enforcement.md) | IMDSv2 enforcement on all EC2 instances |
| [ADR-008](docs/decisions/ADR-008-terraform-code-organization.md) | Terraform code organization and environment constraints |
| [ADR-009](docs/decisions/ADR-009-rds-backup-availability.md) | RDS backup and availability strategy |
| [ADR-010](docs/decisions/ADR-010-monitoring-alerting.md) | Monitoring and alerting strategy |

---

## Lessons Learned

Six real problems I ran into while building and testing this project, and what I learned from each one.

See [`docs/lessons-learned.md`](docs/lessons-learned.md).

---

## Validation Results

| Test | Expected | Result |
|------|----------|--------|
| Web Server responds on port 80 | HTTP 200 from curl | Passed |
| Bastion accessible via SSM, no SSH | Session opens without key pair | Passed |
| App Server accessible via SSM only | Session opens, no public IP | Passed |
| App Server connects to RDS | mysql prompt appears | Passed |
| Bastion cannot reach RDS port 3306 | Connection timed out | Passed |
| IMDSv2 rejects requests without token | Empty response on plain GET | Passed |
| IMDSv2 works correctly with token | Instance ID returned | Passed |

---

## Author

Yvan Raffi
AWS Certified Cloud Practitioner | AWS Certified Solutions Architect Associate
Cameroon | Cloud Security | DevSecOps
