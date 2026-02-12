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

# setup-antigravity.sh - Configure Antigravity with dosu and linux-mcp-server
# NOTE: Reference implementation - agents follow SKILL.md instructions inline

set -euo pipefail

# Source library functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/config.sh"
source "${SCRIPT_DIR}/lib/validation.sh"

# Configuration
ANTIGRAVITY_CONFIG="$HOME/.gemini/antigravity/mcp_config.json"

main() {
    log_info "Starting Antigravity setup for bluespeed-onboarding..."
    
    # Validate prerequisites
    if ! validate_prerequisites; then
        log_error "Prerequisites not met. Exiting."
        exit 1
    fi
    
    # Check if linux-mcp-server is installed
    if [[ ! -f /home/linuxbrew/.linuxbrew/bin/linux-mcp-server ]]; then
        log_error "linux-mcp-server is not installed. Install with: brew install ublue-os/tap/linux-mcp-server"
        exit 1
    fi
    
    # Detect username
    USERNAME=$(get_username)
    log_info "Detected username: $USERNAME"
    
    # Create config if it doesn't exist
    if [[ ! -f "$ANTIGRAVITY_CONFIG" ]]; then
        log_info "Antigravity MCP config not found, creating default..."
        mkdir -p "$HOME/.gemini/antigravity"
        echo '{}' | jq '.' > "$ANTIGRAVITY_CONFIG" || {
            log_error "Failed to create default MCP config"
            exit 1
        }
    fi
    
    # Backup existing config
    BACKUP_PATH=$(backup_file "$ANTIGRAVITY_CONFIG")
    if [[ -z "$BACKUP_PATH" ]]; then
        log_error "Failed to create backup"
        exit 1
    fi
    
    # Set up error handler to restore backup
    trap "cleanup_on_error '$ANTIGRAVITY_CONFIG' '$BACKUP_PATH'" ERR
    
    # Merge MCP servers configuration
    log_info "Configuring MCP servers..."
    
    # Antigravity uses a simple root-level object with server names as keys
    jq --arg user "$USERNAME" '
. = (. // {}) |
.dosu = {
    "url": "https://api.dosu.dev/v1/mcp",
    "headers": {
        "X-Deployment-ID": "83775020-c22e-485a-a222-987b2f5a3823"
    }
} |
."linux-mcp-server" = {
    "command": "/home/linuxbrew/.linuxbrew/bin/linux-mcp-server",
    "env": {
        "LINUX_MCP_USER": $user
    }
}
' "$ANTIGRAVITY_CONFIG" > "${ANTIGRAVITY_CONFIG}.tmp" && mv "${ANTIGRAVITY_CONFIG}.tmp" "$ANTIGRAVITY_CONFIG" || {
        log_error "Failed to merge MCP servers"
        exit 1
    }
    
    log_success "Added MCP servers to Antigravity config (user: $USERNAME)"
    
    # Validate final configuration
    log_info "Validating configuration..."
    if ! validate_json "$ANTIGRAVITY_CONFIG"; then
        log_error "Configuration validation failed, restoring backup..."
        restore_backup "$ANTIGRAVITY_CONFIG" "$BACKUP_PATH"
        exit 1
    fi
    
    # Success!
    log_success "Antigravity configuration complete!"
    echo ""
    log_info "Next steps:"
    echo "  1. Close all Antigravity windows"
    echo "  2. Restart Antigravity from application menu"
    echo "  3. Verify MCP servers loaded: Check status bar or MCP panel"
    echo "  4. Test: Ask 'Can you check my system information?' (tests linux-mcp-server)"
    echo ""
    log_info "Troubleshooting:"
    echo "  - Logs: ~/.config/Antigravity/logs/"
    echo "  - Config: ~/.gemini/antigravity/mcp_config.json"
    echo "  - Backup: $BACKUP_PATH"
}

# Show help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Usage: $0"
    echo ""
    echo "Configure Antigravity with dosu MCP and linux-mcp-server for Bluefin maintenance."
    echo ""
    echo "This script:"
    echo "  - Validates prerequisites (jq, linux-mcp-server)"
    echo "  - Backs up existing Antigravity settings"
    echo "  - Merges dosu and linux-mcp-server MCP configurations"
    echo "  - Validates final configuration"
    echo "  - Auto-restores backup on error"
    echo ""
    echo "Prerequisites:"
    echo "  brew install jq"
    echo "  brew install ublue-os/tap/linux-mcp-server"
    exit 0
fi

main
