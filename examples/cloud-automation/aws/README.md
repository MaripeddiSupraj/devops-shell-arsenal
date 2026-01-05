# AWS Cloud Automation Scripts

Production-ready shell scripts for AWS automation and operations.

## Structure

```
aws/
├── cost-optimization/    # Reduce AWS costs
├── security/             # Security audits and compliance
├── monitoring/           # CloudWatch and alerting
├── automation/           # Task automation
└── backup/               # Backup and disaster recovery
```

## Cost Optimization

### [unused-resources.sh](cost-optimization/unused-resources.sh)
Find and delete unused AWS resources (EBS volumes, Elastic IPs, load balancers, security groups)

**Usage:**
```bash
# Dry-run scan
./unused-resources.sh

# Actually delete resources
./unused-resources.sh --delete
```

### [snapshot-cleanup.sh](cost-optimization/snapshot-cleanup.sh)
Clean up old EBS snapshots based on retention policy

**Usage:**
```bash
# Default 30-day retention
./snapshot-cleanup.sh

# Custom retention
RETENTION_DAYS=60 ./snapshot-cleanup.sh

# Actually delete
DRY_RUN=false ./snapshot-cleanup.sh
```

## Security

### [aws-security-audit.sh](security/aws-security-audit.sh)
Comprehensive security audit across EC2, S3, IAM, RDS

**Checks:**
- Public S3 buckets
- Unencrypted EBS volumes
- Security groups with 0.0.0.0/0 access
- IAM users without MFA
- RDS instances without encryption
- Unused IAM access keys

**Usage:**
```bash
./aws-security-audit.sh -r us-east-1 -o security-report.txt
```

## Automation

### [instance-scheduler.sh](automation/instance-scheduler.sh)
Auto start/stop instances based on tags (cost savings!)

**Usage:**
```bash
# Stop all instances tagged AutoStop=true
./instance-scheduler.sh stop

# Start them back
./instance-scheduler.sh start

# Custom tag
TAG_KEY=Environment TAG_VALUE=development ./instance-scheduler.sh stop
```

**Example cron for office hours:**
```cron
# Stop at 7 PM
0 19 * * * /path/to/instance-scheduler.sh stop

# Start at 8 AM
0 8 * * 1-5 /path/to/instance-scheduler.sh start
```

## Prerequisites

```bash
# Install AWS CLI v2
aws configure

# Verify credentials
aws sts get-caller-identity
```

## Common Patterns

### Multi-Region Operations
```bash
for region in us-east-1 us-west-2 eu-west-1; do
  AWS_REGION=$region ./script.sh
done
```

### Cross-Account
```bash
# Assume role first
temp_role=$(aws sts assume-role --role-arn arn:aws:iam::123456789:role/ReadOnly --role-session-name script)
export AWS_ACCESS_KEY_ID=$(echo $temp_role | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $temp_role | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $temp_role | jq -r '.Credentials.SessionToken')

./script.sh
```

## Safety First

✅ All scripts have dry-run mode by default  
✅ Confirmation prompts for destructive operations  
✅ Comprehensive logging  
✅ Error handling with rollback where applicable  

**Always test in non-production first!**
