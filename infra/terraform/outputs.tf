# ===========================================================================
# Outputs — useful information after terraform apply
# ===========================================================================

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}

# ---------------------------------------------------------------------------
# EC2
# ---------------------------------------------------------------------------

output "bastion_instance_id" {
  description = "Bastion Host instance ID — use this with aws ssm start-session"
  value       = aws_instance.bastion.id
}

output "web_server_public_ip" {
  description = "Web Server public IP — open http://<ip> to verify the server is running"
  value       = aws_instance.web.public_ip
}

output "web_server_public_dns" {
  description = "Web Server public DNS name"
  value       = aws_instance.web.public_dns
}

output "app_server_private_ip" {
  description = "App Server private IP address"
  value       = aws_instance.app.private_ip
}

output "app_instance_id" {
  description = "App Server instance ID — use this with aws ssm start-session"
  value       = aws_instance.app.id
}

# ---------------------------------------------------------------------------
# RDS
# ---------------------------------------------------------------------------

output "rds_endpoint" {
  description = "RDS MariaDB endpoint — use this to connect from the App Server"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "RDS MariaDB port"
  value       = aws_db_instance.main.port
}

# ---------------------------------------------------------------------------
# Secrets
# ---------------------------------------------------------------------------

output "db_secret_arn" {
  description = "Secrets Manager secret ARN (empty if enable_secrets_manager is false)"
  value       = var.enable_secrets_manager ? aws_secretsmanager_secret.db_credentials[0].arn : "Secrets Manager is disabled — use terraform output -raw db_password instead"
}

output "db_secret_name" {
  description = "Secrets Manager secret name (empty if enable_secrets_manager is false)"
  value       = var.enable_secrets_manager ? aws_secretsmanager_secret.db_credentials[0].name : "Secrets Manager is disabled — use terraform output -raw db_password instead"
}

# Fallback for restricted environments where Secrets Manager is not available.
# The value is marked sensitive so it never appears in plain text in logs.
# Retrieve it with: terraform output -raw db_password
output "db_password" {
  description = "Generated RDS password (sensitive — retrieve with: terraform output -raw db_password)"
  value       = random_password.db_password.result
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Useful commands — printed after terraform apply
# ---------------------------------------------------------------------------

output "ssm_connect_bastion" {
  description = "Command to connect to the Bastion Host via SSM Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.bastion.id} --region ${var.aws_region}"
}

output "ssm_connect_app" {
  description = "Command to connect to the App Server via SSM Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.app.id} --region ${var.aws_region}"
}

output "test_web_server" {
  description = "Command to test that the Web Server is responding"
  value       = "curl http://${aws_instance.web.public_ip}/health.html"
}

output "get_db_password" {
  description = "Command to retrieve the RDS password"
  value = var.enable_secrets_manager ? (
    "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.db_credentials[0].name} --query SecretString --output text | python3 -m json.tool"
    ) : (
    "terraform output -raw db_password"
  )
}
