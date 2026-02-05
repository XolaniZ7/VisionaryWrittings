variable "project" {
  type        = string
  description = "Project name for resource tagging"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for Lambda functions"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for Lambda functions"
}

variable "database_url" {
  type        = string
  description = "Database connection string"
  sensitive   = true
}

variable "rds_security_group_id" {
  type        = string
  description = "RDS security group ID for Lambda access"
}