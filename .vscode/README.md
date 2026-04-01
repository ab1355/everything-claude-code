# Everything Claude Code for VS Code

Bring Everything Claude Code (ECC) workflows to VS Code with the Claude Code extension. This repository provides custom commands, agents, skills, and rules that can be installed into any VS Code project with a single command.

## Quick Start

```bash
# Install to current project
.vscode/install.sh

# Install globally to ~/.vscode/
.vscode/install.sh ~
```

The installer uses non-destructive copy — it will not overwrite your existing files.

## What's Included

### Commands

Commands are on-demand workflows invocable via the `/` menu in the Claude Code panel. All commands are reused directly from the project root's `commands/` folder.

### Agents

Agents are specialized AI assistants with specific tool configurations. All agents are reused directly from the project root's `agents/` folder.

### Skills

Skills are on-demand workflows invocable via the `/` menu in chat. All skills are reused directly from the project's `skills/` folder.

### Rules

Rules provide always-on context that shapes how the agent works with your code. All rules are reused directly from the project root's `rules/` folder.

### VS Code Settings

The installer creates `.vscode/settings.json` with recommended settings for use with the Claude Code extension:

- `editor.formatOnSave` — automatically format files on save
- `files.trimTrailingWhitespace` — keep files clean
- `claude.agentsFile` — points to the `AGENTS.md` file at the project root

### Recommended Extensions

The installer creates `.vscode/extensions.json` recommending the Claude Code extension (`anthropic.claude-code`).

## Installation Modes

### Local Installation

Install to the current project's `.vscode` directory:

```bash
cd /path/to/your/project
.vscode/install.sh
```

This creates agent, command, skill, and rule files in your project and configures `.vscode/settings.json`.

### Global Installation

Install to your home directory:

```bash
.vscode/install.sh ~
```

## Uninstall

The uninstaller uses a manifest file (`.ecc-manifest`) to track installed files, ensuring safe removal:

```bash
.vscode/uninstall.sh
```

### Uninstall Behavior

- **Safe removal**: Only removes files tracked in the manifest (installed by ECC)
- **User files preserved**: Any files you added manually are kept
- **Non-empty directories**: Directories containing user-added files are skipped
- **Manifest-based**: Requires `.ecc-manifest` file (created during install)

## Project Structure

```
.vscode/
├── settings.json       # VS Code workspace settings
├── extensions.json     # Recommended extensions
├── install.sh          # Install script
├── uninstall.sh        # Uninstall script
└── README.md           # This file

commands/               # Command files (reused from project root)
agents/                 # Agent files (reused from project root)
skills/                 # Skill files (reused from skills/)
rules/                  # Rule files (reused from project root)
AGENTS.md               # Agent descriptions (read by Claude Code extension)
```

## Prerequisites

1. [VS Code](https://code.visualstudio.com/) installed
2. [Claude Code extension](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code) installed
3. An Anthropic API key configured

## Usage

1. Open your project in VS Code
2. Open the Claude Code panel (click the Claude icon in the sidebar)
3. Type `/` to see available commands
4. Select a command or skill to invoke it
5. The agent will guide you through the workflow

## Recommended Workflow

1. **Start with planning**: Use `/plan` command to break down complex features
2. **Write tests first**: Invoke `/tdd` command before implementing
3. **Review your code**: Use `/code-review` after writing code
4. **Check security**: Use `/code-review` for auth, API endpoints, or sensitive data
5. **Fix build errors**: Use `/build-fix` if there are build errors

## Next Steps

- Open your project in VS Code
- Install the Claude Code extension if you haven't already
- Type `/` in the Claude Code panel to see available commands
- Enjoy the ECC workflows!
