aws_region         = "us-east-2"
environment        = "dev"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-2a", "us-east-2b"]

# Private subnets for EKS nodes (your application)
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

# Public subnets for NAT Gateway and Load Balancers
public_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]

# Simplified Configuration - NAT Gateway Only
enable_nat_gateway      = true   # For outbound internet access
enable_internet_gateway = true   # Required for NAT Gateway to work
single_nat_gateway      = true   # Cost optimization for dev ($32/month vs $96/month)
enable_vpc_endpoints    = false  # Not needed for now (can add later)

tags = {
  Owner      = "DevOps-Team"
  CostCenter = "Engineering"
}
