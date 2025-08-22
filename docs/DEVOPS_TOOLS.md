# DevOps Tools

## Installed Tools

### Container & Orchestration
- **Docker**: Latest from official repository
- **Docker Compose**: v2 standalone binary
- **kubectl**: Kubernetes CLI (latest stable)
- **helm**: Kubernetes package manager

### Infrastructure as Code
- **Terraform**: HashiCorp official binary
- **OpenTofu**: Open source Terraform fork
- **Terragrunt**: Terraform wrapper

### Cloud CLIs
- **AWS CLI**: v2 latest
- **Azure CLI**: Latest
- **Google Cloud CLI**: Latest

### Monitoring & Observability
- **Prometheus**: Binary installation
- **Grafana CLI**: Official binary

## Installation

```bash
# All tools
./scripts/components/devops-tools.sh

# Specific categories
./scripts/components/devops-tools.sh --containers-only
./scripts/components/devops-tools.sh --iac-only
./scripts/components/devops-tools.sh --cloud-only
```