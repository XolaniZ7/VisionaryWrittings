output "assets_bucket_name" {
  value = aws_s3_bucket.assets.bucket
}

output "logs_bucket_name" {
  value = aws_s3_bucket.logs.bucket
}

output "backups_bucket_name" {
  value = aws_s3_bucket.backups.bucket
}
