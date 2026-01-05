#!/bin/bash
################################################################################
# Script Name: error-spike-detector.sh
# Description: Real-time monitoring of HTTP error rates (4xx/5xx) from logs
#              Alerts when error rate exceeds threshold
# Usage: ./error-spike-detector.sh [options]
# Author: maripeddi supraj
# Dependencies: awk, tail
################################################################################

set -euo pipefail

# Configuration
readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_FILE="${LOG_FILE:-/var/log/nginx/access.log}"
readonly ERROR_THRESHOLD="${ERROR_THRESHOLD:-5}"  # Errors per minute
readonly CHECK_INTERVAL="${CHECK_INTERVAL:-60}"   # Seconds
readonly ALERT_EMAIL="${ALERT_EMAIL:-ops@example.com}"

# Colors for output
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m' # No Color

################################################################################
# Display usage information
################################################################################
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Monitor HTTP logs for error spikes and alert when thresholds are exceeded.

OPTIONS:
    -f, --file FILE         Log file to monitor (default: $LOG_FILE)
    -t, --threshold NUM     Error threshold per minute (default: $ERROR_THRESHOLD)
    -i, --interval SEC      Check interval in seconds (default: $CHECK_INTERVAL)
    -e, --email EMAIL       Alert email address (default: $ALERT_EMAIL)
    -d, --dry-run           Show what would be monitored without actually monitoring
    -h, --help              Display this help message

EXAMPLES:
    # Monitor default nginx access log
    $SCRIPT_NAME

    # Monitor custom log with 10 errors/min threshold
    $SCRIPT_NAME -f /var/log/app/access.log -t 10

    # Check every 30 seconds with email alerts
    $SCRIPT_NAME -i 30 -e oncall@company.com

ENVIRONMENT VARIABLES:
    LOG_FILE            Path to log file
    ERROR_THRESHOLD     Errors per minute threshold
    CHECK_INTERVAL      Seconds between checks
    ALERT_EMAIL         Email for alerts

EOF
    exit 0
}

################################################################################
# Log messages with timestamp
################################################################################
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        ERROR)
            echo -e "${RED}[$timestamp] [ERROR] $message${NC}" >&2
            ;;
        WARN)
            echo -e "${YELLOW}[$timestamp] [WARN] $message${NC}"
            ;;
        INFO)
            echo -e "${GREEN}[$timestamp] [INFO] $message${NC}"
            ;;
        *)
            echo "[$timestamp] $message"
            ;;
    esac
}

################################################################################
# Send alert notification
################################################################################
send_alert() {
    local error_count=$1
    local time_window=$2
    local status_breakdown=$3
    
    local subject="[ALERT] High Error Rate Detected: ${error_count} errors in ${time_window}s"
    local body="Error spike detected on $(hostname)
    
Time: $(date)
Log File: $LOG_FILE
Error Count: $error_count errors in $time_window seconds
Threshold: $ERROR_THRESHOLD errors/minute
Rate: $(echo "scale=2; $error_count * 60 / $time_window" | bc) errors/minute

Status Code Breakdown:
$status_breakdown

Please investigate immediately.
"
    
    log WARN "ALERT: $error_count errors detected in ${time_window}s (threshold: ${ERROR_THRESHOLD}/min)"
    
    # Send email if mail command is available
    if command -v mail &> /dev/null; then
        echo "$body" | mail -s "$subject" "$ALERT_EMAIL"
        log INFO "Alert email sent to $ALERT_EMAIL"
    else
        log WARN "mail command not found, cannot send email alert"
    fi
}

################################################################################
# Analyze error rates from log file
################################################################################
analyze_errors() {
    local duration=$1
    
    log INFO "Analyzing errors from last ${duration} seconds..."
    
    # Get timestamp from duration seconds ago
    local start_time=$(date -v-${duration}S '+%d/%b/%Y:%H:%M:%S' 2>/dev/null || date -d "${duration} seconds ago" '+%d/%b/%Y:%H:%M:%S')
    
    # Count 4xx and 5xx errors in the time window
    # Assumes nginx/apache combined log format
    local error_analysis=$(tail -n 10000 "$LOG_FILE" | awk -v start="$start_time" '
    BEGIN {
        total_4xx = 0
        total_5xx = 0
    }
    {
        # Extract timestamp and status code
        # Example: 127.0.0.1 - - [05/Jan/2026:15:14:35 +0530] "GET /api HTTP/1.1" 500 1234
        match($0, /\[([^\]]+)\]/, timestamp)
        match($0, /" ([0-9]{3}) /, status)
        
        if (timestamp[1] >= start && status[1] != "") {
            code = status[1]
            status_codes[code]++
            
            if (code >= 400 && code < 500) {
                total_4xx++
            } else if (code >= 500) {
                total_5xx++
            }
        }
    }
    END {
        total = total_4xx + total_5xx
        print total
        print "4xx errors: " total_4xx
        print "5xx errors: " total_5xx
        print "---"
        for (code in status_codes) {
            if (code >= 400) {
                print code ": " status_codes[code]
            }
        }
    }
    ')
    
    local error_count=$(echo "$error_analysis" | head -1)
    local breakdown=$(echo "$error_analysis" | tail -n +2)
    
    echo "$error_count|$breakdown"
}

################################################################################
# Main monitoring loop
################################################################################
monitor_errors() {
    log INFO "Starting error spike detector..."
    log INFO "Log file: $LOG_FILE"
    log INFO "Threshold: $ERROR_THRESHOLD errors/minute"
    log INFO "Check interval: $CHECK_INTERVAL seconds"
    log INFO "Alert email: $ALERT_EMAIL"
    echo ""
    
    # Verify log file exists
    if [[ ! -f "$LOG_FILE" ]]; then
        log ERROR "Log file not found: $LOG_FILE"
        exit 1
    fi
    
    # Main loop
    while true; do
        local result=$(analyze_errors "$CHECK_INTERVAL")
        local error_count=$(echo "$result" | cut -d'|' -f1)
        local breakdown=$(echo "$result" | cut -d'|' -f2)
        
        # Calculate error rate per minute
        local error_rate=$(echo "scale=2; $error_count * 60 / $CHECK_INTERVAL" | bc)
        
        log INFO "Errors in last ${CHECK_INTERVAL}s: $error_count (rate: ${error_rate}/min)"
        
        # Check if threshold exceeded
        if (( $(echo "$error_count * 60 / $CHECK_INTERVAL > $ERROR_THRESHOLD" | bc -l) )); then
            send_alert "$error_count" "$CHECK_INTERVAL" "$breakdown"
        fi
        
        # Wait for next check
        sleep "$CHECK_INTERVAL"
    done
}

################################################################################
# Main
################################################################################
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                LOG_FILE="$2"
                shift 2
                ;;
            -t|--threshold)
                ERROR_THRESHOLD="$2"
                shift 2
                ;;
            -i|--interval)
                CHECK_INTERVAL="$2"
                shift 2
                ;;
            -e|--email)
                ALERT_EMAIL="$2"
                shift 2
                ;;
            -d|--dry-run)
                log INFO "DRY RUN MODE"
                log INFO "Would monitor: $LOG_FILE"
                log INFO "Threshold: $ERROR_THRESHOLD errors/min"
                log INFO "Interval: $CHECK_INTERVAL seconds"
                exit 0
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
    
    # Start monitoring
    monitor_errors
}

# Run main function
main "$@"
