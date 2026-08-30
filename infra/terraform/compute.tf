# ===========================================================================
# EC2 Instances — Bastion Host, Web Server, App Server
# Security: SSM Session Manager access (no port 22), IMDSv2 enforced, EBS encrypted
# ===========================================================================

# ---------------------------------------------------------------------------
# Bastion Host — accessed through SSM Session Manager only.
# No inbound ports are open on its Security Group.
# ---------------------------------------------------------------------------

resource "aws_instance" "bastion" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = var.lab_instance_profile  # Must include AmazonSSMManagedInstanceCore

  # IMDSv2 enforced — prevents SSRF attacks against the instance metadata endpoint.
  # Without this, a compromised application could read IAM credentials from the metadata API.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 only
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${local.name_prefix}-bastion"
    Role = "BastionHost"
  }
}

# ---------------------------------------------------------------------------
# Web Server — Apache and PHP, in the public subnet, reachable from the internet
# ---------------------------------------------------------------------------

resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = var.lab_instance_profile

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOT
    #!/bin/bash
    set -e
    yum update -y
    amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd

    # Basic landing page
    cat > /var/www/html/index.html << 'HTML'
    <!DOCTYPE html>
    <html>
    <head><title>3-Tier Architecture - Web Server</title></head>
    <body>
      <h1>Web Server is running</h1>
      <p>Project: ${local.name_prefix}</p>
      <p>Tier: Web (Public Subnet)</p>
    </body>
    </html>
    HTML

    # Health check endpoint for monitoring
    echo "OK" > /var/www/html/health.html
  EOT

  tags = {
    Name = "${local.name_prefix}-web-server"
    Role = "WebServer"
  }
}

# ---------------------------------------------------------------------------
# App Server — MariaDB client, in the private subnet.
# Accessible through SSM Session Manager only, no public IP.
# ---------------------------------------------------------------------------

resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_app.id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = var.lab_instance_profile

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOT
    #!/bin/bash
    set -e
    yum update -y
    # Install the MariaDB client only — the database engine runs on RDS, not on this instance
    yum install -y mariadb
  EOT

  tags = {
    Name = "${local.name_prefix}-app-server"
    Role = "AppServer"
  }

  # The App Server needs the NAT Gateway to be ready before it launches,
  # so that SSM can reach the instance through outbound HTTPS.
  depends_on = [aws_nat_gateway.main]
}
