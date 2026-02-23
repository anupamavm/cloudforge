# Terraform Backend Setup

This directory creates the **S3 bucket** and **DynamoDB table** required for storing Terraform state remotely and enabling state locking.

## 🎯 Purpose

This is a **one-time setup** that must be run **BEFORE** deploying your main infrastructure (dev/prod environments).

### What Gets Created

1. **S3 Bucket** (`cloudforge-terraform-state`)
   - Stores Terraform state files
   - Versioning enabled (rollback capability)
   - Encryption enabled (AES-256)
   - Public access blocked

2. **DynamoDB Table** (`cloudforge-terraform-locks`)
   - Prevents concurrent Terraform runs
   - Ensures only one person can modify infrastructure at a time
   - Pay-per-request billing (nearly free)

## 📋 Prerequisites

- AWS CLI installed and configured (`aws configure`)
- Terraform >= 1.6.0 installed
- AWS credentials with permissions to create S3 and DynamoDB resources

## 🚀 Quick Start

```powershell
# Navigate to backend-setup
cd infra/terraform/backend-setup

# Initialize Terraform (uses LOCAL state for this setup)
terraform init

# Review what will be created
terraform plan

# Create the S3 bucket and DynamoDB table
terraform apply

# Type "yes" when prompted
```

**Expected Output:**

```
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:
s3_bucket_name = "cloudforge-terraform-state"
dynamodb_table_name = "cloudforge-terraform-locks"
```

## 🔐 How State Locking Works

### The Problem Without Locking

```
10:00:00 - Alice runs: terraform apply
10:00:01 - Bob runs: terraform apply

Both read state simultaneously → Both try to modify infrastructure
Result: Corrupted state, duplicate resources, conflicts!
```

### How DynamoDB Prevents This

**Step 1: Lock Acquisition**

```
Alice runs terraform apply
  ↓
Creates lock in DynamoDB:
{
  "LockID": "cloudforge-terraform-state/dev/terraform.tfstate-md5",
  "Who": "alice@laptop",
  "Created": "2026-02-23T10:00:00Z",
  "Operation": "OperationTypeApply"
}
```

**Step 2: Bob Tries to Run**

```
Bob runs terraform apply (1 second later)
  ↓
Tries to create lock
  ↓
DynamoDB says: "Lock already exists!"
  ↓
Error: Lock held by alice@laptop
  ↓
Bob must WAIT
```

**Step 3: Lock Release**

```
Alice's apply completes
  ↓
Writes new state to S3
  ↓
Deletes lock from DynamoDB
  ↓
Bob can now proceed!
```

### DynamoDB Table Structure

```
Table: cloudforge-terraform-locks
Partition Key: LockID (String)

Example Lock:
┌────────────────────────────────────┬──────────────────────────┐
│ LockID                             │ Lock Info                │
├────────────────────────────────────┼──────────────────────────┤
│ cloudforge-terraform-state/dev/... │ Who: alice@laptop        │
│                                    │ Operation: Apply         │
│                                    │ Created: 10:00:00        │
└────────────────────────────────────┴──────────────────────────┘
```

## 💰 Cost

| Resource                   | Monthly Cost       |
| -------------------------- | ------------------ |
| S3 Bucket (1MB state)      | ~$0.02             |
| S3 Requests (100/month)    | ~$0.01             |
| DynamoDB (Pay-per-request) | ~$0.00 (Free tier) |
| **TOTAL**                  | **~$0.50/month**   |

## ⚙️ Configuration

### Resources Created

#### 1. S3 Bucket

```terraform
resource "aws_s3_bucket" "terraform_state" {
  bucket = "cloudforge-terraform-state"
}
```

#### 2. S3 Versioning (Rollback Protection)

```terraform
resource "aws_s3_bucket_versioning" "terraform_state" {
  versioning_configuration {
    status = "Enabled"  # Keeps history of all state changes
  }
}
```

#### 3. S3 Encryption (Protect Secrets)

```terraform
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # Military-grade encryption
    }
  }
}
```

#### 4. Public Access Block (Prevent Leaks)

```terraform
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

#### 5. DynamoDB Table (State Locking)

```terraform
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "cloudforge-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
}
```

## 🔄 Next Steps After Setup

1. **Verify Resources Created**

   ```powershell
   # Check S3 bucket
   aws s3 ls | grep cloudforge-terraform-state

   # Check DynamoDB table
   aws dynamodb describe-table --table-name cloudforge-terraform-locks
   ```

2. **Configure Dev Environment**
   - Navigate to `infra/terraform/environments/dev/`
   - Edit `main.tf` and uncomment the backend block (lines 16-22)
   - Run `terraform init -migrate-state`

3. **Configure Prod Environment**
   - Navigate to `infra/terraform/environments/prod/`
   - Edit `main.tf` and uncomment the backend block
   - Run `terraform init -migrate-state`

## 🚨 Troubleshooting

### Issue: Lock Gets Stuck

If Terraform crashes and doesn't release the lock:

```powershell
# View lock info
terraform force-unlock LOCK_ID

# Example
terraform force-unlock a1b2c3d4-5678-90ab-cdef-1234567890ab
```

⚠️ **Only force-unlock if you're SURE no one else is running Terraform!**

### Issue: Bucket Already Exists

If the bucket name is taken:

1. Edit `backend-setup/variables.tf`
2. Change `project_name` default to something unique
3. Re-run `terraform apply`

### Issue: Permission Denied

Ensure your AWS credentials have these permissions:

- `s3:CreateBucket`
- `s3:PutBucketVersioning`
- `s3:PutEncryptionConfiguration`
- `dynamodb:CreateTable`
- `dynamodb:DescribeTable`

## 📁 File Structure

```
backend-setup/
├── main.tf          # Module configuration
├── variables.tf     # Input variables
├── outputs.tf       # Exported values
└── README.md        # This file

../modules/terraform-state/
├── main.tf          # S3 + DynamoDB resources
├── variables.tf     # Module inputs
└── outputs.tf       # Module outputs
```

## 🔐 Security Features

✅ **Versioning** - Rollback to any previous state version  
✅ **Encryption** - AES-256 encryption at rest  
✅ **Public Access Blocked** - Prevents accidental exposure  
✅ **State Locking** - Prevents concurrent modifications  
✅ **IAM Access Control** - Only authorized users can access

## ⚠️ Important Notes

1. **This backend uses LOCAL state**
   - The backend-setup itself stores state locally (`terraform.tfstate`)
   - This is intentional (chicken-and-egg problem)
   - Keep this local state file safe!

2. **One-Time Setup**
   - Only needs to be run once per AWS account
   - Can be shared across multiple projects

3. **State File Contains Secrets**
   - Never commit `terraform.tfstate` to Git
   - State files contain passwords, keys, and sensitive data
   - S3 encryption protects this data

4. **Deletion Protection**
   - To destroy these resources: `terraform destroy`
   - ⚠️ This will delete ALL environment state files!
   - Only do this if you're decommissioning the entire project

## 📚 Additional Resources

- [Terraform S3 Backend Documentation](https://www.terraform.io/docs/backends/types/s3.html)
- [DynamoDB State Locking](https://www.terraform.io/docs/backends/state.html#state-locking)
- [AWS S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)

## 💡 Why Not Store State in Git?

**Problems with Git:**

- ❌ Secrets exposed in Git history (permanent)
- ❌ No state locking (merge conflicts destroy infrastructure)
- ❌ Large files bloat repository
- ❌ Anyone with repo access sees all credentials

**Benefits of S3 + DynamoDB:**

- ✅ Encrypted secrets
- ✅ Atomic state locking
- ✅ Versioning and rollback
- ✅ IAM-based access control
- ✅ Team collaboration safe

## 🎓 How This Fits into Overall Workflow

```
1. backend-setup/           👈 YOU ARE HERE
   ├── Creates S3 bucket
   └── Creates DynamoDB table

2. environments/dev/
   ├── Uses S3 backend
   └── Deploys dev infrastructure

3. environments/prod/
   ├── Uses S3 backend
   └── Deploys prod infrastructure
```

---

**Ready to proceed?** Run `terraform apply` to create your backend infrastructure! 🚀
