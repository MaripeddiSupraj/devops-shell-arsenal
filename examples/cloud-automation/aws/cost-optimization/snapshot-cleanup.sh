#!/bin/bash
################################################################################
# Script: aws-snapshot-cleanup.sh
# Description: Clean up old EBS snapshots to reduce costs
# Author: maripeddi supraj
################################################################################

set -euo pipefail

readonly RETENTION_DAYS="${RETENTION_DAYS:-30}"
readonly REGION="${AWS_REGION:-us-east-1}"
readonly DRY_RUN="${DRY_RUN:-true}"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "INFO: Finding snapshots older than $RETENTION_DAYS days in $REGION"

cutoff_date=$(date -u -d "$RETENTION_DAYS days ago" +%Y-%m-%d 2>/dev/null || date -u -v-${RETENTION_DAYS}d +%Y-%m-%d)

aws ec2 describe-snapshots --owner-ids self --region "$REGION" \
    --query "Snapshots[?StartTime<='${cutoff_date}'].{ID:SnapshotId,Date:StartTime,Size:VolumeSize,Desc:Description}" \
    --output table

old_snapshots=$(aws ec2 describe-snapshots --owner-ids self --region "$REGION" \
    --query "Snapshots[?StartTime<='${cutoff_date}'].SnapshotId" --output text)

if [[ -z "$old_snapshots" ]]; then
    log "INFO: No old snapshots found"
    exit 0
fi

total_size=0
count=0

for snap_id in $old_snapshots; do
    size=$(aws ec2 describe-snapshots --snapshot-ids "$snap_id" --region "$REGION" \
        --query 'Snapshots[0].VolumeSize' --output text)
    
    ((total_size += size))
    ((count++))
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY-RUN: Would delete snapshot $snap_id (${size}GB)"
    else
        log "INFO: Deleting snapshot $snap_id (${size}GB)"
        aws ec2 delete-snapshot --snapshot-id "$snap_id" --region "$REGION"
    fi
done

monthly_savings=$(echo "scale=2; $total_size * 0.05" | bc)
log "INFO: Total snapshots: $count, Total size: ${total_size}GB"
log "INFO: Estimated monthly savings: \$${monthly_savings}"

[[ "$DRY_RUN" == "true" ]] && log "INFO: This was a DRY-RUN. Use DRY_RUN=false to actually delete"
