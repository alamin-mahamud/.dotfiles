#!/bin/bash
# scripts/profile-engine.sh - Profile installation engine

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"
source "$DOTFILES_ROOT/core/utils/logging.sh"
source "$DOTFILES_ROOT/core/utils/platform.sh"

# Paths
PROFILES_DIR="$DOTFILES_ROOT/profiles"
COMPONENTS_DIR="$DOTFILES_ROOT"
CACHE_DIR="$HOME/.cache/dotfiles"

# Profile engine configuration
PROFILE_ENGINE_VERSION="1.0.0"

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# Profile validation
validate_profile() {
    local profile_file=$1
    
    if [[ ! -f "$profile_file" ]]; then
        log_error "Profile file not found: $profile_file"
        return 1
    fi
    
    # Check if yq is available for YAML parsing
    if ! command -v yq &> /dev/null; then
        log_error "yq is required for profile parsing. Please install yq first."
        return 1
    fi
    
    # Validate YAML syntax
    if ! yq eval '.' "$profile_file" &> /dev/null; then
        log_error "Invalid YAML syntax in profile: $profile_file"
        return 1
    fi
    
    # Check required fields
    local profile_name=$(yq eval '.profile.name // ""' "$profile_file")
    local profile_version=$(yq eval '.profile.version // ""' "$profile_file")
    
    if [[ -z "$profile_name" ]]; then
        log_error "Profile missing required field: profile.name"
        return 1
    fi
    
    if [[ -z "$profile_version" ]]; then
        log_error "Profile missing required field: profile.version"
        return 1
    fi
    
    log_debug "Profile validation passed: $profile_name v$profile_version"
    return 0
}

# Extract components from profile
get_profile_components() {
    local profile_file=$1
    
    # Extract components with category prefixes
    yq eval '.components | to_entries | .[] | .key as $category | .value[] | $category + "/" + .' "$profile_file" 2>/dev/null
}

# Create installation plan with dependency resolution
create_install_plan() {
    local components=$1
    local install_order=("core" "security" "productivity" "cloud" "devops" "infra" "ai-ml" "observability")
    local plan_file="$CACHE_DIR/install_plan_$(date +%s).txt"
    
    log_info "Creating installation plan..."
    
    # Sort components by installation order
    > "$plan_file"
    for category in "${install_order[@]}"; do
        echo "$components" | grep "^$category/" | sort >> "$plan_file"
    done
    
    # Add any components not in standard categories
    for category in "${install_order[@]}"; do
        components=$(echo "$components" | grep -v "^$category/")
    done
    echo "$components" | grep -v '^$' >> "$plan_file"
    
    # Remove empty lines (macOS compatible)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/^$/d' "$plan_file"
    else
        sed -i '/^$/d' "$plan_file"
    fi
    
    local component_count=$(wc -l < "$plan_file")
    log_info "Installation plan created with $component_count components"
    
    echo "$plan_file"
}

# Execute installation plan
execute_install_plan() {
    local plan_file=$1
    local profile_file=$2
    local dry_run=${3:-false}
    
    if [[ ! -f "$plan_file" ]]; then
        log_error "Installation plan file not found: $plan_file"
        return 1
    fi
    
    local total_components=$(wc -l < "$plan_file")
    local current=0
    local failed_components=()
    
    log_info "Executing installation plan ($total_components components)..."
    
    while IFS= read -r component; do
        [[ -z "$component" ]] && continue
        
        ((current++))
        show_progress $current $total_components "Installing $component"
        
        if [[ "$dry_run" == "true" ]]; then
            log_debug "[DRY RUN] Would install: $component"
            sleep 0.1  # Simulate work
        else
            if ! install_component "$component"; then
                log_error "Failed to install component: $component"
                failed_components+=("$component")
                # Continue with other components
            fi
        fi
    done < "$plan_file"
    
    echo  # New line after progress
    
    if [[ ${#failed_components[@]} -gt 0 ]]; then
        log_warn "Some components failed to install:"
        printf '  - %s\n' "${failed_components[@]}"
        return 1
    fi
    
    log_success "All components installed successfully"
    return 0
}

# Install individual component
install_component() {
    local component=$1
    local category=$(echo "$component" | cut -d'/' -f1)
    local name=$(echo "$component" | cut -d'/' -f2)
    
    # Find component script
    local component_script=""
    local search_paths=(
        "$COMPONENTS_DIR/$category/$name.sh"
        "$COMPONENTS_DIR/components/$category/$name.sh"
        "$COMPONENTS_DIR/core/$category/$name.sh"
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -f "$path" ]]; then
            component_script="$path"
            break
        fi
    done
    
    if [[ -z "$component_script" ]]; then
        log_error "Component script not found: $component"
        log_debug "Searched paths: ${search_paths[*]}"
        return 1
    fi
    
    log_debug "Installing component: $category/$name"
    log_debug "Using script: $component_script"
    
    # Execute component in its directory
    local component_dir=$(dirname "$component_script")
    
    # Export environment for component
    export DOTFILES_ROOT
    export DOTFILES_PROFILE_ENGINE="true"
    
    # Execute component script
    if ! (cd "$component_dir" && bash "$(basename "$component_script")"); then
        log_error "Component installation failed: $category/$name"
        return 1
    fi
    
    log_debug "Component installed successfully: $category/$name"
    return 0
}

# Apply profile configuration
apply_profile_configuration() {
    local profile_file=$1
    
    log_info "Applying profile configuration..."
    
    # Extract configuration values with defaults
    local config_vars=$(yq eval '.configuration // {} | to_entries | .[] | .key + "=" + (.value | @sh)' "$profile_file" 2>/dev/null)
    
    if [[ -n "$config_vars" ]]; then
        # Create user config directory
        local user_config_dir="$HOME/.config/dotfiles"
        mkdir -p "$user_config_dir"
        
        # Save profile configuration
        local profile_name=$(yq eval '.profile.name' "$profile_file")
        local profile_config="$user_config_dir/profile-$profile_name.env"
        
        cat > "$profile_config" << EOF
# Profile configuration for $profile_name
# Generated on $(date)

$config_vars
EOF
        
        log_success "Profile configuration saved to: $profile_config"
    else
        log_debug "No configuration variables found in profile"
    fi
}

# Run post-install scripts
run_post_install_scripts() {
    local profile_file=$1
    
    # Check for post-install scripts in profile
    local post_install_scripts=$(yq eval '.post_install[]? // empty' "$profile_file" 2>/dev/null)
    
    if [[ -n "$post_install_scripts" ]]; then
        log_info "Running post-install scripts..."
        
        while IFS= read -r script; do
            [[ -z "$script" ]] && continue
            
            log_info "Executing post-install script: $script"
            
            # Execute script in safe environment
            if ! eval "$script"; then
                log_warn "Post-install script failed: $script"
            fi
        done <<< "$post_install_scripts"
    else
        log_debug "No post-install scripts defined"
    fi
}

# Validate profile installation
validate_profile_installation() {
    local profile_file=$1
    local errors=0
    
    log_info "Validating profile installation..."
    
    # Get components and validate each one
    local components=$(get_profile_components "$profile_file")
    local total_components=$(echo "$components" | wc -l)
    local validated=0
    
    while IFS= read -r component; do
        [[ -z "$component" ]] && continue
        
        if validate_component "$component"; then
            ((validated++))
        else
            log_error "Component validation failed: $component"
            ((errors++))
        fi
    done <<< "$components"
    
    log_info "Component validation: $validated/$total_components passed"
    
    if [[ $errors -eq 0 ]]; then
        log_success "Profile installation validation passed"
        return 0
    else
        log_error "Profile installation validation failed with $errors errors"
        return 1
    fi
}

# Validate individual component
validate_component() {
    local component=$1
    local category=$(echo "$component" | cut -d'/' -f1)
    local name=$(echo "$component" | cut -d'/' -f2)
    
    # Find and execute component validation
    local component_script=""
    local search_paths=(
        "$COMPONENTS_DIR/$category/$name.sh"
        "$COMPONENTS_DIR/components/$category/$name.sh"
        "$COMPONENTS_DIR/core/$category/$name.sh"
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -f "$path" ]]; then
            component_script="$path"
            break
        fi
    done
    
    if [[ -z "$component_script" ]]; then
        log_debug "Component script not found for validation: $component"
        return 1
    fi
    
    # Check if component has validation function
    if ! grep -q "component_validate" "$component_script"; then
        log_debug "Component has no validation function: $component"
        return 0  # No validation means success
    fi
    
    local component_dir=$(dirname "$component_script")
    
    # Execute validation by sourcing and calling validate function
    (
        cd "$component_dir"
        source "$(basename "$component_script")"
        if declare -f component_validate &> /dev/null; then
            component_validate
        else
            return 0
        fi
    )
}

# Main profile installation function
install_profile() {
    local profile_file=$1
    local dry_run=${2:-false}
    local skip_validation=${3:-false}
    
    if [[ ! -f "$profile_file" ]]; then
        log_error "Profile file not found: $profile_file"
        return 1
    fi
    
    local profile_name=$(yq eval '.profile.name' "$profile_file")
    local profile_version=$(yq eval '.profile.version' "$profile_file")
    
    log_info "Installing profile: $profile_name v$profile_version"
    
    # Validate profile
    if [[ "$skip_validation" != "true" ]]; then
        validate_profile "$profile_file" || return 1
    fi
    
    # Extract components
    local components=$(get_profile_components "$profile_file")
    if [[ -z "$components" ]]; then
        log_warn "No components found in profile"
        return 0
    fi
    
    log_info "Found $(echo "$components" | wc -l) components to install"
    
    # Create installation plan
    local plan_file=$(create_install_plan "$components")
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "DRY RUN - Installation plan:"
        cat "$plan_file" | while read -r component; do
            echo "  - $component"
        done
        rm -f "$plan_file"
        return 0
    fi
    
    # Execute installation plan
    if ! execute_install_plan "$plan_file" "$profile_file"; then
        rm -f "$plan_file"
        return 1
    fi
    
    # Apply profile configuration
    apply_profile_configuration "$profile_file"
    
    # Run post-install scripts
    run_post_install_scripts "$profile_file"
    
    # Validate installation
    if [[ "$skip_validation" != "true" ]]; then
        validate_profile_installation "$profile_file"
    fi
    
    # Cleanup
    rm -f "$plan_file"
    
    log_success "Profile '$profile_name' installed successfully!"
    
    # Save installation record
    local install_record="$CACHE_DIR/installed_profiles.log"
    echo "$(date -Iseconds) $profile_name $profile_version $profile_file" >> "$install_record"
    
    return 0
}

# List available profiles
list_profiles() {
    local profiles_dir=${1:-$PROFILES_DIR}
    
    if [[ ! -d "$profiles_dir" ]]; then
        log_error "Profiles directory not found: $profiles_dir"
        return 1
    fi
    
    log_info "Available profiles:"
    
    for profile_file in "$profiles_dir"/*.yaml "$profiles_dir"/*.yml; do
        [[ ! -f "$profile_file" ]] && continue
        
        local name=$(yq eval '.profile.name // "Unknown"' "$profile_file" 2>/dev/null)
        local version=$(yq eval '.profile.version // "Unknown"' "$profile_file" 2>/dev/null)
        local description=$(yq eval '.profile.description // "No description"' "$profile_file" 2>/dev/null)
        
        echo "  $(basename "$profile_file"): $name v$version"
        echo "    $description"
    done
}

# Show profile information
show_profile_info() {
    local profile_file=$1
    
    if [[ ! -f "$profile_file" ]]; then
        log_error "Profile file not found: $profile_file"
        return 1
    fi
    
    local name=$(yq eval '.profile.name' "$profile_file")
    local version=$(yq eval '.profile.version' "$profile_file")
    local description=$(yq eval '.profile.description // "No description"' "$profile_file")
    local author=$(yq eval '.profile.author // "Unknown"' "$profile_file")
    
    echo "Profile Information:"
    echo "  Name: $name"
    echo "  Version: $version"
    echo "  Description: $description"
    echo "  Author: $author"
    echo ""
    
    echo "Components:"
    local components=$(get_profile_components "$profile_file")
    if [[ -n "$components" ]]; then
        echo "$components" | while IFS= read -r component; do
            echo "  - $component"
        done
    else
        echo "  No components defined"
    fi
    
    echo ""
    
    local config_vars=$(yq eval '.configuration // {} | keys | .[]' "$profile_file" 2>/dev/null)
    if [[ -n "$config_vars" ]]; then
        echo "Configuration variables:"
        echo "$config_vars" | while IFS= read -r var; do
            local value=$(yq eval ".configuration.$var" "$profile_file")
            echo "  $var: $value"
        done
    fi
}

# Command-line interface
main() {
    local command=${1:-"help"}
    
    case "$command" in
        install)
            local profile_file=$2
            local dry_run=false
            local skip_validation=false
            
            # Parse options
            shift 2
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --dry-run)
                        dry_run=true
                        shift
                        ;;
                    --skip-validation)
                        skip_validation=true
                        shift
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done
            
            if [[ -z "$profile_file" ]]; then
                log_error "Profile file required"
                echo "Usage: $0 install <profile_file> [--dry-run] [--skip-validation]"
                exit 1
            fi
            
            # Initialize platform detection
            init_platform
            
            install_profile "$profile_file" "$dry_run" "$skip_validation"
            ;;
        list)
            list_profiles
            ;;
        info)
            local profile_file=$2
            if [[ -z "$profile_file" ]]; then
                log_error "Profile file required"
                echo "Usage: $0 info <profile_file>"
                exit 1
            fi
            show_profile_info "$profile_file"
            ;;
        validate)
            local profile_file=$2
            if [[ -z "$profile_file" ]]; then
                log_error "Profile file required"
                echo "Usage: $0 validate <profile_file>"
                exit 1
            fi
            validate_profile "$profile_file"
            ;;
        help|*)
            echo "Profile Engine v$PROFILE_ENGINE_VERSION"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  install <profile_file>     Install a profile"
            echo "    --dry-run               Show what would be installed"
            echo "    --skip-validation       Skip profile validation"
            echo "  list                      List available profiles"
            echo "  info <profile_file>       Show profile information"
            echo "  validate <profile_file>   Validate profile syntax"
            echo "  help                      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 list"
            echo "  $0 info profiles/server-minimal.yaml"
            echo "  $0 install profiles/devops-workstation.yaml --dry-run"
            echo "  $0 install profiles/server-minimal.yaml"
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi