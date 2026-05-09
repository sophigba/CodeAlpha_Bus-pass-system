# Cloud-Based Bus Pass Booking System 

**A fully functional online bus pass booking platform where users can register, select a city route, choose a pass type and complete a booking, all served from the cloud.**

## Live URLs

| Resource | URL |
|---|---|
| Booking | https://d3subdvdad9cu1.cloudfront.net |
| API Health Check | http://buspass-alb-1884523472.us-east-1.elb.amazonaws.com/health |

---

## Architecture Overview

![Architecture Diagram](docs/Architectural%20Diagram.jpg)

This system is a fully cloud-native bus pass booking platform built on AWS and provisioned entirely with Terraform. It demonstrates scalable, highly available infrastructure across two availability zones with a clear separation between the static frontend, application layer, and database layer.

**Traffic Flow:**
```
Users → Route 53 → CloudFront → S3 (Frontend)
Users → ALB → EC2 Auto Scaling Group (Flask API) → RDS MySQL (Private Subnet)
```

---

## AWS Services

| Service | Purpose |
|---|---|
| **VPC** | Isolated network with public and private subnets across 2 AZs |
| **EC2 + Auto Scaling Group** | Hosts Flask backend, scales from 1 to 3 instances under load |
| **Application Load Balancer** | Distributes traffic across EC2 instances with health checks |
| **RDS MySQL (Multi-AZ)** | Primary database in private subnet, standby in second AZ for failover |
| **S3** | Hosts static frontend (index.html, auth.html, book.html) |
| **CloudFront** | CDN — serves frontend globally over HTTPS |
| **Route 53** | DNS routing |
| **NAT Gateway** | Allows private subnet resources to reach internet for updates |
| **IAM** | Roles and policies for least privilege access |
| **CloudWatch** | Metrics, logs, CPU alarm triggering Auto Scaling |
| **Secrets Manager** | Secure storage for DB credentials |

---

## Project Structure

```
Bus-Pass-System/
├── terraform/
│   ├── main.tf                      # Root — calls all modules, passes variables
│   ├── variables.tf                 # Input variable definitions
│   ├── outputs.tf                   # ALB DNS, RDS endpoint, CloudFront URL
│   ├── providers.tf                 # AWS provider configuration
│   ├── .terraform.lock.hcl          # Provider version lock file
│   └── modules/
│       ├── vpc/                     # VPC, subnets, IGW, NAT, route tables, security groups
│       ├── s3/                      # S3 bucket, CloudFront distribution
│       ├── rds/                     # RDS MySQL Multi-AZ in private subnets
│       ├── ec2/                     # Launch template, Auto Scaling Group, scaling policy
│       └── alb/                     # Application Load Balancer, target group, listener
├── app/
│   └── app.py                       # Flask backend (register, login, book, health)
├── frontend/
│   ├── index.html                   # Landing page
│   ├── auth.html                    # Register / Login
│   └── book.html                    # Book a Pass (4-step booking flow)
└── docs/
    ├── Architectural Diagram.jpg    # Full AWS architecture diagram
    └── /                            # Deployment 
```

---

## Infrastructure Details

### Networking
| Resource | Value |
|---|---|
| VPC CIDR | 10.0.0.0/16 |
| Public Subnet A | 10.0.1.0/24 — EC2, NAT Gateway — us-east-1a |
| Public Subnet B | 10.0.2.0/24 — EC2 — us-east-1b |
| Private Subnet A | 10.0.3.0/24 — RDS Primary — us-east-1a |
| Private Subnet B | 10.0.4.0/24 — RDS Standby — us-east-1b |

### Security Groups (Least Privilege)
| Security Group | Inbound Rule |
|---|---|
| **ALB-SG** | Port 80/443 from internet (0.0.0.0/0) |
| **EC2-SG** | Port 80 from ALB-SG only. Port 22 locked to deployer IP. |
| **RDS-SG** | Port 3306 from EC2-SG only. No internet access. |

### High Availability
- EC2 instances deployed across **2 Availability Zones** via Auto Scaling Group
- **Auto Scaling:** Min 1 → Desired 2 → Max 3 instances
- **CloudWatch CPU alarm** triggers scale-up at 75% utilization
- **RDS Multi-AZ:** automatic failover to standby if primary fails
- **ALB health checks** route traffic away from unhealthy instances automatically

---

## Application

### Frontend (S3 + CloudFront)
Three-page HTML/CSS/JS application served as static files from S3 via CloudFront:
- **Landing Page** (`index.html`) — routes overview, features, how it works
- **Auth Page** (`auth.html`) — register and login with client-side validation
- **Booking Page** (`book.html`) — 4-step booking flow: route selection → pass type → travel dates → confirmation

### Backend (Flask on EC2)
Python Flask REST API with the following endpoints:

| Method | Endpoint | Description |
|---|---|---|
| GET | `/health` | ALB health check |
| POST | `/register` | Create new user account |
| POST | `/login` | Authenticate user |
| POST | `/book` | Create a new bus pass booking |
| GET | `/passes/<user_id>` | Get all passes for a user |

### Database Schema (RDS MySQL)
```sql
users (id, full_name, email, password, created_at)
bus_passes (id, user_id, route, pass_type, start_date, expiry_date, status)
bookings (id, user_id, pass_id, booking_date, amount, payment_status)
```

---

## Deployment Guide

### Prerequisites
- AWS CLI configured with IAM credentials (`aws configure`)
- Terraform installed
- EC2 Key Pair created in AWS Console

### 1. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform apply
```

Terraform will output:
```
alb_dns_name      = "your-alb-dns.us-east-1.elb.amazonaws.com"
rds_endpoint      = "your-db.us-east-1.rds.amazonaws.com:3306"
cloudfront_domain = "xxxxxx.cloudfront.net"
```

### 2. Create Database Schema
```bash
# SSH into EC2
ssh -i buspass-key.pem ec2-user@<EC2_PUBLIC_IP>

# Connect to RDS from EC2
mysql -h <RDS_ENDPOINT> -u admin -p

# Run schema
CREATE DATABASE buspassdb;
USE buspassdb;
-- (run full schema from app/schema.sql)
```

### 3. Deploy Flask Backend
```bash
# Inside EC2
export DB_HOST="your-rds-endpoint"
export DB_USER="admin"
export DB_PASS="yourpassword"

nohup sudo -E python3 /var/www/buspass/app.py > /var/log/buspass.log 2>&1 &

# Verify
curl http://localhost/health
```

### 4. Upload Frontend to S3
```bash
# Update API_BASE in auth.html and book.html with your ALB DNS first, then:
aws s3 cp frontend/index.html s3://your-bucket-name/
aws s3 cp frontend/auth.html  s3://your-bucket-name/
aws s3 cp frontend/book.html  s3://your-bucket-name/

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

### 5. Verify End-to-End
```bash
# Test API through ALB
curl http://your-alb-dns/health
# Expected: {"status": "healthy"}

# Test registration
curl -X POST http://your-alb-dns/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@test.com","password":"pass123"}'

# Open browser → CloudFront URL → complete full booking flow
```

---

## Screenshots

| Step | Screenshot |
|---|---|
| VPC and subnets created | [docs/vpc.jpg](docs/vpc.jpg) |
| RDS instance available | [docs/rds.jpg](docs/rds.jpg) |
| EC2 Auto Scaling Group healthy | [docs/asg.jpg](docs/asg.jpg) |
| ALB active with healthy targets | [docs/alb.jpg](docs/alb.jpg) |
| CloudFront distribution deployed | [docs/cloudfront.jpg](docs/cloudfront.jpg) |
| Flask health check via ALB | [docs/health-check.jpg](docs/health-check.jpg) |
| Full booking flow in browser | [docs/booking-1.jpg](docs/booking-1.jpg) |
| RDS showing inserted data | [docs/rds-data.jpg](docs/rds-data-1.jpg) |
| Live Demo - full booking flow | [![Demo Video](https://img.shields.io/badge/Watch-Demo-red)](https://onedrive.live.com/?qt=allmyphotos&photosData=%2Fshare%2F3169724B9B4E50FC%21s69f6dcd05ead42bf80d63dd8f489dfc7%3Fithint%3Dvideo%26e%3DgKcWtc%26migratedtospo%3Dtrue&cid=3169724B9B4E50FC&id=3169724B9B4E50FC%21s69f6dcd05ead42bf80d63dd8f489dfc7&redeem=aHR0cHM6Ly8xZHJ2Lm1zL3YvYy8zMTY5NzI0YjliNGU1MGZjL0lRRFEzUFpwclY2X1FvRFdQZGowaWRfSEFad2FtM2U1bkYtMFMtczdRaVJMRmwwP2U9Z0tjV3Rj&v=photos)

---

*Deployed on AWS · Provisioned with Terraform · Secured with AWS Security Services · CodeAlpha Cloud Computing Internship*
