# SSH & Networking Essentials for DevOps

Master SSH tunneling, ProxyJump, and essential networking commands for production operations.

---

## SSH Mastery

### Basic SSH (Beyond the Basics)

```bash
# SSH with specific key
ssh -i ~/.ssh/prod-key.pem user@server

# SSH with port forwarding (local)
ssh -L 8080:localhost:80 user@server
# Access via: localhost:8080

# SSH with port forwarding (remote)
ssh -R 9000:localhost:3000 user@server
# Server can access via: localhost:9000

# SSH tunnel as background process
ssh -f -N -L 8080:localhost:80 user@server

# Keep connection alive
ssh -o ServerAliveInterval=60 user@server
```

### ProxyJump (Bastion Hosts)

```bash
# Jump through bastion
ssh -J bastion-user@bastion.com final-user@internal-server

# Multiple jumps
ssh -J jump1,jump2,jump3 final-server

# Configure in ~/.ssh/config:
Host internal-*
    ProxyJump bastion.company.com
    User devops

# Then simply:
ssh internal-db-01
```

### SSH Config File Magic

```bash
# ~/.ssh/config
Host prod-*
    User ubuntu
    IdentityFile ~/.ssh/prod-key.pem
    StrictHostKeyChecking no
    ServerAliveInterval 60

Host bastion
    Hostname bastion.company.com
    User admin
    Port 2222

Host db-prod
    Hostname 10.0.1.50
    ProxyJump bastion
    LocalForward 5432 localhost:5432

# Usage:
ssh prod-web-01       # Auto uses ubuntu@ and prod-key
ssh db-prod           # Auto jumps through bastion
```

### SSH Tunneling Patterns

```bash
# Access remote database locally
ssh -L 3306:localhost:3306 db-server
mysql -h 127.0.0.1 -P 3306

# Access internal web service
ssh -L 8080:internal-api:80 bastion
curl localhost:8080/api

# SOCKS proxy (route all traffic)
ssh -D 9050 server
# Configure browser to use localhost:9050 as SOCKS5 proxy

# Reverse tunnel (expose local to remote)
ssh -R 8080:localhost:3000 server
# Server can now access your local:3000 via their localhost:8080
```

---

## SCP & RSYNC

### SCP (Secure Copy)

```bash
# Copy to remote
scp file.txt user@server:/path/

# Copy from remote
scp user@server:/path/file.txt ./

# Recursive copy
scp -r /local/dir user@server:/remote/dir

# Copy through bastion
scp -o "ProxyJump bastion" file.txt user@internal:/path/

# Copy with specific key
scp -i ~/.ssh/key.pem file.txt user@server:/path/

# Show progress
scp -v file.txt user@server:/path/

# Preserve permissions
scp -p file.txt user@server:/path/
```

### RSYNC (Better than SCP!)

```bash
# Basic sync
rsync -av /local/dir/ user@server:/remote/dir/

# Sync with progress
rsync -av --progress /local/ user@server:/remote/

# Sync with delete (mirror)
rsync -av --delete /local/ user@server:/remote/

# Dry run first!
rsync -av --dry-run --delete /local/ user@server:/remote/

# Exclude files
rsync -av --exclude='*.log' --exclude='node_modules'  /local/ user@server:/remote/

# Resume interrupted transfer
rsync -av --partial --progress /local/ user@server:/remote/

# Sync through SSH tunnel
rsync -av -e "ssh -J bastion" /local/ user@internal:/remote/

# Backup with bandwidth limit (1MB/s)
rsync -av --bwlimit=1000 /data/ backup-server:/backups/
```

---

## Network Troubleshooting

### Test Connectivity

```bash
# Simple ping
ping -c 4 google.com

# Test specific port (using nc)
nc -zv server.com 443

# Test port with timeout
timeout 5 bash -c "</dev/tcp/server.com/80" && echo "Port open"

# Test multiple ports
for port in 22 80 443 3306; do
  nc -zv -w 2 server.com $port
done

# Trace network path
traceroute google.com
mtr google.com  # Better: combines ping + traceroute
```

### DNS Queries

```bash
# Basic lookup
host example.com
nslookup example.com

# Detailed DNS query
dig example.com

# Only show IP
dig +short example.com

# Query specific nameserver
dig @8.8.8.8 example.com

# Reverse DNS
dig -x 8.8.8.8

# Show all DNS records
dig example.com ANY
```

### Network Statistics

```bash
# Show listening ports
sudo ss -tulpn
sudo netstat -tulpn  # Older, but still works

# Show active connections
ss -tun

# Show connections by process
sudo ss -tp

# Count connections per state
ss -tan | awk '{print $1}' | sort | uniq -c

# Show bandwidth usage per connection
sudo nethogs

# Show network interface statistics
ip -s link
ifconfig -a
```

---

## Real-World Networking Scenarios

### 1. SSH Connection Dropping?

```bash
# Add to ~/.ssh/config
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
```

### 2. Test if Port is Blocked

```bash
#!/bin/bash
# Test if firewall is blocking port

HOST="server.com"
PORT=443

timeout 5 bash -c "cat < /dev/null > /dev/tcp/$HOST/$PORT"
if [ $? -eq 0 ]; then
    echo "✓ Port $PORT is open"
else
    echo "✗ Port $PORT is blocked or unreachable"
fi
```

### 3. Find Which Process is Using a Port

```bash
# Who's on port 8080?
sudo lsof -i :8080

# Or with ss
sudo ss -tulpn | grep :8080

# Kill process on port
sudo kill $(sudo lsof -t -i:8080)
```

### 4. Monitor Network Traffic

```bash
# Show real-time bandwidth by process
sudo nethogs

# Show real-time interface statistics
watch -n1 'ip -s link show eth0'

# Capture packets (like Wireshark CLI)
sudo tcpdump -i eth0 -n "port 80"

# Capture to file for analysis
sudo tcpdump -i eth0 -w capture.pcap
```

### 5. Test Download Speed

```bash
# Download speed test
curl -o /dev/null https://speed.cloudflare.com/__down?bytes=100000000

# With progress
curl -o /dev/null --progress-bar https://speed.cloudflare.com/__down?bytes=10000000

# Upload speed test
dd if=/dev/zero bs=1M count=100 | ssh server "cat > /dev/null"
```

---

## SSH Security Best Practices

```bash
# Disable password auth (use keys only)
# In /etc/ssh/sshd_config:
PasswordAuthentication no
PubkeyAuthentication yes

# Disable root login
PermitRootLogin no

# Change default port
Port 2222

# Restrict users
AllowUsers devops deploy

# Enable 2FA
AuthenticationMethods publickey,keyboard-interactive

# Restart SSH
sudo systemctl restart sshd
```

---

## Cheat Sheet

```bash
# SSH
ssh user@host                        # Basic SSH
ssh -i key.pem user@host             # With key
ssh -J bastion user@internal         # Through bastion
ssh -L 8080:localhost:80 server      # Local port forward
ssh -R 9000:localhost:3000 server    # Remote port forward
ssh -D 9050 server                   # SOCKS proxy

# SCP
scp file user@host:/path/            # Copy to remote
scp user@host:/path/file ./          # Copy from remote
scp -r dir user@host:/path/          # Recursive

# RSYNC
rsync -av /local/ user@host:/remote/ # Sync
rsync -av --delete /src/ /dst/       # Mirror
rsync -av --dry-run /src/ /dst/      # Test first

# Network Testing
ping -c 4 host                       # Test connectivity
nc -zv host port                     # Test port
dig +short domain.com                # DNS lookup
traceroute host                      # Trace route

# Port Info
sudo ss -tulpn                       # Show listening
sudo lsof -i :port                   # Who uses port
sudo netstat -tulpn                  # Show connections
```

---

**Master SSH and networking for seamless DevOps operations!** 🌐
