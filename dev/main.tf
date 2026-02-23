provider "aws" {
  region = var.aws_region
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_ssm_role" {
  name               = "${var.project}-${var.environment}-ec2-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.project}-${var.environment}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_iam_policy" "ec2_secrets_policy" {
  name        = "${var.project}-${var.environment}-ec2-secrets-policy"
  description = "Allows EC2 to access the GitHub token secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "${var.github_token_secret_arn}*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_secrets_attachment" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = aws_iam_policy.ec2_secrets_policy.arn
}

resource "tls_private_key" "deployer" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content  = tls_private_key.deployer.private_key_pem
  filename = "${path.module}/deployer-key.pem"
}

module "vpc" {
  source   = "../Infrastructure/vpc"
  vpc_cidr = "10.40.0.0/16"
  env      = "dev"
  project  = "telkom-ai-visionary-writings"
}

module "rds" {
  source                 = "../Infrastructure/rds"
  private_subnet_ids     = module.vpc.private_subnet_ids
  rds_security_group_ids = [module.vpc.db_security_group_id]
  # db_subnet_group_name         = module.vpc.rds_subnet_group_name
  environment                  = "dev"
  instance_class               = "db.t3.micro"
  db_username                  = var.db_username
  db_password                  = var.db_password
  performance_insights_enabled = false
}

module "s3" {
  source      = "../Infrastructure/s3"
  environment = "dev"
}

module "app_transfer" {
  source      = "../Infrastructure/app_transfer"
  environment = "dev"
  project     = "telkom-ai-visionary-writings"
}

# module "lambda_etl" {
#   source                = "../Infrastructure/ETL"
#   project               = "telkom-ai-visionary-writings"
#   environment           = "dev"
#   vpc_id                = module.vpc.vpc_id
#   private_subnet_ids    = module.vpc.private_subnet_ids
#   database_url          = module.rds.database_url
#   rds_security_group_id = module.vpc.db_security_group_id
# }

module "ec2_app" {
  source                  = "../Infrastructure/EC2"
  project                 = "telkom-ai-visionary-writings"
  environment             = "dev"
  vpc_id                  = module.vpc.vpc_id
  subnet_id               = module.vpc.public_subnet_ids[0]
  infra_security_group_id = module.vpc.ec2_security_group_id
  iam_instance_profile    = aws_iam_instance_profile.ssm_profile.name
  instance_type           = "t3.small"
  my_ip_for_ssh           = var.my_ip_for_ssh
  ssh_public_key          = tls_private_key.deployer.public_key_openssh

  github_repo_url         = var.github_repo_url
  github_token_secret_arn = var.github_token_secret_arn

  # Environment variables for the application
  env_vars = {
    DB_HOST      = module.rds.db_endpoint
    DB_USER      = var.db_username
    DB_PASSWORD  = var.db_password
    DB_NAME      = module.rds.db_name
    DB_PORT      = "3306"
    NODE_ENV     = "development"
    DATABASE_URL = "mysql://${var.db_username}:${var.db_password}@${module.rds.db_endpoint}/${module.rds.db_name}"
    PORT         = "3000"
  }
}

# import {
#   to = module.lambda_etl.aws_lambda_function.metadata_extraction
#   id = "telkom-ai-visionary-writings-metadata-extraction"
# }

# import {
#   to = module.rds.aws_db_instance.vw_db
#   id = "visionary-writings-dev-db"
# }

# import {
#   to = module.lambda_etl.aws_lambda_permission.eventbridge_invoke_metadata
#   id = "telkom-ai-visionary-writings-metadata-extraction/AllowExecutionFromEventBridge"
# }
