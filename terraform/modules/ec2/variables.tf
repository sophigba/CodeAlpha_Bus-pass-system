# terraform/modules/ec2/variables.tf

variable "key_pair_name" {
  description = "EC2 key pair name for SSH"
  type        = string
}

variable "ec2_sg_id" {
  description = "Security group ID for EC2"
  type        = string
}

variable "public_subnet_a_id" {
  description = "Public subnet A for EC2 instances"
  type        = string
}

variable "public_subnet_b_id" {
  description = "Public subnet B for EC2 instances"
  type        = string
}

variable "db_host" {
  description = "RDS endpoint passed to Flask app"
  type        = string
}

variable "db_user" {
  description = "RDS username passed to Flask app"
  type        = string
}

variable "db_pass" {
  description = "RDS password passed to Flask app"
  type        = string
  sensitive   = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID for us-east-1"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}