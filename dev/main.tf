provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source   = "../Infrastructure/vpc"
  vpc_cidr = "10.40.0.0/16"
}

module "rds" {
  source                       = "../Infrastructure/rds"
  private_subnet_ids           = module.vpc.private_subnet_ids
  rds_security_group_ids       = [module.vpc.db_security_group_id]
  # db_subnet_group_name         = module.vpc.rds_subnet_group_name
  environment                  = "dev"
  instance_class               = "db.t3.micro"
  performance_insights_enabled = false
}

module "s3" {
  source      = "../Infrastructure/s3"
  environment = "dev"
}
