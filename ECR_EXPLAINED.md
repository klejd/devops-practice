# ECR (Elastic Container Registry) - Complete Guide

## 🐳 What is ECR?

ECR is AWS's **private Docker registry** - like DockerHub, but private and integrated with AWS.

```
Think of it like this:
- DockerHub = Public apartment building (anyone can see your stuff)
- ECR = Your private storage unit (only you and authorized people have access)
```

---

## 🏗️ How ECR Works

### **1. ECR Repository Structure**

```
AWS Account: 123456789012
Region: us-east-2

ECR Registry URL: 123456789012.dkr.ecr.us-east-2.amazonaws.com
│
├── Repository: dev-devops-practice-app
│   ├── Image: latest
│   ├── Image: v1.0.0
│   ├── Image: v1.0.1
│   ├── Image: abc123def (commit hash)
│   └── Image: pr-42
│
├── Repository: staging-devops-practice-app
│   ├── Image: latest
│   ├── Image: v1.1.0
│   └── Image: v1.1.1
│
└── Repository: prod-devops-practice-app
    ├── Image: v1.0.0
    ├── Image: v1.0.1
    └── Image: v1.1.0
```

---

## 🎯 Our ECR Setup

### **Option 1: Separate Repositories Per Environment (What We're Using)**

```
Pros:
✅ Clear separation (dev images can't accidentally go to prod)
✅ Different retention policies per environment
✅ Better IAM permissions (dev team can only push to dev repo)
✅ Easier to clean up old dev images without affecting prod

Cons:
❌ Need to re-tag and push when promoting from dev → prod
❌ More repositories to manage
```

**Our Structure:**
```
dev-devops-practice-app       → For development testing
staging-devops-practice-app   → For QA/staging (future)
prod-devops-practice-app      → For production (future)
```

### **Option 2: Single Repository with Environment Tags**

```
Repository: devops-practice-app
├── Image: dev-latest
├── Image: dev-v1.0.0
├── Image: staging-v1.0.0
├── Image: prod-v1.0.0
└── Image: prod-latest

Pros:
✅ Single repository to manage
✅ Easy to promote (just re-tag the same image)

Cons:
❌ All environments share same retention policy
❌ Harder to control who can push where
❌ Dev and prod images mixed together
```

---

## 📊 Complete Image Lifecycle

### **1. Build Phase (GitHub Actions)**

```yaml
# In GitHub Actions CI/CD pipeline

- name: Build Docker Image
  run: |
    docker build -t myapp:${{ github.sha }} .
    # Creates image locally with commit hash as tag
```

### **2. Login to ECR**

```bash
# Get login token from ECR
aws ecr get-login-password --region us-east-2 | \
  docker login --username AWS \
    --password-stdin 123456789012.dkr.ecr.us-east-2.amazonaws.com
```

### **3. Tag Image for ECR**

```bash
# Your ECR repository URL
REPO_URL=123456789012.dkr.ecr.us-east-2.amazonaws.com/dev-devops-practice-app

# Tag the local image with ECR URL
docker tag myapp:abc123def $REPO_URL:abc123def
docker tag myapp:abc123def $REPO_URL:latest
docker tag myapp:abc123def $REPO_URL:v1.0.0
```

**Result:**
```
Local:
├── myapp:abc123def

ECR Repository: dev-devops-practice-app
├── 123456789012.dkr.ecr.us-east-2.amazonaws.com/dev-devops-practice-app:abc123def
├── 123456789012.dkr.ecr.us-east-2.amazonaws.com/dev-devops-practice-app:latest
└── 123456789012.dkr.ecr.us-east-2.amazonaws.com/dev-devops-practice-app:v1.0.0
```

### **4. Push to ECR**

```bash
# Push all tags
docker push $REPO_URL:abc123def
docker push $REPO_URL:latest
docker push $REPO_URL:v1.0.0
```

**What happens:**
```
1. Docker compresses image layers
2. Uploads to ECR (only changed layers are uploaded - efficient!)
3. ECR scans image for vulnerabilities (if scan_on_push = true)
4. Image is now available for EKS to pull
```

### **5. EKS Pulls Image**

```yaml
# In Kubernetes deployment manifest
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: myapp
        image: 123456789012.dkr.ecr.us-east-2.amazonaws.com/dev-devops-practice-app:v1.0.0
        # EKS pulls this image from ECR when creating pods
```

**Pull Process:**
```
1. EKS needs to create a pod
2. Kubelet on EKS node says "I need image X"
3. EKS uses IAM role to authenticate to ECR
4. Downloads image layers from ECR
5. Caches locally on node (subsequent pulls are faster)
6. Starts container
```

---

## 🔐 Security & Permissions

### **How Images are Protected**

```
ECR Repository: dev-devops-practice-app

Repository Policy (Who can pull):
{
  "Effect": "Allow",
  "Principal": {
    "Service": "eks.amazonaws.com"  ← Only EKS can pull
  },
  "Action": [
    "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage",
    "ecr:BatchCheckLayerAvailability"
  ]
}

IAM Policy (Who can push):
{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::123456789012:role/GitHubActionsRole"
  },
  "Action": [
    "ecr:PutImage",
    "ecr:InitiateLayerUpload",
    "ecr:UploadLayerPart",
    "ecr:CompleteLayerUpload"
  ]
}
```

**Access Control:**
```
✅ GitHub Actions (via IAM role) → Can push images
✅ EKS (via IAM role) → Can pull images
✅ Developers (via AWS CLI) → Can pull for local testing
❌ Public Internet → Cannot access (private registry!)
```

---

## 🗄️ Image Storage & Layers

### **How Docker Images Work**

```
Your Spring Boot App Image:

Layer 5: Your app JAR file (10 MB)          ← Changes frequently
Layer 4: Maven dependencies (150 MB)        ← Changes occasionally
Layer 3: Java 17 runtime (200 MB)           ← Rarely changes
Layer 2: Base OS libraries (100 MB)         ← Rarely changes
Layer 1: Ubuntu base (50 MB)                ← Never changes
─────────────────────────────────────────
Total: 510 MB
```

**First Push:**
```bash
docker push $REPO_URL:v1.0.0

Uploading:
├── Layer 1: 50 MB   ← Uploads
├── Layer 2: 100 MB  ← Uploads
├── Layer 3: 200 MB  ← Uploads
├── Layer 4: 150 MB  ← Uploads
└── Layer 5: 10 MB   ← Uploads

Total uploaded: 510 MB
Time: ~5 minutes
```

**Second Push (after code change):**
```bash
docker push $REPO_URL:v1.0.1

Uploading:
├── Layer 1: 50 MB   ← Already exists, skipped!
├── Layer 2: 100 MB  ← Already exists, skipped!
├── Layer 3: 200 MB  ← Already exists, skipped!
├── Layer 4: 150 MB  ← Already exists, skipped!
└── Layer 5: 11 MB   ← Changed, uploads only this!

Total uploaded: 11 MB
Time: ~10 seconds
```

**This is why Docker is fast!** Only changed layers are uploaded.

---

## 🔄 Image Lifecycle Management

### **What We Configured**

```hcl
image_retention_count = 10
```

**How it works:**

```
Day 1:
dev-devops-practice-app
├── v1.0.0 (age: 0 days)

Day 2:
dev-devops-practice-app
├── v1.0.0 (age: 1 day)
├── v1.0.1 (age: 0 days)

... after many builds ...

Day 30:
dev-devops-practice-app
├── v1.0.0 (age: 30 days)
├── v1.0.1 (age: 29 days)
├── v1.0.2 (age: 28 days)
├── ... (8 more images)
├── v1.0.9 (age: 21 days)
├── v1.0.10 (age: 20 days)  ← 10th image
└── v1.0.11 (age: 0 days)   ← 11th image (NEW!)

ECR Lifecycle Policy triggers:
❌ Deletes v1.0.0 (oldest)
✅ Keeps newest 10 images
```

**Why this matters:**
- ECR charges $0.10/GB per month
- Without lifecycle policy, old images accumulate
- Dev environment might have 100+ images after a year
- 100 images × 500 MB = 50 GB = $5/month wasted

---

## 📋 Environment Separation Strategy

### **Our Approach (Separate Repos)**

```
Development Workflow:
1. Developer commits code
2. GitHub Actions builds image
3. Tags: dev-devops-practice-app:abc123def
4. Pushes to: dev-devops-practice-app repository
5. Deploys to dev EKS cluster

Staging Workflow:
1. Promotion pipeline triggered
2. Pulls from dev repo
3. Re-tags for staging
4. Pushes to: staging-devops-practice-app repository
5. Deploys to staging EKS cluster

Production Workflow:
1. Manual approval required
2. Pulls from staging repo
3. Re-tags for production
4. Pushes to: prod-devops-practice-app repository
5. Deploys to production EKS cluster
```

### **Image Naming Convention**

```
dev-devops-practice-app:
├── latest                    ← Always points to newest dev build
├── <commit-hash>            ← abc123def (traceability)
├── <branch-name>            ← feature-login, bugfix-123
├── pr-<number>              ← pr-42 (for pull request previews)
└── dev-v1.0.0              ← Versioned dev releases

staging-devops-practice-app:
├── latest                    ← Points to newest staging build
├── <commit-hash>            ← abc123def (same as dev)
└── staging-v1.0.0          ← Versioned staging releases

prod-devops-practice-app:
├── v1.0.0                   ← Production releases (NO 'latest' tag!)
├── v1.0.1                   ← Next production release
└── <commit-hash>            ← abc123def (full traceability)
```

---

## 🔍 Image Scanning

### **What We Enabled**

```hcl
scan_on_push = true
```

**How it works:**

```
1. You push image to ECR
   docker push $REPO_URL:v1.0.0

2. ECR immediately starts scanning
   Scanning for:
   - CVE vulnerabilities (Common Vulnerabilities and Exposures)
   - Known security issues in packages
   - Outdated dependencies

3. Scan completes (usually 30 seconds - 2 minutes)
   
4. Results available in AWS Console:
   ✅ No vulnerabilities found
   OR
   ⚠️  5 MEDIUM vulnerabilities found:
       - CVE-2023-12345 in openssl (upgrade to 1.1.1w)
       - CVE-2023-67890 in curl (upgrade to 7.88.0)
       ...

5. GitHub Actions can fail build if HIGH/CRITICAL found
```

**Example Scan Result:**
```
Image: dev-devops-practice-app:v1.0.0
Scan Status: COMPLETE

Vulnerabilities:
├── CRITICAL: 0
├── HIGH: 2
├── MEDIUM: 5
├── LOW: 12
└── INFORMATIONAL: 3

Details:
┌─────────────────┬──────────┬─────────────┬──────────────┐
│ CVE ID          │ Severity │ Package     │ Fix Available│
├─────────────────┼──────────┼─────────────┼──────────────┤
│ CVE-2023-12345  │ HIGH     │ openssl     │ 1.1.1w       │
│ CVE-2023-67890  │ HIGH     │ curl        │ 7.88.0       │
│ CVE-2023-11111  │ MEDIUM   │ libxml2     │ None         │
└─────────────────┴──────────┴─────────────┴──────────────┘
```

---

## 💰 ECR Pricing

### **What We'll Pay**

```
Storage Costs:
- $0.10 per GB-month

Data Transfer:
- IN to ECR: FREE
- OUT to EKS (same region): FREE
- OUT to internet: $0.09 per GB (we won't do this)

Estimated Monthly Cost:

Dev Environment:
├── 10 images × 500 MB = 5 GB
├── Storage: 5 GB × $0.10 = $0.50/month
└── Data transfer: FREE (EKS pulls from same region)

Staging Environment (future):
├── 10 images × 500 MB = 5 GB
└── Storage: $0.50/month

Prod Environment (future):
├── 5 images × 500 MB = 2.5 GB  (smaller retention)
└── Storage: $0.25/month

Total: ~$1.25/month
```

**Compared to alternatives:**
- Self-hosted Harbor registry: $50-100/month (EC2 instance)
- DockerHub Pro: $5-9/month (but public or limited private repos)
- ECR: $1-2/month ✅ (cheap and fully managed!)

---

## 🚀 Complete Workflow Example

### **From Code Commit to Running Container**

```
1. Developer writes code
   git commit -m "Add user login feature"
   git push origin main

2. GitHub Actions triggers
   ├── Checkout code
   ├── Build JAR file (mvn package)
   ├── Build Docker image
   │   FROM openjdk:17
   │   COPY target/app.jar /app/app.jar
   │   CMD ["java", "-jar", "/app/app.jar"]
   └── Image created: myapp:abc123def

3. Login to ECR
   aws ecr get-login-password | docker login ...

4. Tag image
   docker tag myapp:abc123def \
     123456789012.dkr.ecr.us-east-2.amazonaws.com/dev-devops-practice-app:abc123def

5. Push to ECR
   docker push ... /dev-devops-practice-app:abc123def
   ├── Layer 1: Already exists ✓
   ├── Layer 2: Already exists ✓
   ├── Layer 3: Already exists ✓
   ├── Layer 4: Already exists ✓
   └── Layer 5: Uploading 11 MB... ✓

6. ECR scans image
   Scanning... ✓
   Found 2 MEDIUM vulnerabilities (acceptable for dev)

7. Update Kubernetes deployment
   kubectl set image deployment/myapp \
     myapp=.../dev-devops-practice-app:abc123def

8. EKS pulls image
   ├── Pod on node-1 needs image
   ├── Node authenticates to ECR (IAM role)
   ├── Downloads layers (cache hit on most layers!)
   ├── Starts container
   └── Application running! ✅

9. Users access application
   User → Load Balancer → EKS Pod (running your new code!)
```

---

## 🎯 Interview Talking Points

**Q: How do you manage Docker images in AWS?**

*"I use ECR with **separate repositories per environment** for clear isolation. Each repository has a **lifecycle policy** to retain only the last 10 images, reducing storage costs. I enable **scan-on-push** to automatically detect vulnerabilities. Images are tagged with commit hashes for traceability, and EKS pulls from ECR using IAM roles - no credentials stored in manifests."*

**Q: How do you promote images from dev to production?**

*"Images in dev-repo are tested, then **re-tagged and pushed to prod-repo**. This ensures the exact same image layers run in production. I never use the 'latest' tag in production - only immutable version tags like v1.0.0 for rollback capability."*

**Q: How do you handle image security?**

*"ECR automatically **scans on push** for CVE vulnerabilities. In the CI/CD pipeline, I fail the build if CRITICAL or HIGH vulnerabilities are found. I use **private repositories** with IAM-based access control - only authorized services and users can pull/push images."*

---

Ready to create the ECR repository? Just confirm and I'll run `terraform apply`! 🚀
