# Application Load Balancer (публічний, default VPC, 2+ AZ)
resource "aws_lb" "web" {
  name               = "mystat-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.default_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "mystat-web-alb"
  }
}

# Target group: HTTP/80, health check GET /
resource "aws_lb_target_group" "web" {
  name     = "mystat-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    path                = "/"
    matcher             = "200"
    protocol            = "HTTP"
  }

  tags = {
    Name = "mystat-web-tg"
  }
}

# Listener: порт 80 → forward на target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Підключення обох інстансів до target group
resource "aws_lb_target_group_attachment" "web" {
  count            = length(aws_instance.web)
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}
