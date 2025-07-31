#!/bin/bash
# core/utils/component.sh - Component framework base class

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/platform.sh"

# Component metadata
declare -A COMPONENT_META
COMPONENT_META[name]=""
COMPONENT_META[description]=""
COMPONENT_META[version]=""
COMPONENT_META[dependencies]=""
COMPONENT_META[conflicts]=""
COMPONENT_META[platforms]=""
COMPONENT_META[category]=""

# Component state management
COMPONENT_STATE_DIR="${HOME}/.config/dotfiles/components"
mkdir -p "$COMPONENT_STATE_DIR"

# Component lifecycle hooks
component_pre_install() {
    log_debug "Pre-install hook for ${COMPONENT_META[name]}"
    return 0
}

component_install() {
    log_error "Install method must be implemented by component: ${COMPONENT_META[name]}"
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

component_update() {
    log_debug "Update hook for ${COMPONENT_META[name]} - running install"
    component_install
}

# Component metadata validation
validate_component_metadata() {
    local errors=0
    
    if [[ -z "${COMPONENT_META[name]}" ]]; then
        log_error "Component name is required"
        ((errors++))
    fi
    
    if [[ -z "${COMPONENT_META[description]}" ]]; then
        log_error "Component description is required"
        ((errors++))
    fi
    
    if [[ -z "${COMPONENT_META[version]}" ]]; then
        log_error "Component version is required"
        ((errors++))
    fi
    
    return $errors
}

# Platform compatibility check
is_platform_supported() {
    local supported_platforms=${COMPONENT_META[platforms]}
    
    # If platforms is empty, assume all platforms are supported
    [[ -z "$supported_platforms" ]] && return 0
    
    # Check if current platform is in supported list
    [[ "$supported_platforms" =~ $DOTFILES_OS ]]
}

# Dependency checking
check_dependencies() {
    local dependencies=${COMPONENT_META[dependencies]}
    [[ -z "$dependencies" ]] && return 0
    
    local missing_deps=()
    local dep
    
    # Convert space-separated dependencies to array
    IFS=' ' read -ra deps <<< "$dependencies"
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null && ! is_package_installed "$dep"; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies for ${COMPONENT_META[name]}: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# Conflict checking
check_conflicts() {
    local conflicts=${COMPONENT_META[conflicts]}
    [[ -z "$conflicts" ]] && return 0
    
    local conflicting=()
    local conflict
    
    # Convert space-separated conflicts to array
    IFS=' ' read -ra conflict_list <<< "$conflicts"
    
    for conflict in "${conflict_list[@]}"; do
        if command -v "$conflict" &> /dev/null || is_package_installed "$conflict"; then
            conflicting+=("$conflict")
        fi
    done
    
    if [[ ${#conflicting[@]} -gt 0 ]]; then
        log_error "Conflicting packages found for ${COMPONENT_META[name]}: ${conflicting[*]}"
        return 1
    fi
    
    return 0
}

# Component state management
mark_component_installed() {
    local component_name=${COMPONENT_META[name]}
    local state_file="$COMPONENT_STATE_DIR/$component_name.state"
    
    cat > "$state_file" <<EOF
name=${COMPONENT_META[name]}
description=${COMPONENT_META[description]}
version=${COMPONENT_META[version]}
category=${COMPONENT_META[category]}
installed_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
platform=$DOTFILES_OS
environment=$DOTFILES_ENV
EOF
    
    log_debug "Component state recorded: $state_file"
}

mark_component_uninstalled() {
    local component_name=${COMPONENT_META[name]}
    local state_file="$COMPONENT_STATE_DIR/$component_name.state"
    
    if [[ -f "$state_file" ]]; then
        rm "$state_file"
        log_debug "Component state removed: $state_file"
    fi
}

is_component_installed() {
    local component_name=${1:-${COMPONENT_META[name]}}
    local state_file="$COMPONENT_STATE_DIR/$component_name.state"
    
    [[ -f "$state_file" ]]
}

get_component_info() {
    local component_name=${1:-${COMPONENT_META[name]}}
    local state_file="$COMPONENT_STATE_DIR/$component_name.state"
    
    if [[ -f "$state_file" ]]; then
        cat "$state_file"
    else
        return 1
    fi
}

# Component execution with error handling
run_component() {
    local component_name=${COMPONENT_META[name]}
    local start_time=$(date +%s)
    
    # Validate metadata
    if ! validate_component_metadata; then
        log_error "Component metadata validation failed for $component_name"
        return 1
    fi
    
    log_banner "Installing Component: $component_name"
    
    # Check if already installed
    if is_component_installed; then
        log_info "Component $component_name is already installed"
        if [[ "${FORCE_REINSTALL:-false}" == "true" ]]; then
            log_info "Force reinstall enabled, proceeding..."
        else
            log_info "Skipping installation. Use FORCE_REINSTALL=true to reinstall."
            return 0
        fi
    fi
    
    # Check platform compatibility
    if ! is_platform_supported; then
        log_warn "Component $component_name not supported on $DOTFILES_OS/$DOTFILES_ENV"
        return 0
    fi
    
    # Check system requirements if specified
    if [[ -n "${COMPONENT_META[min_memory_gb]}" ]] || [[ -n "${COMPONENT_META[min_disk_gb]}" ]]; then
        check_system_requirements "${COMPONENT_META[min_memory_gb]}" "${COMPONENT_META[min_disk_gb]}" || {
            log_error "System requirements not met for $component_name"
            return 1
        }
    fi
    
    # Check dependencies
    if ! check_dependencies; then
        log_error "Dependencies not met for $component_name"
        return 1
    fi
    
    # Check conflicts
    if ! check_conflicts; then
        log_error "Conflicts detected for $component_name"
        return 1
    fi
    
    # Execute component lifecycle
    local lifecycle_error=0
    
    # Pre-install hook
    log_info "Running pre-install for $component_name..."
    if ! component_pre_install; then
        log_error "Pre-install failed for $component_name"
        lifecycle_error=1
    fi
    
    # Main install
    if [[ $lifecycle_error -eq 0 ]]; then
        log_info "Installing $component_name..."
        if ! component_install; then
            log_error "Installation failed for $component_name"
            lifecycle_error=1
        fi
    fi
    
    # Post-install hook
    if [[ $lifecycle_error -eq 0 ]]; then
        log_info "Running post-install for $component_name..."
        if ! component_post_install; then
            log_error "Post-install failed for $component_name"
            lifecycle_error=1
        fi
    fi
    
    # Validation
    if [[ $lifecycle_error -eq 0 ]]; then
        log_info "Validating $component_name installation..."
        if ! component_validate; then
            log_error "Validation failed for $component_name"
            lifecycle_error=1
        fi
    fi
    
    # Record success/failure
    if [[ $lifecycle_error -eq 0 ]]; then
        mark_component_installed
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "Component $component_name installed successfully in ${duration}s"
        return 0
    else
        log_error "Component $component_name installation failed"
        return 1
    fi
}

# Component uninstallation
uninstall_component() {
    local component_name=${COMPONENT_META[name]}
    
    if ! is_component_installed; then
        log_warn "Component $component_name is not installed"
        return 0
    fi
    
    log_info "Uninstalling component: $component_name"
    
    if component_uninstall; then
        mark_component_uninstalled
        log_success "Component $component_name uninstalled successfully"
        return 0
    else
        log_error "Failed to uninstall component: $component_name"
        return 1
    fi
}

# Dry run mode
run_component_dry() {
    local component_name=${COMPONENT_META[name]}
    
    log_banner "DRY RUN: Component Analysis for $component_name"
    
    echo "Component: ${COMPONENT_META[name]}"
    echo "Description: ${COMPONENT_META[description]}"
    echo "Version: ${COMPONENT_META[version]}"
    echo "Category: ${COMPONENT_META[category]}"
    echo "Platforms: ${COMPONENT_META[platforms]:-all}"
    echo "Dependencies: ${COMPONENT_META[dependencies]:-none}"
    echo "Conflicts: ${COMPONENT_META[conflicts]:-none}"
    echo ""
    
    echo "Platform Check:"
    if is_platform_supported; then
        echo "  ✅ Supported on $DOTFILES_OS/$DOTFILES_ENV"
    else
        echo "  ❌ Not supported on $DOTFILES_OS/$DOTFILES_ENV"
        return 0
    fi
    
    echo "Dependency Check:"
    if check_dependencies; then
        echo "  ✅ All dependencies available"
    else
        echo "  ❌ Missing dependencies"
    fi
    
    echo "Conflict Check:"
    if check_conflicts; then
        echo "  ✅ No conflicts detected"
    else
        echo "  ❌ Conflicts detected"
    fi
    
    echo "Installation Status:"
    if is_component_installed; then
        echo "  ℹ️  Already installed"
    else
        echo "  📦 Ready for installation"
    fi
}

# Help and information functions
show_component_help() {
    cat <<EOF
Component Framework Usage:

Available functions:
  run_component        - Install the component
  uninstall_component  - Remove the component
  run_component_dry    - Dry run analysis
  is_component_installed - Check installation status
  get_component_info   - Get component information

Environment variables:
  FORCE_REINSTALL=true - Force reinstall even if already installed
  LOG_LEVEL=0-4        - Set logging verbosity

Component metadata should be set in the component script:
  COMPONENT_META[name]="component-name"
  COMPONENT_META[description]="Component description"
  COMPONENT_META[version]="1.0.0"
  COMPONENT_META[dependencies]="curl git"
  COMPONENT_META[platforms]="linux macos"
  COMPONENT_META[category]="productivity"
EOF
}

# Export functions for use in component scripts
export -f run_component uninstall_component run_component_dry
export -f is_component_installed get_component_info mark_component_installed
export -f check_dependencies check_conflicts is_platform_supported
export -f component_pre_install component_install component_post_install
export -f component_validate component_uninstall component_update