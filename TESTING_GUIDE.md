# EC2 Deployment - Testing & Conflict Resolution Guide

## ✅ Changes Made in Staging Branch

### 1. **Database Conflict Resolution**

- ✅ Removed manual SQL table creation from EC2 user_data script
- ✅ Unified schema across Lambda (db_init.js, database-setup.js) and Prisma
- ✅ Let Prisma handle all schema management via `prisma db push`
- ✅ Removed deprecated columns: `word_count`, `reading_time`
- ✅ Standardized data types: `size` as BIGINT, `content_type` as VARCHAR(100)

### 2. **Code Cleanup**

- ✅ Removed mysql-client installation (not needed, Prisma handles DB)
- ✅ Removed manual CREATE TABLE SQL from user_data.sh.tpl
- ✅ Simplified deployment flow
- ✅ Added proper error handling

### 3. **Files Created/Modified**

```
Infrastructure/
├── EC2/
│   ├── main.tf              (cleaned)
│   ├── user_data.sh.tpl     (cleaned, no manual DB init)
│   ├── variables.tf         (cleaned)
│   └── outputs.tf           (new)
├── ETL/lambda/
│   └── db_init.js           (updated to unified schema)
└── DATABASE_SCHEMA.md       (new - single source of truth)
```

## 🔍 Testing Plan

### Phase 1: Staging Environment Testing

#### Step 1: Update dev/main.tf

Add EC2 module to dev environment:

```hcl
module "ec2_app" {
  source                     = "../Infrastructure/EC2"
  project                    = "telkom-ai-visionary-writings"
  environment                = "dev"
  vpc_id                     = module.vpc.vpc_id
  subnet_id                  = module.vpc.public_subnet_ids[0]
  infra_security_group_id    = module.vpc.db_security_group_id
  iam_instance_profile       = aws_iam_instance_profile.ssm_profile.name
  instance_type              = "t3.small"  # Use smaller for dev
  my_ip_for_ssh              = var.my_ip_for_ssh
  ssh_public_key             = var.ssh_public_key
  github_repo_url            = var.github_repo_url
  github_token_secret_arn    = var.github_token_secret_arn

  env_vars = {
    DB_HOST     = module.rds.db_endpoint
    DB_USER     = module.rds.db_username
    DB_PASSWORD = module.rds.db_password
    DB_NAME     = module.rds.db_name
    DB_PORT     = "3306"
    NODE_ENV    = "development"
    # Add other app-specific env vars
  }
}
```

#### Step 2: Add Required Variables to dev/variables.tf

Ensure the following variables are present in `dev/variables.tf`. They are required for the EC2 module but do not have default values. You will provide values for them in the next step.

- `github_repo_url`
- `github_token_secret_arn`
- `my_ip_for_ssh`
- `ssh_public_key`

#### Step 3: Add Values to dev/terraform.tfvars

Create a file named `terraform.tfvars` in the `dev/` directory. This file will provide values for the variables that don't have defaults.

**Do not commit `terraform.tfvars` to version control**, as it contains sensitive information like your IP address and SSH key.

**Example `dev/terraform.tfvars`:**

```hcl
# Replace these placeholder values with your actual data.
# To find your IP, you can search "what is my ip" in a web browser.
my_ip_for_ssh              = "1.2.3.4/32"
# This should be the content of your public SSH key file (e.g., ~/.ssh/id_rsa.pub)
ssh_public_key             = "ssh-rsa AAAA..."

github_repo_url            = "github.com/your-org/your-repo.git"
github_token_secret_arn    = "arn:aws:secretsmanager:af-south-1:123456789012:secret:your-github-token-secret-name-xxxxxx"
```

#### Step 4: Deploy to Dev

```bash
cd dev
terraform init
terraform plan
terraform apply
```

#### Step 5: Verify EC2 Deployment

```bash
# Get EC2 public IP
terraform output

# Connect via AWS SSM
# Option 1 (CLI):
# aws ssm start-session --target <INSTANCE_ID>
# Option 2 (Console):
# Go to AWS Console > EC2 > Select Instance > Click "Connect" > Select "Session Manager" tab > Click "Connect"

# Check logs
sudo tail -f /var/log/user-data.log

# Verify app is running
pm2 status
pm2 logs astro-app

# Check database connection
mysql -h <RDS_ENDPOINT> -u <USER> -p<PASSWORD> <DB_NAME> -e "SHOW TABLES;"
mysql -h <RDS_ENDPOINT> -u <USER> -p<PASSWORD> <DB_NAME> -e "DESCRIBE content_uploads;"
```

### Phase 2: Database Conflict Testing

#### Test 1: Verify Schema Consistency

```bash
# On EC2 instance
cd /home/ubuntu/app
npx prisma db pull  # Pull current schema
cat prisma/schema.prisma  # Verify matches expected schema
```

#### Test 2: Test Lambda ETL Functions

```bash
# Trigger Lambda db_init function
aws lambda invoke --function-name telkom-ai-visionary-writings-dev-db-init response.json

# Check response
cat response.json

# Verify no schema conflicts
mysql -h <RDS_ENDPOINT> -u <USER> -p<PASSWORD> <DB_NAME> -e "DESCRIBE content_uploads;"
```

#### Test 3: Test File Upload Flow

1. Upload a file via the app
2. Verify it appears in S3
3. Verify Lambda processes it
4. Check database record created
5. Verify no duplicate/conflicting records

### Phase 3: Production Deployment

#### Step 1: Update prod/main.tf

```hcl
module "ec2_app" {
  source                     = "../Infrastructure/EC2"
  project                    = "telkom-ai-visionary-writings"
  environment                = "prod"
  vpc_id                     = module.vpc.vpc_id
  subnet_id                  = module.vpc.public_subnet_ids[0]
  infra_security_group_id    = module.vpc.db_security_group_id
  instance_type              = "t3.medium"  # Larger for prod
  my_ip_for_ssh              = var.my_ip_for_ssh
  ssh_public_key             = var.ssh_public_key
  github_repo_url            = var.github_repo_url
  github_token_secret_arn    = var.github_token_secret_arn

  env_vars = {
    DB_HOST     = module.rds.db_endpoint
    DB_USER     = module.rds.db_username
    DB_PASSWORD = module.rds.db_password
    DB_NAME     = module.rds.db_name
    DB_PORT     = "3306"
    NODE_ENV    = "production"
    # Add other app-specific env vars
  }
}
```

#### Step 2: Uncomment Lambda ETL in prod/main.tf

```hcl
module "lambda_etl" {
  source                = "../Infrastructure/ETL"
  project               = "telkom-ai-visionary-writings"
  environment           = "prod"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  database_url          = module.rds.database_url
  rds_security_group_id = module.vpc.db_security_group_id
}
```

## 🚨 Potential Issues & Solutions

### Issue 1: Schema Mismatch After Deployment

**Symptom**: Prisma errors about missing columns
**Solution**:

```bash
# On EC2
cd /home/ubuntu/app
npx prisma db push --force-reset  # CAUTION: Drops data
# OR
npx prisma migrate deploy  # If using migrations
```

### Issue 2: Lambda Can't Write to Database

**Symptom**: Lambda timeout or permission errors
**Solution**:

- Verify Lambda is in VPC private subnets
- Check security group allows Lambda → RDS
- Verify database credentials in Lambda env vars

### Issue 3: EC2 Can't Connect to RDS

**Symptom**: Connection timeout during user_data
**Solution**:

- Verify EC2 security group is added to RDS security group ingress
- Check `infra_security_group_id` is correctly passed
- Verify RDS is in private subnet, EC2 in public subnet with route to private

### Issue 4: Duplicate Records

**Symptom**: Same file creates multiple DB entries
**Solution**:

- Add unique constraint on filename
- Implement idempotency in Lambda
- Check for existing records before INSERT

## 📋 Pre-Deployment Checklist

- [ ] GitHub token stored in AWS Secrets Manager
- [ ] SSH key pair generated and public key ready
- [ ] Your IP address for SSH access identified
- [ ] RDS database credentials configured
- [ ] VPC with public and private subnets exists
- [ ] Security groups properly configured
- [ ] S3 bucket for content uploads exists
- [ ] Prisma schema in app repo matches DATABASE_SCHEMA.md
- [ ] All environment variables identified and documented
- [ ] Backup strategy for RDS in place

## 🔄 Rollback Plan

If deployment fails:

```bash
# Destroy EC2 resources
cd dev  # or prod
terraform destroy -target=module.ec2_app

# Revert database schema if needed
mysql -h <RDS_ENDPOINT> -u <USER> -p<PASSWORD> <DB_NAME> < backup.sql
```

## 📊 Monitoring

After deployment, monitor:

- CloudWatch Logs: `/var/log/user-data.log`
- PM2 logs: `pm2 logs astro-app`
- Lambda logs: CloudWatch Logs for each Lambda function
- RDS connections: CloudWatch RDS metrics
- Application health: HTTP checks on port 80/443

## 🎯 Success Criteria

- [ ] EC2 instance launches successfully
- [ ] Application clones from GitHub
- [ ] Prisma schema syncs to RDS
- [ ] App builds and starts with PM2
- [ ] Nginx reverse proxy works
- [ ] Can access app via public IP
- [ ] File uploads work end-to-end
- [ ] Lambda functions process files
- [ ] Database records created correctly
- [ ] No schema conflicts between EC2 and Lambda
