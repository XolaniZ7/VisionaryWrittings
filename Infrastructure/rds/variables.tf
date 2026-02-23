variable "project" {
  type    = string
  default = "visionary-writings"
}

variable "environment" {
  type = string
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

variable "allocated_storage" {
  type    = number
  default = 150
}

variable "max_allocated_storage" {
  type    = number
  default = 400
}

variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "storage_type" {
  type    = string
  default = "gp3"
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

# variable "db_subnet_group_name" {
#   description = "The name of the DB subnet group to use for the RDS instance."
#   type        = string
# }

variable "mysql_engine_version" {
  type    = string
  default = "8.0.43"
}

variable "db_username" {
  description = "The master username for the database."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The master password for the database."
  type        = string
  sensitive   = true
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "performance_insights_enabled" {
  type    = bool
  default = true
}
