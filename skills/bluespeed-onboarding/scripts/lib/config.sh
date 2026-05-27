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
    if jq -e '.mcp."linux_mcp_server"' "$config_path" >/dev/null 2>&1; then
        log_warn "linux-mcp-server already configured, skipping..."
        return 1
    fi
    
    # Merge linux-mcp-server configuration
    local temp_file="${config_path}.tmp"
    if jq --arg user "$username" '.mcp."linux_mcp_server" = {
        "type": "local",
        "command": ["/usr/bin/env", "LINUX_MCP_USER=" + $user, "/home/linuxbrew/.linuxbrew/bin/linux-mcp-server"],
        "enabled": true
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
    if yq eval '.extensions."linux_mcp_server"' "$config_path" 2>/dev/null | grep -q -v "null"; then
        log_warn "linux-mcp-server extension already configured, skipping..."
        return 1
    fi
    
    # Merge linux-mcp-server extension as a map key (not a list item)
    local temp_file="${config_path}.tmp"
    if yq eval '.extensions."linux_mcp_server" = {
        "enabled": true,
        "type": "local",
        "name": "linux_mcp_server",
        "description": "Linux system diagnostics and maintenance tools",
        "command": "/home/linuxbrew/.linuxbrew/bin/linux-mcp-server",
        "env": {
            "LINUX_MCP_USER": "'"$username"'"
        },
        "bundled": false,
        "available_tools": []
    }' "$config_path" > "$temp_file"; then
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

# Merge dosu and linux-mcp-server into VS Code/Antigravity settings.json
# Args:
#   $1 - config file path (settings.json)
#   $2 - username
# Returns: 0 on success, 1 if already exists, 2 on error
merge_vscode_mcp_servers() {
    local config_path="$1"
    local username="$2"
    
    # Check if mcp.servers already exists with both servers
    local has_dosu has_linux_mcp
    has_dosu=$(jq -e '.mcp.servers.dosu' "$config_path" > /dev/null 2>&1 && echo 1 || echo 0)
    has_linux_mcp=$(jq -e '.mcp.servers."linux_mcp_server"' "$config_path" > /dev/null 2>&1 && echo 1 || echo 0)
    
    if [[ $has_dosu -eq 1 && $has_linux_mcp -eq 1 ]]; then
        log_warn "Both dosu and linux-mcp-server already configured in mcp.servers, skipping..."
        return 1
    fi
    
    local temp_file="${config_path}.tmp"
    local jq_filter='.mcp.servers = (.mcp.servers // {})'
    
    # Add dosu if missing
    if [[ $has_dosu -eq 0 ]]; then
        jq_filter+=' | .mcp.servers.dosu = {
            "type": "http",
            "url": "https://api.dosu.dev/v1/mcp",
            "headers": {
                "X-Deployment-ID": "83775020-c22e-485a-a222-987b2f5a3823"
            }
        }'
    fi
    
    # Add linux-mcp-server if missing
    if [[ $has_linux_mcp -eq 0 ]]; then
        jq_filter+=' | .mcp.servers."linux_mcp_server" = {
            "type": "local",
            "command": "/home/linuxbrew/.linuxbrew/bin/linux-mcp-server",
            "env": {
                "LINUX_MCP_USER": $user
            }
        }'
    fi
    
    if jq --arg user "$username" "$jq_filter" "$config_path" > "$temp_file"; then
        mv "$temp_file" "$config_path"
        log_success "Added MCP servers to mcp.servers (user: $username)"
        return 0
    else
        log_error "Failed to merge MCP servers configuration"
        rm -f "$temp_file"
        return 2
    fi
}

# Merge dosu and linux-mcp-server into Gemini CLI settings.json
# Args:
#   $1 - config file path (~/.gemini/settings.json)
#   $2 - username
# Returns: 0 on success, 1 if already exists, 2 on error
merge_gemini_mcp_servers() {
    local config_path="$1"
    local username="$2"
    
    # Check if mcpServers already exists with both servers
    local has_dosu has_linux_mcp
    has_dosu=$(jq -e '.mcpServers.dosu' "$config_path" > /dev/null 2>&1 && echo 1 || echo 0)
    has_linux_mcp=$(jq -e '.mcpServers."linux_mcp_server"' "$config_path" > /dev/null 2>&1 && echo 1 || echo 0)
    
    if [[ $has_dosu -eq 1 && $has_linux_mcp -eq 1 ]]; then
        log_warn "Both dosu and linux-mcp-server already configured in mcpServers, skipping..."
        return 1
    fi
    
    local temp_file="${config_path}.tmp"
    local jq_filter='.mcpServers = (.mcpServers // {})'
    
    # Add dosu if missing
    if [[ $has_dosu -eq 0 ]]; then
        jq_filter+=' | .mcpServers.dosu = {
            "url": "https://api.dosu.dev/v1/mcp",
            "headers": {
                "X-Deployment-ID": "83775020-c22e-485a-a222-987b2f5a3823"
            }
        }'
    fi
    
    # Add linux-mcp-server if missing
    if [[ $has_linux_mcp -eq 0 ]]; then
        jq_filter+=' | .mcpServers."linux_mcp_server" = {
            "command": "/home/linuxbrew/.linuxbrew/bin/linux-mcp-server",
            "env": {
                "LINUX_MCP_USER": $user
            }
        }'
    fi
    
    if jq --arg user "$username" "$jq_filter" "$config_path" > "$temp_file"; then
        mv "$temp_file" "$config_path"
        log_success "Added MCP servers to mcpServers (user: $username)"
        return 0
    else
        log_error "Failed to merge Gemini MCP servers configuration"
        rm -f "$temp_file"
        return 2
    fi
}

# Create default VS Code/Antigravity settings.json if none exists
# Args:
#   $1 - config file path
# Returns: 0 on success, 1 on failure
create_default_vscode_settings() {
    local config_path="$1"
    local config_dir
    config_dir=$(dirname "$config_path")
    
    # Create config directory if needed
    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir" || return 1
    fi
    
    # Create minimal settings with mcp.servers
    echo '{"mcp":{"servers":{}}}' | jq '.' > "$config_path"
    log_info "Created default settings: $config_path"
    return 0
}

# Create default Gemini CLI settings.json if none exists
# Args:
#   $1 - config file path
# Returns: 0 on success, 1 on failure
create_default_gemini_settings() {
    local config_path="$1"
    local config_dir
    config_dir=$(dirname "$config_path")
    
    # Create config directory if needed
    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir" || return 1
    fi
    
    # Create minimal settings with mcpServers
    echo '{"mcpServers":{}}' | jq '.' > "$config_path"
    log_info "Created default Gemini settings: $config_path"
    return 0
}
