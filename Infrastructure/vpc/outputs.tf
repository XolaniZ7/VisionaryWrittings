# ----------------------------
# VPC Outputs
# ----------------------------

output "vpc_id" {
  description = "ID of the VPC provisioned for the project environment."
  value       = aws_vpc.vw_vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block associated with the project VPC."
  value       = aws_vpc.vw_vpc.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway attached to the VPC for public internet access."
  value       = aws_internet_gateway.vw_igw.id
}

# ----------------------------
# Subnet Outputs
# ----------------------------

output "public_subnet_ids" {
  description = "List of public subnet IDs spread across availability zones."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs spread across availability zones."
  value       = aws_subnet.private[*].id
}

output "availability_zones" {
  description = "Availability Zones used for subnet distribution."
  value       = local.azs
}

# ----------------------------
# Route Table Outputs
# ----------------------------

output "public_route_table_id" {
  description = "Route table ID used by public subnets (routes internet traffic via IGW)."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of route table IDs used by private subnets."
  value       = aws_route_table.private[*].id
}

# ----------------------------
# Security Group Outputs
# ----------------------------

output "ecs_security_group_id" {
  description = "Security Group ID attached to ECS services and tasks."
  value       = aws_security_group.ecs.id
}

output "ec2_security_group_id" {
  description = "Security Group ID attached to EC2 instances (application or bastion access)."
  value       = aws_security_group.ec2.id
}

output "db_security_group_id" {
  description = "Security Group ID attached to the Aurora/RDS database (private access only)."
  value       = aws_security_group.db.id
}

# ----------------------------
# RDS Outputs
# ----------------------------

# output "rds_subnet_group_name" {
#   description = "Name of the DB subnet group containing only private subnets for RDS/Aurora."
#   value       = aws_db_subnet_group.rds_private.name
# }

# output "rds_subnet_group_id" {
#   description = "ID of the DB subnet group used for private RDS/Aurora deployments."
#   value       = aws_db_subnet_group.rds_private.id
# }
