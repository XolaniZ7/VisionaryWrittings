# -----------------------------
# Variables
# -----------------------------

variable "environment" {
  type    = string
  default = "prod"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "master_username" {
  type    = string
  default = "dbadmin"
}

# -----------------------------
# Networking inputs
# -----------------------------
variable "private_subnet_ids" {
  description = "List of private subnet IDs used for the RDS/Aurora subnet group."
  type        = list(string)
}

variable "rds_security_group_ids" {
  description = "List of security group IDs attached to the Aurora cluster."
  type        = list(string)
}
