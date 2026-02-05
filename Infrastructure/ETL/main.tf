# S3 bucket for ETL staging
resource "aws_s3_bucket" "etl_staging" {
  bucket        = "${var.project}-etl-staging-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "${var.project}-etl-staging"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_public_access_block" "etl_staging" {
  bucket = aws_s3_bucket.etl_staging.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "etl_staging" {
  bucket = aws_s3_bucket.etl_staging.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Secret for Database URL
resource "aws_secretsmanager_secret" "database_url" {
  name                    = "${var.project}/database_url-${random_id.bucket_suffix.hex}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id = aws_secretsmanager_secret.database_url.id
  # This assumes `var.database_url` is passed into the module and contains the sensitive connection string.
  secret_string = var.database_url
}

# IAM role for Lambda functions
resource "aws_iam_role" "etl_lambda_role" {
  name = "${var.project}-etl-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "etl_lambda_policy" {
  name = "${var.project}-etl-lambda-policy"
  role = aws_iam_role.etl_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.etl_staging.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "${aws_s3_bucket.etl_staging.arn}"
      },
      # Allow Lambda to retrieve the database credentials from Secrets Manager
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.database_url.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.etl_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Security group for Lambda functions
resource "aws_security_group" "etl_lambda_sg" {
  name_prefix = "${var.project}-etl-lambda-"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-etl-lambda-sg"
  }
}

# Allow Lambda to access RDS
resource "aws_security_group_rule" "lambda_to_rds" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.etl_lambda_sg.id
  security_group_id        = var.rds_security_group_id
}

# Allow HTTPS ingress to the VPC Endpoint (Secrets Manager)
resource "aws_security_group_rule" "vpce_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.etl_lambda_sg.id
}

# Data source to get the current region
data "aws_region" "current" {}

# VPC Endpoint for Secrets Manager to allow Lambda access from within the VPC
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.secretsmanager"
  vpc_endpoint_type = "Interface"

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.etl_lambda_sg.id]

  private_dns_enabled = true

  tags = {
    Name        = "${var.project}-secretsmanager-vpce"
  }
}

# Data source to get the route table associated with the private subnets
data "aws_route_table" "private" {
  vpc_id = var.vpc_id
  filter {
    name   = "association.main"
    values = ["true"]
  }
}

# VPC Endpoint for S3 (Gateway) to allow Lambda access to S3 without NAT Gateway
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [data.aws_route_table.private.id]

  tags = {
    Name        = "${var.project}-s3-vpce"
  }
}


# Lambda function for content ingestion
resource "aws_lambda_function" "content_ingestion" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "${var.project}-content-ingestion"
  role          = aws_iam_role.etl_lambda_role.arn
  handler       = "content_ingestion.handler"
  runtime       = "nodejs20.x"
  timeout       = 300

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.etl_lambda_sg.id]
  }

  environment {
    variables = {
      # Pass the ARN of the secret, not the secret itself
      DB_SECRET_ARN = aws_secretsmanager_secret.database_url.arn
      S3_BUCKET     = aws_s3_bucket.etl_staging.bucket
    }
  }

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  depends_on       = [data.archive_file.lambda_zip]
}

# Lambda function for metadata extraction
resource "aws_lambda_function" "metadata_extraction" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "${var.project}-metadata-extraction"
  role          = aws_iam_role.etl_lambda_role.arn
  handler       = "metadata_extraction.handler"
  runtime       = "nodejs20.x"
  timeout       = 300

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.etl_lambda_sg.id]
  }

  environment {
    variables = {
      # Pass the ARN of the secret, not the secret itself
      DB_SECRET_ARN = aws_secretsmanager_secret.database_url.arn
      S3_BUCKET     = aws_s3_bucket.etl_staging.bucket
    }
  }

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  depends_on       = [data.archive_file.lambda_zip]
}

# S3 trigger for content ingestion
resource "aws_s3_bucket_notification" "etl_trigger" {
  bucket = aws_s3_bucket.etl_staging.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.content_ingestion.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
  }

  depends_on = [aws_lambda_permission.s3_invoke_content_ingestion]
}

resource "aws_lambda_permission" "s3_invoke_content_ingestion" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.content_ingestion.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.etl_staging.arn
}

# EventBridge rule for scheduled ETL jobs
resource "aws_cloudwatch_event_rule" "daily_etl" {
  name                = "${var.project}-daily-etl"
  description         = "Daily ETL processing"
  schedule_expression = "cron(0 2 * * ? *)" # 2 AM daily
}

resource "aws_cloudwatch_event_target" "metadata_extraction_target" {
  rule      = aws_cloudwatch_event_rule.daily_etl.name
  target_id = "MetadataExtractionTarget"
  arn       = aws_lambda_function.metadata_extraction.arn
}

resource "aws_lambda_permission" "eventbridge_invoke_metadata" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.metadata_extraction.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_etl.arn
}

# Create Lambda deployment packages
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "lambda_package.zip"
  source_dir  = "${path.module}/lambda"
}

# Lambda function for DB initialization
resource "aws_lambda_function" "db_init" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "${var.project}-db-init"
  role          = aws_iam_role.etl_lambda_role.arn
  handler       = "db_init.handler"
  runtime       = "nodejs20.x"
  timeout       = 60

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.etl_lambda_sg.id]
  }

  environment {
    variables = {
      DB_SECRET_ARN = aws_secretsmanager_secret.database_url.arn
    }
  }

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  depends_on       = [data.archive_file.lambda_zip, aws_vpc_endpoint.secretsmanager, aws_secretsmanager_secret_version.database_url]
}

# Invoke the DB Init Lambda on deployment to ensure tables exist
resource "aws_lambda_invocation" "db_init_invoke" {
  function_name = aws_lambda_function.db_init.function_name

  triggers = {
    redeployment = sha256(aws_lambda_function.db_init.source_code_hash)
  }

  input = jsonencode({})
}
