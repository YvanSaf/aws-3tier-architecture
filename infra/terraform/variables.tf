# ---------------------------------------------------------------------------
# General
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "Target AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name, used as a prefix on all resource names"
  type        = string
  default     = "yvan-3tier"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Project owner, used in resource tags"
  type        = string
  default     = "yvan-raffi"
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet (AZ-a) — Bastion Host and Web Server"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_app_cidr" {
  description = "CIDR for the private App Server subnet (AZ-a)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_db_a_cidr" {
  description = "CIDR for the primary DB private subnet (AZ-a)"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_db_b_cidr" {
  description = "CIDR for the secondary DB private subnet (AZ-b), required by the RDS subnet group"
  type        = string
  default     = "10.0.4.0/24"
}

variable "az_a" {
  description = "Primary Availability Zone"
  type        = string
  default     = "us-east-1a"
}

variable "az_b" {
  description = "Secondary Availability Zone (used for the RDS subnet group)"
  type        = string
  default     = "us-east-1b"
}

# ---------------------------------------------------------------------------
# EC2
# ---------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID for us-east-1"
  type        = string
  # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  default     = "ami-0c02fb55956c7d316"
}

variable "lab_instance_profile" {
  description = "IAM instance profile name to attach to EC2 instances. Must include AmazonSSMManagedInstanceCore for SSM Session Manager to work."
  type        = string
  default     = "LabInstanceProfile"
}

# ---------------------------------------------------------------------------
# RDS
# ---------------------------------------------------------------------------

variable "db_name" {
  description = "Name of the initial database"
  type        = string
  default     = "mydb"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

# ---------------------------------------------------------------------------
# Monitoring
# ---------------------------------------------------------------------------

variable "alert_email" {
  description = "Email address for CloudWatch SNS alert notifications. Leave empty to disable email alerts."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Feature flags
# ---------------------------------------------------------------------------
# Some features require IAM permissions that may not be available in all
# environments. These flags let you enable or disable those features without
# changing any code. Set them to true on a full-permission AWS account.

variable "enable_secrets_manager" {
  description = "Store the RDS password in AWS Secrets Manager. Requires secretsmanager:CreateSecret. Set to true on a full-permission AWS account."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch. Requires iam:PassRole. Set to true on a full-permission AWS account."
  type        = bool
  default     = false
}
