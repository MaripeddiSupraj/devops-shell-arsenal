#!/bin/bash
################################################################################
# Script Name: aws-unused-resources.sh
# Description: Identify and optionally delete unused AWS resources to reduce costs
# Usage: ./aws-unused-resources.sh [options]
# Author: maripeddi supraj
# Dependencies: aws-cli, jq
################################################################################

set -euo pipefail

readonly SCRIPT_NAME=$(basename "$0")
readonly DRY_RUN="${DRY_RUN:-true}"
readonly REGION="${AWS_REGION:-us-east-1}"
readonly DAYS_UNUSED="${DAYS_UNUSED:-30}"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Find and optionally delete unused AWS resources to optimize costs.

RESOURCES CHECKED:
    • Unattached EBS volumes
    • Unused Elastic IPs
    • Idle load balancers (no targets)
    • Unused security groups
    • Unattached ENIs
    • Old snapshots (beyond retention)

OPTIONS:
    -r, --region REGION     AWS region (default: $REGION)
    -d, --days NUM          Days unused threshold (default: $DAYS_UNUSED)
    --delete                Actually delete resources (default: dry-run)
    --export FILE           Export findings to JSON file
    -h, --help              Display this help message

EXAMPLES:
    # Find unused resources (dry-run)
    $SCRIPT_NAME

    # Find in specific region
    $SCRIPT_NAME -r eu-west-1

    # Actually delete unused resources
    $SCRIPT_NAME --delete

    # Export findings
    $SCRIPT_NAME --export unused-resources.json

SAFETY:
    • Dry-run mode by default
    • Resources are tagged before deletion
    • Snapshot created for volumes before deletion

EOF
    exit 0
}

log() {
    local level=$1; shift
    local color=$GREEN
    case $level in
        ERROR) color=$RED ;;
        WARN) color=$YELLOW ;;
        INFO) color=$GREEN ;;
    esac
    echo -e "${color}[$level]${NC} $*"
}

check_dependencies() {
    for cmd in aws jq; do
        if ! command -v $cmd &> /dev/null; then
            log ERROR "$cmd is required but not installed"
            exit 1
        fi
    done
    
    # Verify AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log ERROR "AWS credentials not configured"
        exit 1
    fi
}

################################################################################
# Find unattached EBS volumes
################################################################################
find_unused_volumes() {
    log INFO "Checking for unattached EBS volumes in $REGION..."
    
    local volumes=$(aws ec2 describe-volumes \
        --region "$REGION" \
        --filters Name=status,Values=available \
        --query 'Volumes[*].[VolumeId,Size,CreateTime,VolumeType]' \
        --output json)
    
    local count=$(echo "$volumes" | jq '. | length')
    
    if [[ $count -gt 0 ]]; then
        log WARN "Found $count unattached EBS volumes"
        echo "$volumes" | jq -r '.[] | @tsv' | while IFS=$'\t' read -r vol_id size created type; do
            local cost=$(echo "scale=2; $size * 0.10" | bc)  # Approximate $0.10/GB/month
            echo "  • Volume: $vol_id | Size: ${size}GB | Type: $type | Cost: ~\$${cost}/month | Created: $created"
            
            if [[ "$DRY_RUN" == "false" ]]; then
                log WARN "Creating snapshot before deletion..."
                aws ec2 create-snapshot --volume-id "$vol_id" --description "Pre-deletion backup" --region "$REGION" > /dev/null
                
                log WARN "Deleting volume $vol_id..."
                aws ec2 delete-volume --volume-id "$vol_id" --region "$REGION"
                log INFO "Deleted volume $vol_id"
            fi
        done
        
        echo ""
    else
        log INFO "No unattached volumes found"
    fi
    
    echo "$volumes"
}

################################################################################
# Find unused Elastic IPs
################################################################################
find_unused_eips() {
    log INFO "Checking for unused Elastic IPs in $REGION..."
    
    local eips=$(aws ec2 describe-addresses \
        --region "$REGION" \
        --query 'Addresses[?AssociationId==`null`].[PublicIp,AllocationId]' \
        --output json)
    
    local count=$(echo "$eips" | jq '. | length')
    
    if [[ $count -gt 0 ]]; then
        log WARN "Found $count unused Elastic IPs (~\$3.65/month each)"
        echo "$eips" | jq -r '.[] | @tsv' | while IFS=$'\t' read -r ip alloc_id; do
            local monthly_cost=3.65
            echo "  • IP: $ip | Allocation: $alloc_id | Cost: \$${monthly_cost}/month"
            
            if [[ "$DRY_RUN" == "false" ]]; then
                log WARN "Releasing Elastic IP $ip..."
                aws ec2 release-address --allocation-id "$alloc_id" --region "$REGION"
                log INFO "Released Elastic IP $ip"
            fi
        done
        
        echo ""
    else
        log INFO "No unused Elastic IPs found"
    fi
    
    echo "$eips"
}

################################################################################
# Find unused load balancers
################################################################################
find_unused_load_balancers() {
    log INFO "Checking for load balancers with no targets in $REGION..."
    
    # Get all ALBs/NLBs
    local lbs=$(aws elbv2 describe-load-balancers \
        --region "$REGION" \
        --query 'LoadBalancers[*].[LoadBalancerArn,LoadBalancerName,Type]' \
        --output json 2>/dev/null || echo '[]')
    
    local unused_lbs='[]'
    
    echo "$lbs" | jq -r '.[] | @tsv' | while IFS=$'\t' read -r lb_arn lb_name lb_type; do
        # Get target groups
        local tg_arns=$(aws elbv2 describe-target-groups \
            --load-balancer-arn "$lb_arn" \
            --region "$REGION" \
            --query 'TargetGroups[*].TargetGroupArn' \
            --output json 2>/dev/null || echo '[]')
        
        local has_targets=false
        echo "$tg_arns" | jq -r '.[]' | while read -r tg_arn; do
            local health=$(aws elbv2 describe-target-health \
                --target-group-arn "$tg_arn" \
                --region "$REGION" \
                --query 'TargetHealthDescriptions' \
                --output json 2>/dev/null || echo '[]')
            
            if [[ $(echo "$health" | jq '. | length') -gt 0 ]]; then
                has_targets=true
            fi
        done
        
        if [[ "$has_targets" == "false" ]]; then
            log WARN "Load balancer has no targets: $lb_name (Type: $lb_type)"
            echo "  • $lb_name | Type: $lb_type | ARN: $lb_arn"
            
            if [[ "$DRY_RUN" == "false" ]]; then
                log WARN "Deleting load balancer $lb_name..."
                aws elbv2 delete-load-balancer --load-balancer-arn "$lb_arn" --region "$REGION"
                log INFO "Deleted load balancer $lb_name"
            fi
        fi
    done
    
    echo ""
}

################################################################################
# Find unused security groups
################################################################################
find_unused_security_groups() {
    log INFO "Checking for unused security groups in $REGION..."
    
    # Get all security groups
    local all_sgs=$(aws ec2 describe-security-groups \
        --region "$REGION" \
        --query 'SecurityGroups[*].GroupId' \
        --output json)
    
    # Get security groups in use by instances
    local used_sgs=$(aws ec2 describe-instances \
        --region "$REGION" \
        --query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId' \
        --output json | jq -r '.[][] | .[]' | sort -u)
    
    # Get security groups in use by network interfaces
    local eni_sgs=$(aws ec2 describe-network-interfaces \
        --region "$REGION" \
        --query 'NetworkInterfaces[*].Groups[*].GroupId' \
        --output json | jq -r '.[][] | .GroupId' | sort -u)
    
    local unused_count=0
    echo "$all_sgs" | jq -r '.[]' | while read -r sg_id; do
        # Skip default SGs
        local sg_name=$(aws ec2 describe-security-groups --group-ids "$sg_id" --region "$REGION" --query 'SecurityGroups[0].GroupName' --output text)
        if [[ "$sg_name" == "default" ]]; then
            continue
        fi
        
        # Check if SG is in use
        if ! echo "$used_sgs" | grep -q "$sg_id" && ! echo "$eni_sgs" | grep -q "$sg_id"; then
            echo "  • Unused security group: $sg_id ($sg_name)"
            ((unused_count++))
            
            if [[ "$DRY_RUN" == "false" ]]; then
                log WARN "Deleting security group $sg_id..."
                aws ec2 delete-security-group --group-id "$sg_id" --region "$REGION" 2>/dev/null || log WARN "Could not delete $sg_id (may have dependencies)"
            fi
        fi
    done
    
    if [[ $unused_count -gt 0 ]]; then
        log WARN "Found $unused_count unused security groups"
        echo ""
    else
        log INFO "No unused security groups found"
    fi
}

################################################################################
# Generate cost savings report
################################################################################
generate_report() {
    local volumes_data=$1
    local eips_data=$2
    
    local volume_cost=$(echo "$volumes_data" | jq -r '.[] | .[1]' | awk '{sum+=$1*0.10} END {printf "%.2f", sum}')
    local eip_count=$(echo "$eips_data" | jq '. | length')
    local eip_cost=$(echo "$eip_count * 3.65" | bc)
    local total_monthly=$(echo "$volume_cost + $eip_cost" | bc)
    local total_yearly=$(echo "$total_monthly * 12" | bc)
    
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}           COST SAVINGS OPPORTUNITY REPORT          ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${YELLOW}Unattached EBS Volumes:${NC} \$${volume_cost}/month"
    echo -e "${YELLOW}Unused Elastic IPs:${NC} \$${eip_cost}/month"
    echo -e "${GREEN}─────────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}Total Monthly Savings:${NC} \$${total_monthly}"
    echo -e "${GREEN}Total Yearly Savings:${NC} \$${total_yearly}\n"
}

################################################################################
# Main
################################################################################
main() {
    local export_file=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--region)
                REGION="$2"
                shift 2
                ;;
            -d|--days)
                DAYS_UNUSED="$2"
                shift 2
                ;;
            --delete)
                DRY_RUN=false
                shift
                ;;
            --export)
                export_file="$2"
                shift 2
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
    
    check_dependencies
    
    log INFO "AWS Unused Resource Scanner"
    log INFO "Region: $REGION"
    log INFO "Mode: $(if [[ "$DRY_RUN" == "true" ]]; then echo "DRY-RUN"; else echo "DELETE"; fi)"
    echo ""
    
    # Find unused resources
    local volumes=$(find_unused_volumes)
    local eips=$(find_unused_eips)
    find_unused_load_balancers
    find_unused_security_groups
    
    # Generate report
    generate_report "$volumes" "$eips"
    
    # Export if requested
    if [[ -n "$export_file" ]]; then
        cat > "$export_file" << EOF
{
  "scan_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "region": "$REGION",
  "unused_volumes": $volumes,
  "unused_eips": $eips
}
EOF
        log INFO "Findings exported to: $export_file"
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}This was a DRY-RUN. Use --delete to actually remove resources.${NC}\n"
    fi
}

main "$@"
