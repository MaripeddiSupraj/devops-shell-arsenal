#!/bin/bash
################################################################################
# Script: azure-vm-backup.sh
# Description: Backup Azure VMs using Recovery Services Vault
# Author: maripeddi supraj
################################################################################

set -euo pipefail

readonly VAULT_NAME="${VAULT_NAME:?VAULT_NAME required}"
readonly RESOURCE_GROUP="${RESOURCE_GROUP:?RESOURCE_GROUP required}"
readonly VM_NAME="${VM_NAME:?VM_NAME required}"
readonly POLICY_NAME="${POLICY_NAME:-DefaultPolicy}"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "INFO: Enabling backup for VM: $VM_NAME"

# Get VM ID
vm_id=$(az vm show --name "$VM_NAME" --resource-group "$RESOURCE_GROUP" --query id -o tsv)

# Enable backup
az backup protection enable-for-vm \
    --vault-name "$VAULT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --vm "$vm_id" \
    --policy-name "$POLICY_NAME"

log "INFO: Backup enabled. Triggering initial backup..."

# Trigger immediate backup
az backup protection backup-now \
    --vault-name "$VAULT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --container-name "$VM_NAME" \
    --item-name "$VM_NAME" \
    --retain-until "$(date -d '+30 days' '+%d-%m-%Y')"

log "INFO: Backup initiated successfully"
