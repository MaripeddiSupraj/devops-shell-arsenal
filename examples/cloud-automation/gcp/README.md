# GCP Cloud Automation Scripts

Production-ready shell scripts for Google Cloud Platform automation.

## Structure

```
gcp/
├── cost-optimization/    # Reduce GCP costs
├── security/             # Firewall audits and IAM
├── monitoring/           # Stackdriver and logging
├── automation/           # GKE, GCE automation
└── backup/               # Backup strategies
```

## Cost Optimization

### [unused-disks.sh](cost-optimization/unused-disks.sh)
Find and delete unattached persistent disks

**Usage:**
```bash
# Scan project
./unused-disks.sh

# Different project
GCP_PROJECT=my-project ./unused-disks.sh

# Actually delete
DRY_RUN=false ./unused-disks.sh
```

## Security

### [firewall-audit.sh](security/firewall-audit.sh)
Audit firewall rules for security issues

**Checks:**
- Rules allowing 0.0.0.0/0 access
- SSH/RDP open to Internet
- Rules without target tags

**Usage:**
```bash
./firewall-audit.sh
```

## Automation

### [gke-autoscale.sh](automation/gke-autoscale.sh)
Configure GKE node pool autoscaling

**Usage:**
```bash
GKE_CLUSTER=my-cluster MIN_NODES=1 MAX_NODES=10 ./gke-autoscale.sh
```

## Prerequisites

```bash
# Install gcloud
gcloud init
gcloud auth login

# Set project
gcloud config set project PROJECT_ID
```

## Common Patterns

### Multi-Project Operations
```bash
for project in $(gcloud projects list --format="value(projectId)"); do
  GCP_PROJECT=$project ./script.sh
done
```

### Service Account Automation
```bash
# Activate service account
gcloud auth activate-service-account --key-file=key.json

./script.sh
```

## Safety

✅ Dry-run mode by default  
✅ Confirmation before destructive actions  
✅ Comprehensive error handling  

**Test in development projects first!**
