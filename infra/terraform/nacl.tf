# ===========================================================================
# Network ACLs
# NACLs operate at the subnet level and are stateless, meaning every allowed
# flow requires explicit rules for both directions including return traffic
# on ephemeral ports (1024-65535). They work as a second, independent layer
# of network defense alongside Security Groups.
# ===========================================================================

# ---------------------------------------------------------------------------
# Public subnet NACL — Bastion Host and Web Server
# ---------------------------------------------------------------------------

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.public.id]

  # Inbound
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Ephemeral ports — required for return TCP traffic (NACLs are stateless)
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Application port toward the App Server subnet
  egress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.private_subnet_app_cidr
    from_port  = 8080
    to_port    = 8080
  }

  # Ephemeral ports for return traffic
  egress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "${local.name_prefix}-nacl-public"
  }
}

# ---------------------------------------------------------------------------
# Private app subnet NACL — App Server
# ---------------------------------------------------------------------------

resource "aws_network_acl" "private_app" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.private_app.id]

  # Inbound — application port from the public subnet only
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.public_subnet_cidr
    from_port  = 8080
    to_port    = 8080
  }

  # Ephemeral ports for return traffic from the internet through the NAT Gateway
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound — return traffic to the public subnet
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.public_subnet_cidr
    from_port  = 1024
    to_port    = 65535
  }

  # MySQL toward the database subnet
  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.private_subnet_db_a_cidr
    from_port  = 3306
    to_port    = 3306
  }

  # HTTPS through the NAT Gateway for SSM and system updates
  egress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  tags = {
    Name = "${local.name_prefix}-nacl-private-app"
  }
}

# ---------------------------------------------------------------------------
# Database subnet NACL — maximum isolation
# ---------------------------------------------------------------------------

resource "aws_network_acl" "private_db" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.private_db_a.id, aws_subnet.private_db_b.id]

  # Inbound — MySQL from the App Server subnet only
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.private_subnet_app_cidr
    from_port  = 3306
    to_port    = 3306
  }

  # Outbound — return traffic to the App Server subnet only
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.private_subnet_app_cidr
    from_port  = 1024
    to_port    = 65535
  }

  # All other traffic is blocked by the implicit DENY ALL at the end of every NACL.

  tags = {
    Name = "${local.name_prefix}-nacl-private-db"
  }
}
