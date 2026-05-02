variable "aws_region" {
  description = "AWS region to deploy all resources"
  type        = string
  default     = "us-east-1"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "key_pair_name" {
  description = "Name of EC2 key pair for SSH access"
  type        = string
}

variable "my_ip" {
  description = "Your local IP address for SSH access (format: x.x.x.x/32)"
  type        = string
}

variable "s3_bucket_name" {
  description = "Unique name for the S3 frontend bucket"
  type        = string
  default     = "buspass-frontend"
}
