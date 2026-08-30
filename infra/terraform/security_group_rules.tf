# ===========================================================================
# Security Group Rules
# Declared separately from the Security Group resources to avoid circular
# dependency errors when groups reference each other.
# ===========================================================================

# ---------------------------------------------------------------------------
# Bastion Host — outbound HTTPS only (required for SSM Session Manager)
# ---------------------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "bastion_https" {
  security_group_id = aws_security_group.bastion.id
  description       = "HTTPS to SSM endpoints and system update servers"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# ---------------------------------------------------------------------------
# Web Server — inbound from internet, outbound to App Server and SSM
# ---------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP from internet (redirected to HTTPS by the application)"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "web_https" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS from internet"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "web_to_app" {
  security_group_id            = aws_security_group.web.id
  description                  = "Application traffic to the App Server"
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_egress_rule" "web_https_out" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS to SSM endpoints and system update servers"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# ---------------------------------------------------------------------------
# App Server — inbound from Web Server, outbound to Database and SSM
# ---------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "app_from_web" {
  security_group_id            = aws_security_group.app.id
  description                  = "Application traffic from the Web Server only"
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.web.id
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  description                  = "MySQL to RDS from the App Server only"
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_vpc_security_group_egress_rule" "app_https_out" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS for SSM Session Manager through the NAT Gateway"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# ---------------------------------------------------------------------------
# Database — inbound from App Server only, no outbound
#
# AWS adds a default allow-all outbound rule to every Security Group.
# Terraform does not remove that default rule on its own unless it is managed
# explicitly. To guarantee full outbound isolation, we declare a single egress
# rule restricted to the loopback address (127.0.0.1/32), which effectively
# allows no real outbound traffic while overriding the default.
# ---------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "MySQL from the App Server only"
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_egress_rule" "db_deny_all" {
  security_group_id = aws_security_group.db.id
  description       = "No outbound traffic - database is fully isolated"
  ip_protocol       = "-1"
  cidr_ipv4         = "127.0.0.1/32"
}
