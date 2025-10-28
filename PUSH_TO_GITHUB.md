# Quick Push to GitHub

## Your AWS Credentials for GitHub Secrets:
Get these from your `~/.aws/credentials` file:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION: `us-east-2`

## Steps to Complete:

### 1. Create GitHub Repo (if not done)
- Go to: https://github.com/new
- Name: `devops-practice`
- Click "Create repository"

### 2. Push Code (run these commands):
```powershell
# Replace YOUR_USERNAME with your actual GitHub username
git remote add origin https://github.com/YOUR_USERNAME/devops-practice.git
git branch -M main
git push -u origin main
```

### 3. Add GitHub Secrets
Go to: https://github.com/YOUR_USERNAME/devops-practice/settings/secrets/actions

Click "New repository secret" for each:

**Secret 1:**
- Name: `AWS_ACCESS_KEY_ID`
- Value: [Get from ~/.aws/credentials]

**Secret 2:**
- Name: `AWS_SECRET_ACCESS_KEY`  
- Value: [Get from ~/.aws/credentials]

**Secret 3:**
- Name: `AWS_REGION`
- Value: `us-east-2`

### 4. Test CI/CD
```powershell
# Make a change
echo "Testing CI/CD" >> README.md
git add README.md
git commit -m "test: trigger CI/CD pipeline"
git push
```

Then watch at: https://github.com/YOUR_USERNAME/devops-practice/actions

## Already Committed Files:
✅ Spring Boot application code
✅ Dockerfile for multi-stage builds
✅ Kubernetes manifests (deployment, service, ingress)
✅ Terraform infrastructure code
✅ GitHub Actions workflow (`.github/workflows/deploy.yml`)
✅ Documentation

## CI/CD Will Automatically:
1. Build Docker image
2. Push to ECR: `676206948248.dkr.ecr.us-east-2.amazonaws.com/dev-devops-practice-app:latest`
3. Deploy to EKS cluster: `dev-eks-cluster`
4. Show ALB URL in workflow output
