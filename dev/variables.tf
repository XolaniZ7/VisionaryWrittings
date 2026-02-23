variable "project" {
  description = "The project name"
  type        = string
}

variable "environment" {
  description = "The deployment environment"
  type        = string
}

variable "aws_region" {
  type    = string
  default = "af-south-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "github_repo_url" {
  description = "The URL of the GitHub repository to be cloned onto the EC2 instance."
  type        = string
}

variable "github_token_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret containing the GitHub token."
  type        = string
}

variable "my_ip_for_ssh" {
  description = "Your public IP address for SSH access to the EC2 instance (in CIDR format, e.g., '1.2.3.4/32')."
  type        = string
}

variable "ssh_public_key" {
  description = "The content of your SSH public key to access the EC2 instance."
  type        = string
  sensitive   = true
}
