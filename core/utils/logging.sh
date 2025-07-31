#!/bin/bash
# core/utils/logging.sh - Centralized logging functionality

# Guard against multiple sourcing
[[ -n "${DOTFILES_LOGGING_LOADED:-}" ]] && return 0
DOTFILES_LOGGING_LOADED=1

# Color codes
declare -r RED='\033[0;31m'
declare -r GREEN='\033[0;32m'
declare -r YELLOW='\033[1;33m'
declare -r BLUE='\033[0;34m'
declare -r PURPLE='\033[0;35m'
declare -r CYAN='\033[0;36m'
declare -r NC='\033[0m'

# Log levels
declare -r LOG_DEBUG=0
declare -r LOG_INFO=1
declare -r LOG_WARN=2
declare -r LOG_ERROR=3
declare -r LOG_FATAL=4

# Current log level (can be overridden)
LOG_LEVEL=${LOG_LEVEL:-$LOG_INFO}

# Log file
LOG_FILE="${LOG_FILE:-/tmp/dotfiles-$(date +%Y%m%d-%H%M%S).log}"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

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

# Spinner for long-running operations
show_spinner() {
    local pid=$1
    local message=$2
    local spinner='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        printf "\r${CYAN}%s${NC} %s" "${spinner:$i:1}" "$message"
        i=$(( (i+1) % ${#spinner} ))
        sleep 0.1
    done
    printf "\r"
}

# Box drawing for important messages
log_box() {
    local message=$1
    local color=${2:-$NC}
    local width=$((${#message} + 4))
    
    echo -e "${color}┌$(printf "%*s" $width | tr ' ' '─')┐${NC}"
    echo -e "${color}│  $message  │${NC}"
    echo -e "${color}└$(printf "%*s" $width | tr ' ' '─')┘${NC}"
}

# Banner for section headers
log_banner() {
    local message=$1
    local color=${2:-$BLUE}
    
    echo
    echo -e "${color}============================================${NC}"
    echo -e "${color}  $message${NC}"
    echo -e "${color}============================================${NC}"
    echo
}

# Initialize logging
init_logging() {
    local log_level=${1:-$LOG_INFO}
    LOG_LEVEL=$log_level
    
    log_info "Logging initialized - Level: $LOG_LEVEL, File: $LOG_FILE"
}

# Export functions for use in other scripts
export -f log_debug log_info log_warn log_error log_fatal log_success
export -f show_progress show_spinner log_box log_banner init_logging