# CloudForge Deployment Script
# This script automates the deployment process

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('all', 'backend', 'frontend')]
    [string]$Component = 'all',
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = 'dev',
    
    [Parameter(Mandatory=$false)]
    [string]$Region = 'us-east-1'
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CloudForge Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to Terraform directory
$TerraformDir = "$PSScriptRoot\terraform\environments\$Environment"
Set-Location $TerraformDir

# Get Terraform outputs
Write-Host "Fetching infrastructure details..." -ForegroundColor Yellow
$BackendECR = terraform output -raw backend_ecr_repository_url
$FrontendECR = terraform output -raw frontend_ecr_repository_url
$ALB_DNS = terraform output -raw alb_dns_name
$ClusterName = terraform output -raw ecs_cluster_name

Write-Host "ECR Backend: $BackendECR" -ForegroundColor Green
Write-Host "ECR Frontend: $FrontendECR" -ForegroundColor Green
Write-Host "ALB DNS: $ALB_DNS" -ForegroundColor Green
Write-Host ""

# ECR Login
Write-Host "Logging into ECR..." -ForegroundColor Yellow
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $BackendECR

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to login to ECR" -ForegroundColor Red
    exit 1
}

# Build and push backend
if ($Component -eq 'all' -or $Component -eq 'backend') {
    Write-Host ""
    Write-Host "Building and pushing backend..." -ForegroundColor Yellow
    
    Set-Location "$PSScriptRoot\..\..\backend"
    
    docker build -t cloudforge-backend .
    if ($LASTEXITCODE -ne 0) { Write-Host "Backend build failed" -ForegroundColor Red; exit 1 }
    
    docker tag cloudforge-backend:latest "${BackendECR}:latest"
    docker push "${BackendECR}:latest"
    if ($LASTEXITCODE -ne 0) { Write-Host "Backend push failed" -ForegroundColor Red; exit 1 }
    
    Write-Host "Backend image pushed successfully!" -ForegroundColor Green
    
    # Update ECS service
    Write-Host "Updating backend ECS service..." -ForegroundColor Yellow
    aws ecs update-service --cluster $ClusterName --service "cloudforge-$Environment-backend-service" --force-new-deployment --region $Region
    if ($LASTEXITCODE -ne 0) { Write-Host "Backend service update failed" -ForegroundColor Red; exit 1 }
}

# Build and push frontend
if ($Component -eq 'all' -or $Component -eq 'frontend') {
    Write-Host ""
    Write-Host "Building and pushing frontend..." -ForegroundColor Yellow
    
    Set-Location "$PSScriptRoot\..\..\frontend"
    
    docker build --build-arg VITE_API_URL="http://$ALB_DNS" -t cloudforge-frontend .
    if ($LASTEXITCODE -ne 0) { Write-Host "Frontend build failed" -ForegroundColor Red; exit 1 }
    
    docker tag cloudforge-frontend:latest "${FrontendECR}:latest"
    docker push "${FrontendECR}:latest"
    if ($LASTEXITCODE -ne 0) { Write-Host "Frontend push failed" -ForegroundColor Red; exit 1 }
    
    Write-Host "Frontend image pushed successfully!" -ForegroundColor Green
    
    # Update ECS service
    Write-Host "Updating frontend ECS service..." -ForegroundColor Yellow
    aws ecs update-service --cluster $ClusterName --service "cloudforge-$Environment-frontend-service" --force-new-deployment --region $Region
    if ($LASTEXITCODE -ne 0) { Write-Host "Frontend service update failed" -ForegroundColor Red; exit 1 }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Application URL: http://$ALB_DNS" -ForegroundColor Cyan
Write-Host ""
Write-Host "Monitor deployment status:" -ForegroundColor Yellow
Write-Host "  aws ecs describe-services --cluster $ClusterName --services cloudforge-$Environment-backend-service --region $Region" -ForegroundColor Gray
Write-Host ""
Write-Host "View logs:" -ForegroundColor Yellow
Write-Host "  aws logs tail /ecs/cloudforge-$Environment/backend --follow --region $Region" -ForegroundColor Gray
Write-Host "  aws logs tail /ecs/cloudforge-$Environment/frontend --follow --region $Region" -ForegroundColor Gray
