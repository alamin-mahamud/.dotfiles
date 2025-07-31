# Cloud-Native Tooling Specifications

## Overview
Comprehensive cloud-native tooling setup for multi-cloud DevOps operations, targeting enterprise-scale infrastructure management and AI/ML workload deployment.

## Multi-Cloud CLI Tools

### AWS Ecosystem
```bash
# Core AWS tools
- aws-cli v2 (latest)
- aws-vault (credential management)
- eksctl (EKS cluster management)
- aws-cdk (Infrastructure as Code)
- copilot-cli (container deployment)

# Specialized tools
- chamber (parameter store secrets)
- aws-nuke (resource cleanup)
- steampipe (AWS security scanning)
- sso-util (SSO credential helper)
```

### Google Cloud Platform
```bash
# Core GCP tools
- gcloud SDK (latest)
- kubectl (GKE integration)
- terraform-google-modules
- cloud-sql-proxy
- gsutil (storage operations)

# Specialized tools
- skaffold (k8s development)
- anthos-cli (hybrid cloud)
- cloud-build-local (local builds)
```

### Microsoft Azure
```bash
# Core Azure tools
- az-cli (latest)
- azure-functions-core-tools
- bicep (ARM template authoring)
- kubelogin (AAD integration)

# Specialized tools
- azure-devops-cli-extension
- aztfexport (resource import)
```

## Kubernetes Ecosystem

### Core Tools
```yaml
tools:
  kubectl:
    version: "latest"
    plugins:
      - kubectl-neat
      - kubectl-tree
      - kubectl-who-can
      - kubectl-cost
      - kubectl-images
  
  helm:
    version: "v3.latest"
    plugins:
      - helm-diff
      - helm-secrets
      - helm-unittest
  
  kustomize:
    version: "latest"
    
  k9s:
    version: "latest"
    config: "vim-style-navigation"
```

### Specialized Kubernetes Tools
```bash
# Cluster management
- cluster-api-cli (CAPI)
- velero (backup/restore)
- sealed-secrets (secret encryption)
- external-secrets (secret management)

# Development workflow
- telepresence (local development)
- draft (application scaffolding)
- devspace (development workflow)
- tilt (local k8s development)

# Security & compliance
- falco (runtime security)
- polaris (best practices validation)
- kubesec (security scanning)
- kube-hunter (penetration testing)

# Observability
- stern (log tailing)
- kubetail (multi-pod logging)
- kail (kubernetes log viewer)
```

## Infrastructure as Code

### Terraform Ecosystem
```yaml
terraform:
  version: "latest"
  providers:
    - aws: "~> 5.0"
    - google: "~> 4.0" 
    - azurerm: "~> 3.0"
    - kubernetes: "~> 2.0"
    - helm: "~> 2.0"
  
  tools:
    - terragrunt: "latest"     # DRY configurations
    - terratest: "latest"      # Infrastructure testing
    - terraform-docs: "latest" # Documentation generation
    - tflint: "latest"         # Linting
    - checkov: "latest"        # Security scanning
    - infracost: "latest"      # Cost estimation
    - atlantis: "latest"       # PR automation
```

### Ansible Integration
```yaml
ansible:
  version: "latest"
  collections:
    - community.general
    - ansible.posix
    - kubernetes.core
    - amazon.aws
    - google.cloud
    - azure.azcollection
  
  tools:
    - ansible-lint: "latest"
    - molecule: "latest"       # Testing framework
    - ansible-vault: "built-in"
```

## Container & Registry Tools

### Container Management
```bash
# Container runtimes
- docker (latest)
- podman (alternative runtime)
- buildah (image building)
- skopeo (image operations)

# Registry operations
- crane (google container registry)
- docker-credential-helpers
- registry-cli (private registry management)

# Image security
- trivy (vulnerability scanning)
- grype (vulnerability scanner)
- syft (SBOM generation)
- cosign (container signing)
```

## Service Mesh & API Gateway

### Service Mesh
```yaml
service_mesh:
  istio:
    version: "latest"
    tools:
      - istioctl
      - kiali (observability)
      - jaeger (tracing)
  
  linkerd:
    version: "stable"
    tools:
      - linkerd-cli
      - linkerd-viz
  
  consul_connect:
    version: "latest"
    tools:
      - consul
      - consul-k8s
```

### API Management
```bash
# API gateways
- kong (API gateway)
- ambassador (kubernetes-native)
- contour (ingress controller)
- traefik (reverse proxy)

# API tools
- postman-cli (API testing)
- insomnia-cli (API client)
- openapi-generator (client generation)
```

## GitOps & CI/CD

### GitOps Tools
```yaml
gitops:
  argocd:
    version: "latest"
    cli: "argocd"
  
  flux:
    version: "v2"
    cli: "flux"
  
  tekton:
    version: "latest"
    cli: "tkn"
```

### CI/CD Integration
```bash
# GitHub Actions
- gh (GitHub CLI)
- act (local GitHub Actions)
- actionlint (Actions linting)

# GitLab
- glab (GitLab CLI)
- gitlab-runner (self-hosted)

# Jenkins
- jenkins-cli
- blue-ocean-cli
```

## Security & Compliance

### Security Scanning
```yaml
security_tools:
  vulnerability_scanning:
    - trivy
    - grype
    - clair-scanner
    - anchore-cli
  
  configuration_scanning:
    - checkov
    - kics
    - terrascan
    - tfsec
  
  secrets_detection:
    - gitleaks
    - truffleHog
    - detect-secrets
  
  compliance:
    - inspec
    - kitchen-terraform
    - compliance-masonry
```

### Certificate Management
```bash
# Certificate tools
- cert-manager-cli
- cfssl (certificate authority)
- mkcert (local development)
- acme.sh (Let's Encrypt)
```

## Network & DNS Tools

### Network Utilities
```bash
# Network diagnosis
- dig (DNS lookup)
- nslookup (name resolution)
- netstat (network connections)
- ss (socket statistics)
- tcpdump (packet capture)
- wireshark-cli (packet analysis)

# Load testing
- hey (HTTP load testing)
- wrk (HTTP benchmarking)
- k6 (load testing)
```

### DNS Management
```bash
# DNS tools
- cloudflare-cli
- route53-cli
- external-dns (k8s integration)
```

## Installation Strategy

### Phased Rollout
1. **Phase 1**: Core tools (kubectl, docker, terraform)
2. **Phase 2**: Cloud provider CLIs
3. **Phase 3**: Specialized tools based on profile
4. **Phase 4**: Security and compliance tools

### Verification Scripts
```bash
# Tool verification template
verify_tool() {
    local tool=$1
    local expected_version=$2
    
    if command -v "$tool" &> /dev/null; then
        local version=$(get_version "$tool")
        echo "✓ $tool: $version"
        return 0
    else
        echo "✗ $tool: not installed"
        return 1
    fi
}
```

### Profile-Specific Configurations
- **Minimal Server**: kubectl, docker, aws-cli, terraform
- **DevOps Workstation**: Full multi-cloud toolkit
- **AI/ML Engineer**: Core + GPU tools + model serving
- **Security Engineer**: Security scanning + compliance tools