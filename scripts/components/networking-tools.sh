#!/usr/bin/env bash

# Networking Tools Installation Script for Linux and macOS
# Comprehensive installer for network analysis, security, performance testing, and monitoring tools
# Installs: DNS tools, packet analysis, network monitoring, security tools, VPN/tunneling tools

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/package-managers.sh"

# Initialize environment variables
setup_environment

# Parse command line arguments
INSTALL_ALL=true
DNS_ONLY=false
PACKET_ONLY=false
PERFORMANCE_ONLY=false
SECURITY_ONLY=false
MONITORING_ONLY=false
ROUTING_ONLY=false
VPN_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dns-only)
            INSTALL_ALL=false
            DNS_ONLY=true
            shift
            ;;
        --packet-only)
            INSTALL_ALL=false
            PACKET_ONLY=true
            shift
            ;;
        --performance-only)
            INSTALL_ALL=false
            PERFORMANCE_ONLY=true
            shift
            ;;
        --security-only)
            INSTALL_ALL=false
            SECURITY_ONLY=true
            shift
            ;;
        --monitoring-only)
            INSTALL_ALL=false
            MONITORING_ONLY=true
            shift
            ;;
        --routing-only)
            INSTALL_ALL=false
            ROUTING_ONLY=true
            shift
            ;;
        --vpn-only)
            INSTALL_ALL=false
            VPN_ONLY=true
            shift
            ;;
        --help|-h)
            cat << EOF
Networking Tools Installer

Usage: $0 [OPTIONS]

OPTIONS:
    --dns-only          Install only DNS tools (dig, nslookup, host, dnsutils)
    --packet-only       Install only packet capture/analysis tools (tcpdump, tshark, tcpflow)
    --performance-only  Install only performance testing tools (iperf3, speedtest-cli, netperf)
    --security-only     Install only security tools (nmap, masscan, nikto, whois)
    --monitoring-only   Install only monitoring tools (netstat, ss, lsof, iftop, vnstat, bandwhich)
    --routing-only      Install only routing/BGP tools (traceroute, mtr, bird)
    --vpn-only         Install only VPN/tunneling tools (openvpn, wireguard, cloudflared, ngrok)
    --help, -h         Show this help message

If no option is specified, all categories will be installed.

Examples:
    $0                    # Install all networking tools
    $0 --dns-only         # Install only DNS tools
    $0 --security-only    # Install only security/reconnaissance tools

EOF
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Helper functions for permissions and groups
add_user_to_group() {
    local group="$1"
    local user="${2:-$USER}"
    
    case "${DOTFILES_OS}" in
        linux)
            if ! getent group "$group" >/dev/null 2>&1; then
                sudo groupadd "$group" 2>/dev/null || true
                info "Created group: $group"
            fi
            
            if ! groups "$user" | grep -q "\b$group\b"; then
                sudo usermod -aG "$group" "$user"
                success "Added user $user to group $group"
                return 0  # Indicate group was added
            else
                debug "User $user already in group $group"
                return 1  # Indicate no change needed
            fi
            ;;
        macos)
            # macOS uses different group management
            if ! dscl . -read "/Groups/$group" >/dev/null 2>&1; then
                sudo dscl . -create "/Groups/$group"
                info "Created group: $group"
            fi
            
            if ! dscl . -read "/Groups/$group" GroupMembership | grep -q "$user"; then
                sudo dscl . -append "/Groups/$group" GroupMembership "$user"
                success "Added user $user to group $group"
                return 0
            else
                debug "User $user already in group $group"
                return 1
            fi
            ;;
    esac
}

ensure_capture_permissions() {
    info "Setting up packet capture permissions..."
    local needs_relogin=false
    
    case "${DOTFILES_OS}" in
        linux)
            # Add user to wireshark group for non-root packet capture
            if add_user_to_group "wireshark" "$USER"; then
                needs_relogin=true
            fi
            
            # Set capabilities for dumpcap if available (Wireshark/tshark)
            if command_exists dumpcap; then
                local dumpcap_path
                dumpcap_path="$(which dumpcap)"
                if [[ -f "$dumpcap_path" ]]; then
                    sudo setcap cap_net_raw,cap_net_admin=eip "$dumpcap_path" 2>/dev/null || {
                        warning "Could not set capabilities for dumpcap. You may need to run tshark with sudo."
                    }
                    info "Set packet capture capabilities for dumpcap"
                fi
            fi
            
            # Set capabilities for tcpdump for non-root capture
            if command_exists tcpdump; then
                local tcpdump_path
                tcpdump_path="$(which tcpdump)"
                if [[ -f "$tcpdump_path" ]]; then
                    sudo setcap cap_net_raw,cap_net_admin=eip "$tcpdump_path" 2>/dev/null || {
                        warning "Could not set capabilities for tcpdump. You may need to run with sudo."
                    }
                    info "Set packet capture capabilities for tcpdump"
                fi
            fi
            ;;
        macos)
            # macOS requires admin privileges for packet capture by default
            info "On macOS, packet capture tools may require sudo privileges"
            ;;
    esac
    
    if [[ "$needs_relogin" == "true" ]]; then
        warning "You may need to log out and log back in for group membership changes to take effect"
    fi
}

install_from_github_release() {
    local repo="$1"
    local binary_name="$2"
    local arch_pattern="$3"
    local extract_dir="${4:-}"
    
    info "Installing $binary_name from GitHub releases..."
    
    if command_exists "$binary_name"; then
        info "$binary_name is already installed"
        return 0
    fi
    
    local latest_version
    latest_version=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    
    if [[ -z "$latest_version" ]]; then
        warning "Could not determine latest version for $repo"
        return 1
    fi
    
    local arch
    arch=$(detect_arch)
    
    # Map architecture names for different projects
    case "$arch" in
        amd64) arch="x86_64" ;;
        arm64) arch="aarch64" ;;
    esac
    
    # Construct download URL pattern
    local download_url="https://github.com/$repo/releases/download/$latest_version/$binary_name-$latest_version-$arch_pattern"
    
    # Download and install
    local temp_file="/tmp/${binary_name}.tar.gz"
    if curl -fsSL "$download_url" -o "$temp_file"; then
        if [[ -n "$extract_dir" ]]; then
            tar -xzf "$temp_file" -C /tmp/
            sudo mv "/tmp/$extract_dir/$binary_name" "/usr/local/bin/$binary_name"
        else
            sudo mv "$temp_file" "/usr/local/bin/$binary_name"
        fi
        sudo chmod +x "/usr/local/bin/$binary_name"
        rm -f "$temp_file"
        success "Installed $binary_name $latest_version"
    else
        warning "Failed to download $binary_name from $download_url"
        return 1
    fi
}

main() {
    init_script "Networking Tools Installation"
    
    local os
    os=$(detect_os)
    
    info "Installing networking tools for $os"
    info "Log file: $LOG_FILE"
    info "Backup directory: $BACKUP_DIR"
    
    # Build installation plan
    if [[ "$INSTALL_ALL" == "true" || "$DNS_ONLY" == "true" ]]; then
        install_dns_tools "$os"
    fi
    
    if [[ "$INSTALL_ALL" == "true" || "$PACKET_ONLY" == "true" ]]; then
        install_packet_tools "$os"
    fi
    
    if [[ "$INSTALL_ALL" == "true" || "$PERFORMANCE_ONLY" == "true" ]]; then
        install_performance_tools "$os"
    fi
    
    if [[ "$INSTALL_ALL" == "true" || "$SECURITY_ONLY" == "true" ]]; then
        install_security_tools "$os"
    fi
    
    if [[ "$INSTALL_ALL" == "true" || "$MONITORING_ONLY" == "true" ]]; then
        install_monitoring_tools "$os"
    fi
    
    if [[ "$INSTALL_ALL" == "true" || "$ROUTING_ONLY" == "true" ]]; then
        install_routing_tools "$os"
    fi
    
    if [[ "$INSTALL_ALL" == "true" || "$VPN_ONLY" == "true" ]]; then
        install_vpn_tools "$os"
    fi
    
    setup_environment
    
    success "Networking tools installation completed!"
    
    print_header "Next Steps"
    info "1. For packet capture tools, you may need to log out and back in"
    info "2. Test with: dig google.com, nmap -sn 192.168.1.0/24, iperf3 -c iperf.he.net"
    info "3. Run 'speedtest-cli' to test your internet speed"
    info "4. Use 'mtr google.com' for network path analysis"
}

install_dns_tools() {
    local os="$1"
    
    print_header "Installing DNS Tools"
    
    info "Installing DNS utilities..."
    
    case "$os" in
        linux)
            # Install DNS utilities package (contains dig, nslookup, host)
            case "$(detect_package_manager)" in
                apt)
                    install_packages dnsutils bind9-host whois
                    ;;
                dnf|yum)
                    install_packages bind-utils whois
                    ;;
                pacman)
                    install_packages bind whois
                    ;;
                apk)
                    install_packages bind-tools whois
                    ;;
            esac
            ;;
        macos)
            install_packages bind whois
            ;;
    esac
    
    # Install additional DNS tools
    install_dns_additional_tools "$os"
    
    success "DNS tools installed"
}

install_dns_additional_tools() {
    local os="$1"
    
    # Install dog (modern dig alternative) if available
    case "$os" in
        macos)
            if command_exists brew; then
                brew install dog 2>/dev/null || true
            fi
            ;;
        linux)
            # dog is available in some package managers
            case "$(detect_package_manager)" in
                apt)
                    # Check if dog is available (Ubuntu 22.04+)
                    apt list dog 2>/dev/null | grep -q dog || true
                    ;;
            esac
            ;;
    esac
}

install_packet_tools() {
    local os="$1"
    
    print_header "Installing Packet Capture & Analysis Tools"
    
    info "Installing packet analysis tools..."
    
    case "$os" in
        linux)
            case "$(detect_package_manager)" in
                apt)
                    install_packages tcpdump tshark tcpflow wireshark-common
                    ;;
                dnf|yum)
                    install_packages tcpdump wireshark-cli tcpflow
                    ;;
                pacman)
                    install_packages tcpdump wireshark-cli tcpflow
                    ;;
                apk)
                    install_packages tcpdump tcpflow
                    # tshark may not be available in Alpine
                    ;;
            esac
            ;;
        macos)
            install_packages tcpdump wireshark
            ;;
    esac
    
    # Set up packet capture permissions
    ensure_capture_permissions
    
    success "Packet capture tools installed"
}

install_performance_tools() {
    local os="$1"
    
    print_header "Installing Network Performance Testing Tools"
    
    info "Installing performance testing tools..."
    
    case "$os" in
        linux)
            case "$(detect_package_manager)" in
                apt)
                    install_packages iperf3 netperf curl wget
                    ;;
                dnf|yum)
                    install_packages iperf3 netperf curl wget
                    ;;
                pacman)
                    install_packages iperf3 netperf curl wget
                    ;;
                apk)
                    install_packages iperf3 curl wget
                    ;;
            esac
            ;;
        macos)
            install_packages iperf3 curl wget
            ;;
    esac
    
    # Install speedtest-cli via pip if available
    if command_exists python3; then
        if ! command_exists speedtest-cli; then
            info "Installing speedtest-cli via pip..."
            python3 -m pip install --user speedtest-cli 2>/dev/null || {
                warning "Could not install speedtest-cli via pip"
            }
        fi
    fi
    
    # Install additional performance tools
    case "$os" in
        macos)
            # Install additional tools available on macOS
            install_packages hyperfine 2>/dev/null || true
            ;;
        linux)
            case "$(detect_package_manager)" in
                apt)
                    install_packages hyperfine 2>/dev/null || true
                    ;;
            esac
            ;;
    esac
    
    success "Performance testing tools installed"
}

install_security_tools() {
    local os="$1"
    
    print_header "Installing Network Security & Reconnaissance Tools"
    
    info "Installing security and reconnaissance tools..."
    
    case "$os" in
        linux)
            case "$(detect_package_manager)" in
                apt)
                    install_packages nmap nikto whois
                    # masscan may not be available in all repos
                    install_packages masscan 2>/dev/null || {
                        warning "masscan not available in package manager"
                    }
                    ;;
                dnf|yum)
                    install_packages nmap nikto whois
                    install_packages masscan 2>/dev/null || true
                    ;;
                pacman)
                    install_packages nmap nikto whois masscan
                    ;;
                apk)
                    install_packages nmap whois
                    ;;
            esac
            ;;
        macos)
            install_packages nmap
            # nikto may not be readily available
            install_packages nikto 2>/dev/null || {
                warning "nikto not available via Homebrew"
            }
            ;;
    esac
    
    success "Security tools installed"
}

install_monitoring_tools() {
    local os="$1"
    
    print_header "Installing Network Monitoring & Visualization Tools"
    
    info "Installing network monitoring tools..."
    
    case "$os" in
        linux)
            case "$(detect_package_manager)" in
                apt)
                    install_packages net-tools lsof iftop vnstat htop
                    ;;
                dnf|yum)
                    install_packages net-tools lsof iftop vnstat htop
                    ;;
                pacman)
                    install_packages net-tools lsof iftop vnstat htop
                    ;;
                apk)
                    install_packages net-tools lsof iftop vnstat htop
                    ;;
            esac
            ;;
        macos)
            install_packages lsof htop
            # iftop and vnstat may not be available
            install_packages iftop 2>/dev/null || true
            ;;
    esac
    
    # Install bandwhich (modern network utilization tool) from GitHub releases
    if [[ "$os" == "linux" ]]; then
        install_from_github_release "imsnif/bandwhich" "bandwhich" "x86_64-unknown-linux-musl.tar.gz" "bandwhich-*" || true
    elif [[ "$os" == "macos" ]]; then
        install_packages bandwhich 2>/dev/null || {
            warning "bandwhich not available via package manager"
        }
    fi
    
    success "Network monitoring tools installed"
}

install_routing_tools() {
    local os="$1"
    
    print_header "Installing Routing & BGP Tools"
    
    info "Installing routing and path analysis tools..."
    
    case "$os" in
        linux)
            case "$(detect_package_manager)" in
                apt)
                    install_packages traceroute mtr iproute2
                    # bird may be available for BGP tools
                    install_packages bird2 2>/dev/null || {
                        install_packages bird 2>/dev/null || true
                    }
                    ;;
                dnf|yum)
                    install_packages traceroute mtr iproute
                    install_packages bird 2>/dev/null || true
                    ;;
                pacman)
                    install_packages traceroute mtr iproute2
                    install_packages bird 2>/dev/null || true
                    ;;
                apk)
                    install_packages traceroute mtr iproute2
                    ;;
            esac
            ;;
        macos)
            install_packages mtr
            # traceroute is usually built-in on macOS
            ;;
    esac
    
    success "Routing tools installed"
}

install_vpn_tools() {
    local os="$1"
    
    print_header "Installing VPN & Tunneling Tools"
    
    info "Installing VPN and tunneling tools..."
    
    case "$os" in
        linux)
            case "$(detect_package_manager)" in
                apt)
                    install_packages openvpn wireguard-tools
                    ;;
                dnf|yum)
                    install_packages openvpn wireguard-tools
                    ;;
                pacman)
                    install_packages openvpn wireguard-tools
                    ;;
                apk)
                    install_packages openvpn wireguard-tools
                    ;;
            esac
            ;;
        macos)
            install_packages openvpn wireguard-tools
            ;;
    esac
    
    # Install cloudflared (Cloudflare Argo Tunnel)
    install_cloudflared "$os"
    
    # Install ngrok (if available)
    install_ngrok "$os"
    
    success "VPN and tunneling tools installed"
}

install_cloudflared() {
    local os="$1"
    
    if command_exists cloudflared; then
        info "cloudflared already installed"
        return 0
    fi
    
    info "Installing cloudflared..."
    
    case "$os" in
        linux)
            local arch
            arch="$(detect_arch)"
            case "$arch" in
                amd64) arch="amd64" ;;
                arm64) arch="arm64" ;;
                *) arch="amd64" ;;  # fallback
            esac
            
            local cloudflared_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${arch}"
            if curl -fsSL "$cloudflared_url" -o /tmp/cloudflared; then
                sudo mv /tmp/cloudflared /usr/local/bin/cloudflared
                sudo chmod +x /usr/local/bin/cloudflared
                success "Installed cloudflared"
            else
                warning "Failed to install cloudflared"
            fi
            ;;
        macos)
            install_packages cloudflared 2>/dev/null || {
                # Install from GitHub if not in Homebrew
                local arch
                arch="$(detect_arch)"
                case "$arch" in
                    arm64) arch="arm64" ;;
                    *) arch="amd64" ;;
                esac
                
                local cloudflared_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-${arch}"
                if curl -fsSL "$cloudflared_url" -o /tmp/cloudflared; then
                    sudo mv /tmp/cloudflared /usr/local/bin/cloudflared
                    sudo chmod +x /usr/local/bin/cloudflared
                    success "Installed cloudflared from GitHub"
                else
                    warning "Failed to install cloudflared"
                fi
            }
            ;;
    esac
}

install_ngrok() {
    local os="$1"
    
    if command_exists ngrok; then
        info "ngrok already installed"
        return 0
    fi
    
    info "Installing ngrok..."
    
    case "$os" in
        macos)
            install_packages ngrok 2>/dev/null || {
                warning "ngrok not available via Homebrew. Install manually from https://ngrok.com/"
            }
            ;;
        linux)
            # ngrok provides official packages
            case "$(detect_package_manager)" in
                apt)
                    # Add ngrok repository
                    if ! grep -q "ngrok.com" /etc/apt/sources.list.d/* 2>/dev/null; then
                        curl -fsSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/sources.list.d/ngrok.asc >/dev/null
                        echo 'deb https://ngrok-agent.s3.amazonaws.com buster main' | sudo tee /etc/apt/sources.list.d/ngrok.list
                        sudo apt-get update -qq
                        install_packages ngrok 2>/dev/null || {
                            warning "Could not install ngrok via package manager"
                        }
                    fi
                    ;;
                *)
                    warning "ngrok package not available. Install manually from https://ngrok.com/"
                    ;;
            esac
            ;;
    esac
}

setup_environment() {
    print_header "Setting up Environment"
    
    # Add /usr/local/bin to PATH if not already there
    local shell_config="$HOME/.zshrc"
    if [[ -f "$shell_config" ]]; then
        if ! grep -q 'export PATH="/usr/local/bin:$PATH"' "$shell_config"; then
            echo 'export PATH="/usr/local/bin:$PATH"' >> "$shell_config"
            info "Added /usr/local/bin to PATH in $shell_config"
        fi
    fi
    
    # Add networking tool aliases to shell config
    add_networking_aliases
    
    success "Environment setup completed"
}

add_networking_aliases() {
    local alias_file="$HOME/.zsh_local"
    
    if [[ ! -f "$alias_file" ]]; then
        touch "$alias_file"
    fi
    
    # Check if networking aliases are already added
    if grep -q "# Networking Tools Aliases" "$alias_file" 2>/dev/null; then
        info "Networking aliases already configured"
        return 0
    fi
    
    info "Adding networking tool aliases..."
    
    cat >> "$alias_file" << 'EOF'

# Networking Tools Aliases
# DNS Tools
alias dnsinfo='dig +noall +answer'
alias dnsmx='dig MX +short'
alias dnsns='dig NS +short'
alias dnstxt='dig TXT +short'
alias dnsreverse='dig -x'

# Network Analysis
alias sniff='sudo tcpdump -i any -nn -s0'
alias pingf='ping -c 5'
alias ports='netstat -tulanp 2>/dev/null || ss -tulanp'
alias listening='netstat -tlnp 2>/dev/null || ss -tlnp'
alias connections='netstat -tanp 2>/dev/null || ss -tanp'

# Performance Testing
alias speed='speedtest-cli'
alias myip='curl -s ifconfig.me && echo'
alias localips='hostname -I 2>/dev/null || ifconfig | grep inet'

# Network Path Analysis
alias trace='mtr --report'
alias tracepath='mtr --report --report-cycles 10'

# Security/Recon
alias portscan='nmap -sS -O'
alias netscan='nmap -sn'
alias vulnscan='nmap -sC -sV'

# Monitoring
alias bandwidth='iftop -t -s 10 2>/dev/null || echo "iftop not available"'
alias netstat='ss -tulanp 2>/dev/null || netstat -tulanp'

# VPN/Tunneling
alias tunnel='cloudflared tunnel'
alias wgup='sudo wg-quick up'
alias wgdown='sudo wg-quick down'

EOF
    
    success "Added networking tool aliases to $alias_file"
    info "Restart your shell or run 'source ~/.zshrc' to load new aliases"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
