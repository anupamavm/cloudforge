# CloudForge

A multi-tenant SaaS todo application built with **React**, **Express.js**, and **PostgreSQL**. Each tenant (workspace) is fully isolated — only authenticated users belonging to a tenant can view, create, or delete that tenant's tasks.

---

## Architecture

```
frontend/   React (Vite) SPA — tenant picker, login/register, todo list
backend/    Express.js REST API with JWT authentication
            PostgreSQL database (tenants → users → todos)
```

### Database Schema

| Table     | Key columns                                                          |
| --------- | -------------------------------------------------------------------- |
| `tenants` | `id`, `name`, `slug` (unique)                                        |
| `users`   | `id`, `tenant_id` (FK), `email` (unique per tenant), `password_hash` |
| `todos`   | `id`, `tenant_id` (FK), `user_id` (FK), `title`, `completed`         |

Tenant isolation is enforced at **two** levels:

1. The JWT token embeds `tenantId` — it is impossible to forge cross-tenant access.
2. Every SQL query filters by `tenant_id`, so even a compromised token cannot reach another tenant's data.

---

## Quick Start (Docker)

```bash
# Clone
git clone https://github.com/anupamavm/cloudforge.git
cd cloudforge

# (Optional) Customize environment variables
# A .env file is already included with development defaults
# To customize, edit .env or copy from .env.example:
# cp .env.example .env

# Start everything (PostgreSQL + backend + frontend)
docker compose up --build
```

| Service  | URL                   |
| -------- | --------------------- |
| Frontend | http://localhost:3000 |
| Backend  | http://localhost:5000 |

### Environment Variables

The project uses a `.env` file in the root directory. Key variables:

- `JWT_SECRET` — Secret key for JWT token signing (change in production!)
- `VITE_API_URL` — API URL for frontend to connect to backend (default: http://localhost:5000)

---

## Manual / Development Setup

### Prerequisites

- Node.js 20+
- PostgreSQL 14+ running locally

### Backend

```bash
cd backend
cp .env.example .env   # edit DATABASE_URL and JWT_SECRET
npm install
npm run dev            # starts on :5000 with nodemon
```

### Frontend

```bash
cd frontend
cp .env.example .env   # set VITE_API_URL=http://localhost:5000
npm install
npm run dev            # starts on :5173
```

---

## API Reference

All requests and responses use JSON.

### Tenants

| Method | Path           | Body             | Description         |
| ------ | -------------- | ---------------- | ------------------- |
| GET    | `/api/tenants` | —                | List all tenants    |
| POST   | `/api/tenants` | `{ name, slug }` | Create a new tenant |

### Auth (per tenant)

| Method | Path                                | Body                  | Description |
| ------ | ----------------------------------- | --------------------- | ----------- |
| POST   | `/api/tenants/:tenantSlug/register` | `{ email, password }` | Register    |
| POST   | `/api/tenants/:tenantSlug/login`    | `{ email, password }` | Login → JWT |

### Todos (requires `Authorization: Bearer <token>`)

| Method | Path                                 | Body        | Description      |
| ------ | ------------------------------------ | ----------- | ---------------- |
| GET    | `/api/tenants/:tenantSlug/todos`     | —           | List all todos   |
| POST   | `/api/tenants/:tenantSlug/todos`     | `{ title }` | Create a todo    |
| PATCH  | `/api/tenants/:tenantSlug/todos/:id` | —           | Toggle completed |
| DELETE | `/api/tenants/:tenantSlug/todos/:id` | —           | Delete a todo    |

---

## Security

- Passwords are hashed with **bcryptjs** (cost factor 10).
- JWTs expire after **7 days** and embed `userId`, `email`, and `tenantId`.
- The `tenantGuard` middleware cross-checks the JWT's `tenantId` against the URL's `:tenantSlug` — a user from Tenant A **cannot** access Tenant B's todos even with a valid token.
- Auth endpoints are rate-limited (20 req / 15 min) and tenant creation is rate-limited (10 req / hour) via `express-rate-limit`.

---

## AWS Deployment

CloudForge is production-ready with complete **AWS infrastructure as code** using Terraform.

### Architecture Overview

```
Internet → ALB → ECS Fargate (Backend + Frontend) → RDS PostgreSQL
                      ↓
                ECR (Docker Images)
```

**Services Used:**

- **ECS Fargate**: Serverless container orchestration
- **Application Load Balancer**: Path-based routing (`/api/*` → backend, `/*` → frontend)
- **RDS PostgreSQL**: Managed database with automated backups
- **ECR**: Private Docker image repositories
- **VPC**: Multi-AZ networking with public/private subnets
- **Secrets Manager**: Secure storage for DB passwords and JWT secrets
- **S3 + DynamoDB**: Terraform state management with locking

### Quick Deploy

Full deployment guide: [infra/terraform/QUICKSTART.md](infra/terraform/QUICKSTART.md)

```bash
# 1. Create Terraform backend
cd infra/terraform/backend-setup
terraform init && terraform apply

# 2. Deploy infrastructure
cd ../environments/dev
terraform init && terraform apply

# 3. Deploy application using PowerShell script
cd ../../..
.\infra\deploy.ps1 -Environment dev -Build -Push -Deploy
```

**Estimated Costs:**

- Development: ~$80-85/month
- Production: ~$200-250/month

---

## CI/CD with GitHub Actions

Automated deployment pipelines for continuous integration and delivery.

### Available Workflows

| Workflow                     | Trigger              | Purpose                                       |
| ---------------------------- | -------------------- | --------------------------------------------- |
| **Deploy to Dev**            | Push to `main`       | Build images → Push to ECR → Deploy to ECS    |
| **Deploy to Prod**           | Push to `production` | Build → Require approval → Deploy             |
| **PR Validation**            | Pull request         | Lint, test, security scan, terraform validate |
| **Terraform Infrastructure** | Manual               | Provision/update/destroy infrastructure       |

### Setup

1. **Configure GitHub Secrets:**
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

2. **Deploy infrastructure first:**

   ```bash
   cd infra/terraform/environments/dev
   terraform init && terraform apply
   ```

3. **Push to main:**

   ```bash
   git add .
   git commit -m "Deploy to dev"
   git push origin main
   ```

   GitHub Actions will automatically build, push, and deploy! 🚀

**Full CI/CD Documentation:** [.github/workflows/README.md](.github/workflows/README.md)

---
