# Migration & Refactoring Guide

## Overview
This guide outlines the migration path from the current dotfiles structure to the enhanced, profile-based system. The migration prioritizes zero-downtime transitions, data preservation, and backward compatibility.

## Pre-Migration Assessment

### Current System Analysis
Before beginning migration, assess your current setup:

```bash
# Run the assessment script
./scripts/assess-current-setup.sh

# Manual assessment checklist
echo "=== Current Dotfiles Assessment ==="
echo "1. Installed packages:"
apt list --installed | grep -E "(zsh|tmux|docker|git)" || brew list

echo "2. Current shell configuration:"
ls -la ~/.zshrc ~/.bashrc ~/.profile

echo "3. Existing dotfiles:"
find ~ -maxdepth 1 -name ".*" -type f | head -20

echo "4. Git configuration:"
git config --list --global

echo "5. SSH configuration:"
ls -la ~/.ssh/

echo "6. Development tools:"
which python3 node npm docker kubectl terraform
```

### Backup Current Configuration
```bash
#!/bin/bash
# backup-current-config.sh

BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Creating backup in: $BACKUP_DIR"

# Backup shell configurations
cp ~/.zshrc "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.bashrc "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.profile "$BACKUP_DIR/" 2>/dev/null || true

# Backup development configurations
cp -r ~/.config "$BACKUP_DIR/" 2>/dev/null || true
cp -r ~/.ssh "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.gitconfig "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.tmux.conf "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.vimrc "$BACKUP_DIR/" 2>/dev/null || true

# Backup package lists
if command -v apt &> /dev/null; then
    apt list --installed > "$BACKUP_DIR/apt-packages.txt"
elif command -v brew &> /dev/null; then
    brew list > "$BACKUP_DIR/brew-packages.txt"
    brew list --cask > "$BACKUP_DIR/brew-casks.txt"
fi

# Create system info snapshot
uname -a > "$BACKUP_DIR/system-info.txt"
id >> "$BACKUP_DIR/system-info.txt"
echo "Backup completed: $BACKUP_DIR"
```

## Migration Strategies

### Strategy 1: In-Place Migration (Recommended)
Upgrade existing installation while preserving configurations:

```bash
# 1. Backup current system
./backup-current-config.sh

# 2. Update repository to new structure
git fetch origin
git checkout main
git pull origin main

# 3. Run migration script
./migrate.sh --in-place --preserve-config

# 4. Verify migration
./verify-migration.sh
```

### Strategy 2: Side-by-Side Migration
Install new system alongside existing configuration:

```bash
# 1. Clone to new location
git clone https://github.com/username/dotfiles.git ~/.dotfiles-new

# 2. Run new installation with existing config detection
cd ~/.dotfiles-new
./bootstrap.sh --detect-existing --import-config

# 3. Test new installation
source ~/.zshrc-new

# 4. Switch when ready
mv ~/.dotfiles ~/.dotfiles-old
mv ~/.dotfiles-new ~/.dotfiles
```

### Strategy 3: Fresh Installation
Clean installation with manual configuration import:

```bash
# 1. Backup everything
./backup-current-config.sh

# 2. Remove old dotfiles (optional)
# rm -rf ~/.dotfiles-old

# 3. Fresh installation
git clone https://github.com/username/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh --fresh-install

# 4. Import specific configurations manually
./import-config.sh --source ~/.dotfiles-backup-*/
```

## Migration Script Implementation

### Core Migration Script
```bash
#!/bin/bash
# migrate.sh - Main migration orchestrator

set -euo pipefail

MIGRATION_LOG="/tmp/dotfiles-migration-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR=""
PRESERVE_CONFIG=false
IN_PLACE=false
DRY_RUN=false

migrate_main() {
    echo "Starting dotfiles migration..."
    
    # Create backup
    create_backup
    
    # Detect current profile
    DETECTED_PROFILE=$(detect_current_profile)
    echo "Detected profile: $DETECTED_PROFILE"
    
    # Migrate configurations
    migrate_configurations
    
    # Update system components
    update_system_components
    
    # Install new features
    install_new_features
    
    # Verify migration
    verify_migration
    
    echo "Migration completed successfully!"
    echo "Log file: $MIGRATION_LOG"
    echo "Backup directory: $BACKUP_DIR"
}

create_backup() {
    BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    echo "Creating backup in: $BACKUP_DIR"
    
    # Use the backup script
    bash "$(dirname "$0")/backup-current-config.sh"
}

detect_current_profile() {
    local profile="server-minimal"  # default
    
    # Check for desktop environment
    if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
        profile="devops-workstation"
    fi
    
    # Check for AI/ML tools
    if command -v jupyter &> /dev/null || command -v conda &> /dev/null; then
        profile="ai-ml-research"
    fi
    
    # Check for security tools
    if command -v nmap &> /dev/null || command -v wireshark &> /dev/null; then
        profile="security-engineer"
    fi
    
    echo "$profile"
}

migrate_configurations() {
    echo "Migrating configurations..."
    
    # Migrate zsh configuration
    if [[ -f ~/.zshrc ]]; then
        echo "Migrating zsh configuration..."
        migrate_zsh_config
    fi
    
    # Migrate tmux configuration
    if [[ -f ~/.tmux.conf ]]; then
        echo "Migrating tmux configuration..."
        migrate_tmux_config
    fi
    
    # Migrate git configuration
    migrate_git_config
    
    # Migrate SSH configuration
    migrate_ssh_config
}

migrate_zsh_config() {
    local old_zshrc="$HOME/.zshrc"
    local new_zshrc="$HOME/.zshrc.new"
    
    # Extract custom configurations
    local custom_aliases=$(grep -E "^alias " "$old_zshrc" | grep -v "# dotfiles managed" || true)
    local custom_exports=$(grep -E "^export " "$old_zshrc" | grep -v "# dotfiles managed" || true)
    local custom_functions=$(sed -n '/^# Custom functions/,/^# End custom functions/p' "$old_zshrc" || true)
    
    # Create new zshrc with preserved customizations
    cat > "$new_zshrc" <<EOF
# Generated by dotfiles migration - $(date)
# Original configuration backed up to: $BACKUP_DIR

# Load new profile-based configuration
source ~/.dotfiles/zsh/profile-$DETECTED_PROFILE.zsh

# Preserved custom aliases
$custom_aliases

# Preserved custom exports  
$custom_exports

# Preserved custom functions
$custom_functions

# Load any additional local configuration
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
EOF
    
    # Replace old configuration
    mv "$old_zshrc" "$old_zshrc.backup"
    mv "$new_zshrc" "$old_zshrc"
}

migrate_tmux_config() {
    local old_tmux_conf="$HOME/.tmux.conf"
    local custom_tmux="$HOME/.tmux.conf.local"
    
    # Extract custom key bindings and settings
    grep -v "# dotfiles managed" "$old_tmux_conf" > "$custom_tmux" || true
    
    # Use new profile-based tmux configuration
    ln -sf "$HOME/.dotfiles/tmux/profile-$DETECTED_PROFILE.conf" "$old_tmux_conf"
    
    # Source custom configuration at the end
    echo "source-file ~/.tmux.conf.local" >> "$old_tmux_conf"
}

migrate_git_config() {
    echo "Preserving git configuration..."
    
    # Git config is usually user-specific, so we preserve it
    # Only update if there are new features to add
    
    # Add new aliases if they don't exist
    git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit" || true
    
    # Set up delta if not configured
    if ! git config --global core.pager | grep -q delta; then
        git config --global core.pager delta
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate true
        git config --global merge.conflictstyle diff3
        git config --global diff.colorMoved default
    fi
}

migrate_ssh_config() {
    local ssh_config="$HOME/.ssh/config"
    
    if [[ -f "$ssh_config" ]]; then
        echo "Preserving SSH configuration..."
        
        # Add performance optimizations if not present
        if ! grep -q "ControlMaster" "$ssh_config"; then
            cat >> "$ssh_config" <<EOF

# Added by dotfiles migration
Host *
    ControlMaster auto
    ControlPath ~/.ssh/control-%r@%h:%p
    ControlPersist 10m
    ServerAliveInterval 30
    ServerAliveCountMax 3
    TCPKeepAlive yes
EOF
        fi
    fi
}

update_system_components() {
    echo "Updating system components..."
    
    # Update package lists
    if command -v apt &> /dev/null; then
        sudo apt update
    elif command -v brew &> /dev/null; then
        brew update
    fi
    
    # Install new essential packages
    install_essential_packages
    
    # Update existing packages
    update_existing_packages
}

install_essential_packages() {
    local new_packages=()
    
    # Check for modern CLI tools
    command -v bat &> /dev/null || new_packages+=("bat")
    command -v exa &> /dev/null || new_packages+=("exa")
    command -v fd &> /dev/null || new_packages+=("fd-find")
    command -v rg &> /dev/null || new_packages+=("ripgrep")
    command -v delta &> /dev/null || new_packages+=("git-delta")
    
    if [[ ${#new_packages[@]} -gt 0 ]]; then
        echo "Installing new packages: ${new_packages[*]}"
        
        if command -v apt &> /dev/null; then
            sudo apt install -y "${new_packages[@]}"
        elif command -v brew &> /dev/null; then
            brew install "${new_packages[@]}"
        fi
    fi
}

install_new_features() {
    echo "Installing new features based on detected profile: $DETECTED_PROFILE"
    
    # Install profile-specific components
    case "$DETECTED_PROFILE" in
        "devops-workstation")
            install_devops_tools
            ;;
        "ai-ml-research")
            install_ml_tools
            ;;
        "security-engineer")
            install_security_tools
            ;;
        *)
            echo "Using minimal server installation"
            ;;
    esac
}

install_devops_tools() {
    echo "Installing DevOps tools..."
    
    # Kubernetes tools
    install_kubectl
    install_helm
    install_k9s
    
    # Cloud tools
    install_aws_cli
    install_terraform
    
    # Container tools
    install_docker_compose
}

install_ml_tools() {
    echo "Installing AI/ML tools..."
    
    # Python environment
    install_pyenv
    install_conda
    
    # Jupyter
    install_jupyter_lab
    
    # GPU support (if available)
    check_and_install_gpu_support
}

verify_migration() {
    echo "Verifying migration..."
    
    local errors=0
    
    # Check shell
    if [[ "$SHELL" != */zsh ]]; then
        echo "WARNING: Shell is not zsh"
        ((errors++))
    fi
    
    # Check zsh configuration
    if ! zsh -c "source ~/.zshrc" &> /dev/null; then
        echo "ERROR: Zsh configuration has errors"
        ((errors++))
    fi
    
    # Check tmux configuration
    if command -v tmux &> /dev/null; then
        if ! tmux -f ~/.tmux.conf list-sessions &> /dev/null; then
            echo "WARNING: Tmux configuration may have issues"
        fi
    fi
    
    # Check git configuration
    if ! git config --list &> /dev/null; then
        echo "ERROR: Git configuration has errors"
        ((errors++))
    fi
    
    # Profile-specific verification
    verify_profile_installation "$DETECTED_PROFILE"
    
    if [[ $errors -eq 0 ]]; then
        echo "✅ Migration verification passed!"
        return 0
    else
        echo "❌ Migration verification found $errors errors"
        return 1
    fi
}

# Command line argument parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        --in-place)
            IN_PLACE=true
            shift
            ;;
        --preserve-config)
            PRESERVE_CONFIG=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
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

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    migrate_main "$@" 2>&1 | tee "$MIGRATION_LOG"
fi
```

## Post-Migration Verification

### Verification Checklist
```bash
#!/bin/bash
# verify-migration.sh

echo "=== Post-Migration Verification ==="

# 1. Shell functionality
echo "1. Testing shell configuration..."
zsh -c "source ~/.zshrc && echo 'Zsh configuration loaded successfully'"

# 2. Git functionality
echo "2. Testing git configuration..."
git config --list > /dev/null && echo "Git configuration valid"

# 3. Development tools
echo "3. Checking development tools..."
for tool in git docker kubectl terraform; do
    if command -v "$tool" &> /dev/null; then
        echo "✅ $tool: $(command -v "$tool")"
    else
        echo "❌ $tool: not found"
    fi
done

# 4. Modern CLI tools
echo "4. Checking modern CLI tools..."
for tool in bat exa fd rg delta; do
    if command -v "$tool" &> /dev/null; then
        echo "✅ $tool: installed"
    else
        echo "⚠️  $tool: not installed"
    fi
done

# 5. Profile-specific verification
echo "5. Profile-specific verification..."
if [[ -f ~/.dotfiles/profiles/current.yaml ]]; then
    echo "Profile configuration found"
    yq eval '.profile.name' ~/.dotfiles/profiles/current.yaml
else
    echo "No profile configuration found"
fi

echo "=== Verification Complete ==="
```

## Rollback Procedures

### Automatic Rollback
```bash
#!/bin/bash
# rollback-migration.sh

BACKUP_DIR="$1"

if [[ -z "$BACKUP_DIR" || ! -d "$BACKUP_DIR" ]]; then
    echo "Usage: rollback-migration.sh <backup-directory>"
    exit 1
fi

echo "Rolling back to configuration from: $BACKUP_DIR"

# Restore shell configurations
[[ -f "$BACKUP_DIR/.zshrc" ]] && cp "$BACKUP_DIR/.zshrc" ~/
[[ -f "$BACKUP_DIR/.bashrc" ]] && cp "$BACKUP_DIR/.bashrc" ~/
[[ -f "$BACKUP_DIR/.profile" ]] && cp "$BACKUP_DIR/.profile" ~/

# Restore development configurations
[[ -d "$BACKUP_DIR/.config" ]] && cp -r "$BACKUP_DIR/.config" ~/
[[ -d "$BACKUP_DIR/.ssh" ]] && cp -r "$BACKUP_DIR/.ssh" ~/
[[ -f "$BACKUP_DIR/.gitconfig" ]] && cp "$BACKUP_DIR/.gitconfig" ~/
[[ -f "$BACKUP_DIR/.tmux.conf" ]] && cp "$BACKUP_DIR/.tmux.conf" ~/
[[ -f "$BACKUP_DIR/.vimrc" ]] && cp "$BACKUP_DIR/.vimrc" ~/

echo "Rollback completed. Please restart your shell."
```

## Common Migration Issues

### Issue 1: Zsh Configuration Errors
**Symptoms**: Shell startup errors, missing aliases
**Solution**:
```bash
# Check for syntax errors
zsh -n ~/.zshrc

# Reset to minimal configuration
cp ~/.dotfiles/zsh/minimal.zsh ~/.zshrc

# Gradually add back customizations
```

### Issue 2: Missing Dependencies
**Symptoms**: Command not found errors
**Solution**:
```bash
# Install missing packages
./install-dependencies.sh

# Check package manager
if command -v apt &> /dev/null; then
    sudo apt update && sudo apt install -f
elif command -v brew &> /dev/null; then
    brew doctor && brew install <missing-package>
fi
```

### Issue 3: Permission Issues
**Symptoms**: Permission denied errors
**Solution**:
```bash
# Fix file permissions
chmod 644 ~/.zshrc ~/.gitconfig
chmod 600 ~/.ssh/config ~/.ssh/id_*
chmod 700 ~/.ssh

# Fix directory permissions
chmod 755 ~/.dotfiles
find ~/.dotfiles -type d -exec chmod 755 {} \;
find ~/.dotfiles -type f -exec chmod 644 {} \;
```

### Issue 4: Git Configuration Conflicts
**Symptoms**: Git commands fail, authentication issues
**Solution**:
```bash
# Reset git configuration
git config --global --unset-all user.name
git config --global --unset-all user.email

# Reconfigure git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Test git access
git ls-remote origin
```

## Migration Testing

### Test Environment Setup
```bash
# Create test environment using Docker
docker run -it --rm \
  -v $(pwd):/dotfiles \
  -w /dotfiles \
  ubuntu:22.04 \
  bash -c "
    apt update && apt install -y git curl sudo
    useradd -m -s /bin/bash testuser
    sudo -u testuser bash -c 'cd /dotfiles && ./test-migration.sh'
  "
```

### Automated Testing
```bash
#!/bin/bash
# test-migration.sh

set -e

echo "=== Migration Testing ==="

# Test 1: Backup functionality
echo "Testing backup functionality..."
./backup-current-config.sh
[[ -d ~/.dotfiles-backup-* ]] && echo "✅ Backup created"

# Test 2: Migration process
echo "Testing migration process..."
./migrate.sh --dry-run
echo "✅ Migration dry-run completed"

# Test 3: Profile detection
echo "Testing profile detection..."
PROFILE=$(./detect-profile.sh)
echo "Detected profile: $PROFILE"

# Test 4: Verification
echo "Testing verification..."
./verify-migration.sh
echo "✅ Verification completed"

echo "=== All Tests Passed ==="
```

## Migration Timelines

### Quick Migration (30 minutes)
1. **Backup** (5 minutes)
2. **Update repository** (5 minutes)
3. **Run migration script** (15 minutes)
4. **Verification** (5 minutes)

### Full Migration (2 hours)
1. **Assessment and planning** (30 minutes)
2. **Backup and documentation** (15 minutes)
3. **Migration execution** (45 minutes)
4. **Testing and verification** (15 minutes)
5. **Customization and optimization** (15 minutes)

### Enterprise Migration (1 day)
1. **Environment assessment** (2 hours)
2. **Migration planning** (2 hours)
3. **Staging environment testing** (2 hours)
4. **Production migration** (1 hour)
5. **Verification and validation** (1 hour)

## Support and Troubleshooting

### Getting Help
1. **Check logs**: Review migration logs for errors
2. **Run diagnostics**: Use built-in diagnostic tools
3. **Community support**: Search issues and discussions
4. **Documentation**: Refer to troubleshooting guides

### Emergency Contacts
- **Rollback**: Use automatic rollback scripts
- **Recovery**: Restore from backup directory
- **Support**: Create issue with migration logs
- **Documentation**: Reference this migration guide

---

*This migration guide ensures a smooth transition from the current dotfiles system to the enhanced profile-based configuration while preserving user customizations and minimizing downtime.*