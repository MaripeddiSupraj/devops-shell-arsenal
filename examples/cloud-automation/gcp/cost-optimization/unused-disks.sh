#!/bin/bash
################################################################################
# Script: gcp-unused-disks.sh
# Description: Find and delete unattached GCP persistent disks
# Author: maripeddi supraj
################################################################################

set -euo pipefail

readonly PROJECT="${GCP_PROJECT:-$(gcloud config get-value project)}"
readonly DRY_RUN="${DRY_RUN:-true}"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "INFO: Scanning for unattached disks in project: $PROJECT"

# Get all zones
zones=$(gcloud compute zones list --format="value(name)")

total_size=0
total_cost=0

for zone in $zones; do
    unattached=$(gcloud compute disks list \
        --project="$PROJECT" \
        --filter="zone:$zone AND -users:*" \
        --format="csv[no-heading](name,sizeGb,type)")
    
    if [[ -z "$unattached" ]]; then
        continue
    fi
    
    while IFS=, read -r disk_name size_gb disk_type; do
        # Calculate monthly cost (approximate)
        if [[ "$disk_type" == *"ssd"* ]]; then
            cost=$(echo "scale=2; $size_gb * 0.17" | bc)
        else
            cost=$(echo "scale=2; $size_gb * 0.04" | bc)
        fi
        
        total_size=$((total_size + size_gb))
        total_cost=$(echo "scale=2; $total_cost + $cost" | bc)
        
        log "FOUND: $disk_name in $zone (${size_gb}GB, ~\$${cost}/month)"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "DRY-RUN: Would delete $disk_name"
        else
            log "INFO: Deleting $disk_name"
            gcloud compute disks delete "$disk_name" --zone="$zone" --quiet
        fi
    done <<< "$unattached"
done

log "INFO: Total unattached disks: ${total_size}GB"
log "INFO: Estimated monthly savings: \$${total_cost}"

[[ "$DRY_RUN" == "true" ]] && log "INFO: This was a DRY-RUN. Use DRY_RUN=false to actually delete"
