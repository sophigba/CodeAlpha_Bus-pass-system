# terraform/main.tf
data "http" "my_ip" {
  url = "https://api.ipify.org/"
}

locals {
  my_ip = "${data.http.my_ip.response_body}/32"
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"

  aws_region = var.aws_region

  my_ip = local.my_ip
}

module "s3" {
  source = "./modules/s3"

  s3_bucket_name = var.s3_bucket_name
}

module "rds" {
  source = "./modules/rds"

  private_subnet_a_id = module.vpc.private_subnet_a_id
  private_subnet_b_id = module.vpc.private_subnet_b_id
  rds_sg_id           = module.vpc.rds_sg_id
  db_username         = var.db_username
  db_password         = var.db_password
}

module "ec2" {
  source = "./modules/ec2"

  key_pair_name      = var.key_pair_name
  ec2_sg_id          = module.vpc.ec2_sg_id
  public_subnet_a_id = module.vpc.public_subnet_a_id
  public_subnet_b_id = module.vpc.public_subnet_b_id
  db_host            = module.rds.rds_endpoint
  db_user            = var.db_username
  db_pass            = var.db_password
}

module "alb" {
  source = "./modules/alb"

  alb_sg_id          = module.vpc.alb_sg_id
  public_subnet_a_id = module.vpc.public_subnet_a_id
  public_subnet_b_id = module.vpc.public_subnet_b_id
  vpc_id             = module.vpc.vpc_id
  asg_name           = module.ec2.asg_name
}