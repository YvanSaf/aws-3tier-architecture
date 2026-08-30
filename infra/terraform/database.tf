# ===========================================================================
# RDS MariaDB — database in an isolated private subnet
# Security: encrypted at rest, no public access, password from random_password
# ===========================================================================

# RDS requires a subnet group with subnets in at least two AZs
resource "aws_db_subnet_group" "main" {
  name        = "${local.name_prefix}-db-subnet-group"
  description = "Subnet group for RDS MariaDB - private subnets only"
  subnet_ids  = [aws_subnet.private_db_a.id, aws_subnet.private_db_b.id]

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-db"

  # Engine
  engine         = "mariadb"
  engine_version = "10.6"
  instance_class = var.db_instance_class

  # Storage
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = 0       # Disable storage autoscaling in this environment
  storage_type          = "gp2"
  storage_encrypted     = true    # Encryption at rest enabled
  # The default aws/rds KMS key is used for encryption.
  # On a production account with full KMS access, use a customer-managed key:
  # kms_key_id = aws_kms_key.rds.arn

  # Credentials — the password comes from random_password, never hardcoded
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  # Network — no public access
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false  # The database is never reachable from the internet

  # Single-AZ deployment.
  # The subnet group already covers two AZs, so enabling Multi-AZ in the future
  # requires no infrastructure changes.
  multi_az = false

  # Backups
  backup_retention_period = 7             # 7 days of automated backups
  backup_window           = "03:00-04:00" # UTC
  maintenance_window      = "sun:04:00-sun:05:00"

  # Deletion settings — relaxed for a lab environment
  deletion_protection      = false  # Set to true in production
  skip_final_snapshot      = true   # Set to false in production
  delete_automated_backups = true

  performance_insights_enabled = false  # Disabled to avoid additional cost in this environment

  tags = {
    Name = "${local.name_prefix}-mariadb"
    Role = "Database"
  }

  depends_on = [
    aws_db_subnet_group.main,
    aws_secretsmanager_secret_version.db_credentials
  ]
}
