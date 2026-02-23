terraform {
  backend "s3" {
    bucket         = "visionary-writings-disraptor-backend-terraform-state35"
    key            = "dev/infra-resources/terraform.tfstate"
    region         = "af-south-1"
    dynamodb_table = "visionary-writings-backend-terraform-lock-table"
  }
}
