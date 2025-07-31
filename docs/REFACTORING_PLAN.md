# Refactoring Plan: From Monolithic to Modular Architecture

## Overview
This document outlines the systematic refactoring of the existing dotfiles from a monolithic structure to a modular, component-based architecture that supports profile-driven installation and configuration management.

## Current Architecture Analysis

### Existing Structure Issues
```
Current Problems:
├── Monolithic installation scripts
├── Hard-coded paths and configurations  
├── Platform-specific logic scattered throughout
├── No component isolation or dependency management
├── Limited reusability and customization options
├── Difficult testing and maintenance
└── No rollback or error recovery mechanisms
```

### Technical Debt Assessment
```yaml
technical_debt:
  high_priority:
    - Duplicated code across platform scripts
    - Hard-coded configuration values
    - No error handling or logging
    - Missing dependency management
    - No validation or testing framework
    
  medium_priority:
    - Inconsistent coding standards
    - Missing documentation
    - No performance optimization
    - Limited configuration options
    
  low_priority:
    - Code style inconsistencies
    - Missing comments and documentation
    - Outdated tool versions
    - Manual update processes
```

## Refactoring Strategy

### Phase 1: Foundation Refactoring

#### 1.1 Directory Structure Reorganization
```bash
# New modular structure
.dotfiles/
├── bootstrap.sh                    # Main entry point (refactored)
├── core/                          # Core system functionality
│   ├── system/                    # System-level operations
│   │   ├── updates.sh
│   │   ├── packages.sh
│   │   ├── users.sh
│   │   └── locale.sh
│   ├── security/                  # Security components
│   │   ├── ssh.sh
│   │   ├── firewall.sh
│   │   ├── fail2ban.sh
│   │   └── hardening.sh
│   └── utils/                     # Utility functions
│       ├── logging.sh
│       ├── validation.sh
│       ├── platform.sh
│       └── errors.sh
├── components/                    # Modular components
│   ├── cloud/                     # Cloud provider tools
│   ├── devops/                    # DevOps tooling
│   ├── ai-ml/                     # AI/ML environment
│   ├── productivity/              # Development tools
│   └── observability/             # Monitoring tools
├── profiles/                      # Profile definitions
│   ├── server-minimal.yaml
│   ├── devops-workstation.yaml
│   └── templates/
├── configs/                       # Configuration templates
│   ├── zsh/
│   ├── tmux/
│   ├── git/
│   └── ssh/
└── scripts/                       # Utility scripts
    ├── install-engine.sh
    ├── profile-manager.sh
    ├── backup-restore.sh
    └── validation.sh
```

#### 1.2 Core Utility Functions Extraction
```bash
#!/bin/bash
# core/utils/logging.sh - Centralized logging functionality

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Log levels
readonly LOG_DEBUG=0
readonly LOG_INFO=1
readonly LOG_WARN=2
readonly LOG_ERROR=3
readonly LOG_FATAL=4

# Current log level (can be overridden)
LOG_LEVEL=${LOG_LEVEL:-$LOG_INFO}

# Log file
LOG_FILE="${LOG_FILE:-/tmp/dotfiles-$(date +%Y%m%d-%H%M%S).log}"

# Logging functions
log_debug() {
    [[ $LOG_LEVEL -le $LOG_DEBUG ]] && _log "DEBUG" "$1" "$BLUE"
}

log_info() {
    [[ $LOG_LEVEL -le $LOG_INFO ]] && _log "INFO" "$1" "$NC"
}

log_warn() {
    [[ $LOG_LEVEL -le $LOG_WARN ]] && _log "WARN" "$1" "$YELLOW"
}

log_error() {
    [[ $LOG_LEVEL -le $LOG_ERROR ]] && _log "ERROR" "$1" "$RED"
}

log_fatal() {
    _log "FATAL" "$1" "$RED"
    exit 1
}

log_success() {
    _log "SUCCESS" "$1" "$GREEN"
}

_log() {
    local level=$1
    local message=$2
    local color=$3
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Console output with color
    echo -e "${color}[$timestamp] [$level]${NC} $message" >&2
    
    # File log without color
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Progress indicator
show_progress() {
    local current=$1
    local total=$2
    local message=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r[%s%s] %d%% %s" \
        "$(printf "%*s" $filled | tr ' ' '█')" \
        "$(printf "%*s" $empty | tr ' ' '░')" \
        "$percent" \
        "$message"
    
    if [[ $current -eq $total ]]; then
        echo
    fi
}
```

#### 1.3 Platform Detection and Abstraction
```bash
#!/bin/bash
# core/utils/platform.sh - Platform detection and abstraction

# Platform detection
detect_platform() {
    local os_type=""
    local env_type=""
    local distro=""
    local version=""
    local arch=""
    
    # Detect architecture
    arch=$(uname -m)
    
    # Detect OS
    case "$OSTYPE" in
        linux-gnu*)
            os_type="linux"
            detect_linux_environment
            ;;
        darwin*)
            os_type="macos"
            env_type="desktop"
            version="$(sw_vers -productVersion)"
            ;;
        msys*|cygwin*)
            os_type="windows"
            env_type="wsl"
            ;;
        *)
            log_fatal "Unsupported OS: $OSTYPE"
            ;;
    esac
    
    # Export platform variables
    export DOTFILES_OS="$os_type"
    export DOTFILES_ENV="$env_type"
    export DOTFILES_DISTRO="${distro:-unknown}"
    export DOTFILES_VERSION="${version:-unknown}"
    export DOTFILES_ARCH="$arch"
    
    log_info "Platform detected: $os_type/$env_type ($distro $version) on $arch"
}

detect_linux_environment() {
    # Check for WSL
    if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
        env_type="wsl"
    else
        # Check for desktop environment
        if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]] || [[ -n "${DESKTOP_SESSION:-}" ]]; then
            env_type="desktop"
        else
            env_type="server"
        fi
    fi
    
    # Get distribution info
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        distro="$ID"
        version="$VERSION_ID"
    fi
}

# Package manager abstraction
install_package() {
    local package=$1
    local options=${2:-""}
    
    case "$DOTFILES_OS" in
        linux)
            case "$DOTFILES_DISTRO" in
                ubuntu|debian)
                    sudo apt-get install -y $options "$package"
                    ;;
                fedora|centos|rhel)
                    sudo dnf install -y $options "$package"
                    ;;
                arch)
                    sudo pacman -S --noconfirm $options "$package"
                    ;;
                *)
                    log_error "Unsupported Linux distribution: $DOTFILES_DISTRO"
                    return 1
                    ;;
            esac
            ;;
        macos)
            if command -v brew &> /dev/null; then
                brew install $options "$package"
            else
                log_error "Homebrew not found. Please install Homebrew first."
                return 1
            fi
            ;;
        *)
            log_error "Package installation not supported on: $DOTFILES_OS"
            return 1
            ;;
    esac
}

# Service management abstraction
manage_service() {
    local action=$1
    local service=$2
    
    case "$action" in
        start|stop|restart|enable|disable)
            if command -v systemctl &> /dev/null; then
                sudo systemctl "$action" "$service"
            elif command -v service &> /dev/null; then
                sudo service "$service" "$action"
            else
                log_error "No service manager found"
                return 1
            fi
            ;;
        *)
            log_error "Invalid service action: $action"
            return 1
            ;;
    esac
}
```

### Phase 2: Component Modularization

#### 2.1 Component Framework
```bash
#!/bin/bash
# Component framework base class

# Component metadata
declare -A COMPONENT_META
COMPONENT_META[name]=""
COMPONENT_META[description]=""
COMPONENT_META[version]=""
COMPONENT_META[dependencies]=""
COMPONENT_META[conflicts]=""
COMPONENT_META[platforms]=""

# Component lifecycle hooks
component_pre_install() {
    log_debug "Pre-install hook for ${COMPONENT_META[name]}"
    return 0
}

component_install() {
    log_error "Install method must be implemented by component"
    return 1
}

component_post_install() {
    log_debug "Post-install hook for ${COMPONENT_META[name]}"
    return 0
}

component_validate() {
    log_debug "Validation hook for ${COMPONENT_META[name]}"
    return 0
}

component_uninstall() {
    log_debug "Uninstall hook for ${COMPONENT_META[name]}"
    return 0
}

# Component execution
run_component() {
    local component_name=${COMPONENT_META[name]}
    
    log_info "Installing component: $component_name"
    
    # Check platform compatibility
    if ! is_platform_supported; then
        log_warn "Component $component_name not supported on $DOTFILES_OS"
        return 0
    fi
    
    # Check dependencies
    if ! check_dependencies; then
        log_error "Dependencies not met for $component_name"
        return 1
    fi
    
    # Execute lifecycle
    component_pre_install || return 1
    component_install || return 1
    component_post_install || return 1
    component_validate || return 1
    
    log_success "Component $component_name installed successfully"
}

is_platform_supported() {
    local supported_platforms=${COMPONENT_META[platforms]}
    [[ -z "$supported_platforms" ]] && return 0
    [[ "$supported_platforms" =~ $DOTFILES_OS ]]
}

check_dependencies() {
    local dependencies=${COMPONENT_META[dependencies]}
    [[ -z "$dependencies" ]] && return 0
    
    local dep
    for dep in $dependencies; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Missing dependency: $dep"
            return 1
        fi
    done
    return 0
}
```

#### 2.2 Example Component: Docker
```bash
#!/bin/bash
# components/productivity/docker.sh

source "$(dirname "$0")/../../core/utils/component.sh"

# Component metadata
COMPONENT_META[name]="docker"
COMPONENT_META[description]="Docker container runtime and tools"
COMPONENT_META[version]="1.0.0"
COMPONENT_META[dependencies]="curl"
COMPONENT_META[platforms]="linux macos"

component_install() {
    case "$DOTFILES_OS" in
        linux)
            install_docker_linux
            ;;
        macos)
            install_docker_macos
            ;;
        *)
            log_error "Docker installation not supported on $DOTFILES_OS"
            return 1
            ;;
    esac
}

install_docker_linux() {
    log_info "Installing Docker on Linux..."
    
    # Remove old versions
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Install prerequisites
    install_package ca-certificates
    install_package gnupg
    install_package lsb-release
    
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Add repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt-get update
    install_package docker-ce
    install_package docker-ce-cli
    install_package containerd.io
    install_package docker-buildx-plugin
    install_package docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker "$USER"
    
    # Enable and start Docker
    manage_service enable docker
    manage_service start docker
}

install_docker_macos() {
    log_info "Installing Docker on macOS..."
    
    if command -v brew &> /dev/null; then
        brew install --cask docker
    else
        log_error "Homebrew required for Docker installation on macOS"
        return 1
    fi
}

component_validate() {
    # Check if Docker is installed and running
    if ! command -v docker &> /dev/null; then
        log_error "Docker command not found"
        return 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_warn "Docker daemon not running or accessible"
        return 1
    fi
    
    # Test Docker functionality
    if docker run --rm hello-world &> /dev/null; then
        log_success "Docker installation validated"
        return 0
    else
        log_error "Docker validation failed"
        return 1
    fi
}

# Execute component if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_component
fi
```

### Phase 3: Configuration Management Refactoring

#### 3.1 Template-Based Configuration
```bash
#!/bin/bash
# scripts/config-manager.sh

CONFIG_DIR="$DOTFILES_ROOT/configs"
USER_CONFIG_DIR="$HOME/.config/dotfiles"

# Configuration template processing
process_config_template() {
    local template_file=$1
    local output_file=$2
    local variables_file=${3:-"$USER_CONFIG_DIR/variables.env"}
    
    if [[ ! -f "$template_file" ]]; then
        log_error "Template file not found: $template_file"
        return 1
    fi
    
    log_info "Processing template: $(basename "$template_file")"
    
    # Load variables
    if [[ -f "$variables_file" ]]; then
        set -a
        source "$variables_file"
        set +a
    fi
    
    # Process template with environment variable substitution
    envsubst < "$template_file" > "$output_file"
    
    log_success "Configuration generated: $output_file"
}

# Configuration deployment
deploy_config() {
    local config_name=$1
    local profile=${2:-"default"}
    
    local template_dir="$CONFIG_DIR/$config_name"
    local profile_template="$template_dir/$profile.template"
    local default_template="$template_dir/default.template"
    
    # Choose template
    local template_file=""
    if [[ -f "$profile_template" ]]; then
        template_file="$profile_template"
    elif [[ -f "$default_template" ]]; then
        template_file="$default_template"
    else
        log_error "No template found for $config_name"
        return 1
    fi
    
    # Determine output location
    local output_file
    case "$config_name" in
        zsh)
            output_file="$HOME/.zshrc"
            ;;
        tmux)
            output_file="$HOME/.tmux.conf"
            ;;
        git)
            output_file="$HOME/.gitconfig"
            ;;
        *)
            output_file="$HOME/.$config_name"
            ;;
    esac
    
    # Backup existing configuration
    if [[ -f "$output_file" ]]; then
        backup_file "$output_file"
    fi
    
    # Process and deploy template
    process_config_template "$template_file" "$output_file"
    
    # Set appropriate permissions
    chmod 644 "$output_file"
}

# Configuration validation
validate_config() {
    local config_name=$1
    local config_file=$2
    
    case "$config_name" in
        zsh)
            zsh -n "$config_file"
            ;;
        tmux)
            tmux -f "$config_file" list-sessions &> /dev/null || true
            ;;
        git)
            git config --file="$config_file" --list &> /dev/null
            ;;
        *)
            log_warn "No validation available for $config_name"
            ;;
    esac
}
```

#### 3.2 Configuration Templates
```bash
# configs/zsh/devops-workstation.template
# Zsh configuration for DevOps Workstation profile
# Generated from template: $(date)

# Environment variables
export EDITOR="${EDITOR:-nvim}"
export PAGER="${PAGER:-less}"
export BROWSER="${BROWSER:-firefox}"

# Path configuration
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="/usr/local/go/bin:$PATH"

# Cloud provider configurations
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
export AWS_PROFILE="${AWS_PROFILE:-default}"

# Kubernetes configuration
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    docker
    kubectl
    terraform
    aws
    gcloud
    azure
    zsh-autosuggestions
    zsh-syntax-highlighting
    fzf-tab
)

source $ZSH/oh-my-zsh.sh

# DevOps aliases
alias k='kubectl'
alias tf='terraform'
alias tg='terragrunt'
alias d='docker'
alias dc='docker-compose'

# AWS aliases
alias awsp='export AWS_PROFILE=$(aws configure list-profiles | fzf)'
alias awsr='export AWS_DEFAULT_REGION=$(echo -e "us-east-1\nus-west-2\neu-west-1\neu-central-1" | fzf)'

# Kubernetes aliases
alias kctx='kubectl config use-context $(kubectl config get-contexts -o name | fzf)'
alias kns='kubectl config set-context --current --namespace=$(kubectl get ns -o name | cut -d/ -f2 | fzf)'

# Custom functions
function aws-mfa() {
    local mfa_device="$1"
    local token_code="$2"
    
    if [[ -z "$mfa_device" || -z "$token_code" ]]; then
        echo "Usage: aws-mfa <mfa-device-arn> <token-code>"
        return 1
    fi
    
    local credentials=$(aws sts get-session-token \
        --serial-number "$mfa_device" \
        --token-code "$token_code" \
        --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
        --output text)
    
    export AWS_ACCESS_KEY_ID=$(echo "$credentials" | cut -f1)
    export AWS_SECRET_ACCESS_KEY=$(echo "$credentials" | cut -f2)
    export AWS_SESSION_TOKEN=$(echo "$credentials" | cut -f3)
    
    echo "MFA session credentials exported"
}

function k8s-forward() {
    local service="$1"
    local port="${2:-8080}"
    local namespace="${3:-default}"
    
    kubectl port-forward -n "$namespace" "svc/$service" "$port:$port"
}

# Load local customizations
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Load powerlevel10k configuration
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
```

### Phase 4: Profile System Refactoring

#### 4.1 Profile Engine
```bash
#!/bin/bash
# scripts/profile-engine.sh

PROFILES_DIR="$DOTFILES_ROOT/profiles"
COMPONENTS_DIR="$DOTFILES_ROOT/components"

# Profile installation engine
install_profile() {
    local profile_file=$1
    local dry_run=${2:-false}
    
    if [[ ! -f "$profile_file" ]]; then
        log_error "Profile file not found: $profile_file"
        return 1
    fi
    
    log_info "Installing profile: $(basename "$profile_file")"
    
    # Validate profile
    validate_profile "$profile_file" || return 1
    
    # Extract profile information
    local profile_name=$(yq eval '.profile.name' "$profile_file")
    local components=$(yq eval '.components | to_entries | .[] | .key as $category | .value[] | $category + "/" + .' "$profile_file")
    
    # Create installation plan
    local install_plan=$(create_install_plan "$components")
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "Dry run - installation plan:"
        echo "$install_plan"
        return 0
    fi
    
    # Execute installation plan
    execute_install_plan "$install_plan" "$profile_file"
    
    # Apply profile configuration
    apply_profile_configuration "$profile_file"
    
    # Run post-install scripts
    run_post_install_scripts "$profile_file"
    
    # Validate installation
    validate_profile_installation "$profile_file"
    
    log_success "Profile '$profile_name' installed successfully"
}

create_install_plan() {
    local components=$1
    local install_order=("core" "security" "productivity" "cloud" "devops" "ai_ml" "observability")
    local plan=""
    
    # Sort components by installation order
    for category in "${install_order[@]}"; do
        local category_components=$(echo "$components" | grep "^$category/" | sort)
        plan="$plan$category_components\n"
    done
    
    echo -e "$plan" | grep -v '^$'
}

execute_install_plan() {
    local install_plan=$1
    local profile_file=$2
    local total_components=$(echo "$install_plan" | wc -l)
    local current=0
    
    while IFS= read -r component; do
        ((current++))
        show_progress $current $total_components "Installing $component"
        
        install_component "$component" || {
            log_error "Failed to install component: $component"
            return 1
        }
    done <<< "$install_plan"
    
    echo  # New line after progress
}

install_component() {
    local component=$1
    local category=$(echo "$component" | cut -d'/' -f1)
    local name=$(echo "$component" | cut -d'/' -f2)
    local script="$COMPONENTS_DIR/$category/$name.sh"
    
    if [[ ! -f "$script" ]]; then
        log_error "Component script not found: $script"
        return 1
    fi
    
    log_debug "Installing component: $category/$name"
    
    # Execute component script
    (
        cd "$COMPONENTS_DIR/$category"
        bash "$name.sh"
    ) || return 1
    
    log_debug "Component installed: $category/$name"
}

apply_profile_configuration() {
    local profile_file=$1
    
    log_info "Applying profile configuration..."
    
    # Extract configuration values
    local timezone=$(yq eval '.configuration.timezone // "UTC"' "$profile_file")
    local locale=$(yq eval '.configuration.locale // "en_US.UTF-8"' "$profile_file")
    local shell=$(yq eval '.configuration.shell // "zsh"' "$profile_file")
    local editor=$(yq eval '.configuration.editor // "vim"' "$profile_file")
    
    # Apply system configuration
    apply_system_config "$timezone" "$locale" "$shell" "$editor"
    
    # Apply profile-specific configurations
    local profile_name=$(yq eval '.profile.name' "$profile_file")
    deploy_config "zsh" "$profile_name"
    deploy_config "tmux" "$profile_name"
    deploy_config "git" "$profile_name"
}

validate_profile_installation() {
    local profile_file=$1
    local errors=0
    
    log_info "Validating profile installation..."
    
    # Validate components
    local components=$(yq eval '.components | to_entries | .[] | .key as $category | .value[] | $category + "/" + .' "$profile_file")
    
    while IFS= read -r component; do
        if ! validate_component "$component"; then
            log_error "Component validation failed: $component"
            ((errors++))
        fi
    done <<< "$components"
    
    # Validate configurations
    validate_config "zsh" "$HOME/.zshrc" || ((errors++))
    validate_config "git" "$HOME/.gitconfig" || ((errors++))
    
    if [[ $errors -eq 0 ]]; then
        log_success "Profile installation validation passed"
        return 0
    else
        log_error "Profile installation validation failed with $errors errors"
        return 1
    fi
}
```

### Phase 5: Testing Framework Implementation

#### 5.1 Component Testing
```bash
#!/bin/bash
# tests/component-test-framework.sh

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENTS_DIR="$TEST_DIR/../components"

# Test runner
run_component_tests() {
    local component_path=$1
    local test_env=${2:-"docker"}
    
    log_info "Running tests for component: $component_path"
    
    case "$test_env" in
        docker)
            run_docker_tests "$component_path"
            ;;
        local)
            run_local_tests "$component_path"
            ;;
        *)
            log_error "Unknown test environment: $test_env"
            return 1
            ;;
    esac
}

run_docker_tests() {
    local component_path=$1
    local component_name=$(basename "$component_path" .sh)
    
    # Test on multiple platforms
    local platforms=("ubuntu:20.04" "ubuntu:22.04" "debian:11")
    
    for platform in "${platforms[@]}"; do
        log_info "Testing $component_name on $platform"
        
        docker run --rm -v "$PWD:/dotfiles" -w /dotfiles "$platform" bash -c "
            apt-get update -qq
            apt-get install -y curl git sudo
            useradd -m -s /bin/bash testuser
            echo 'testuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
            sudo -u testuser bash -c '
                export DOTFILES_ROOT=/dotfiles
                source /dotfiles/core/utils/logging.sh
                source /dotfiles/core/utils/platform.sh
                detect_platform
                bash $component_path
            '
        " || {
            log_error "Test failed for $component_name on $platform"
            return 1
        }
    done
    
    log_success "All tests passed for $component_name"
}

# Integration tests
run_integration_tests() {
    local profile=$1
    
    log_info "Running integration tests for profile: $profile"
    
    # Create test environment
    local test_container="dotfiles-test-$(date +%s)"
    
    docker run -d --name "$test_container" \
        -v "$PWD:/dotfiles" \
        -w /dotfiles \
        ubuntu:22.04 \
        sleep 3600
    
    # Install profile
    docker exec "$test_container" bash -c "
        apt-get update -qq
        apt-get install -y curl git sudo yq
        useradd -m -s /bin/bash testuser
        echo 'testuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
        sudo -u testuser bash -c '
            cd /dotfiles
            ./bootstrap.sh --profile $profile --non-interactive
        '
    " || {
        log_error "Profile installation failed: $profile"
        docker rm -f "$test_container"
        return 1
    }
    
    # Run validation tests
    docker exec "$test_container" bash -c "
        sudo -u testuser bash -c '
            cd /dotfiles
            ./scripts/validate-installation.sh $profile
        '
    " || {
        log_error "Profile validation failed: $profile"
        docker rm -f "$test_container"
        return 1
    }
    
    # Cleanup
    docker rm -f "$test_container"
    
    log_success "Integration tests passed for profile: $profile"
}
```

## Implementation Timeline

### Week 1-2: Foundation Refactoring
- ✅ Extract utility functions (logging, platform detection)
- ✅ Create component framework base classes
- ✅ Implement configuration template system
- ✅ Set up testing framework

### Week 3-4: Component Migration
- 🔄 Refactor existing scripts into components
- 🔄 Implement component dependency system
- 🔄 Create component validation framework
- 🔄 Add error handling and rollback

### Week 5-6: Profile System Integration
- 📋 Implement profile engine
- 📋 Create profile validation
- 📋 Add configuration management
- 📋 Implement installation orchestration

### Week 7-8: Testing and Validation
- 📋 Complete test suite implementation
- 📋 Add integration testing
- 📋 Performance optimization
- 📋 Documentation updates

## Quality Assurance

### Code Quality Standards
```yaml
quality_standards:
  shell_scripting:
    - Use shellcheck for static analysis
    - Follow Google Shell Style Guide
    - Implement proper error handling
    - Add comprehensive comments
    
  testing:
    - Unit tests for all components
    - Integration tests for profiles
    - Cross-platform testing
    - Performance benchmarking
    
  documentation:
    - Component documentation
    - API documentation
    - User guides
    - Troubleshooting guides
```

### Automated Quality Gates
```bash
#!/bin/bash
# scripts/quality-check.sh

# Static analysis
shellcheck -x components/**/*.sh scripts/*.sh

# Unit tests
./tests/run-unit-tests.sh

# Integration tests
./tests/run-integration-tests.sh

# Performance tests
./tests/run-performance-tests.sh

# Security scanning
./tests/run-security-scan.sh

# Documentation validation
./tests/validate-documentation.sh
```

## Migration Path

### Backward Compatibility
- Maintain existing script interfaces during transition
- Provide legacy wrapper scripts
- Gradual migration of users to new system
- Comprehensive migration documentation

### Rollback Strategy
- Automated backup before refactoring
- Component-level rollback capability
- Profile-level rollback mechanism
- Emergency restoration procedures

---

*This refactoring plan provides a systematic approach to transforming the current dotfiles into a modern, maintainable, and extensible system while preserving existing functionality and user experience.*