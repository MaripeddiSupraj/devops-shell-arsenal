#!/bin/bash
################################################################################
# Script: gcp-gke-node-pool-autoscale.sh
# Description: Configure GKE node pool autoscaling
# Author: maripeddi supraj
################################################################################

set -euo pipefail

readonly CLUSTER="${GKE_CLUSTER:?GKE_CLUSTER required}"
readonly NODE_POOL="${NODE_POOL:-default-pool}"
readonly REGION="${GCP_REGION:-us-central1}"
readonly MIN_NODES="${MIN_NODES:-1}"
readonly MAX_NODES="${MAX_NODES:-10}"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "INFO: Configuring autoscaling for cluster $CLUSTER, pool $NODE_POOL"
log "INFO: Min nodes: $MIN_NODES, Max nodes: $MAX_NODES"

gcloud container clusters update "$CLUSTER" \ 
    --enable-autoscaling \
    --node-pool "$NODE_POOL" \
    --min-nodes "$MIN_NODES" \
    --max-nodes "$MAX_NODES" \
    --region "$REGION"

log "INFO: Autoscaling configured successfully"

# Show current status
gcloud container node-pools describe "$NODE_POOL" \
    --cluster="$CLUSTER" \
    --region="$REGION" \
    --format="table(name,autoscaling.minNodeCount,autoscaling.maxNodeCount,autoscaling.enabled)"
