provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Default VPC та його default subnets (2+ AZ) — для ALB та інстансів
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

locals {
  # Сортуємо, щоб отримати стабільний порядок підмереж
  default_subnet_ids = sort(data.aws_subnets.default.ids)
}

# Security Group для веб-інстансів: HTTP лише від ALB, SSH для адміністрування
resource "aws_security_group" "web" {
  name        = "mystat-web-sg"
  description = "Web instances: HTTP from ALB, SSH for admin"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "mystat-web-sg"
  }
}

# HTTP дозволено ззовні (лабораторна робота — прямий доступ до нод)
resource "aws_security_group_rule" "web_http_from_alb" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
  description       = "HTTP access (lab: direct + via ALB)"
}

resource "aws_security_group_rule" "web_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
  description       = "SSH access"
}

resource "aws_security_group_rule" "web_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound"
}
