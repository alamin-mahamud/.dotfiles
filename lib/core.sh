#!/usr/bin/env bash
# Core library - Foundation ingredients for all scripts
# Following Python's Zen: "Simple is better than complex"

set -euo pipefail

# Color definitions (check if already defined)
[[ -z "${RED:-}" ]] && readonly RED='\033[0;31m'
[[ -z "${GREEN:-}" ]] && readonly GREEN='\033[0;32m'
[[ -z "${YELLOW:-}" ]] && readonly YELLOW='\033[1;33m'
[[ -z "${BLUE:-}" ]] && readonly BLUE='\033[0;34m'
[[ -z "${MAGENTA:-}" ]] && readonly MAGENTA='\033[0;35m'
[[ -z "${CYAN:-}" ]] && readonly CYAN='\033[0;36m'
[[ -z "${WHITE:-}" ]] && readonly WHITE='\033[1;37m'
[[ -z "${NC:-}" ]] && readonly NC='\033[0m' # No Color

# Logging functions
log() { echo -e "${WHITE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"; }
info() { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
debug() { [[ "${DEBUG:-0}" == "1" ]] && echo -e "${MAGENTA}[DEBUG]${NC} $*" || true; }

# Error handling
die() {
    error "$@"
    exit 1
}

# Trap errors
trap 'error "Error on line $LINENO"' ERR

# Check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Run command with error checking
run() {
    debug "Running: $*"
    if ! "$@"; then
        error "Command failed: $*"
        return 1
    fi
}

# Ask yes/no question
confirm() {
    local prompt="${1:-Continue?}"
    local response
    
    while true; do
        read -rp "${prompt} [y/N]: " response
        case "${response,,}" in
            y|yes) return 0 ;;
            n|no|"") return 1 ;;
            *) warning "Please answer yes or no" ;;
        esac
    done
}

# Create directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        debug "Creating directory: $dir"
        mkdir -p "$dir"
    fi
}

# Backup file
backup_file() {
    local file="$1"
    if [[ -e "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        debug "Backing up $file to $backup"
        cp -a "$file" "$backup"
        info "Backed up: $file"
    fi
}

# Create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    
    if [[ ! -e "$source" ]]; then
        error "Source does not exist: $source"
        return 1
    fi
    
    if [[ -L "$target" ]]; then
        local current_source
        current_source=$(readlink "$target")
        if [[ "$current_source" == "$source" ]]; then
            debug "Symlink already correct: $target -> $source"
            return 0
        else
            warning "Removing incorrect symlink: $target -> $current_source"
            rm "$target"
        fi
    elif [[ -e "$target" ]]; then
        backup_file "$target"
        rm -rf "$target"
    fi
    
    debug "Creating symlink: $target -> $source"
    ln -sfn "$source" "$target"
    success "Created symlink: $target"
}

# Download file
download() {
    local url="$1"
    local dest="${2:-}"
    
    if command_exists curl; then
        if [[ -n "$dest" ]]; then
            curl -fsSL "$url" -o "$dest"
        else
            curl -fsSL "$url"
        fi
    elif command_exists wget; then
        if [[ -n "$dest" ]]; then
            wget -qO "$dest" "$url"
        else
            wget -qO- "$url"
        fi
    else
        die "Neither curl nor wget available"
    fi
}

# Check internet connectivity
check_internet() {
    if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null && \
       ! ping -c 1 -W 2 1.1.1.1 &>/dev/null; then
        return 1
    fi
    return 0
}

# Get user home directory
get_home() {
    echo "${HOME:-$(eval echo ~$USER)}"
}

# Get dotfiles root
get_dotfiles_root() {
    echo "${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
}

export -f log info success warning error debug die
export -f command_exists run confirm
export -f ensure_dir backup_file create_symlink
export -f download check_internet
export -f get_home get_dotfiles_root