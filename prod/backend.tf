terraform {
  backend "s3" {
    bucket         = "visionary-writings-disraptor-backend-terraform-state"
    key            = "prod/infra-resources/terraform.tfstate"
    region         = "af-south-1"
    dynamodb_table = "visionary-writings-backend-terraform-lock-table"
  }
}
# terraform {
#   required_version = ">= 1.5.0"
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.0"
#     }
#   }
#   backend "s3" {
#     bucket         = "khoi-tech-disraptor-backend-terraform-state"
#     key            = "prod/infra-resources/terraform.tfstate"
#     region         = "af-south-1"
#     dynamodb_table = "khoi-tech-backend-terraform-lock-table"
#   }

