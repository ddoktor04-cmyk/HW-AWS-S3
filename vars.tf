variable "aws_access_key" {
  type        = string
  description = "AWS Access Key ID"
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Secret Access Key"
  sensitive   = true
}

variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for the static website"
  default     = "hwbarabash1.pp.ua"
}
