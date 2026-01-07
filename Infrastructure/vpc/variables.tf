# ----------------------------
# Variables
# ----------------------------
variable "project" {
  type    = string
  default = "visionary-writings"
}

variable "env" {
  type    = string
  default = "prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

# Aurora MySQL Serverless v2 settings
variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_master_username" {
  type    = string
  default = "admin"
}

# # Serverless v2 ACUs (0.5 increments). Example: 0.5–4 for small, 2–16 for bigger.
# variable "aurora_min_acu" {
#   type    = number
#   default = 0.5
# }

# variable "aurora_max_acu" {
#   type    = number
#   default = 4
# }

# Set true if you want Aurora cluster storage encryption (recommended)
variable "storage_encrypted" {
  type    = bool
  default = true
}
