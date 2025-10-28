# Quick Start - Terraform VPC (Local State)

## 🚀 Simple Setup (No S3/DynamoDB Required)

### Prerequisites
1. **AWS CLI configured** with credentials
2. **Terraform installed** (v1.5.0+)

### Step 1: Configure AWS Credentials

**Option 1: Using AWS CLI (Recommended for local dev)**
```bash
aws configure
```

Enter:
- AWS Access Key ID: `AKIA...` (get from IAM Console)
- AWS Secret Access Key: `...` (get from IAM Console)
- Default region: `us-east-2`
- Default output format: `json`

This creates `~/.aws/credentials` file that Terraform uses automatically.

**Option 2: Environment Variables**
```powershell
# PowerShell
$env:AWS_ACCESS_KEY_ID="AKIA..."
$env:AWS_SECRET_ACCESS_KEY="..."
$env:AWS_DEFAULT_REGION="us-east-2"
```

### Step 2: Navigate to Dev Environment
```powershell
cd C:\Users\klejd\Desktop\devops-practice\terraform\environments\dev
```

### Step 3: Initialize Terraform
```bash
terraform init
```

**What this does:**
- Downloads AWS provider plugin (~200MB)
- Creates `.terraform/` directory
- Prepares local state backend

**Expected output:**
```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.70.0...
- Installed hashicorp/aws v5.70.0

Terraform has been successfully initialized!
```

### Step 4: Preview What Will Be Created
```bash
terraform plan
```

**What this does:**
- Shows all resources that will be created
- Does NOT make any changes
- Like a "dry run"

**Expected output:**
```
Terraform will perform the following actions:

  # module.vpc.aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + cidr_block = "10.0.0.0/16"
      + id         = (known after apply)
      ...
    }

  # module.vpc.aws_internet_gateway.main[0] will be created
  ...

  # module.vpc.aws_subnet.private[0] will be created
  ...

Plan: 18 to add, 0 to change, 0 to destroy.
```

### Step 5: Create the VPC
```bash
terraform apply
```

**What this does:**
- Shows the plan again
- Asks for confirmation
- Creates resources in AWS
- Saves state to local file `terraform.tfstate`

**You'll see:**
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: 
```

Type `yes` and press Enter.

**Expected output:**
```
module.vpc.aws_vpc.main: Creating...
module.vpc.aws_vpc.main: Creation complete after 3s [id=vpc-0abc123]
module.vpc.aws_internet_gateway.main[0]: Creating...
module.vpc.aws_internet_gateway.main[0]: Creation complete after 2s
module.vpc.aws_subnet.private[0]: Creating...
module.vpc.aws_subnet.private[1]: Creating...
...

Apply complete! Resources: 18 added, 0 changed, 0 destroyed.

Outputs:

vpc_id = "vpc-0abc123def456"
private_subnet_ids = [
  "subnet-0abc111",
  "subnet-0abc222",
]
public_subnet_ids = [
  "subnet-0abc333",
  "subnet-0abc444",
]
```

### Step 6: Verify in AWS Console

Go to AWS Console → VPC → Your VPCs

You should see:
- ✅ VPC: `dev-vpc` (10.0.0.0/16)
- ✅ Subnets: 4 subnets (2 private, 2 public)
- ✅ Internet Gateway: `dev-igw`
- ✅ NAT Gateway: `dev-nat-gateway-1`
- ✅ Route Tables: 2 route tables

---

## 📊 What Gets Created

### Network Resources (us-east-2)
```
VPC: dev-vpc
├── CIDR: 10.0.0.0/16 (65,536 IPs)
├── Region: us-east-2 (Ohio)
│
├── Private Subnets (No internet access)
│   ├── 10.0.1.0/24 in us-east-2a (256 IPs) → For EKS nodes
│   └── 10.0.2.0/24 in us-east-2b (256 IPs) → For EKS nodes
│
├── Public Subnets (Internet-facing)
│   ├── 10.0.101.0/24 in us-east-2a (256 IPs) → For NAT Gateway, Load Balancer
│   └── 10.0.102.0/24 in us-east-2b (256 IPs) → For Load Balancer
│
├── Internet Gateway
│   └── Allows public subnets to reach internet
│
├── NAT Gateway (1)
│   ├── Located in: Public subnet (us-east-2a)
│   ├── Elastic IP: (assigned by AWS)
│   └── Purpose: Allows private subnets outbound internet
│
├── Route Tables
│   ├── Public Route Table
│   │   └── 0.0.0.0/0 → Internet Gateway
│   └── Private Route Table
│       └── 0.0.0.0/0 → NAT Gateway
│
└── VPC Flow Logs
    └── CloudWatch Log Group: /aws/vpc/dev-flow-logs
```

### Estimated Monthly Cost
```
NAT Gateway:     $32.85  (730 hours × $0.045/hour)
Data Processing: ~$5-10  (depends on usage)
VPC/Subnets:     FREE
Internet Gateway: FREE
Route Tables:    FREE
Flow Logs:       ~$0.50  (minimal logs)
─────────────────────────
TOTAL:           ~$38-43/month
```

---

## 🔍 View Outputs

```bash
# View all outputs
terraform output

# View specific output
terraform output vpc_id
```

**Output:**
```
vpc_id = "vpc-0abc123def456"
```

---

## 🛠️ Common Operations

### Make Changes
1. Edit `terraform.tfvars` or module files
2. Run `terraform plan` to preview
3. Run `terraform apply` to apply changes

### Destroy Everything
```bash
terraform destroy
```

**WARNING:** This deletes ALL resources! Use carefully.

---

## 📁 Local State Files

With local backend, Terraform creates these files:

```
terraform/environments/dev/
├── terraform.tfstate          ← Current state (DO NOT commit!)
├── terraform.tfstate.backup   ← Previous state (DO NOT commit!)
└── .terraform/
    └── providers/             ← Downloaded plugins
```

**Important:**
- ✅ `.gitignore` already configured to exclude these
- ❌ DO NOT commit `terraform.tfstate` to git (contains sensitive data!)
- ❌ DO NOT share state files (they contain resource IDs and metadata)
- ⚠️  If you delete state file, Terraform loses track of resources!

---

## 🔒 Local State Limitations

### ✅ Advantages (for learning/dev)
- Simple to get started
- No AWS setup required (S3/DynamoDB)
- Fast to iterate

### ❌ Disadvantages (for production)
- State file on your laptop only
- No team collaboration
- No state locking (concurrent changes can corrupt state)
- No automatic backups
- If you lose the file, you lose track of resources

### 📈 When to Upgrade to S3 Backend
Move to S3 backend when:
- Working in a team
- Deploying to production
- Need state locking
- Want automatic backups

---

## 🐛 Troubleshooting

### Error: No credentials found
```
Error: No valid credential sources found
```

**Solution:**
```bash
aws configure
# OR set environment variables
```

### Error: Region not set
```
Error: error configuring Terraform AWS Provider: region not found
```

**Solution:** Ensure region is set in `terraform.tfvars` or AWS CLI config

### Error: Permission denied
```
Error: creating VPC: UnauthorizedOperation
```

**Solution:** Ensure your AWS user has VPC permissions:
- AmazonVPCFullAccess policy
- OR EC2FullAccess policy

### State file locked
```
Error: state is locked
```

**Solution:** 
With local state, this shouldn't happen. If it does:
```bash
# Remove lock file
rm .terraform.tfstate.lock.info
```

---

## 🎯 Next Steps After VPC is Created

1. ✅ **View resources in AWS Console**
2. ✅ **Test VPC connectivity** (optional)
3. ✅ **Create ECR module** for Docker images
4. ✅ **Create EKS module** for Kubernetes cluster
5. ✅ **Deploy your application**

---

## 📚 Useful Commands

```bash
# Format Terraform files
terraform fmt -recursive

# Validate syntax
terraform validate

# Show current state
terraform show

# List all resources
terraform state list

# Show specific resource
terraform state show module.vpc.aws_vpc.main

# Refresh state (sync with AWS)
terraform refresh

# Import existing resource (if needed)
terraform import module.vpc.aws_vpc.main vpc-xxx
```

---

## 🔐 Security Checklist

- ✅ `.gitignore` configured to exclude state files
- ✅ `.gitignore` configured to exclude AWS credentials
- ✅ Using AWS CLI credentials (not hardcoded)
- ✅ VPC Flow Logs enabled for monitoring
- ✅ Private subnets for application workloads
- ✅ NAT Gateway for secure outbound access

---

Ready to create the VPC? Just run:

```bash
cd terraform/environments/dev
terraform init
terraform apply
```

🚀 **Let me know when you're ready for the ECR module!**
