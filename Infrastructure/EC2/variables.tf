variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "VPC ID passed from root module"
}

variable "subnet_id" {
  type        = string
  description = "The Public Subnet ID where the EC2 instance will be deployed"
}

variable "infra_security_group_id" {
  type        = string
  description = "The Security Group ID from the infrastructure (allows DB access)"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "my_ip_for_ssh" {
  description = "Your public IP address to allow SSH access. Should be in CIDR format (e.g., '1.2.3.4/32')."
  type        = string
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for EC2 access"
}

variable "iam_instance_profile" {
  description = "The IAM instance profile to associate with the EC2 instance."
  type        = string
}

variable "github_repo_url" {
  type        = string
  description = "URL of the GitHub repository to clone (e.g., github.com/user/repo.git)"
}

variable "github_token_secret_arn" {
  type        = string
  description = "ARN of the Secrets Manager secret containing the GitHub token"
}

variable "env_vars" {
  type        = map(string)
  description = "Environment variables to generate .env file on EC2"
  default     = {}
}
