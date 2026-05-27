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

# setup-vscode.sh - Configure VS Code with dosu and linux-mcp-server
# NOTE: Reference implementation - agents follow SKILL.md instructions inline

set -euo pipefail

# Source library functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/config.sh"
source "${SCRIPT_DIR}/lib/validation.sh"

# Configuration
VSCODE_CONFIG="$HOME/.config/Code/User/settings.json"

main() {
    log_info "Starting VS Code setup for bluespeed-onboarding..."
    
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
    if [[ ! -f "$VSCODE_CONFIG" ]]; then
        log_info "VS Code settings not found, creating default..."
        create_default_vscode_settings "$VSCODE_CONFIG" || {
            log_error "Failed to create default settings"
            exit 1
        }
    fi
    
    # Backup existing config
    BACKUP_PATH=$(backup_file "$VSCODE_CONFIG")
    if [[ -z "$BACKUP_PATH" ]]; then
        log_error "Failed to create backup"
        exit 1
    fi
    
    # Set up error handler to restore backup
    trap "cleanup_on_error '$VSCODE_CONFIG' '$BACKUP_PATH'" ERR
    
    # Merge MCP servers configuration
    log_info "Configuring MCP servers..."
    merge_vscode_mcp_servers "$VSCODE_CONFIG" "$USERNAME" || {
        status=$?
        if [[ $status -eq 2 ]]; then
            # Error occurred, trap will restore backup
            exit 1
        fi
        # status=1 means already exists, continue
    }
    
    # Validate final configuration
    log_info "Validating configuration..."
    if ! validate_json "$VSCODE_CONFIG"; then
        log_error "Configuration validation failed, restoring backup..."
        restore_backup "$VSCODE_CONFIG" "$BACKUP_PATH"
        exit 1
    fi
    
    # Success!
    log_success "VS Code configuration complete!"
    echo ""
    log_info "Next steps:"
    echo "  1. Close all VS Code windows"
    echo "  2. Restart VS Code from application menu or 'code' command"
    echo "  3. Verify MCP servers loaded: Check GitHub Copilot chat panel"
    echo "  4. Test: Ask 'Can you check my system information?' (tests linux-mcp-server)"
    echo ""
    log_info "Troubleshooting:"
    echo "  - Logs: ~/.config/Code/logs/"
    echo "  - Config: ~/.config/Code/User/settings.json"
    echo "  - Backup: $BACKUP_PATH"
}

# Show help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Usage: $0"
    echo ""
    echo "Configure VS Code with dosu MCP and linux-mcp-server for Bluefin maintenance."
    echo ""
    echo "This script:"
    echo "  - Validates prerequisites (jq, linux-mcp-server)"
    echo "  - Backs up existing VS Code settings"
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
