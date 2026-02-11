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

# config.sh - Configuration file manipulation functions
# NOTE: Reference implementation - agents follow SKILL.md instructions inline

# Source common functions (if not already sourced)
if ! type -t log_info >/dev/null 2>&1; then
    LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${LIB_DIR}/common.sh"
fi

# Merge dosu MCP configuration into OpenCode config
# Args:
#   $1 - config file path
#   $2 - username
# Returns: 0 on success, 1 if already exists, 2 on error
merge_dosu_mcp() {
    local config_path="$1"
    local username="$2"
    
    # Check if dosu already exists
    if jq -e '.mcp.dosu' "$config_path" >/dev/null 2>&1; then
        log_warn "dosu MCP already configured, skipping..."
        return 1
    fi
    
    # Merge dosu configuration
    local temp_file="${config_path}.tmp"
    if jq '.mcp.dosu = {
        "type": "remote",
        "url": "https://api.dosu.dev/v1/mcp",
        "headers": {
            "X-Deployment-ID": "83775020-c22e-485a-a222-987b2f5a3823"
        }
    }' "$config_path" > "$temp_file"; then
        mv "$temp_file" "$config_path"
        log_success "Added dosu MCP configuration"
        return 0
    else
        log_error "Failed to merge dosu MCP configuration"
        rm -f "$temp_file"
        return 2
    fi
}

# Merge linux-mcp-server configuration into OpenCode config
# Args:
#   $1 - config file path
#   $2 - username
# Returns: 0 on success, 1 if already exists, 2 on error
merge_linux_mcp() {
    local config_path="$1"
    local username="$2"
    
    # Check if linux-mcp-server already exists
    if jq -e '.mcp."linux-mcp-server"' "$config_path" >/dev/null 2>&1; then
        log_warn "linux-mcp-server already configured, skipping..."
        return 1
    fi
    
    # Merge linux-mcp-server configuration
    local temp_file="${config_path}.tmp"
    if jq --arg user "$username" '.mcp."linux-mcp-server" = {
        "type": "stdio",
        "command": "/home/linuxbrew/.linuxbrew/bin/linux-mcp-server",
        "env": {
            "LINUX_MCP_USER": $user
        }
    }' "$config_path" > "$temp_file"; then
        mv "$temp_file" "$config_path"
        log_success "Added linux-mcp-server configuration (user: $username)"
        return 0
    else
        log_error "Failed to merge linux-mcp-server configuration"
        rm -f "$temp_file"
        return 2
    fi
}

# Merge linux-mcp-server extension into Goose config
# Args:
#   $1 - config file path
#   $2 - username
# Returns: 0 on success, 1 if already exists, 2 on error
merge_goose_linux_mcp() {
    local config_path="$1"
    local username="$2"
    
    # Check if linux-mcp-server extension already exists
    if yq eval '.extensions[] | select(.name == "linux-mcp-server")' "$config_path" 2>/dev/null | grep -q linux-mcp-server; then
        log_warn "linux-mcp-server extension already configured, skipping..."
        return 1
    fi
    
    # Merge linux-mcp-server extension
    local temp_file="${config_path}.tmp"
    if yq eval ".extensions += [{
        \"name\": \"linux-mcp-server\",
        \"type\": \"stdio\",
        \"command\": \"/home/linuxbrew/.linuxbrew/bin/linux-mcp-server\",
        \"env\": {
            \"LINUX_MCP_USER\": \"$username\"
        }
    }]" "$config_path" > "$temp_file"; then
        mv "$temp_file" "$config_path"
        log_success "Added linux-mcp-server extension (user: $username)"
        return 0
    else
        log_error "Failed to merge linux-mcp-server extension"
        rm -f "$temp_file"
        return 2
    fi
}

# Validate JSON file syntax
# Args:
#   $1 - JSON file path
# Returns: 0 if valid, 1 if invalid
validate_json() {
    local file_path="$1"
    
    if jq empty "$file_path" 2>/dev/null; then
        log_success "JSON validation passed: $file_path"
        return 0
    else
        log_error "JSON validation failed: $file_path"
        return 1
    fi
}

# Validate YAML file syntax
# Args:
#   $1 - YAML file path
# Returns: 0 if valid, 1 if invalid
validate_yaml() {
    local file_path="$1"
    
    if yq eval '.' "$file_path" >/dev/null 2>&1; then
        log_success "YAML validation passed: $file_path"
        return 0
    else
        log_error "YAML validation failed: $file_path"
        return 1
    fi
}

# Create default OpenCode config if none exists
# Args:
#   $1 - config file path
# Returns: 0 on success, 1 on failure
create_default_opencode_config() {
    local config_path="$1"
    local config_dir
    config_dir=$(dirname "$config_path")
    
    # Create config directory if needed
    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir" || return 1
    fi
    
    # Create minimal config
    echo '{"mcp":{}}' | jq '.' > "$config_path"
    log_info "Created default OpenCode config: $config_path"
    return 0
}

# Create default Goose config if none exists
# Args:
#   $1 - config file path
# Returns: 0 on success, 1 on failure
create_default_goose_config() {
    local config_path="$1"
    local config_dir
    config_dir=$(dirname "$config_path")
    
    # Create config directory if needed
    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir" || return 1
    fi
    
    # Create minimal config
    echo 'extensions: []' > "$config_path"
    log_info "Created default Goose config: $config_path"
    return 0
}
