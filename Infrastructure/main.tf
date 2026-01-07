provider "aws" {
  region = "af-south-1"
}

module "iam_roles" {
  source = "./iam_roles"
}

module "rds" {
  source = "./rds"
}

module "tagging_standards" {
  source = "./tagging_standards"
}

module "vpc" {
  source = "./vpc"
}
