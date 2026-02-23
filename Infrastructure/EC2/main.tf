data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#############################
# Security Group
#############################

resource "aws_security_group" "app" {
  name        = "${var.project}-${var.environment}-app-sg"
  description = "Security group for Astro SSR app"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_for_ssh]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-app-sg"
  }
}

#############################
# SSH Key
#############################

resource "aws_key_pair" "deployer" {
  key_name   = "${var.project}-${var.environment}-key"
  public_key = var.ssh_public_key
}

#############################
# Elastic IP
#############################

resource "aws_eip" "app" {
  domain = "vpc"

  tags = {
    Name = "${var.project}-${var.environment}-eip"
  }
}

#############################
# EC2 Instance – Astro SSR
#############################

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.app.id, var.infra_security_group_id]
  iam_instance_profile   = var.iam_instance_profile

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    app_dir                 = "/home/ubuntu/app"
    app_user                = "ubuntu"
    github_repo_url         = var.github_repo_url
    github_token_secret_arn = var.github_token_secret_arn
    aws_region              = data.aws_region.current.name
    env_vars                = var.env_vars
  })

  tags = {
    Name = "${var.project}-${var.environment}-app"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip_association" "app" {
  instance_id   = aws_instance.app.id
  allocation_id = aws_eip.app.id
}
