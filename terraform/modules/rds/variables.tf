# terraform/modules/rds/variables.tf

variable "private_subnet_a_id" {
  description = "Private subnet A ID for RDS"
  type        = string
}

variable "private_subnet_b_id" {
  description = "Private subnet B ID for RDS"
  type        = string
}

variable "rds_sg_id" {
  description = "Security group ID for RDS"
  type        = string
}

variable "db_username" {
  description = "RDS master username"
  type        = string
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "buspassdb"
}

variable "instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}