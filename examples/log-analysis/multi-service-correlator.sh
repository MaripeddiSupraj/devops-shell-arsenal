#!/bin/bash
################################################################################
# Script Name: multi-service-correlator.sh
# Description: Correlate logs across multiple microservices using trace IDs
#              to debug distributed systems issues
# Usage: ./multi-service-correlator.sh [options] TRACE_ID
# Author: maripeddi supraj
# Dependencies: awk, grep
################################################################################

set -euo pipefail

readonly SCRIPT_NAME=$(basename "$0")
readonly SERVICE_LOGS_DIR="${SERVICE_LOGS_DIR:-/var/log/services}"
readonly OUTPUT_FORMAT="${OUTPUT_FORMAT:-table}"  # table, json, or timeline

# Colors
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] TRACE_ID

Correlate logs across multiple microservices by trace ID to debug distributed requests.

ARGUMENTS:
    TRACE_ID            The trace/correlation ID to search for

OPTIONS:
    -d, --dir DIR       Directory containing service logs (default: $SERVICE_LOGS_DIR)
    -f, --format FMT    Output format: table, json, timeline (default: $OUTPUT_FORMAT)
    -s, --services      Comma-separated list of services to include
    -o, --output FILE   Write output to file instead of stdout
    -t, --time-range    Show only logs within time range (format: HH:MM:SS-HH:MM:SS)
    -h, --help          Display this help message

EXAMPLES:
    # Find all logs for a trace ID
    $SCRIPT_NAME abc-123-def

    # Search specific services only
    $SCRIPT_NAME -s api,auth,db abc-123-def

    # Output as timeline
    $SCRIPT_NAME -f timeline abc-123-def

    # Save to file
    $SCRIPT_NAME -o trace-analysis.txt abc-123-def

EOF
    exit 0
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

################################################################################
# Extract logs containing the trace ID from all service logs
################################################################################
extract_trace_logs() {
    local trace_id=$1
    local services_filter=$2
    
    log_info "Searching for trace ID: $trace_id"
    
    # Find all log files
    local log_files=()
    if [[ -n "$services_filter" ]]; then
        IFS=',' read -ra services <<< "$services_filter"
        for service in "${services[@]}"; do
            while IFS= read -r file; do
                log_files+=("$file")
            done < <(find "$SERVICE_LOGS_DIR" -name "${service}*.log" -type f 2>/dev/null)
        done
    else
        while IFS= read -r file; do
            log_files+=("$file")
        done < <(find "$SERVICE_LOGS_DIR" -name "*.log" -type f 2>/dev/null)
    fi
    
    if [[ ${#log_files[@]} -eq 0 ]]; then
        log_error "No log files found in $SERVICE_LOGS_DIR"
        return 1
    fi
    
    log_info "Searching ${#log_files[@]} log files..."
    
    # Extract matching lines with service name, timestamp, and log level
    for log_file in "${log_files[@]}"; do
        local service_name=$(basename "$log_file" .log)
        
        grep -i "$trace_id" "$log_file" 2>/dev/null | while IFS= read -r line; do
            # Parse log line (assumes common format: timestamp level message)
            # Example: 2026-01-05 15:14:35.123 INFO [trace_id=abc-123] User login successful
            
            local timestamp=$(echo "$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?' | head -1)
            local level=$(echo "$line" | grep -oE '\b(DEBUG|INFO|WARN|ERROR|FATAL)\b' | head -1)
            
            echo "$service_name|$timestamp|${level:-INFO}|$line"
        done
    done | sort -t'|' -k2  # Sort by timestamp
}

################################################################################
# Format output as table
################################################################################
format_table() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    DISTRIBUTED TRACE ANALYSIS                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    printf "${BLUE}%-20s %-25s %-8s %s${NC}\n" "SERVICE" "TIMESTAMP" "LEVEL" "MESSAGE"
    printf "%.0s─" {1..120}
    echo ""
    
    while IFS='|' read -r service timestamp level message; do
        local color=$GREEN
        case $level in
            ERROR|FATAL) color=$RED ;;
            WARN) color=$YELLOW ;;
            DEBUG) color=$CYAN ;;
        esac
        
        # Truncate message for display
        local short_msg=$(echo "$message" | cut -c1-70)
        
        printf "${color}%-20s %-25s %-8s %s${NC}\n" "$service" "$timestamp" "$level" "$short_msg"
    done
}

################################################################################
# Format output as timeline
################################################################################
format_timeline() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}              REQUEST TIMELINE (by timestamp)                 ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local prev_time=""
    local sequence=1
    
    while IFS='|' read -r service timestamp level message; do
        local color=$GREEN
        case $level in
            ERROR|FATAL) color=$RED ;;
            WARN) color=$YELLOW ;;
        esac
        
        # Show time delta if we have previous timestamp
        local delta=""
        if [[ -n "$prev_time" && -n "$timestamp" ]]; then
            delta=" [+Δt]"
        fi
        
        echo -e "${BLUE}[$sequence]${NC} ${timestamp}${delta}"
        echo -e "    ${color}└─→ [$service] [$level]${NC} $message"
        echo ""
        
        prev_time=$timestamp
        ((sequence++))
    done
}

################################################################################
# Format output as JSON
################################################################################
format_json() {
    echo "{"
    echo '  "trace_analysis": ['
    
    local first=true
    while IFS='|' read -r service timestamp level message; do
        if [[ "$first" == "false" ]]; then
            echo ","
        fi
        first=false
        
        # Escape quotes in message
        message=$(echo "$message" | sed 's/"/\\"/g')
        
        cat << EOF
    {
      "service": "$service",
      "timestamp": "$timestamp",
      "level": "$level",
      "message": "$message"
    }
EOF
    done
    
    echo ""
    echo "  ]"
    echo "}"
}

################################################################################
# Main
################################################################################
main() {
    local trace_id=""
    local services_filter=""
    local output_file=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dir)
                SERVICE_LOGS_DIR="$2"
                shift 2
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -s|--services)
                services_filter="$2"
                shift 2
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                trace_id="$1"
                shift
                ;;
        esac
    done
    
    # Validate trace ID
    if [[ -z "$trace_id" ]]; then
        log_error "Trace ID is required"
        usage
    fi
    
    # Extract logs
    local logs=$(extract_trace_logs "$trace_id" "$services_filter")
    
    if [[ -z "$logs" ]]; then
        log_error "No logs found for trace ID: $trace_id"
        exit 1
    fi
    
    # Count total entries
    local count=$(echo "$logs" | wc -l)
    log_info "Found $count log entries across services"
    echo ""
    
    # Format and output
    local output=""
    case $OUTPUT_FORMAT in
        table)
            output=$(echo "$logs" | format_table)
            ;;
        timeline)
            output=$(echo "$logs" | format_timeline)
            ;;
        json)
            output=$(echo "$logs" | format_json)
            ;;
        *)
            log_error "Unknown format: $OUTPUT_FORMAT"
            exit 1
            ;;
    esac
    
    # Write to file or stdout
    if [[ -n "$output_file" ]]; then
        echo "$output" > "$output_file"
        log_info "Output written to: $output_file"
    else
        echo "$output"
    fi
}

main "$@"
