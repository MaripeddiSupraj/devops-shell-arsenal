# Find + Xargs Power Combos

Master `find` and `xargs` for parallel processing and bulk operations.

---

## Why Find + Xargs?

The Find + Xargs combination is essential for DevOps because it allows you to:
- Process thousands of files in parallel
- Perform bulk operations safely  
- Filter files by complex criteria
- Build powerful automation pipelines

---

## Real-World DevOps Use Cases

### 1. Bulk File Operations

```bash
# Delete log files older than 30 days
find /var/log -name "*.log" -mtime +30 -print0 | xargs -0 rm -f

# Change ownership of all config files
find /etc/app -name "*.conf" -print0 | xargs -0 chown app:app

# Fix permissions on shell scripts
find . -name "*.sh" -print0 | xargs -0 chmod +x

# Compress old logs (parallel with 4 jobs)
find /var/log -name "*.log" -mtime +7 -print0 | \
  xargs -0 -P 4 -I {} gzip {}
```

### 2. Code Search and Refactoring

```bash
# Find all TODO comments across codebase
find . -name "*.py" -print0 | xargs -0 grep -n "TODO"

# Replace deprecated function calls
find . -name "*.js" -print0 | \
  xargs -0 sed -i 's/oldFunction/newFunction/g'

# Count lines of code by file type
find . -name "*.go" -print0 | xargs -0 wc -l | sort -n

# Find files with hardcoded IPs
find . -type f -print0 | \
  xargs -0 grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
```

### 3. Docker / Container Cleanup

```bash
# Find and remove old Docker build artifacts
find /var/lib/docker/tmp -mtime +2 -print0 | xargs -0 rm -rf

# Clean up unused container volumes
docker volume ls -q | xargs docker volume rm 2>/dev/null

# Remove stopped containers
docker ps -aq -f status=exited | xargs docker rm

# Delete untagged images
docker images -f"dangling=true" -q | xargs docker rmi
```

### 4. Log Analysis (Parallel Processing)

```bash
# Count errors in all log files (parallel)
find /var/log/app -name "*.log" -print0 | \
  xargs -0 -P 8 -I {} grep -c "ERROR" {} | \
  awk '{sum+=$1} END {print sum}'

# Extract unique IP addresses from all access logs
find /var/log/nginx -name "access.log*" -print0 | \
  xargs -0 awk '{print $1}' | sort -u

# Find slow queries across all logs
find /var/log/mysql -name "slow.log*" -print0 | \
  xargs -0 grep "Query_time"
```

### 5. Security Scanning

```bash
# Find files with suspicious permissions
find / -perm -4000 -type f -print0 2>/dev/null | xargs -0 ls -lh

# Find world-writable files
find /var/www -type f -perm -002 -print0 | xargs -0 ls -l

# Scan for potential secrets
find . -type f -print0 | \
  xargs -0 grep -i "password\|api_key\|secret" | \
  grep -v ".git"

# Find recently modified files (potential intrusion)
find /var/www -type f -mtime -1 -print0 | xargs -0 ls -lh
```

---

## Advanced Patterns

### Parallel Processing with xargs -P

```bash
# Process 10 files at a time
find /data -name "*.csv" -print0 | \
  xargs -0 -P 10 -I {} python process.py {}

# Convert images in parallel
find . -name "*.png" -print0 | \
  xargs -0 -P 4 -I {} convert {} {}.jpg

# Backup multiple databases concurrently
echo -e "db1\ndb2\ndb3" | \
  xargs -P 3 -I {} mysqldump {} > {}.sql
```

### Safe File Handling with -print0 and -0

```bash
# Problem: Files with spaces break without -print0
find . -name "*.txt" | xargs rm  # BREAKS on "my file.txt"

# Solution: Use -print0 and -0
find . -name "*.txt" -print0 | xargs -0 rm  # Works!
```

### Interactive Confirmation

```bash
# Ask before deleting each file
find . -name "*.tmp" -print0 | xargs -0 -p rm  

# Custom confirmation
find . -name "*.log" -mtime +30 -print0 | \
  xargs -0 -I {} bash -c 'read -p "Delete {}? " ans && [[ $ans == y ]] && rm {}'
```

---

## Complex Real-World Examples

### Example 1: Kubernetes Config Validation

```bash
# Validate all Kubernetes YAML files in parallel
find k8s/ -name "*.yaml" -print0 | \
  xargs -0 -P 8 -I {} kubectl apply --dry-run=client -f {}
```

### Example 2: Multi-Server Log Collection

```bash
# Collect logs from multiple servers
cat servers.txt | \
  xargs -I {} -P 10 ssh {} "tar czf - /var/log/app/*.log" > {}-logs.tar.gz
```

### Example 3: Git Repository Maintenance

```bash
# Find and clean all git repos
find ~/projects -name ".git" -type d -print0 | \
  xargs -0 -I {} bash -c 'cd {}/.. && git gc --aggressive'
```

### Example 4: Terraform/IaC Validation

```bash
# Validate all HCL files
find . -name "*.tf" -print0 | \
  xargs -0 -P 4 terraform fmt -check  

# Find unused terraform modules
find modules/ -type d -mindepth 1 -maxdepth 1 -print0 | \
  xargs -0 -I {} bash -c \
    'grep -r "source.*{}" . > /dev/null || echo "Unused: {}"'
```

---

## Common Gotchas & Solutions

### 1. Argument List Too Long

```bash
# Error: Argument list too long
rm *.log  # Fails with 100,000 files

# Solution: Use find + xargs
find . -name "*.log" -print0 | xargs -0 rm
```

### 2. Special Characters in Filenames

```bash
# Always use -print0 and -0 for safety
find . -name "*special*" -print0 | xargs -0 process
```

### 3. Empty Input Handling

```bash
# xargs runs even with no input (dangerous!)
find . -name "nope.txt" | xargs rm  # Still runs rm!

# Solution: Use -r (or --no-run-if-empty)
find . -name "nope.txt" -print0 | xargs -0 -r rm
```

---

## Find Filters

```bash
# By time
find . -mtime -7        # Modified in last 7 days
find . -mtime +30       # Modified more than 30 days ago
find . -atime -1        # Accessed in last 24 hours

# By size
find . -size +100M      # Larger than 100MB
find . -size -1k        # Smaller than 1KB
find . -empty           # Empty files

# By type
find . -type f          # Files only
find . -type d          # Directories only
find . -type l          # Symlinks

# By permissions
find . -perm 777        # Exact permission
find . -perm -644       # At least these permissions
find . -user root       # Owned by root

# Combined filters (AND)
find . -name "*.log" -mtime +30 -size +100M

# OR logic
find . \( -name "*.log" -o -name "*.txt" \)
```

---

## Cheat Sheet

```bash
# Basic pattern
find <path> <filters> -print0 | xargs -0 <command>

# Parallel processing
find <path> <filters> -print0 | xargs -0 -P <N> <command>

# Interactive
find <path> <filters> -print0 | xargs -0 -p <command>

# Placeholder
find <path> <filters> -print0 | xargs -0 -I {} <command> {}

# Dry run (safe testing)
find <path> <filters> -print0 | xargs -0 echo <command>

# Common filters
-name "pattern"         # Filename matches
-type f                 # Files only
-mtime +N               # Modified N+ days ago
-size +100M             # Larger than 100MB
-executable             # Executable files
```

---

**Master find + xargs for powerful bulk operations!** 🔧
