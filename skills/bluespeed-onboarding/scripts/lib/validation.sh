#!/usr/bin/env bash
# Copyright 2026 Jorge Castro
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# validation.sh - Prerequisite validation functions
# NOTE: Reference implementation - agents follow SKILL.md instructions inline

# Source common functions (if not already sourced)
if ! type -t log_info >/dev/null 2>&1; then
    LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${LIB_DIR}/common.sh"
fi

# Check if a Homebrew package is installed
# Args:
#   $1 - package name (formula or cask)
# Returns: 0 if installed, 1 if not
check_brew_package() {
    local package="$1"
    
    # Check formulas
    if brew list "$package" &>/dev/null; then
        return 0
    fi
    
    # Check casks
    if brew list --cask "$package" &>/dev/null; then
        return 0
    fi
    
    return 1
}

# Check if a command exists in PATH
# Args:
#   $1 - command name
# Returns: 0 if exists, 1 if not
check_command_exists() {
    local command="$1"
    
    if command -v "$command" &>/dev/null; then
        return 0
    fi
    
    return 1
}

# Check if a file or directory exists
# Args:
#   $1 - file/directory path
# Returns: 0 if exists, 1 if not
check_file_exists() {
    local path="$1"
    
    if [[ -e "$path" ]]; then
        return 0
    fi
    
    return 1
}

# Validate generic prerequisites (brew, jq, yq)
# Returns: 0 if all prerequisites met, 1 if any missing
validate_prerequisites() {
    local missing=0
    
    log_info "Validating generic prerequisites..."
    
    # Check Homebrew
    if ! check_command_exists brew; then
        log_error "Homebrew is not installed. Install from: https://brew.sh"
        missing=1
    else
        log_success "Homebrew is installed"
    fi
    
    # Check jq
    if ! check_command_exists jq; then
        log_error "jq is not installed. Install with: brew install jq"
        missing=1
    else
        log_success "jq is installed"
    fi
    
    # Check yq
    if ! check_command_exists yq; then
        log_error "yq is not installed. Install with: brew install yq"
        missing=1
    else
        log_success "yq is installed"
    fi
    
    if [[ $missing -eq 1 ]]; then
        log_error "Some prerequisites are missing. Please install them and try again."
        return 1
    fi
    
    log_success "All generic prerequisites are met"
    return 0
}

# Validate OpenCode-specific prerequisites
# Returns: 0 if all prerequisites met, 1 if any missing
validate_opencode_prerequisites() {
    local missing=0
    
    log_info "Validating OpenCode prerequisites..."
    
    # Check generic prerequisites first
    if ! validate_prerequisites; then
        return 1
    fi
    
    # Check linux-mcp-server
    if ! check_file_exists /home/linuxbrew/.linuxbrew/bin/linux-mcp-server; then
        log_error "linux-mcp-server is not installed. Install with: brew install ublue-os/tap/linux-mcp-server"
        missing=1
    else
        log_success "linux-mcp-server is installed"
    fi
    
    if [[ $missing -eq 1 ]]; then
        log_error "Some OpenCode prerequisites are missing. Please install them and try again."
        return 1
    fi
    
    log_success "All OpenCode prerequisites are met"
    return 0
}

# Validate Goose-specific prerequisites
# Returns: 0 if all prerequisites met, 1 if any missing
validate_goose_prerequisites() {
    local missing=0
    
    log_info "Validating Goose prerequisites..."
    
    # Check generic prerequisites first
    if ! validate_prerequisites; then
        return 1
    fi
    
    # Check linux-mcp-server
    if ! check_file_exists /home/linuxbrew/.linuxbrew/bin/linux-mcp-server; then
        log_error "linux-mcp-server is not installed. Install with: brew install ublue-os/tap/linux-mcp-server"
        missing=1
    else
        log_success "linux-mcp-server is installed"
    fi
    
    if [[ $missing -eq 1 ]]; then
        log_error "Some Goose prerequisites are missing. Please install them and try again."
        return 1
    fi
    
    log_success "All Goose prerequisites are met"
    return 0
}
