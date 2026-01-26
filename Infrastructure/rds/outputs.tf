# -----------------------------
# RDS Instance Outputs
# -----------------------------

output "rds_instance_id" {
  description = "ID of the SQL Server RDS instance."
  value       = aws_db_instance.legal_ascend_db.id
}

output "rds_instance_arn" {
  description = "ARN of the SQL Server RDS instance."
  value       = aws_db_instance.legal_ascend_db.arn
}

output "rds_instance_identifier" {
  description = "Identifier of the SQL Server RDS instance."
  value       = aws_db_instance.legal_ascend_db.identifier
}

output "rds_engine" {
  description = "Database engine used by the RDS instance."
  value       = aws_db_instance.legal_ascend_db.engine
}

output "rds_engine_version" {
  description = "Database engine version used by the RDS instance."
  value       = aws_db_instance.legal_ascend_db.engine_version
}

output "rds_endpoint" {
  description = "Connection endpoint for the SQL Server RDS instance."
  value       = aws_db_instance.legal_ascend_db.endpoint
}

output "rds_port" {
  description = "Port on which the SQL Server RDS instance listens."
  value       = aws_db_instance.legal_ascend_db.port
}

# -----------------------------
# Networking Outputs
# -----------------------------

output "rds_subnet_group_name" {
  description = "Name of the DB subnet group associated with the RDS instance."
  value       = aws_db_subnet_group.rds_private.name
}

output "rds_subnet_group_id" {
  description = "ID of the DB subnet group associated with the RDS instance."
  value       = aws_db_subnet_group.rds_private.id
}

output "rds_security_group_ids" {
  description = "Security group IDs attached to the RDS instance."
  value       = aws_db_instance.legal_ascend_db.vpc_security_group_ids
}