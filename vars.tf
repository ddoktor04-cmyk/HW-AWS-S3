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

variable "aws_zone" {
  type    = string
  default = "eu-north-1a"
}

variable "aws_image_id" {
  type    = string
  default = "ami-0aba19e56f3eaec05"
}

variable "aws_instance_type" {
  type    = string
  default = "t3.small"
}

variable "aws_key_name" {
  type    = string
  default = "Key1"
}

variable "aws_instance_type_web" {
  type        = string
  description = "Instance type for web nodes behind the ALB"
  default     = "t3.micro"
}
