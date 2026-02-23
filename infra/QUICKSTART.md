# CloudForge - AWS Deployment Quick Start

This is a step-by-step guide to deploy CloudForge to AWS.

## Prerequisites Checklist

- [ ] AWS Account with admin access
- [ ] AWS CLI installed: `aws --version`
- [ ] AWS CLI configured: `aws configure`
- [ ] Terraform installed: `terraform version`
- [ ] Docker installed: `docker --version`

## Quick Deployment (15 minutes)

### 1. Create Terraform Backend (2 min)

```powershell
cd infra/terraform/backend-setup
terraform init
terraform apply -auto-approve
```

Note the S3 bucket name from output.

### 2. Configure Remote State (1 min)

Edit `infra/terraform/environments/dev/main.tf` and uncomment lines 14-20:

```hcl
backend "s3" {
  bucket         = "cloudforge-terraform-state"  # Use bucket name from step 1
  key            = "dev/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "cloudforge-terraform-locks"
}
```

Then migrate state:

```powershell
cd ../environments/dev
terraform init -migrate-state
```

### 3. Deploy Infrastructure (15 min)

```powershell
terraform apply -auto-approve
```

☕ Take a break - this creates VPC, RDS, ALB, ECS cluster, etc.

### 4. Deploy Application (5 min)

Use the automated deployment script:

```powershell
cd ../../../
.\deploy.ps1 -Component all -Environment dev -Region us-east-1
```

Or manually:

```powershell
cd environments/dev
$BACKEND_ECR = terraform output -raw backend_ecr_repository_url
$FRONTEND_ECR = terraform output -raw frontend_ecr_repository_url
$ALB_DNS = terraform output -raw alb_dns_name
$CLUSTER = terraform output -raw ecs_cluster_name
$REGION = "us-east-1"

# Login to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $BACKEND_ECR

# Build and push backend
cd ../../../../backend
docker build -t cloudforge-backend .
docker tag cloudforge-backend:latest ${BACKEND_ECR}:latest
docker push ${BACKEND_ECR}:latest

# Build and push frontend
cd ../frontend
docker build --build-arg VITE_API_URL=http://$ALB_DNS -t cloudforge-frontend .
docker tag cloudforge-frontend:latest ${FRONTEND_ECR}:latest
docker push ${FRONTEND_ECR}:latest

# Update ECS services
aws ecs update-service --cluster $CLUSTER --service cloudforge-dev-backend-service --force-new-deployment --region $REGION
aws ecs update-service --cluster $CLUSTER --service cloudforge-dev-frontend-service --force-new-deployment --region $REGION
```

### 5. Access Your Application (1 min)

Get the URL:

```powershell
cd infra/terraform/environments/dev
$ALB_DNS = terraform output -raw alb_dns_name
Write-Host "Application URL: http://$ALB_DNS"
```

Open in browser: `http://<alb-dns-name>`

## Verify Deployment

```powershell
# Check ECS services
aws ecs describe-services --cluster cloudforge-dev-cluster --services cloudforge-dev-backend-service cloudforge-dev-frontend-service --region us-east-1

# View backend logs
aws logs tail /ecs/cloudforge-dev/backend --follow --region us-east-1

# Test backend health
curl http://$ALB_DNS/api/health
```

## Common Issues

### Issue: ECS tasks not starting

**Solution:** Check logs:

```powershell
aws logs tail /ecs/cloudforge-dev/backend --since 30m --region us-east-1
```

### Issue: "No tasks found" error

**Solution:** Wait 2-3 minutes for ECS to pull images and start tasks:

```powershell
aws ecs list-tasks --cluster cloudforge-dev-cluster --region us-east-1
```

### Issue: Health checks failing

**Solution:** Verify backend is running and responding:

```powershell
# Check task status
aws ecs describe-tasks --cluster cloudforge-dev-cluster --tasks $(aws ecs list-tasks --cluster cloudforge-dev-cluster --service cloudforge-dev-backend-service --query 'taskArns[0]' --output text --region us-east-1) --region us-east-1
```

## Update Application

After making code changes:

```powershell
# Quick update (both frontend + backend)
cd infra
.\deploy.ps1

# Update only backend
.\deploy.ps1 -Component backend

# Update only frontend
.\deploy.ps1 -Component frontend
```

## Monitor Costs

Estimated monthly cost: **$80-85**

Breakdown:

- ECS Fargate (2 tasks): $15-20
- RDS db.t3.micro: $15
- ALB: $18
- NAT Gateway: $32
- Other (CloudWatch, S3): $5

To reduce costs:

```powershell
# Stop ECS services when not in use
aws ecs update-service --cluster cloudforge-dev-cluster --service cloudforge-dev-backend-service --desired-count 0 --region us-east-1
aws ecs update-service --cluster cloudforge-dev-cluster --service cloudforge-dev-frontend-service --desired-count 0 --region us-east-1

# Restart when needed
aws ecs update-service --cluster cloudforge-dev-cluster --service cloudforge-dev-backend-service --desired-count 1 --region us-east-1
aws ecs update-service --cluster cloudforge-dev-cluster --service cloudforge-dev-frontend-service --desired-count 1 --region us-east-1
```

## Cleanup (Delete Everything)

⚠️ **WARNING: This deletes all resources and data!**

```powershell
cd infra/terraform/environments/dev
terraform destroy -auto-approve

# Optional: Delete backend
cd ../../backend-setup
terraform destroy -auto-approve
```

## Next Steps

1. **Setup Custom Domain** - Configure Route 53 and point to ALB
2. **Enable HTTPS** - Request SSL certificate in ACM, add HTTPS listener
3. **Setup CI/CD** - Automate deployments with GitHub Actions
4. **Add Monitoring** - Configure CloudWatch alarms and dashboards
5. **Enable Auto Scaling** - Scale based on CPU/memory usage

## Need Help?

- **Terraform Docs**: See `infra/terraform/README.md`
- **AWS Console**: Check resources at https://console.aws.amazon.com
- **CloudWatch Logs**: Monitor application logs in real-time
