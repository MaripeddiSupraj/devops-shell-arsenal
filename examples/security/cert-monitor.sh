#!/bin/bash
################################################################################
# Script Name: cert-monitor.sh
# Description: Monitor SSL/TLS certificate expiry across services
# Usage: ./cert-monitor.sh [options]
# Author: maripeddi supraj
# Dependencies: openssl
################################################################################

set -euo pipefail

readonly SCRIPT_NAME=$(basename "$0")
readonly WARN_DAYS="${WARN_DAYS:-30}"
readonly CRITICAL_DAYS="${CRITICAL_DAYS:-7}"
readonly TIMEOUT="${TIMEOUT:-5}"

# Colors
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m'

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Monitor SSL/TLS certificates and alert on expiry.

OPTIONS:
    -f, --file FILE         File containing hostnames (one per line)
    -h, --host HOST         Single hostname to check
    -p, --port PORT         Port number (default: 443)
    -w, --warn DAYS         Warning threshold in days (default: $WARN_DAYS)
    -c, --critical DAYS     Critical threshold in days (default: $CRITICAL_DAYS)
    --help                  Display this help message

EXAMPLES:
    # Check single host
    $SCRIPT_NAME -h example.com

    # Check from file
    $SCRIPT_NAME -f hosts.txt

    # Custom thresholds
    $SCRIPT_NAME -h example.com -w 60 -c 14

FILE FORMAT:
    example.com
    api.example.com:8443
    *.wildcard.com

EOF
    exit 0
}

log() {
    local level=$1; shift
    echo -e "${GREEN}[$level]${NC} $*" >&2
}

################################################################################
# Check certificate for a single host
################################################################################
check_certificate() {
    local host=$1
    local port=${2:-443}
    
    # Extract hostname and port if provided together
    if [[ "$host" == *:* ]]; then
        port="${host##*:}"
        host="${host%:*}"
    fi
    
    # Get certificate info
    local cert_info
    if ! cert_info=$(echo | timeout "$TIMEOUT" openssl s_client -servername "$host" -connect "$host:$port" 2>/dev/null | openssl x509 -noout -dates -subject 2>/dev/null); then
        echo -e "${RED}✗${NC} $host:$port - Connection failed"
        return 1
    fi
    
    # Parse dates
    local not_before=$(echo "$cert_info" | grep "notBefore=" | cut -d= -f2)
    local not_after=$(echo "$cert_info" | grep "notAfter=" | cut -d= -f2)
    local subject=$(echo "$cert_info" | grep "subject=" | cut -d= -f2-)
    
    # Calculate days until expiry
    local expiry_epoch=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$not_after" +%s 2>/dev/null || date -d "$not_after" +%s 2>/dev/null)
    local now_epoch=$(date +%s)
    local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
    
    # Status and color
    local status="${GREEN}✓ VALID${NC}"
    local color=$GREEN
    
    if [[ $days_left -lt 0 ]]; then
        status="${RED}✗ EXPIRED${NC}"
        color=$RED
    elif [[ $days_left -le $CRITICAL_DAYS ]]; then
        status="${RED}⚠ CRITICAL${NC}"
        color=$RED
    elif [[ $days_left -le $WARN_DAYS ]]; then
        status="${YELLOW}⚠ WARNING${NC}"
        color=$YELLOW
    fi
    
    # Output
    echo -e "${color}$status${NC} $host:$port"
    echo "    Subject: $subject"
    echo "    Expires: $not_after"
    echo "    Days left: $days_left"
    echo ""
}

################################################################################
# Check multiple hosts from file
################################################################################
check_from_file() {
    local file=$1
    local port=${2:-443}
    
    if [[ ! -f "$file" ]]; then
        log ERROR "File not found: $file"
        exit 1
    fi
    
    local total=0
    local valid=0
    local warnings=0
    local critical=0
    local failed=0
    
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}         SSL/TLS CERTIFICATE MONITOR               ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo ""
    
    while IFS= read -r host; do
        # Skip empty lines and comments
        [[ -z "$host" || "$host" =~ ^# ]] && continue
        
        ((total++))
        
        if check_certificate "$host" "$port"; then
            ((valid++))
        else
            ((failed++))
        fi
    done < "$file"
    
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}SUMMARY${NC}"
    echo "  Total hosts: $total"
    echo "  Valid: $valid"
    echo "  Failed connections: $failed"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
}

################################################################################
# Main
################################################################################
main() {
    local host=""
    local file=""
    local port=443
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                file="$2"
                shift 2
                ;;
            -h|--host)
                host="$2"
                shift 2
                ;;
            -p|--port)
                port="$2"
                shift 2
                ;;
            -w|--warn)
                WARN_DAYS="$2"
                shift 2
                ;;
            -c|--critical)
                CRITICAL_DAYS="$2"
                shift 2
                ;;
            --help)
                usage
                ;;
            *)
                log ERROR "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    # Validate
    if [[ -z "$host" && -z "$file" ]]; then
        log ERROR "Must specify either --host or --file"
        usage
    fi
    
    # Execute
    if [[ -n "$file" ]]; then
        check_from_file "$file" "$port"
    else
        check_certificate "$host" "$port"
    fi
}

main "$@"
