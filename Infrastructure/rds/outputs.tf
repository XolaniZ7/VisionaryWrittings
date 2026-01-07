# -----------------------------
# Aurora Cluster Outputs
# -----------------------------

output "aurora_cluster_id" {
  description = "ID of the Aurora MySQL cluster."
  value       = aws_rds_cluster.aurora.id
}

output "aurora_cluster_arn" {
  description = "ARN of the Aurora MySQL cluster."
  value       = aws_rds_cluster.aurora.arn
}

output "aurora_endpoint_writer" {
  description = "Writer endpoint for the Aurora MySQL cluster."
  value       = aws_rds_cluster.aurora.endpoint
}

output "aurora_endpoint_reader" {
  description = "Reader endpoint for the Aurora MySQL cluster."
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "aurora_port" {
  description = "Port on which the Aurora MySQL cluster listens."
  value       = aws_rds_cluster.aurora.port
}

# -----------------------------
# Subnet Group Outputs
# -----------------------------

output "rds_subnet_group_name" {
  description = "Name of the DB subnet group used by the Aurora cluster."
  value       = aws_db_subnet_group.rds_private.name
}

output "rds_subnet_group_id" {
  description = "ID of the DB subnet group used by the Aurora cluster."
  value       = aws_db_subnet_group.rds_private.id
}

# -----------------------------
# Instance Outputs
# -----------------------------

output "aurora_writer_instance_id" {
  description = "Identifier of the primary (writer) Aurora instance."
  value       = aws_rds_cluster_instance.writer.id
}

output "aurora_reader_instance_ids" {
  description = "Identifiers of the Aurora reader instances."
  value       = aws_rds_cluster_instance.reader[*].id
}
