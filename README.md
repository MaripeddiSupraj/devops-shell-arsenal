# DevOps Shell Arsenal 🛡️

> Production-grade shell scripts and advanced command usage for DevOps and Cloud Engineers

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Why This Repository?

This isn't another basic shell scripting tutorial. This is a **battle-tested arsenal** of scripts and techniques that solve real production problems. Every example here comes from actual DevOps scenarios - no "hello world" fluff.

### What Makes This Different:
- ✅ **Production-Ready**: All scripts include error handling, logging, and safety checks
- ✅ **Real-World Scenarios**: Solutions to actual problems, not contrived examples
- ✅ **Advanced Techniques**: Deep dives into powerful command combinations
- ✅ **Copy-Paste Ready**: Fully documented, ready to use immediately
- ✅ **Cloud-Native**: AWS, GCP, Azure CLI automation and best practices
- ✅ **Performance-Focused**: Optimized for speed and efficiency

## 🎯 Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/devops-shell-arsenal.git
cd devops-shell-arsenal

# Browse examples by category
ls examples/

# Read advanced command guides
ls docs/advanced-commands/
```

## 📚 Repository Structure

```
devops-shell-arsenal/
├── docs/
│   ├── advanced-commands/        # Linux command mastery
│   │   ├── awk-mastery.md       # AWK data processing
│   │   ├── sed-advanced.md      # Text transformations
│   │   ├── jq-json-kung-fu.md   # JSON manipulation
│   │   ├── grep-performance.md   # GREP & ripgrep
│   │   ├── find-xargs-power.md  # Parallel processing
│   │   ├── systemctl-journalctl.md  # Service management
│   │   ├── ssh-networking.md    # SSH tunneling & networking
│   │   └── docker-commands.md   # Container operations
│   ├── cloud-guides/            # Cloud CLI mastery
│   │   ├── aws/                 # AWS CLI patterns
│   │   └── gcp/                 # GCP gcloud patterns
│   └── best-practices.md
├── examples/
│   ├── cloud-automation/        # Cloud-specific scripts
│   │   ├── aws/                 # AWS automation
│   │   │   ├── cost-optimization/
│   │   │   ├── security/
│   │   │   └── automation/
│   │   ├── gcp/                 # GCP automation
│   │   │   ├── cost-optimization/
│   │   │   ├── security/
│   │   │   └── automation/
│   │   └── azure/               # Azure automation
│   │       ├── cost-optimization/
│   │       ├── security/
│   │       └── backup/
│   ├── log-analysis/            # Log parsing & analysis
│   ├── kubernetes/              # K8s utilities
│   ├── security/                # Security tools
│   └── ...
└── templates/                   # Script templates
```

## 🚀 Featured Content

### Log Analysis Scripts
- **[Error Spike Detector](examples/log-analysis/error-spike-detector.sh)** - Real-time 5xx error rate monitoring
- **[Multi-Service Correlator](examples/log-analysis/multi-service-correlator.sh)** - Correlate logs across microservices by trace ID

### AWS Automation
- **[Unused Resources](examples/cloud-automation/aws/cost-optimization/aws-unused-resources.sh)** - Find and delete unused AWS resources
- **[Security Audit](examples/cloud-automation/aws/security/aws-security-audit.sh)** - Comprehensive security checks (S3, EC2, IAM, RDS)
- **[Snapshot Cleanup](examples/cloud-automation/aws/cost-optimization/snapshot-cleanup.sh)** - Clean up old EBS snapshots
- **[Instance Scheduler](examples/cloud-automation/aws/automation/instance-scheduler.sh)** - Auto start/stop instances by tags

### GCP Automation
- **[Unused Disks](examples/cloud-automation/gcp/cost-optimization/unused-disks.sh)** - Find and delete unattached persistent disks
- **[Firewall Audit](examples/cloud-automation/gcp/security/firewall-audit.sh)** - Audit firewall rules for security issues
- **[GKE Autoscale](examples/cloud-automation/gcp/automation/gke-autoscale.sh)** - Configure GKE node pool autoscaling

### Azure Automation
- **[Unused Resources](examples/cloud-automation/azure/cost-optimization/unused-resources.sh)** - Find unused Azure resources (disks, IPs, NSGs)
- **[NSG Audit](examples/cloud-automation/azure/security/nsg-audit.sh)** - Audit network security groups
- **[VM Backup](examples/cloud-automation/azure/backup/vm-backup.sh)** - Automated VM backups

### Kubernetes
- **[Pod Restart Analyzer](examples/kubernetes/pod-restart-analyzer.sh)** - Identify patterns in pod restarts and troubleshoot issues

### Security
- **[Certificate Monitor](examples/security/cert-monitor.sh)** - Monitor SSL certificate expiry across services

## 📖 Linux Command Mastery Guides

Essential command guides for DevOps engineers:

- **[AWK Mastery](docs/advanced-commands/awk-mastery.md)** - Data processing, log analysis, custom reports
- **[SED Advanced](docs/advanced-commands/sed-advanced.md)** - Text transformations, config automation
- **[JQ JSON Kung Fu](docs/advanced-commands/jq-json-kung-fu.md)** - JSON manipulation, cloud CLI parsing
- **[GREP Performance](docs/advanced-commands/grep-performance.md)** - Fast log searching with grep/ripgrep  
- **[Find + Xargs Power](docs/advanced-commands/find-xargs-power.md)** - Parallel processing, bulk operations
- **[systemctl & journalctl](docs/advanced-commands/systemctl-journalctl.md)** - Service management, log querying
- **[SSH & Networking](docs/advanced-commands/ssh-networking.md)** - Tunneling, ProxyJump, troubleshooting
- **[Docker Commands](docs/advanced-commands/docker-commands.md)** - Container operations, production patterns

## ☁️ Cloud CLI Guides

- **[AWS CLI Mastery](docs/cloud-guides/aws/aws-cli-mastery.md)** - Production AWS patterns
- **[GCP gcloud Mastery](docs/cloud-guides/gcp/gcloud-mastery.md)** - Google Cloud operations

## 🎓 Learning Path

**Beginner → Intermediate:**
1. Start with `docs/best-practices.md`
2. Explore `examples/log-analysis/` for practical scenarios
3. Study `docs/advanced-commands/` to level up

**Intermediate → Advanced:**
1. Dive into `examples/cloud-automation/` and `examples/kubernetes/`
2. Master advanced commands with `jq`, `awk`, and `sed` guides
3. Build your own utilities using `templates/`

**Advanced → Expert:**
1. Study `examples/performance/` and `examples/security/`
2. Contribute your own production scripts
3. Optimize and customize scripts for your environment

## 🔧 Prerequisites

Most scripts require standard Unix tools. Specific examples may need:

- **Cloud CLIs**: `aws-cli`, `gcloud`, `az`
- **Container Tools**: `kubectl`, `docker`
- **JSON Processing**: `jq`
- **Modern Tools**: `ripgrep`, `fd`, `bat` (optional but recommended)

## 💡 Usage Guidelines

Every script follows this structure:

```bash
#!/bin/bash
# Script Name: example-script.sh
# Description: What this script does
# Usage: ./example-script.sh [options]
# Author: Your Name
# Dependencies: list of required tools

# Safety first
set -euo pipefail

# Your code here...
```

**Key Features:**
- Error handling with `set -euo pipefail`
- Dry-run mode for destructive operations
- Logging to both stdout and files
- Input validation and safety checks
- Clear usage messages and help text

## 🛡️ Safety First

All destructive scripts include:
- ✅ Dry-run mode (`--dry-run` flag)
- ✅ Confirmation prompts
- ✅ Logging of all actions
- ✅ Rollback mechanisms where applicable

**Always test in a non-production environment first!**

## 🤝 Contributing

Have a production script that saved your day? Share it!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-script`)
3. Add your script with comprehensive documentation
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 📝 Script Template

Use our [production script template](templates/production-script-template.sh) to create your own scripts with built-in best practices.

## 🌟 Use Cases

This repository is perfect for:
- **DevOps Engineers** automating infrastructure tasks
- **SREs** troubleshooting production issues
- **Cloud Engineers** managing multi-cloud environments
- **Platform Engineers** building self-service tooling
- **Security Engineers** automating compliance checks

## 📚 Additional Resources

- [ShellCheck](https://www.shellcheck.net/) - Shell script linter
- [Bash Pitfalls](https://mywiki.wooledge.org/BashPitfalls) - Common mistakes
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

## 📄 License

MIT License - see [LICENSE](LICENSE) for details

## 🙏 Acknowledgments

Built by DevOps engineers, for DevOps engineers. Special thanks to the community for sharing their battle-tested scripts.

---

**⭐ If this repository helped you solve a production issue, please star it!**

**Questions or suggestions?** Open an issue or start a discussion.
