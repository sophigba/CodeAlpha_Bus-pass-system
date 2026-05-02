# terraform/modules/s3/variables.tf

variable "s3_bucket_name" {
  description = "Unique name for the S3 frontend bucket"
  type        = string
}