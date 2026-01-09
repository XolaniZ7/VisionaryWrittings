provider "aws" {
  region = "af-south-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "visionary-writings-disraptor-backend-terraform-state"

  tags = {
    Name        = "backend Terraform State Storage"
    owner       = "Disraptor"
    environment = "production"
    automation  = "terraform"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "visionary-writings-backend-terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "backend Terraform Lock Table"
    owner       = "disraptor"
    environment = "production"
    automation  = "terraform"
  }
}
   