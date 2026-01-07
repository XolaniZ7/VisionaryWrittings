provider "aws" {
  region = "af-south-1"
}

module "iam_roles" {
  source = "./iam_roles"
}

module "tagging_standards" {
  source = "./tagging_standards"
}

module "vpc" {
  source = "./vpc"
}

module "rds" {
  source                 = "./rds"
  private_subnet_ids     = module.vpc.private_subnet_ids
  rds_security_group_ids = [module.vpc.ecs_security_group_id]
}
