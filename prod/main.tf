provider "aws" {
  region = var.aws_region
}

module "iam_roles" {
  source = "../Infrastructure/iam_roles"
}

module "tagging_standards" {
  source = "../Infrastructure/tagging_standards"
}

module "vpc" {
  source = "../Infrastructure/vpc"
}

module "rds" {
  source                 = "../Infrastructure/rds"
  private_subnet_ids     = module.vpc.private_subnet_ids
  rds_security_group_ids = [module.vpc.ecs_security_group_id]
  # db_subnet_group_name   = module.vpc.rds_subnet_group_name
  environment = "prod"
}

module "s3" {
  source      = "../Infrastructure/s3"
  environment = "prod"
}
