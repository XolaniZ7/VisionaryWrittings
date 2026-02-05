locals {
  name = "${var.project}-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
    Team        = "Disraptor/DevOps"
    Automation  = "Terraform"
  }
}

resource "aws_db_instance" "legal_ascend_db" {
  identifier = "visionary-writings-${var.environment}-db"

  # MySQL
  engine         = "mysql"
  engine_version = var.mysql_engine_version
  port           = 3306

  instance_class = var.instance_class
  storage_type   = var.storage_type # "gp3" recommended
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  multi_az              = false

  # DB settings
  username                    = "admin"
  manage_master_user_password = true
  # optional: if you want a default database created
  db_name = var.db_name

  # Backups
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"

  # Maintenance
  maintenance_window = "sun:04:00-sun:05:00"

  # Recommended defaults
  storage_encrypted   = true
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "visionary-writings-${var.environment}-final"

  # Networking / security
  db_subnet_group_name         = aws_db_subnet_group.rds_private.name
  vpc_security_group_ids       = var.rds_security_group_ids
  publicly_accessible          = false
  performance_insights_enabled = var.performance_insights_enabled

  tags = merge(local.tags, { Name = "${local.name}-${var.environment}-db" })
}

# ----------------------------
# RDS Subnet Group (PRIVATE ONLY)
# ----------------------------
resource "aws_db_subnet_group" "rds_private" {
  name       = "${var.environment}-${local.name}-rds-private-subnets"
  subnet_ids = var.private_subnet_ids

  tags = merge(local.tags, { Name = "${local.name}-rds-subnet-group" })
}