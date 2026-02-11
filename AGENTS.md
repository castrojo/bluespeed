# castrojo/bluespeed Repository Structure

**Purpose:** Agents and skills for maintaining Project Bluefin

---

## ⚠️ CRITICAL: Skills-Based Architecture - READ THIS FIRST

**This repository follows a STRICT skills-based pattern. All future agents MUST follow this architecture.**

### Core Principles (MANDATORY)

1. **SKILL.md is the Source of Truth**
   - Every skill's `SKILL.md` contains COMPLETE, EXECUTABLE instructions
   - Agents read `SKILL.md` from GitHub and execute instructions inline
   - NO git clone required - agents work from remote repository
   - SKILL.md must be self-contained and actionable

2. **Bash Scripts are OPTIONAL REFERENCE**
   - Scripts in `scripts/` directory are examples for manual users
   - Agents DO NOT run bash scripts - they follow SKILL.md instructions
   - Scripts serve as reference implementations only
   - Keep scripts in sync with SKILL.md, but SKILL.md is authoritative

3. **User Invocation Pattern**
   - User says: "Onboard me to projectbluefin/bluespeed" or "Onboard me to castrojo/bluespeed"
   - Agent searches GitHub repository: `castrojo/bluespeed`
   - Agent finds and reads: `skills/<skill-name>/SKILL.md`
   - Agent executes instructions inline using Bash tool
   - NO CLONING, NO SCRIPT EXECUTION - direct instruction following only

4. **Auto-Installation Philosophy**
   - Skills auto-install missing prerequisites via Homebrew
   - Fail fast if Homebrew not installed
   - Verify each package after installation
   - Provide clear error messages with remediation steps

5. **Configuration Management**
   - Always backup configs before modification (timestamped: `.YYYY-MM-DDTHH:MM:SS.backup`)
   - Merge, never overwrite - preserve existing user settings
   - Skip duplicates with warning messages
   - Validate JSON/YAML after changes
   - Auto-rollback on validation errors

### Forbidden Patterns (DO NOT DO THIS)

❌ **DO NOT** tell users to clone this repository  
❌ **DO NOT** execute bash scripts from this repo  
❌ **DO NOT** require manual setup steps that can be automated  
❌ **DO NOT** write SKILL.md as documentation only - it must be executable  
❌ **DO NOT** assume prerequisites are installed - auto-install them  

### Required Patterns (ALWAYS DO THIS)

✅ **DO** read SKILL.md from GitHub directly  
✅ **DO** execute inline commands via Bash tool  
✅ **DO** auto-install missing prerequisites  
✅ **DO** backup configs before modifying  
✅ **DO** validate all changes and auto-rollback on errors  
✅ **DO** keep SKILL.md and bash scripts in sync  
✅ **DO** provide clear success/error messages to users

---

## Directory Organization

```
bluespeed/
├── README.md                           # Repository overview
├── AGENTS.md                           # Instructions for AI agents (YOU ARE HERE)
├── docs/
│   └── plans/                          # Implementation plans
│       └── YYYY-MM-DD-feature.md
├── skills/                             # OpenCode/Goose skills
│   └── <skill-name>/
│       ├── SKILL.md                    # Skill documentation (frontmatter + instructions)
│       ├── AGENTS.md                   # Agent-specific execution notes (optional)
│       └── scripts/                    # Bash scripts for this skill
│           ├── lib/                    # Shared library functions
│           │   ├── common.sh           # Common utilities
│           │   ├── config.sh           # Configuration helpers
│           │   └── validation.sh       # Validation functions
│           └── <action>.sh             # Executable scripts
└── configs/                            # Configuration examples
    └── <tool>-example.<ext>            # Template configs
```

## Skill Organization Pattern

Each skill follows this structure:

### 1. Skill Documentation (`skills/<skill-name>/SKILL.md`)
- Frontmatter with `name:` and `description:`
- Overview and "When to Use" section
- Step-by-step process instructions
- Error handling guidance
- Integration with other skills

### 2. Agent Instructions (`skills/<skill-name>/AGENTS.md`) - Optional
- Agent-specific execution notes
- Expected inputs/outputs
- Success criteria
- Example invocations

### 3. Script Directory (`skills/<skill-name>/scripts/`)
- **Executable scripts**: Named by action (e.g., `setup-opencode.sh`, `setup-goose.sh`)
- **Library functions**: Organized in `lib/` subdirectory
  - `lib/common.sh` - Utilities used across scripts (logging, error handling)
  - `lib/config.sh` - Configuration file manipulation (JSON/YAML)
  - `lib/validation.sh` - Prerequisite checks, validation functions

### Script Naming Convention
- Use kebab-case: `setup-opencode.sh`, `validate-prereqs.sh`
- Action-based names: `<verb>-<noun>.sh`
- Main entry point: `setup.sh` or skill name (e.g., `bluespeed-onboarding.sh`)

### Library Function Pattern
Scripts in `lib/` are sourced by executable scripts:

```bash
#!/usr/bin/env bash
# Source library functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/config.sh"
source "${SCRIPT_DIR}/lib/validation.sh"

# Use library functions
log_info "Starting setup..."
validate_prerequisites
merge_mcp_config "dosu" "remote"
```

## Example: bluespeed-onboarding Skill

```
skills/bluespeed-onboarding/
├── SKILL.md                            # User-facing documentation
├── AGENTS.md                           # Agent execution notes
└── scripts/
    ├── lib/
    │   ├── common.sh                   # Logging, error handling, whoami
    │   ├── config.sh                   # JSON/YAML manipulation with jq/yq
    │   └── validation.sh               # Brew package checks, file existence
    ├── setup-opencode.sh               # Configure OpenCode MCP servers
    ├── setup-goose.sh                  # Configure Goose extensions (future)
    └── bluespeed-onboarding.sh         # Main entry point (asks which tool)
```

## Why This Structure?

### Scalability
- Add new skills without affecting existing ones
- Each skill is self-contained
- Shared code in `lib/` prevents duplication

### Maintainability
- Clear separation: docs vs. code
- Library functions reduce script complexity
- Agent instructions separate from user docs

### Discoverability
- Predictable locations (`skills/<name>/scripts/`)
- Consistent naming patterns
- Self-documenting structure

## For AI Agents Working on Bluespeed

### Adding a New Skill

1. **Create skill directory:**
   ```bash
   mkdir -p skills/<skill-name>/scripts/lib
   ```

2. **Write SKILL.md** with frontmatter:
   ```yaml
   ---
   name: skill-name
   description: Brief description
   ---
   ```

3. **Create scripts** in `scripts/` directory:
   - Start with main entry point: `<skill-name>.sh`
   - Extract reusable code to `lib/` functions
   - Source library functions at top of scripts

4. **Write AGENTS.md** (optional):
   - If agents need special execution notes
   - Don't duplicate SKILL.md content

### Modifying Existing Skills

1. **Read SKILL.md first** - Understand the skill's purpose
2. **Check scripts/lib/** - Use existing library functions
3. **Update both docs and code** - Keep them in sync
4. **Test scripts** - Verify functionality before committing

### Script Development Guidelines

**Library Functions (`lib/`):**
- Pure functions with clear inputs/outputs
- No side effects unless explicitly documented
- Return 0 for success, non-zero for errors
- Use descriptive function names: `validate_brew_package`, `merge_json_config`

**Executable Scripts:**
- Start with shebang: `#!/usr/bin/env bash`
- Set strict mode: `set -euo pipefail`
- Source library functions from `lib/`
- Main logic at bottom, functions at top
- Exit with appropriate code: 0=success, 1=error

**Error Handling:**
- Check prerequisites early (fail fast)
- Provide clear error messages
- Suggest remediation steps
- Use library's `log_error` function

**Configuration Management:**
- Never overwrite configs without backup
- Use `lib/config.sh` merge functions
- Validate syntax after modifications
- Preserve existing user settings

## Growth Strategy

As bluespeed grows:

### Adding New Skills
- Follow the established pattern: `skills/<name>/scripts/lib/`
- Reuse existing `lib/` functions across skills
- Update this AGENTS.md with new patterns if needed

### Extracting Common Code
- When 3+ skills use similar code → extract to shared library
- Create `lib/shared/` for cross-skill utilities
- Update all skills to source from shared location

### Organizing by Domain
- If skills grow beyond 10, consider grouping:
  ```
  skills/
  ├── onboarding/
  │   └── bluespeed-onboarding/
  ├── monitoring/
  │   └── system-check/
  └── deployment/
      └── container-build/
  ```

## Technology Choices

### Why Bash?
- Native to Linux environments (Bluefin/Universal Blue)
- Direct system interaction (file manipulation, command execution)
- Works with existing tools (jq, yq, gh, brew)
- Portable across Bluefin installations
- No additional runtime dependencies

### External Tools Used
- **jq** - JSON manipulation (`lib/config.sh`)
- **yq** - YAML manipulation (`lib/config.sh`)
- **gh** - GitHub CLI operations
- **brew** - Package management verification

### When NOT to Use Bash
- Complex data structures → Use Python/Node.js
- Heavy string processing → Use Python/Node.js
- API-heavy operations → Use Python/Node.js with proper libraries

## Configuration Examples

The `configs/` directory contains template configurations:

```
configs/
├── README.md                           # Explains each template
├── opencode-example.json               # OpenCode MCP configuration
└── goose-example.yaml                  # Goose extension configuration
```

These are **reference templates**, not executed. Scripts in `skills/*/scripts/` use these as examples when generating or merging user configurations.

## Naming Conventions Summary

| Type | Convention | Example |
|------|------------|---------|
| Skill directory | kebab-case | `bluespeed-onboarding/` |
| Script file | kebab-case.sh | `setup-opencode.sh` |
| Library file | kebab-case.sh | `common.sh` |
| Function name | snake_case | `merge_json_config()` |
| Variable name | snake_case | `config_path` |
| Constant name | SCREAMING_SNAKE | `DEFAULT_CONFIG_PATH` |

## Best Practices for Agents

1. **Read before writing** - Always read existing scripts/docs before modifying
2. **Test locally** - Run scripts in `/var/home/jorge/src/bluespeed` before committing
3. **Update documentation** - Keep SKILL.md in sync with script changes
4. **Use library functions** - Don't duplicate code, extract to `lib/`
5. **Follow conventions** - Maintain consistent naming and structure
6. **Commit atomically** - One logical change per commit
7. **Write clear commit messages** - Follow Conventional Commits

## Questions for Future Agents

Before modifying bluespeed:

1. **Does this fit the existing pattern?** - If not, ask the user first
2. **Can I reuse existing library functions?** - Check `lib/` first
3. **Should this be a new skill or extend existing?** - Consider scope
4. **Do I need to update AGENTS.md?** - If pattern changes, yes
5. **Are there external dependencies?** - Document in SKILL.md prerequisites

## Related Documentation

- **Powerlevel AGENTS.md**: `/var/home/jorge/.config/opencode/powerlevel/AGENTS.md`
  - Explains external project tracking
  - Mandatory workflow: writing-plans → epic-creation → executing-plans
- **Bluefin AGENTS.md**: `projectbluefin/documentation/AGENTS.md`
  - AI agent attribution requirements
  - Bluefin-specific conventions
- **OpenCode Skills**: `~/.config/opencode/skills/`
  - Examples of skill structure
  - Powerlevel skills follow similar patterns

## Current Skills

### bluespeed-onboarding
**Status:** In Development (Epic #1)  
**Purpose:** Setup dosu MCP and linux-mcp-server for Bluefin maintainers  
**Tech:** Bash scripts, jq/yq for JSON/YAML manipulation  
**Location:** `skills/bluespeed-onboarding/`

More skills will be added as Bluefin maintenance tasks are identified.
