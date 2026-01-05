# GCP Cloud CLI Mastery for DevOps Engineers

Production-ready gcloud commands for real-world Google Cloud engineering.

---

## Essential gcloud Commands for DevOps

### Initial Setup

```bash
# Install gcloud CLI
curl https://sdk.cloud.google.com | bash

# Initialize and authenticate
gcloud init
gcloud auth login

# Set default project
gcloud config set project my-project-id

# Set default compute region/zone
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

---

## Real-World Use Cases

### 1. GCE Instance Management

```bash
# List all running instances across all zones
gcloud compute instances list --filter="status:RUNNING"

# Find instances by label
gcloud compute instances list --filter="labels.environment=production"

# SSH to instance (no need to manage keys!)
gcloud compute ssh instance-name --zone=us-central1-a

# Execute command on remote instance
gcloud compute ssh instance-name --command="sudo systemctl restart nginx"

# Stop all development instances (cost saving!)
gcloud compute instances list \
  --filter="labels.environment=development AND status:RUNNING" \
  --format="value(name,zone)" | while IFS=$'\t' read name zone; do
    gcloud compute instances stop $name --zone=$zone
done
```

### 2. GKE Cluster Operations

```bash
# List all GKE clusters
gcloud container clusters list

# Get kubectl credentials
gcloud container clusters get-credentials cluster-name --region us-central1

# Resize node pool
gcloud container clusters resize cluster-name \
  --node-pool default-pool \
  --num-nodes 5 \
  --region us-central1

# Upgrade cluster
gcloud container clusters upgrade cluster-name \
  --master \
  --cluster-version 1.28 \
  --region us-central1

# Create autopilot cluster (serverless K8s!)
gcloud container clusters create-auto my-cluster \
  --region us-central1
```

### 3. Cloud Storage (GCS) Operations

```bash
# List all buckets
gsutil ls

# Sync local directory to GCS
gsutil -m rsync -r ./local-dir gs://my-bucket/path/

# Make bucket public (use with caution!)
gsutil iam ch allUsers:objectViewer gs://my-bucket

# Set lifecycle policy (auto-delete old files)
cat > lifecycle.json << EOF
{
  "lifecycle": {
    "rule": [{
      "action": {"type": "Delete"},
      "condition": {"age": 30}
    }]
  }
}
EOF
gsutil lifecycle set lifecycle.json gs://my-bucket

# Find large files
gsutil du -sh gs://my-bucket/** | sort -h | tail -20
```

### 4. IAM and Permissions

```bash
# List IAM roles for project
gcloud projects get-iam-policy my-project-id

# Grant role to user
gcloud projects add-iam-policy-binding my-project-id \
  --member="user:devops@example.com" \
  --role="roles/compute.admin"

# Create custom role
gcloud iam roles create customDevOpsRole \
  --project=my-project-id \
  --title="Custom DevOps Role" \
  --permissions=compute.instances.start,compute.instances.stop

# List service accounts
gcloud iam service-accounts list

# Create service account
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions Automation"
```

### 5. Cloud SQL Management

```bash
# List Cloud SQL instances
gcloud sql instances list

# Create backup
gcloud sql backups create \
  --instance=prod-db

# Restore from backup
gcloud sql backups restore BACKUP_ID \
  --backup-instance=prod-db \
  --backup-location=us-central1

#  Connect to Cloud SQL via proxy
cloud_sql_proxy -instances=my-project:us-central1:prod-db=tcp:3306
```

### 6. Logging and Monitoring

```bash
# Tail real-time logs
gcloud logging tail "resource.type=gce_instance"

# Search logs for errors
gcloud logging read "severity>=ERROR" \
  --limit 50 \
  --format json

# Query logs with filter
gcloud logging read \
  'resource.type="k8s_container" AND 
   resource.labels.namespace_name="production" AND
   jsonPayload.message=~"error"' \
  --limit 100

# Create log-based metric
gcloud logging metrics create error_count \
  --description="Count of ERROR logs" \
  --log-filter='severity="ERROR"'
```

### 7. Cost Management

```bash
# Export billing to BigQuery
gcloud alpha billing accounts get-iam-policy BILLING_ACCOUNT_ID

# Query costs with BigQuery
bq query --use_legacy_sql=false '
SELECT
  service.description,
  SUM(cost) as total_cost
FROM `project.dataset.gcp_billing_export_v1_XXXXX`
WHERE DATE(_PARTITIONTIME) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY service.description
ORDER BY total_cost DESC
LIMIT 10
'

# List all disks (potential cost savings)
gcloud compute disks list --format="table(name,sizeGb,zone,users)"

# Find unused disks
gcloud compute disks list --filter="NOT users:*" --format="table(name,sizeGb,zone)"
```

### 8. Security and Compliance

```bash
# List firewall rules
gcloud compute firewall-rules list

# Find overly permissive firewall rules
gcloud compute firewall-rules list \
  --filter="sourceRanges=0.0.0.0/0" \
  --format="table(name,allowed,sourceRanges)"

# Disable default service account
gcloud compute instances create my-instance \
  --no-service-account \
  --no-scopes

# Enable OS Login (SSH key management)
gcloud compute project-info add-metadata \
  --metadata enable-oslogin=TRUE
```

---

## Advanced Patterns

### Multi-Project Operations

```bash
#!/bin/bash
# Iterate through all projects
for project in $(gcloud projects list --format="value(projectId)"); do
  echo "=== $project ==="
  gcloud compute instances list --project=$project
done
```

### Automated Instance Scheduling

```bash
#!/bin/bash
# Stop all non-production instances at night

gcloud compute instances list \
  --filter="labels.environment!=production AND status:RUNNING" \
  --format="csv[no-heading](name,zone)" | while IFS=, read name zone; do
    echo "Stopping $name in $zone"
    gcloud compute instances stop $name --zone=$zone --quiet
done
```

### Inventory Report

```bash
#!/bin/bash
# Generate infrastructure inventory

{
  echo "=== Compute Instances ==="
  gcloud compute instances list --format="table(name,zone,machineType,status)"
  
  echo -e "\n=== GKE Clusters ==="
  gcloud container clusters list --format="table(name,location,currentNodeCount,status)"
  
  echo -e "\n=== Cloud SQL ==="
  gcloud sql instances list --format="table(name,region,tier,state)"
  
  echo -e "\n=== Storage Buckets ==="
  gsutil ls
} | tee gcp-inventory-$(date +%Y%m%d).txt
```

---

## JQ Integration (JSON Parsing)

```bash
# Get instance details as JSON and parse
gcloud compute instances list --format=json | \
  jq -r '.[] | select(.status=="RUNNING") | 
    [.name, .machineType, .networkInterfaces[0].networkIP] | @tsv'

# Find instances with specific label
gcloud compute instances list --format=json | \
  jq -r '.[] | select(.labels.team=="platform") | .name'
```

---

## Cheat Sheet

```bash
# Compute Engine
gcloud compute instances list                      # List instances
gcloud compute instances start INSTANCE --zone=ZONE  # Start
gcloud compute instances stop INSTANCE --zone=ZONE   # Stop
gcloud compute ssh INSTANCE                        # SSH

# GKE
gcloud container clusters list                     # List clusters
gcloud container clusters get-credentials CLUSTER  # Get kubectl config

# Cloud Storage
gsutil ls                                          # List buckets
gsutil cp file.txt gs://bucket/                    # Upload
gsutil rsync -r dir gs://bucket/path/              # Sync

# Cloud SQL
gcloud sql instances list                          # List databases
gcloud sql backups create --instance=INSTANCE      # Create backup

# IAM
gcloud projects get-iam-policy PROJECT_ID          # Get IAM policy
gcloud iam service-accounts list                   # List service accounts

# Logging
gcloud logging tail "resource.type=gce_instance"   # Tail logs
gcloud logging read "severity>=ERROR" --limit 50   # Read errors
```

---

**Master gcloud and automate Google Cloud operations!** ☁️
