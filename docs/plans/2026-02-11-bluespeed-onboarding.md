# bluespeed-onboarding Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create the bluespeed-onboarding skill and agent to automate setup of dosu MCP and linux-mcp-server for Bluefin maintainers using OpenCode.

**Architecture:** Skill-based automation system that detects user's AI tool (OpenCode/Goose), verifies prerequisites, and merges MCP server configurations into existing config files. MVP focuses on OpenCode with full dosu + linux-mcp-server support. Goose support planned as Phase 4 enhancement.

**Tech Stack:** Bash scripts, JSON/YAML configuration manipulation, OpenCode skills system, MCP server integration

## Task 1: Repository Initialization

**Files:**
- `/var/home/jorge/src/bluespeed/.gitignore`
- `/var/home/jorge/src/bluespeed/README.md`

**Steps:**
1. Initialize git repository in `/var/home/jorge/src/bluespeed`
2. Create `.gitignore` excluding `*.local` files only
3. Write `README.md` with repository purpose: "Agents and skills for maintaining Project Bluefin"
4. Create initial directory structure:
   - `skills/bluespeed-onboarding/`
   - `agents/bluespeed-onboarding/`
   - `configs/`
5. Initial commit with repository structure

## Task 2: Configuration Examples

**Files:**
- `/var/home/jorge/src/bluespeed/configs/README.md`
- `/var/home/jorge/src/bluespeed/configs/opencode-example.json`
- `/var/home/jorge/src/bluespeed/configs/goose-example.yaml`

**Steps:**
1. Create `configs/README.md` explaining example configurations
2. Create `opencode-example.json` with:
   - dosu remote MCP server (deployment ID: 83775020-c22e-485a-a222-987b2f5a3823)
   - linux-mcp-server local MCP (command: /home/linuxbrew/.linuxbrew/bin/linux-mcp-server)
   - LINUX_MCP_USER placeholder: REPLACE_WITH_YOUR_USERNAME
3. Create `goose-example.yaml` with:
   - linux-mcp-server extension (stdio type)
   - LINUX_MCP_USER placeholder: REPLACE_WITH_YOUR_USERNAME
   - Document dosu support as TBD (pending Goose remote MCP research)
4. Document prerequisite brew packages:
   - `ublue-os/tap/linux-mcp-server`
   - `ublue-os/experimental-tap/opencode-desktop-linux`
   - `ublue-os/tap/goose-linux`

## Task 3: Skill Implementation

**Files:**
- `/var/home/jorge/src/bluespeed/skills/bluespeed-onboarding/SKILL.md`

**Steps:**
1. Create SKILL.md following OpenCode skills format with frontmatter:
   ```yaml
   ---
   name: bluespeed-onboarding
   description: Setup dosu MCP and linux-mcp-server for Bluefin maintainers
   ---
   ```
2. Document skill workflow:
   - Detect which AI tool user wants to configure (OpenCode/Goose/Both)
   - Verify prerequisites (brew packages installed)
   - Detect username via `whoami` command
   - Backup existing configuration files
   - Merge MCP configurations preserving existing servers
   - Validate JSON/YAML syntax
   - Instruct user to restart tools
3. Include OpenCode-specific instructions:
   - Read `~/.config/opencode/opencode.json`
   - Merge dosu and linux-mcp-server into `mcp:` section
   - Handle case where file doesn't exist (create new)
   - Handle case where mcp section already exists (merge)
4. Include Goose instructions (future):
   - Read `~/.config/goose/config.yaml`
   - Merge linux-mcp-server into `extensions:` section
   - Note: dosu remote MCP support pending research
5. Add error handling patterns:
   - Missing brew packages
   - Permission denied on config files
   - Invalid existing JSON/YAML
   - MCP server binary not found
6. Add troubleshooting section

## Task 4: Agent Instructions

**Files:**
- `/var/home/jorge/src/bluespeed/agents/bluespeed-onboarding/AGENTS.md`

**Steps:**
1. Create AGENTS.md with agent execution instructions
2. Document how to invoke the skill
3. Specify expected inputs (which tools to configure)
4. Document expected outputs (success messages, file locations)
5. Include error handling patterns for agents
6. Add example invocations
7. Define success criteria

## Task 5: GitHub Repository Creation

**Files:**
- Remote: `castrojo/bluespeed` on GitHub

**Steps:**
1. Ensure all files are committed locally
2. Create GitHub repository: `gh repo create castrojo/bluespeed --public --source=. --remote=origin`
3. Push initial commit: `git push -u origin main`
4. Verify repository is public and accessible
5. Update powerlevel tracking to point to live repository

## Task 6: Powerlevel Integration

**Files:**
- `/var/home/jorge/.config/opencode/powerlevel/AGENTS.md`
- `/var/home/jorge/.config/opencode/powerlevel/projects/bluespeed/config.json` (already created)

**Steps:**
1. Verify powerlevel project config exists for bluespeed
2. Update powerlevel AGENTS.md to document org/repo convention:
   - When user says `org/repo`, it means GitHub organization and repository
   - Examples: `castrojo/bluespeed`, `projectbluefin/common`
   - `castrojo/bluespeed` is for Bluefin maintenance agents/skills
3. Commit powerlevel changes documenting new convention
4. Test external tracking sync (if implemented)

## Implementation Notes

### MVP Scope (Phases 1-3)
- **OpenCode full support**: dosu + linux-mcp-server configuration
- **Goose partial support**: linux-mcp-server only (dosu TBD)
- **Manual setup documentation**: As fallback option
- **Username detection**: Via `whoami` command
- **Config merging**: Preserve existing MCP servers/extensions
- **Validation**: JSON/YAML syntax checking

### Phase 4 (Future Enhancement)
- **Goose dosu integration**: Research remote MCP server configuration
- **Update goose-example.yaml**: Add dosu if supported
- **Update SKILL.md**: Add Goose dosu instructions
- **Test with Goose**: Validate skill execution in Goose

### Key Technical Decisions
1. **Username detection**: `whoami` command (dynamic, portable)
2. **Repository visibility**: Public (aligns with Bluefin open source philosophy)
3. **MVP approach**: OpenCode first, Goose incrementally
4. **Deployment ID**: Public and safe to commit (83775020-c22e-485a-a222-987b2f5a3823)
5. **Config strategy**: Merge, don't replace (preserve existing work)

### Prerequisites
Users must install these brew packages before running skill:
- `brew install ublue-os/tap/linux-mcp-server`
- `brew install --cask ublue-os/experimental-tap/opencode-desktop-linux`
- `brew install --cask ublue-os/tap/goose-linux` (optional)

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
- ✅ OpenCode users can configure dosu + linux-mcp-server
- ✅ Goose users can configure linux-mcp-server (dosu documented as TBD)
- ✅ Username detected dynamically via `whoami`
- ✅ Existing configs preserved and merged
- ✅ Clear documentation for manual setup
- ✅ Powerlevel tracking configured
- ✅ org/repo convention documented in powerlevel
