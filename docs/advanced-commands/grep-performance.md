# GREP & Ripgrep Mastery for DevOps

Master grep and ripgrep for lightning-fast searching in logs, code, and configs.

---

## Why GREP/Ripgrep?

Essential for DevOps because:
- ✅ Search through massive log files instantly
- ✅ Find configuration issues across servers
- ✅ Debug production incidents in real-time
- ✅ Search codebases for patterns

---

## Basic GREP vs Ripgrep

| Feature | grep | ripgrep (rg) |
|---------|------|--------------|
| Speed | Fast | **10-100x faster** |
| Recursive | `grep -r` | Default |
| Ignores .git | No | **Yes** |
| Color | `--color` | Default |
| Modern regex | Limited | Full support |

**Install ripgrep:**
```bash
# macOS
brew install ripgrep

# Ubuntu/Debian
apt install ripgrep

# CentOS/RHEL
yum install ripgrep
```

---

## Real-World DevOps Use Cases

### 1. Find Errors in Logs (Fast!)

```bash
# Traditional grep
grep "ERROR" /var/log/app/*.log

# Ripgrep (faster, better output)
rg "ERROR" /var/log/app/

# Case-insensitive
rg -i "error" /var/log/

# Show context (3 lines before/after)
rg -C 3 "ERROR" /var/log/app.log

# Count errors
rg -c "ERROR" /var/log/app.log
```

### 2. Search Across Multiple Files

```bash
# Find all TODO comments in codebase
rg "TODO|FIXME" --type python

# Search only JavaScript files
rg "console.log" --type js

# Search specific file patterns
rg "password" -g "*.conf" -g "*.yaml"

# Exclude certain directories
rg "error" --ignore-dir node_modules --ignore-dir vendor
```

### 3. Find Configuration Issues

```bash
# Find listen ports in nginx configs
rg "listen \d+" /etc/nginx/ -A 2

# Find database connections
rg "DB_HOST|DATABASE_URL" --type sh --type yaml

# Find hardcoded IPs (security issue!)
rg '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b' --type python
```

### 4. Log Analysis (Production Debugging)

```bash
# Find 500 errors in last hour
rg "\" 500 " /var/log/nginx/access.log | tail -1000

# Extract unique error messages
rg "ERROR" app.log | sort | uniq -c | sort -rn

# Find slow queries (> 1 second)
rg "Query_time: [1-9]" /var/log/mysql/slow.log

# Trace specific request ID across services
rg "request_id=abc-123" /var/log/*/app.log
```

### 5. Security Scanning

```bash
# Find potential secrets
rg -i "password|api_key|secret|token" --type yaml --type json

# Find world-writable files in configs
rg "0777|0666" /etc/

# Find sudo usage
rg "sudo" /var/log/auth.log
```

---

## Advanced GREP Patterns

### Regular Expressions

```bash
# Email addresses
rg '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'

# IPv4 addresses
rg '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b'

# URLs
rg 'https?://[^\s"]+'

# Semantic versions
rg '\d+\.\d+\.\d+'
```

### Word Boundaries

```bash
# Match whole word "error" (not "errors" or "terrorize")
rg '\berror\b'

# Match at start of line
rg '^ERROR'

# Match at end of line
rg 'failed$'
```

---

## Performance Optimization

### 1. Use Ripgrep for Speed

```bash
# Grep (slow on large directories)
time grep -r "error" /var/log/
# real: 45.2s

# Ripgrep (much faster!)
time rg "error" /var/log/
# real: 2.1s
```

### 2. Limit Search Scope

```bash
# Only search recent logs
rg "ERROR" $(find /var/log -name "*.log" -mtime -1)

# Only specific file types
rg "error" --type-add 'log:*.log' --type log
```

### 3. Use Fixed Strings for Literal Matches

```bash
# Faster (no regex processing)
rg -F "exact.string.to.find"
```

---

## Production Incident Response

### Scenario: Find Error Spike

```bash
#!/bin/bash
# Find error spike in last 10 minutes

# Get timestamp 10 minutes ago
ten_min_ago=$(date -d '10 minutes ago' '+%Y-%m-%d %H:%M')

# Count errors since then
rg "ERROR.*$ten_min_ago" /var/log/app/ | wc -l

# Show breakdown by error type
rg "ERROR.*$ten_min_ago" /var/log/app/ | \
  awk '{print $5}' | \
  sort | uniq -c | sort -rn
```

### Scenario: Trace Distributed Request

```bash
# Find all logs for trace ID across services
for service in api auth db payment; do
  echo "=== $service ==="
  rg "trace_id=abc-123" /var/log/$service/
done
```

### Scenario: Find Memory Leaks

```bash
# Find OOM killer events
rg "Out of memory|OOM" /var/log/kern.log

# Find processes with high memory
rg "RSS.*[0-9]{6,}" <(ps aux)
```

---

## Useful Patterns for DevOps

```bash
# Find failed systemd services
rg "Failed to start" /var/log/syslog

# Find authentication failures
rg "authentication failure|Failed password" /var/log/auth.log

# Find disk space warnings
rg "No space left|Disk full" /var/log/syslog

# Find network errors
rg "Connection refused|Connection timed out" /var/log/*.log

# Find database errors
rg "Deadlock|Lock wait timeout" /var/log/mysql/

# Find certificate expiry warnings
rg "certificate.*expir" /var/log/nginx/
```

---

## Combining with Other Tools

### With xargs (Process Results)

```bash
# Find and delete old logs
rg -l "2020-" /var/log/ | xargs rm

# Fix permissions on config files
rg -l "database.password" /etc/ | xargs chmod 600
```

### With awk (Extract Fields)

```bash
# Extract IPs from logs
rg "Failed login" /var/log/auth.log | awk '{print $11}' | sort | uniq -c
```

### With jq (Parse JSON Logs)

```bash
# Find errors in JSON logs
rg '"level":"error"' app.log | jq '.message'
```

---

## Cheat Sheet

```bash
# Basic search
rg "pattern" file

# Case-insensitive
rg -i "pattern"

# Whole word
rg -w "word"

# Count matches
rg -c "pattern"

# Show only filenames
rg -l "pattern"

# Invert match (show non-matching)
rg -v "pattern"

# Context (3 lines before/after)
rg -C 3 "pattern"

# Only show matches
rg -o "pattern"

# Specific file types
rg "pattern" --type python
rg "pattern" -t py

# Multiple patterns (OR)
rg "error|warning|critical"

# Multiple patterns (AND)
rg "error" | rg "database"

# Fixed string (no regex)
rg -F "literal.string"
```

---

## Pro Tips

1. **Use ripgrep for everything** - It's faster and has better defaults
2. **Always search with context** (`-C 3`) when debugging
3. **Use `--type` to filter** - Much faster than searching everything
4. **Pipe to less** for large output: `rg "pattern" | less -R`
5. **Save common searches as aliases**:
```bash
alias finderrors='rg -i "error|fail|critical" --type log'
alias findtodos='rg "TODO|FIXME|HACK"'
```

---

**Master grep/ripgrep and search like a pro!** 🔍
