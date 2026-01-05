# Azure Cloud Automation Scripts

Production-ready shell scripts for Microsoft Azure automation.

## Structure

```
azure/
├── cost-optimization/    # Reduce Azure costs
├── security/             # NSG audits and compliance
├── monitoring/           # Azure Monitor integration
├── automation/           # VM, AKS automation
└── backup/               # Recovery Services Vault
```

## Cost Optimization

### [unused-resources.sh](cost-optimization/unused-resources.sh)
Find unused Azure resources (disks, public IPs, NSGs, VMs)

**Usage:**
```bash
# Scan subscription
./unused-resources.sh

# Specific subscription
AZURE_SUBSCRIPTION=sub-id ./unused-resources.sh
```

## Security

### [nsg-audit.sh](security/nsg-audit.sh)
Audit Network Security Groups for risky rules

**Checks:**
- Rules allowing Internet access (* or 0.0.0.0/0)
- RDP/SSH open to Internet
- Overly permissive inbound rules

**Usage:**
```bash
./nsg-audit.sh
```

## Backup

### [vm-backup.sh](backup/vm-backup.sh)
Enable and configure VM backups

**Usage:**
```bash
VAULT_NAME=my-vault RESOURCE_GROUP=my-rg VM_NAME=my-vm ./vm-backup.sh
```

## Prerequisites

```bash
# Install Azure CLI
az login

# Set subscription
az account set --subscription "subscription-name"

# Verify
az account show
```

## Common Patterns

### Multi-Subscription Operations
```bash
for sub in $(az account list --query "[].id" -o tsv); do
  AZURE_SUBSCRIPTION=$sub ./script.sh
done
```

### Resource Group Operations
```bash
for rg in $(az group list --query "[].name" -o tsv); do
  RESOURCE_GROUP=$rg ./script.sh
done
```

## Safety

✅ Dry-run mode by default  
✅ Clear output and logging  
✅ Error handling  

**Always test in development subscriptions first!**
