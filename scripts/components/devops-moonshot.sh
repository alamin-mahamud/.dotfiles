#!/usr/bin/env bash

# MOONSHOT: DevOps Tools Ultra-Stack
# Complete K8s, Monitoring, and Cloud-Native toolkit for 10x engineers
# Prometheus/Grafana ready, multi-cloud, production-grade

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/package-managers.sh"

# Initialize environment
setup_environment

# Parse command line arguments
INSTALL_ALL=true
CONTAINERS_ONLY=false
IAC_ONLY=false
CLOUD_ONLY=false
MONITORING_ONLY=false
SECURITY_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --containers-only)
            INSTALL_ALL=false; CONTAINERS_ONLY=true; shift ;;
        --iac-only)
            INSTALL_ALL=false; IAC_ONLY=true; shift ;;
        --cloud-only)
            INSTALL_ALL=false; CLOUD_ONLY=true; shift ;;
        --monitoring-only)
            INSTALL_ALL=false; MONITORING_ONLY=true; shift ;;
        --security-only)
            INSTALL_ALL=false; SECURITY_ONLY=true; shift ;;
        *)
            error "Unknown option: $1"; exit 1 ;;
    esac
done

install_container_orchestration_stack() {
    print_header "Installing Container & Orchestration Ultra-Stack"
    
    # Docker with BuildKit optimizations
    install_docker_moonshot
    
    # Podman as Docker alternative
    install_podman
    
    # Docker Compose with profiles support
    install_docker_compose_moonshot
    
    # Kubernetes tools ecosystem
    install_kubernetes_ecosystem
    
    # Service mesh tools
    install_service_mesh_tools
    
    # Container security tools
    install_container_security
}

install_docker_moonshot() {
    info "Installing Docker with MOONSHOT optimizations..."
    
    case "${DOTFILES_OS}" in
        linux)
            # Remove old versions
            sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
            
            # Install dependencies
            install_packages ca-certificates curl gnupg lsb-release
            
            # Add Docker repository with BuildKit support
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            
            # Configure Docker for performance
            sudo mkdir -p /etc/docker
            cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "features": {
        "buildkit": true
    },
    "experimental": true,
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ],
    "dns": ["8.8.8.8", "8.8.4.4"],
    "registry-mirrors": [],
    "insecure-registries": [],
    "default-address-pools": [
        {
            "base": "172.30.0.0/16",
            "size": 24
        }
    ]
}
EOF
            
            # Add user to docker group
            sudo usermod -aG docker "$USER"
            
            # Enable and configure Docker service
            sudo systemctl enable docker
            sudo systemctl enable containerd
            sudo systemctl start docker
            sudo systemctl start containerd
            
            # Enable Docker BuildKit globally
            echo 'export DOCKER_BUILDKIT=1' >> ~/.zshrc
            echo 'export COMPOSE_DOCKER_CLI_BUILD=1' >> ~/.zshrc
            ;;
            
        macos)
            if [[ ! -d "/Applications/Docker.app" ]]; then
                if command_exists brew; then
                    brew install --cask docker
                else
                    warning "Please install Docker Desktop from https://docker.com"
                    return 1
                fi
            fi
            ;;
    esac
    
    success "Docker with MOONSHOT optimizations installed"
}

install_podman() {
    info "Installing Podman as Docker alternative..."
    
    case "${DOTFILES_OS}" in
        linux)
            case "$(detect_package_manager)" in
                apt)
                    install_packages podman buildah skopeo || true
                    ;;
                pacman)
                    install_packages podman buildah skopeo || true
                    ;;
            esac
            
            # Configure Podman
            mkdir -p ~/.config/containers
            cat > ~/.config/containers/containers.conf <<'EOF'
[containers]
default_sysctls = []
dns_servers = ["8.8.8.8", "8.8.4.4"]

[engine]
cgroup_manager = "systemd"
events_logger = "journald"
runtime = "crun"

[machine]
cpus = 2
disk_size = 20
memory = 2048
EOF
            
            # Enable Podman socket for Docker compatibility
            systemctl --user enable --now podman.socket
            echo 'export DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock' >> ~/.zshrc
            ;;
    esac
    
    success "Podman installed"
}

install_docker_compose_moonshot() {
    info "Installing Docker Compose with advanced features..."
    
    # Get latest version
    local compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    
    case "${DOTFILES_OS}" in
        linux)
            local arch=$(detect_arch)
            curl -L "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-linux-${arch}" -o /tmp/docker-compose
            sudo mv /tmp/docker-compose /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            
            # Install Docker Compose Switch for v1 compatibility
            sudo curl -fL https://raw.githubusercontent.com/docker/compose-switch/master/install.sh | sh
            ;;
    esac
    
    # Create useful Docker Compose templates
    mkdir -p "$HOME/docker-templates"
    
    # Full-stack development template
    cat > "$HOME/docker-templates/fullstack-dev.yml" <<'EOF'
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - backend
      - frontend

  frontend:
    build: ./frontend
    environment:
      - NODE_ENV=development
    volumes:
      - ./frontend:/app
      - /app/node_modules

  backend:
    build: ./backend
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/app
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis
    volumes:
      - ./backend:/app

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=app
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgres-init:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
EOF

    # Monitoring stack template
    cat > "$HOME/docker-templates/monitoring-stack.yml" <<'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus
      - prometheus_data:/prometheus

  grafana:
    image: grafana/grafana:latest
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning

  node-exporter:
    image: prom/node-exporter:latest
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    restart: unless-stopped
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro

volumes:
  prometheus_data:
  grafana_data:
EOF

    success "Docker Compose with templates installed"
}

install_kubernetes_ecosystem() {
    info "Installing Kubernetes ecosystem..."
    
    # Core Kubernetes tools
    install_kubectl_moonshot
    install_helm_moonshot
    install_k9s_moonshot
    
    # Advanced Kubernetes tools
    install_kustomize
    install_kubectx_kubens
    install_stern
    install_krew
    install_kube_score
    install_kubernetes_dashboard
    install_argo_cli
    install_flux_cli
}

install_kubectl_moonshot() {
    info "Installing kubectl with optimizations..."
    
    if command_exists kubectl; then
        local version=$(kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion' 2>/dev/null || echo "unknown")
        info "kubectl $version already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux)
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo mv kubectl /usr/local/bin/kubectl
            sudo chmod +x /usr/local/bin/kubectl
            ;;
        macos)
            if command_exists brew; then
                brew install kubectl
            fi
            ;;
    esac
    
    # Enable kubectl completion
    echo 'source <(kubectl completion zsh)' >> ~/.zshrc
    echo 'alias k=kubectl' >> ~/.zshrc
    echo 'compdef __start_kubectl k' >> ~/.zshrc
    
    # Create useful kubectl aliases
    cat >> ~/.zshrc <<'EOF'

# Kubectl aliases for productivity
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployment'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kdp='kubectl describe pod'
alias kds='kubectl describe svc'
alias kdd='kubectl describe deployment'
alias kdn='kubectl describe node'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias ke='kubectl edit'
alias kex='kubectl exec -it'
alias kdel='kubectl delete'
alias kpf='kubectl port-forward'
alias kctx='kubectl config current-context'
alias kns='kubectl config view --minify -o jsonpath="{..namespace}"'

# Advanced kubectl functions
klog() {
    kubectl logs -f $(kubectl get pods -o name | fzf | sed 's/pod\///')
}

kexec() {
    kubectl exec -it $(kubectl get pods -o name | fzf | sed 's/pod\///') -- /bin/bash
}

kdesc() {
    kubectl describe $(kubectl api-resources --verbs=list -o name | fzf) $(kubectl get $(kubectl api-resources --verbs=list -o name | fzf) -o name | fzf)
}
EOF
    
    success "kubectl with optimizations installed"
}

install_helm_moonshot() {
    info "Installing Helm with chart management..."
    
    if command_exists helm; then
        local version=$(helm version --template='{{.Version}}' 2>/dev/null)
        info "Helm $version already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux|macos)
            curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
            ;;
    esac
    
    # Add popular Helm repositories
    helm repo add stable https://charts.helm.sh/stable 2>/dev/null || true
    helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
    helm repo add jetstack https://charts.jetstack.io 2>/dev/null || true
    helm repo add nginx-stable https://helm.nginx.com/stable 2>/dev/null || true
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
    helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
    helm repo add hashicorp https://helm.releases.hashicorp.com 2>/dev/null || true
    helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
    helm repo update 2>/dev/null || true
    
    # Enable Helm completion
    echo 'source <(helm completion zsh)' >> ~/.zshrc
    
    success "Helm with repositories installed"
}

install_k9s_moonshot() {
    info "Installing k9s (Kubernetes TUI)..."
    
    if command_exists k9s; then
        info "k9s already installed"
        return 0
    fi
    
    local k9s_version=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    
    case "${DOTFILES_OS}" in
        linux)
            curl -Lo /tmp/k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${k9s_version}/k9s_Linux_amd64.tar.gz"
            tar xf /tmp/k9s.tar.gz -C /tmp k9s
            sudo mv /tmp/k9s /usr/local/bin
            rm /tmp/k9s.tar.gz
            ;;
        macos)
            if command_exists brew; then
                brew install derailed/k9s/k9s
            fi
            ;;
    esac
    
    # Configure k9s with custom skin
    mkdir -p ~/.config/k9s
    cat > ~/.config/k9s/skin.yml <<'EOF'
# Tokyo Night theme for k9s
k9s:
  body:
    fgColor: "#c0caf5"
    bgColor: "#1a1b26"
    logoColor: "#bb9af7"
  prompt:
    fgColor: "#c0caf5"
    bgColor: "#1a1b26"
    suggestColor: "#565f89"
  info:
    fgColor: "#73daca"
    sectionColor: "#c0caf5"
  dialog:
    fgColor: "#c0caf5"
    bgColor: "#1a1b26"
    buttonFgColor: "#1a1b26"
    buttonBgColor: "#7aa2f7"
    buttonFocusFgColor: "#1a1b26"
    buttonFocusBgColor: "#bb9af7"
    labelFgColor: "#c0caf5"
    fieldFgColor: "#c0caf5"
  frame:
    border:
      fgColor: "#414868"
      focusColor: "#7aa2f7"
    menu:
      fgColor: "#c0caf5"
      keyColor: "#bb9af7"
      numKeyColor: "#73daca"
    crumbs:
      fgColor: "#c0caf5"
      bgColor: "#1a1b26"
      activeColor: "#7aa2f7"
    status:
      newColor: "#73daca"
      modifyColor: "#7dcfff"
      addColor: "#9ece6a"
      errorColor: "#f7768e"
      highlightColor: "#e0af68"
      killColor: "#414868"
      completedColor: "#565f89"
    title:
      fgColor: "#c0caf5"
      bgColor: "#1a1b26"
      highlightColor: "#7aa2f7"
      counterColor: "#bb9af7"
      filterColor: "#73daca"
  views:
    charts:
      bgColor: default
      defaultDialColors:
        - "#7aa2f7"
        - "#7dcfff"
        - "#73daca"
        - "#9ece6a"
        - "#e0af68"
        - "#f7768e"
        - "#bb9af7"
      defaultChartColors:
        - "#7aa2f7"
        - "#7dcfff"
        - "#73daca"
        - "#9ece6a"
        - "#e0af68"
        - "#f7768e"
        - "#bb9af7"
    table:
      fgColor: "#c0caf5"
      bgColor: "#1a1b26"
      cursorColor: "#414868"
      header:
        fgColor: "#c0caf5"
        bgColor: "#1a1b26"
        sorterColor: "#7aa2f7"
    xray:
      fgColor: "#c0caf5"
      bgColor: "#1a1b26"
      cursorColor: "#414868"
      graphicColor: "#7aa2f7"
      showIcons: false
    yaml:
      keyColor: "#7aa2f7"
      colonColor: "#c0caf5"
      valueColor: "#9ece6a"
    logs:
      fgColor: "#c0caf5"
      bgColor: "#1a1b26"
      indicator:
        fgColor: "#73daca"
        bgColor: "#1a1b26"
EOF
    
    success "k9s with Tokyo Night theme installed"
}

install_kustomize() {
    info "Installing Kustomize..."
    
    if command_exists kustomize; then
        info "kustomize already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux)
            curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
            sudo mv kustomize /usr/local/bin/
            ;;
        macos)
            if command_exists brew; then
                brew install kustomize
            fi
            ;;
    esac
    
    success "Kustomize installed"
}

install_kubectx_kubens() {
    info "Installing kubectx and kubens..."
    
    case "${DOTFILES_OS}" in
        linux)
            local version=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
            
            # kubectx
            curl -Lo /tmp/kubectx.tar.gz "https://github.com/ahmetb/kubectx/releases/download/${version}/kubectx_${version}_linux_x86_64.tar.gz"
            tar xf /tmp/kubectx.tar.gz -C /tmp kubectx
            sudo mv /tmp/kubectx /usr/local/bin/
            
            # kubens
            curl -Lo /tmp/kubens.tar.gz "https://github.com/ahmetb/kubectx/releases/download/${version}/kubens_${version}_linux_x86_64.tar.gz"
            tar xf /tmp/kubens.tar.gz -C /tmp kubens
            sudo mv /tmp/kubens /usr/local/bin/
            
            rm /tmp/kubectx.tar.gz /tmp/kubens.tar.gz
            ;;
        macos)
            if command_exists brew; then
                brew install kubectx
            fi
            ;;
    esac
    
    # Add to zshrc
    echo 'alias kctx=kubectx' >> ~/.zshrc
    echo 'alias kns=kubens' >> ~/.zshrc
    
    success "kubectx and kubens installed"
}

install_stern() {
    info "Installing Stern (multi-pod log tailing)..."
    
    if command_exists stern; then
        info "stern already installed"
        return 0
    fi
    
    local version=$(curl -s https://api.github.com/repos/stern/stern/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    
    case "${DOTFILES_OS}" in
        linux)
            curl -Lo /tmp/stern.tar.gz "https://github.com/stern/stern/releases/download/${version}/stern_${version#v}_linux_amd64.tar.gz"
            tar xf /tmp/stern.tar.gz -C /tmp stern
            sudo mv /tmp/stern /usr/local/bin/
            rm /tmp/stern.tar.gz
            ;;
        macos)
            if command_exists brew; then
                brew install stern
            fi
            ;;
    esac
    
    success "Stern installed"
}

install_krew() {
    info "Installing Krew (kubectl plugin manager)..."
    
    if kubectl krew version >/dev/null 2>&1; then
        info "Krew already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux)
            curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz"
            tar zxvf krew-linux_amd64.tar.gz
            KREW=./krew-linux_amd64
            "$KREW" install krew
            rm krew-linux_amd64*
            ;;
        macos)
            curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-darwin_amd64.tar.gz"
            tar zxvf krew-darwin_amd64.tar.gz
            KREW=./krew-darwin_amd64
            "$KREW" install krew
            rm krew-darwin_amd64*
            ;;
    esac
    
    # Add krew to PATH
    echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.zshrc
    
    # Install useful kubectl plugins
    kubectl krew install ctx ns tree blame get-all whoami resource-capacity node-shell
    
    success "Krew with plugins installed"
}

install_kube_score() {
    info "Installing kube-score (Kubernetes manifest analysis)..."
    
    if command_exists kube-score; then
        info "kube-score already installed"
        return 0
    fi
    
    local version=$(curl -s https://api.github.com/repos/zegl/kube-score/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    
    case "${DOTFILES_OS}" in
        linux)
            curl -Lo /tmp/kube-score.tar.gz "https://github.com/zegl/kube-score/releases/download/${version}/kube-score_${version#v}_linux_amd64.tar.gz"
            tar xf /tmp/kube-score.tar.gz -C /tmp kube-score
            sudo mv /tmp/kube-score /usr/local/bin/
            rm /tmp/kube-score.tar.gz
            ;;
        macos)
            if command_exists brew; then
                brew install kube-score
            fi
            ;;
    esac
    
    success "kube-score installed"
}

install_kubernetes_dashboard() {
    info "Installing Kubernetes Dashboard..."
    
    # Create namespace and deployment script
    mkdir -p "$HOME/.local/bin"
    cat > "$HOME/.local/bin/k8s-dashboard" <<'EOF'
#!/bin/bash
# Kubernetes Dashboard installer/manager

set -e

NAMESPACE="kubernetes-dashboard"
DASHBOARD_VERSION="v2.7.0"

case "${1:-install}" in
    install)
        echo "Installing Kubernetes Dashboard..."
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml
        
        # Create admin user
        kubectl apply -f - <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
YAML
        
        echo "Dashboard installed! Use 'k8s-dashboard token' to get login token"
        echo "Use 'k8s-dashboard proxy' to start proxy"
        ;;
    
    token)
        kubectl -n kubernetes-dashboard create token admin-user
        ;;
    
    proxy)
        echo "Starting dashboard proxy at http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
        kubectl proxy
        ;;
    
    uninstall)
        kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml
        ;;
    
    *)
        echo "Usage: k8s-dashboard [install|token|proxy|uninstall]"
        exit 1
        ;;
esac
EOF
    chmod +x "$HOME/.local/bin/k8s-dashboard"
    
    success "Kubernetes Dashboard manager installed"
}

install_argo_cli() {
    info "Installing Argo CLI tools..."
    
    # ArgoCD CLI
    if ! command_exists argocd; then
        local version=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
        case "${DOTFILES_OS}" in
            linux)
                curl -sSL -o /tmp/argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/${version}/argocd-linux-amd64
                sudo mv /tmp/argocd-linux-amd64 /usr/local/bin/argocd
                sudo chmod +x /usr/local/bin/argocd
                ;;
        esac
    fi
    
    # Argo Workflows CLI
    if ! command_exists argo; then
        local version=$(curl -s https://api.github.com/repos/argoproj/argo-workflows/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
        case "${DOTFILES_OS}" in
            linux)
                curl -sLO https://github.com/argoproj/argo-workflows/releases/download/${version}/argo-linux-amd64.gz
                gunzip argo-linux-amd64.gz
                sudo mv argo-linux-amd64 /usr/local/bin/argo
                sudo chmod +x /usr/local/bin/argo
                ;;
        esac
    fi
    
    success "Argo CLI tools installed"
}

install_flux_cli() {
    info "Installing Flux CLI..."
    
    if command_exists flux; then
        info "Flux CLI already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux)
            curl -s https://fluxcd.io/install.sh | sudo bash
            ;;
        macos)
            if command_exists brew; then
                brew install fluxcd/tap/flux
            fi
            ;;
    esac
    
    # Enable Flux completion
    echo 'source <(flux completion zsh)' >> ~/.zshrc
    
    success "Flux CLI installed"
}

install_service_mesh_tools() {
    info "Installing Service Mesh tools..."
    
    # Istio
    install_istioctl
    
    # Linkerd
    install_linkerd_cli
    
    # Consul Connect
    install_consul_cli
}

install_istioctl() {
    info "Installing Istioctl..."
    
    if command_exists istioctl; then
        info "istioctl already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux|macos)
            curl -L https://istio.io/downloadIstio | sh -
            sudo mv istio-*/bin/istioctl /usr/local/bin/
            rm -rf istio-*
            ;;
    esac
    
    success "Istioctl installed"
}

install_linkerd_cli() {
    info "Installing Linkerd CLI..."
    
    if command_exists linkerd; then
        info "linkerd already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux|macos)
            curl -fsL https://run.linkerd.io/install | sh
            sudo mv ~/.linkerd2/bin/linkerd /usr/local/bin/
            rm -rf ~/.linkerd2
            ;;
    esac
    
    success "Linkerd CLI installed"
}

install_consul_cli() {
    info "Installing Consul CLI..."
    
    if command_exists consul; then
        info "consul already installed"
        return 0
    fi
    
    local version=$(curl -s https://api.github.com/repos/hashicorp/consul/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    
    case "${DOTFILES_OS}" in
        linux)
            curl -Lo /tmp/consul.zip "https://releases.hashicorp.com/consul/${version#v}/consul_${version#v}_linux_amd64.zip"
            unzip -q /tmp/consul.zip -d /tmp
            sudo mv /tmp/consul /usr/local/bin/
            rm /tmp/consul.zip
            ;;
        macos)
            if command_exists brew; then
                brew tap hashicorp/tap
                brew install hashicorp/tap/consul
            fi
            ;;
    esac
    
    success "Consul CLI installed"
}

install_container_security() {
    info "Installing container security tools..."
    
    # Trivy (vulnerability scanner)
    install_trivy
    
    # Grype (vulnerability scanner)
    install_grype
    
    # Syft (SBOM generator)
    install_syft
    
    # Cosign (container signing)
    install_cosign
    
    # Falco (runtime security)
    install_falco_cli
}

install_trivy() {
    info "Installing Trivy vulnerability scanner..."
    
    if command_exists trivy; then
        info "trivy already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux)
            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
            echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
            sudo apt-get update
            sudo apt-get install trivy
            ;;
        macos)
            if command_exists brew; then
                brew install aquasecurity/trivy/trivy
            fi
            ;;
    esac
    
    success "Trivy installed"
}

install_grype() {
    info "Installing Grype vulnerability scanner..."
    
    if command_exists grype; then
        info "grype already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux|macos)
            curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
            ;;
    esac
    
    success "Grype installed"
}

install_syft() {
    info "Installing Syft SBOM generator..."
    
    if command_exists syft; then
        info "syft already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux|macos)
            curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
            ;;
    esac
    
    success "Syft installed"
}

install_cosign() {
    info "Installing Cosign container signing tool..."
    
    if command_exists cosign; then
        info "cosign already installed"
        return 0
    fi
    
    local version=$(curl -s https://api.github.com/repos/sigstore/cosign/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    
    case "${DOTFILES_OS}" in
        linux)
            curl -Lo /tmp/cosign "https://github.com/sigstore/cosign/releases/download/${version}/cosign-linux-amd64"
            sudo mv /tmp/cosign /usr/local/bin/cosign
            sudo chmod +x /usr/local/bin/cosign
            ;;
        macos)
            if command_exists brew; then
                brew install cosign
            fi
            ;;
    esac
    
    success "Cosign installed"
}

install_falco_cli() {
    info "Installing Falco CLI..."
    
    if command_exists falcoctl; then
        info "falcoctl already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux|macos)
            curl -s https://falco.org/script/install | bash
            ;;
    esac
    
    success "Falco CLI installed"
}

install_infrastructure_as_code_stack() {
    print_header "Installing Infrastructure as Code Ultra-Stack"
    
    # Core IaC tools
    install_terraform_moonshot
    install_opentofu_moonshot
    install_terragrunt_moonshot
    install_terraform_docs
    install_tflint_moonshot
    install_checkov
    
    # Pulumi
    install_pulumi
    
    # CDK tools
    install_cdk_tools
    
    # Configuration management
    install_ansible_moonshot
}

install_terraform_moonshot() {
    info "Installing Terraform with optimizations..."
    
    if command_exists terraform; then
        local version=$(terraform version | head -1 | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+')
        info "Terraform $version already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux)
            # Add HashiCorp repository
            curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
            sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
            sudo apt-get update && sudo apt-get install terraform
            ;;
        macos)
            if command_exists brew; then
                brew tap hashicorp/tap
                brew install hashicorp/tap/terraform
            fi
            ;;
    esac
    
    # Configure Terraform with optimizations
    mkdir -p ~/.terraform.d/plugin-cache
    cat > ~/.terraformrc <<'EOF'
plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
disable_checkpoint = true
EOF
    
    # Add useful Terraform aliases
    cat >> ~/.zshrc <<'EOF'

# Terraform aliases
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfs='terraform show'
alias tfv='terraform validate'
alias tff='terraform fmt'
alias tfo='terraform output'
alias tfw='terraform workspace'
alias tfws='terraform workspace select'
alias tfwl='terraform workspace list'
alias tfwn='terraform workspace new'
alias tfl='terraform state list'
alias tfsh='terraform state show'
alias tfr='terraform refresh'
alias tft='terraform taint'
alias tfu='terraform untaint'
alias tfg='terraform graph'
alias tfim='terraform import'

# Terraform functions
tfplan() {
    terraform plan -out=tfplan && terraform show -no-color tfplan > tfplan.txt
}

tfapply() {
    if [[ -f tfplan ]]; then
        terraform apply tfplan
        rm tfplan tfplan.txt
    else
        terraform apply
    fi
}
EOF
    
    success "Terraform with optimizations installed"
}

install_opentofu_moonshot() {
    info "Installing OpenTofu..."
    
    if command_exists tofu; then
        local version=$(tofu version | head -1 | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+')
        info "OpenTofu $version already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux)
            # Install OpenTofu
            local tofu_version=$(curl -s https://api.github.com/repos/opentofu/opentofu/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
            curl -Lo /tmp/tofu.tar.gz "https://github.com/opentofu/opentofu/releases/download/${tofu_version}/tofu_${tofu_version#v}_linux_amd64.tar.gz"
            tar -xzf /tmp/tofu.tar.gz -C /tmp
            sudo mv /tmp/tofu /usr/local/bin/tofu
            sudo chmod +x /usr/local/bin/tofu
            rm /tmp/tofu.tar.gz
            ;;
        macos)
            if command_exists brew; then
                brew install opentofu
            fi
            ;;
    esac
    
    success "OpenTofu installed"
}

install_terragrunt_moonshot() {
    info "Installing Terragrunt..."
    
    if command_exists terragrunt; then
        local version=$(terragrunt --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
        info "Terragrunt $version already installed"
        return 0
    fi
    
    local tg_version=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    
    case "${DOTFILES_OS}" in
        linux)
            curl -Lo /tmp/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/${tg_version}/terragrunt_linux_amd64"
            sudo mv /tmp/terragrunt /usr/local/bin/terragrunt
            sudo chmod +x /usr/local/bin/terragrunt
            ;;
        macos)
            if command_exists brew; then
                brew install terragrunt
            fi
            ;;
    esac
    
    # Add terragrunt aliases
    echo 'alias tg=terragrunt' >> ~/.zshrc
    echo 'alias tgp="terragrunt plan"' >> ~/.zshrc
    echo 'alias tga="terragrunt apply"' >> ~/.zshrc
    echo 'alias tgd="terragrunt destroy"' >> ~/.zshrc
    
    success "Terragrunt installed"
}

install_terraform_docs() {
    info "Installing terraform-docs..."
    
    if command_exists terraform-docs; then
        info "terraform-docs already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux|macos)
            curl -sSLo ./terraform-docs.tar.gz https://terraform-docs.io/dl/v0.16.0/terraform-docs-v0.16.0-$(uname)-amd64.tar.gz
            tar -xzf terraform-docs.tar.gz
            sudo mv terraform-docs /usr/local/bin/
            rm terraform-docs.tar.gz
            ;;
    esac
    
    success "terraform-docs installed"
}

install_tflint_moonshot() {
    info "Installing TFLint..."
    
    if command_exists tflint; then
        info "tflint already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux|macos)
            curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
            ;;
    esac
    
    success "TFLint installed"
}

install_checkov() {
    info "Installing Checkov (IaC security scanner)..."
    
    if command_exists checkov; then
        info "checkov already installed"
        return 0
    fi
    
    pip3 install --user checkov || {
        warning "Failed to install checkov via pip3"
        return 1
    }
    
    success "Checkov installed"
}

install_pulumi() {
    info "Installing Pulumi..."
    
    if command_exists pulumi; then
        info "pulumi already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux|macos)
            curl -fsSL https://get.pulumi.com | sh
            echo 'export PATH="$HOME/.pulumi/bin:$PATH"' >> ~/.zshrc
            ;;
    esac
    
    success "Pulumi installed"
}

install_cdk_tools() {
    info "Installing CDK tools..."
    
    # AWS CDK
    if command_exists npm && ! command_exists cdk; then
        npm install -g aws-cdk
    fi
    
    # CDK for Terraform
    if ! command_exists cdktf; then
        npm install -g cdktf-cli
    fi
    
    success "CDK tools installed"
}

install_ansible_moonshot() {
    info "Installing Ansible with optimizations..."
    
    if command_exists ansible; then
        local version=$(ansible --version | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
        info "Ansible $version already installed"
        return 0
    fi
    
    pip3 install --user ansible ansible-lint molecule yamllint jmespath || {
        warning "Failed to install Ansible"
        return 1
    }
    
    # Configure Ansible
    mkdir -p ~/.ansible/collections
    cat > ~/.ansible.cfg <<'EOF'
[defaults]
host_key_checking = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = ~/.ansible/facts_cache
fact_caching_timeout = 7200
callback_whitelist = timer, profile_tasks
stdout_callback = yaml
bin_ansible_callbacks = True
inventory = ./inventory
roles_path = ./roles:~/.ansible/roles
collections_paths = ~/.ansible/collections
interpreter_python = auto_silent

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
pipelining = True
control_path = ~/.ansible/cp/%%h-%%p-%%r
EOF
    
    mkdir -p ~/.ansible/facts_cache ~/.ansible/cp
    
    success "Ansible with optimizations installed"
}

install_monitoring_stack() {
    print_header "Installing Monitoring & Observability Stack"
    
    # Prometheus ecosystem
    install_prometheus_tools
    
    # Grafana tools
    install_grafana_tools
    
    # OpenTelemetry
    install_otel_tools
    
    # Log management
    install_log_tools
    
    # APM tools
    install_apm_tools
}

install_prometheus_tools() {
    info "Installing Prometheus ecosystem..."
    
    # Prometheus CLI tools
    if ! command_exists promtool; then
        local version=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
        case "${DOTFILES_OS}" in
            linux)
                curl -Lo /tmp/prometheus.tar.gz "https://github.com/prometheus/prometheus/releases/download/${version}/prometheus-${version#v}.linux-amd64.tar.gz"
                tar xf /tmp/prometheus.tar.gz -C /tmp
                sudo mv /tmp/prometheus-${version#v}.linux-amd64/promtool /usr/local/bin/
                rm -rf /tmp/prometheus*
                ;;
        esac
    fi
    
    # AlertManager CLI
    if ! command_exists amtool; then
        local version=$(curl -s https://api.github.com/repos/prometheus/alertmanager/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
        case "${DOTFILES_OS}" in
            linux)
                curl -Lo /tmp/alertmanager.tar.gz "https://github.com/prometheus/alertmanager/releases/download/${version}/alertmanager-${version#v}.linux-amd64.tar.gz"
                tar xf /tmp/alertmanager.tar.gz -C /tmp
                sudo mv /tmp/alertmanager-${version#v}.linux-amd64/amtool /usr/local/bin/
                rm -rf /tmp/alertmanager*
                ;;
        esac
    fi
    
    success "Prometheus tools installed"
}

install_grafana_tools() {
    info "Installing Grafana tools..."
    
    # Grafana CLI
    case "${DOTFILES_OS}" in
        linux)
            wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
            echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
            sudo apt-get update && sudo apt-get install grafana
            ;;
        macos)
            if command_exists brew; then
                brew install grafana
            fi
            ;;
    esac
    
    success "Grafana tools installed"
}

install_otel_tools() {
    info "Installing OpenTelemetry tools..."
    
    # OTEL Collector
    if ! command_exists otelcol; then
        local version=$(curl -s https://api.github.com/repos/open-telemetry/opentelemetry-collector-releases/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
        case "${DOTFILES_OS}" in
            linux)
                curl -Lo /tmp/otelcol.tar.gz "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/${version}/otelcol_${version#v}_linux_amd64.tar.gz"
                tar xf /tmp/otelcol.tar.gz -C /tmp
                sudo mv /tmp/otelcol /usr/local/bin/
                rm /tmp/otelcol.tar.gz
                ;;
        esac
    fi
    
    success "OpenTelemetry tools installed"
}

install_log_tools() {
    info "Installing log management tools..."
    
    # Loki CLI (LogCLI)
    if ! command_exists logcli; then
        local version=$(curl -s https://api.github.com/repos/grafana/loki/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
        case "${DOTFILES_OS}" in
            linux)
                curl -Lo /tmp/logcli.zip "https://github.com/grafana/loki/releases/download/${version}/logcli-linux-amd64.zip"
                unzip -q /tmp/logcli.zip -d /tmp
                sudo mv /tmp/logcli-linux-amd64 /usr/local/bin/logcli
                sudo chmod +x /usr/local/bin/logcli
                rm /tmp/logcli.zip
                ;;
        esac
    fi
    
    success "Log management tools installed"
}

install_apm_tools() {
    info "Installing APM tools..."
    
    # Jaeger CLI
    if ! command_exists jaeger-query; then
        local version=$(curl -s https://api.github.com/repos/jaegertracing/jaeger/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
        case "${DOTFILES_OS}" in
            linux)
                curl -Lo /tmp/jaeger.tar.gz "https://github.com/jaegertracing/jaeger/releases/download/${version}/jaeger-${version#v}-linux-amd64.tar.gz"
                tar xf /tmp/jaeger.tar.gz -C /tmp
                sudo mv /tmp/jaeger-${version#v}-linux-amd64/jaeger-query /usr/local/bin/
                rm -rf /tmp/jaeger*
                ;;
        esac
    fi
    
    success "APM tools installed"
}

install_cloud_provider_stack() {
    print_header "Installing Multi-Cloud CLI Ultra-Stack"
    
    # AWS ecosystem
    install_aws_moonshot
    
    # Azure ecosystem  
    install_azure_moonshot
    
    # Google Cloud ecosystem
    install_gcp_moonshot
    
    # DigitalOcean
    install_digitalocean_cli
    
    # Linode
    install_linode_cli
}

install_aws_moonshot() {
    info "Installing AWS ecosystem..."
    
    # AWS CLI v2
    if ! command_exists aws; then
        case "${DOTFILES_OS}" in
            linux)
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
                cd /tmp && unzip -o awscliv2.zip
                sudo ./aws/install --update
                rm -rf /tmp/awscliv2.zip /tmp/aws
                ;;
            macos)
                if command_exists brew; then
                    brew install awscli
                fi
                ;;
        esac
    fi
    
    # AWS tools
    local aws_tools=(
        "eksctl"
        "aws-iam-authenticator"
        "copilot-cli"
        "sam-cli"
        "amplify-cli"
    )
    
    for tool in "${aws_tools[@]}"; do
        case "$tool" in
            eksctl)
                if ! command_exists eksctl; then
                    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
                    sudo mv /tmp/eksctl /usr/local/bin
                fi
                ;;
            aws-iam-authenticator)
                if ! command_exists aws-iam-authenticator; then
                    curl -Lo aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator
                    sudo mv aws-iam-authenticator /usr/local/bin
                    sudo chmod +x /usr/local/bin/aws-iam-authenticator
                fi
                ;;
            copilot-cli)
                if ! command_exists copilot; then
                    curl -Lo copilot https://github.com/aws/copilot-cli/releases/latest/download/copilot-linux
                    sudo mv copilot /usr/local/bin
                    sudo chmod +x /usr/local/bin/copilot
                fi
                ;;
            sam-cli)
                if ! command_exists sam; then
                    pip3 install --user aws-sam-cli
                fi
                ;;
            amplify-cli)
                if command_exists npm && ! command_exists amplify; then
                    npm install -g @aws-amplify/cli
                fi
                ;;
        esac
    done
    
    success "AWS ecosystem installed"
}

install_azure_moonshot() {
    info "Installing Azure ecosystem..."
    
    # Azure CLI
    if ! command_exists az; then
        case "${DOTFILES_OS}" in
            linux)
                curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
                ;;
            macos)
                if command_exists brew; then
                    brew install azure-cli
                fi
                ;;
        esac
    fi
    
    # Azure tools
    if command_exists az; then
        az extension add --name aks-preview --yes 2>/dev/null || true
        az extension add --name azure-devops --yes 2>/dev/null || true
        az extension add --name azure-firewall --yes 2>/dev/null || true
    fi
    
    success "Azure ecosystem installed"
}

install_gcp_moonshot() {
    info "Installing Google Cloud ecosystem..."
    
    # Google Cloud SDK
    if ! command_exists gcloud; then
        case "${DOTFILES_OS}" in
            linux)
                echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
                sudo apt-get update && sudo apt-get install google-cloud-cli
                ;;
            macos)
                if command_exists brew; then
                    brew install google-cloud-sdk
                fi
                ;;
        esac
    fi
    
    # Install additional components
    if command_exists gcloud; then
        gcloud components install gke-gcloud-auth-plugin kubectl --quiet 2>/dev/null || true
    fi
    
    success "Google Cloud ecosystem installed"
}

install_digitalocean_cli() {
    info "Installing DigitalOcean CLI..."
    
    if command_exists doctl; then
        info "doctl already installed"
        return 0
    fi
    
    case "${DOTFILES_OS}" in
        linux)
            local version=$(curl -s https://api.github.com/repos/digitalocean/doctl/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
            curl -Lo /tmp/doctl.tar.gz "https://github.com/digitalocean/doctl/releases/download/${version}/doctl-${version#v}-linux-amd64.tar.gz"
            tar xf /tmp/doctl.tar.gz -C /tmp
            sudo mv /tmp/doctl /usr/local/bin
            rm /tmp/doctl.tar.gz
            ;;
        macos)
            if command_exists brew; then
                brew install doctl
            fi
            ;;
    esac
    
    success "DigitalOcean CLI installed"
}

install_linode_cli() {
    info "Installing Linode CLI..."
    
    if command_exists linode-cli; then
        info "linode-cli already installed"
        return 0
    fi
    
    pip3 install --user linode-cli || {
        warning "Failed to install linode-cli"
        return 1
    }
    
    success "Linode CLI installed"
}

create_productivity_workflows() {
    print_header "Creating MOONSHOT Productivity Workflows"
    
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.config/moonshot"
    
    # DevOps dashboard script
    cat > "$HOME/.local/bin/moonshot-dashboard" <<'EOF'
#!/usr/bin/env bash
# MOONSHOT DevOps Dashboard

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                    MOONSHOT DEVOPS DASHBOARD                  ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# System Info
echo -e "${CYAN}🖥️  SYSTEM STATUS${NC}"
echo -e "   Hostname: $(hostname)"
echo -e "   Uptime: $(uptime | awk '{print $3,$4}' | sed 's/,//')"
echo -e "   Load: $(uptime | awk -F'load average:' '{print $2}')"
echo -e "   Memory: $(free -h | grep '^Mem:' | awk '{print $3"/"$2}')"
echo

# Docker Status
if command -v docker >/dev/null 2>&1; then
    echo -e "${BLUE}🐳 DOCKER STATUS${NC}"
    if docker info >/dev/null 2>&1; then
        echo -e "   Docker: ${GREEN}Running${NC}"
        echo -e "   Containers: $(docker ps -q | wc -l) running"
        echo -e "   Images: $(docker images -q | wc -l) total"
    else
        echo -e "   Docker: ${RED}Not running${NC}"
    fi
    echo
fi

# Kubernetes Status
if command -v kubectl >/dev/null 2>&1; then
    echo -e "${YELLOW}☸️  KUBERNETES STATUS${NC}"
    if kubectl cluster-info >/dev/null 2>&1; then
        current_context=$(kubectl config current-context 2>/dev/null || echo "none")
        current_namespace=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null || echo "default")
        echo -e "   Context: ${GREEN}${current_context}${NC}"
        echo -e "   Namespace: ${GREEN}${current_namespace}${NC}"
        echo -e "   Nodes: $(kubectl get nodes --no-headers 2>/dev/null | wc -l) total"
        echo -e "   Pods: $(kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l) total"
    else
        echo -e "   Cluster: ${RED}Not accessible${NC}"
    fi
    echo
fi

# Git Status
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -e "${GREEN}📁 GIT STATUS${NC}"
    echo -e "   Branch: $(git branch --show-current 2>/dev/null || echo 'detached')"
    echo -e "   Status: $(git status --porcelain 2>/dev/null | wc -l) changes"
    echo -e "   Remote: $(git remote get-url origin 2>/dev/null || echo 'none')"
    echo
fi

# Quick Actions
echo -e "${PURPLE}🚀 QUICK ACTIONS${NC}"
echo "   1) k9s                    - Kubernetes TUI"
echo "   2) lazydocker             - Docker TUI"
echo "   3) lazygit                - Git TUI"
echo "   4) htop                   - Process monitor"
echo "   5) moonshot-logs          - View logs"
echo "   6) moonshot-deploy        - Deploy tools"
echo "   7) Exit"
echo

read -p "Select action (1-7): " choice

case $choice in
    1) command -v k9s >/dev/null && k9s || echo "k9s not installed" ;;
    2) command -v lazydocker >/dev/null && lazydocker || echo "lazydocker not installed" ;;
    3) command -v lazygit >/dev/null && lazygit || echo "lazygit not installed" ;;
    4) command -v htop >/dev/null && htop || command -v btm >/dev/null && btm || top ;;
    5) moonshot-logs ;;
    6) moonshot-deploy ;;
    7) exit 0 ;;
    *) echo "Invalid selection" ;;
esac
EOF
    
    # Log aggregator script
    cat > "$HOME/.local/bin/moonshot-logs" <<'EOF'
#!/usr/bin/env bash
# MOONSHOT Log Aggregator

set -e

show_logs() {
    local source="$1"
    
    case "$source" in
        docker)
            echo "🐳 Docker Container Logs"
            container=$(docker ps --format "table {{.Names}}\t{{.Status}}" | tail -n +2 | fzf --height 40% --reverse | awk '{print $1}')
            [[ -n "$container" ]] && docker logs -f --tail=100 "$container"
            ;;
        k8s)
            echo "☸️  Kubernetes Pod Logs"
            if command -v stern >/dev/null; then
                stern . --all-namespaces
            else
                pod=$(kubectl get pods --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase" --no-headers | fzf --height 40% --reverse)
                [[ -n "$pod" ]] && {
                    namespace=$(echo "$pod" | awk '{print $1}')
                    podname=$(echo "$pod" | awk '{print $2}')
                    kubectl logs -f -n "$namespace" "$podname"
                }
            fi
            ;;
        system)
            echo "🖥️  System Logs"
            if [[ -f /var/log/syslog ]]; then
                tail -f /var/log/syslog
            elif command -v journalctl >/dev/null; then
                journalctl -f
            else
                echo "No system logs available"
            fi
            ;;
        *)
            echo "Invalid log source"
            exit 1
            ;;
    esac
}

echo "📋 MOONSHOT Log Viewer"
echo "1) Docker logs"
echo "2) Kubernetes logs"
echo "3) System logs"
echo "4) Exit"

read -p "Select log source (1-4): " choice

case $choice in
    1) show_logs docker ;;
    2) show_logs k8s ;;
    3) show_logs system ;;
    4) exit 0 ;;
    *) echo "Invalid selection" ;;
esac
EOF
    
    # Deployment script
    cat > "$HOME/.local/bin/moonshot-deploy" <<'EOF'
#!/usr/bin/env bash
# MOONSHOT Deployment Helper

set -e

deploy_app() {
    local method="$1"
    
    case "$method" in
        docker)
            echo "🐳 Docker Deployment"
            if [[ -f docker-compose.yml ]]; then
                docker-compose up -d
            elif [[ -f Dockerfile ]]; then
                tag="$(basename $PWD):$(date +%Y%m%d-%H%M%S)"
                docker build -t "$tag" .
                echo "Built image: $tag"
            else
                echo "No Dockerfile or docker-compose.yml found"
            fi
            ;;
        k8s)
            echo "☸️  Kubernetes Deployment"
            if [[ -f kustomization.yaml ]] || [[ -f kustomization.yml ]]; then
                kubectl apply -k .
            elif ls *.yaml >/dev/null 2>&1 || ls *.yml >/dev/null 2>&1; then
                kubectl apply -f .
            else
                echo "No Kubernetes manifests found"
            fi
            ;;
        terraform)
            echo "🏗️  Terraform Deployment"
            if [[ -f main.tf ]] || ls *.tf >/dev/null 2>&1; then
                terraform init
                terraform plan
                read -p "Apply changes? (y/N): " confirm
                [[ "$confirm" == "y" ]] && terraform apply
            else
                echo "No Terraform files found"
            fi
            ;;
        helm)
            echo "⛵ Helm Deployment"
            if [[ -f Chart.yaml ]]; then
                helm upgrade --install "$(basename $PWD)" . --wait
            else
                echo "No Helm chart found"
            fi
            ;;
        *)
            echo "Invalid deployment method"
            exit 1
            ;;
    esac
}

echo "🚀 MOONSHOT Deployment Helper"
echo "1) Docker deployment"
echo "2) Kubernetes deployment"  
echo "3) Terraform deployment"
echo "4) Helm deployment"
echo "5) Exit"

read -p "Select deployment method (1-5): " choice

case $choice in
    1) deploy_app docker ;;
    2) deploy_app k8s ;;
    3) deploy_app terraform ;;
    4) deploy_app helm ;;
    5) exit 0 ;;
    *) echo "Invalid selection" ;;
esac
EOF
    
    # Make scripts executable
    chmod +x "$HOME/.local/bin/moonshot-"*
    
    success "MOONSHOT productivity workflows created"
}

setup_environment_moonshot() {
    print_header "Setting up MOONSHOT Environment"
    
    # Create comprehensive environment setup
    cat >> ~/.zshrc <<'EOF'

# ===== MOONSHOT DEVOPS ENVIRONMENT =====
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

# Tool configurations
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export KUBERNETES_EDITOR=nvim
export KUBE_EDITOR=nvim

# Productivity aliases for DevOps workflows
alias moonshot='moonshot-dashboard'
alias logs='moonshot-logs'
alias deploy='moonshot-deploy'

# Quick infrastructure commands
alias infra-up='terraform init && terraform plan && terraform apply'
alias infra-down='terraform destroy'
alias k8s-dashboard='kubectl proxy --port=8001 & sleep 2 && open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/'

# Cloud provider quick switches
aws-profile() {
    export AWS_PROFILE=$(aws configure list-profiles | fzf --height 40% --reverse)
    echo "AWS Profile set to: $AWS_PROFILE"
}

k8s-context() {
    kubectl config use-context $(kubectl config get-contexts -o name | fzf --height 40% --reverse)
}

k8s-namespace() {
    kubectl config set-context --current --namespace=$(kubectl get namespaces -o name | cut -d/ -f2 | fzf --height 40% --reverse)
}

# Container management
docker-clean() {
    docker system prune -af --volumes
    docker image prune -af
}

k8s-clean() {
    kubectl delete pods --field-selector=status.phase=Succeeded --all-namespaces
    kubectl delete pods --field-selector=status.phase=Failed --all-namespaces
}

# Monitoring shortcuts
metrics() {
    if command -v btm >/dev/null; then
        btm
    elif command -v htop >/dev/null; then
        htop
    else
        top
    fi
}

resources() {
    echo "=== CPU & Memory ==="
    top -bn1 | head -5
    echo -e "\n=== Disk Usage ==="
    df -h | grep -E '^/dev/'
    echo -e "\n=== Network ==="
    netstat -i | grep -E '^(eth|en|wl)'
}

# Development workflow helpers
dev-env() {
    local project_type="${1:-}"
    
    case "$project_type" in
        python)
            python3 -m venv venv
            source venv/bin/activate
            pip install --upgrade pip
            [[ -f requirements.txt ]] && pip install -r requirements.txt
            ;;
        node)
            [[ -f package.json ]] && npm install
            ;;
        go)
            go mod tidy
            ;;
        *)
            echo "Usage: dev-env [python|node|go]"
            ;;
    esac
}

# Git workflow helpers
git-feature() {
    local branch_name="feature/$1"
    git checkout -b "$branch_name"
    git push -u origin "$branch_name"
}

git-hotfix() {
    local branch_name="hotfix/$1"
    git checkout -b "$branch_name"
    git push -u origin "$branch_name"
}

git-cleanup() {
    git branch --merged | grep -v "\*\|main\|master\|develop" | xargs -n 1 git branch -d
    git remote prune origin
}

# Infrastructure helpers
terraform-workspace() {
    local workspace=$(terraform workspace list | fzf --height 40% --reverse | xargs)
    [[ -n "$workspace" ]] && terraform workspace select "$workspace"
}

ansible-run() {
    local playbook=$(find . -name "*.yml" -o -name "*.yaml" | grep -v group_vars | grep -v host_vars | fzf --height 40% --reverse)
    [[ -n "$playbook" ]] && ansible-playbook "$playbook" -i inventory
}

# Welcome message for new shells
if [[ -o interactive ]] && [[ -z "$TMUX" ]]; then
    echo "🚀 MOONSHOT DevOps Environment Loaded"
    echo "💡 Quick commands: moonshot | logs | deploy | metrics | k8s-context"
fi
EOF
    
    # Source the new configuration
    # source ~/.zshrc
    
    success "MOONSHOT environment configured"
}

verify_moonshot_installation() {
    print_header "Verifying MOONSHOT Installation"
    
    local categories=(
        "Core Tools:docker,kubectl,helm,terraform"
        "K8s Tools:k9s,kubectx,kubens,stern,kustomize"
        "Cloud CLIs:aws,az,gcloud"
        "Container Security:trivy,grype,syft"
        "IaC Tools:terragrunt,ansible,pulumi"
        "Monitoring:promtool,logcli"
        "Service Mesh:istioctl,linkerd"
        "Productivity:lazygit,lazydocker,fzf"
    )
    
    local all_good=true
    
    for category in "${categories[@]}"; do
        local cat_name="${category%%:*}"
        local tools="${category##*:}"
        
        echo -e "\n${cat_name}"
        IFS=',' read -ra TOOLS <<< "$tools"
        for tool in "${TOOLS[@]}"; do
            if command_exists "$tool"; then
                echo "  ✅ $tool"
            else
                echo "  ❌ $tool"
                all_good=false
            fi
        done
    done
    
    echo
    if $all_good; then
        success "🎉 MOONSHOT DevOps Stack fully operational!"
        echo "  • Run 'moonshot' for the main dashboard"
        echo "  • Run 'k9s' for Kubernetes management"
        echo "  • Run 'lazydocker' for Docker management"
        echo "  • Run 'lazygit' for Git operations"
    else
        warning "⚠️  Some tools are missing but core functionality available"
        echo "  • Check individual tool installation logs"
        echo "  • Re-run specific installation functions if needed"
    fi
}

main() {
    print_header "MOONSHOT DevOps Tools Ultra-Stack Installation"
    
    info "Installing the most comprehensive DevOps toolkit for 10x engineers"
    info "This includes: K8s ecosystem, monitoring stack, multi-cloud CLIs, IaC tools, and security scanners"
    
    # Install based on options
    if [[ "$INSTALL_ALL" == "true" || "$CONTAINERS_ONLY" == "true" ]]; then
        install_container_orchestration_stack
    fi
    
    if [[ "$INSTALL_ALL" == "true" || "$IAC_ONLY" == "true" ]]; then
        install_infrastructure_as_code_stack
    fi
    
    if [[ "$INSTALL_ALL" == "true" || "$CLOUD_ONLY" == "true" ]]; then
        install_cloud_provider_stack
    fi
    
    if [[ "$INSTALL_ALL" == "true" || "$MONITORING_ONLY" == "true" ]]; then
        install_monitoring_stack
    fi
    
    if [[ "$INSTALL_ALL" == "true" ]]; then
        create_productivity_workflows
        setup_environment_moonshot
    fi
    
    # Verify installation
    verify_moonshot_installation
    
    success "🚀 MOONSHOT DevOps Ultra-Stack Installation Complete!"
    
    echo
    info "=== NEXT STEPS ==="
    info "1. Restart your terminal: exec zsh"
    info "2. Run 'moonshot' for the main dashboard"
    info "3. Configure your cloud providers:"
    info "   • aws configure"
    info "   • az login"
    info "   • gcloud init"
    info "4. Set up your Kubernetes contexts"
    info "5. Install monitoring stack with 'docker-compose -f ~/docker-templates/monitoring-stack.yml up'"
    info ""
    info "=== KEY FEATURES ==="
    info "🐳 Container Management: Docker + Podman + K8s ecosystem"
    info "☸️  Kubernetes: Full toolchain (k9s, helm, kustomize, stern, etc.)"
    info "☁️  Multi-Cloud: AWS + Azure + GCP + DigitalOcean + Linode"
    info "🏗️  Infrastructure: Terraform + OpenTofu + Terragrunt + Pulumi"
    info "📊 Monitoring: Prometheus + Grafana + OpenTelemetry stack"
    info "🔒 Security: Trivy + Grype + Falco + Cosign"
    info "🌐 Service Mesh: Istio + Linkerd + Consul Connect"
    info "🚀 Productivity: Custom workflows + TUI tools"
    info ""
    info "Your terminal is now a DevOps command center! 💪"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi