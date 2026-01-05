# AWS CLI Mastery for DevOps Engineers

Production-ready AWS CLI commands and scripts for real-world cloud engineering.

---

## Why This Guide is Different

This is **NOT** a basic tutorial. These are battle-tested AWS CLI patterns used daily by cloud engineers for:
- Production incident response
- Cost optimization
- Security auditing
- Infrastructure automation
- Compliance reporting

---

## Essential Setup

```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Configure with SSO (modern approach)
aws configure sso

# Or traditional (for automation)
aws configure
```

---

## Real-World Use Cases

### 1. Incident Response - Find and Restart Failed Instances

```bash
# Find all stopped instances with their names
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=stopped" \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
  --output table

# Start specific instance
aws ec2 start-instances --instance-ids i-1234567890abcdef0

# Bulk start all stopped instances in production (use with caution!)
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=stopped" \
            "Name=tag:Environment,Values=production" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text | xargs -n1 aws ec2 start-instances --instance-ids
```

### 2. Cost Optimization - Find Expensive Resources

```bash
# List all EBS volumes sorted by size
aws ec2 describe-volumes \
  --query 'Volumes[].[VolumeId,Size,State,VolumeType]' \
  --output table | sort -k2 -rn

# Calculate total EBS cost
aws ec2 describe-volumes --query 'Volumes[].Size' --output text | \
  awk '{sum+=$1} END {printf "Total: %d GB, Est. Cost: $%.2f/month\n", sum, sum*0.10}'

# Find unattached volumes (wasting money!)
aws ec2 describe-volumes \
  --filters "Name=status,Values=available" \
  --query 'Volumes[].[VolumeId,Size,CreateTime]' \
  --output table

# Delete specific unattached volume ( DRY-RUN first!)
aws ec2 delete-volume --volume-id vol-1234567890abcdef0 --dry-run
```

### 3. Security Audit - Find Publicly Accessible Resources

```bash
# Find security groups allowing 0.0.0.0/0 access
aws ec2 describe-security-groups \
  --query 'SecurityGroups[?IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`]]].{GroupId:GroupId,GroupName:GroupName,VpcId:VpcId}' \
  --output table

# Find S3 buckets with public access
for bucket in $(aws s3 ls | awk '{print $3}'); do
  public=$(aws s3api get-bucket-acl --bucket $bucket --query 'Grants[?Grantee.URI==`http://acs.amazonaws.com/groups/global/AllUsers`]' --output text)
  if [ -n "$public" ]; then
    echo "⚠️  PUBLIC: $bucket"
  fi
done

# Find RDS instances without encryption
aws rds describe-db-instances \
  --query 'DBInstances[?!StorageEncrypted].{DBInstanceIdentifier:DBInstanceIdentifier,Engine:Engine,DBInstanceClass:DBInstanceClass}' \
  --output table
```

### 4. Tagging Compliance - Find Untagged Resources

```bash
# EC2 instances without required tags
aws ec2 describe-instances \
  --query 'Reservations[].Instances[?!Tags || !contains(Tags[].Key, `Environment`)].{ID:InstanceId,Name:Tags[?Key==`Name`].Value|[0]}' \
  --output table

# Bulk tag instances
aws ec2 create-tags \
  --resources i-1234567890abcdef0 i-0987654321fedcba0 \
  --tags Key=Environment,Value=production Key=Owner,Value=platform-team
```

### 5. AMI Management - Cleanup Old Images

```bash
# Find AMIs older than 90 days
aws ec2 describe-images --owners self \
  --query "Images[?CreationDate<='$(date -u -d '90 days ago' +%Y-%m-%dT%H:%M:%S.000Z)'].{ID:ImageId,Name:Name,CreatedOn:CreationDate}" \
  --output table

# Deregister old AMI (deletes the image)
aws ec2 deregister-image --image-id ami-1234567890abcdef0

# Delete associated snapshots
aws ec2 describe-snapshots --owner-ids self \
  --filters "Name=description,Values=*ami-1234567890abcdef0*" \
  --query 'Snapshots[].SnapshotId' --output text | \
  xargs -n1 aws ec2 delete-snapshot --snapshot-id
```

---

## Advanced Querying with JMESPath

### Complex Filtering

```bash
# Find instances with specific tag AND running state
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=production" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,PrivateIpAddress,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Get ELB health status for all targets
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-targets/50dc6c495c0c9188 \
  --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State,TargetHealth.Reason]' \
  --output table
```

### Custom JSON Output

```bash
# Build custom inventory
aws ec2 describe-instances --query '{
  total_instances: length(Reservations[].Instances[]),
  running: length(Reservations[].Instances[?State.Name==`running`]),
  stopped: length(Reservations[].Instances[?State.Name==`stopped`])
}'
```

---

## Lambda Function Management

```bash
# List all Lambda functions with runtime and memory
aws lambda list-functions \
  --query 'Functions[].[FunctionName,Runtime,MemorySize,LastModified]' \
  --output table

# Find functions using deprecated runtimes
aws lambda list-functions \
  --query 'Functions[?Runtime==`python3.7` || Runtime==`nodejs12.x`].[FunctionName,Runtime]' \
  --output table

# Update function memory (performance tuning)
aws lambda update-function-configuration \
  --function-name my-function \
  --memory-size 512

# Invoke function and see response
aws lambda invoke \
  --function-name my-function \
  --payload '{"key":"value"}' \
  --cli-binary-format raw-in-base64-out \
  response.json && cat response.json
```

---

## S3 Operations

### Bulk Operations

```bash
# Sync with delete (mirror local to S3)
aws s3 sync ./local-dir s3://my-bucket/path/ --delete

# Copy entire bucket to another region
aws s3 sync s3://source-bucket s3://dest-bucket --source-region us-east-1 --region eu-west-1

# Find large files in bucket
aws s3api list-objects-v2 --bucket my-bucket \
  --query 'Contents[?Size>`1073741824`].[Key,Size]' \
  --output table

# Set lifecycle policy (auto-delete old versions)
cat > lifecycle.json << EOF
{
  "Rules": [{
    "Id": "DeleteOldVersions",
    "Status": "Enabled",
    "NoncurrentVersionExpiration": {"NoncurrentDays": 30}
  }]
}
EOF
aws s3api put-bucket-lifecycle-configuration \
  --bucket my-bucket \
  --lifecycle-configuration file://lifecycle.json
```

### Access Control

```bash
# Block all public access (security best practice)
aws s3api put-public-access-block \
  --bucket my-bucket \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket my-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket my-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'
```

---

## CloudWatch Logs

```bash
# Tail logs in real-time
aws logs tail /aws/lambda/my-function --follow

# Search logs for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/my-function \
  --filter-pattern "ERROR" \
  --start-time $(date -u -d '1 hour ago' +%s)000

# Query logs with Insights
aws logs start-query \
  --log-group-name /aws/lambda/my-function \
  --start-time $(date -u -d '1 day ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20'

# Get query results
aws logs get-query-results --query-id <query-id-from-previous-command>
```

---

## IAM Security

```bash
# List users without MFA
aws iam get-credential-report
aws iam list-users --query 'Users[].UserName' --output text | while read user; do
  mfa=$(aws iam list-mfa-devices --user-name $user --query 'MFADevices' --output text)
  if [ -z "$mfa" ]; then
    echo "⚠️  No MFA: $user"
  fi
done

# Find overly permissive roles
aws iam list-roles --query 'Roles[].RoleName' --output text | while read role; do
  policies=$(aws iam list-attached-role-policies --role-name $role --query 'AttachedPolicies[?PolicyName==`AdministratorAccess`]')
  if [ "$policies" != "[]" ]; then
    echo "⚠️  Admin access: $role"
  fi
done

# Find unused access keys
aws iam list-users --query 'Users[].UserName' --output text | while read user; do
  aws iam list-access-keys --user-name $user \
    --query 'AccessKeyMetadata[].[UserName,AccessKeyId,CreateDate]' \
    --output table
done
```

---

## RDS Database Management

```bash
# List all RDS instances with key info
aws rds describe-db-instances \
  --query 'DBInstances[].[DBInstanceIdentifier,Engine,DBInstanceClass,MultiAZ,StorageEncrypted,PubliclyAccessible]' \
  --output table

# Create snapshot before maintenance
aws rds create-db-snapshot \
  --db-instance-identifier prod-db \
  --db-snapshot-identifier prod-db-$(date +%Y%m%d-%H%M%S)

# Modify instance (scaling)
aws rds modify-db-instance \
  --db-instance-identifier prod-db \
  --db-instance-class db.r5.xlarge \
  --apply-immediately

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier restored-db \
  --db-snapshot-identifier prod-db-20260105-120000
```

---

## Cost and Billing

```bash
# Get current month cost
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --query 'ResultsByTime[].Total.BlendedCost'

# Cost by service
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[].Groups[]' \
  --output table
```

---

## Automation Scripts

### Multi-Region Instance Inventory

```bash
#!/bin/bash
for region in us-east-1 us-west-2 eu-west-1 ap-southeast-1; do
  echo "=== $region ==="
  aws ec2 describe-instances --region $region \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].[InstanceId,InstanceType,Tags[?Key==`Name`].Value|[0]]' \
    --output table
done
```

### Cross-Account Resource Inventory

```bash
#!/bin/bash
# Requires assume-role permissions
for account in 123456789012 234567890123; do
  temp_creds=$(aws sts assume-role \
    --role-arn "arn:aws:iam::$account:role/ReadOnlyRole" \
    --role-session-name inventory)
  
  export AWS_ACCESS_KEY_ID=$(echo $temp_creds | jq -r '.Credentials.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo $temp_creds | jq -r '.Credentials.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo $temp_creds | jq -r '.Credentials.SessionToken')
  
  echo "=== Account $account ==="
  aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --output text | wc -w
  
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
done
```

---

## Pro Tips

### 1. Use Profiles for Multi-Account
```bash
# Configure profiles
aws configure --profile prod
aws configure --profile staging

# Use specific profile
aws s3 ls --profile prod

# Set default profile
export AWS_PROFILE=prod
```

### 2. Output Formats
```bash
# Table for humans
aws ec2 describe-instances --output table

# JSON for scripting
aws ec2 describe-instances --output json | jq '.Reservations[].Instances[].InstanceId'

# Text for pipelines
aws ec2 describe-instances --output text --query 'Reservations[].Instances[].InstanceId'
```

### 3. Use CLI Skeletons
```bash
# Generate input template
aws ec2 run-instances --generate-cli-skeleton > instance-template.json

# Edit template, then use it
aws ec2 run-instances --cli-input-json file://instance-template.json
```

---

## Cheat Sheet

```bash
# EC2
aws ec2 describe-instances                    # List instances
aws ec2 start-instances --instance-ids i-xxx  # Start instance
aws ec2 stop-instances --instance-ids i-xxx   # Stop instance
aws ec2 terminate-instances --instance-ids    # Terminate

# S3
aws s3 ls                                     # List buckets
aws s3 ls s3://bucket/                        # List objects
aws s3 cp file.txt s3://bucket/               # Upload
aws s3 sync ./dir s3://bucket/path/           # Sync directory

# Lambda
aws lambda list-functions                     # List functions
aws lambda invoke --function-name func out.json  # Invoke

# RDS
aws rds describe-db-instances                 # List databases
aws rds create-db-snapshot --db-instance-identifier db --db-snapshot-identifier snap

# IAM
aws iam list-users                            # List users
aws iam list-roles                            # List roles
```

---

**Master AWS CLI and automate cloud operations like a pro!** ☁️
