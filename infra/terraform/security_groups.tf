# ===========================================================================
# Security Groups
#
# Each Security Group is declared here without any inline ingress or egress
# rules. Rules are defined separately in security_group_rules.tf using
# aws_vpc_security_group_ingress_rule and aws_vpc_security_group_egress_rule.
#
# This separation avoids the circular dependency that occurs when Security
# Groups reference each other: web references app, app references db, and
# declaring inline rules in the same resource block creates a dependency
# cycle that Terraform cannot resolve.
# ===========================================================================

# Bastion Host — no inbound ports, SSM Session Manager only
resource "aws_security_group" "bastion" {
  name        = "${local.name_prefix}-sg-bastion"
  description = "Bastion Host - SSM Session Manager only, no inbound ports"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-sg-bastion"
  }
}

# Web Server — HTTP and HTTPS from the internet
resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-sg-web"
  description = "Web Server - HTTP and HTTPS from internet"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-sg-web"
  }
}

# App Server — inbound from the Web Server only
resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-sg-app"
  description = "App Server - inbound from Web Server only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-sg-app"
  }
}

# Database — inbound from the App Server only, no outbound traffic
resource "aws_security_group" "db" {
  name        = "${local.name_prefix}-sg-db"
  description = "RDS MariaDB - inbound from App Server only, no outbound"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-sg-db"
  }
}
