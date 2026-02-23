output "db_endpoint" {
  description = "The connection endpoint for the database instance (hostname only)."
  value       = aws_db_instance.vw_db.address
}

output "db_name" {
  description = "The database name."
  value       = aws_db_instance.vw_db.db_name
}

output "database_url" {
  description = "The database connection URL used by the Lambda ETL."
  value       = "mysql://${aws_db_instance.vw_db.username}:${aws_db_instance.vw_db.password}@${aws_db_instance.vw_db.endpoint}/${aws_db_instance.vw_db.db_name}"
  sensitive   = true
}
