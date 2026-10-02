output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.web.zone_id
}

output "instance_ids" {
  description = "IDs of the web EC2 instances ([0] = main site, [1] = backup site)"
  value       = aws_instance.web[*].id
}

output "site_urls" {
  description = "URL of the load balancer serving both sites (round-robin)"
  value       = "http://${aws_lb.web.dns_name}/"
}
