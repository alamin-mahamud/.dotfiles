# Profile-Based Installation System Specifications

## Overview
Declarative, YAML-driven installation system that enables users to select predefined profiles or create custom configurations. This approach follows the Python Zen principle of "explicit is better than implicit" while maintaining simplicity and modularity.

## Profile Architecture

### Configuration Schema
```yaml
# profiles/schema.yaml
profile_schema:
  profile:
    name: "string"              # Profile display name
    description: "string"       # Profile description
    version: "string"           # Profile version
    author: "string"            # Profile maintainer
    target_os: ["linux", "macos", "windows"]  # Supported platforms
    
  requirements:
    min_memory_gb: "number"     # Minimum RAM requirement
    min_disk_gb: "number"       # Minimum disk space
    network_required: "boolean" # Internet connection needed
    sudo_required: "boolean"    # Root privileges needed
    
  components:
    core: ["string"]            # Core system components
    cloud: ["string"]           # Cloud provider tools
    devops: ["string"]          # DevOps/infrastructure tools
    ai_ml: ["string"]           # AI/ML development stack
    observability: ["string"]   # Monitoring and logging
    productivity: ["string"]   # Development productivity
    security: ["string"]       # Security hardening
    
  configuration:
    timezone: "string"          # System timezone
    locale: "string"            # System locale
    shell: "string"             # Default shell
    editor: "string"            # Default editor
    
    custom_settings:
      key: "value"              # Custom configuration options
      
  post_install:
    scripts: ["string"]         # Post-installation scripts
    manual_steps: ["string"]   # Manual configuration steps
    validation: ["string"]     # Validation commands
```

## Predefined Profiles

### 1. Server Minimal Profile
```yaml
# profiles/server-minimal.yaml
profile:
  name: "Server Minimal"
  description: "Lightweight server setup for production environments"
  version: "2.0.0"
  author: "dotfiles-maintainer"
  target_os: ["linux"]

requirements:
  min_memory_gb: 1
  min_disk_gb: 10
  network_required: true
  sudo_required: true

components:
  core:
    - system_updates
    - essential_packages
    - user_management
    - timezone_config
    
  security:
    - ssh_hardening
    - firewall_basic
    - fail2ban
    - automatic_updates
    
  productivity:
    - zsh_minimal
    - tmux_basic
    - vim_enhanced
    - modern_cli_minimal

configuration:
  timezone: "UTC"
  locale: "en_US.UTF-8"
  shell: "zsh"
  editor: "vim"
  
  security:
    ssh_port: 22
    firewall_enabled: true
    fail2ban_enabled: true
    
  performance:
    swap_size: "1G"
    vm_swappiness: 10

post_install:
  scripts:
    - "verify_installation.sh"
    - "generate_ssh_keys.sh"
  manual_steps:
    - "Configure SSH public key authentication"
    - "Review firewall rules"
    - "Set up monitoring alerts"
  validation:
    - "systemctl status sshd"
    - "ufw status"
    - "fail2ban-client status"
```

### 2. DevOps Workstation Profile
```yaml
# profiles/devops-workstation.yaml
profile:
  name: "DevOps Workstation"
  description: "Complete DevOps engineer setup with multi-cloud tools"
  version: "2.0.0"
  author: "dotfiles-maintainer"
  target_os: ["linux", "macos"]

requirements:
  min_memory_gb: 8
  min_disk_gb: 50
  network_required: true
  sudo_required: true

components:
  core:
    - system_updates
    - essential_packages
    - development_tools
    - container_runtime
    
  cloud:
    - aws_cli
    - gcp_cli
    - azure_cli
    - multi_cloud_tools
    
  devops:
    - terraform
    - ansible
    - kubernetes_tools
    - ci_cd_tools
    - infrastructure_as_code
    
  observability:
    - prometheus_client
    - grafana_client
    - logging_tools
    - monitoring_agents
    
  productivity:
    - zsh_advanced
    - tmux_enhanced
    - neovim_full
    - vscode_extensions
    - modern_cli_full
    
  security:
    - security_scanning
    - secrets_management
    - compliance_tools

configuration:
  timezone: "UTC"
  locale: "en_US.UTF-8" 
  shell: "zsh"
  editor: "nvim"
  
  development:
    python_version: "3.11"
    node_version: "18"
    go_version: "1.21"
    
  cloud:
    default_region: "us-east-1"
    
  kubernetes:
    default_context: "development"
    
  git:
    default_branch: "main"
    signing_enabled: true

post_install:
  scripts:
    - "setup_cloud_credentials.sh"
    - "configure_kubernetes.sh"
    - "install_custom_tools.sh"
  manual_steps:
    - "Configure cloud provider credentials"
    - "Set up Git signing key"
    - "Configure monitoring dashboards"
  validation:
    - "kubectl version --client"
    - "terraform version"
    - "aws --version"
    - "docker version"
```

### 3. AI/ML Research Profile  
```yaml
# profiles/ai-ml-research.yaml
profile:
  name: "AI/ML Research"
  description: "Machine learning research and development environment"
  version: "2.0.0"
  author: "dotfiles-maintainer"
  target_os: ["linux", "macos"]

requirements:
  min_memory_gb: 16
  min_disk_gb: 100
  network_required: true
  sudo_required: true
  gpu_recommended: true

components:
  core:
    - system_updates
    - essential_packages
    - development_tools
    - python_scientific
    
  ai_ml:
    - pytorch_ecosystem
    - tensorflow_ecosystem
    - jupyter_lab
    - data_science_tools
    - model_serving
    - experiment_tracking
    - gpu_support
    
  productivity:
    - zsh_advanced
    - tmux_enhanced
    - neovim_python
    - vscode_ml_extensions
    - modern_cli_full
    
  observability:
    - gpu_monitoring
    - resource_monitoring
    - experiment_logging

configuration:
  timezone: "UTC"
  locale: "en_US.UTF-8"
  shell: "zsh"
  editor: "nvim"
  
  python:
    version: "3.11"
    package_manager: "conda"
    
  jupyter:
    lab_enabled: true
    extensions:
      - jupyterlab-git
      - jupyterlab-lsp
      - jupyter-ai
      
  gpu:
    cuda_version: "12.0"
    driver_auto_install: true
    
  ml_frameworks:
    pytorch: "2.0+"
    tensorflow: "2.13+"
    
  experiment_tracking:
    wandb_enabled: true
    mlflow_enabled: true

post_install:
  scripts:
    - "setup_conda_environments.sh"
    - "install_gpu_drivers.sh"
    - "configure_jupyter.sh"
  manual_steps:
    - "Create Weights & Biases account"
    - "Configure GPU monitoring"
    - "Set up model storage"
  validation:
    - "python -c 'import torch; print(torch.cuda.is_available())'"
    - "jupyter lab --version"
    - "conda list pytorch"
```

### 4. Security Engineer Profile
```yaml
# profiles/security-engineer.yaml
profile:
  name: "Security Engineer"
  description: "Cybersecurity professional toolkit with hardening"
  version: "2.0.0"
  author: "dotfiles-maintainer"
  target_os: ["linux", "macos"]

requirements:
  min_memory_gb: 8
  min_disk_gb: 50
  network_required: true
  sudo_required: true

components:
  core:
    - system_updates
    - essential_packages
    - development_tools
    
  security:
    - security_hardening_full
    - vulnerability_scanning
    - penetration_testing
    - forensics_tools
    - compliance_tools
    - incident_response
    - threat_hunting
    
  observability:
    - security_monitoring
    - log_analysis_tools
    - network_monitoring
    - anomaly_detection
    
  productivity:
    - zsh_security
    - tmux_enhanced
    - neovim_security
    - security_cli_tools

configuration:
  timezone: "UTC"
  locale: "en_US.UTF-8"
  shell: "zsh"
  editor: "nvim"
  
  security:
    hardening_level: "maximum"
    audit_logging: "comprehensive"
    network_monitoring: "enabled"
    
  compliance:
    frameworks: ["soc2", "iso27001", "nist"]
    
  tools:
    nmap_enabled: true
    wireshark_enabled: true
    metasploit_enabled: false  # Ethical use only

post_install:
  scripts:
    - "apply_security_hardening.sh"
    - "setup_monitoring.sh"
    - "configure_audit_logging.sh"
  manual_steps:
    - "Review security policies"
    - "Configure incident response procedures"
    - "Set up compliance reporting"
  validation:
    - "nmap --version"
    - "wireshark --version"
    - "auditctl -s"
```

### 5. Remote Developer Profile
```yaml
# profiles/remote-developer.yaml
profile:
  name: "Remote Developer"
  description: "Optimized setup for remote development workflows"
  version: "2.0.0"
  author: "dotfiles-maintainer"
  target_os: ["linux", "macos"]

requirements:
  min_memory_gb: 8
  min_disk_gb: 30
  network_required: true
  sudo_required: true

components:
  core:
    - system_updates
    - essential_packages
    - development_tools
    
  productivity:
    - zsh_remote_optimized
    - tmux_session_management
    - neovim_remote
    - vscode_remote_extensions
    - modern_cli_bandwidth_optimized
    
  networking:
    - vpn_clients
    - ssh_optimization
    - bandwidth_monitoring
    - connection_management
    
  collaboration:
    - screen_sharing_tools
    - communication_clients
    - file_sync_tools

configuration:
  timezone: "UTC"
  locale: "en_US.UTF-8"
  shell: "zsh"
  editor: "nvim"
  
  ssh:
    keep_alive: true
    connection_multiplexing: true
    compression: true
    
  tmux:
    session_persistence: true
    remote_clipboard: true
    
  bandwidth:
    optimization: "enabled"
    compression: "maximum"

post_install:
  scripts:
    - "optimize_ssh_config.sh"
    - "setup_tmux_sessions.sh"
    - "configure_remote_tools.sh"
  manual_steps:
    - "Configure VPN connections"
    - "Set up SSH key authentication"
    - "Configure remote desktop access"
  validation:
    - "ssh -V"
    - "tmux -V"
    - "code --version"
```

## Profile Selection System

### Interactive Profile Selector
```yaml
profile_selector:
  interface: "terminal_ui"
  
  categories:
    - name: "Server Environments"
      profiles:
        - server-minimal
        - server-monitoring
        - server-hardened
        
    - name: "Development Workstations"
      profiles:
        - devops-workstation
        - fullstack-developer
        - backend-developer
        - frontend-developer
        
    - name: "Specialized Environments"
      profiles:
        - ai-ml-research
        - security-engineer  
        - data-scientist
        - site-reliability-engineer
        
    - name: "Remote Work"
      profiles:
        - remote-developer
        - digital-nomad
        - home-office-setup
  
  features:
    - profile_preview
    - component_details
    - requirement_checking
    - custom_profile_creation
    - profile_comparison
```

### Profile Validation
```bash
# scripts/validate-profile.sh
#!/bin/bash

validate_profile() {
    local profile_file=$1
    
    # Schema validation
    echo "Validating profile schema..."
    yq eval '.profile.name' "$profile_file" > /dev/null || {
        echo "ERROR: Missing profile name"
        return 1
    }
    
    # Component validation
    echo "Validating components..."
    local components=$(yq eval '.components | keys | .[]' "$profile_file")
    for component in $components; do
        if [[ ! -d "components/$component" ]]; then
            echo "WARNING: Component '$component' not found"
        fi
    done
    
    # Requirements check
    echo "Checking system requirements..."
    local min_memory=$(yq eval '.requirements.min_memory_gb' "$profile_file")
    local available_memory=$(free -g | awk '/^Mem:/{print $2}')
    
    if [[ $available_memory -lt $min_memory ]]; then
        echo "WARNING: Insufficient memory (need ${min_memory}GB, have ${available_memory}GB)"
    fi
    
    echo "Profile validation complete"
}
```

## Custom Profile Creation

### Profile Builder Interface
```yaml
profile_builder:
  steps:
    1. basic_info:
        - profile_name
        - description
        - target_platform
        
    2. requirements:
        - memory_requirements
        - disk_requirements
        - network_requirements
        
    3. component_selection:
        - core_components
        - optional_components
        - custom_components
        
    4. configuration:
        - system_settings
        - application_settings
        - security_settings
        
    5. post_install:
        - custom_scripts
        - manual_steps
        - validation_commands
        
    6. validation:
        - schema_check
        - dependency_check
        - compatibility_check
        
    7. export:
        - yaml_file
        - installation_script
        - documentation
```

### Profile Templates
```yaml
# templates/basic-template.yaml
profile:
  name: "{{ profile_name }}"
  description: "{{ profile_description }}"
  version: "1.0.0"
  author: "{{ author_name }}"
  target_os: {{ target_platforms }}

requirements:
  min_memory_gb: {{ min_memory | default(4) }}
  min_disk_gb: {{ min_disk | default(20) }}
  network_required: {{ network_required | default(true) }}
  sudo_required: {{ sudo_required | default(true) }}

components:
  core: {{ core_components | default([]) }}
  {% for category, components in optional_components.items() %}
  {{ category }}: {{ components }}
  {% endfor %}

configuration:
  timezone: "{{ timezone | default('UTC') }}"
  locale: "{{ locale | default('en_US.UTF-8') }}"
  shell: "{{ shell | default('zsh') }}"
  editor: "{{ editor | default('vim') }}"
  
  {% for key, value in custom_config.items() %}
  {{ key }}: {{ value }}
  {% endfor %}

post_install:
  scripts: {{ post_install_scripts | default([]) }}
  manual_steps: {{ manual_steps | default([]) }}
  validation: {{ validation_commands | default([]) }}
```

## Installation Engine

### Profile Processor
```bash
#!/bin/bash
# scripts/install-profile.sh

set -euo pipefail

PROFILE_FILE=""
DRY_RUN=false
VERBOSE=false
LOG_FILE="/tmp/dotfiles-install-$(date +%Y%m%d-%H%M%S).log"

process_profile() {
    local profile_file=$1
    
    echo "Processing profile: $profile_file"
    
    # Validate profile
    validate_profile "$profile_file"
    
    # Extract components
    local components=$(yq eval '.components | to_entries | .[] | .key as $category | .value[] | $category + "/" + .' "$profile_file")
    
    # Install components in order
    local install_order=("core" "security" "productivity" "cloud" "devops" "ai_ml" "observability")
    
    for category in "${install_order[@]}"; do
        echo "Installing $category components..."
        
        local category_components=$(echo "$components" | grep "^$category/" | cut -d'/' -f2)
        
        for component in $category_components; do
            install_component "$category" "$component"
        done
    done
    
    # Apply configuration
    apply_configuration "$profile_file"
    
    # Run post-install scripts
    run_post_install "$profile_file"
    
    echo "Profile installation complete!"
}

install_component() {
    local category=$1
    local component=$2
    
    local script="components/$category/$component.sh"
    
    if [[ -f "$script" ]]; then
        echo "Installing $category/$component..."
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "DRY RUN: Would execute $script"
        else
            bash "$script" 2>&1 | tee -a "$LOG_FILE"
        fi
    else
        echo "WARNING: Component script not found: $script"
    fi
}

apply_configuration() {
    local profile_file=$1
    
    echo "Applying configuration..."
    
    # Extract and apply system configuration
    local timezone=$(yq eval '.configuration.timezone' "$profile_file")
    local locale=$(yq eval '.configuration.locale' "$profile_file")
    local shell=$(yq eval '.configuration.shell' "$profile_file")
    
    # Apply timezone
    if [[ "$timezone" != "null" ]]; then
        sudo timedatectl set-timezone "$timezone"
    fi
    
    # Apply locale
    if [[ "$locale" != "null" ]]; then
        export LC_ALL="$locale"
    fi
    
    # Set default shell
    if [[ "$shell" != "null" && "$shell" != "$(basename "$SHELL")" ]]; then
        chsh -s "$(which "$shell")"
    fi
}

run_post_install() {
    local profile_file=$1
    
    echo "Running post-install scripts..."
    
    local scripts=$(yq eval '.post_install.scripts[]' "$profile_file" 2>/dev/null || true)
    
    for script in $scripts; do
        if [[ -f "scripts/$script" ]]; then
            echo "Executing post-install script: $script"
            bash "scripts/$script"
        fi
    done
    
    # Display manual steps
    local manual_steps=$(yq eval '.post_install.manual_steps[]' "$profile_file" 2>/dev/null || true)
    
    if [[ -n "$manual_steps" ]]; then
        echo ""
        echo "Manual steps required:"
        echo "$manual_steps" | sed 's/^/  - /'
    fi
}

# Main execution
main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--profile)
                PROFILE_FILE="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$PROFILE_FILE" ]]; then
        echo "Profile file is required"
        exit 1
    fi
    
    if [[ ! -f "$PROFILE_FILE" ]]; then
        echo "Profile file not found: $PROFILE_FILE"
        exit 1
    fi
    
    process_profile "$PROFILE_FILE"
}

main "$@"
```

## Profile Management

### Profile Operations
```bash
# Profile management commands
dotfiles profile list                    # List available profiles
dotfiles profile show <profile-name>    # Show profile details
dotfiles profile validate <profile>     # Validate profile
dotfiles profile install <profile>      # Install profile
dotfiles profile create                 # Create custom profile
dotfiles profile edit <profile>         # Edit existing profile
dotfiles profile export <profile>       # Export profile
dotfiles profile import <file>          # Import profile
dotfiles profile compare <p1> <p2>      # Compare profiles
```

### Profile Repository
```yaml
profile_repository:
  structure:
    profiles/
    ├── official/           # Maintained profiles
    │   ├── server-minimal.yaml
    │   ├── devops-workstation.yaml
    │   └── ai-ml-research.yaml
    ├── community/          # Community contributions
    │   ├── data-scientist.yaml
    │   └── game-developer.yaml
    ├── custom/             # User-created profiles
    │   └── my-profile.yaml
    └── templates/          # Profile templates
        ├── basic-template.yaml
        └── advanced-template.yaml
  
  versioning:
    - semantic_versioning
    - backward_compatibility
    - migration_scripts
    
  validation:
    - schema_validation
    - component_existence
    - dependency_checking
    - platform_compatibility
```