# DevOps Shell Arsenal - Example README

This file provides an overview of what each example script does and when to use it.

## Log Analysis

### [error-spike-detector.sh](error-spike-detector.sh)
Monitor HTTP logs in real-time for error rate spikes (4xx/5xx errors).

**Use When:**
- Monitoring production web servers
- Need real-time error alerting
- Troubleshooting traffic spikes

**Example:**
```bash
./error-spike-detector.sh -f /var/log/nginx/access.log -t 10 -i 60
```

### [multi-service-correlator.sh](multi-service-correlator.sh)
Correlate logs across multiple microservices using trace IDs.

**Use When:**
- Debugging distributed systems
- Tracing requests across services
- Analyzing microservice interactions

**Example:**
```bash
./multi-service-correlator.sh abc-123-def -f timeline
```

---

## Cloud Automation

### [aws-unused-resources.sh](../cloud-automation/aws-unused-resources.sh)
Find and optionally delete unused AWS resources to reduce costs.

**Use When:**
- Monthly cost optimization
- Cleaning up after development
- Identifying resource waste

**Example:**
```bash
# Dry-run scan
./aws-unused-resources.sh

# Actually delete resources
./aws-unused-resources.sh --delete
```

**Finds:**
- Unattached EBS volumes
- Unused Elastic IPs
- Idle load balancers
- Unused security groups

---

## Kubernetes

### [pod-restart-analyzer.sh](../kubernetes/pod-restart-analyzer.sh)
Analyze pod restart patterns to identify problematic workloads.

**Use When:**
- Troubleshooting CrashLoopBackOff
- Identifying resource issues
- Investigating OOMKilled containers

**Example:**
```bash
# Basic analysis
./pod-restart-analyzer.sh -n production -m 5

# Detailed debugging with logs
./pod-restart-analyzer.sh --debug
```

**Detects:**
- OOMKilled containers
- CrashLoopBackOff states
- Resource misconfiguration
- Recent events and logs

---

## Security

### [cert-monitor.sh](../security/cert-monitor.sh)
Monitor SSL/TLS certificates for expiry across services.

**Use When:**
- Preventing certificate expiry incidents
- Compliance auditing
- Regular security checks

**Example:**
```bash
# Check single host
./cert-monitor.sh -h example.com

# Check multiple hosts from file
./cert-monitor.sh -f production-hosts.txt -w 60 -c 14
```

---

## General Tips

1. **Always test in non-production first**
2. **Use dry-run mode for destructive operations**
3. **Check script help with `--help` flag**
4. **Review logs in `/tmp/` for debugging**
5. **Customize thresholds for your environment**

---

## Contributing

Found a bug or have an improvement? Submit a PR!

Each script should:
- Include comprehensive help text
- Have error handling
- Support dry-run mode
- Produce clear output
- Be well-commented
