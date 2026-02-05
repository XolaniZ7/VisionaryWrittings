output "etl_staging_bucket_name" {
  description = "Name of the ETL staging S3 bucket"
  value       = aws_s3_bucket.etl_staging.bucket
}

output "content_ingestion_function_name" {
  description = "Name of the content ingestion Lambda function"
  value       = aws_lambda_function.content_ingestion.function_name
}

output "metadata_extraction_function_name" {
  description = "Name of the metadata extraction Lambda function"
  value       = aws_lambda_function.metadata_extraction.function_name
}