---
name: aws-elb
description: Load balancer configuration. Use when setting up ALB/NLB, creating target groups, configuring listeners, or managing health checks.
metadata:
  author: cmd521
  version: "1.0"
---

# AWS Elastic Load Balancing

## When to Use

- Setting up Application Load Balancer (ALB)
- Setting up Network Load Balancer (NLB)
- Creating target groups
- Configuring listeners
- Managing health checks

## ALB vs NLB

| Feature | ALB | NLB |
|---------|-----|-----|
| Protocol | HTTP, HTTPS | TCP, UDP, TLS |
| Use case | Web applications | High performance, static IP |
| Routing | Path, Host, Header | IP, Port |
| Latency | Milliseconds | Sub-millisecond |
| Cost | Lower | Higher |

## Application Load Balancer

```hcl
resource "aws_lb" "web" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.web_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod" ? true : false

  access_logs {
    bucket  = var.access_logs_bucket
    enabled = true
  }

  tags = {
    Name        = "${var.project}-${var.environment}-alb"
    Environment = var.environment
  }
}
```

## Target Group

```hcl
resource "aws_lb_target_group" "web" {
  name     = "${var.project}-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project}-${var.environment}-tg"
  }
}
```

## Listeners

### HTTP to HTTPS Redirect

```hcl
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
```

### HTTPS Listener

```hcl
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.web.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
```

### Path-Based Routing

```hcl
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
```

## Target Group Attachments

```hcl
resource "aws_lb_target_group_attachment" "web" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = var.instance_ids[count.index]
  port             = 80
}
```

## Environment Differences

| Aspect | Dev | Staging | Prod |
|--------|-----|---------|------|
| Deletion protection | false | false | true |
| Access logs | false | true | true |
| SSL policy | TLS 1.2 | TLS 1.3 | TLS 1.3 |
| Cross-zone | false | true | true |
| Internal | true | false | false |

## Gotchas

1. **Deletion Protection**: Enable for production
2. **Health Checks**: Configure appropriate thresholds
3. **Deregistration Delay**: Default 300s, reduce for fast deploys
4. **Cross-Zone**: ALB enabled by default, NLB opt-in
5. **SSL Policy**: Use latest TLS 1.3 policy
6. **Access Logs**: Enable for debugging and audit
7. **Connection Draining**: Graceful shutdown of connections

## See Also

- [aws-ec2](../aws-ec2/SKILL.md) for instances
- [aws-security-groups](../aws-security-groups/SKILL.md) for firewall rules
- [assets/elb.tf.example](assets/elb.tf.example) for complete example
