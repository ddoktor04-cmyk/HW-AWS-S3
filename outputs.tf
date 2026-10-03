output "bucket_id" {
  description = "Name of the S3 bucket hosting the static website"
  value       = aws_s3_bucket.site.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.site.arn
}

output "website_endpoint" {
  description = "S3 static website endpoint (HTTP)"
  value       = aws_s3_bucket_website_configuration.site.website_endpoint
}

output "site_url" {
  description = "URL of the static website via S3 endpoint"
  value       = "http://${aws_s3_bucket_website_configuration.site.website_endpoint}/"
}

output "cname_name" {
  description = "DNS name to point at the S3 website endpoint (add manually at the registrar)"
  value       = "pzt.pp.ua"
}

output "cname_value" {
  description = "CNAME target value for the pzt.pp.ua DNS record"
  value       = aws_s3_bucket_website_configuration.site.website_endpoint
}
