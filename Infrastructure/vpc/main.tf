terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = "af-south-1"
}

locals {
  name = "${var.project}-${var.env}"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    Project     = var.project
    Environment = var.env
    Team        = "Disraptor/DevOps"
    Automation  = "Terraform"
  }
}

data "aws_availability_zones" "available" {}

# ----------------------------
# VPC + IGW
# ----------------------------
resource "aws_vpc" "vw_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, { Name = "${local.name}-vpc" })
}

resource "aws_internet_gateway" "vw_igw" {
  vpc_id = aws_vpc.vw_vpc.id
  tags   = merge(local.tags, { Name = "${local.name}-igw" })
}

# ----------------------------
# Subnets (2 AZs)
# ----------------------------
resource "aws_subnet" "public" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.vw_vpc.id
  availability_zone       = local.azs[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${var.env}-${local.name}-public-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.vw_vpc.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)

  tags = merge(local.tags, {
    Name = "${var.env}-${local.name}-private-${count.index + 1}"
    Tier = "private"
  })
}

# ----------------------------
# Route tables
# ----------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vw_vpc.id
  tags   = merge(local.tags, { Name = "${var.env}-${local.name}-rt-public" })
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vw_igw.id
}

resource "aws_route_table_association" "public" {
  count          = length(local.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = length(local.azs)
  vpc_id = aws_vpc.vw_vpc.id

  tags = merge(local.tags, {
    Name = "${var.env}-${local.name}-rt-private"
  })
}

resource "aws_route_table_association" "private" {
  count          = length(local.azs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# ----------------------------
# Security Groups
# ----------------------------

# ECS tasks SG (attach this to ECS services/tasks)
resource "aws_security_group" "ecs" {
  name        = "${var.env}-${local.name}-sg-ecs"
  description = "ECS tasks/services SG"
  vpc_id      = aws_vpc.vw_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.env}-${local.name}-sg-ecs" })
}

# EC2 SG (attach to EC2 instances that must access DB)
resource "aws_security_group" "ec2" {
  name        = "${var.env}-${local.name}-sg-ec2"
  description = "EC2 app/bastion SG (for DB access)"
  vpc_id      = aws_vpc.vw_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.env}-${local.name}-sg-ec2" })
}

# DB SG
resource "aws_security_group" "db" {
  name        = "${local.name}-sg-db"
  description = "Aurora DB SG (private only)"
  vpc_id      = aws_vpc.vw_vpc.id

  tags = merge(local.tags, { Name = "${local.name}-sg-db" })
}

# Allow MySQL from ECS SG
resource "aws_security_group_rule" "db_ingress_from_ecs" {
  type                     = "ingress"
  security_group_id        = aws_security_group.db.id
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
  description              = "Allow MySQL from ECS tasks SG"
}

# Allow MySQL from EC2 SG
resource "aws_security_group_rule" "db_ingress_from_ec2" {
  type                     = "ingress"
  security_group_id        = aws_security_group.db.id
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2.id
  description              = "Allow MySQL from EC2 SG"
}

# Frontend EC2 SG
resource "aws_security_group" "frontend_ec2" {
  name        = "${var.env}-${local.name}-sg-frontend-ec2"
  description = "Frontend EC2 SG (needs DB access)"
  vpc_id      = aws_vpc.vw_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-sg-frontend-ec2" })
}

# Admin/Bastion EC2 SG
resource "aws_security_group" "admin_ec2" {
  name        = "${var.env}-${local.name}-sg-admin-ec2"
  description = "Admin/Bastion EC2 SG (DB access)"
  vpc_id      = aws_vpc.vw_vpc.id

  # optional: restrict SSH
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # e.g. "x.x.x.x/32"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-sg-admin-ec2" })
}

# Allow MySQL from Frontend EC2
resource "aws_security_group_rule" "db_ingress_from_frontend_ec2" {
  type                     = "ingress"
  security_group_id        = aws_security_group.db.id
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend_ec2.id
  description              = "Allow MySQL from Frontend EC2"
}

# Allow MySQL from Admin/Bastion EC2
resource "aws_security_group_rule" "db_ingress_from_admin_ec2" {
  type                     = "ingress"
  security_group_id        = aws_security_group.db.id
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.admin_ec2.id
  description              = "Allow MySQL from Admin/Bastion EC2"
}

# Keep ECS as optional (you already have this)
# aws_security_group_rule.db_ingress_from_ecs stays
