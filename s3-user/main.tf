provider "aws" {
  region = "af-south-1"
}

terraform {
  backend "s3" {
    bucket         = "visionary-writings-disraptor-backend-terraform-state"
    key            = "s3/user/terraform.tfstate"
    region         = "af-south-1"
    dynamodb_table = "visionary-writings-backend-terraform-lock-table"
  }
}

############################
# IAM user for DO -> S3 migration
############################

variable "project" {
  type    = string
  default = "digital-ocean-to-s3-migration-vw"
}


locals {
  name = "${var.project}-migration-vw"
  tags = {
    Project     = var.project
    Environment = "prod/dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_user" "migration_user" {
  name = "${local.name}-user"
  tags = local.tags
}

# Attach AWS managed policies (full access)
resource "aws_iam_user_policy_attachment" "s3_full" {
  user       = aws_iam_user.migration_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_user_policy_attachment" "ec2_full" {
  user       = aws_iam_user.migration_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# Programmatic access credentials
resource "aws_iam_access_key" "migration_key" {
  user = aws_iam_user.migration_user.name
}

############################
# Outputs
############################

output "migration_iam_user_name" {
  value = aws_iam_user.migration_user.name
}

output "migration_access_key_id" {
  value = aws_iam_access_key.migration_key.id
}

# WARNING: This is sensitive. It will be stored in terraform state.
output "migration_secret_access_key" {
  value     = aws_iam_access_key.migration_key.secret
}
