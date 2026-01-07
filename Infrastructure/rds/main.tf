terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "af-south-1"
}

# -----------------------------
# Locals
# -----------------------------
locals {
  name = "visionary-writings-${var.environment}"
  tags = {
    Project     = "visionary-writings"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_rds_cluster_parameter_group" "aurora_mysql" {
  name        = "${local.name}-aurora-mysql"
  family      = "aurora-mysql8.0"
  description = "Aurora MySQL 8.0 parameter group"

  # Example: enable slow query log (tune as needed)
  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  tags = merge(local.tags, { Name = "${local.name}-aurora-mysql-pg" })
}

resource "aws_db_subnet_group" "rds_private" {
  name       = "${local.name}-rds-private-subnets"
  subnet_ids = var.private_subnet_ids

  tags = merge(local.tags, { Name = "${local.name}-rds-subnet-group" })
}


resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${local.name}-aurora-mysql"

  engine         = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.08.2" # pin for stability; update intentionally

  database_name   = var.db_name
  master_username = var.master_username
  # master_password = "ChangeMe-Use-SecretsManager!"
  manage_master_user_password = true

  port = 3306

  db_subnet_group_name   = aws_db_subnet_group.rds_private.name
  vpc_security_group_ids = var.rds_security_group_ids

  # Serverless v2 scaling config (ACUs)
  serverlessv2_scaling_configuration {
    min_capacity = 4  # prod baseline
    max_capacity = 16 # burst headroom
  }

  storage_encrypted = true
  # kms_key_id      = aws_kms_key.rds.arn  # optional: supply your own CMK

  backup_retention_period = 14
  preferred_backup_window = "02:00-03:00"

  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.name}-aurora-final"

  enabled_cloudwatch_logs_exports = ["error", "slowquery"] # aurora-mysql supports these

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_mysql.name

  tags = merge(local.tags, { Name = "${local.name}-aurora-mysql" })
}

# Writer instance (Serverless v2 uses instance class db.serverless)
resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${local.name}-aurora-writer-1"
  cluster_identifier = aws_rds_cluster.aurora.id

  engine         = aws_rds_cluster.aurora.engine
  engine_version = aws_rds_cluster.aurora.engine_version

  instance_class = "db.serverless"

  publicly_accessible = false

  tags = merge(local.tags, { Name = "${local.name}-aurora-writer-1", Role = "writer" })
}

# Optional: add a reader for HA/read scaling (recommended for prod)
resource "aws_rds_cluster_instance" "reader" {
  count              = 1
  identifier         = "${local.name}-aurora-reader-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora.id

  engine         = aws_rds_cluster.aurora.engine
  engine_version = aws_rds_cluster.aurora.engine_version

  instance_class = "db.serverless"

  publicly_accessible = false

  tags = merge(local.tags, { Name = "${local.name}-aurora-reader-${count.index + 1}", Role = "reader" })
}
