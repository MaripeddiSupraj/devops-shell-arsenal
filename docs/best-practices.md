# Shell Scripting Best Practices for DevOps

Production-ready guidelines for writing maintainable, reliable, and secure shell scripts.

---

## Table of Contents
1. [Safety First](#safety-first)
2. [Error Handling](#error-handling)
3. [Logging and Debugging](#logging-and-debugging)
4. [Code Organization](#code-organization)
5. [Security Considerations](#security-considerations)
6. [Performance Optimization](#performance-optimization)
7. [Testing](#testing)

---

## Safety First

### Always Use Strict Mode
```bash
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
```

**What each flag does:**
- `set -e` - Exit immediately if any command fails
- `set -u` - Treat undefined variables as errors
- `set -o pipefail` - Return failure if any command in a pipeline fails
- `IFS=$'\n\t'` - Internal Field Separator (prevents word splitting issues)

### Dry-Run Mode for Destructive Operations
```bash
DRY_RUN="${DRY_RUN:-true}"

if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY-RUN] Would delete: $file"
else
    rm "$file"
    echo "Deleted: $file"
fi
```

### Use Confirmation for Dangerous Actions
```bash
read -rp "Are you sure you want to delete all logs? [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted"
    exit 0
fi
```

---

## Error Handling

### Trap Signals and Clean Up
```bash
cleanup() {
    local exit_code=$?
    echo "Cleaning up..."
    rm -f /tmp/tempfile.*
    exit $exit_code
}

trap cleanup EXIT
trap 'echo "Script interrupted"; exit 130' INT TERM
```

### Check Command Success
```bash
# Good - check return code
if ! aws s3 ls s3://my-bucket &> /dev/null; then
    echo "ERROR: Bucket does not exist"
    exit 1
fi

# Better - with error message
if ! result=$(aws s3 ls s3://my-bucket 2>&1); then
    echo "ERROR: $result"
    exit 1
fi
```

### Defensive Programming
```bash
# Check file exists before reading
if [[ ! -f "$config_file" ]]; then
    echo "ERROR: Config file not found: $config_file"
    exit 1
fi

# Check directory exists before cd
if [[ ! -d "$target_dir" ]]; then
    mkdir -p "$target_dir" || exit 1
fi
cd "$target_dir" || exit 1
```

---

## Logging and Debugging

### Structured Logging
```bash
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log INFO "Starting process"
log WARN "Disk space low"
log ERROR "Connection failed"
```

### Debug Mode
```bash
DEBUG="${DEBUG:-false}"

debug() {
    if [[ "$DEBUG" == "true" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

debug "Variable value: $var"

# Or use bash -x for full trace
if [[ "$DEBUG" == "true" ]]; then
    set -x
fi
```

### Print Commands Before Execution
```bash
run_cmd() {
    echo "Running: $*"
    "$@"
}

run_cmd aws s3 sync . s3://bucket/
```

---

## Code Organization

### Use Functions
```bash
# Bad - spaghetti code
aws ec2 describe-instances | jq '.Reservations[].Instances[]' | ...
# 50 more lines...

# Good - organized functions
get_running_instances() {
    local region=$1
    aws ec2 describe-instances \
        --region "$region" \
        --filters Name=instance-state-name,Values=running \
        --query 'Reservations[].Instances[]' \
        --output json
}

instances=$(get_running_instances "us-east-1")
```

### Use Constants
```bash
# Bad - magic values
if [[ $status -eq 200 ]]; then

# Good - named constants
readonly HTTP_OK=200
if [[ $status -eq $HTTP_OK ]]; then
```

### Readable Long Commands
```bash
# Bad - hard to read
aws ec2 run-instances --image-id ami-12345 --instance-type t3.micro --key-name mykey --security-group-ids sg-123 --subnet-id subnet-456

# Good - readable
aws ec2 run-instances \
    --image-id ami-12345 \
    --instance-type t3.micro \
    --key-name mykey \
    --security-group-ids sg-123 \
    --subnet-id subnet-456
```

---

## Security Considerations

### Never Hardcode Secrets
```bash
# Bad
AWS_SECRET_KEY="AKIAxxxxxxxxx"

# Good - use environment variables
if [[ -z "$AWS_SECRET_KEY" ]]; then
    echo "ERROR: AWS_SECRET_KEY not set"
    exit 1
fi

# Better - use AWS credentials file or IAM roles
```

### Validate Input
```bash
# Validate email format
if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "ERROR: Invalid email format"
    exit 1
fi

# Validate IP address
if [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "ERROR: Invalid IP address"
    exit 1
fi
```

### Quote Variables
```bash
# Bad - word splitting issues
file=$1
rm $file  # Dangerous!

# Good - always quote
file="$1"
rm "$file"
```

### Use `mktemp` for Temporary Files
```bash
# Bad
tmpfile="/tmp/myfile.txt"

# Good - prevents race conditions
tmpfile=$(mktemp) || exit 1
trap "rm -f '$tmpfile'" EXIT
```

---

## Performance Optimization

### Avoid Unnecessary Subshells
```bash
# Slow - new process for each iteration
for file in $(ls *.txt); do
    echo "$file"
done

# Fast - shell glob
for file in *.txt; do
    echo "$file"
done
```

### Use Built-in String Operations
```bash
# Slow - external command
basename=$(basename "$file")

# Fast - parameter expansion
basename="${file##*/}"

# More examples:
${var#pattern}     # Remove shortest match from start
${var##pattern}    # Remove longest match from start
${var%pattern}     # Remove shortest match from end
${var%%pattern}    # Remove longest match from end
```

### Parallel Processing
```bash
# Sequential (slow)
for server in "${servers[@]}"; do
    ping -c 1 "$server" &> /dev/null
done

# Parallel (fast)
for server in "${servers[@]}"; do
    ping -c 1 "$server" &> /dev/null &
done
wait

# Using GNU parallel (even better)
parallel -j 10 ping -c 1 ::: "${servers[@]}"
```

### Read Files Line by Line Efficiently
```bash
# Bad - loads entire file
for line in $(cat file.txt); do
    echo "$line"
done

# Good - reads line by line
while IFS= read -r line; do
    echo "$line"
done < file.txt
```

---

## Testing

### ShellCheck - Static Analysis
```bash
# Install
brew install shellcheck  # macOS
apt-get install shellcheck  # Ubuntu

# Run
shellcheck myscript.sh
```

### Unit Testing with BATS
```bash
# Install BATS (Bash Automated Testing System)
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local

# test_script.bats
#!/usr/bin/env bats

@test "function returns expected value" {
    source myscript.sh
    result=$(my_function "input")
    [ "$result" = "expected_output" ]
}

# Run tests
bats test_script.bats
```

### Integration Testing
```bash
#!/bin/bash
# test_integration.sh

# Setup
setup() {
    TEST_DIR=$(mktemp -d)
}

# Teardown
teardown() {
    rm -rf "$TEST_DIR"
}

# Test
test_backup_creates_file() {
    setup
    
    ./backup.sh --output "$TEST_DIR/backup.tar.gz"
    
    if [[ -f "$TEST_DIR/backup.tar.gz" ]]; then
        echo "PASS: Backup file created"
    else
        echo "FAIL: Backup file not created"
        exit 1
    fi
    
    teardown
}

test_backup_creates_file
```

---

## Style Guide

### Naming Conventions
```bash
# Constants - UPPERCASE
readonly MAX_RETRIES=3

# Functions - lowercase with underscores
get_user_input() {
    ...
}

# Variables - lowercase with underscores
user_name="john"
```

### Comments
```bash
# Single-line comment

################################################################################
# Multi-line section header
# Describes a major section of the script
################################################################################

# Function documentation
# Args:
#   $1 - server name
#   $2 - port number
# Returns:
#   0 on success, 1 on failure
check_server() {
    ...
}
```

---

## Common Pitfalls

### 1. Word Splitting
```bash
# Bad
files="file1.txt file2.txt"
rm $files  # Splits into two arguments

# Good
files="file1.txt file2.txt"
rm $files  # Error - should use array
```

### 2. Glob Expansion
```bash
# Bad
if [ $var == *.txt ]; then  # Glob expands!

# Good
if [[ $var == *.txt ]]; then  # Pattern match, no expansion
```

### 3. Exit Codes
```bash
# Bad - can't distinguish between different errors
some_command || exit 1

# Good - meaningful exit codes
if ! some_command; then
    echo "Command failed"
    exit 2
fi
```

---

## Checklist for Production Scripts

- [ ] Uses `set -euo pipefail`
- [ ] Has proper shebang (`#!/bin/bash`)
- [ ] Includes usage/help function
- [ ] Validates all inputs
- [ ] Quotes all variables
- [ ] Implements logging
- [ ] Has error handling and cleanup
- [ ] Includes dry-run mode for destructive operations
- [ ] Checked with ShellCheck
- [ ] Documented with comments
- [ ] Tested in realistic environment
- [ ] Has meaningful exit codes
- [ ] Uses functions for organization
- [ ] No hardcoded secrets
- [ ] Handles signals (trap)

---

## Resources

- [ShellCheck](https://www.shellcheck.net/) - Find bugs in shell scripts
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Bash Pitfalls](https://mywiki.wooledge.org/BashPitfalls)
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)

---

**Write safe, reliable, production-ready shell scripts!** 🛡️
