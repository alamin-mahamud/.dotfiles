# Ubuntu Server Installation Guide

This guide covers the minimal dotfiles setup for Ubuntu Server environments, focusing on security, productivity, and essential development tools.

## Prerequisites

- Ubuntu Server 20.04 LTS or newer
- SSH access or direct console access
- User account with sudo privileges
- Internet connection

## Quick Installation

### Standalone Script (Recommended for Servers)

```bash
wget https://raw.githubusercontent.com/yourusername/dotfiles/main/ubuntu-server-setup.sh
chmod +x ubuntu-server-setup.sh
./ubuntu-server-setup.sh
```

### Using Bootstrap Script

```bash
git clone https://github.com/yourusername/dotfiles.git ~/Work/.dotfiles
cd ~/Work/.dotfiles
chmod +x ./bootstrap.sh
./bootstrap.sh
```

Select option `2) Server Installation (Minimal, no GUI)` from the menu.

## What Gets Installed

### Essential System Packages
- **Core utilities**: curl, wget, git, vim, nano, htop, tree, jq
- **Development tools**: build-essential, make, gcc, g++, cmake
- **System monitoring**: sysstat, iotop, nethogs, iftop
- **Network tools**: net-tools, dnsutils, traceroute, nmap, tcpdump
- **Text processing**: sed, awk, grep, ripgrep, fd-find, bat
- **Process management**: supervisor
- **Shell**: zsh with minimal configuration

### Security Tools
- **UFW**: Uncomplicated Firewall for basic protection
- **fail2ban**: Intrusion prevention system
- **SSH hardening**: Optional security configurations
- **chrony**: Time synchronization

### Development Environment
- **Python**: python3, pip, venv, development headers
- **Git**: Version control with global configuration
- **Tmux**: Terminal multiplexer for session management
- **Neovim**: Modern text editor
- **Node.js**: Optional JavaScript runtime
- **Docker**: Optional container platform

### Modern CLI Tools
- **ripgrep**: Fast text search
- **fd-find**: Fast file finder
- **bat**: Cat with syntax highlighting
- **fzf**: Fuzzy finder
- **ncdu**: Disk usage analyzer

## Installation Features

### Interactive Setup
The server setup script includes interactive prompts for:
- Docker installation
- Node.js installation
- SSH hardening configuration
- Default shell selection
- Git configuration

### Security Hardening

#### Firewall Configuration
- UFW enabled with default deny incoming
- SSH port (22) allowed by default
- Easy configuration for additional ports

#### fail2ban Setup
- SSH brute force protection
- Configurable ban times and retry limits
- Email notifications (optional)

#### SSH Hardening (Optional)
- Disable root login
- Strong cipher configuration
- Connection limits
- Key-based authentication preference

### System Maintenance
- Automated maintenance script creation
- Weekly system updates via cron
- Log rotation and cleanup
- Disk usage monitoring

## Configuration Details

### Shell Setup
Minimal Zsh configuration includes:
- Command history with search
- Basic completion system
- Useful aliases for system administration
- Safety aliases (rm -i, cp -i, mv -i)
- System monitoring shortcuts

### Tmux Configuration
Server-optimized tmux setup:
- Prefix key: Ctrl-a
- Mouse support enabled
- Pane navigation shortcuts
- Status bar with system information
- Session persistence

### Vim/Neovim Setup
Minimal but functional editor configuration:
- Syntax highlighting
- Line numbers
- Basic key mappings
- File type detection
- Search improvements

## Post-Installation Steps

### 1. Configure Git
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 2. Set Up SSH Keys (Recommended)
```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
# Add public key to ~/.ssh/authorized_keys on the server
```

### 3. Configure Firewall Rules
```bash
# Allow HTTP (if running web server)
sudo ufw allow 80/tcp

# Allow HTTPS (if running web server)
sudo ufw allow 443/tcp

# Allow custom application port
sudo ufw allow 8080/tcp

# Check status
sudo ufw status
```

### 4. Enable SSH Hardening (Optional)
If you chose SSH hardening during installation:
1. Ensure SSH key access is working
2. Test new SSH connection before closing current session
3. Disable password authentication if using keys only

### 5. Set Up Docker (If Installed)
```bash
# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Test Docker installation
docker run hello-world

# Use Docker Compose
docker-compose --version
```

## Server Administration

### System Monitoring
```bash
# System overview
htop

# Disk usage
ncdu /

# Network connections
ss -tuln

# System logs
journalctl -n 50

# Firewall status
sudo ufw status verbose

# fail2ban status
sudo fail2ban-client status
```

### Maintenance Commands
```bash
# Update system
sudo apt update && sudo apt upgrade

# Clean package cache
sudo apt autoremove && sudo apt autoclean

# Check system status
systemctl status

# Monitor logs
tail -f /var/log/syslog
```

### Backup Important Configs
```bash
# Create backup directory
mkdir -p ~/backups/configs

# Backup important configurations
sudo cp /etc/ssh/sshd_config ~/backups/configs/
sudo cp /etc/ufw/user.rules ~/backups/configs/
cp ~/.zshrc ~/backups/configs/
cp ~/.tmux.conf ~/backups/configs/
```

## Development Workflow

### Python Development
```bash
# Create virtual environment
python3 -m venv myproject
source myproject/bin/activate

# Install packages
pip install requests flask

# Or use pipenv
pipenv install requests flask
pipenv shell
```

### Docker Development
```bash
# Run containers
docker run -d -p 80:80 nginx

# Docker Compose project
docker-compose up -d

# Container management
docker ps
docker logs container_name
docker exec -it container_name bash
```

### Git Workflow
```bash
# Clone repository
git clone https://github.com/user/repo.git

# Basic workflow
git add .
git commit -m "Update configuration"
git push origin main
```

## Security Best Practices

### Regular Updates
```bash
# Set up automatic security updates
sudo dpkg-reconfigure -plow unattended-upgrades
```

### Monitor System
```bash
# Check failed login attempts
sudo grep "Failed password" /var/log/auth.log

# Monitor fail2ban
sudo fail2ban-client status sshd

# Check system resources
free -h
df -h
```

### Backup Strategy
1. Regular system snapshots
2. Configuration file backups
3. Database backups (if applicable)
4. Off-site backup storage

## Troubleshooting

### Common Issues

1. **SSH connection refused**
   ```bash
   sudo systemctl status ssh
   sudo ufw status
   ```

2. **Services not starting**
   ```bash
   sudo systemctl status service-name
   journalctl -u service-name
   ```

3. **Disk space issues**
   ```bash
   df -h
   sudo du -sh /var/log/*
   sudo journalctl --vacuum-time=7d
   ```

4. **Network connectivity**
   ```bash
   ping google.com
   nslookup domain.com
   ss -tuln
   ```

### Log Locations
- System logs: `/var/log/syslog`
- Authentication: `/var/log/auth.log`
- fail2ban: `/var/log/fail2ban.log`
- UFW: `/var/log/ufw.log`
- Installation: `/tmp/ubuntu-server-setup.log`

## Customization

### Adding Custom Scripts
```bash
# Create scripts directory
mkdir -p ~/scripts

# Make script executable
chmod +x ~/scripts/my-script.sh

# Add to PATH in ~/.zshrc
echo 'export PATH="$HOME/scripts:$PATH"' >> ~/.zshrc
```

### Custom Aliases
Add to `~/.zshrc`:
```bash
# Custom server aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# System monitoring
alias ports='ss -tuln'
alias meminfo='free -h'
alias cpuinfo='lscpu'

# Docker shortcuts (if installed)
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
```

## Production Considerations

### Resource Management
- Monitor CPU and memory usage
- Set up log rotation
- Configure swap if needed
- Monitor disk space

### Backup and Recovery
- Regular system snapshots
- Configuration backups
- Database backups
- Recovery procedures documentation

### Monitoring and Alerting
- Set up system monitoring
- Configure email alerts
- Log aggregation
- Performance metrics

## Support

For server-specific issues:
1. Check system logs: `journalctl -n 50`
2. Review installation log: `/tmp/ubuntu-server-setup.log`
3. Verify service status: `systemctl status`
4. Check network connectivity and firewall rules
5. Consult the main repository documentation