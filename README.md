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

| Table     | Key columns                                              |
|-----------|----------------------------------------------------------|
| `tenants` | `id`, `name`, `slug` (unique)                            |
| `users`   | `id`, `tenant_id` (FK), `email` (unique per tenant), `password_hash` |
| `todos`   | `id`, `tenant_id` (FK), `user_id` (FK), `title`, `completed` |

Tenant isolation is enforced at **two** levels:
1. The JWT token embeds `tenantId` — it is impossible to forge cross-tenant access.
2. Every SQL query filters by `tenant_id`, so even a compromised token cannot reach another tenant's data.

---

## Quick Start (Docker)

```bash
# Clone
git clone https://github.com/anupamavm/cloudforge.git
cd cloudforge

# Copy env (optional — defaults work for local dev)
cp backend/.env.example backend/.env

# Start everything (PostgreSQL + backend + frontend)
docker compose up --build
```

| Service  | URL                    |
|----------|------------------------|
| Frontend | http://localhost:3000  |
| Backend  | http://localhost:5000  |

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

| Method | Path            | Body              | Description           |
|--------|-----------------|-------------------|-----------------------|
| GET    | `/api/tenants`  | —                 | List all tenants      |
| POST   | `/api/tenants`  | `{ name, slug }`  | Create a new tenant   |

### Auth (per tenant)

| Method | Path                                  | Body                    | Description  |
|--------|---------------------------------------|-------------------------|--------------|
| POST   | `/api/tenants/:tenantSlug/register`   | `{ email, password }`   | Register     |
| POST   | `/api/tenants/:tenantSlug/login`      | `{ email, password }`   | Login → JWT  |

### Todos (requires `Authorization: Bearer <token>`)

| Method | Path                                           | Body        | Description      |
|--------|------------------------------------------------|-------------|------------------|
| GET    | `/api/tenants/:tenantSlug/todos`               | —           | List all todos   |
| POST   | `/api/tenants/:tenantSlug/todos`               | `{ title }` | Create a todo    |
| PATCH  | `/api/tenants/:tenantSlug/todos/:id`           | —           | Toggle completed |
| DELETE | `/api/tenants/:tenantSlug/todos/:id`           | —           | Delete a todo    |

---

## Security

- Passwords are hashed with **bcryptjs** (cost factor 10).
- JWTs expire after **7 days** and embed `userId`, `email`, and `tenantId`.
- The `tenantGuard` middleware cross-checks the JWT's `tenantId` against the URL's `:tenantSlug` — a user from Tenant A **cannot** access Tenant B's todos even with a valid token.
- Auth endpoints are rate-limited (20 req / 15 min) and tenant creation is rate-limited (10 req / hour) via `express-rate-limit`.

