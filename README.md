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
│   ├── advanced-commands/        # Master powerful commands
│   │   ├── awk-mastery.md       # AWK for data processing
│   │   ├── sed-advanced.md      # Advanced text transformations
│   │   ├── jq-json-kung-fu.md   # JSON manipulation mastery
│   │   ├── grep-performance.md   # High-performance searching
│   │   └── find-xargs-power.md  # Parallel processing patterns
│   └── best-practices.md
├── examples/
│   ├── log-analysis/             # Production log analysis
│   ├── cloud-automation/         # AWS, GCP, Azure automation
│   ├── kubernetes/               # kubectl and k8s utilities
│   ├── cicd/                     # CI/CD pipeline helpers
│   ├── monitoring/               # Metrics and alerting
│   ├── security/                 # Security scanning & compliance
│   ├── performance/              # Performance troubleshooting
│   ├── backup-recovery/          # Backup & DR automation
│   └── incident-response/        # On-call utilities
└── templates/                    # Reusable script templates
```

## 🚀 Featured Examples

### Log Analysis
- **[Error Spike Detector](examples/log-analysis/error-spike-detector.sh)** - Real-time 5xx error rate monitoring
- **[Multi-Service Correlator](examples/log-analysis/multi-service-correlator.sh)** - Correlate logs across microservices by trace ID
- **[Slow Query Analyzer](examples/log-analysis/slow-query-analyzer.sh)** - Parse and rank slow database queries

### Cloud Automation
- **[Unused Resource Cleaner](examples/cloud-automation/aws-unused-resources.sh)** - Find and delete unused AWS resources
- **[Cost Anomaly Detector](examples/cloud-automation/cost-anomaly-detector.sh)** - Alert on unusual cloud spending
- **[Cross-Account Resource Inventory](examples/cloud-automation/aws-cross-account-inventory.sh)** - Inventory resources across all accounts

### Kubernetes
- **[Pod Restart Analyzer](examples/kubernetes/pod-restart-analyzer.sh)** - Identify patterns in pod restarts
- **[Resource Right-Sizer](examples/kubernetes/resource-right-sizer.sh)** - Suggest optimal resource requests based on usage
- **[CrashLoopBackOff Debugger](examples/kubernetes/crashloop-debugger.sh)** - Automated CrashLoopBackOff troubleshooting

### CI/CD
- **[Blue-Green Deployment](examples/cicd/blue-green-deploy.sh)** - Automated blue-green deployment script
- **[Canary Monitor](examples/cicd/canary-monitor.sh)** - Monitor canary deployment metrics
- **[Artifact Promoter](examples/cicd/artifact-promoter.sh)** - Multi-environment artifact promotion

### Security
- **[Secret Scanner](examples/security/secret-scanner.sh)** - Scan for exposed secrets in logs and configs
- **[Certificate Monitor](examples/security/cert-monitor.sh)** - Monitor SSL certificate expiry across services
- **[Security Group Auditor](examples/security/sg-auditor.sh)** - Audit AWS security groups for overly permissive rules

### Performance
- **[Resource Hog Hunter](examples/performance/resource-hog-hunter.sh)** - Identify top CPU/memory consumers
- **[Disk I/O Analyzer](examples/performance/disk-io-analyzer.sh)** - Detect disk I/O bottlenecks
- **[Network Troubleshooter](examples/performance/network-troubleshooter.sh)** - Comprehensive network connectivity testing

## 📖 Advanced Command Mastery

Deep dives into the most powerful shell commands:

- **[AWK Mastery](docs/advanced-commands/awk-mastery.md)** - Multi-file processing, custom reports, data transformation
- **[SED Advanced](docs/advanced-commands/sed-advanced.md)** - Complex text transformations, in-place editing at scale
- **[JQ JSON Kung Fu](docs/advanced-commands/jq-json-kung-fu.md)** - Advanced JSON manipulation, API response parsing
- **[GREP Performance](docs/advanced-commands/grep-performance.md)** - Performance-optimized searching techniques
- **[Find + Xargs Power](docs/advanced-commands/find-xargs-power.md)** - Parallel processing patterns

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
