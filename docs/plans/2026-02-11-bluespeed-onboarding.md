# bluespeed-onboarding Implementation Plan

> **Epic Issue:** https://github.com/castrojo/bluespeed/issues/1
> **Sub-Tasks:** #2, #3, #4, #5, #6, #7, #8

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create the bluespeed-onboarding skill to automate setup of dosu MCP and linux-mcp-server for Bluefin maintainers using OpenCode.

**Architecture:** SKILL-CENTRIC automation where agents read SKILL.md from GitHub and execute instructions inline. NO git clone required. Bash scripts are optional reference implementations for manual users. Skills auto-install prerequisites and merge MCP configurations safely.

**Tech Stack:** OpenCode skills (SKILL.md as executable specification), inline bash commands via agent, jq/yq for config manipulation, MCP server integration

## ⚠️ CRITICAL ARCHITECTURE DECISION

**Skills-Based Pattern (MANDATORY):**
- **SKILL.md is the source of truth** - contains complete executable instructions
- **Agents read from GitHub** - no cloning, agents execute instructions inline
- **Bash scripts are optional** - reference implementations for manual users only
- **Auto-installation** - skills install missing prerequisites automatically
- **Safe merging** - backup before changes, skip duplicates, auto-rollback on errors

**User Experience Flow:**
1. User: "Onboard me to projectbluefin/bluespeed"
2. Agent searches GitHub: `castrojo/bluespeed`
3. Agent reads: `skills/bluespeed-onboarding/SKILL.md`
4. Agent executes instructions inline (brew install, jq commands, config merging)
5. Agent reports results, tells user to restart OpenCode
6. Done - no cloning, no manual steps

## Task 1: Repository Initialization

**Files:**
- `/var/home/jorge/src/bluespeed/.gitignore`
- `/var/home/jorge/src/bluespeed/README.md`
- `/var/home/jorge/src/bluespeed/AGENTS.md`

**Steps:**
1. Initialize git repository in `/var/home/jorge/src/bluespeed` ✅ DONE
2. Create `.gitignore` excluding `*.local` files only
3. Write `README.md` with repository purpose: "Agents and skills for maintaining Project Bluefin"
4. Write `AGENTS.md` documenting repository structure and Bash script organization
5. Create initial directory structure following AGENTS.md pattern:
   - `skills/bluespeed-onboarding/scripts/lib/` (for organized Bash scripts)
   - `configs/` (for configuration examples)
6. Commit repository structure with clear documentation

## Task 2: Configuration Examples

**Files:**
- `/var/home/jorge/src/bluespeed/configs/README.md`
- `/var/home/jorge/src/bluespeed/configs/opencode-example.json`
- `/var/home/jorge/src/bluespeed/configs/goose-example.yaml`

**Purpose:** Provide reference templates showing the target configuration structure. These are NOT executed by agents - they serve as documentation and examples for manual setup.

**Steps:**
1. Create `configs/README.md` with centralized prerequisite documentation:
   - **Core AI Tools**: OpenCode (required), Goose (optional)
   - **MCP Servers**: linux-mcp-server (brew package), dosu (remote-only, no install needed)
   - **Configuration Utilities**: jq (JSON), yq (YAML)
   - Complete brew install commands in one centralized location
   - Package details table with purpose and status
   - Note: dosu MCP is remote-only (deployment ID: 83775020-c22e-485a-a222-987b2f5a3823)
2. Create `opencode-example.json` with:
   - dosu remote MCP server (type: remote, url: https://api.dosu.dev/v1/mcp)
   - linux-mcp-server local MCP (command: /home/linuxbrew/.linuxbrew/bin/linux-mcp-server)
   - LINUX_MCP_USER placeholder: REPLACE_WITH_YOUR_USERNAME
   - Full JSON structure matching OpenCode config schema
3. Create `goose-example.yaml` with:
   - linux-mcp-server extension (stdio type)
   - LINUX_MCP_USER placeholder: REPLACE_WITH_YOUR_USERNAME
   - Document dosu support as TBD (pending Goose remote MCP research - Phase 4)
4. Add smoke test validation:
   - Test JSON validity: `jq empty configs/opencode-example.json`
   - Test YAML validity: `yq eval '.' configs/goose-example.yaml`

## Task 3: Bash Library Functions (Optional Reference)

**Files:**
- `/var/home/jorge/src/bluespeed/skills/bluespeed-onboarding/scripts/lib/common.sh`
- `/var/home/jorge/src/bluespeed/skills/bluespeed-onboarding/scripts/lib/config.sh`
- `/var/home/jorge/src/bluespeed/skills/bluespeed-onboarding/scripts/lib/validation.sh`

**Purpose:** Optional reference implementations for manual users. Agents execute SKILL.md instructions inline - these scripts are NOT required for agent execution.

**Steps:**
1. Create `lib/common.sh` with utility functions:
   - Apache license header with note: "Reference implementation - agents follow SKILL.md"
   - `log_info()`, `log_error()`, `log_success()`, `log_warn()` - Formatted output with colors
   - `get_username()` - Uses `whoami` to detect current user
   - `backup_file()` - Creates timestamped backups (.backup suffix with ISO timestamp)
   - `restore_backup()` - Restore from timestamped backup
   - `cleanup_on_error()` - Restore backups on failure (trap handler)
2. Create `lib/config.sh` with configuration functions:
   - Apache license header with note: "Reference implementation - agents follow SKILL.md"
   - `merge_json_config()` - Uses jq to merge MCP servers into OpenCode config
     - Skip if MCP server name already exists (log warning)
     - Preserve all existing user configuration
     - Automatically detect username via `get_username()`
   - `merge_yaml_config()` - Uses yq to merge extensions into Goose config
     - Skip if extension name already exists (log warning)
     - Preserve all existing user configuration
     - Automatically detect username via `get_username()`
   - `validate_json()` - Check JSON syntax with jq
   - `validate_yaml()` - Check YAML syntax with yq
   - `create_default_config()` - Generate minimal config if none exists
3. Create `lib/validation.sh` with prerequisite checks:
   - Apache license header with note: "Reference implementation - agents follow SKILL.md"
   - `validate_prerequisites()` - Generic checks (brew, jq, yq)
   - `validate_opencode_prerequisites()` - OpenCode-specific (package checks)
   - `validate_goose_prerequisites()` - Goose-specific (package checks)
   - `check_brew_package()` - Verify brew package installed with clear error messages
   - `check_file_exists()` - Verify file/directory existence
   - `check_command_exists()` - Verify command available in PATH
   - All error messages include exact brew install commands
4. Add smoke test validation:
   - Test: Source all library files without errors
   - Test: Call dummy functions (log_info, get_username)

## Task 4: Bash Setup Scripts (Optional Reference)

**Files:**
- `/var/home/jorge/src/bluespeed/skills/bluespeed-onboarding/scripts/setup-opencode.sh`
- `/var/home/jorge/src/bluespeed/skills/bluespeed-onboarding/scripts/setup-goose.sh`
- `/var/home/jorge/src/bluespeed/skills/bluespeed-onboarding/scripts/bluespeed-onboarding.sh`

**Purpose:** Optional standalone scripts for manual users. Agents execute SKILL.md instructions inline - these scripts are NOT required for agent execution.

**Steps:**
1. Create `setup-opencode.sh` (Reference implementation for OpenCode setup):
   - Apache license header with note: "Reference implementation - agents follow SKILL.md"
   - Set strict mode: `set -euo pipefail`
   - Source library functions from `lib/` (common.sh, config.sh, validation.sh)
   - Call `validate_opencode_prerequisites()` early (fail fast)
   - Detect username via `get_username()`
   - Backup existing `~/.config/opencode/opencode.json` with timestamp
   - Merge dosu MCP config (skip if exists, log warning)
   - Merge linux-mcp-server MCP config (skip if exists, log warning)
   - Validate JSON syntax with `validate_json()`
   - On error: auto-restore backup via `restore_backup()`
   - Print success message with restart instructions
2. Create `setup-goose.sh` (Reference implementation for Goose setup):
   - Apache license header with note: "Reference implementation - agents follow SKILL.md"
   - Set strict mode: `set -euo pipefail`
   - Source library functions from `lib/`
   - Call `validate_goose_prerequisites()` early (fail fast)
   - Detect username via `get_username()`
   - Backup existing `~/.config/goose/config.yaml` with timestamp
   - Merge linux-mcp-server extension config (skip if exists, log warning)
   - Add TODO comment: "Phase 4: Add dosu remote MCP support (pending Goose research)"
   - Validate YAML syntax with `validate_yaml()`
   - On error: auto-restore backup via `restore_backup()`
   - Print success message with restart instructions
3. Create `bluespeed-onboarding.sh` main entry point:
   - Apache license header with note: "Reference implementation - agents follow SKILL.md"
   - Set strict mode: `set -euo pipefail`
   - Source library functions from `lib/`
   - Call `validate_prerequisites()` for generic checks (brew, jq, yq)
   - Ask user which tool to configure: OpenCode / Goose / Both
   - Call appropriate setup script(s) based on choice
   - Handle errors gracefully with rollback via `cleanup_on_error()`
   - Print final summary of changes made
4. Make all scripts executable: `chmod +x scripts/*.sh`
5. Add smoke test validation:
   - Test: All scripts are executable
   - Test: Scripts show usage/help with --help flag
   - Test: Dry-run mode works (if implemented)

## Task 5: Skill Documentation (PRIMARY IMPLEMENTATION)

**Files:**
- `/var/home/jorge/src/bluespeed/skills/bluespeed-onboarding/SKILL.md` ⭐ **CRITICAL - EXECUTABLE SPECIFICATION**
- `/var/home/jorge/src/bluespeed/skills/bluespeed-onboarding/AGENTS.md`

**Purpose:** Create SKILL.md with COMPLETE, EXECUTABLE instructions that agents read from GitHub and execute inline. This is the PRIMARY implementation - bash scripts are optional reference only.

**Steps:**
1. Create `SKILL.md` with frontmatter:
   ```yaml
   ---
   name: bluespeed-onboarding
   description: Setup dosu MCP and linux-mcp-server for Bluefin maintainers
   ---
   ```
2. Add "When to Use" section:
   - User says: "Onboard me to projectbluefin/bluespeed" or "Onboard me to castrojo/bluespeed"
   - New Bluefin contributor needs MCP servers configured
3. Add complete step-by-step executable instructions:
   - **Step 1**: Verify Homebrew (fail fast if missing)
   - **Step 2**: Auto-install jq if missing: `brew install jq`
   - **Step 3**: Auto-install yq if missing: `brew install yq`
   - **Step 4**: Auto-install linux-mcp-server if missing: `brew install ublue-os/tap/linux-mcp-server`
   - **Step 5**: Detect username: `USERNAME=$(whoami)`
   - **Step 6**: Backup existing config with timestamp
   - **Step 7**: Merge dosu MCP (skip if exists, use jq commands)
   - **Step 8**: Merge linux-mcp-server (skip if exists, use jq commands with $USERNAME)
   - **Step 9**: Validate JSON config with jq, auto-rollback on error
   - **Step 10**: Tell user to restart OpenCode with clear instructions
4. Add error handling section with rollback instructions
5. Add success criteria checklist
6. Include full jq command examples for config merging (copy-paste ready)
7. Create `AGENTS.md` with execution notes:
   - **Key principle**: Agents read SKILL.md from GitHub, execute inline
   - **No cloning required**: Agent uses Bash tool for each step
   - **Bash scripts optional**: Reference implementations for manual users only
   - Expected behavior and success output examples
8. Add smoke test validation:
   - Test: SKILL.md has valid frontmatter
   - Test: All jq/brew commands are syntactically correct
   - Test: Config paths are accurate

## Task 6: GitHub Repository Publishing

**Files:**
- Remote: `castrojo/bluespeed` on GitHub ✅ DONE

**Steps:**
1. Ensure all files are committed locally ✅ DONE
2. Create GitHub repository: `gh repo create castrojo/bluespeed --public` ✅ DONE
3. Push initial commit: `git push -u origin main` ✅ DONE
4. Create labels: `type/epic`, `type/task` ✅ DONE
5. Create Epic #1 for bluespeed-onboarding ✅ DONE
6. Create sub-task issues for Tasks 1-6
7. Update epic with sub-task issue numbers

## Task 7: Powerlevel Integration Documentation

**Files:**
- `/var/home/jorge/.config/opencode/powerlevel/AGENTS.md` ✅ UPDATED
- `/var/home/jorge/.config/opencode/powerlevel/projects/bluespeed/config.json` ✅ CREATED

**Steps:**
1. Verify powerlevel project config exists for bluespeed ✅ DONE
2. Update powerlevel AGENTS.md with mandatory workflow section ✅ DONE
3. Document where work happens for external projects ✅ DONE
4. Add clarification that agents MUST follow the workflow ✅ DONE
5. Commit powerlevel changes with clear documentation ✅ DONE

## Implementation Notes

### ⚠️ CRITICAL: Skills-Based Architecture

**PRIMARY IMPLEMENTATION: SKILL.md**
- SKILL.md is the executable specification agents follow
- Agents read from GitHub, execute inline via Bash tool
- NO git clone required, NO bash script execution required
- Bash scripts are optional reference implementations only

**User Experience:**
1. User: "Onboard me to projectbluefin/bluespeed"
2. Agent searches: `castrojo/bluespeed` repository on GitHub
3. Agent reads: `skills/bluespeed-onboarding/SKILL.md` from remote
4. Agent executes: Each step inline using Bash tool
5. Result: MCP servers configured, user told to restart OpenCode

### MVP Scope (Phases 1-3)
- **OpenCode full support**: dosu + linux-mcp-server auto-configuration
- **Goose partial support**: linux-mcp-server only (dosu marked as TODO for Phase 4)
- **Auto-installation**: Missing packages installed via brew automatically
- **Username detection**: Via `whoami` command (dynamic, portable)
- **Config merging**: Preserve existing MCP servers/extensions (skip if exists, log warning)
- **Validation**: JSON/YAML syntax checking with auto-rollback on error
- **Smoke testing**: Basic validation for each task (config validity, script execution, docs)
- **Apache License**: All scripts include Apache 2.0 license headers (reference only)

### Phase 4 (Future Enhancement)
- **Goose dosu integration**: Research remote MCP server configuration for Goose
- **Update goose-example.yaml**: Add dosu if supported by Goose
- **Update SKILL.md**: Add Goose dosu instructions if supported
- **Test with Goose**: Validate skill execution in Goose environment
- **Auto-install enhancement**: Add `auto_install_prerequisites()` function
  - Detect missing brew packages
  - Prompt user: "Install X missing packages? (y/n)"
  - Auto-install with `brew install` on confirmation
  - Verify installation success with clear error handling
  - Document in AGENTS.md for future agents to implement

### Key Technical Decisions
1. **Username detection**: `whoami` command (dynamic, portable, cross-platform)
2. **Repository visibility**: Public (aligns with Bluefin open source philosophy)
3. **License**: Apache 2.0 for all scripts and configuration files
4. **MVP approach**: OpenCode first (full support), Goose incremental (Phase 4 for dosu)
5. **Deployment ID**: Public and safe to commit (83775020-c22e-485a-a222-987b2f5a3823)
6. **Config strategy**: Merge, don't replace (preserve existing work, skip duplicates)
7. **Prerequisite validation**: Centralized in `lib/validation.sh` with clear error messages
8. **Error handling**: Auto-backup before changes, auto-rollback on failure
9. **jq/yq availability**: System jq (/usr/bin/jq) used, yq from brew required

### Config Merge Behavior (Agent Implementation Guidance)

**For OpenCode (JSON):**
```bash
# If MCP server name exists → skip with warning message
# If MCP server name is new → add to .mcp object
# Preserve all existing user configuration
# Example: Merging "dosu" MCP
if jq -e '.mcp.dosu' "$config_path" >/dev/null 2>&1; then
    log_warn "dosu MCP already configured, skipping..."
else
    # Merge new MCP server using jq
    jq '.mcp.dosu = {...}' "$config_path" > "$config_path.tmp"
    mv "$config_path.tmp" "$config_path"
fi
```

**For Goose (YAML):**
```bash
# If extension name exists → skip with warning message
# If extension name is new → add to extensions array
# Preserve all existing user configuration
# Example: Merging "linux-mcp-server" extension
if yq eval '.extensions[] | select(.name == "linux-mcp-server")' "$config_path" | grep -q linux-mcp-server; then
    log_warn "linux-mcp-server extension already configured, skipping..."
else
    # Merge new extension using yq
    yq eval '.extensions += [...]' "$config_path" > "$config_path.tmp"
    mv "$config_path.tmp" "$config_path"
fi
```

**Backup Strategy:**
- Always create timestamped backup before modification
- Format: `<original>.<ISO-timestamp>.backup` (e.g., `opencode.json.2026-02-11T16:30:45.backup`)
- On error: restore from backup automatically via `restore_backup()`
- Log all operations for troubleshooting

**Restart Instructions:**

**OpenCode:**
1. Close all OpenCode windows
2. Restart OpenCode from application menu or `opencode` command
3. Verify MCP servers loaded: Check "MCP Servers" panel in sidebar
4. Test: Ask "Can you check my system information?" (tests linux-mcp-server)
5. Troubleshooting: Logs at `~/.config/opencode/logs/`, config at `~/.config/opencode/opencode.json`

**Goose:**
1. Exit Goose session: `exit` command or `Ctrl+D`
2. Restart Goose from terminal: `goose`
3. Verify extensions: Check startup messages for "linux-mcp-server" loading
4. Test: Ask "Can you check my disk usage?" (tests linux-mcp-server)
5. Troubleshooting: Logs at `~/.config/goose/logs/`, config at `~/.config/goose/config.yaml`

### Prerequisites (Centralized Installation)

**All required packages must be installed via Homebrew before running the skill.**

#### Core AI Tools
```bash
# OpenCode (Primary - Required for MVP)
brew install --cask ublue-os/experimental-tap/opencode-desktop-linux

# Goose (Optional - MVP has partial support)
brew install --cask ublue-os/tap/goose-linux
```

#### MCP Servers
```bash
# linux-mcp-server (Local MCP - Required)
brew install ublue-os/tap/linux-mcp-server

# dosu MCP (Remote - No installation needed)
# Configured via deployment ID: 83775020-c22e-485a-a222-987b2f5a3823
# API endpoint: https://api.dosu.dev/v1/mcp
```

#### Configuration Utilities
```bash
# JSON manipulation (Required)
brew install jq

# YAML manipulation (Required)
brew install yq
```

#### Package Summary Table

| Package | Type | Purpose | Status |
|---------|------|---------|--------|
| `ublue-os/experimental-tap/opencode-desktop-linux` | Cask | AI coding assistant (primary) | Required for OpenCode setup |
| `ublue-os/tap/goose-linux` | Cask | AI coding assistant (alternative) | Optional (MVP partial support) |
| `ublue-os/tap/linux-mcp-server` | Formula | Local MCP for Linux diagnostics | Required |
| `jq` | Formula | JSON config manipulation | Required |
| `yq` | Formula | YAML config manipulation | Required |
| dosu MCP | Remote | Bluefin knowledge base MCP | No install needed (remote) |

**Note for Future Agents:**
- All prerequisite validation happens in `lib/validation.sh`
- Generic checks (brew, jq, yq): `validate_prerequisites()`
- Tool-specific checks: `validate_opencode_prerequisites()`, `validate_goose_prerequisites()`
- Error messages include exact brew install commands
- Phase 4 enhancement: Auto-install missing packages with user confirmation

### Configuration Paths
- **OpenCode**: `~/.config/opencode/opencode.json`
- **Goose**: `~/.config/goose/config.yaml`
- **linux-mcp-server**: `/home/linuxbrew/.linuxbrew/bin/linux-mcp-server`

### Dosu Deployment Details
- **Deployment ID**: `83775020-c22e-485a-a222-987b2f5a3823`
- **API Endpoint**: `https://api.dosu.dev/v1/mcp`
- **Type**: Remote MCP server
- **Authentication**: Via `X-Deployment-ID` header (public, not secret)

### Success Criteria
- ✅ Repository `castrojo/bluespeed` is public on GitHub
- ✅ All scripts include Apache 2.0 license headers
- ✅ OpenCode users can configure dosu + linux-mcp-server (full support)
- ✅ Goose users can configure linux-mcp-server (Phase 4 TODO for dosu)
- ✅ Username detected dynamically via `whoami`
- ✅ Existing configs preserved and merged (skip duplicates)
- ✅ Clear documentation for manual setup with restart instructions
- ✅ Centralized prerequisite installation (all brew packages in one place)
- ✅ Validation functions with exact brew install commands in error messages
- ✅ Auto-backup and auto-rollback on errors
- ✅ Smoke tests for each task (config validity, script execution, docs)
- ✅ Powerlevel tracking configured
- ✅ org/repo convention documented in powerlevel
- ✅ Phase 4 auto-install enhancement documented for future agents
