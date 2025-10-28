# DevOps Practice - Quick Deploy Script
# Run this after Docker Desktop is running

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  DevOps Practice - Deployment Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Variables
$ECR_REPO = "676206948248.dkr.ecr.us-east-2.amazonaws.com/dev-devops-practice-app"
$AWS_REGION = "us-east-2"
$VERSION = "v1.0.0"

Write-Host "Step 1: Checking Docker..." -ForegroundColor Yellow
try {
    docker version | Out-Null
    Write-Host "✓ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Authenticating to ECR..." -ForegroundColor Yellow
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Successfully authenticated to ECR" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to authenticate to ECR" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 3: Building Docker image..." -ForegroundColor Yellow
Set-Location app
docker build -t "$ECR_REPO:$VERSION" .
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Image built successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to build image" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..

Write-Host ""
Write-Host "Step 4: Tagging image as latest..." -ForegroundColor Yellow
docker tag "$ECR_REPO:$VERSION" "$ECR_REPO:latest"
Write-Host "✓ Tagged as latest" -ForegroundColor Green

Write-Host ""
Write-Host "Step 5: Pushing images to ECR..." -ForegroundColor Yellow
docker push "$ECR_REPO:$VERSION"
docker push "$ECR_REPO:latest"
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Images pushed successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to push images" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 6: Deploying to Kubernetes..." -ForegroundColor Yellow
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Manifests applied successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to apply manifests" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 7: Waiting for deployment..." -ForegroundColor Yellow
kubectl rollout status deployment/devops-practice-app -n default --timeout=5m
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Deployment successful" -ForegroundColor Green
} else {
    Write-Host "✗ Deployment failed or timed out" -ForegroundColor Red
    Write-Host "Check logs: kubectl logs -l app=devops-practice-app" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Step 8: Getting Load Balancer URL..." -ForegroundColor Yellow
Write-Host "Waiting for ALB to provision (this may take 2-3 minutes)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

$ALB_URL = kubectl get ingress devops-practice-app -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null

if ($ALB_URL) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Application URL: http://$ALB_URL" -ForegroundColor Cyan
    Write-Host "API Endpoint: http://$ALB_URL/api/hello" -ForegroundColor Cyan
    Write-Host "Health Check: http://$ALB_URL/actuator/health" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Test the application:" -ForegroundColor Yellow
    Write-Host "  curl http://$ALB_URL/api/hello" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "⚠ ALB URL not available yet. Check status with:" -ForegroundColor Yellow
    Write-Host "  kubectl get ingress devops-practice-app" -ForegroundColor White
}

Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Yellow
Write-Host "  kubectl get pods              # Check pod status" -ForegroundColor White
Write-Host "  kubectl logs -l app=devops-practice-app -f  # View logs" -ForegroundColor White
Write-Host "  kubectl get ingress           # Check ALB status" -ForegroundColor White
Write-Host "  kubectl describe pod <pod>    # Debug pod issues" -ForegroundColor White
