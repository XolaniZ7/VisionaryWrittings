locals {
  bucket_prefix = "${var.project}-${var.environment}"

  assets_bucket_name  = "${local.bucket_prefix}-assets4"
  logs_bucket_name    = "${local.bucket_prefix}-logs4"
  backups_bucket_name = "${local.bucket_prefix}-backups4"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

############################################
# ---------------- ASSETS BUCKET ----------------
# Purpose: media, PDFs, user uploads
############################################
resource "aws_s3_bucket" "assets" {
  bucket = local.assets_bucket_name
  tags   = merge(local.common_tags, { Name = local.assets_bucket_name, Purpose = "assets" })
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "assets" {
  bucket = aws_s3_bucket.assets.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id
  rule {
    apply_server_side_encryption_by_default {
      # Keep cost-efficient default encryption (SSE-S3).
      # If you want SSE-KMS, change to "aws:kms" + add kms_key_id.
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

############################################
# ---------------- LOGGING BUCKET ----------------
# Purpose: ALB/S3/CloudTrail/VPC Flow/etc. log dumps
############################################
resource "aws_s3_bucket" "logs" {
  bucket = local.logs_bucket_name
  tags   = merge(local.common_tags, { Name = local.logs_bucket_name, Purpose = "logs" })
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# (Optional) Let OTHER buckets write server-access logs into this logs bucket
# If you enable server access logging elsewhere, you typically add a policy like below.
# NOTE: Many AWS services (ALB/CloudTrail/etc.) have their own required bucket policies.
# Keep this generic policy ONLY if you intend to use S3 Server Access Logging.
resource "aws_s3_bucket_policy" "logs_allow_s3_server_access_logging" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "S3ServerAccessLogsPolicy"
        Effect    = "Allow"
        Principal = { Service = "logging.s3.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.logs.arn}/*"
      }
    ]
  })
}

############################################
# ---------------- BACKUPS BUCKET ----------------
# Purpose: DB backups, exports, snapshots, app backups
############################################
resource "aws_s3_bucket" "backups" {
  bucket = local.backups_bucket_name
  tags   = merge(local.common_tags, { Name = local.backups_bucket_name, Purpose = "backups" })
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

