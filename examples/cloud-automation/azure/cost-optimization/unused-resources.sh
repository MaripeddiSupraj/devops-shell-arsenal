#!/bin/bash
################################################################################
# Script: azure-unused-resources.sh
# Description: Find unused Azure resources to reduce costs
# Author: maripeddi supraj
################################################################################

set -euo pipefail

readonly SUBSCRIPTION="${AZURE_SUBSCRIPTION:-$(az account show --query id -o tsv)}"
readonly DRY_RUN="${DRY_RUN:-true}"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "INFO: Scanning subscription: $SUBSCRIPTION"

echo "========================================"
echo "  AZURE UNUSED RESOURCES REPORT"
echo "========================================"
echo ""

# Unattached managed disks
log "INFO: Finding unattached managed disks"

az disk list --query "[?managedBy==null].{Name:name,Size:diskSizeGb,Location:location}" -o table

unattached_disks=$(az disk list --query "[?managedBy==null].{name:name,size:diskSizeGb}" -o json)
total_disk_size=$(echo "$unattached_disks" | jq '[.[].size] | add // 0')
disk_cost=$(echo "scale=2; $total_disk_size * 0.05" | bc)

echo ""
log "INFO: Total unattached disk size: ${total_disk_size}GB (~\$${disk_cost}/month)"
echo ""

# Unused public IPs
log "INFO: Finding unused public IP addresses"

az network public-ip list --query "[?ipConfiguration==null].{Name:name,Location:location}" -o table

unused_ips=$(az network public-ip list --query "[?ipConfiguration==null]" -o json | jq '. | length')
ip_cost=$(echo "scale=2; $unused_ips * 3.00" | bc)

echo ""
log "INFO: Total unused public IPs: $unused_ips (~\$${ip_cost}/month)"
echo ""

# Stopped but allocated VMs (still charging for disks!)
log "INFO: Finding deallocated VMs (still incurring storage costs)"

az vm list -d --query "[?powerState=='VM deallocated'].{Name:name,ResourceGroup:resourceGroup,Location:location}" -o table

echo ""

# Network security groups with no associations
log "INFO: Finding unused network security groups"

az network nsg list --query "[?networkInterfaces==null && subnets==null].{Name:name,ResourceGroup:resourceGroup}" -o table

echo ""

total_monthly=$(echo "scale=2; $disk_cost + $ip_cost" | bc)

echo "========================================"
echo "  ESTIMATED MONTHLY SAVINGS: \$${total_monthly}"
echo "========================================"

[[ "$DRY_RUN" == "true" ]] && log "INFO: This was a DRY-RUN. Review findings above."
