# DevOps Practice - Spring Boot on AWS EKS

Complete production-ready infrastructure and CI/CD pipeline demonstrating modern DevOps practices with GitHub Actions, Terraform, Kubernetes, and AWS.

## 🏗️ Architecture

```
GitHub Actions CI/CD
    ↓
Docker Build → Amazon ECR
    ↓
kubectl deploy → Amazon EKS
    ↓
AWS Load Balancer Controller → Application Load Balancer
    ↓
Internet Traffic → Spring Boot Application
```

## 📦 Infrastructure Components

### AWS Resources (53 total)
- **VPC** (10.0.0.0/16)
  - 2 Public Subnets (us-east-2a, us-east-2b)
  - 2 Private Subnets (us-east-2a, us-east-2b)
  - NAT Gateway for private subnet internet access
  - Internet Gateway for public access
  
- **EKS Cluster** (Kubernetes 1.31)
  - 2x t3.small nodes (2 vCPU, 2GB RAM each)
  - Add-ons: VPC CNI, CoreDNS, kube-proxy, EBS CSI Driver
  - KMS encryption for secrets
  - OIDC provider for IRSA
  
- **ECR Repository**
  - Private container registry
  - Image scanning enabled
  - Lifecycle policy (retain 10 images)
  
- **AWS Load Balancer Controller**
  - Automatic ALB provisioning from Kubernetes Ingress
  - Health checks, path-based routing
  - Integration with ACM, WAF, Shield

### Application
- **Spring Boot 3.2** REST API
- **Java 17** runtime
- **Maven** build system
- **Actuator** health checks
- **Multi-stage Docker** build

## 💰 Cost Breakdown

| Resource | Monthly Cost |
|----------|-------------|
| VPC (NAT Gateway) | $36 |
| EKS Control Plane | $73 |
| 2x t3.small nodes | $30 |
| EBS Storage (40GB) | $7 |
| Application Load Balancer | $18-25 |
| **Total** | **~$164-171/month** |

## 🚀 Deployment Status

### ✅ Completed
- [x] Terraform infrastructure deployed (53 AWS resources)
- [x] VPC with public/private subnets
- [x] EKS cluster with Kubernetes 1.31
- [x] ECR container registry
- [x] All EKS add-ons installed (VPC CNI, CoreDNS, kube-proxy, EBS CSI)
- [x] AWS Load Balancer Controller installed via Helm
- [x] kubectl configured for cluster access
- [x] Spring Boot application created
- [x] Dockerfile with multi-stage build
- [x] Kubernetes manifests (Deployment, Service, Ingress)
- [x] GitHub Actions CI/CD workflow

### 🔄 Next Steps

#### 1. Start Docker Desktop
Docker Desktop was installed but requires:
1. Restart your computer
2. Start Docker Desktop manually
3. Wait for Docker daemon to start

#### 2. Build and Push Initial Image (Manual)
```powershell
# Authenticate to ECR
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 676206948248.dkr.ecr.us-east-2.amazonaws.com

# Build the image
cd app
docker build -t 676206948248.dkr.ecr.us-east-2.amazonaws.com/dev-devops-practice-app:v1.0.0 .

# Push to ECR
docker push 676206948248.dkr.ecr.us-east-2.amazonaws.com/dev-devops-practice-app:v1.0.0
docker tag 676206948248.dkr.ecr.us-east-2.amazonaws.com/dev-devops-practice-app:v1.0.0 676206948248.dkr.ecr.us-east-2.amazonaws.com/dev-devops-practice-app:latest
docker push 676206948248.dkr.ecr.us-east-2.amazonaws.com/dev-devops-practice-app:latest
```

#### 3. Deploy to Kubernetes
```powershell
# Verify cluster access
kubectl get nodes

# Apply manifests
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

# Check deployment status
kubectl get pods -w
kubectl get ingress

# Get ALB URL (takes 2-3 minutes to provision)
kubectl get ingress devops-practice-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

#### 4. Setup GitHub Repository
```powershell
# Initialize git (if not already done)
git init
git add .
git commit -m "Initial commit - Complete DevOps infrastructure"

# Create GitHub repository and push
git remote add origin https://github.com/YOUR_USERNAME/devops-practice.git
git branch -M main
git push -u origin main
```

#### 5. Configure GitHub Secrets
Add these secrets in your GitHub repository:
- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key

#### 6. Trigger CI/CD Pipeline
Once GitHub secrets are configured, any push to `main` branch will:
1. Build Docker image
2. Push to ECR
3. Deploy to EKS
4. Output the ALB URL

## 🔍 Verification

### Check Infrastructure
```powershell
# Refresh PATH and check cluster
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
```

### Check Load Balancer Controller
```powershell
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### Test Application
Once deployed, test the endpoints:
```powershell
# Get ALB hostname
$ALB_URL = kubectl get ingress devops-practice-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Test endpoints
curl "http://$ALB_URL/api/hello"
curl "http://$ALB_URL/actuator/health"
```

Expected response:
```json
{
  "message": "Hello from Spring Boot on EKS!",
  "timestamp": "2025-10-27T21:15:00",
  "version": "1.0.0",
  "environment": "production"
}
```

## 📊 Monitoring

### View Logs
```powershell
# Application logs
kubectl logs -l app=devops-practice-app -f

# Load Balancer Controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -f
```

### Check Resource Usage
```powershell
kubectl top nodes
kubectl top pods
```

## 🛠️ Terraform Management

### View State
```powershell
cd terraform/environments/dev
terraform state list
terraform output
```

### Update Infrastructure
```powershell
# Make changes to .tf files
terraform plan
terraform apply -auto-approve
```

### Destroy (when done)
```powershell
# Delete Kubernetes resources first
kubectl delete -f k8s/

# Destroy Terraform infrastructure
cd terraform/environments/dev
terraform destroy -auto-approve
```

## 📚 Documentation

- [AWS Load Balancer Controller Guide](./AWS_LOAD_BALANCER_CONTROLLER.md)
- [EKS Cost Breakdown](./EKS_COST_BREAKDOWN.md)
- [ECR Explained](./ECR_EXPLAINED.md)
- [GitHub Actions & Terraform Practice](./GitHub_Actions_Terraform_Practice.md)
- [Interview Preparation](./Interview_Preparation_Guide.md)

## 🔐 Security Best Practices Implemented

- ✅ KMS encryption for EKS secrets
- ✅ IRSA (IAM Roles for Service Accounts) for pod permissions
- ✅ Non-root container user (UID 1001)
- ✅ Security groups with minimal required access
- ✅ Private subnets for worker nodes
- ✅ IMDSv2 enforced on EC2 instances
- ✅ ECR image scanning enabled
- ✅ Network policies ready (VPC CNI supports)

## 🎯 Skills Demonstrated

This project showcases expertise in:
- **Terraform** - Infrastructure as Code with modules
- **Kubernetes** - EKS cluster management, deployments, services, ingress
- **Docker** - Multi-stage builds, optimization, security
- **GitHub Actions** - CI/CD pipeline automation
- **AWS** - VPC, EKS, ECR, ALB, IAM, KMS
- **Spring Boot** - REST API development
- **DevOps** - End-to-end deployment automation
- **Security** - IRSA, encryption, least privilege

## 📞 Support

For issues or questions:
1. Check logs: `kubectl logs -l app=devops-practice-app`
2. Check ALB controller: `kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller`
3. Verify infrastructure: `terraform output`
4. Check AWS Console for resource status

## 📝 Notes

- **Region**: us-east-2 (Ohio)
- **Cluster**: dev-eks-cluster
- **ECR**: 676206948248.dkr.ecr.us-east-2.amazonaws.com/dev-devops-practice-app
- **State**: Local (terraform.tfstate in dev environment)

---

**Status**: Infrastructure deployed, application code ready, awaiting Docker build and first deployment.

**Next Action**: Restart computer → Start Docker Desktop → Build & push image → Deploy to EKS → Setup GitHub CI/CD
#   C I / C D   T e s t  
 