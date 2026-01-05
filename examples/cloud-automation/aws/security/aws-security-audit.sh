#!/bin/bash
################################################################################
# Script Name: aws-security-audit.sh
# Description: Comprehensive AWS security audit across multiple services
# Usage: ./aws-security-audit.sh [options]
# Author: maripeddi supraj
# Dependencies: aws-cli, jq
################################################################################

set -euo pipefail

readonly SCRIPT_NAME=$(basename "$0")
readonly REGION="${AWS_REGION:-us-east-1}"
readonly OUTPUT_FILE="aws-security-audit-$(date +%Y%m%d-%H%M%S).txt"

# Colors
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m'

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Perform comprehensive security audit of AWS account.

CHECKS:
    • Public S3 buckets
    • Unencrypted EBS volumes
    • Security groups with 0.0.0.0/0 access
    • IAM users without MFA
    • RDS instances without encryption
    • Unused IAM access keys
    • Public RDS/EC2 instances

OPTIONS:
    -r, --region REGION     AWS region (default: $REGION)
    -o, --output FILE       Output file (default: $OUTPUT_FILE)
    -h, --help              Display this help message

EXAMPLES:
    # Full audit
    $SCRIPT_NAME

    # Specific region
    $SCRIPT_NAME -r eu-west-1

EOF
    exit 0
}

log() {
    local level=$1; shift
    local message="$*"
    echo -e "${GREEN}[$level]${NC} $message" | tee -a "$OUTPUT_FILE"
}

log_finding() {
    local severity=$1
    shift
    local message="$*"
    
    local color=$YELLOW
    case $severity in
        CRITICAL|HIGH) color=$RED ;;
        MEDIUM) color=$YELLOW ;;
        LOW) color=$GREEN ;;
    esac
    
    echo -e "${color}[$severity]${NC} $message" | tee -a "$OUTPUT_FILE"
}

check_dependencies() {
    for cmd in aws jq; do
        if ! command -v $cmd &> /dev/null; then
            echo "ERROR: $cmd is required"
            exit 1
        fi
    done
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "ERROR: AWS credentials not configured"
        exit 1
    fi
}

################################################################################
# Check for public S3 buckets
################################################################################
check_public_s3_buckets() {
    log INFO "Checking for public S3 buckets..."
    
    local public_count=0
    
    for bucket in $(aws s3 ls | awk '{print $3}'); do
        # Check public access block
        local block_config=$(aws s3api get-public-access-block --bucket "$bucket" 2>/dev/null || echo "none")
        
        if [[ "$block_config" == "none" ]] || echo "$block_config" | grep -q "false"; then
            log_finding HIGH "Public S3 bucket: $bucket (public access not fully blocked)"
            ((public_count++))
        fi
        
        # Check bucket ACL
        local public_acl=$(aws s3api get-bucket-acl --bucket "$bucket" \
            --query 'Grants[?Grantee.URI==`http://acs.amazonaws.com/groups/global/AllUsers`]' \
            --output text 2>/dev/null)
        
        if [[ -n "$public_acl" ]]; then
            log_finding CRITICAL "Public ACL on bucket: $bucket"
            ((public_count++))
        fi
    done
    
    echo "  Found $public_count public bucket issues"
    echo ""
}

################################################################################
# Check for unencrypted EBS volumes
################################################################################
check_unencrypted_ebs() {
    log INFO "Checking for unencrypted EBS volumes..."
    
    local unencrypted=$(aws ec2 describe-volumes \
        --region "$REGION" \
        --filters "Name=encrypted,Values=false" \
        --query 'Volumes[].[VolumeId,Size,State]' \
        --output text)
    
    if [[ -n "$unencrypted" ]]; then
        while IFS=$'\t' read -r vol_id size state; do
            log_finding HIGH "Unencrypted EBS volume: $vol_id (${size}GB, $state)"
        done <<< "$unencrypted"
    else
        log INFO "  ✓ All EBS volumes are encrypted"
    fi
    echo ""
}

################################################################################
# Check security groups for overly permissive rules
################################################################################
check_security_groups() {
    log INFO "Checking security groups for 0.0.0.0/0 access..."
    
    local sgs=$(aws ec2 describe-security-groups \
        --region "$REGION" \
        --query 'SecurityGroups[?IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`]]]' \
        --output json)
    
    echo "$sgs" | jq -r '.[] | 
        .GroupId as $gid | 
        .GroupName as $gname |
        .IpPermissions[] | 
        select(.IpRanges[]?.CidrIp == "0.0.0.0/0") |
        "[\($gid)] \($gname): Port \(.FromPort // "ALL") - \(.ToPort // "ALL")"' | while read -r line; do
        log_finding MEDIUM "Open security group: $line"
    done
    
    echo ""
}

################################################################################
# Check IAM users without MFA
################################################################################
check_iam_mfa() {
    log INFO "Checking IAM users without MFA..."
    
    local users_without_mfa=0
    
    aws iam list-users --query 'Users[].UserName' --output text | while read -r user; do
        local mfa=$(aws iam list-mfa-devices --user-name "$user" --query 'MFADevices' --output text)
        
        if [[ -z "$mfa" ]]; then
            log_finding HIGH "IAM user without MFA: $user"
            ((users_without_mfa++))
        fi
    done
    
    echo ""
}

################################################################################
# Check for unencrypted RDS instances
################################################################################
check_rds_encryption() {
    log INFO "Checking for unencrypted RDS instances..."
    
    local unencrypted=$(aws rds describe-db-instances \
        --region "$REGION" \
        --query 'DBInstances[?!StorageEncrypted].[DBInstanceIdentifier,Engine,PubliclyAccessible]' \
        --output text)
    
    if [[ -n "$unencrypted" ]]; then
        while IFS=$'\t' read -r db_id engine public; do
            local severity="HIGH"
            [[ "$public" == "True" ]] && severity="CRITICAL"
            log_finding $severity "Unencrypted RDS: $db_id ($engine, Public: $public)"
        done <<< "$unencrypted"
    else
        log INFO "  ✓ All RDS instances are encrypted"
    fi
    echo ""
}

################################################################################
# Check for unused IAM access keys
################################################################################
check_unused_access_keys() {
    log INFO "Checking for old/unused IAM access keys..."
    
    local old_keys=0
    local ninety_days_ago=$(date -u -d '90 days ago' +%Y-%m-%d 2>/dev/null || date -u -v-90d +%Y-%m-%d 2>/dev/null)
    
    aws iam list-users --query 'Users[].UserName' --output text | while read -r user; do
        aws iam list-access-keys --user-name "$user" \
            --query "AccessKeyMetadata[?CreateDate<='${ninety_days_ago}'].[AccessKeyId,CreateDate]" \
            --output text | while IFS=$'\t' read -r key_id create_date; do
            if [[ -n "$key_id" ]]; then
                log_finding MEDIUM "Old access key: $user ($key_id, created $create_date)"
                ((old_keys++))
            fi
        done
    done
    
    echo ""
}

################################################################################
# Check for publicly accessible resources
################################################################################
check_public_resources() {
    log INFO "Checking for publicly accessible EC2/RDS instances..."
    
    # Public EC2 instances
    local public_ec2=$(aws ec2 describe-instances \
        --region "$REGION" \
        --filters "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[?PublicIpAddress].[InstanceId,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
        --output text)
    
    if [[ -n "$public_ec2" ]]; then
        while IFS=$'\t' read -r instance_id public_ip name; do
            log_finding MEDIUM "Public EC2 instance: ${name:-$instance_id} ($public_ip)"
        done <<< "$public_ec2"
    fi
    
    # Public RDS instances
    local public_rds=$(aws rds describe-db-instances \
        --region "$REGION" \
        --query 'DBInstances[?PubliclyAccessible].[DBInstanceIdentifier,Endpoint.Address]' \
        --output text)
    
    if [[ -n "$public_rds" ]]; then
        while IFS=$'\t' read -r db_id endpoint; do
            log_finding HIGH "Publicly accessible RDS: $db_id ($endpoint)"
        done <<< "$public_rds"
    fi
    
    echo ""
}

################################################################################
# Generate summary report
################################################################################
generate_summary() {
    echo ""  | tee -a "$OUTPUT_FILE"
    echo "═══════════════════════════════════════════════════" | tee -a "$OUTPUT_FILE"
    echo "           AWS SECURITY AUDIT SUMMARY              " | tee -a "$OUTPUT_FILE"
    echo "═══════════════════════════════════════════════════" | tee -a "$OUTPUT_FILE"
    echo "Completed: $(date)" | tee -a "$OUTPUT_FILE"
    echo "Region: $REGION" | tee -a "$OUTPUT_FILE"
    echo "Account: $(aws sts get-caller-identity --query Account --output text)" | tee -a "$OUTPUT_FILE"
    echo "" | tee -a "$OUTPUT_FILE"
    echo "Report saved to: $OUTPUT_FILE" | tee -a "$OUTPUT_FILE"
    echo "═══════════════════════════════════════════════════" | tee -a "$OUTPUT_FILE"
}

################################################################################
# Main
################################################################################
main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--region)
                REGION="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    check_dependencies
    
    echo "═══════════════════════════════════════════════════" | tee "$OUTPUT_FILE"
    echo "         AWS SECURITY AUDIT STARTING               " | tee -a "$OUTPUT_FILE"
    echo "═══════════════════════════════════════════════════" | tee -a "$OUTPUT_FILE"
    echo "" | tee -a "$OUTPUT_FILE"
    
    check_public_s3_buckets
    check_unencrypted_ebs
    check_security_groups
    check_iam_mfa
    check_rds_encryption
    check_unused_access_keys
    check_public_resources
    
    generate_summary
}

main "$@"
