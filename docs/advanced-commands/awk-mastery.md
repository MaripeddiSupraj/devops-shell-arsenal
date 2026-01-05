# AWK Mastery Guide for DevOps Engineers

Master AWK for powerful data processing, log analysis, and report generation.

## Table of Contents
- [Introduction](#introduction)
- [AWK Basics Refresher](#awk-basics-refresher)
- [Advanced Patterns](#advanced-patterns)
- [Real-World DevOps Examples](#real-world-devops-examples)
- [Performance Optimization](#performance-optimization)

---

## Introduction

AWK is one of the most powerful text-processing tools for DevOps work. While `grep` finds lines and `sed` modifies them, AWK excels at:
- **Data extraction and transformation**
- **Column-based processing** (logs, CSVs, metrics)
- **Statistical analysis** (averages, sums, counts)
- **Custom report generation**

### Why AWK for DevOps?
- ✅ Lightning-fast for large log files
- ✅ Built-in support for field/column processing
- ✅ Powerful arithmetic and string operations
- ✅ Available on every Unix system

---

## AWK Basics Refresher

### AWK Structure
```bash
awk 'PATTERN { ACTION }' file
```

### Built-in Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `$0` | Entire line | Full log entry |
| `$1, $2, ...` | Fields (columns) | `$1` = first field |
| `NR` | Current line number | Line 42 |
| `NF` | Number of fields in line | 5 fields |
| `FS` | Field separator (input) | Default: whitespace |
| `OFS` | Output field separator | Default: space |
| `RS` | Record separator | Default: newline |
| `FILENAME` | Current filename | access.log |

---

## Advanced Patterns

### 1. Pattern Matching with Regex
```bash
# Lines containing "ERROR" or "FATAL"
awk '/ERROR|FATAL/ { print $0 }' app.log

# Lines where field 9 (status code) is 5xx
awk '$9 ~ /^5/ { print $0 }' access.log

# Lines NOT containing "INFO"
awk '!/INFO/ { print $0 }' app.log
```

### 2. Field Conditions
```bash
# Response time (field 11) > 1000ms
awk '$11 > 1000 { print $1, $7, $11 }' access.log

# Status code = 404
awk '$9 == 404 { print $7 }' access.log

# Multiple conditions (AND)
awk '$9 >= 500 && $11 > 2000 { print $0 }' access.log

# Multiple conditions (OR)
awk '$9 == 404 || $9 == 500 { print $0 }' access.log
```

### 3. BEGIN and END Blocks
```bash
# BEGIN: Runs before processing any input
# END: Runs after processing all input

awk '
BEGIN {
    print "=== Log Analysis Report ==="
    count = 0
}
/ERROR/ {
    count++
    print "Error on line " NR ": " $0
}
END {
    print "=== Summary ==="
    print "Total errors: " count
}
' app.log
```

---

## Real-World DevOps Examples

### Example 1: Nginx Access Log Analysis

**Input (nginx access.log):**
```
192.168.1.1 - - [05/Jan/2026:10:15:30 +0000] "GET /api/users HTTP/1.1" 200 1234 0.123
192.168.1.2 - - [05/Jan/2026:10:15:31 +0000] "POST /api/login HTTP/1.1" 500 567 2.456
192.168.1.3 - - [05/Jan/2026:10:15:32 +0000] "GET /api/products HTTP/1.1" 200 8901 0.089
```

**Task: Calculate average response time by status code**
```bash
awk '
{
    status = $9    # Status code (field 9)
    time = $NF     # Response time (last field)
    
    count[status]++
    sum[status] += time
}
END {
    for (status in count) {
        avg = sum[status] / count[status]
        printf "Status %s: %.3f avg response time (%d requests)\n", status, avg, count[status]
    }
}
' access.log
```

**Output:**
```
Status 200: 0.106 avg response time (2 requests)
Status 500: 2.456 avg response time (1 requests)
```

---

### Example 2: Top 10 Slowest API Endpoints

```bash
awk '
{
    endpoint = $7       # URL path
    response_time = $NF # Last field
    
    if (response_time > max[endpoint]) {
        max[endpoint] = response_time
    }
    sum[endpoint] += response_time
    count[endpoint]++
}
END {
    for (ep in count) {
        avg = sum[ep] / count[ep]
        printf "%s\t%.3f\t%.3f\t%d\n", ep, avg, max[ep], count[ep]
    }
}
' access.log | sort -k2 -rn | head -10 | column -t
```

---

### Example 3: Parse CSV and Generate Report

**Input (servers.csv):**
```csv
hostname,cpu,memory,disk,status
web-01,45.2,67.8,80.1,healthy
web-02,89.5,91.2,95.3,warning
db-01,34.1,55.6,45.2,healthy
```

**Task: Find servers with high resource usage**
```bash
awk -F',' '
BEGIN {
    print "=== High Resource Usage Report ==="
    print ""
}
NR > 1 {  # Skip header
    hostname = $1
    cpu = $2
    memory = $3
    disk = $4
    
    if (cpu > 80 || memory > 80 || disk > 80) {
        printf "⚠️  %s: CPU=%.1f%% MEM=%.1f%% DISK=%.1f%%\n", hostname, cpu, memory, disk
        
        if (cpu > 80) alerts[hostname] = alerts[hostname] " HIGH_CPU"
        if (memory > 80) alerts[hostname] = alerts[hostname] " HIGH_MEM"
        if (disk > 80) alerts[hostname] = alerts[hostname] " HIGH_DISK"
    }
}
END {
    print ""
    print "=== Alerts Summary ==="
    for (host in alerts) {
        print host ":" alerts[host]
    }
}
' servers.csv
```

**Output:**
```
=== High Resource Usage Report ===

⚠️  web-02: CPU=89.5% MEM=91.2% DISK=95.3%

=== Alerts Summary ===
web-02: HIGH_CPU HIGH_MEM HIGH_DISK
```

---

### Example 4: Kubernetes Pod Resource Usage

```bash
# Get pod resource usage and format nicely
kubectl top pods --all-namespaces | awk '
BEGIN {
    printf "%-20s %-40s %10s %10s\n", "NAMESPACE", "POD", "CPU", "MEMORY"
    printf "%.0s-" {1..80}
    print ""
}
NR > 1 {
    namespace = $1
    pod = $2
    cpu = $3
    memory = $4
    
    # Extract numeric value from CPU (e.g., "125m" -> 125)
    cpu_val = substr(cpu, 1, length(cpu)-1)
    
    # Color code high usage
    if (cpu_val > 1000) {
        printf "\033[0;31m%-20s %-40s %10s %10s\033[0m\n", namespace, pod, cpu, memory
    } else if (cpu_val > 500) {
        printf "\033[1;33m%-20s %-40s %10s %10s\033[0m\n", namespace, pod, cpu, memory
    } else {
        printf "%-20s %-40s %10s %10s\n", namespace, pod, cpu, memory
    }
}
'
```

---

### Example 5: Application Log Error Rate

**Calculate error rate per minute:**
```bash
awk '
{
    # Extract timestamp (assumes format: 2026-01-05 10:15:30)
    timestamp = $1 " " substr($2, 1, 5)  # YYYY-MM-DD HH:MM
    level = $3
    
    total[timestamp]++
    
    if (level == "ERROR" || level == "FATAL") {
        errors[timestamp]++
    }
}
END {
    print "Timestamp\t\tTotal\tErrors\tError %"
    print "================================================"
    for (ts in total) {
        error_count = errors[ts] ? errors[ts] : 0
        error_pct = (error_count / total[ts]) * 100
        printf "%s\t%d\t%d\t%.2f%%\n", ts, total[ts], error_count, error_pct
    }
}
' app.log | sort
```

---

### Example 6: Multi-File Processing

**Combine metrics from multiple files:**
```bash
awk '
# Track current filename
FNR == 1 {
    file_count++
}
{
    # Process each line
    server = $1
    metric = $2
    
    sum[server] += metric
    count[server]++
}
END {
    print "Processed " file_count " files"
    print ""
    print "Server\t\tAverage"
    for (s in sum) {
        printf "%s\t\t%.2f\n", s, sum[s]/count[s]
    }
}
' server1-metrics.log server2-metrics.log server3-metrics.log
```

---

## Advanced Techniques

### 1. Functions in AWK
```bash
awk '
# Define custom functions
function format_bytes(bytes) {
    if (bytes >= 1073741824) {
        return sprintf("%.2f GB", bytes / 1073741824)
    } else if (bytes >= 1048576) {
        return sprintf("%.2f MB", bytes / 1048576)
    } else if (bytes >= 1024) {
        return sprintf("%.2f KB", bytes / 1024)
    } else {
        return bytes " B"
    }
}

{
    bytes = $10
    print $7, format_bytes(bytes)
}
' access.log
```

### 2. Arrays for Deduplication
```bash
# Find unique IP addresses
awk '!seen[$1]++ { print $1 }' access.log

# Count unique values
awk '{ count[$1]++ } END { print length(count) " unique IPs" }' access.log
```

### 3. Two-Dimensional Arrays
```bash
# Count requests by hour and status code
awk '
{
    hour = substr($4, 13, 2)  # Extract hour from timestamp
    status = $9
    
    matrix[hour, status]++
}
END {
    # Print header
    printf "Hour\t200\t404\t500\n"
    
    for (h = 0; h < 24; h++) {
        printf "%02d:00\t%d\t%d\t%d\n", h, matrix[h, "200"], matrix[h, "404"], matrix[h, "500"]
    }
}
' access.log
```

---

## Performance Optimization

### 1. Use Field Numbers Instead of Regex When Possible
```bash
# Slow (regex on every line)
awk '/^192\./ { print }' access.log

# Fast (field comparison)
awk '$1 ~ /^192\./ { print }' access.log
```

### 2. Exit Early When Possible
```bash
# Find first 10 errors and exit
awk '/ERROR/ { print; count++; if (count >= 10) exit }' huge.log
```

### 3. Use Built-in Functions
```bash
# Slow (custom logic)
awk '{ for (i=1; i<=NF; i++) if ($i == "ERROR") print }' file

# Fast (built-in match)
awk '/ERROR/ { print }' file
```

---

## Common DevOps AWK One-Liners

```bash
# Sum values in column 3
awk '{ sum += $3 } END { print sum }' file

# Average of column 5
awk '{ sum += $5; count++ } END { print sum/count }' file

# Print lines longer than 80 characters
awk 'length > 80' file

# Number lines (like cat -n)
awk '{ print NR, $0 }' file

# Remove duplicate lines (keeps first occurrence)
awk '!seen[$0]++' file

# Print specific columns in different order
awk '{ print $3, $1, $2 }' file

# Conditional column printing
awk '{ if ($3 > 100) print $1, $3 }' file

# Print every 10th line
awk 'NR % 10 == 0' file
```

---

## AWK vs Other Tools

| Task | AWK | Alternatives |
|------|-----|--------------|
| Extract columns | ⭐⭐⭐⭐⭐ | `cut` (simple), `grep` (patterns) |
| Math operations | ⭐⭐⭐⭐⭐ | `bc` (calculator), `expr` |
| Pattern matching | ⭐⭐⭐⭐ | `grep` (simpler), `sed` (editing) |
| Aggregation | ⭐⭐⭐⭐⭐ | `sort | uniq -c`, `datamash` |
| Complex logic | ⭐⭐⭐⭐ | Python/Perl (more features) |

---

## Best Practices

1. **Use `-F` for custom delimiters**: `awk -F',' '{ print $1 }' file.csv`
2. **Quote AWK programs**: Always use single quotes to avoid shell expansion
3. **Test patterns first**: Use `awk '/pattern/ { print }' file` before complex actions
4. **Use meaningful variable names**: `status` instead of `x`
5. **Comment complex scripts**: Add comments for maintenance
6. **Profile performance**: Use `time` for benchmarking large files

---

## Debugging AWK Scripts

```bash
# Print all fields with their numbers
awk '{ for(i=1; i<=NF; i++) print i, $i }' file

# Show NR and NF for each line
awk '{ print "Line", NR, "has", NF, "fields" }' file

# Debug mode (shows pattern-action execution)
awk -d '{ print $1 }' file
```

---

## Resources

- [GNU AWK Manual](https://www.gnu.org/software/gawk/manual/)
- [AWK One-Liners](https://www.pement.org/awk/awk1line.txt)
- Practice with real logs from `/var/log/`

---

**Master AWK and unlock powerful data processing capabilities in your shell scripting!** 🚀
