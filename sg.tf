# Security Group для Application Load Balancer: HTTP ззовні
resource "aws_security_group" "alb" {
  name        = "mystat-alb-sg"
  description = "Application Load Balancer: HTTP from internet"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "mystat-alb-sg"
  }
}

resource "aws_security_group_rule" "alb_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet"
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound"
}
