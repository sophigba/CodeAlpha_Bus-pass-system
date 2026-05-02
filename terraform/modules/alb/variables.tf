# terraform/modules/alb/variables.tf

variable "alb_sg_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "public_subnet_a_id" {
  description = "Public subnet A for ALB"
  type        = string
}

variable "public_subnet_b_id" {
  description = "Public subnet B for ALB"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for target group"
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name to attach to ALB"
  type        = string
}
