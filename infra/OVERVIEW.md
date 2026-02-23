# CloudForge AWS Infrastructure Overview

## 📁 Infrastructure Structure

```
infra/
├── deploy.ps1                      # Automated deployment script
├── QUICKSTART.md                   # Quick start guide
├── .gitignore                      # Ignore sensitive files
└── terraform/
    ├── README.md                   # Detailed documentation
    ├── backend-setup/              # S3 + DynamoDB for state storage
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── modules/                    # Reusable infrastructure modules
    │   ├── vpc/                    # VPC, subnets, NAT, routing
    │   ├── security/               # Security groups
    │   ├── alb/                    # Application Load Balancer
    │   ├── rds/                    # PostgreSQL database
    │   ├── ecr/                    # Docker image registry
    │   ├── ecs/                    # ECS Fargate cluster & services
    │   └── s3/                     # S3 bucket for state
    ├── environments/
    │   ├── dev/                    # Development environment
    │   │   ├── main.tf             # Provider & backend config
    │   │   ├── resources.tf        # Module orchestration
    │   │   ├── variables.tf        # Variable definitions
    │   │   ├── outputs.tf          # Output values
    │   │   └── terraform.tfvars.example
    │   └── prod/                   # Production environment
    │       ├── main.tf
    │       ├── resources.tf
    │       ├── variables.tf
    │       ├── outputs.tf
    │       └── terraform.tfvars.example
    └── shared/
        ├── versions.tf
        └── provider.tf
```

## 🏗️ Infrastructure Components

### 1. VPC Module

- **Purpose**: Network isolation with public/private subnets
- **Resources**: VPC, Internet Gateway, NAT Gateway, Route Tables
- **Design**: 2 AZs for high availability

### 2. Security Groups Module

- **ALB SG**: Allows HTTP/HTTPS from internet
- **ECS Tasks SG**: Allows traffic from ALB only
- **RDS SG**: Allows PostgreSQL (5432) from ECS tasks only

### 3. Application Load Balancer (ALB) Module

- **Target Groups**: Separate for frontend (port 80) and backend (port 5000)
- **Routing**:
  - `/api/*` → Backend
  - `/*` → Frontend
- **Health Checks**: Automatic health monitoring

### 4. RDS Module

- **Database**: PostgreSQL 15.4
- **Features**:
  - Automatic password generation
  - Secrets Manager integration
  - Automated backups
  - Encryption at rest

### 5. ECR Module

- **Repositories**: Separate for backend and frontend
- **Features**:
  - Automatic image scanning
  - Lifecycle policies (keep last 10 images)
  - Encryption at rest

### 6. ECS Fargate Module

- **Cluster**: Managed container orchestration
- **Services**: Backend and Frontend
- **Features**:
  - Auto-healing (replaces failed tasks)
  - CloudWatch logging
  - Secrets injection
  - Health monitoring

### 7. S3 Backend Module

- **S3 Bucket**: Encrypted Terraform state storage
- **DynamoDB**: State locking to prevent conflicts
- **Security**: Private bucket with versioning

## 🔄 Deployment Flow

```
1. Create S3 Backend
   ↓
2. Initialize Terraform
   ↓
3. Deploy Infrastructure (VPC, RDS, ALB, ECS)
   ↓
4. Build Docker Images
   ↓
5. Push to ECR
   ↓
6. ECS Auto-deploys containers
   ↓
7. Application accessible via ALB
```

## 📊 Architecture Diagram

```
                    Internet
                       ↓
                   [Route 53]  (Optional - for custom domain)
                       ↓
                      [ALB]
                    /      \
          (/:80)   /        \  (/api/*:5000)
                  /          \
         [ECS Frontend]   [ECS Backend]
             (nginx)      (Node.js + Express)
                              ↓
                        [RDS PostgreSQL]
                       (Private Subnet)
                              ↓
                  [Secrets Manager]
                  (DB Password, JWT Secret)
```

## 🔐 Security Features

1. **Network Isolation**
   - Private subnets for ECS and RDS
   - Public subnets for ALB only
   - NAT Gateway for outbound internet access

2. **Least Privilege**
   - Security groups limit traffic flow
   - IAM roles with minimal permissions
   - No public database access

3. **Encryption**
   - RDS encryption at rest
   - ECR encryption at rest
   - S3 encryption for state files
   - Secrets Manager for sensitive data

4. **Monitoring**
   - CloudWatch logs for all containers
   - ECS Container Insights enabled
   - RDS CloudWatch metrics

## 💰 Cost Optimization

### Development Environment (~$80-85/month)

- **ECS Fargate**: 2 tasks × 0.25 vCPU × 0.5GB = ~$15-20
- **RDS db.t3.micro**: Single-AZ = ~$15
- **ALB**: ~$18
- **NAT Gateway**: ~$32
- **Other**: ~$5

### Production Environment (~$200-250/month)

- **ECS Fargate**: 4 tasks × 0.5 vCPU × 1GB = ~$60-80
- **RDS db.t3.small**: Multi-AZ = ~$60
- **ALB**: ~$18
- **NAT Gateway**: ~$32
- **Other**: ~$10

### Cost Saving Tips

```powershell
# Stop dev environment when not in use
aws ecs update-service --cluster cloudforge-dev-cluster --service cloudforge-dev-backend-service --desired-count 0
aws ecs update-service --cluster cloudforge-dev-cluster --service cloudforge-dev-frontend-service --desired-count 0

# Restart when needed
aws ecs update-service --cluster cloudforge-dev-cluster --service cloudforge-dev-backend-service --desired-count 1
aws ecs update-service --cluster cloudforge-dev-cluster --service cloudforge-dev-frontend-service --desired-count 1
```

## 🚀 Quick Commands

### Initial Setup

```powershell
# Create backend
cd infra/terraform/backend-setup
terraform init && terraform apply

# Deploy infrastructure
cd ../environments/dev
terraform init && terraform apply

# Deploy application
cd ../../../
.\deploy.ps1
```

### Daily Operations

```powershell
# Update code
.\deploy.ps1

# View logs
aws logs tail /ecs/cloudforge-dev/backend --follow

# Check status
aws ecs describe-services --cluster cloudforge-dev-cluster --services cloudforge-dev-backend-service
```

### Troubleshooting

```powershell
# Get DB password
aws secretsmanager get-secret-value --secret-id $(terraform output -raw db_password_secret_arn) --query SecretString --output text

# List running tasks
aws ecs list-tasks --cluster cloudforge-dev-cluster

# Describe failed task
aws ecs describe-tasks --cluster cloudforge-dev-cluster --tasks <task-arn>
```

## 📚 Documentation Files

- **[QUICKSTART.md](QUICKSTART.md)**: 15-minute deployment guide
- **[terraform/README.md](terraform/README.md)**: Comprehensive Terraform documentation
- **[deploy.ps1](deploy.ps1)**: Automated deployment script

## 🎯 Next Steps

1. **Deploy Development**: Follow QUICKSTART.md
2. **Test Application**: Access via ALB DNS name
3. **Setup Domain**: Configure Route 53 (optional)
4. **Enable HTTPS**: Add ACM certificate
5. **Deploy Production**: Use prod environment
6. **Setup CI/CD**: Automate with GitHub Actions
7. **Monitor Costs**: Setup billing alarms

## ⚠️ Important Notes

1. **Database Password**:
   - Auto-generated and stored in Secrets Manager
   - Never committed to version control
   - Retrieve with AWS CLI when needed

2. **JWT Secret**:
   - Auto-generated for each environment
   - Stored in Secrets Manager
   - Automatically injected into ECS tasks

3. **State Files**:
   - Stored in S3 (after backend setup)
   - Contains sensitive information
   - Never commit `*.tfstate` files

4. **Cost Management**:
   - Set up billing alarms immediately
   - Stop dev resources when not in use
   - Monitor CloudWatch metrics

5. **Production Deployment**:
   - Always use version tags (not `latest`)
   - Enable deletion protection
   - Use Multi-AZ for RDS
   - Configure automated backups

## 🐛 Common Issues & Solutions

### Issue: "Error acquiring state lock"

**Solution**: Another Terraform operation is running or crashed. Check DynamoDB locks:

```powershell
aws dynamodb scan --table-name cloudforge-terraform-locks
```

### Issue: ECS tasks failing to start

**Solution**: Check CloudWatch logs:

```powershell
aws logs tail /ecs/cloudforge-dev/backend --since 30m
```

### Issue: Health checks failing

**Solution**: Verify backend responds on `/api/health`:

```powershell
curl http://<alb-dns>/api/health
```

## 📞 Support Resources

- **AWS Documentation**: https://docs.aws.amazon.com/
- **Terraform Documentation**: https://www.terraform.io/docs/
- **ECS Best Practices**: https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/
- **AWS Support**: AWS Console → Support Center
