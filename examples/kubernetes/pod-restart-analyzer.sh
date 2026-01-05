#!/bin/bash
################################################################################
# Script Name: pod-restart-analyzer.sh
# Description: Analyze pod restart patterns to identify problematic workloads
# Usage: ./pod-restart-analyzer.sh [options]
# Author: maripeddi supraj
# Dependencies: kubectl, jq
################################################################################

set -euo pipefail

readonly SCRIPT_NAME=$(basename "$0")
readonly NAMESPACE="${NAMESPACE:-all}"
readonly MIN_RESTARTS="${MIN_RESTARTS:-3}"
readonly TIME_WINDOW="${TIME_WINDOW:-24h}"

# Colors
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Analyze pod restart patterns to identify and troubleshoot problematic workloads.

OPTIONS:
    -n, --namespace NS      Kubernetes namespace (default: all namespaces)
    -m, --min-restarts N    Minimum restart count to report (default: $MIN_RESTARTS)
    -t, --time-window TIME  Time window to analyze (default: $TIME_WINDOW)
    -o, --output FORMAT     Output format: table, json, detailed (default: table)
    --debug                 Show debug information from recent pod logs
    -h, --help              Display this help message

EXAMPLES:
    # Analyze all namespaces
    $SCRIPT_NAME

    # Analyze specific namespace
    $SCRIPT_NAME -n production

    # Find pods with 5+ restarts
    $SCRIPT_NAME -m 5

    # Show detailed output with logs
    $SCRIPT_NAME --debug

TIME FORMATS:
    24h, 7d, 1w, etc.

EOF
    exit 0
}

log() {
    local level=$1; shift
    echo -e "${GREEN}[$level]${NC} $*" >&2
}

check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}kubectl is required but not installed${NC}"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}Cannot connect to Kubernetes cluster${NC}"
        exit 1
    fi
}

################################################################################
# Get pods with restarts
################################################################################
get_restarting_pods() {
    local namespace=$1
    local min_restarts=$2
    
    local ns_flag=""
    if [[ "$namespace" != "all" ]]; then
        ns_flag="-n $namespace"
    else
        ns_flag="--all-namespaces"
    fi
    
    # Get pods with restart counts
    kubectl get pods $ns_flag -o json | jq -r --arg min "$min_restarts" '
        .items[] |
        select(.status.containerStatuses != null) |
        {
            namespace: .metadata.namespace,
            pod: .metadata.name,
            node: .spec.nodeName,
            containers: [
                .status.containerStatuses[] |
                select(.restartCount >= ($min | tonumber)) |
                {
                    name: .name,
                    restarts: .restartCount,
                    ready: .ready,
                    state: .state,
                    lastState: .lastState
                }
            ]
        } |
        select(.containers | length > 0) |
        [.namespace, .pod, .node, (.containers | length), (.containers | map(.restarts) | add)] |
        @tsv
    '
}

################################################################################
# Analyze restart reasons
################################################################################
analyze_restart_reasons() {
    local namespace=$1
    local pod=$2
    
    echo -e "\n${BLUE}━━━ Analyzing Pod: $pod in $namespace ━━━${NC}\n"
    
    # Get pod details
    local pod_info=$(kubectl get pod "$pod" -n "$namespace" -o json 2>/dev/null || echo '{}')
    
    # Container statuses
    echo -e "${YELLOW}Container Statuses:${NC}"
    echo "$pod_info" | jq -r '
        .status.containerStatuses[]? |
        "  • \(.name): \(.restartCount) restarts, State: \(.state | keys[0]), Ready: \(.ready)"
    '
    
    echo ""
    
    # Check for OOMKilled
    local oom_killed=$(echo "$pod_info" | jq -r '
        .status.containerStatuses[]? |
        select(.lastState.terminated.reason == "OOMKilled") |
        .name
    ')
    
    if [[ -n "$oom_killed" ]]; then
        echo -e "${RED}⚠ OOMKilled detected in containers: $oom_killed${NC}"
        echo "  Recommendation: Increase memory limits"
        echo ""
    fi
    
    # Check for CrashLoopBackOff
    local crash_loop=$(echo "$pod_info" | jq -r '
        .status.containerStatuses[]? |
        select(.state.waiting.reason == "CrashLoopBackOff") |
        .name
    ')
    
    if [[ -n "$crash_loop" ]]; then
        echo -e "${RED}⚠ CrashLoopBackOff detected in containers: $crash_loop${NC}"
        echo "  Recommendation: Check application logs for errors"
        echo ""
    fi
    
    # Check resource requests/limits
    echo -e "${YELLOW}Resource Configuration:${NC}"
    echo "$pod_info" | jq -r '
        .spec.containers[] |
        "  • \(.name):",
        "    Requests: CPU=\(.resources.requests.cpu // "not set"), Memory=\(.resources.requests.memory // "not set")",
        "    Limits: CPU=\(.resources.limits.cpu // "not set"), Memory=\(.resources.limits.memory // "not set")"
    '
    
    echo ""
    
    # Recent events
    echo -e "${YELLOW}Recent Events:${NC}"
    kubectl get events -n "$namespace" --field-selector involvedObject.name="$pod" --sort-by='.lastTimestamp' 2>/dev/null | tail -5
    
    echo ""
}

################################################################################
# Show recent logs from crashed containers
################################################################################
show_recent_logs() {
    local namespace=$1
    local pod=$2
    
    echo -e "${YELLOW}Recent Logs (last 20 lines from previous instance):${NC}"
    
    # Get container names
    local containers=$(kubectl get pod "$pod" -n "$namespace" -o json 2>/dev/null | jq -r '.spec.containers[].name')
    
    for container in $containers; do
        echo -e "\n${BLUE}Container: $container${NC}"
        kubectl logs "$pod" -n "$namespace" -c "$container" --previous --tail=20 2>/dev/null || echo "  No previous logs available"
    done
    
    echo ""
}

################################################################################
# Format output
################################################################################
format_table() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}                   POD RESTART ANALYSIS REPORT                        ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    printf "${YELLOW}%-20s %-40s %-15s %-10s %-10s${NC}\n" "NAMESPACE" "POD" "NODE" "CONTAINERS" "RESTARTS"
    printf '%.0s─' {1..120}
    echo ""
    
    while IFS=$'\t' read -r ns pod node containers restarts; do
        local color=$GREEN
        if (( restarts > 10 )); then
            color=$RED
        elif (( restarts > 5 )); then
            color=$YELLOW
        fi
        
        printf "${color}%-20s %-40s %-15s %-10s %-10s${NC}\n" "$ns" "$pod" "${node:0:15}" "$containers" "$restarts"
    done
    
    echo ""
}

################################################################################
# Main
################################################################################
main() {
    local namespace="$NAMESPACE"
    local min_restarts="$MIN_RESTARTS"
    local output_format="table"
    local debug=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--namespace)
                namespace="$2"
                shift 2
                ;;
            -m|--min-restarts)
                min_restarts="$2"
                shift 2
                ;;
            -t|--time-window)
                TIME_WINDOW="$2"
                shift 2
                ;;
            -o|--output)
                output_format="$2"
                shift 2
                ;;
            --debug)
                debug=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                log ERROR "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    check_kubectl
    
    log INFO "Analyzing pod restarts (min: $min_restarts restarts)"
    log INFO "Namespace: $namespace"
    echo ""
    
    # Get restarting pods
    local pods=$(get_restarting_pods "$namespace" "$min_restarts")
    
    if [[ -z "$pods" ]]; then
        log INFO "No pods found with $min_restarts+ restarts"
        exit 0
    fi
    
    # Display table
    echo "$pods" | format_table
    
    # Detailed analysis if requested
    if [[ "$debug" == "true" ]]; then
        echo "$pods" | while IFS=$'\t' read -r ns pod node containers restarts; do
            analyze_restart_reasons "$ns" "$pod"
            show_recent_logs "$ns" "$pod"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
        done
    fi
    
    # Summary
    local total=$(echo "$pods" | wc -l)
    local total_restarts=$(echo "$pods" | awk -F'\t' '{sum+=$5} END {print sum}')
    
    echo -e "${GREEN}Summary:${NC}"
    echo "  • Total problematic pods: $total"
    echo "  • Total restarts: $total_restarts"
    echo ""
    
    if [[ "$debug" == "false" ]]; then
        echo -e "${YELLOW}💡 Tip: Use --debug flag for detailed analysis and logs${NC}"
    fi
}

main "$@"
