# terraform/modules/vpc/variables.tf

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "private_subnet_a_cidr" {
  type    = string
  default = "10.0.3.0/24"
}

variable "private_subnet_b_cidr" {
  type    = string
  default = "10.0.4.0/24"
}

variable "my_ip" {
  description = "Your IP for SSH access"
  type        = string
}

