#!/bin/bash
################################################################################
# Script: gcp-firewall-audit.sh
# Description: Audit GCP firewall rules for security issues
# Author: maripeddi supraj
################################################################################

set -euo pipefail

readonly PROJECT="${GCP_PROJECT:-$(gcloud config get-value project)}"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "INFO: Auditing firewall rules in project: $PROJECT"

echo "========================================"
echo "  GCP FIREWALL SECURITY AUDIT"
echo "========================================"
echo ""

# Find rules allowing 0.0.0.0/0
log "INFO: Checking for overly permissive rules (0.0.0.0/0)"

gcloud compute firewall-rules list \
    --project="$PROJECT" \
    --filter="sourceRanges:0.0.0.0/0" \
    --format="table(name,direction,allowed,sourceRanges)" | while IFS= read -r line; do
    echo "⚠️  $line"
done

echo ""

# Find rules allowing SSH from anywhere
log "INFO: Checking for SSH access from anywhere"

gcloud compute firewall-rules list \
    --project="$PROJECT" \
    --filter="allowed.ports:22 AND sourceRanges:0.0.0.0/0" \
    --format="table(name,targetTags,sourceRanges)"

echo ""

# Find rules with no target tags (applies to all instances)
log "INFO: Checking for rules without target tags"

gcloud compute firewall-rules list \
    --project="$PROJECT" \
    --filter="-targetTags:* AND direction:INGRESS" \
    --format="table(name,allowed,sourceRanges)"

echo ""

log "INFO: Audit complete. Review findings above."
