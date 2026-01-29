provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source   = "../Infrastructure/vpc"
  vpc_cidr = "10.40.0.0/16"
  env = "dev"
}

module "rds" {
  source                       = "../Infrastructure/rds"
  private_subnet_ids           = module.vpc.private_subnet_ids
  rds_security_group_ids       = [module.vpc.ecs_security_group_id]
  db_subnet_group_name         = module.vpc.rds_subnet_group_name
  environment                  = "dev"
  instance_class               = "db.t3.micro"
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

module "lambda_etl" {
  source                = "../Infrastructure/ETL"
  project               = "telkom-ai-visionary-writings"
  environment           = "dev"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  database_url          = module.rds.database_url
  rds_security_group_id = module.rds.rds_security_group_id
}