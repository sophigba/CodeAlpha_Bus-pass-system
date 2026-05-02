# terraform/modules/alb/outputs.tf

output "alb_dns_name" {
  description = "Public DNS name of the load balancer"
  value       = aws_lb.buspass_alb.dns_name
}