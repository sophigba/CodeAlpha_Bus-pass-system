# terraform/modules/s3/outputs.tf

output "cloudfront_domain" {
  description = "CloudFront public URL for the frontend"
  value       = aws_cloudfront_distribution.frontend_cdn.domain_name
}

output "s3_bucket_name" {
  description = "S3 bucket name for upload commands"
  value       = aws_s3_bucket.frontend.bucket
}