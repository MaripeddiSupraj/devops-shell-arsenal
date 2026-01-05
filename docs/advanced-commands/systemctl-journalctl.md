# systemctl & journalctl Mastery for DevOps

Master systemd service management and journal log querying for modern Linux systems.

---

## Why systemctl/journalctl?

All modern Linux distros use systemd. You need this for:
- ✅ Managing services (start, stop, restart, enable)
- ✅ Debug why services fail
- ✅ Query structured logs efficiently
- ✅ Monitor system events in real-time

---

## systemctl - Service Management

### Basic Service Control

```bash
# Start service
sudo systemctl start nginx

# Stop service
sudo systemctl stop nginx

# Restart service
sudo systemctl restart nginx

# Reload config without restart
sudo systemctl reload nginx

# Enable (start on boot)
sudo systemctl enable nginx

# Disable (don't start on boot)
sudo systemctl disable nginx

# Check if enabled
systemctl is-enabled nginx

# Check if running
systemctl is-active nginx
```

### Service Status

```bash
# Detailed status
systemctl status nginx

# Show recent logs in status
systemctl status nginx -l

# Show all properties
systemctl show nginx

# Check exit code
systemctl show nginx -p ExecMainStatus
```

### List Services

```bash
# All services
systemctl list-units --type=service

# Only running
systemctl list-units --type=service --state=running

# Only failed
systemctl list-units --type=service --state=failed

# Show  all (including disabled)
systemctl list-unit-files --type=service
```

---

## Real-World systemctl Use Cases

### 1. Find Failed Services

```bash
# Quick check for failures
systemctl --failed

# Detailed failure info
systemctl status $(systemctl --failed --plain | awk '{print $2}')
```

### 2. Restart All Web Services

```bash
# Find and restart
systemctl list-units --type=service --state=running | \
  grep -E "nginx|apache|httpd" | \
  awk '{print $1}' | \
  xargs -I {} sudo systemctl restart {}
```

### 3. Service Dependencies

```bash
# What depends on this service?
systemctl list-dependencies nginx --reverse

# What does this service depend on?
systemctl list-dependencies nginx
```

### 4. Auto-Restart Failed Services

```bash
# Edit service to auto-restart
sudo systemctl edit nginx

# Add this:
[Service]
Restart=on-failure
RestartSec=5s
```

---

## journalctl - Log Querying

### Basic Log Viewing

```bash
# All logs
journalctl

# Follow (tail -f equivalent)
journalctl -f

# Last 100 lines
journalctl -n 100

# Reverse order (newest first)
journalctl -r

# Since boot
journalctl -b

# Previous boot
journalctl -b -1
```

### Filter by Service

```bash
# Specific service
journalctl -u nginx

# Follow specific service
journalctl -u nginx -f

# Multiple services
journalctl -u nginx -u mysql

# Since/until time
journalctl -u nginx --since "2026-01-05 10:00:00"
journalctl -u nginx --since "1 hour ago"
journalctl -u nginx --until "30 minutes ago"
```

### Filter by Priority

```bash
# Only errors
journalctl -p err

# Errors and critical
journalctl -p err..crit

# Priority levels:
# 0: emerg (system unusable)
# 1: alert (immediate action)
# 2: crit (critical)
# 3: err (error)
# 4: warning
# 5: notice
# 6: info
# 7: debug
```

---

## Real-World journalctl Use Cases

### 1. Debug Service Failure

```bash
# See why nginx failed to start
journalctl -u nginx -xe

# Check config errors
journalctl -u nginx | grep -i error | tail -20
```

### 2. Track Service Restarts

```bash
# Find all service restarts today
journalctl --since today | grep "Started\|Stopped" | grep nginx
```

### 3. Find Boot Issues

```bash
# Check last boot for errors
journalctl -b -p err

# See all failed units at boot
journalctl -b | grep "Failed to start"
```

### 4. Monitor System in Real-Time

```bash
# Live errors across all services
journalctl -f -p err

# Live logs from multiple services
journalctl -f -u nginx -u mysql -u redis
```

### 5. Search for Specific Events

```bash
# Find OOM killer events
journalctl | grep -i "out of memory"

# Find SSH login attempts
journalctl -u sshd | grep "Accepted\|Failed"

# Find disk errors
journalctl -k | grep -i "I/O error"
```

---

## Advanced Patterns

### Output Formats

```bash
# JSON output (for parsing)
journalctl -u nginx -o json

# JSON lines (one per line)
journalctl -u nginx -o json-pretty

# Short format (syslog-like)
journalctl -u nginx -o short

# Verbose (all fields)
journalctl -u nginx -o verbose
```

### Disk Usage

```bash
# Check journal size
journalctl --disk-usage

# Clean old logs (keep 100MB)
sudo journalctl --vacuum-size=100M

# Clean logs older than 30 days
sudo journalctl --vacuum-time=30d

# Rotate journals
sudo journalctl --rotate
```

### Query Performance

```bash
# Use --since for faster queries
journalctl -u nginx --since "1 hour ago"

# Limit output
journalctl -u nginx -n 1000

# Cursor (for pagination)
journalctl --show-cursor
journalctl --after-cursor="s=..."
```

---

## Production Debugging Workflows

### Scenario: Service Won't Start

```bash
# 1. Check status
systemctl status nginx

# 2. See detailed errors
journalctl -u nginx -xe

# 3. Check config
nginx -t

# 4. See recent failures
journalctl -u nginx --since "10 minutes ago" -p err
```

### Scenario: Service Keeps Restarting

```bash
# 1. Watch real-time
journalctl -u app -f

# 2. Count restarts today
journalctl -u app --since today | grep -c "Started"

# 3. Find crash reason
journalctl -u app | grep -B 10 "Main process exited"

# 4. Check resource limits
systemctl show app | grep -E "Limit|Memory"
```

### Scenario: Find What Changed

```bash
# Compare current boot vs previous
diff <(journalctl -b -1 -u nginx) <(journalctl -b 0 -u nginx)

# Find recent config changes
journalctl | grep "reload\|restart" | grep nginx
```

---

## Custom Service Creation

### Simple Service Example

```bash
# Create service file
sudo nano /etc/systemd/system/myapp.service
```

```ini
[Unit]
Description=My Application
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/start.sh
Restart=on-failure
RestartSec=10s

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=myapp

# Security
PrivateTmp=yes
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
```

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable and start
sudo systemctl enable myapp
sudo systemctl start myapp

# Check logs
journalctl -u myapp -f
```

---

## Useful Aliases

Add to `~/.bashrc`:

```bash
# systemctl shortcuts
alias sc='systemctl'
alias scs='systemctl status'
alias scr='sudo systemctl restart'
alias sce='sudo systemctl enable'
alias scd='sudo systemctl disable'

# journalctl shortcuts
alias jc='journalctl'
alias jcf='journalctl -f'
alias jce='journalctl -p err'
alias jcu='journalctl -u'
```

---

## Cheat Sheet

```bash
# systemctl
systemctl start SERVICE              # Start
systemctl stop SERVICE               # Stop
systemctl restart SERVICE            # Restart
systemctl reload SERVICE             # Reload config
systemctl enable SERVICE             # Start on boot
systemctl disable SERVICE            # Don't start on boot
systemctl status SERVICE             # Status
systemctl is-active SERVICE          # Check if running
systemctl is-enabled SERVICE         # Check if enabled
systemctl --failed                   # Show failed services
systemctl list-units --type=service  # List all services

# journalctl
journalctl                           # All logs
journalctl -f                        # Follow
journalctl -u SERVICE                # Service logs
journalctl -u SERVICE -f             # Follow service
journalctl -p err                    # Only errors
journalctl -b                        # Current boot
journalctl -b -1                     # Previous boot
journalctl --since "1 hour ago"      # Time filter
journalctl -xe                       # Recent errors
journalctl --disk-usage              # Check size
sudo journalctl --vacuum-size=100M   # Clean logs
```

---

**Master systemd and manage services like a pro!** ⚙️
