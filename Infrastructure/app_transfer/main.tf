# S3 bucket for app deployment
resource "aws_s3_bucket" "app_transfer" {
  bucket        = "${var.environment}-${var.project}-app-transfer-bucket"
  force_destroy = true
  tags = {
    Name        = "${var.environment}-${var.project}-app-transfer-bucket"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "app_transfer" {
  bucket = aws_s3_bucket.app_transfer.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
