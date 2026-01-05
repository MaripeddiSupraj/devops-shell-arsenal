#!/bin/bash
################################################################################
# PRODUCTION SCRIPT TEMPLATE
# Use this template as a foundation for production-ready shell scripts
################################################################################

################################################################################
# Script Metadata
################################################################################
# Script Name: script-name.sh
# Description: Brief description of what this script does
# Usage: ./script-name.sh [OPTIONS] [ARGUMENTS]
# Author: Your Name
# Created: YYYY-MM-DD
# Version: 1.0.0
# Dependencies: list-required-commands (e.g., aws, jq, kubectl)

################################################################################
# Safety and Best Practices
################################################################################
set -euo pipefail  # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'        # Safe Internal Field Separator

################################################################################
# Script Configuration
################################################################################
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_VERSION="1.0.0"

# Default configuration (can be overridden by env vars or arguments)
readonly DRY_RUN="${DRY_RUN:-true}"
readonly LOG_LEVEL="${LOG_LEVEL:-INFO}"  # DEBUG, INFO, WARN, ERROR
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

################################################################################
# Color Codes for Output
################################################################################
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'  # No Color

################################################################################
# Logging Functions
################################################################################
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Also write to log file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Console output with colors
    case $level in
        DEBUG)
            [[ "$LOG_LEVEL" == "DEBUG" ]] && \
                echo -e "${CYAN}[DEBUG]${NC} $message" >&2
            ;;
        INFO)
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} $message" >&2
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        *)
            echo "[$level] $message"
            ;;
    esac
}

################################################################################
# Error Handling
################################################################################
error_exit() {
    log ERROR "$1"
    exit "${2:-1}"
}

# Trap errors and cleanup
cleanup() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        log ERROR "Script failed with exit code: $exit_code"
    fi
    
    # Add cleanup tasks here
    # e.g., remove temp files, restore state, etc.
    
    log INFO "Cleanup completed"
}

trap cleanup EXIT
trap 'error_exit "Script interrupted" 130' INT TERM

################################################################################
# Dependency Checking
################################################################################
check_dependencies() {
    local deps=("$@")
    local missing=()
    
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error_exit "Missing required dependencies: ${missing[*]}"
    fi
    
    log DEBUG "All dependencies satisfied"
}

################################################################################
# Usage/Help
################################################################################
usage() {
    cat << EOF
${SCRIPT_NAME} - Script description

Usage: $SCRIPT_NAME [OPTIONS] [ARGUMENTS]

DESCRIPTION:
    Detailed description of what the script does and when to use it.

OPTIONS:
    -h, --help              Display this help message
    -v, --version           Display script version
    -d, --dry-run           Run in dry-run mode (no changes)
    --debug                 Enable debug logging
    -c, --config FILE       Path to configuration file
    
ARGUMENTS:
    arg1                    Description of argument 1
    arg2                    Description of argument 2

EXAMPLES:
    # Example 1
    $SCRIPT_NAME --dry-run arg1 arg2
    
    # Example 2
    $SCRIPT_NAME -c config.json arg1

ENVIRONMENT VARIABLES:
    DRY_RUN                 Set to 'false' to execute changes
    LOG_LEVEL               Set logging level (DEBUG, INFO, WARN, ERROR)
    LOG_FILE                Path to log file

EXIT CODES:
    0   Success
    1   General error
    2   Invalid arguments
    3   Missing dependencies

AUTHOR:
    Your Name <your.email@example.com>

VERSION:
    $SCRIPT_VERSION

EOF
    exit 0
}

################################################################################
# Validation Functions
################################################################################
validate_input() {
    local input=$1
    local pattern=$2
    
    if [[ ! "$input" =~ $pattern ]]; then
        return 1
    fi
    return 0
}

require_arg() {
    local arg_name=$1
    local arg_value=$2
    
    if [[ -z "$arg_value" ]]; then
        error_exit "Missing required argument: $arg_name" 2
    fi
}

################################################################################
# Confirmation Prompt
################################################################################
confirm() {
    local prompt=$1
    local default=${2:-N}  # Default to No
    
    if [[ "$default" == "Y" ]]; then
        prompt="$prompt [Y/n] "
    else
        prompt="$prompt [y/N] "
    fi
    
    read -rp "$prompt" response
    response=${response:-$default}
    
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

################################################################################
# Progress Bar
################################################################################
progress_bar() {
    local current=$1
    local total=$2
    local width=${3:-50}
    
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    
    printf "\rProgress: ["
    printf "%${filled}s" | tr ' ' '='
    printf "%$((width - filled))s" | tr ' ' '-'
    printf "] %3d%% (%d/%d)" $percent $current $total
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

################################################################################
# Safe Execute (respects DRY_RUN)
################################################################################
safe_execute() {
    local cmd="$*"
    
    log INFO "Executing: $cmd"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log WARN "[DRY-RUN] Would execute: $cmd"
        return 0
    fi
    
    if eval "$cmd"; then
        log INFO "Command successful"
        return 0
    else
        local exit_code=$?
        log ERROR "Command failed with exit code: $exit_code"
        return $exit_code
    fi
}

################################################################################
# Main Business Logic
################################################################################
main_function() {
    # Your main script logic goes here
    
    log INFO "Starting main function..."
    
    # Example:
    # Process arguments
    # Validate inputs
    # Execute main tasks
    # Generate reports
    
    log INFO "Main function completed"
}

################################################################################
# Argument Parsing
################################################################################
parse_arguments() {
    local args=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                ;;
            -v|--version)
                echo "$SCRIPT_NAME version $SCRIPT_VERSION"
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            --debug)
                LOG_LEVEL=DEBUG
                shift
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -*)
                error_exit "Unknown option: $1" 2
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    
    # Store positional arguments
    set -- "${args[@]}"
    
    # Export for use in other functions
    export ARG1="${1:-}"
    export ARG2="${2:-}"
}

################################################################################
# Main Entry Point
################################################################################
main() {
    # Initialize logging
    log INFO "=== Starting $SCRIPT_NAME v$SCRIPT_VERSION ==="
    log INFO "Log file: $LOG_FILE"
    
    # Check dependencies
    check_dependencies bash  # Add your required commands here
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Validate required arguments
    # require_arg "ARG1" "$ARG1"
    
    # Execute main logic
    main_function
    
    # Success
    log INFO "=== Script completed successfully ==="
    exit 0
}

################################################################################
# Execute Main
################################################################################
# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
