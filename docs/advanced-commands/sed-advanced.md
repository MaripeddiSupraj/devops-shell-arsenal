# SED Advanced - Master Text Transformation

Master SED for powerful in-place editing, complex text transformations, and production automation.

---

## Why SED for DevOps?

SED excels at:
- ✅ **In-place file editing** - Modify config files without manual editing
- ✅ **Stream processing** - Transform data in pipelines
- ✅ **Batch operations** - Update multiple files at once
- ✅ **Pattern-based replacement** - Complex search and replace

---

## Real-World DevOps Use Cases

### 1. Config File Updates in CI/CD

**Replace environment variables in config files:**
```bash
# Update API endpoint across all configs
sed -i 's|api.staging.example.com|api.production.example.com|g' config/*.yaml

# Update database connection string
sed -i 's/DB_HOST=localhost/DB_HOST=prod-db-01.aws.com/' .env

# Change port numbers
sed -i 's/:8080/:9000/g' docker-compose.yml
```

### 2. Log Sanitization (Remove Sensitive Data)

**Remove IP addresses from logs before sharing:**
```bash
# Anonymize IPs
sed 's/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/XXX.XXX.XXX.XXX/g' access.log

# Remove API keys
sed 's/api_key=[A-Za-z0-9]\{32\}/api_key=REDACTED/g' app.log

# Remove email addresses
sed 's/[a-zA-Z0-9._%+-]\+@[a-zA-Z0-9.-]\+\.[a-zA-Z]\{2,\}/user@REDACTED/g' debug.log
```

### 3. Infrastructure as Code Updates

**Update Terraform versions:**
```bash
# Bump AWS provider version across all .tf files
find . -name "*.tf" -exec sed -i 's/version = "~> 4.0"/version = "~> 5.0"/' {} \;

# Update instance types
sed -i 's/instance_type = "t2.micro"/instance_type = "t3.micro"/' main.tf
```

### 4. Kubernetes Manifest Editing

**Update image tags for deployment:**
```bash
# Update all nginx images to latest
sed -i 's|image: nginx:.*|image: nginx:1.25|' k8s/*.yaml

# Change namespace
sed -i 's/namespace: staging/namespace: production/' deployment.yaml

# Update resource limits
sed -i 's/memory: "128Mi"/memory: "256Mi"/' deployment.yaml
```

---

## Advanced SED Patterns

### Multiple Operations (Chaining Commands)

```bash
# Multiple substitutions in one command
sed -e 's/foo/bar/' -e 's/old/new/' -e 's/debug/info/' app.log

# Or use semicolons
sed 's/foo/bar/; s/old/new/; s/debug/info/' app.log
```

### Line-Based Operations

```bash
# Delete lines matching pattern
sed '/DEBUG/d' app.log                    # Delete lines with DEBUG

# Delete blank lines
sed '/^$/d' file.txt

# Delete lines 5-10
sed '5,10d' file.txt

# Print only lines matching pattern
sed -n '/ERROR/p' app.log                 # -n suppresses default output
```

### Insert/Append Lines

```bash
# Insert line before match
sed '/pattern/i\New line before pattern' file.txt

# Append line after match
sed '/pattern/a\New line after pattern' file.txt

# Insert at line number
sed '5i\New line 5' file.txt
```

### Capture Groups and Backreferences

```bash
# Swap two words
echo "Hello World" | sed 's/\(.*\) \(.*\)/\2 \1/'
# Output: World Hello

# Extract domain from email
echo "user@example.com" | sed 's/.*@\(.*\)/\1/'
# Output: example.com

# Reformat date: YYYY-MM-DD to DD/MM/YYYY
echo "2026-01-05" | sed 's/\([0-9]\{4\}\)-\([0-9]\{2\}\)-\([0-9]\{2\}\)/\3\/\2\/\1/'
# Output: 05/01/2026
```

---

## Production Examples

### Example 1: Rotate Log Levels for All Microservices

```bash
#!/bin/bash
# Reduce logging from DEBUG to INFO across all service configs

for config in /etc/services/*/config.yaml; do
    echo "Updating $config..."
    sed -i 's/log_level: DEBUG/log_level: INFO/' "$config"
done
```

### Example 2: Update Docker Compose Environment Variables

```bash
# Update all environment variables prefixed with OLD_
sed -i 's/OLD_\([A-Z_]*\)=/NEW_\1=/' docker-compose.yml

# Example transformation:
# OLD_DATABASE_URL=... → NEW_DATABASE_URL=...
# OLD_API_KEY=... → NEW_API_KEY=...
```

### Example 3: Add Monitoring Labels to Kubernetes Manifests

```bash
# Add monitoring label to all deployments
sed -i '/kind: Deployment/,/metadata:/a\  labels:\n    monitoring: "true"' k8s/*.yaml
```

### Example 4: Sanitize Terraform State for Sharing

```bash
# Remove sensitive outputs from terraform show
terraform show | sed 's/\(password.*=\).*/\1 "REDACTED"/' > sanitized_state.txt
```

### Example 5: Batch Update Server IPs in Configs

```bash
# Update old server IP to new IP across all configs
find /etc/app/config -type f -name "*.conf" -exec \
    sed -i 's/192\.168\.1\.100/10\.0\.1\.50/g' {} \;
```

---

## Advanced Techniques

### 1. Conditional Replacement

```bash
# Replace only on lines containing "production"
sed '/production/ s/http:/https:/' config.yaml

# Replace only on lines NOT containing "staging"
sed '/staging/! s/debug/info/' app.log
```

### 2. Multi-Line Patterns

```bash
# Join lines ending with backslash
sed ':a; /\\$/N; s/\\\n//; ta' file.txt

# Delete XML/HTML tags across multiple lines
sed ':a; /<[^>]*>/{ s/<[^>]*>//g; ta }' file.html
```

### 3. In-Place Editing with Backup

```bash
# Create backup with .bak extension
sed -i.bak 's/old/new/' file.txt

# Backup with timestamp
sed -i.$(date +%Y%m%d) 's/old/new/' config.yaml
```

### 4. Address Ranges

```bash
# Replace only between line 10 and 20
sed '10,20 s/foo/bar/' file.txt

# Replace from match to end of file
sed '/START_MARKER/,$ s/debug/info/' app.log

# Replace between two patterns
sed '/BEGIN/,/END/ s/old/new/' file.txt
```

---

## Common DevOps Patterns

### Update Version Numbers
```bash
# Semantic versioning bump
sed -i 's/version: "1\.2\.3"/version: "1.2.4"/' chart.yaml

# Update all version strings
sed -i -E 's/v[0-9]+\.[0-9]+\.[0-9]+/v2.0.0/' README.md
```

### Environment Promotion
```bash
# Promote staging to production
sed 's/env: staging/env: production/; s/replicas: 1/replicas: 3/' \
    staging.yaml > production.yaml
```

### Secret Placeholder Replacement
```bash
# Replace placeholders with actual secrets (from env vars)
sed "s/{{DB_PASSWORD}}/$DB_PASSWORD/; s/{{API_KEY}}/$API_KEY/" \
    template.yaml > actual.yaml
```

### Comment/Uncomment Configuration
```bash
# Comment out debug lines
sed -i 's/^\(.*debug.*\)$/# \1/' config.ini

# Uncomment production settings
sed -i 's/^# \(.*production.*\)$/\1/' config.ini
```

---

## Performance Tips

### 1. Use Extended Regex (`-E` or `-r`)
```bash
# Standard (BRE - Basic Regular Expression)
sed 's/\([0-9]\{3\}\)-\([0-9]\{3\}\)/\1.\2/'

# Extended (ERE - much cleaner)
sed -E 's/([0-9]{3})-([0-9]{3})/\1.\2/'
```

### 2. Exit After First Match
```bash
# Stop processing after first match (faster for large files)
sed '/pattern/q' huge_file.log
```

### 3. Process Only Specific Files
```bash
# Only process .conf files
find . -name "*.conf" -exec sed -i 's/old/new/' {} +
```

---

## SED vs Other Tools

| Task | SED | AWK | Perl |
|------|-----|-----|------|
| Line-based replacement | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| In-place editing | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| Field processing | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Complex logic | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Simple substitution | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |

---

## Debugging SED

```bash
# Show what sed would do (dry-run)
sed 's/old/new/' file.txt  # No -i, just preview

# Show line numbers
sed = file.txt | sed 'N; s/\n/\t/'

# Verbose mode (GNU sed)
sed --debug 's/old/new/' file.txt
```

---

## Common Pitfalls

### 1. Mac vs Linux Differences
```bash
# Mac requires empty string after -i
sed -i '' 's/old/new/' file.txt  # macOS

# Linux allows -i alone
sed -i 's/old/new/' file.txt     # Linux

# Portable version
sed -i.bak 's/old/new/' file.txt  # Works on both
```

### 2. Special Characters
```bash
# Escape special characters: . * [ ] ^ $ \ /
sed 's/192\.168\.1\.1/10.0.0.1/'  # Escape dots

# Use different delimiter to avoid escaping
sed 's|/old/path|/new/path|' file.txt  # Use | instead of /
```

### 3. Greedy Matching
```bash
# Problem: Greedy match
echo "foo bar baz" | sed 's/f.*b/X/'  # Output: Xaz (too much!)

# Solution: Use non-greedy (not in standard sed, use Perl)
echo "foo bar baz" | perl -pe 's/f.*?b/X/'  # Output: Xar baz
```

---

## Cheat Sheet

```bash
# Substitute
sed 's/old/new/'              # First occurrence per line
sed 's/old/new/g'             # All occurrences (global)
sed 's/old/new/2'             # Only 2nd occurrence
sed 's/old/new/gi'            # Case-insensitive global

# Delete
sed '/pattern/d'              # Delete matching lines
sed '5d'                      # Delete line 5
sed '5,10d'                   # Delete lines 5-10

# Print
sed -n '/pattern/p'           # Print only matching lines
sed -n '5,10p'                # Print lines 5-10

# Insert/Append
sed '5i\New line'             # Insert before line 5
sed '5a\New line'             # Append after line 5

# In-place editing
sed -i 's/old/new/g' file     # Edit file in-place
sed -i.bak 's/old/new/g' file # With backup

# Multiple commands
sed -e 's/a/A/' -e 's/b/B/'   # Multiple -e flags
sed 's/a/A/; s/b/B/'          # Semicolon separator
```

---

## Resources

- [GNU SED Manual](https://www.gnu.org/software/sed/manual/)
- [SED One-Liners](https://sed.sourceforge.io/sed1line.txt)
- Practice with real config files in `/etc/`

---

**Master SED and automate configuration management like a pro!** ⚙️
