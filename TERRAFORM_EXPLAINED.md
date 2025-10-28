# Terraform VPC - Complete Line-by-Line Explanation

## 📁 Project Structure

```
terraform/
├── modules/
│   └── vpc/                    # Reusable VPC module
│       ├── main.tf            # VPC resources (what to create)
│       ├── variables.tf       # Input parameters (what can be customized)
│       └── outputs.tf         # Return values (what to expose)
└── environments/
    └── dev/                   # Dev environment configuration
        ├── backend.tf         # Where to store state file
        ├── main.tf            # Uses the VPC module
        ├── variables.tf       # Dev-specific variable definitions
        ├── outputs.tf         # Dev-specific outputs
        └── terraform.tfvars   # Dev-specific values (DO NOT commit secrets here!)
```

---

## 🔍 Line-by-Line Explanation

### 1️⃣ **backend.tf** - Where Terraform Stores State

```hcl
terraform {
  backend "s3" {
    bucket         = "devops-practice-terraform-state-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-dev"
  }
}
```

**Line-by-line:**
- `terraform {` - Terraform configuration block
- `backend "s3" {` - Store state file in AWS S3 (NOT on your laptop!)
- `bucket = "..."` - S3 bucket name (you need to create this FIRST manually)
- `key = "dev/terraform.tfstate"` - File path inside the bucket
- `region = "us-east-2"` - AWS region where S3 bucket exists
- `encrypt = true` - Encrypt the state file at rest (security best practice)
- `dynamodb_table = "..."` - DynamoDB table for state locking (prevents concurrent changes)

**Why this matters:**
- ✅ State is shared across team members
- ✅ Prevents two people from running terraform at the same time (locking)
- ✅ State is encrypted and backed up
- ❌ Without this, state is stored locally on your laptop (bad for teams!)

**What you need to create FIRST (one-time setup):**
```bash
# Create S3 bucket for state
aws s3 mb s3://devops-practice-terraform-state-dev --region us-east-2

# Enable versioning (so you can recover from mistakes)
aws s3api put-bucket-versioning \
  --bucket devops-practice-terraform-state-dev \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-state-lock-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-2
```

---

### 2️⃣ **main.tf** (environment) - The Orchestrator

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

**Line-by-line:**
- `required_version = ">= 1.5.0"` - Minimum Terraform version (ensures compatibility)
- `required_providers {` - Which plugins to download
- `source = "hashicorp/aws"` - Official AWS provider from HashiCorp
- `version = "~> 5.0"` - Use version 5.x.x (but not 6.0)

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "DevOps-Practice"
    }
  }
}
```

**Line-by-line:**
- `provider "aws" {` - Configure AWS provider
- `region = var.aws_region` - Use us-east-2 (from variables)
- `default_tags {` - Tags automatically added to ALL resources
- `Environment = var.environment` - Tags each resource with "dev"
- `ManagedBy = "Terraform"` - So you know it was created by Terraform
- `Project = "DevOps-Practice"` - For cost tracking/organization

```hcl
module "vpc" {
  source = "../../modules/vpc"

  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  availability_zones      = var.availability_zones
  private_subnet_cidrs    = var.private_subnet_cidrs
  public_subnet_cidrs     = var.public_subnet_cidrs
  enable_nat_gateway      = var.enable_nat_gateway
  single_nat_gateway      = var.single_nat_gateway
  enable_internet_gateway = var.enable_internet_gateway
  enable_vpc_endpoints    = var.enable_vpc_endpoints

  tags = var.tags
}
```

**Line-by-line:**
- `module "vpc" {` - Create a VPC using our reusable module
- `source = "../../modules/vpc"` - Path to the VPC module folder
- `environment = var.environment` - Pass "dev" to the module
- `vpc_cidr = var.vpc_cidr` - Pass "10.0.0.0/16" to the module
- etc. - Pass all configuration to the module

**This is like calling a function:**
```javascript
// Similar to:
createVPC({
  environment: "dev",
  vpc_cidr: "10.0.0.0/16",
  availability_zones: ["us-east-2a", "us-east-2b"],
  // ...
})
```

---

### 3️⃣ **variables.tf** (environment) - Input Definitions

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}
```

**Line-by-line:**
- `variable "aws_region" {` - Define a variable named "aws_region"
- `description = "..."` - Documentation (what is this for?)
- `type = string` - Must be a string (not a number or list)
- `default = "us-east-2"` - Default value if not specified

**This defines the INPUT contract** - what values can be passed in.

```hcl
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}
```

**CIDR Explanation:**
- `10.0.0.0/16` = IP range from 10.0.0.0 to 10.0.255.255
- `/16` = First 16 bits are fixed (10.0), last 16 bits are variable
- Provides 65,536 IP addresses (2^16)

```hcl
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}
```

**Availability Zones:**
- `us-east-2a` = Data center 1 in Ohio region
- `us-east-2b` = Data center 2 in Ohio region (physically separate)
- Using 2 AZs = High availability (if one fails, other still works)

```hcl
variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}
```

**Private Subnets:**
- `10.0.1.0/24` = 256 IPs (10.0.1.0 - 10.0.1.255) in AZ-a
- `10.0.2.0/24` = 256 IPs (10.0.2.0 - 10.0.2.255) in AZ-b
- `/24` = 24 bits fixed, 8 bits variable (2^8 = 256 IPs)
- Used for: EKS nodes, databases (no public IP)

```hcl
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}
```

**Public Subnets:**
- `10.0.101.0/24` = 256 IPs in AZ-a
- `10.0.102.0/24` = 256 IPs in AZ-b
- Used for: NAT Gateway, Load Balancers (have public IP)

---

### 4️⃣ **terraform.tfvars** - Actual Values (SENSITIVE!)

```hcl
aws_region         = "us-east-2"
environment        = "dev"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-2a", "us-east-2b"]
```

**This file contains ACTUAL VALUES:**
- Not committed to git if it contains secrets!
- Can be different for dev/staging/prod
- Overrides defaults in variables.tf

```hcl
# Private subnets for EKS nodes (your application)
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

# Public subnets for NAT Gateway and Load Balancers
public_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
```

**Comments explain the PURPOSE** of each value.

```hcl
enable_nat_gateway      = true   # For outbound internet access
enable_internet_gateway = true   # Required for NAT Gateway to work
single_nat_gateway      = true   # Cost optimization for dev
enable_vpc_endpoints    = false  # Not needed for now
```

**Flags control what gets created:**
- `enable_nat_gateway = true` → Creates NAT Gateway resource
- `enable_nat_gateway = false` → Skips NAT Gateway creation

---

### 5️⃣ **VPC Module - main.tf** (THE MEAT!)

#### VPC Creation

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    {
      Name        = "${var.environment}-vpc"
      Environment = var.environment
    },
    var.tags
  )
}
```

**Line-by-line:**
- `resource "aws_vpc" "main" {` - Create an AWS VPC resource, name it "main" in Terraform
- `cidr_block = var.vpc_cidr` - Set IP range to 10.0.0.0/16
- `enable_dns_hostnames = true` - Instances get DNS names (ec2-x-x-x-x.compute.amazonaws.com)
- `enable_dns_support = true` - Enable DNS resolution in VPC
- `tags = merge(...)` - Combine default tags + custom tags
- `Name = "${var.environment}-vpc"` - Tag as "dev-vpc"

**What this creates in AWS:**
```
VPC ID: vpc-0abc123def456
CIDR: 10.0.0.0/16
DNS: Enabled
Tags: Name=dev-vpc, Environment=dev, ManagedBy=Terraform
```

#### Internet Gateway

```hcl
resource "aws_internet_gateway" "main" {
  count  = var.enable_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name        = "${var.environment}-igw"
      Environment = var.environment
    },
    var.tags
  )
}
```

**Line-by-line:**
- `count = var.enable_internet_gateway ? 1 : 0` - **Conditional creation!**
  - If `enable_internet_gateway = true` → Create 1 IGW
  - If `enable_internet_gateway = false` → Create 0 IGW (skip it!)
- `vpc_id = aws_vpc.main.id` - Attach to the VPC we created above
- `aws_vpc.main.id` - Reference to the VPC resource (creates dependency)

**What this creates:**
```
Internet Gateway ID: igw-0abc123
Attached to: vpc-0abc123def456
Purpose: Gateway to the internet
```

#### Private Subnets

```hcl
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      Name                              = "${var.environment}-private-subnet-${count.index + 1}"
      Environment                       = var.environment
      Type                              = "private"
      "kubernetes.io/role/internal-elb" = "1"
    },
    var.tags
  )
}
```

**Line-by-line:**
- `count = length(var.private_subnet_cidrs)` - Create 2 subnets (length of array = 2)
- `count.index` - Loop counter (0, 1)
  - When count.index = 0 → Use `private_subnet_cidrs[0]` = "10.0.1.0/24"
  - When count.index = 1 → Use `private_subnet_cidrs[1]` = "10.0.2.0/24"
- `availability_zone = var.availability_zones[count.index]`
  - Subnet 0 → us-east-2a
  - Subnet 1 → us-east-2b
- `"kubernetes.io/role/internal-elb" = "1"` - **Special tag for EKS!**
  - Tells EKS: "Use these subnets for internal load balancers"

**What this creates:**
```
Subnet 1:
  ID: subnet-0abc111
  CIDR: 10.0.1.0/24 (256 IPs)
  AZ: us-east-2a
  Type: Private
  Tags: Name=dev-private-subnet-1, kubernetes.io/role/internal-elb=1

Subnet 2:
  ID: subnet-0abc222
  CIDR: 10.0.2.0/24 (256 IPs)
  AZ: us-east-2b
  Type: Private
  Tags: Name=dev-private-subnet-2, kubernetes.io/role/internal-elb=1
```

#### Public Subnets

```hcl
resource "aws_subnet" "public" {
  count             = var.enable_internet_gateway ? length(var.public_subnet_cidrs) : 0
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = merge(
    {
      Name                        = "${var.environment}-public-subnet-${count.index + 1}"
      Environment                 = var.environment
      Type                        = "public"
      "kubernetes.io/role/elb"    = "1"
    },
    var.tags
  )
}
```

**Key difference from private:**
- `map_public_ip_on_launch = true` - **Instances automatically get public IP!**
- `"kubernetes.io/role/elb" = "1"` - For **public** load balancers

#### NAT Gateway

```hcl
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]
}
```

**Line-by-line:**
- `count = ...` - **Complex conditional!**
  - If NAT disabled → 0 EIPs
  - If single NAT → 1 EIP
  - If multi-AZ NAT → 2 EIPs (one per AZ)
- `domain = "vpc"` - Elastic IP for VPC (not EC2-Classic)
- `depends_on = [aws_internet_gateway.main]` - **Must create IGW first!**
  - Terraform will wait for IGW before creating EIP

```hcl
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.main]
}
```

**Line-by-line:**
- `allocation_id = aws_eip.nat[count.index].id` - Use the EIP we created above
- `subnet_id = aws_subnet.public[count.index].id` - **NAT goes in PUBLIC subnet!**

**What this creates (single_nat_gateway = true):**
```
Elastic IP:
  IP Address: 3.141.59.26 (example)
  
NAT Gateway:
  ID: nat-0abc123
  Elastic IP: 3.141.59.26
  Subnet: subnet-0abc333 (public subnet 1)
  Purpose: Allows private subnet to reach internet
```

#### Route Tables

```hcl
resource "aws_route_table" "public" {
  count  = var.enable_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name        = "${var.environment}-public-rt"
      Environment = var.environment
      Type        = "public"
    },
    var.tags
  )
}

resource "aws_route" "public_internet_gateway" {
  count                  = var.enable_internet_gateway ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id
}
```

**What this means:**
- **Route Table** = Routing rules for a subnet
- `destination_cidr_block = "0.0.0.0/0"` - **"All internet traffic"**
- `gateway_id = aws_internet_gateway.main[0].id` - **"Send to Internet Gateway"**

**Translation:**
```
Public Route Table:
  Rule: If destination is 0.0.0.0/0 (internet) → Send to IGW
  
Example:
  Instance in public subnet wants to reach 8.8.8.8 (Google DNS)
  → Matches 0.0.0.0/0 rule → Routed to Internet Gateway → Internet
```

```hcl
resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 1
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "private_nat_gateway" {
  count                  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}
```

**Translation:**
```
Private Route Table:
  Rule: If destination is 0.0.0.0/0 (internet) → Send to NAT Gateway
  
Example:
  EKS pod (10.0.1.50) wants to pull image from ECR
  → Matches 0.0.0.0/0 rule → Routed to NAT Gateway → NAT → IGW → Internet
```

#### Route Table Associations

```hcl
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.enable_nat_gateway ? (var.single_nat_gateway ? 0 : count.index) : 0].id
}
```

**What this does:**
- **Associates** route table with subnet
- Subnet 1 (10.0.1.0/24) → Use private route table
- Subnet 2 (10.0.2.0/24) → Use private route table

**If single_nat_gateway = true:**
- Both private subnets use the SAME route table (index 0)

**If single_nat_gateway = false:**
- Private subnet 1 → Route table 1 → NAT 1
- Private subnet 2 → Route table 2 → NAT 2

---

### 6️⃣ **outputs.tf** - What to Expose

```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}
```

**Line-by-line:**
- `output "vpc_id" {` - Define an output named "vpc_id"
- `value = aws_vpc.main.id` - Return the VPC ID (e.g., vpc-0abc123)

**Why outputs matter:**
- Other modules (like EKS) need the VPC ID
- You can see outputs after `terraform apply`
- Can be referenced: `module.vpc.vpc_id`

```hcl
output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}
```

**Line-by-line:**
- `aws_subnet.private[*].id` - **The `[*]` means "all of them"**
- Returns: `["subnet-0abc111", "subnet-0abc222"]`

**Used by EKS module:**
```hcl
# In EKS module
subnet_ids = module.vpc.private_subnet_ids
# EKS will create nodes in both subnets
```

---

## 🔐 AWS Credentials - Best Practices

### ❌ **NEVER DO THIS:**
```hcl
# DON'T HARDCODE CREDENTIALS!
provider "aws" {
  access_key = "AKIAIOSFODNN7EXAMPLE"  # ❌ NO!
  secret_key = "wJalrXUtnFEMI/..."     # ❌ NO!
  region     = "us-east-2"
}
```

### ✅ **Best Practices (in order of preference):**

#### **1. IAM Roles (Best for Production)**
```hcl
# If running in AWS (EKS, EC2, Lambda)
provider "aws" {
  region = "us-east-2"
  # No credentials needed! Uses instance role automatically
}
```

**How it works:**
- GitHub Actions → Assumes IAM role via OIDC
- No secrets stored in code or CI/CD
- Temporary credentials (expire in 1 hour)

**Setup:**
```yaml
# In GitHub Actions
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
    aws-region: us-east-2
```

#### **2. AWS CLI Credentials (Best for Local Development)**
```bash
# Configure AWS CLI once
aws configure

# This creates ~/.aws/credentials:
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/...
region = us-east-2
```

**Terraform automatically uses these:**
```hcl
provider "aws" {
  region = "us-east-2"
  # Reads from ~/.aws/credentials automatically
}
```

#### **3. Environment Variables (Good for CI/CD)**
```bash
# Set environment variables
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/..."
export AWS_DEFAULT_REGION="us-east-2"

# Terraform reads these automatically
terraform apply
```

**In GitHub Actions:**
```yaml
env:
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  AWS_REGION: us-east-2
```

#### **4. Named Profiles (Multiple AWS Accounts)**
```bash
# ~/.aws/credentials
[dev]
aws_access_key_id = AKIA...DEV
aws_secret_access_key = ...

[prod]
aws_access_key_id = AKIA...PROD
aws_secret_access_key = ...
```

```hcl
# Use specific profile
provider "aws" {
  region  = "us-east-2"
  profile = "dev"
}
```

---

## 🚀 How to Run Terraform

### **Step 1: Create S3 Backend (ONE TIME ONLY)**
```bash
# Create S3 bucket
aws s3 mb s3://devops-practice-terraform-state-dev --region us-east-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket devops-practice-terraform-state-dev \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket devops-practice-terraform-state-dev \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-state-lock-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-2
```

### **Step 2: Navigate to Environment**
```bash
cd terraform/environments/dev
```

### **Step 3: Initialize Terraform**
```bash
terraform init
```

**What this does:**
- Downloads AWS provider plugin
- Configures S3 backend
- Creates `.terraform/` directory

**Output:**
```
Initializing the backend...
Successfully configured the backend "s3"!

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.70.0...

Terraform has been successfully initialized!
```

### **Step 4: Plan (Preview Changes)**
```bash
terraform plan
```

**What this does:**
- Shows what will be created/changed/destroyed
- Does NOT make any changes
- Like a "dry run"

**Output:**
```
Terraform will perform the following actions:

  # module.vpc.aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + cidr_block = "10.0.0.0/16"
      + id         = (known after apply)
      ...
    }

  # module.vpc.aws_subnet.private[0] will be created
  ...

Plan: 15 to add, 0 to change, 0 to destroy.
```

### **Step 5: Apply (Create Resources)**
```bash
terraform apply
```

**What this does:**
- Shows plan again
- Asks for confirmation (`yes`)
- Creates all resources in AWS
- Saves state to S3

**Output:**
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.vpc.aws_vpc.main: Creating...
module.vpc.aws_vpc.main: Creation complete after 3s [id=vpc-0abc123]
...

Apply complete! Resources: 15 added, 0 changed, 0 destroyed.

Outputs:

vpc_id = "vpc-0abc123def456"
private_subnet_ids = [
  "subnet-0abc111",
  "subnet-0abc222",
]
...
```

### **Step 6: View Outputs**
```bash
terraform output
```

**Output:**
```
private_subnet_ids = [
  "subnet-0abc111",
  "subnet-0abc222",
]
vpc_id = "vpc-0abc123def456"
```

### **Step 7: Destroy (Clean Up)**
```bash
terraform destroy
```

**What this does:**
- Deletes ALL resources
- Use carefully in production!

---

## 🎯 Common Commands

```bash
# Format code
terraform fmt -recursive

# Validate syntax
terraform validate

# Show current state
terraform show

# List resources
terraform state list

# Target specific resource
terraform apply -target=module.vpc.aws_vpc.main

# Use different var file
terraform apply -var-file="production.tfvars"

# Auto-approve (use in CI/CD only)
terraform apply -auto-approve
```

---

## 🔒 Security Best Practices Summary

1. ✅ **Never commit secrets** to git
2. ✅ **Use IAM roles** instead of access keys (when possible)
3. ✅ **Store state in S3** with encryption
4. ✅ **Enable state locking** with DynamoDB
5. ✅ **Use `.gitignore`** for sensitive files
6. ✅ **Rotate credentials** regularly
7. ✅ **Use separate AWS accounts** for dev/staging/prod
8. ✅ **Enable CloudTrail** to audit Terraform actions

**What to add to `.gitignore`:**
```
# Terraform
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars    # If it contains secrets!
.terraform.lock.hcl

# AWS
.aws/
credentials
```

---

## 📊 What Gets Created

```
Resources Created in us-east-2:

VPC (vpc-0abc123)
├── CIDR: 10.0.0.0/16
├── DNS: Enabled
│
├── Internet Gateway (igw-0abc123)
│
├── Private Subnets (2)
│   ├── subnet-0abc111 (10.0.1.0/24) in us-east-2a
│   └── subnet-0abc222 (10.0.2.0/24) in us-east-2b
│
├── Public Subnets (2)
│   ├── subnet-0abc333 (10.0.101.0/24) in us-east-2a
│   └── subnet-0abc444 (10.0.102.0/24) in us-east-2b
│
├── NAT Gateway (1)
│   └── nat-0abc555 in subnet-0abc333 with EIP 3.141.59.26
│
├── Route Tables (2)
│   ├── Public RT: 0.0.0.0/0 → Internet Gateway
│   └── Private RT: 0.0.0.0/0 → NAT Gateway
│
└── VPC Flow Logs
    └── Log Group: /aws/vpc/dev-flow-logs
```

---

Ready to run it? Want me to create the ECR module next? 🚀
