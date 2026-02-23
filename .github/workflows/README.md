# GitHub Actions CI/CD Workflows

Automated deployment pipelines for CloudForge infrastructure and applications.

## 📋 Available Workflows

### 1. **Deploy to Dev** (`deploy-dev.yml`)

- **Trigger**: Automatic on push to `main` branch (only for `backend/` or `frontend/` changes) or manual dispatch
- **Purpose**: Build and deploy backend/frontend to development environment
- **Steps**:
  1. Build Docker images with commit SHA tags
  2. Push images to ECR repositories
  3. Deploy to ECS Fargate services
  4. Wait for deployment stabilization

### 2. **Deploy to Production** (`deploy-prod.yml`)

- **Trigger**: Automatic on push to `production` branch (only for `backend/` or `frontend/` changes) or manual dispatch
- **Purpose**: Build and deploy to production with approval gate
- **Steps**:
  1. Require manual approval (GitHub environment protection)
  2. Build Docker images with commit SHA tags
  3. Push images to ECR repositories
  4. Deploy to ECS Fargate services
  5. Perform health checks
  6. Notify on failure

### 3. **Terraform Infrastructure** (`terraform.yml`)

- **Trigger**: Manual dispatch only
- **Purpose**: Provision, update, or destroy infrastructure
- **Actions**: `plan`, `apply`, `destroy`
- **Environments**: `dev`, `prod`

### 4. **Pull Request Validation** (`pr-validation.yml`)

- **Trigger**: Automatic on pull requests to `main` or `production` branches
- **Purpose**: Validate code quality before merging
- **Smart Validation**: Only runs relevant checks based on changed files:
  - `backend/**` changes → Backend lint, test, Docker build, security scan
  - `frontend/**` changes → Frontend lint, test, build, Docker build, security scan
  - `infra/**` changes → Terraform validation
  - `.github/workflows/**` changes → Full validation
- **Features**: Path-based filtering prevents unnecessary CI runs on documentation updates

---

## 📊 Workflow Triggers

To optimize CI/CD performance and costs, workflows are configured with **path-based filtering**:

| Workflow       | Triggers On                                                     | Ignores                          |
| -------------- | --------------------------------------------------------------- | -------------------------------- |
| Deploy to Dev  | `backend/**`, `frontend/**`, `docker-compose.yml`               | `*.md`, `infra/**`, `.github/**` |
| Deploy to Prod | `backend/**`, `frontend/**`, `docker-compose.yml`               | `*.md`, `infra/**`, `.github/**` |
| PR Validation  | `backend/**`, `frontend/**`, `infra/**`, `.github/workflows/**` | `*.md` (except in listed paths)  |
| Terraform      | Manual only                                                     | N/A                              |

**This means:**

- ✅ Updating README.md won't trigger a deployment
- ✅ Changing Terraform configs won't rebuild Docker images
- ✅ PR validation only runs relevant tests for changed code
- ✅ Manual deployments are always available via workflow_dispatch

---

## 🚀 Initial Setup

### Step 1: Configure GitHub Secrets

Add these secrets to your GitHub repository:

**Settings → Secrets and variables → Actions → New repository secret**

| Secret Name             | Description        | How to Get                               |
| ----------------------- | ------------------ | ---------------------------------------- |
| `AWS_ACCESS_KEY_ID`     | AWS IAM access key | Create IAM user with programmatic access |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key | From IAM user creation                   |

#### Required IAM Permissions

Your IAM user needs the following policies:

- `AmazonEC2ContainerRegistryFullAccess`
- `AmazonECS_FullAccess`
- `AmazonS3FullAccess` (for Terraform state)
- `AmazonDynamoDBFullAccess` (for Terraform state locking)

Or create a custom policy:

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"ecr:*",
				"ecs:*",
				"s3:*",
				"dynamodb:*",
				"ec2:Describe*",
				"elasticloadbalancing:Describe*",
				"logs:*"
			],
			"Resource": "*"
		}
	]
}
```

### Step 2: Configure GitHub Environments

**For Production Protection:**

1. Go to **Settings → Environments → New environment**
2. Create environment: `production`
3. Enable **Required reviewers** and add yourself/team
4. (Optional) Set deployment branch to `production` only

This ensures production deployments require manual approval.

### Step 3: Create Terraform State Backend

Before running any workflows, create the S3 backend:

```powershell
cd infra/terraform/backend-setup
terraform init
terraform apply
```

This creates:

- S3 bucket for state storage
- DynamoDB table for state locking

### Step 4: Deploy Infrastructure

**Option A: Using GitHub Actions (Recommended)**

1. Go to **Actions → Terraform Infrastructure → Run workflow**
2. Select:
   - Environment: `dev`
   - Action: `plan`
3. Review the plan
4. Run again with Action: `apply`

**Option B: Locally**

```powershell
cd infra/terraform/environments/dev
terraform init
terraform plan
terraform apply
```

---

## 📦 Deployment Workflows

### Automatic Deployment (Dev)

**When**: Push to `main` branch

```bash
git add .
git commit -m "Feature: Add new functionality"
git push origin main
```

GitHub Actions will automatically:

1. ✅ Build backend/frontend Docker images
2. ✅ Push to ECR with tags: `latest` and `{commit-sha}`
3. ✅ Deploy to ECS dev environment
4. ✅ Wait for services to stabilize

### Manual Deployment (Dev)

1. Go to **Actions → Deploy to AWS Dev Environment**
2. Click **Run workflow**
3. Select branch: `main`
4. Click **Run workflow**

### Production Deployment

**When**: Push to `production` branch

```bash
# Create production branch from main
git checkout -b production
git push origin production
```

GitHub Actions will:

1. ⏸️ Pause and wait for approval
2. ✅ Send notification to reviewers
3. ⏸️ Wait for manual approval
4. ✅ Build and push images
5. ✅ Deploy to production
6. ✅ Run health checks

---

## 🔧 Workflow Customization

### Change AWS Region

Edit in workflow files:

```yaml
env:
  AWS_REGION: us-east-1 # Change to your region
```

### Change Image Tags

Current strategy: Uses `latest` + `commit SHA`

To use semantic versioning:

```yaml
# In deploy-dev.yml
- name: Get version
  id: version
  run: echo "tag=v1.2.3" >> $GITHUB_OUTPUT

- name: Build image
  env:
    IMAGE_TAG: ${{ steps.version.outputs.tag }}
```

### Add Slack Notifications

Add to end of workflow:

```yaml
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Add Rollback on Failure

```yaml
- name: Rollback on failure
  if: failure()
  run: |
    aws ecs update-service \
      --cluster $CLUSTER \
      --service cloudforge-dev-backend-service \
      --task-definition cloudforge-dev-backend:PREVIOUS \
      --force-new-deployment
```

---

## 📊 Monitoring Deployments

### View Workflow Runs

1. Go to **Actions** tab in GitHub
2. Click on workflow run
3. View logs for each step

### Check ECS Service Status

```bash
aws ecs describe-services \
  --cluster cloudforge-dev \
  --services cloudforge-dev-backend-service
```

### View Application Logs

```bash
# Get task ARN
aws ecs list-tasks --cluster cloudforge-dev

# View logs (or use CloudWatch console)
aws logs tail /ecs/cloudforge-dev-backend --follow
```

---

## 🐛 Troubleshooting

### Issue: "Error: Could not get Terraform outputs"

**Cause**: Infrastructure not deployed yet

**Fix**:

1. Deploy infrastructure first using Terraform workflow
2. Or run locally: `cd infra/terraform/environments/dev && terraform apply`

### Issue: "Error: Login to ECR failed"

**Cause**: Invalid AWS credentials or missing permissions

**Fix**:

1. Verify secrets: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
2. Check IAM permissions include `ecr:GetAuthorizationToken`

### Issue: "Services failed to stabilize"

**Cause**: ECS tasks crashing or failing health checks

**Fix**:

1. Check CloudWatch logs: `/ecs/cloudforge-dev-backend`
2. Verify environment variables in ECS task definition
3. Check database connectivity
4. Verify ALB health check path: `/api/health`

### Issue: "Docker build failed"

**Cause**: Missing dependencies or build errors

**Fix**:

1. Test build locally: `docker build -t test ./backend`
2. Check `package.json` dependencies
3. Verify Dockerfile paths

---

## 🔒 Security Best Practices

### 1. Use OIDC Instead of Access Keys (Recommended)

Replace static credentials with OpenID Connect:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
    aws-region: us-east-1
```

**Setup**: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services

### 2. Rotate Access Keys

If using access keys, rotate them every 90 days.

### 3. Use Environment-Specific Secrets

For production, use environment secrets instead of repository secrets:

- `Settings → Environments → production → Add secret`

### 4. Enable Branch Protection

Require pull request reviews before merging to `main` or `production`.

---

## 📝 Workflow Diagram

```
┌─────────────┐
│  Git Push   │
│  to main    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│   GitHub Actions Triggered      │
└──────┬──────────────────────────┘
       │
       ▼
┌─────────────────────┐
│  1. Checkout Code   │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  2. Get Terraform   │
│     Outputs (ECR)   │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  3. Login to ECR    │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  4. Build Images    │
│     Backend + FE    │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  5. Push to ECR     │
│     (latest + SHA)  │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────────┐
│  6. Update ECS Service  │
│     Force New Deploy    │
└──────┬──────────────────┘
       │
       ▼
┌─────────────────────────┐
│  7. Wait for Stable     │
│     (Health Checks)     │
└──────┬──────────────────┘
       │
       ▼
┌─────────────────────────┐
│  ✅ Deployment Complete │
└─────────────────────────┘
```

---

## 🎯 Next Steps

1. ✅ **Test Dev Deployment**: Push to `main` and monitor workflow
2. ✅ **Set Up Production Branch**: Create and protect `production` branch
3. ✅ **Add Custom Domain**: Set up Route 53 and ACM certificate
4. ✅ **Enable Auto-Scaling**: Add ECS auto-scaling based on CPU/memory
5. ✅ **Set Up Monitoring**: CloudWatch alarms for errors and latency
6. ✅ **Add Database Migrations**: Run migrations before ECS deployment

---

## 📚 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/)

---

**Need Help?** Check the [main README](../../README.md) or create an issue.
