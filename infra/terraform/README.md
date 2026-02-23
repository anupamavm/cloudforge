# CloudForge AWS Infrastructure - Terraform Deployment

This directory contains Terraform configurations to deploy the CloudForge application on AWS using:

- **ECS Fargate** - Container orchestration
- **Application Load Balancer (ALB)** - Traffic routing
- **RDS PostgreSQL** - Managed database
- **ECR** - Docker image registry
- **VPC** - Network infrastructure
- **Secrets Manager** - Secure credential storage
- **S3** - Terraform state storage

## Architecture Overview

```
Internet → ALB → ECS Fargate (Frontend + Backend) → RDS PostgreSQL
                          ↓
                  Private Subnets with NAT Gateway
```

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured (`aws configure`)
3. **Terraform** >= 1.6.0 ([Download](https://www.terraform.io/downloads))
4. **Docker** installed for building images

## Cost Estimate (Development)

- **ECS Fargate**: ~$15-20/month (2 tasks running 24/7)
- **RDS db.t3.micro**: ~$15/month
- **ALB**: ~$18/month
- **NAT Gateway**: ~$32/month
- **Total**: ~$80-85/month

**Cost Optimization Tips:**

- Use Fargate Spot for non-production (~70% savings)
- Stop resources when not in use
- Use smaller RDS instances
- Consider removing NAT Gateway (requires public subnets for ECS)

## Deployment Steps

### Step 1: Setup Terraform Backend (One-time)

This creates S3 bucket and DynamoDB table for storing Terraform state:

```powershell
cd infra/terraform/backend-setup
terraform init
terraform plan
terraform apply
```

After successful creation, note the S3 bucket name from the output.

### Step 2: Configure Remote State

1. Open `infra/terraform/environments/dev/main.tf`
2. Uncomment the backend configuration block
3. Update the bucket name with the one created in Step 1
4. Initialize with state migration:

```powershell
cd ../environments/dev
terraform init -migrate-state
```

### Step 3: Deploy Infrastructure

```powershell
# Review what will be created
terraform plan

# Deploy infrastructure
terraform apply

# Save outputs for later use
terraform output > outputs.txt
```

**Deployment time:** ~15-20 minutes (RDS and NAT Gateway take the longest)

### Step 4: Build and Push Docker Images

After infrastructure is deployed, push your application images to ECR:

```powershell
# Get ECR URLs from Terraform output
$BACKEND_ECR = terraform output -raw backend_ecr_repository_url
$FRONTEND_ECR = terraform output -raw frontend_ecr_repository_url
$AWS_REGION = "us-east-1"  # Or your configured region

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $BACKEND_ECR

# Build and push backend
cd ../../../../backend
docker build -t cloudforge-backend .
docker tag cloudforge-backend:latest ${BACKEND_ECR}:latest
docker push ${BACKEND_ECR}:latest

# Build and push frontend
cd ../frontend
docker build --build-arg VITE_API_URL=http://$(terraform -chdir=../../infra/terraform/environments/dev output -raw alb_dns_name) -t cloudforge-frontend .
docker tag cloudforge-frontend:latest ${FRONTEND_ECR}:latest
docker push ${FRONTEND_ECR}:latest
```

### Step 5: Update ECS Services

After pushing images, force ECS to deploy the new versions:

```powershell
cd ../../infra/terraform/environments/dev

$CLUSTER = terraform output -raw ecs_cluster_name

aws ecs update-service --cluster $CLUSTER --service cloudforge-dev-backend-service --force-new-deployment
aws ecs update-service --cluster $CLUSTER --service cloudforge-dev-frontend-service --force-new-deployment
```

### Step 6: Verify Deployment

```powershell
# Get ALB DNS name
$ALB_DNS = terraform output -raw alb_dns_name

# Access your application
Write-Host "Application URL: http://$ALB_DNS"

# Check service status
aws ecs describe-services --cluster $CLUSTER --services cloudforge-dev-backend-service cloudforge-dev-frontend-service
```

## Managing Secrets

### Retrieve Database Password

```powershell
$DB_SECRET_ARN = terraform output -raw db_password_secret_arn
aws secretsmanager get-secret-value --secret-id $DB_SECRET_ARN --query SecretString --output text
```

### Retrieve JWT Secret

```powershell
$JWT_SECRET_ARN = terraform output -raw jwt_secret_arn
aws secretsmanager get-secret-value --secret-id $JWT_SECRET_ARN --query SecretString --output text
```

## Updating the Application

### Update Backend Code

```powershell
cd backend
docker build -t cloudforge-backend .
docker tag cloudforge-backend:latest ${BACKEND_ECR}:latest
docker push ${BACKEND_ECR}:latest

aws ecs update-service --cluster $CLUSTER --service cloudforge-dev-backend-service --force-new-deployment
```

### Update Frontend Code

```powershell
cd frontend
docker build --build-arg VITE_API_URL=http://$ALB_DNS -t cloudforge-frontend .
docker tag cloudforge-frontend:latest ${FRONTEND_ECR}:latest
docker push ${FRONTEND_ECR}:latest

aws ecs update-service --cluster $CLUSTER --service cloudforge-dev-frontend-service --force-new-deployment
```

## Monitoring

### View ECS Logs

```powershell
# Backend logs
aws logs tail /ecs/cloudforge-dev/backend --follow

# Frontend logs
aws logs tail /ecs/cloudforge-dev/frontend --follow
```

### Check Service Health

```powershell
aws ecs describe-services --cluster $CLUSTER --services cloudforge-dev-backend-service --query 'services[0].runningCount'
```

### RDS Metrics

Monitor in AWS Console: CloudWatch → Metrics → RDS

## Scaling

### Manual Scaling

Update `infra/terraform/environments/dev/variables.tf`:

```hcl
variable "backend_desired_count" {
  default = 2  # Increased from 1
}
```

Then apply:

```powershell
terraform apply
```

### Auto Scaling (Advanced)

Add Application Auto Scaling resources to `infra/terraform/modules/ecs/main.tf`

## Troubleshooting

### ECS Tasks Not Starting

```powershell
# Check task failures
aws ecs describe-tasks --cluster $CLUSTER --tasks $(aws ecs list-tasks --cluster $CLUSTER --service cloudforge-dev-backend-service --query 'taskArns[0]' --output text)

# Check task logs
aws logs tail /ecs/cloudforge-dev/backend --since 10m
```

### Database Connection Issues

1. Verify security groups allow traffic from ECS to RDS (port 5432)
2. Check DATABASE_URL environment variable is correct
3. Verify RDS is in `available` state:
   ```powershell
   aws rds describe-db-instances --db-instance-identifier cloudforge-dev-db
   ```

### ALB Health Checks Failing

1. Verify backend is responding on `/api/health`
2. Check health check settings in `modules/alb/main.tf`
3. Review ECS task logs for errors

## Production Deployment

For production, create `infra/terraform/environments/prod/` with:

- **Multi-AZ RDS** (`db_multi_az = true`)
- **Deletion protection** enabled
- **Larger instance types**
- **Auto Scaling** configured
- **HTTPS/SSL** certificate on ALB
- **Route 53** for custom domain
- **Backup strategy** configured

## Cleanup

**⚠️ WARNING: This will delete all resources and data!**

```powershell
cd infra/terraform/environments/dev
terraform destroy

# Optionally delete backend
cd ../../backend-setup
terraform destroy
```

## Cost Monitoring

Set up billing alerts in AWS Console:

1. CloudWatch → Billing Alarms
2. Set threshold (e.g., $50/month)
3. Configure SNS notification

## Support

For issues with:

- **Terraform**: Check `terraform.tfstate` for current state
- **AWS Resources**: Use AWS Console for detailed information
- **Application**: Check ECS logs in CloudWatch

## Next Steps

1. **Add HTTPS**: Configure ACM certificate and HTTPS listener
2. **Custom Domain**: Use Route 53 to point your domain to ALB
3. **CI/CD**: Setup GitHub Actions for automated deployments
4. **Monitoring**: Configure CloudWatch alarms and dashboards
5. **Backup**: Setup automated RDS snapshots
