output "alb_dns_name" {
  description = "Paste this into API_BASE in your frontend files"
  value       = module.alb.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS connection endpoint"
  value       = module.rds.rds_endpoint
}

output "cloudfront_domain" {
  description = "Your frontend public URL"
  value       = module.s3.cloudfront_domain
}