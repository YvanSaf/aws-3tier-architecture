# Screenshots

This folder contains all screenshots taken during the console deployment of the 3-tier architecture.
They are referenced in the console deployment guide at `infra/console/console-guide.md`.

## Naming Convention

Files follow the pattern: `stepNN-description.png`
where `NN` is the step number from the console guide.

## Screenshot List

| File | Step | What it shows |
|------|------|---------------|
| `step01-vpc-form.png` | 1 | Create VPC form filled in before clicking create |
| `step01-vpc-details.png` | 1 | VPC details page after creation (VPC ID and CIDR visible) |
| `step02-subnets-list.png` | 2 | Subnet list showing all four subnets with CIDRs and AZs |
| `step02-public-subnet-auto-assign.png` | 2 | Edit subnet settings with Auto-assign public IPv4 enabled |
| `step03-igw-attached.png` | 3 | Internet Gateway details showing State: Attached and the VPC ID |
| `step04-nat-available.png` | 4 | NAT Gateway details showing State: Available, subnet, and Elastic IP |
| `step05-rt-public-routes.png` | 5 | Public route table showing 0.0.0.0/0 route via Internet Gateway |
| `step05-rt-app-routes.png` | 5 | Private app route table showing 0.0.0.0/0 route via NAT Gateway |
| `step05-rt-db-routes.png` | 5 | Database route table showing only the local route, no internet route |
| `step06-sg-bastion-inbound.png` | 6 | Bastion SG inbound rules tab showing no rules |
| `step06-sg-web-inbound.png` | 6 | Web Server SG inbound rules showing ports 80 and 443 |
| `step06-sg-app-inbound.png` | 6 | App Server SG inbound rules showing port 8080 from the Web SG |
| `step06-sg-db-inbound.png` | 6 | Database SG inbound rules showing port 3306 from the App SG only |
| `step06-sg-db-outbound.png` | 6 | Database SG outbound rules tab showing no rules |
| `step07-bastion-launch-summary.png` | 7 | Bastion launch summary (VPC, subnet, SG, IAM profile visible) |
| `step08-web-server-running.png` | 8 | Web Server instance running with its public IP address |
| `step08-web-server-health-check.png` | 8 | health.html returning OK in the browser or terminal |
| `step09-app-server-details.png` | 9 | App Server instance details (private subnet, no public IP) |
| `step10-db-subnet-group.png` | 10 | DB subnet group showing both subnets and their AZs |
| `step12-web-server-curl.png` | 12 | Terminal showing the curl command and the OK response |
| `step13-ssm-bastion-session.png` | 13 | SSM session open showing the Bastion shell prompt |
| `step14-app-mysql-connected.png` | 14 | App Server SSM session showing successful mysql connection |
