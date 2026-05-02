# terraform/modules/rds/main.tf

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "buspass-rds-subnet-group"
  subnet_ids = [var.private_subnet_a_id, var.private_subnet_b_id]
  tags       = { Name = "BusPass-RDS-Subnet-Group" }
}

resource "aws_db_instance" "buspass_db" {
  identifier             = "buspass-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "buspassdb"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [var.rds_sg_id]
  multi_az               = true
  skip_final_snapshot    = true
  publicly_accessible    = false  # Private — only EC2 can reach it
  tags = { Name = "BusPass-DB" }
}