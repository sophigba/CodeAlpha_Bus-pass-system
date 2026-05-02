# terraform/modules/rds/outputs.tf

output "rds_endpoint" {
  description = "RDS connection endpoint passed to EC2"
  value       = aws_db_instance.buspass_db.endpoint
}

