# ===========================================================================
# VPC and Networking
# ===========================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# ---------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------

# Public subnet — Bastion Host and Web Server
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet"
    Tier = "Public"
  }
}

# Private subnet — App Server
resource "aws_subnet" "private_app" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_app_cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name_prefix}-private-app-subnet"
    Tier = "Private-App"
  }
}

# Private subnet — RDS primary instance (AZ-a)
resource "aws_subnet" "private_db_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_db_a_cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name_prefix}-private-db-subnet-a"
    Tier = "Private-DB"
  }
}

# Private subnet — RDS subnet group secondary slot (AZ-b)
# AWS RDS requires a subnet group with at least two AZs even for single-AZ deployments.
resource "aws_subnet" "private_db_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_db_b_cidr
  availability_zone       = var.az_b
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name_prefix}-private-db-subnet-b"
    Tier = "Private-DB"
  }
}

# ---------------------------------------------------------------------------
# Internet Gateway — outbound and inbound internet access for the public subnet
# ---------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# ---------------------------------------------------------------------------
# NAT Gateway — allows private subnet instances to reach the internet outbound.
# SSM Session Manager requires outbound HTTPS from the private app subnet.
# ---------------------------------------------------------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id  # NAT Gateway always lives in the public subnet

  tags = {
    Name = "${local.name_prefix}-nat-gw"
  }

  depends_on = [aws_internet_gateway.main]
}

# ---------------------------------------------------------------------------
# Route Tables
# ---------------------------------------------------------------------------

# Public route table — internet traffic goes through the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Private app route table — outbound internet goes through the NAT Gateway (for SSM and updates)
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-private-app-rt"
  }
}

resource "aws_route_table_association" "private_app" {
  subnet_id      = aws_subnet.private_app.id
  route_table_id = aws_route_table.private_app.id
}

# Database route table — no internet route at all.
# Security decision: the database has no outbound internet access, not even through NAT.
# A managed database engine has no reason to initiate outbound connections.
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  # No 0.0.0.0/0 route — full network isolation for the database tier

  tags = {
    Name = "${local.name_prefix}-private-db-rt"
  }
}

resource "aws_route_table_association" "private_db_a" {
  subnet_id      = aws_subnet.private_db_a.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_route_table_association" "private_db_b" {
  subnet_id      = aws_subnet.private_db_b.id
  route_table_id = aws_route_table.private_db.id
}

# ---------------------------------------------------------------------------
# VPC Flow Logs — captures all accepted and rejected network traffic.
# Useful for detecting port scans, unauthorized connection attempts,
# and verifying that inter-tier isolation is working correctly.
#
# Disabled by default because writing Flow Logs to CloudWatch requires
# iam:PassRole, which is not available in all environments.
# Set enable_flow_logs = true in terraform.tfvars to activate this feature.
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/vpc/${local.name_prefix}/flow-logs"
  retention_in_days = 30

  tags = {
    Name = "${local.name_prefix}-vpc-flow-logs"
  }
}

data "aws_iam_role" "lab_role" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "LabRole"
}

resource "aws_flow_log" "main" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = data.aws_iam_role.lab_role[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs[0].arn

  tags = {
    Name = "${local.name_prefix}-flow-log"
  }
}
