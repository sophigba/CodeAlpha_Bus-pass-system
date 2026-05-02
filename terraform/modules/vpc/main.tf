# terraform/modules/vpc/main.tf

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "bus_pass_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "BusPass-VPC" }
}

# Public Subnets (ALB + EC2 + NAT Gateway live here)
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.bus_pass_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "Public-Subnet-A" }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.bus_pass_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "Public-Subnet-B" }
}

# Private Subnets (RDS lives here — no direct internet access)
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.bus_pass_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "Private-Subnet-A" }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.bus_pass_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "Private-Subnet-B" }
}

# Internet Gateway — entry point into the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.bus_pass_vpc.id
  tags   = { Name = "BusPass-IGW" }
}

# NAT Gateway — allows private subnet resources to reach internet (for updates)
resource "aws_eip" "nat_eip" { domain = "vpc" }

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_a.id
  tags          = { Name = "BusPass-NAT" }
}

# Route table for public subnets → IGW
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.bus_pass_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "Public-RT" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Route table for private subnets → NAT Gateway
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.bus_pass_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = { Name = "Private-RT" }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt.id
}