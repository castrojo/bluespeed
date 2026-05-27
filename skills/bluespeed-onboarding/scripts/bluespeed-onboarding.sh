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

# bluespeed-onboarding.sh - Main entry point for bluespeed-onboarding skill
# NOTE: Reference implementation - agents follow SKILL.md instructions inline

set -euo pipefail

# Source library functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/validation.sh"

# Show help
show_help() {
    cat << EOF
bluespeed-onboarding - Setup MCP servers for Bluefin maintenance

Usage: $0 [OPTIONS]

Configure AI coding tools with dosu MCP and linux-mcp-server for
Project Bluefin maintenance work.

Options:
  -h, --help         Show this help message
  -o, --opencode     Configure OpenCode only
  -g, --goose        Configure Goose only
  -v, --vscode       Configure VS Code only
  -t, --antigravity  Configure Antigravity only
  -m, --gemini       Configure Gemini CLI only
  -a, --all          Configure all detected tools (default if no option)

Prerequisites:
  brew install jq
  brew install yq
  brew install ublue-os/tap/linux-mcp-server

Examples:
  $0                 # Interactive mode - asks which tool to configure
  $0 --opencode      # Configure OpenCode only
  $0 --antigravity   # Configure Antigravity only
  $0 --vscode        # Configure VS Code only
  $0 --gemini        # Configure Gemini CLI only
  $0 --all           # Configure all detected tools

For more information, see:
  https://github.com/castrojo/bluespeed
EOF
}

# Interactive mode - ask user which tool to configure
interactive_mode() {
    echo ""
    log_info "bluespeed-onboarding - Bluefin MCP Server Setup"
    echo ""
    echo "Which AI tool would you like to configure?"
    echo ""
    echo "  1) OpenCode"
    echo "  2) Goose"
    echo "  3) VS Code"
    echo "  4) Antigravity"
    echo "  5) Gemini CLI"
    echo "  6) All detected tools"
    echo "  7) Exit"
    echo ""
    read -p "Enter choice [1-7]: " choice
    
    case $choice in
        1)
            log_info "Selected: OpenCode"
            return 1
            ;;
        2)
            log_info "Selected: Goose"
            return 2
            ;;
        3)
            log_info "Selected: VS Code"
            return 3
            ;;
        4)
            log_info "Selected: Antigravity"
            return 4
            ;;
        5)
            log_info "Selected: Gemini CLI"
            return 5
            ;;
        6)
            log_info "Selected: All tools"
            return 6
            ;;
        7)
            log_info "Exiting..."
            exit 0
            ;;
        *)
            log_error "Invalid choice: $choice"
            exit 1
            ;;
    esac
}

main() {
    local mode=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -o|--opencode)
                mode="opencode"
                shift
                ;;
            -g|--goose)
                mode="goose"
                shift
                ;;
            -v|--vscode)
                mode="vscode"
                shift
                ;;
            -t|--antigravity)
                mode="antigravity"
                shift
                ;;
            -m|--gemini)
                mode="gemini"
                shift
                ;;
            -a|--all)
                mode="all"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # If no mode specified, use interactive mode
    if [[ -z "$mode" ]]; then
        interactive_mode
        choice=$?
        case $choice in
            1) mode="opencode" ;;
            2) mode="goose" ;;
            3) mode="vscode" ;;
            4) mode="antigravity" ;;
            5) mode="gemini" ;;
            6) mode="all" ;;
        esac
    fi
    
    log_info "Starting bluespeed-onboarding setup..."
    
    # Validate generic prerequisites
    if ! validate_prerequisites; then
        log_error "Generic prerequisites not met. Please install missing packages and try again."
        exit 1
    fi
    
    # Check if linux-mcp-server is installed
    if [[ ! -f /home/linuxbrew/.linuxbrew/bin/linux-mcp-server ]]; then
        log_warn "linux-mcp-server is not installed"
        echo ""
        read -p "Would you like to install linux-mcp-server now? [Y/n]: " install_choice
        install_choice=${install_choice:-Y}
        
        if [[ "$install_choice" =~ ^[Yy]$ ]]; then
            log_info "Installing linux-mcp-server..."
            if brew install ublue-os/tap/linux-mcp-server; then
                log_success "linux-mcp-server installed successfully"
            else
                log_error "Failed to install linux-mcp-server"
                log_error "Please install manually: brew install ublue-os/tap/linux-mcp-server"
                exit 1
            fi
        else
            log_error "linux-mcp-server is required for MCP server configuration"
            log_error "Please install manually: brew install ublue-os/tap/linux-mcp-server"
            exit 1
        fi
    else
        log_success "linux-mcp-server is installed"
    fi
    
    # Run appropriate setup script(s)
    case $mode in
        opencode)
            log_info "Configuring OpenCode..."
            "${SCRIPT_DIR}/setup-opencode.sh" || {
                log_error "OpenCode setup failed"
                exit 1
            }
            ;;
        goose)
            log_info "Configuring Goose..."
            "${SCRIPT_DIR}/setup-goose.sh" || {
                log_error "Goose setup failed"
                exit 1
            }
            ;;
        vscode)
            log_info "Configuring VS Code..."
            "${SCRIPT_DIR}/setup-vscode.sh" || {
                log_error "VS Code setup failed"
                exit 1
            }
            ;;
        antigravity)
            log_info "Configuring Antigravity..."
            "${SCRIPT_DIR}/setup-antigravity.sh" || {
                log_error "Antigravity setup failed"
                exit 1
            }
            ;;
        gemini)
            log_info "Configuring Gemini CLI..."
            "${SCRIPT_DIR}/setup-gemini-cli.sh" || {
                log_error "Gemini CLI setup failed"
                exit 1
            }
            ;;
        all)
            # Configure all tools - continue on error to attempt all
            local failed_tools=()
            
            log_info "Configuring OpenCode..."
            "${SCRIPT_DIR}/setup-opencode.sh" || failed_tools+=("OpenCode")
            echo ""
            
            log_info "Configuring Goose..."
            "${SCRIPT_DIR}/setup-goose.sh" || failed_tools+=("Goose")
            echo ""
            
            log_info "Configuring VS Code..."
            "${SCRIPT_DIR}/setup-vscode.sh" || failed_tools+=("VS Code")
            echo ""
            
            log_info "Configuring Antigravity..."
            "${SCRIPT_DIR}/setup-antigravity.sh" || failed_tools+=("Antigravity")
            echo ""
            
            log_info "Configuring Gemini CLI..."
            "${SCRIPT_DIR}/setup-gemini-cli.sh" || failed_tools+=("Gemini CLI")
            
            # Report failures if any
            if [[ ${#failed_tools[@]} -gt 0 ]]; then
                echo ""
                log_warn "Some tools failed to configure: ${failed_tools[*]}"
                log_info "Check individual tool logs for details"
            fi
            ;;
        *)
            log_error "Invalid mode: $mode"
            exit 1
            ;;
    esac
    
    # Final summary
    echo ""
    log_success "bluespeed-onboarding setup complete!"
    echo ""
    log_info "Summary of changes:"
    case $mode in
        opencode)
            echo "  ✓ OpenCode configured with dosu MCP and linux-mcp-server"
            echo "  → Restart OpenCode to activate changes"
            ;;
        goose)
            echo "  ✓ Goose configured with linux-mcp-server"
            echo "  → Restart Goose to activate changes"
            echo "  ℹ Note: dosu MCP support for Goose planned for Phase 4"
            ;;
        vscode)
            echo "  ✓ VS Code configured with dosu MCP and linux-mcp-server"
            echo "  → Restart VS Code to activate changes"
            ;;
        antigravity)
            echo "  ✓ Antigravity configured with dosu MCP and linux-mcp-server"
            echo "  → Restart Antigravity to activate changes"
            ;;
        gemini)
            echo "  ✓ Gemini CLI configured with dosu MCP and linux-mcp-server"
            echo "  → Restart Gemini CLI to activate changes"
            ;;
        all)
            echo "  ✓ Configured all detected tools with MCP servers"
            echo "  → Restart all tools to activate changes"
            if [[ ${#failed_tools[@]} -eq 0 ]]; then
                echo "  ✓ All tools configured successfully"
            fi
            ;;
    esac
    echo ""
    log_info "Backups created with timestamp suffix (.backup)"

    log_info "For troubleshooting, see ~/.config/opencode/logs/ or ~/.config/goose/logs/"
}

main "$@"
