#!/bin/bash
# core/utils/validation.sh - Profile and component validation utilities

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/platform.sh"

# Profile validation
validate_profile() {
    local profile_file=$1
    
    if [[ ! -f "$profile_file" ]]; then
        log_error "Profile file not found: $profile_file"
        return 1
    fi
    
    log_info "Validating profile: $(basename "$profile_file")"
    
    # Check if yq is available for YAML processing
    if ! command -v yq &> /dev/null; then
        log_error "yq is required for profile validation but not found"
        log_info "Please install yq: https://github.com/mikefarah/yq"
        return 1
    fi
    
    # Basic YAML syntax validation
    if ! yq eval '.' "$profile_file" > /dev/null 2>&1; then
        log_error "Invalid YAML syntax in profile file"
        return 1
    fi
    
    # Validate required fields
    local errors=0
    
    # Check profile metadata
    if ! validate_profile_metadata "$profile_file"; then
        ((errors++))
    fi
    
    # Check components section
    if ! validate_profile_components "$profile_file"; then
        ((errors++))
    fi
    
    # Check configuration section
    if ! validate_profile_configuration "$profile_file"; then
        ((errors++))
    fi
    
    # Check requirements
    if ! validate_profile_requirements "$profile_file"; then
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "Profile validation passed"
        return 0
    else
        log_error "Profile validation failed with $errors errors"
        return 1
    fi
}

validate_profile_metadata() {
    local profile_file=$1
    local errors=0
    
    # Check required profile fields
    local name=$(yq eval '.profile.name' "$profile_file")
    local description=$(yq eval '.profile.description' "$profile_file")
    local version=$(yq eval '.profile.version' "$profile_file")
    
    if [[ "$name" == "null" || -z "$name" ]]; then
        log_error "Profile name is required"
        ((errors++))
    elif [[ ! "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9-_]*$ ]]; then
        log_error "Invalid profile name format: $name"
        ((errors++))
    fi
    
    if [[ "$description" == "null" || -z "$description" ]]; then
        log_error "Profile description is required"
        ((errors++))
    elif [[ ${#description} -lt 10 ]]; then
        log_error "Profile description too short (minimum 10 characters)"
        ((errors++))
    fi
    
    if [[ "$version" == "null" || -z "$version" ]]; then
        log_error "Profile version is required"  
        ((errors++))
    elif [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid version format: $version (expected: X.Y.Z)"
        ((errors++))
    fi
    
    # Check optional target_os
    local target_os=$(yq eval '.profile.target_os[]?' "$profile_file" 2>/dev/null)
    if [[ -n "$target_os" ]]; then
        while IFS= read -r os; do
            if [[ "$os" != "linux" && "$os" != "macos" && "$os" != "windows" ]]; then
                log_error "Invalid target OS: $os"
                ((errors++))
            fi
        done <<< "$target_os"
    fi
    
    return $errors
}

validate_profile_components() {
    local profile_file=$1
    local errors=0
    
    # Check if components section exists
    if ! yq eval '.components' "$profile_file" > /dev/null 2>&1; then
        log_error "Components section is required"
        return 1
    fi
    
    # Valid component categories
    local valid_categories=("core" "cloud" "devops" "ai_ml" "observability" "productivity" "security")
    
    # Get all component categories in the profile
    local categories=$(yq eval '.components | keys | .[]' "$profile_file" 2>/dev/null)
    
    while IFS= read -r category; do
        if [[ -n "$category" ]]; then
            # Check if category is valid
            local valid=false
            for valid_cat in "${valid_categories[@]}"; do
                if [[ "$category" == "$valid_cat" ]]; then
                    valid=true
                    break
                fi
            done
            
            if [[ "$valid" == "false" ]]; then
                log_error "Invalid component category: $category"
                ((errors++))
            fi
            
            # Validate component names in this category
            local components=$(yq eval ".components.${category}[]?" "$profile_file" 2>/dev/null)
            while IFS= read -r component; do
                if [[ -n "$component" ]]; then
                    if [[ ! "$component" =~ ^[a-zA-Z0-9][a-zA-Z0-9-_]*$ ]]; then
                        log_error "Invalid component name format: $component"
                        ((errors++))
                    fi
                fi
            done <<< "$components"
        fi
    done <<< "$categories"
    
    return $errors
}

validate_profile_configuration() {
    local profile_file=$1
    local errors=0
    
    # Configuration section is optional, but if present, validate it
    if yq eval '.configuration' "$profile_file" > /dev/null 2>&1; then
        # Validate timezone
        local timezone=$(yq eval '.configuration.timezone // "UTC"' "$profile_file")
        if [[ -n "$timezone" && "$timezone" != "null" ]]; then
            # Basic timezone validation (could be more comprehensive)
            if [[ ! "$timezone" =~ ^[A-Za-z_/]+$ ]]; then
                log_error "Invalid timezone format: $timezone"
                ((errors++))
            fi
        fi
        
        # Validate locale
        local locale=$(yq eval '.configuration.locale // "en_US.UTF-8"' "$profile_file")
        if [[ -n "$locale" && "$locale" != "null" ]]; then
            if [[ ! "$locale" =~ ^[a-zA-Z]{2}_[A-Z]{2}\.(UTF-8|utf8)$ ]]; then
                log_error "Invalid locale format: $locale"
                ((errors++))
            fi
        fi
        
        # Validate shell
        local shell=$(yq eval '.configuration.shell // "zsh"' "$profile_file")
        if [[ -n "$shell" && "$shell" != "null" ]]; then
            local valid_shells=("bash" "zsh" "fish")
            local valid=false
            for valid_shell in "${valid_shells[@]}"; do
                if [[ "$shell" == "$valid_shell" ]]; then
                    valid=true
                    break
                fi
            done
            if [[ "$valid" == "false" ]]; then
                log_error "Invalid shell: $shell"
                ((errors++))
            fi
        fi
        
        # Validate editor
        local editor=$(yq eval '.configuration.editor // "vim"' "$profile_file")
        if [[ -n "$editor" && "$editor" != "null" ]]; then
            local valid_editors=("vim" "nvim" "nano" "emacs" "code")
            local valid=false
            for valid_editor in "${valid_editors[@]}"; do
                if [[ "$editor" == "$valid_editor" ]]; then
                    valid=true
                    break
                fi
            done
            if [[ "$valid" == "false" ]]; then
                log_error "Invalid editor: $editor"
                ((errors++))
            fi
        fi
    fi
    
    return $errors
}

validate_profile_requirements() {
    local profile_file=$1
    local errors=0
    
    # Requirements section is optional
    if yq eval '.requirements' "$profile_file" > /dev/null 2>&1; then
        # Validate memory requirements
        local min_memory=$(yq eval '.requirements.min_memory_gb // null' "$profile_file")
        if [[ "$min_memory" != "null" && -n "$min_memory" ]]; then
            if ! [[ "$min_memory" =~ ^[0-9]+$ ]] || [[ $min_memory -lt 1 ]] || [[ $min_memory -gt 1024 ]]; then
                log_error "Invalid min_memory_gb: $min_memory (must be 1-1024)"
                ((errors++))
            fi
        fi
        
        # Validate disk requirements
        local min_disk=$(yq eval '.requirements.min_disk_gb // null' "$profile_file")
        if [[ "$min_disk" != "null" && -n "$min_disk" ]]; then
            if ! [[ "$min_disk" =~ ^[0-9]+$ ]] || [[ $min_disk -lt 1 ]] || [[ $min_disk -gt 10240 ]]; then
                log_error "Invalid min_disk_gb: $min_disk (must be 1-10240)"
                ((errors++))
            fi
        fi
        
        # Validate boolean fields
        local network_required=$(yq eval '.requirements.network_required // null' "$profile_file")
        if [[ "$network_required" != "null" && "$network_required" != "true" && "$network_required" != "false" ]]; then
            log_error "Invalid network_required: $network_required (must be true or false)"
            ((errors++))
        fi
        
        local sudo_required=$(yq eval '.requirements.sudo_required // null' "$profile_file")
        if [[ "$sudo_required" != "null" && "$sudo_required" != "true" && "$sudo_required" != "false" ]]; then
            log_error "Invalid sudo_required: $sudo_required (must be true or false)"
            ((errors++))
        fi
    fi
    
    return $errors
}

# Component existence validation
validate_component_exists() {
    local category=$1
    local component=$2
    local components_dir="${DOTFILES_ROOT:-$(pwd)}/components"
    
    local component_script="$components_dir/$category/$component.sh"
    
    if [[ ! -f "$component_script" ]]; then
        log_error "Component script not found: $component_script"
        return 1
    fi
    
    return 0
}

# Profile components existence check
validate_profile_components_exist() {
    local profile_file=$1
    local errors=0
    
    # Get all components from the profile
    local categories=$(yq eval '.components | keys | .[]' "$profile_file" 2>/dev/null)
    
    while IFS= read -r category; do
        if [[ -n "$category" ]]; then
            local components=$(yq eval ".components.${category}[]?" "$profile_file" 2>/dev/null)
            while IFS= read -r component; do
                if [[ -n "$component" ]]; then
                    if ! validate_component_exists "$category" "$component"; then
                        ((errors++))
                    fi
                fi
            done <<< "$components"
        fi
    done <<< "$categories"
    
    return $errors
}

# Full profile validation including component existence
validate_profile_full() {
    local profile_file=$1
    
    log_info "Running full profile validation: $(basename "$profile_file")"
    
    # Basic profile validation
    if ! validate_profile "$profile_file"; then
        return 1
    fi
    
    # Component existence validation
    if ! validate_profile_components_exist "$profile_file"; then
        log_error "Some components referenced in profile do not exist"
        return 1
    fi
    
    log_success "Full profile validation passed"
    return 0
}

# Batch validation for multiple profiles
validate_all_profiles() {
    local profiles_dir=${1:-"profiles/official"}
    local errors=0
    
    log_banner "Validating All Profiles in $profiles_dir"
    
    if [[ ! -d "$profiles_dir" ]]; then
        log_error "Profiles directory not found: $profiles_dir"
        return 1
    fi
    
    # Find all YAML files
    while IFS= read -r -d '' profile_file; do
        if ! validate_profile_full "$profile_file"; then
            log_error "Validation failed for: $(basename "$profile_file")"
            ((errors++))
        else
            log_success "Validation passed for: $(basename "$profile_file")"
        fi
        echo
    done < <(find "$profiles_dir" -name "*.yaml" -print0)
    
    if [[ $errors -eq 0 ]]; then
        log_success "All profiles validated successfully"
        return 0
    else
        log_error "Profile validation failed for $errors profiles"
        return 1
    fi
}

# Export functions
export -f validate_profile validate_profile_full validate_all_profiles
export -f validate_component_exists validate_profile_components_exist