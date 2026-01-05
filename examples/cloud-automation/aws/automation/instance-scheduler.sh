#!/bin/bash
################################################################################
# Script: aws-instance-scheduler.sh
# Description: Start/stop instances based on schedule to save costs
# Author: maripeddi supraj
################################################################################

set -euo pipefail

readonly ACTION="${1:-stop}"
readonly TAG_KEY="${TAG_KEY:-AutoStop}"
readonly TAG_VALUE="${TAG_VALUE:-true}"
readonly REGION="${AWS_REGION:-us-east-1}"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

if [[ "$ACTION" != "start" && "$ACTION" != "stop" ]]; then
    echo "Usage: $0 {start|stop}"
    exit 1
fi

log "INFO: Finding instances with tag $TAG_KEY=$TAG_VALUE"

instances=$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" \
              "Name=instance-state-name,Values=$([ "$ACTION" == "stop" ] && echo "running" || echo "stopped")" \
    --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
    --output text)

if [[ -z "$instances" ]]; then
    log "INFO: No instances found to $ACTION"
    exit 0
fi

while IFS=$'\t' read -r instance_id name; do
    log "INFO: ${ACTION^}ing instance: ${name:-$instance_id} ($instance_id)"
    aws ec2 "${ACTION}-instances" --instance-ids "$instance_id" --region "$REGION"
done <<< "$instances"

log "INFO: Complete"
