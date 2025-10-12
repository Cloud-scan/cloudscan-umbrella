# CloudScan - Open Source Security Scanning Platform

> **Self-hosted, enterprise-grade security and code quality scanning platform**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Go Version](https://img.shields.io/badge/Go-1.23+-00ADD8?logo=go)](https://golang.org)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5?logo=kubernetes)](https://kubernetes.io)

---

## 🌟 What is CloudScan?

CloudScan is a **free, open-source alternative** to expensive commercial security scanning tools (SonarQube Enterprise, Snyk, Checkmarx). It provides:

- ✅ **Multiple scan types**: SAST, SCA, Secrets Detection, License Compliance
- ✅ **Beautiful web UI** with real-time progress updates
- ✅ **Self-hosted** on your Kubernetes cluster (full data privacy)
- ✅ **Multi-tenant** architecture for organizations
- ✅ **Easy deployment** via Helm chart (5-minute setup)
- ✅ **Extensible** plugin architecture for custom scanners

**Cost Comparison:**
- SonarQube Enterprise: $150,000+/year
- Snyk Enterprise: $50,000+/year
- Checkmarx: $100,000+/year
- **CloudScan: FREE** ✨

---

## 🏗️ Architecture

CloudScan is built as a distributed microservices platform:

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  React UI   │────▶│  API Gateway     │────▶│  Orchestrator   │
└─────────────┘     └──────────────────┘     └────────┬────────┘
                                                      │
                    ┌─────────────────────────────────┼─────────┐
                    │                                 │         │
                    ▼                                 ▼         ▼
            ┌───────────────┐              ┌──────────────┐   ┌──────┐
            │    Storage    │              │  WebSocket   │   │ K8s  │
            │    Service    │              │   Service    │   │ Jobs │
            └───────────────┘              └──────────────┘   └───┬──┘
                                                                   │
                                                                   ▼
                                                          ┌────────────────┐
                                                          │ Scanner Runners│
                                                          │ (Semgrep, etc) │
                                                          └────────────────┘
```

**Services:**
- **cloudscan-ui**: React frontend with real-time updates
- **cloudscan-api-gateway**: HTTP gateway with authentication
- **cloudscan-orchestrator**: Core service (job management, K8s dispatcher)
- **cloudscan-storage**: Multi-cloud storage abstraction (S3/GCS/Azure)
- **cloudscan-websocket**: Real-time log streaming
- **cloudscan-runner**: Scanner executors (runs in K8s Jobs)

---

## 🚀 Quick Start

### Prerequisites
- Kubernetes cluster (v1.28+)
- Helm 3.x
- kubectl configured

### Installation

```bash
# Add Helm repository
helm repo add cloudscan https://charts.cloudscan.dev
helm repo update

# Install CloudScan
helm install cloudscan cloudscan/cloudscan \
  --namespace cloudscan \
  --create-namespace \
  --set postgresql.enabled=true \
  --set storage.type=s3 \
  --set storage.s3.bucket=my-scans-bucket \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=cloudscan.mycompany.com
```

### Access the UI

Navigate to: `https://cloudscan.mycompany.com`

Create your account and start scanning! 🎉

---

## 📖 Documentation

- [Installation Guide](docs/installation.md)
- [Configuration](docs/configuration.md)
- [User Guide](docs/user-guide.md)
- [API Documentation](docs/api.md)
- [Architecture](docs/architecture.md)
- [Contributing](CONTRIBUTING.md)

---

## 🔧 Development

### Repository Structure

```
cloudscan/
├── cloudscan-orchestrator/    # Core orchestration service (Go)
├── cloudscan-ui/              # React frontend
├── cloudscan-storage/         # Storage service (Go)
├── cloudscan-api-gateway/     # API gateway (Go)
├── cloudscan-websocket/       # WebSocket service (Go)
├── cloudscan-runner/          # Scanner runner (Go)
├── protobuf/                  # Shared protobuf definitions
├── shared/                    # Shared Go libraries
├── charts/                    # Helm charts
├── docs/                      # Documentation
└── scripts/                   # Build and deployment scripts
```

### Local Development

See individual service READMEs for development setup:
- [cloudscan-orchestrator/README.md](cloudscan-orchestrator/README.md)
- [cloudscan-ui/README.md](cloudscan-ui/README.md)
- [cloudscan-storage/README.md](cloudscan-storage/README.md)

---

## 🧪 Scanners Included

| Type | Tool | What it Scans |
|------|------|---------------|
| **SAST** | Semgrep | Security vulnerabilities in code (SQL injection, XSS, etc.) |
| **SCA** | Trivy | Vulnerable dependencies (CVEs in npm, pip, maven, etc.) |
| **Secrets** | TruffleHog | API keys, passwords, tokens leaked in code |
| **License** | ScanCode | Open-source license compliance |

---

## 🎯 Use Cases

- **Startups**: Free alternative to expensive commercial tools
- **Enterprises**: Self-hosted solution for compliance (GDPR, HIPAA, SOC2)
- **Open Source Projects**: Public scanning with badges
- **Educational**: Teaching secure coding practices

---

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Ways to contribute:**
- 🐛 Report bugs
- 💡 Suggest features
- 📝 Improve documentation
- 🔧 Submit pull requests
- 🌟 Star the repo!

---

## 📄 License

Apache 2.0 - see [LICENSE](LICENSE)

---

## 🙏 Acknowledgments

CloudScan leverages these amazing open-source tools:
- [Semgrep](https://github.com/returntocorp/semgrep)
- [Trivy](https://github.com/aquasecurity/trivy)
- [TruffleHog](https://github.com/trufflesecurity/trufflehog)
- [ScanCode Toolkit](https://github.com/nexB/scancode-toolkit)

---

## 📧 Support

- **Documentation**: https://docs.cloudscan.dev
- **Community Discord**: https://discord.gg/cloudscan
- **GitHub Issues**: https://github.com/cloudscan/cloudscan/issues
- **Email**: support@cloudscan.dev

---

**Made with ❤️ by developers, for developers**