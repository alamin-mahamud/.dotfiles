#!/bin/bash
# core/system/locale_config.sh - System locale and language configuration

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/platform.sh"

# Component metadata
COMPONENT_META[name]="locale_config"
COMPONENT_META[description]="System locale, language, and regional settings configuration"
COMPONENT_META[version]="1.0.0"
COMPONENT_META[category]="core"
COMPONENT_META[platforms]="linux macos"

# Load component framework
source "$SCRIPT_DIR/../utils/component.sh"

# Default locale settings
DEFAULT_LOCALE="${DOTFILES_LOCALE:-en_US.UTF-8}"
DEFAULT_LANGUAGE="${DOTFILES_LANGUAGE:-en_US:en}"

component_install() {
    log_info "Configuring system locale..."
    
    # Get current locale
    local current_locale=$(get_current_locale)
    log_debug "Current locale: $current_locale"
    
    # Determine target locale
    local target_locale="${DOTFILES_LOCALE:-$DEFAULT_LOCALE}"
    log_info "Target locale: $target_locale"
    
    # Validate locale
    if ! validate_locale "$target_locale"; then
        log_error "Invalid locale: $target_locale"
        log_info "Attempting to generate locale..."
        generate_locale "$target_locale" || return 1
    fi
    
    # Set system locale
    set_system_locale "$target_locale"
    
    # Configure language settings
    configure_language_settings
    
    # Configure regional settings
    configure_regional_settings
    
    # Update font cache if needed
    update_font_cache
    
    log_success "Locale configuration completed"
}

get_current_locale() {
    local locale=""
    
    # Try LANG environment variable first
    if [[ -n "$LANG" ]]; then
        locale="$LANG"
    # Try locale command
    elif command -v locale &> /dev/null; then
        locale=$(locale | grep "^LANG=" | cut -d= -f2 | tr -d '"')
    fi
    
    # Fallback to C
    echo "${locale:-C}"
}

validate_locale() {
    local locale=$1
    
    case "$DOTFILES_OS" in
        linux)
            # Check if locale is available
            if locale -a 2>/dev/null | grep -q "^${locale}$"; then
                return 0
            fi
            ;;
        macos)
            # macOS locale validation
            if locale -a 2>/dev/null | grep -q "^${locale}$"; then
                return 0
            fi
            ;;
    esac
    
    return 1
}

generate_locale() {
    local locale=$1
    
    log_info "Generating locale: $locale"
    
    case "$DOTFILES_OS" in
        linux)
            generate_linux_locale "$locale"
            ;;
        macos)
            # macOS doesn't need locale generation
            log_debug "Locale generation not needed on macOS"
            return 0
            ;;
    esac
}

generate_linux_locale() {
    local locale=$1
    local locale_base="${locale%.*}"
    local charset="${locale#*.}"
    
    case "$DOTFILES_DISTRO" in
        ubuntu|debian)
            # Check if locale-gen is available
            if ! command -v locale-gen &> /dev/null; then
                install_package locales
            fi
            
            # Enable locale in /etc/locale.gen
            if [[ -f /etc/locale.gen ]]; then
                sudo sed -i "s/^# *${locale} /${locale} /" /etc/locale.gen
                
                # Also enable without space after #
                sudo sed -i "s/^#${locale} /${locale} /" /etc/locale.gen
            else
                # Create locale.gen if it doesn't exist
                echo "$locale UTF-8" | sudo tee /etc/locale.gen > /dev/null
            fi
            
            # Generate locales
            sudo locale-gen || {
                log_error "Failed to generate locale"
                return 1
            }
            ;;
            
        fedora|centos|rhel)
            # Install language pack
            local lang_pack="glibc-langpack-${locale_base%%_*}"
            install_package "$lang_pack" || {
                log_warn "Failed to install language pack: $lang_pack"
                # Try generic language pack
                install_package "glibc-all-langpacks"
            }
            ;;
            
        arch)
            # Enable locale in /etc/locale.gen
            sudo sed -i "s/^#${locale} /${locale} /" /etc/locale.gen
            
            # Generate locales
            sudo locale-gen || {
                log_error "Failed to generate locale"
                return 1
            }
            ;;
            
        *)
            log_warn "Locale generation not implemented for: $DOTFILES_DISTRO"
            return 1
            ;;
    esac
    
    # Verify locale was generated
    if validate_locale "$locale"; then
        log_success "Locale generated successfully"
        return 0
    else
        log_error "Failed to generate locale"
        return 1
    fi
}

set_system_locale() {
    local locale=$1
    
    log_info "Setting system locale to: $locale"
    
    case "$DOTFILES_OS" in
        linux)
            set_linux_locale "$locale"
            ;;
        macos)
            set_macos_locale "$locale"
            ;;
    esac
}

set_linux_locale() {
    local locale=$1
    
    # Method 1: Using localectl (systemd systems)
    if command -v localectl &> /dev/null; then
        sudo localectl set-locale LANG="$locale" || {
            log_warn "Failed to set locale using localectl"
        }
        
        # Also set other locale variables
        sudo localectl set-locale LC_ALL="$locale" 2>/dev/null || true
        
        log_debug "Locale set using localectl"
    fi
    
    # Method 2: Update /etc/locale.conf (systemd systems)
    if [[ -d /etc ]]; then
        cat << EOF | sudo tee /etc/locale.conf > /dev/null
LANG=$locale
LC_ALL=$locale
EOF
        log_debug "Updated /etc/locale.conf"
    fi
    
    # Method 3: Update /etc/default/locale (Debian/Ubuntu)
    if [[ -f /etc/default/locale ]] || [[ "$DOTFILES_DISTRO" == "ubuntu" ]] || [[ "$DOTFILES_DISTRO" == "debian" ]]; then
        cat << EOF | sudo tee /etc/default/locale > /dev/null
LANG="$locale"
LANGUAGE="$DEFAULT_LANGUAGE"
LC_ALL="$locale"
LC_CTYPE="$locale"
LC_NUMERIC="$locale"
LC_TIME="$locale"
LC_COLLATE="$locale"
LC_MONETARY="$locale"
LC_MESSAGES="$locale"
LC_PAPER="$locale"
LC_NAME="$locale"
LC_ADDRESS="$locale"
LC_TELEPHONE="$locale"
LC_MEASUREMENT="$locale"
LC_IDENTIFICATION="$locale"
EOF
        log_debug "Updated /etc/default/locale"
    fi
    
    # Method 4: Update /etc/environment
    if [[ -f /etc/environment ]]; then
        # Remove existing LANG and LC_ALL entries
        sudo sed -i '/^LANG=/d' /etc/environment
        sudo sed -i '/^LC_ALL=/d' /etc/environment
        
        # Add new entries
        echo "LANG=$locale" | sudo tee -a /etc/environment > /dev/null
        echo "LC_ALL=$locale" | sudo tee -a /etc/environment > /dev/null
        
        log_debug "Updated /etc/environment"
    fi
    
    # Export for current session
    export LANG="$locale"
    export LC_ALL="$locale"
}

set_macos_locale() {
    local locale=$1
    
    # macOS uses defaults command for locale settings
    # Set language and region preferences
    
    # Note: This requires logout/login to take full effect
    log_info "Setting macOS locale preferences..."
    
    # Set locale in user defaults
    defaults write -g AppleLocale -string "$locale"
    
    # Set languages
    defaults write -g AppleLanguages -array "en-US"
    
    # Export for current session
    export LANG="$locale"
    export LC_ALL="$locale"
    
    log_info "Locale preferences set. Restart required for full effect."
}

configure_language_settings() {
    log_info "Configuring language settings..."
    
    # Set LANGUAGE variable for message translations
    local language="${DOTFILES_LANGUAGE:-$DEFAULT_LANGUAGE}"
    
    # Update shell profile
    local profile_file="$HOME/.profile"
    local marker="# Dotfiles language configuration"
    
    if ! grep -q "$marker" "$profile_file" 2>/dev/null; then
        cat >> "$profile_file" << EOF

$marker
export LANGUAGE="$language"
EOF
        log_debug "Added language configuration to .profile"
    fi
}

configure_regional_settings() {
    log_info "Configuring regional settings..."
    
    case "$DOTFILES_OS" in
        linux)
            # Linux regional settings are handled by locale
            log_debug "Regional settings configured via locale"
            ;;
        macos)
            # Configure macOS regional settings
            configure_macos_regional
            ;;
    esac
}

configure_macos_regional() {
    # Set measurement units
    defaults write -g AppleMeasurementUnits -string "Centimeters"
    defaults write -g AppleMetricUnits -bool true
    
    # Set first day of week (1 = Monday)
    defaults write -g AppleFirstWeekday -dict gregorian 2
    
    # Set time format (24-hour)
    defaults write -g AppleICUForce24HourTime -bool true
    
    log_debug "macOS regional settings configured"
}

update_font_cache() {
    log_info "Updating font cache..."
    
    case "$DOTFILES_OS" in
        linux)
            if command -v fc-cache &> /dev/null; then
                fc-cache -f || {
                    log_warn "Failed to update font cache"
                }
                log_debug "Font cache updated"
            fi
            ;;
        macos)
            # macOS updates font cache automatically
            log_debug "Font cache managed by macOS"
            ;;
    esac
}

component_validate() {
    log_info "Validating locale configuration..."
    
    local validation_failed=0
    
    # Check current locale
    local current_locale=$(get_current_locale)
    if [[ "$current_locale" == "C" ]] || [[ "$current_locale" == "POSIX" ]]; then
        log_warn "System using basic C/POSIX locale"
    else
        log_debug "Current locale: $current_locale"
    fi
    
    # Validate locale command output
    if command -v locale &> /dev/null; then
        # Check for any unset locale variables
        if locale 2>&1 | grep -q "cannot set"; then
            log_warn "Some locale variables could not be set"
        fi
        
        # Check for UTF-8 support
        if ! locale charmap 2>/dev/null | grep -q "UTF-8"; then
            log_warn "UTF-8 character encoding not active"
        else
            log_debug "UTF-8 character encoding active"
        fi
    fi
    
    # Check environment variables
    if [[ -z "$LANG" ]]; then
        log_warn "LANG environment variable not set"
    fi
    
    # Platform-specific validation
    case "$DOTFILES_OS" in
        linux)
            # Check locale files
            if [[ -f /etc/locale.conf ]]; then
                log_debug "Found /etc/locale.conf"
            elif [[ -f /etc/default/locale ]]; then
                log_debug "Found /etc/default/locale"
            else
                log_warn "No system locale configuration file found"
            fi
            ;;
        macos)
            # Check macOS locale settings
            local apple_locale=$(defaults read -g AppleLocale 2>/dev/null)
            if [[ -n "$apple_locale" ]]; then
                log_debug "macOS locale: $apple_locale"
            fi
            ;;
    esac
    
    if [[ $validation_failed -eq 0 ]]; then
        log_success "Locale configuration validation passed"
        return 0
    else
        log_error "Locale configuration validation failed"
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