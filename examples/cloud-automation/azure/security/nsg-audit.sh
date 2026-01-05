#!/bin/bash
################################################################################
# Script: azure-nsg-audit.sh
# Description: Audit Azure Network Security Groups for security issues
# Author: maripeddi supraj
################################################################################

set -euo pipefail

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "INFO: Auditing Azure Network Security Groups"

echo "========================================"
echo "  AZURE NSG SECURITY AUDIT"
echo "========================================"
echo ""

# Get all NSGs
nsgs=$(az network nsg list --query "[].{name:name,rg:resourceGroup}" -o json)

echo "$nsgs" | jq -r '.[] | "\(.name),\(.rg)"' | while IFS=, read -r nsg_name rg; do
    log "INFO: Checking NSG: $nsg_name"
    
    # Find rules allowing Internet (0.0.0.0/0 or *)
    open_rules=$(az network nsg rule list \
        --nsg-name "$nsg_name" \
        --resource-group "$rg" \
        --query "[?destinationAddressPrefix=='*' || destinationAddressPrefix=='0.0.0.0/0' || sourceAddressPrefix=='*' || sourceAddressPrefix=='0.0.0.0/0'].{Name:name,Access:access,Direction:direction,Port:destinationPortRange,Source:sourceAddressPrefix}" \
        -o table)
    
    if [[ -n "$open_rules" ]]; then
        echo "⚠️  OVERLY PERMISSIVE RULES in $nsg_name:"
        echo "$open_rules"
        echo ""
    fi
    
    # Find rules allowing RDP/SSH from anywhere
    dangerous_rules=$(az network nsg rule list \
        --nsg-name "$nsg_name" \
        --resource-group "$rg" \
        --query "[?(destinationPortRange=='22' || destinationPortRange=='3389') && (sourceAddressPrefix=='*' || sourceAddressPrefix=='0.0.0.0/0')].{Name:name,Port:destinationPortRange,Source:sourceAddressPrefix}" \
        -o table)
    
    if [[ -n "$dangerous_rules" ]]; then
        echo "🚨 CRITICAL: RDP/SSH open to Internet in $nsg_name:"
        echo "$dangerous_rules"
        echo ""
    fi
done

log "INFO: Audit complete"
