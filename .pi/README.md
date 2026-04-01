# Everything Claude Code for Pi.dev

Bring Everything Claude Code (ECC) workflows to [pi.dev](https://pi.dev) — a minimal, highly customizable terminal-based AI coding agent. This repository provides 140+ skills that can be installed into any pi.dev project with a single command.

## Quick Start

```bash
# Install to current project
.pi/install.sh

# Install globally to ~/.pi/
.pi/install.sh ~
```

The installer uses non-destructive copy — it will not overwrite your existing files.

## What's Included

### Skills

ECC provides 140+ skills that pi.dev can auto-discover from the `.pi/skills/` directory. Each skill is a modular workflow covering:

- **Development Workflows**: TDD, code review, security review, API design
- **Language Standards**: TypeScript, Python, Go, Rust, Java, Kotlin, PHP, Swift, C++
- **Framework Patterns**: React, Next.js, Django, Spring Boot, Laravel, Axum
- **Tool Integration**: MCP server patterns, Playwright E2E, Claude API
- **Content & Business**: Article writing, investor materials, market research

Pi.dev auto-discovers skills placed in `.pi/skills/`. Use `/skill <name>` within pi to activate a specific skill.

### Context Files

The installer copies `AGENTS.md` and `CLAUDE.md` to your project root. These files provide pi.dev with context about available agents and project conventions.

## Prerequisites

1. [Node.js](https://nodejs.org) 18+ installed
2. Pi.dev installed: `npm install -g @mariozechner/pi-coding-agent`
3. An API key for your preferred LLM provider (Anthropic, OpenAI, etc.)

## Installation

### Local Installation

Install to the current project's `.pi` directory:

```bash
cd /path/to/your/project
.pi/install.sh
```

This copies all ECC skills into `.pi/skills/` and creates `.pi/settings.json`.

### Global Installation

Install globally (available in all projects):

```bash
.pi/install.sh ~
```

This creates `~/.pi/skills/` with all ECC skills.

## Using Skills in Pi.dev

After installation, start pi in your project:

```bash
pi
```

Pi will auto-discover skills from `.pi/skills/`. To use a skill:

```
/skill tdd-workflow        # Test-driven development
/skill code-review         # Code quality review
/skill security-review     # Security audit
/skill api-design          # REST API design
```

Or install skills as pi packages:

```bash
pi install git:https://github.com/affaan-m/everything-claude-code
```

## Uninstall

The uninstaller uses a manifest file (`.ecc-manifest`) to track installed files, ensuring safe removal:

```bash
.pi/uninstall.sh
```

### Uninstall Behavior

- **Safe removal**: Only removes files tracked in the manifest (installed by ECC)
- **User files preserved**: Any files you added manually are kept
- **Non-empty directories**: Directories containing user-added files are skipped
- **Manifest-based**: Requires `.ecc-manifest` file (created during install)

## Project Structure

```
.pi/
├── skills/             # ECC skills (auto-discovered by pi)
│   ├── tdd-workflow/
│   │   └── SKILL.md
│   ├── coding-standards/
│   │   └── SKILL.md
│   └── ...             # 140+ more skills
├── settings.json       # Pi.dev project settings
├── install.sh          # Install script
├── uninstall.sh        # Uninstall script
└── README.md           # This file

AGENTS.md               # Agent descriptions (context for pi)
CLAUDE.md               # Project conventions (context for pi)
```

## Customization

Pi.dev is designed to be deeply customizable. After installation, you can:

- **Add custom skills**: Create new directories in `.pi/skills/` with a `SKILL.md` file
- **Modify settings**: Edit `.pi/settings.json` to change context files or skill paths
- **Add extensions**: Create TypeScript extensions in `.pi/extensions/` for advanced automation

See the [pi.dev documentation](https://pi.dev) for more information on customization.

## Recommended Workflow

1. **Start with planning**: `/skill planner` — break down complex features
2. **Write tests first**: `/skill tdd-workflow` — test-driven development
3. **Review your code**: `/skill code-review` — quality review
4. **Check security**: `/skill security-review` — security audit
5. **Fix build errors**: The `build-error-resolver` agent pattern helps debug issues

## Next Steps

- Install pi.dev: `npm install -g @mariozechner/pi-coding-agent`
- Run `pi` in your project
- Use `/skill <name>` to activate ECC workflows
- Enjoy the ECC + pi.dev experience!
