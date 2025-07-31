#!/bin/bash
# core/security/ssh_hardening.sh - SSH configuration hardening

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/platform.sh"

# Component metadata
COMPONENT_META[name]="ssh_hardening"
COMPONENT_META[description]="SSH client and server security hardening"
COMPONENT_META[version]="1.0.0"
COMPONENT_META[category]="security"
COMPONENT_META[platforms]="linux macos"

# Load component framework
source "$SCRIPT_DIR/../utils/component.sh"

# SSH configuration paths
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_CONFIG_D="/etc/ssh/sshd_config.d"

component_install() {
    log_info "Hardening SSH configuration..."
    
    # Configure SSH client
    configure_ssh_client
    
    # Configure SSH server (if installed)
    if is_ssh_server_installed; then
        configure_ssh_server
    else
        log_info "SSH server not installed, skipping server hardening"
    fi
    
    # Set up SSH key management
    setup_ssh_keys
    
    log_success "SSH hardening completed"
}

is_ssh_server_installed() {
    case "$DOTFILES_OS" in
        linux)
            systemctl list-unit-files | grep -q "ssh\(d\)\?.service" 2>/dev/null || \
            command -v sshd &> /dev/null
            ;;
        macos)
            # macOS has built-in SSH server
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

configure_ssh_client() {
    log_info "Configuring SSH client..."
    
    # Create SSH directory with proper permissions
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    
    # Create known_hosts file if it doesn't exist
    touch "$SSH_DIR/known_hosts"
    chmod 644 "$SSH_DIR/known_hosts"
    
    # Backup existing config
    if [[ -f "$SSH_CONFIG" ]]; then
        cp "$SSH_CONFIG" "$SSH_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
        log_debug "Backed up existing SSH config"
    fi
    
    # Create secure SSH client config
    cat > "$SSH_CONFIG" << 'EOF'
# SSH Client Configuration - Hardened by dotfiles
# Generated on: $(date)

# Global settings
Host *
    # Protocol version
    Protocol 2
    
    # Key exchange algorithms (prefer modern algorithms)
    KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
    
    # Host key algorithms
    HostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,ssh-rsa,rsa-sha2-512,rsa-sha2-256
    
    # Ciphers (prefer AES-GCM)
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
    
    # MAC algorithms
    MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
    
    # Security settings
    StrictHostKeyChecking ask
    VerifyHostKeyDNS yes
    HashKnownHosts yes
    
    # Connection settings
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
    Compression yes
    
    # Forwarding settings
    ForwardAgent no
    ForwardX11 no
    ForwardX11Trusted no
    
    # Authentication settings
    PasswordAuthentication no
    PubkeyAuthentication yes
    PreferredAuthentications publickey,keyboard-interactive
    
    # Key settings
    IdentitiesOnly yes
    AddKeysToAgent yes
    UseKeychain yes
    
    # Security restrictions
    PermitLocalCommand no
    
    # Connection reuse
    ControlMaster auto
    ControlPath ~/.ssh/controlmasters/%r@%h:%p
    ControlPersist 10m

# Example host configurations
# Uncomment and modify as needed

# Personal server
# Host myserver
#     HostName server.example.com
#     User myuser
#     Port 22
#     IdentityFile ~/.ssh/id_ed25519

# Work servers with bastion/jump host
# Host work-*
#     User workuser
#     ProxyJump bastion.work.com
#     IdentityFile ~/.ssh/id_work

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    UseKeychain yes

# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    UseKeychain yes

# Bitbucket
Host bitbucket.org
    HostName bitbucket.org
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    UseKeychain yes
EOF
    
    # Set proper permissions
    chmod 644 "$SSH_CONFIG"
    
    # Create control masters directory
    mkdir -p "$SSH_DIR/controlmasters"
    chmod 700 "$SSH_DIR/controlmasters"
    
    log_success "SSH client configured"
}

configure_ssh_server() {
    log_info "Configuring SSH server..."
    
    # Check if we have sudo access
    if ! has_sudo; then
        log_warn "Sudo access required for SSH server configuration"
        return 0
    fi
    
    # Create sshd_config.d directory if it doesn't exist
    if [[ ! -d "$SSHD_CONFIG_D" ]]; then
        sudo mkdir -p "$SSHD_CONFIG_D"
    fi
    
    # Create hardened SSH server configuration
    local sshd_hardening_config="$SSHD_CONFIG_D/99-dotfiles-hardening.conf"
    
    cat << 'EOF' | sudo tee "$sshd_hardening_config" > /dev/null
# SSH Server Hardening Configuration - Managed by dotfiles
# This file is included from /etc/ssh/sshd_config

# Protocol and port
Protocol 2
Port 22

# Network settings
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

# Key exchange algorithms
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256

# Host keys
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key

# Ciphers
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

# MACs
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256

# Authentication
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# User restrictions
AllowUsers *@*
DenyUsers root
AllowGroups ssh sudo

# Connection settings
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 10
MaxStartups 10:30:60

# Security settings
StrictModes yes
IgnoreRhosts yes
HostbasedAuthentication no
X11Forwarding no
PermitUserEnvironment no
PermitTunnel no
AllowAgentForwarding yes
AllowTcpForwarding yes
GatewayPorts no

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# SFTP configuration
Subsystem sftp /usr/lib/openssh/sftp-server -f AUTHPRIV -l INFO

# Banner
Banner /etc/ssh/banner.txt
EOF
    
    # Create SSH banner
    cat << 'EOF' | sudo tee /etc/ssh/banner.txt > /dev/null
********************************************************************************
*                            AUTHORIZED ACCESS ONLY                            *
*                                                                              *
* This system is for authorized use only. Unauthorized access is prohibited   *
* and may be subject to legal action. All activities are monitored and logged.*
*                                                                              *
********************************************************************************
EOF
    
    # Ensure sshd_config includes our configuration
    if ! sudo grep -q "^Include $SSHD_CONFIG_D/\*.conf" "$SSHD_CONFIG" 2>/dev/null; then
        echo -e "\n# Include additional configurations\nInclude $SSHD_CONFIG_D/*.conf" | sudo tee -a "$SSHD_CONFIG" > /dev/null
    fi
    
    # Generate strong host keys if they don't exist
    generate_host_keys
    
    # Test SSH configuration
    if sudo sshd -t; then
        log_success "SSH server configuration is valid"
        
        # Restart SSH service
        case "$DOTFILES_OS" in
            linux)
                manage_service restart ssh || manage_service restart sshd
                ;;
            macos)
                sudo launchctl stop com.openssh.sshd
                sudo launchctl start com.openssh.sshd
                ;;
        esac
    else
        log_error "SSH server configuration test failed"
        sudo rm -f "$sshd_hardening_config"
        return 1
    fi
}

generate_host_keys() {
    log_info "Checking SSH host keys..."
    
    # Generate ED25519 key if missing
    if [[ ! -f /etc/ssh/ssh_host_ed25519_key ]]; then
        log_info "Generating ED25519 host key..."
        sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
    fi
    
    # Generate RSA key if missing (4096 bits)
    if [[ ! -f /etc/ssh/ssh_host_rsa_key ]]; then
        log_info "Generating RSA host key..."
        sudo ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
    fi
    
    # Remove weak DSA and ECDSA keys if they exist
    for weak_key in dsa ecdsa; do
        if [[ -f "/etc/ssh/ssh_host_${weak_key}_key" ]]; then
            log_warn "Removing weak ${weak_key} host key"
            sudo rm -f "/etc/ssh/ssh_host_${weak_key}_key"*
        fi
    done
}

setup_ssh_keys() {
    log_info "Setting up SSH keys..."
    
    # Check for existing SSH keys
    local has_keys=false
    local key_types=("ed25519" "rsa")
    
    for key_type in "${key_types[@]}"; do
        if [[ -f "$SSH_DIR/id_${key_type}" ]]; then
            has_keys=true
            log_debug "Found existing ${key_type} key"
            # Ensure correct permissions
            chmod 600 "$SSH_DIR/id_${key_type}"
            chmod 644 "$SSH_DIR/id_${key_type}.pub" 2>/dev/null || true
        fi
    done
    
    # Generate new key if none exist
    if [[ "$has_keys" == "false" ]]; then
        log_info "No SSH keys found. Generating new ED25519 key..."
        
        # Get user email for key comment
        local email="${DOTFILES_GIT_EMAIL:-$USER@$(hostname)}"
        
        # Generate ED25519 key (recommended)
        ssh-keygen -t ed25519 -C "$email" -f "$SSH_DIR/id_ed25519" -N "" || {
            log_error "Failed to generate SSH key"
            return 1
        }
        
        log_success "Generated new ED25519 SSH key"
        log_info "Public key: $SSH_DIR/id_ed25519.pub"
    fi
    
    # Set up SSH agent
    setup_ssh_agent
}

setup_ssh_agent() {
    log_info "Setting up SSH agent..."
    
    case "$DOTFILES_OS" in
        linux)
            # Check if ssh-agent is running
            if ! pgrep -x ssh-agent > /dev/null; then
                log_debug "Starting ssh-agent"
                eval "$(ssh-agent -s)"
            fi
            
            # Add systemd user service for ssh-agent if on systemd system
            if command -v systemctl &> /dev/null && [[ -d "$HOME/.config/systemd/user" ]]; then
                create_ssh_agent_service
            fi
            ;;
        macos)
            # macOS handles ssh-agent automatically
            log_debug "SSH agent managed by macOS"
            ;;
    esac
}

create_ssh_agent_service() {
    local service_file="$HOME/.config/systemd/user/ssh-agent.service"
    
    if [[ ! -f "$service_file" ]]; then
        cat > "$service_file" << 'EOF'
[Unit]
Description=SSH key agent
Documentation=man:ssh-agent(1)

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK
ExecStartPost=/bin/bash -c 'ssh-add -l || ssh-add ~/.ssh/id_ed25519 ~/.ssh/id_rsa 2>/dev/null'

[Install]
WantedBy=default.target
EOF
        
        # Enable and start the service
        systemctl --user daemon-reload
        systemctl --user enable ssh-agent.service
        systemctl --user start ssh-agent.service
        
        log_debug "Created systemd ssh-agent service"
    fi
}

component_validate() {
    log_info "Validating SSH hardening..."
    
    local validation_failed=0
    
    # Check SSH directory permissions
    if [[ -d "$SSH_DIR" ]]; then
        local perms=$(stat -c %a "$SSH_DIR" 2>/dev/null || stat -f %A "$SSH_DIR" 2>/dev/null)
        if [[ "$perms" != "700" ]]; then
            log_warn "SSH directory has incorrect permissions: $perms (should be 700)"
        fi
    else
        log_error "SSH directory not found"
        ((validation_failed++))
    fi
    
    # Check SSH config exists
    if [[ ! -f "$SSH_CONFIG" ]]; then
        log_error "SSH config not found"
        ((validation_failed++))
    fi
    
    # Check for SSH keys
    if ! ls "$SSH_DIR"/id_* &> /dev/null; then
        log_warn "No SSH keys found"
    fi
    
    # Validate SSH client config
    if command -v ssh &> /dev/null; then
        if ssh -G localhost &> /dev/null; then
            log_debug "SSH client configuration valid"
        else
            log_error "SSH client configuration invalid"
            ((validation_failed++))
        fi
    fi
    
    # Check SSH server config if installed
    if is_ssh_server_installed && has_sudo; then
        if sudo sshd -t &> /dev/null; then
            log_debug "SSH server configuration valid"
        else
            log_warn "SSH server configuration has issues"
        fi
    fi
    
    if [[ $validation_failed -eq 0 ]]; then
        log_success "SSH hardening validation passed"
        return 0
    else
        log_error "SSH hardening validation failed"
        return 1
    fi
}

# Execute component if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Initialize platform detection
    init_platform
    
    # Run component
    run_component
fi